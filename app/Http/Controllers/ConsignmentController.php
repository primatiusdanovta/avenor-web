<?php

namespace App\Http\Controllers;

use App\Models\Consignment;
use App\Models\ConsignmentItem;
use App\Models\User;
use App\Support\AccountReceivableSupport;
use App\Support\SalesRole;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Inertia\Inertia;
use Inertia\Response;

class ConsignmentController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless(
            in_array($request->user()->role, ['superadmin', 'admin', SalesRole::SALES_FIELD_EXECUTIVE], true),
            403
        );

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
                        ->orWhereHas('items', fn ($itemQuery) => $itemQuery->where('product_name', 'like', "%{$search}%"));
                });
            })
            ->latest('submitted_at')
            ->latest('id')
            ->get()
            ->map(fn (Consignment $consignment) => [
                'id' => $consignment->id,
                'user_name' => $consignment->user?->nama,
                'place_name' => $consignment->place_name,
                'address' => $consignment->address,
                'consignment_date' => optional($consignment->consignment_date)->format('Y-m-d'),
                'submitted_at' => optional($consignment->submitted_at)->format('Y-m-d H:i:s'),
                'latitude' => (float) $consignment->latitude,
                'longitude' => (float) $consignment->longitude,
                'handover_proof_photo_url' => $consignment->handover_proof_photo ? Storage::disk('public')->url($consignment->handover_proof_photo) : null,
                'items' => $consignment->items->map(fn (ConsignmentItem $item) => [
                    'id' => $item->id,
                    'product_name' => $item->product_name,
                    'pickup_batch_code' => $item->pickup_batch_code,
                    'quantity' => (int) $item->quantity,
                    'sold_quantity' => (int) $item->sold_quantity,
                    'returned_quantity' => (int) $item->returned_quantity,
                    'status' => $item->status,
                    'status_notes' => $item->status_notes,
                ])->values(),
            ])
            ->values();

        return Inertia::render('Consignments/Index', [
            'filters' => [
                'user_id' => $selectedUserId,
                'search' => $search,
            ],
            'users' => $users,
            'consignments' => $consignments,
            'statuses' => ['dititipkan', 'dikembalikan', 'terjual'],
        ]);
    }

    public function updateItem(Request $request, ConsignmentItem $item): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        $validated = $request->validate([
            'sold_quantity' => ['required', 'integer', 'min:0'],
            'returned_quantity' => ['required', 'integer', 'min:0'],
            'status_notes' => ['nullable', 'string', 'max:2000'],
        ]);

        abort_if(((int) $validated['sold_quantity'] + (int) $validated['returned_quantity']) > (int) $item->quantity, 422, 'Jumlah terjual dan dikembalikan melebihi quantity consign.');

        DB::transaction(function () use ($item, $validated) {
            $status = 'dititipkan';
            if ((int) $validated['sold_quantity'] >= (int) $item->quantity) {
                $status = 'terjual';
            } elseif ((int) $validated['returned_quantity'] >= (int) $item->quantity) {
                $status = 'dikembalikan';
            } elseif ((int) $validated['sold_quantity'] > 0) {
                $status = 'terjual';
            } elseif ((int) $validated['returned_quantity'] > 0) {
                $status = 'dikembalikan';
            }

            $item->update([
                'sold_quantity' => (int) $validated['sold_quantity'],
                'returned_quantity' => (int) $validated['returned_quantity'],
                'status' => $status,
                'status_notes' => $validated['status_notes'] ?? null,
            ]);

            AccountReceivableSupport::syncFromConsignment($item->consignment()->firstOrFail());
        });

        return redirect()->route('consignments.index')->with('success', 'Status consign berhasil diperbarui dan account receivable disinkronkan.');
    }
}
