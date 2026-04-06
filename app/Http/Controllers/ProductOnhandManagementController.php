<?php

namespace App\Http\Controllers;

use App\Models\Product;
use App\Models\ProductOnhand;
use App\Models\User;
use App\Support\ProductOnhandStock;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;
use Inertia\Response;

class ProductOnhandManagementController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless($request->user()?->role === 'superadmin', 403);

        $filters = [
            'search' => trim((string) $request->string('search')),
            'user_id' => $request->integer('user_id') ?: null,
            'take_status' => trim((string) $request->string('take_status')),
        ];

        $users = User::query()
            ->whereIn('role', ['marketing', 'reseller'])
            ->orderBy('nama')
            ->get(['id_user', 'nama', 'role'])
            ->map(fn (User $user) => [
                'id_user' => $user->id_user,
                'nama' => $user->nama,
                'role' => $user->role,
                'option_label' => $user->nama . ' | ' . ucfirst($user->role),
            ])
            ->values();

        $products = Product::query()
            ->orderBy('nama_product')
            ->get(['id_product', 'nama_product', 'stock'])
            ->map(fn (Product $product) => [
                'id_product' => $product->id_product,
                'nama_product' => $product->nama_product,
                'stock' => (int) $product->stock,
                'option_label' => $product->nama_product . ' | stock ' . (int) $product->stock,
            ])
            ->values();

        $onhands = ProductOnhand::query()
            ->with(['user:id_user,nama,role', 'product:id_product,nama_product,stock'])
            ->withCount('offlineSales')
            ->when($filters['user_id'], fn ($query, $userId) => $query->where('user_id', $userId))
            ->when($filters['take_status'] !== '', fn ($query) => $query->where('take_status', $filters['take_status']))
            ->when($filters['search'] !== '', function ($query) use ($filters) {
                $search = $filters['search'];

                $query->where(function ($inner) use ($search) {
                    $inner->where('nama_product', 'like', "%{$search}%")
                        ->orWhereHas('user', fn ($userQuery) => $userQuery->where('nama', 'like', "%{$search}%"));
                });
            })
            ->orderByDesc('assignment_date')
            ->orderByDesc('id_product_onhand')
            ->get()
            ->map(fn (ProductOnhand $onhand) => $this->transformOnhand($onhand))
            ->values();

        return Inertia::render('ProductOnhands/Index', [
            'filters' => [
                'search' => $filters['search'],
                'user_id' => $filters['user_id'],
                'take_status' => $filters['take_status'],
            ],
            'users' => $users,
            'products' => $products,
            'onhands' => $onhands,
            'takeStatuses' => [
                ['value' => 'pending', 'label' => 'Pending'],
                ['value' => 'disetujui', 'label' => 'Disetujui'],
                ['value' => 'ditolak', 'label' => 'Ditolak'],
            ],
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        abort_unless($request->user()?->role === 'superadmin', 403);

        $validated = $this->validatePayload($request);
        $user = $this->resolveTargetUser((int) $validated['user_id']);

        DB::transaction(function () use ($validated, $user, $request): void {
            $product = Product::query()
                ->lockForUpdate()
                ->findOrFail($validated['id_product']);

            $lockedStock = $this->lockedStockForTakeStatus(
                $validated['take_status'],
                (int) $validated['quantity'],
                0
            );

            if ($product->stock < $lockedStock) {
                throw ValidationException::withMessages([
                    'quantity' => 'Stock product tidak mencukupi untuk quantity onhand ini.',
                ]);
            }

            if ($lockedStock > 0) {
                $product->decrement('stock', $lockedStock);
            }

            ProductOnhand::query()->create([
                'user_id' => $user->id_user,
                'id_product' => $product->id_product,
                'nama_product' => $product->nama_product,
                'quantity' => (int) $validated['quantity'],
                'quantity_dikembalikan' => 0,
                'approved_return_quantity' => 0,
                'manual_sold_quantity' => 0,
                'take_status' => $validated['take_status'],
                'return_status' => 'belum',
                'approved_by' => null,
                'take_approved_by' => $validated['take_status'] === 'disetujui' || $validated['take_status'] === 'ditolak'
                    ? $request->user()->id_user
                    : null,
                'assignment_date' => $validated['assignment_date'],
                'created_at' => now(),
                'take_requested_at' => now(),
                'take_reviewed_at' => $validated['take_status'] === 'pending' ? null : now(),
            ]);
        });

        return redirect()
            ->route('product-onhands.index', $this->redirectFilters($request))
            ->with('success', 'Barang onhand berhasil ditambahkan.');
    }

    public function update(Request $request, ProductOnhand $onhand): RedirectResponse
    {
        abort_unless($request->user()?->role === 'superadmin', 403);

        $validated = $this->validatePayload($request);
        $user = $this->resolveTargetUser((int) $validated['user_id']);

        DB::transaction(function () use ($validated, $user, $request, $onhand): void {
            $onhand = ProductOnhand::query()
                ->withCount('offlineSales')
                ->lockForUpdate()
                ->findOrFail($onhand->id_product_onhand);

            $soldQuantity = $this->soldQuantity($onhand);
            $approvedReturnQuantity = ProductOnhandStock::approvedReturnQuantity($onhand);
            $pendingReturnQuantity = ProductOnhandStock::pendingReturnQuantity($onhand);

            if ((int) $validated['quantity'] < ($soldQuantity + $approvedReturnQuantity + $pendingReturnQuantity)) {
                throw ValidationException::withMessages([
                    'quantity' => 'Quantity tidak boleh lebih kecil dari total barang yang sudah terjual atau diproses retur.',
                ]);
            }

            if ($soldQuantity > 0) {
                if ((int) $validated['user_id'] !== (int) $onhand->user_id) {
                    throw ValidationException::withMessages([
                        'user_id' => 'Onhand yang sudah memiliki penjualan tidak bisa dipindahkan ke user lain.',
                    ]);
                }

                if ((int) $validated['id_product'] !== (int) $onhand->id_product) {
                    throw ValidationException::withMessages([
                        'id_product' => 'Onhand yang sudah memiliki penjualan tidak bisa diganti produknya.',
                    ]);
                }

                if ($validated['take_status'] !== $onhand->take_status) {
                    throw ValidationException::withMessages([
                        'take_status' => 'Status ambil tidak bisa diubah karena onhand ini sudah memiliki penjualan.',
                    ]);
                }
            }

            if ($validated['take_status'] !== 'disetujui' && ($approvedReturnQuantity > 0 || $pendingReturnQuantity > 0)) {
                throw ValidationException::withMessages([
                    'take_status' => 'Status ambil tidak bisa diubah karena onhand ini sudah memiliki proses retur.',
                ]);
            }

            $oldLockedStock = $this->lockedStockForTakeStatus(
                $onhand->take_status,
                (int) $onhand->quantity,
                $approvedReturnQuantity
            );
            $newLockedStock = $this->lockedStockForTakeStatus(
                $validated['take_status'],
                (int) $validated['quantity'],
                $approvedReturnQuantity
            );

            if ((int) $validated['id_product'] === (int) $onhand->id_product) {
                $product = Product::query()->lockForUpdate()->findOrFail($onhand->id_product);
                $availableStock = (int) $product->stock + $oldLockedStock;

                if ($availableStock < $newLockedStock) {
                    throw ValidationException::withMessages([
                        'quantity' => 'Stock product tidak mencukupi untuk perubahan onhand ini.',
                    ]);
                }

                $product->update([
                    'stock' => $availableStock - $newLockedStock,
                ]);
            } else {
                $oldProduct = Product::query()->lockForUpdate()->findOrFail($onhand->id_product);
                $newProduct = Product::query()->lockForUpdate()->findOrFail($validated['id_product']);

                if ((int) $newProduct->stock < $newLockedStock) {
                    throw ValidationException::withMessages([
                        'quantity' => 'Stock product baru tidak mencukupi untuk perubahan onhand ini.',
                    ]);
                }

                $oldProduct->increment('stock', $oldLockedStock);

                if ($newLockedStock > 0) {
                    $newProduct->decrement('stock', $newLockedStock);
                }
            }

            $productName = Product::query()->findOrFail($validated['id_product'])->nama_product;

            $onhand->update([
                'user_id' => $user->id_user,
                'id_product' => (int) $validated['id_product'],
                'nama_product' => $productName,
                'quantity' => (int) $validated['quantity'],
                'take_status' => $validated['take_status'],
                'assignment_date' => $validated['assignment_date'],
                'take_approved_by' => $validated['take_status'] === 'pending'
                    ? null
                    : $request->user()->id_user,
                'take_reviewed_at' => $validated['take_status'] === 'pending'
                    ? null
                    : now(),
            ]);
        });

        return redirect()
            ->route('product-onhands.index', $this->redirectFilters($request))
            ->with('success', 'Barang onhand berhasil diperbarui.');
    }

    public function updateSoldQuantity(Request $request, ProductOnhand $onhand): RedirectResponse
    {
        abort_unless($request->user()?->role === 'superadmin', 403);

        $validated = $request->validate([
            'sold_quantity' => ['required', 'integer', 'min:0'],
        ]);

        DB::transaction(function () use ($validated, $onhand): void {
            $onhand = ProductOnhand::query()->lockForUpdate()->findOrFail($onhand->id_product_onhand);

            if ($onhand->take_status !== 'disetujui') {
                throw ValidationException::withMessages([
                    'sold_quantity' => 'Barang terjual hanya bisa diatur untuk onhand yang sudah disetujui.',
                ]);
            }

            $actualSoldQuantity = ProductOnhandStock::actualSoldQuantity($onhand);
            $maxSoldQuantity = ProductOnhandStock::maxSoldQuantity($onhand);
            $targetSoldQuantity = (int) $validated['sold_quantity'];

            if ($targetSoldQuantity < $actualSoldQuantity) {
                throw ValidationException::withMessages([
                    'sold_quantity' => 'Jumlah terjual tidak boleh lebih kecil dari penjualan offline yang sudah tercatat.',
                ]);
            }

            if ($targetSoldQuantity > $maxSoldQuantity) {
                throw ValidationException::withMessages([
                    'sold_quantity' => 'Jumlah terjual melebihi quantity onhand yang tersedia setelah retur.',
                ]);
            }

            $onhand->update([
                'manual_sold_quantity' => $targetSoldQuantity - $actualSoldQuantity,
            ]);
        });

        return redirect()
            ->route('product-onhands.index', $this->redirectFilters($request))
            ->with('success', 'Barang terjual berhasil diperbarui.');
    }

    public function destroy(Request $request, ProductOnhand $onhand): RedirectResponse
    {
        abort_unless($request->user()?->role === 'superadmin', 403);

        DB::transaction(function () use ($onhand): void {
            $onhand = ProductOnhand::query()
                ->withCount('offlineSales')
                ->lockForUpdate()
                ->findOrFail($onhand->id_product_onhand);

            if ($this->soldQuantity($onhand) > 0) {
                throw ValidationException::withMessages([
                    'delete' => 'Onhand yang sudah memiliki barang terjual tidak bisa dihapus.',
                ]);
            }

            if ((int) $onhand->quantity_dikembalikan > 0 || ProductOnhandStock::approvedReturnQuantity($onhand) > 0) {
                throw ValidationException::withMessages([
                    'delete' => 'Onhand yang sudah memiliki proses retur tidak bisa dihapus.',
                ]);
            }

            $lockedStock = $this->lockedStockForTakeStatus(
                $onhand->take_status,
                (int) $onhand->quantity,
                0
            );

            if ($lockedStock > 0) {
                $product = Product::query()->lockForUpdate()->findOrFail($onhand->id_product);
                $product->increment('stock', $lockedStock);
            }

            $onhand->delete();
        });

        return redirect()
            ->route('product-onhands.index', $this->redirectFilters($request))
            ->with('success', 'Barang onhand berhasil dihapus.');
    }

    private function validatePayload(Request $request): array
    {
        return $request->validate([
            'user_id' => ['required', 'integer'],
            'id_product' => ['required', 'integer', 'exists:products,id_product'],
            'quantity' => ['required', 'integer', 'min:1'],
            'assignment_date' => ['required', 'date'],
            'take_status' => ['required', Rule::in(['pending', 'disetujui', 'ditolak'])],
        ]);
    }

    private function resolveTargetUser(int $userId): User
    {
        $user = User::query()->findOrFail($userId);

        if (! in_array($user->role, ['marketing', 'reseller'], true)) {
            throw ValidationException::withMessages([
                'user_id' => 'User onhand harus marketing atau reseller.',
            ]);
        }

        return $user;
    }

    private function transformOnhand(ProductOnhand $onhand): array
    {
        $actualSoldQuantity = ProductOnhandStock::actualSoldQuantity($onhand);
        $manualSoldQuantity = ProductOnhandStock::manualSoldQuantity($onhand);
        $soldQuantity = $actualSoldQuantity + $manualSoldQuantity;
        $approvedReturnQuantity = ProductOnhandStock::approvedReturnQuantity($onhand);
        $pendingReturnQuantity = ProductOnhandStock::pendingReturnQuantity($onhand);
        $remainingQuantity = $onhand->take_status === 'disetujui'
            ? ProductOnhandStock::availableQuantity($onhand)
            : 0;

        return [
            'id_product_onhand' => $onhand->id_product_onhand,
            'user_id' => $onhand->user_id,
            'user_name' => $onhand->user?->nama,
            'user_role' => $onhand->user?->role,
            'id_product' => $onhand->id_product,
            'nama_product' => $onhand->nama_product,
            'quantity' => (int) $onhand->quantity,
            'sold_quantity' => $soldQuantity,
            'actual_sold_quantity' => $actualSoldQuantity,
            'manual_sold_quantity' => $manualSoldQuantity,
            'minimum_sold_quantity' => $actualSoldQuantity,
            'maximum_sold_quantity' => ProductOnhandStock::maxSoldQuantity($onhand),
            'quantity_dikembalikan' => (int) $onhand->quantity_dikembalikan,
            'approved_return_quantity' => $approvedReturnQuantity,
            'pending_return_quantity' => $pendingReturnQuantity,
            'remaining_quantity' => $remainingQuantity,
            'assignment_date' => optional($onhand->assignment_date)->format('Y-m-d'),
            'take_status' => $onhand->take_status,
            'take_status_label' => $this->takeStatusLabel($onhand->take_status),
            'return_status' => $onhand->return_status,
            'return_status_label' => $this->returnStatusLabel($onhand->return_status),
            'sales_count' => (int) ($onhand->offline_sales_count ?? 0),
            'can_delete' => $soldQuantity === 0
                && (int) $onhand->quantity_dikembalikan === 0
                && $approvedReturnQuantity === 0,
        ];
    }

    private function soldQuantity(ProductOnhand $onhand): int
    {
        return ProductOnhandStock::soldQuantity($onhand);
    }

    private function lockedStockForTakeStatus(string $takeStatus, int $quantity, int $approvedReturnQuantity): int
    {
        if ($takeStatus !== 'disetujui') {
            return 0;
        }

        return max($quantity - $approvedReturnQuantity, 0);
    }

    private function takeStatusLabel(string $status): string
    {
        return match ($status) {
            'pending' => 'Pending',
            'ditolak' => 'Ditolak',
            default => 'Disetujui',
        };
    }

    private function returnStatusLabel(string $status): string
    {
        return match ($status) {
            'pending' => 'Pending',
            'disetujui' => 'Disetujui',
            'tidak_disetujui' => 'Tidak Disetujui',
            default => 'Belum',
        };
    }

    private function redirectFilters(Request $request): array
    {
        return array_filter([
            'search' => trim((string) $request->input('search', '')) ?: null,
            'user_id' => $request->input('user_id') ?: null,
            'take_status' => trim((string) $request->input('take_status_filter', '')) ?: null,
        ], fn ($value) => $value !== null && $value !== '');
    }
}
