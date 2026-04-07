<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\Consignment;
use App\Models\ConsignmentItem;
use App\Support\AccountReceivableSupport;
use App\Support\MarketingMobileSupport;
use App\Support\SalesRole;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ConsignmentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user?->role === SalesRole::SALES_FIELD_EXECUTIVE, 403);

        $products = collect();
        $onhands = \App\Models\ProductOnhand::query()
            ->with('user')
            ->where('user_id', $user->id_user)
            ->where('take_status', 'disetujui')
            ->orderByDesc('assignment_date')
            ->orderByDesc('id_product_onhand')
            ->get();

        $products = $onhands
            ->map(function ($onhand) {
                $available = MarketingMobileSupport::availableForOnhand($onhand);

                return [
                    'id_product_onhand' => $onhand->id_product_onhand,
                    'id_product' => $onhand->id_product,
                    'nama_product' => $onhand->nama_product,
                    'pickup_batch_code' => $onhand->pickup_batch_code,
                    'available_quantity' => $available,
                    'option_label' => $onhand->nama_product . ' | batch ' . ($onhand->pickup_batch_code ?: '-') . ' | sisa ' . $available,
                ];
            })
            ->filter(fn (array $item) => $item['available_quantity'] > 0)
            ->values();

        $consignments = Consignment::query()
            ->with('items')
            ->where('user_id', $user->id_user)
            ->latest('submitted_at')
            ->latest('id')
            ->limit(30)
            ->get()
            ->map(fn (Consignment $consignment) => $this->transformConsignment($consignment))
            ->values();

        return response()->json([
            'products' => $products,
            'consignments' => $consignments,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user?->role === SalesRole::SALES_FIELD_EXECUTIVE, 403);

        $validated = $request->validate([
            'place_name' => ['required', 'string', 'max:255'],
            'address' => ['required', 'string', 'max:2000'],
            'consignment_date' => ['required', 'date'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'handover_proof_photo' => ['required', 'image', 'max:4096'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_onhand_id' => ['required', 'distinct', 'exists:product_onhands,id_product_onhand'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
        ]);

        $proofPath = $request->file('handover_proof_photo')?->store('consignments', 'public');
        $consignment = DB::transaction(function () use ($validated, $user, $proofPath) {
            $consignment = Consignment::query()->create([
                'user_id' => $user->id_user,
                'place_name' => $validated['place_name'],
                'address' => $validated['address'],
                'consignment_date' => $validated['consignment_date'],
                'submitted_at' => now(),
                'latitude' => $validated['latitude'],
                'longitude' => $validated['longitude'],
                'handover_proof_photo' => $proofPath,
            ]);

            foreach ($validated['items'] as $item) {
                $onhand = \App\Models\ProductOnhand::query()
                    ->with('user')
                    ->where('id_product_onhand', $item['product_onhand_id'])
                    ->where('user_id', $user->id_user)
                    ->lockForUpdate()
                    ->firstOrFail();

                $available = MarketingMobileSupport::availableForOnhand($onhand);
                abort_if($available < (int) $item['quantity'], 422, 'Quantity consign melebihi stok batch yang tersedia.');

                ConsignmentItem::query()->create([
                    'consignment_id' => $consignment->id,
                    'product_onhand_id' => $onhand->id_product_onhand,
                    'product_id' => $onhand->id_product,
                    'product_name' => $onhand->nama_product,
                    'pickup_batch_code' => $onhand->pickup_batch_code,
                    'quantity' => (int) $item['quantity'],
                    'sold_quantity' => 0,
                    'returned_quantity' => 0,
                    'status' => 'dititipkan',
                ]);
            }

            AccountReceivableSupport::syncFromConsignment($consignment->fresh('items'));

            return $consignment->fresh('items');
        });

        return response()->json([
            'message' => 'Consign berhasil disimpan.',
            'consignment' => $this->transformConsignment($consignment),
        ], 201);
    }

    public function updateItem(Request $request, ConsignmentItem $item): JsonResponse
    {
        $user = $request->user();
        abort_unless($user?->role === SalesRole::SALES_FIELD_EXECUTIVE, 403);

        $item->loadMissing('consignment');
        abort_unless((int) $item->consignment?->user_id === (int) $user->id_user, 403);

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

        $item->refresh();
        $item->loadMissing('consignment');

        return response()->json([
            'message' => 'Status consign berhasil diperbarui.',
            'item' => [
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
            ],
            'consignment' => $this->transformConsignment($item->consignment()->with('items')->firstOrFail()),
        ]);
    }

    private function transformConsignment(Consignment $consignment): array
    {
        return [
            'id' => $consignment->id,
            'place_name' => $consignment->place_name,
            'address' => $consignment->address,
            'consignment_date' => optional($consignment->consignment_date)->format('Y-m-d'),
            'submitted_at' => optional($consignment->submitted_at)->format('Y-m-d H:i:s'),
            'latitude' => (float) $consignment->latitude,
            'longitude' => (float) $consignment->longitude,
            'handover_proof_photo_url' => $consignment->handover_proof_photo ? Storage::disk('public')->url($consignment->handover_proof_photo) : null,
            'items' => $consignment->items->map(fn (ConsignmentItem $item) => [
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
            ])->values(),
        ];
    }
}
