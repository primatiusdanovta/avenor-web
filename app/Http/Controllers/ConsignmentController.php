<?php

namespace App\Http\Controllers;

use App\Models\AccountReceivable;
use App\Models\Consignment;
use App\Models\ConsignmentItem;
use App\Models\ProductOnhand;
use App\Models\User;
use App\Support\AccountReceivableSupport;
use App\Support\ProductOnhandStock;
use App\Support\SalesRole;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;
use Inertia\Response;

class ConsignmentController extends Controller
{
    public function index(Request $request): Response
    {
        $this->abortIfStoreDisablesOnhandAndConsignment($request);
        abort_unless(
            in_array($request->user()->role, ['superadmin', 'admin', SalesRole::SALES_FIELD_EXECUTIVE], true),
            403
        );

        $isSuperadmin = $request->user()->role === 'superadmin';
        $selectedUserId = $request->user()->role === SalesRole::SALES_FIELD_EXECUTIVE
            ? $request->user()->id_user
            : ($request->integer('user_id') ?: null);
        $search = trim((string) $request->string('search'));

        $users = $request->user()->role === SalesRole::SALES_FIELD_EXECUTIVE
            ? collect([[
                'id_user' => $request->user()->id_user,
                'nama' => $request->user()->nama,
                'option_label' => $request->user()->nama,
            ]])
            : User::query()
                ->where('role', SalesRole::SALES_FIELD_EXECUTIVE)
                ->orderBy('nama')
                ->get(['id_user', 'nama'])
                ->map(fn (User $user) => [
                    'id_user' => $user->id_user,
                    'nama' => $user->nama,
                    'option_label' => $user->nama,
                ])
                ->values();

        $consignments = Consignment::query()
            ->with(['user:id_user,nama', 'items'])
            ->when($selectedUserId, fn ($query, $userId) => $query->where('user_id', $userId))
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($inner) use ($search) {
                    $inner->where('place_name', 'like', "%{$search}%")
                        ->orWhere('address', 'like', "%{$search}%")
                        ->orWhereHas('user', fn ($userQuery) => $userQuery->where('nama', 'like', "%{$search}%"))
                        ->orWhereHas('items', fn ($itemQuery) => $itemQuery->where('product_name', 'like', "%{$search}%"));
                });
            })
            ->latest('submitted_at')
            ->latest('id')
            ->get()
            ->map(fn (Consignment $consignment) => $this->transformConsignment($consignment))
            ->values();

        $availableOnhands = ProductOnhand::query()
            ->with(['user:id_user,nama,role'])
            ->where('take_status', 'disetujui')
            ->whereHas('user', fn ($query) => $query->where('role', SalesRole::SALES_FIELD_EXECUTIVE))
            ->when($selectedUserId, fn ($query, $userId) => $query->where('user_id', $userId))
            ->orderByDesc('assignment_date')
            ->orderByDesc('id_product_onhand')
            ->get()
            ->map(fn (ProductOnhand $onhand) => $this->transformAvailableOnhand($onhand))
            ->filter(fn (array $onhand) => $onhand['available_quantity'] > 0 || $onhand['consigned_quantity'] > 0)
            ->values();

        return Inertia::render('Consignments/Index', [
            'filters' => [
                'user_id' => $selectedUserId,
                'search' => $search,
            ],
            'users' => $users,
            'consignments' => $consignments,
            'availableOnhands' => $availableOnhands,
            'canManageConsignments' => $isSuperadmin,
            'statuses' => ['dititipkan', 'dikembalikan', 'terjual'],
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->abortIfStoreDisablesOnhandAndConsignment($request);
        abort_unless($request->user()->role === 'superadmin', 403);

        $validated = $this->validatePayload($request);
        $targetUser = $this->resolveTargetUser((int) $validated['user_id']);
        $proofPath = $request->file('handover_proof_photo')?->store('consignments', 'public');

        try {
            DB::transaction(function () use ($validated, $targetUser, $proofPath): void {
                $consignment = Consignment::query()->create([
                    'user_id' => $targetUser->id_user,
                    'place_name' => $validated['place_name'],
                    'address' => $validated['address'],
                    'consignment_date' => $validated['consignment_date'],
                    'submitted_at' => now(),
                    'latitude' => 0,
                    'longitude' => 0,
                    'notes' => $validated['notes'] ?? null,
                    'handover_proof_photo' => $proofPath,
                ]);

                $this->syncConsignmentItems(
                    $consignment,
                    $targetUser,
                    collect($validated['items'] ?? [])
                );
            });
        } catch (\Throwable $exception) {
            if ($proofPath) {
                Storage::disk('public')->delete($proofPath);
            }

            throw $exception;
        }

        return redirect()
            ->route('consignments.index', $this->redirectFilters($request))
            ->with('success', 'Data consign berhasil ditambahkan.');
    }

    public function update(Request $request, Consignment $consignment): RedirectResponse
    {
        $this->abortIfStoreDisablesOnhandAndConsignment($request);
        abort_unless($request->user()->role === 'superadmin', 403);

        $validated = $this->validatePayload($request, true);
        $targetUser = $this->resolveTargetUser((int) $validated['user_id']);
        $newProofPath = $request->file('handover_proof_photo')?->store('consignments', 'public');
        $oldProofPath = $consignment->handover_proof_photo;
        $removeProof = (bool) ($validated['remove_handover_proof_photo'] ?? false);

        try {
            DB::transaction(function () use ($validated, $targetUser, $consignment, $newProofPath, $oldProofPath, $removeProof): void {
                $consignment = Consignment::query()
                    ->with('items')
                    ->lockForUpdate()
                    ->findOrFail($consignment->id);

                if ((int) $consignment->user_id !== (int) $targetUser->id_user) {
                    $hasActivity = $consignment->items->contains(function (ConsignmentItem $item) {
                        return ((int) $item->sold_quantity + (int) $item->returned_quantity) > 0;
                    });

                    if ($hasActivity) {
                        throw ValidationException::withMessages([
                            'user_id' => 'Consign yang sudah memiliki progres penjualan atau pengembalian tidak bisa dipindahkan ke user lain.',
                        ]);
                    }
                }

                $consignment->update([
                    'user_id' => $targetUser->id_user,
                    'place_name' => $validated['place_name'],
                    'address' => $validated['address'],
                    'consignment_date' => $validated['consignment_date'],
                    'notes' => $validated['notes'] ?? null,
                    'handover_proof_photo' => $newProofPath
                        ?: ($removeProof ? null : $oldProofPath),
                ]);

                $this->syncConsignmentItems(
                    $consignment,
                    $targetUser,
                    collect($validated['items'] ?? [])
                );
            });
        } catch (\Throwable $exception) {
            if ($newProofPath) {
                Storage::disk('public')->delete($newProofPath);
            }

            throw $exception;
        }

        if (($newProofPath || $removeProof) && $oldProofPath) {
            Storage::disk('public')->delete($oldProofPath);
        }

        return redirect()
            ->route('consignments.index', $this->redirectFilters($request))
            ->with('success', 'Data consign berhasil diperbarui.');
    }

    public function destroy(Request $request, Consignment $consignment): RedirectResponse
    {
        $this->abortIfStoreDisablesOnhandAndConsignment($request);
        abort_unless($request->user()->role === 'superadmin', 403);

        $proofPath = $consignment->handover_proof_photo;

        DB::transaction(function () use ($consignment): void {
            $consignment = Consignment::query()
                ->with('items')
                ->lockForUpdate()
                ->findOrFail($consignment->id);

            $hasActivity = $consignment->items->contains(function (ConsignmentItem $item) {
                return ((int) $item->sold_quantity + (int) $item->returned_quantity) > 0;
            });

            if ($hasActivity) {
                throw ValidationException::withMessages([
                    'delete' => 'Consign yang sudah memiliki progres penjualan atau pengembalian tidak bisa dihapus.',
                ]);
            }

            AccountReceivable::query()->where('consignment_id', $consignment->id)->delete();
            $consignment->delete();
        });

        if ($proofPath) {
            Storage::disk('public')->delete($proofPath);
        }

        return redirect()
            ->route('consignments.index', $this->redirectFilters($request))
            ->with('success', 'Data consign berhasil dihapus.');
    }

    public function updateItem(Request $request, ConsignmentItem $item): RedirectResponse
    {
        $this->abortIfStoreDisablesOnhandAndConsignment($request);
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        $validated = $request->validate([
            'sold_quantity' => ['required', 'integer', 'min:0'],
            'returned_quantity' => ['required', 'integer', 'min:0'],
            'status_notes' => ['nullable', 'string', 'max:2000'],
        ]);

        abort_if(
            ((int) $validated['sold_quantity'] + (int) $validated['returned_quantity']) > (int) $item->quantity,
            422,
            'Jumlah terjual dan dikembalikan melebihi quantity consign.'
        );

        DB::transaction(function () use ($item, $validated) {
            $item->update([
                'sold_quantity' => (int) $validated['sold_quantity'],
                'returned_quantity' => (int) $validated['returned_quantity'],
                'status' => $this->resolveItemStatus(
                    (int) $validated['sold_quantity'],
                    (int) $validated['returned_quantity'],
                    (int) $item->quantity
                ),
                'status_notes' => $validated['status_notes'] ?? null,
            ]);

            AccountReceivableSupport::syncFromConsignment($item->consignment()->firstOrFail());
        });

        return redirect()
            ->route('consignments.index', $this->redirectFilters($request))
            ->with('success', 'Status consign berhasil diperbarui dan account receivable disinkronkan.');
    }

    private function validatePayload(Request $request, bool $isUpdate = false): array
    {
        return $request->validate([
            'user_id' => ['required', 'integer'],
            'place_name' => ['required', 'string', 'max:255'],
            'address' => ['required', 'string', 'max:2000'],
            'consignment_date' => ['required', 'date'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'handover_proof_photo' => [$isUpdate ? 'nullable' : 'nullable', 'image', 'max:4096'],
            'remove_handover_proof_photo' => ['nullable', 'boolean'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.id' => ['nullable', 'integer', 'exists:consignment_items,id'],
            'items.*.product_onhand_id' => ['required', 'integer', 'distinct', 'exists:product_onhands,id_product_onhand'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
        ]);
    }

    private function resolveTargetUser(int $userId): User
    {
        $user = User::query()->findOrFail($userId);

        if ($user->role !== SalesRole::SALES_FIELD_EXECUTIVE) {
            throw ValidationException::withMessages([
                'user_id' => 'User consign harus sales field executive.',
            ]);
        }

        return $user;
    }

    private function syncConsignmentItems(Consignment $consignment, User $targetUser, \Illuminate\Support\Collection $submittedItems): void
    {
        $consignment->loadMissing('items');
        $existingItems = $consignment->items->keyBy('id');
        $submittedIds = $submittedItems->pluck('id')->filter()->map(fn ($id) => (int) $id)->values();

        $unknownIds = $submittedIds->filter(fn (int $id) => ! $existingItems->has($id));
        if ($unknownIds->isNotEmpty()) {
            throw ValidationException::withMessages([
                'items' => 'Ada item consign yang tidak cocok dengan data saat ini.',
            ]);
        }

        foreach ($existingItems as $existingItem) {
            if ($submittedIds->contains((int) $existingItem->id)) {
                continue;
            }

            if (((int) $existingItem->sold_quantity + (int) $existingItem->returned_quantity) > 0) {
                throw ValidationException::withMessages([
                    'items' => 'Item consign yang sudah memiliki progres tidak bisa dihapus dari draft consign.',
                ]);
            }

            $existingItem->delete();
        }

        foreach ($submittedItems as $payload) {
            $existingItem = isset($payload['id']) ? $existingItems->get((int) $payload['id']) : null;
            $requestedQuantity = (int) $payload['quantity'];

            $onhand = ProductOnhand::query()
                ->where('id_product_onhand', $payload['product_onhand_id'])
                ->where('user_id', $targetUser->id_user)
                ->where('take_status', 'disetujui')
                ->lockForUpdate()
                ->firstOrFail();

            $minimumQuantity = 1;
            $reservedByCurrentItem = 0;

            if ($existingItem) {
                $minimumQuantity = (int) $existingItem->sold_quantity + (int) $existingItem->returned_quantity;
                $reservedByCurrentItem = max(
                    (int) $existingItem->quantity - (int) $existingItem->sold_quantity - (int) $existingItem->returned_quantity,
                    0
                );

                if ((int) $existingItem->product_onhand_id !== (int) $onhand->id_product_onhand && $minimumQuantity > 0) {
                    throw ValidationException::withMessages([
                        'items' => 'Item consign yang sudah memiliki progres tidak bisa dipindahkan ke batch lain.',
                    ]);
                }
            }

            if ($requestedQuantity < $minimumQuantity) {
                throw ValidationException::withMessages([
                    'items' => 'Quantity consign tidak boleh lebih kecil dari total barang yang sudah terjual atau dikembalikan.',
                ]);
            }

            $availableQuantity = ProductOnhandStock::availableQuantity($onhand) + $reservedByCurrentItem;
            if ($requestedQuantity > $availableQuantity) {
                throw ValidationException::withMessages([
                    'items' => "Quantity consign {$onhand->nama_product} melebihi stok batch yang tersedia.",
                ]);
            }

            $attributes = [
                'product_onhand_id' => $onhand->id_product_onhand,
                'product_id' => $onhand->id_product,
                'product_name' => $onhand->nama_product,
                'pickup_batch_code' => $onhand->pickup_batch_code,
                'quantity' => $requestedQuantity,
            ];

            if ($existingItem) {
                $existingItem->update([
                    ...$attributes,
                    'status' => $this->resolveItemStatus(
                        (int) $existingItem->sold_quantity,
                        (int) $existingItem->returned_quantity,
                        $requestedQuantity
                    ),
                ]);
                continue;
            }

            $consignment->items()->create([
                ...$attributes,
                'sold_quantity' => 0,
                'returned_quantity' => 0,
                'status' => 'dititipkan',
                'status_notes' => null,
            ]);
        }

        AccountReceivableSupport::syncFromConsignment($consignment->fresh('items'));
    }

    private function transformConsignment(Consignment $consignment): array
    {
        $consignment->loadMissing(['user:id_user,nama', 'items']);

        return [
            'id' => $consignment->id,
            'user_id' => $consignment->user_id,
            'user_name' => $consignment->user?->nama,
            'place_name' => $consignment->place_name,
            'address' => $consignment->address,
            'consignment_date' => optional($consignment->consignment_date)->format('Y-m-d'),
            'submitted_at' => optional($consignment->submitted_at)->format('Y-m-d H:i:s'),
            'latitude' => (float) $consignment->latitude,
            'longitude' => (float) $consignment->longitude,
            'notes' => $consignment->notes,
            'handover_proof_photo_url' => $consignment->handover_proof_photo
                ? Storage::disk('public')->url($consignment->handover_proof_photo)
                : null,
            'items' => $consignment->items
                ->map(fn (ConsignmentItem $item) => [
                    'id' => $item->id,
                    'product_onhand_id' => $item->product_onhand_id,
                    'product_id' => $item->product_id,
                    'product_name' => $item->product_name,
                    'pickup_batch_code' => $item->pickup_batch_code,
                    'quantity' => (int) $item->quantity,
                    'sold_quantity' => (int) $item->sold_quantity,
                    'returned_quantity' => (int) $item->returned_quantity,
                    'status' => $item->status,
                    'status_notes' => $item->status_notes,
                ])
                ->values(),
        ];
    }

    private function transformAvailableOnhand(ProductOnhand $onhand): array
    {
        $availableQuantity = ProductOnhandStock::availableQuantity($onhand);
        $consignedQuantity = max(
            (int) $onhand->quantity
            - ProductOnhandStock::soldQuantity($onhand)
            - ProductOnhandStock::approvedReturnQuantity($onhand)
            - ProductOnhandStock::pendingReturnQuantity($onhand)
            - $availableQuantity,
            0
        );

        return [
            'id_product_onhand' => $onhand->id_product_onhand,
            'user_id' => $onhand->user_id,
            'user_name' => $onhand->user?->nama,
            'user_role' => $onhand->user?->role,
            'id_product' => $onhand->id_product,
            'nama_product' => $onhand->nama_product,
            'pickup_batch_code' => $onhand->pickup_batch_code,
            'assignment_date' => optional($onhand->assignment_date)->format('Y-m-d'),
            'quantity' => (int) $onhand->quantity,
            'available_quantity' => $availableQuantity,
            'consigned_quantity' => $consignedQuantity,
            'option_label' => sprintf(
                '%s | %s | batch %s | sisa %d',
                $onhand->user?->nama ?? 'User',
                $onhand->nama_product,
                $onhand->pickup_batch_code ?: '-',
                $availableQuantity
            ),
        ];
    }

    private function resolveItemStatus(int $soldQuantity, int $returnedQuantity, int $quantity): string
    {
        if ($soldQuantity >= $quantity) {
            return 'terjual';
        }

        if ($returnedQuantity >= $quantity) {
            return 'dikembalikan';
        }

        if ($soldQuantity > 0) {
            return 'terjual';
        }

        if ($returnedQuantity > 0) {
            return 'dikembalikan';
        }

        return 'dititipkan';
    }

    private function redirectFilters(Request $request): array
    {
        return array_filter([
            'search' => trim((string) $request->input('search', '')) ?: null,
            'user_id' => $request->input('user_id') ?: null,
        ], fn ($value) => $value !== null && $value !== '');
    }
}
