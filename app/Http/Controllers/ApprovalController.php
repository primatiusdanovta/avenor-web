<?php

namespace App\Http\Controllers;

use App\Models\ProductOnhand;
use App\Models\User;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class ApprovalController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true) && $request->user()->hasPermission('products.approve'), 403);
        $storeId = $this->currentStoreId($request);

        $selectedId = (int) $request->integer('selected');

        $takeRequests = ProductOnhand::query()
            ->where('store_id', $storeId)
            ->with('user')
            ->where('take_status', 'pending')
            ->orderByDesc('take_requested_at')
            ->orderByDesc('id_product_onhand')
            ->get()
            ->map(fn (ProductOnhand $item) => [
                'id_product_onhand' => $item->id_product_onhand,
                'id_user' => $item->user_id,
                'nama' => $item->user?->nama,
                'role' => $item->user?->role,
                'nama_product' => $item->nama_product,
                'quantity' => (int) $item->quantity,
                'assignment_date' => optional($item->assignment_date)->format('Y-m-d'),
                'requested_at' => optional($item->take_requested_at)->format('Y-m-d H:i:s'),
            ])
            ->values();

        $returnRequests = ProductOnhand::query()
            ->where('store_id', $storeId)
            ->with('user')
            ->where('take_status', 'disetujui')
            ->where('return_status', 'pending')
            ->orderByDesc('assignment_date')
            ->orderByDesc('id_product_onhand')
            ->get()
            ->map(fn (ProductOnhand $item) => [
                'id_product_onhand' => $item->id_product_onhand,
                'id_user' => $item->user_id,
                'nama' => $item->user?->nama,
                'role' => $item->user?->role,
                'nama_product' => $item->nama_product,
                'quantity' => (int) $item->quantity,
                'quantity_dikembalikan' => (int) $item->quantity_dikembalikan,
                'assignment_date' => optional($item->assignment_date)->format('Y-m-d'),
            ])
            ->values();

        $selectedMarketing = null;
        if ($selectedId > 0) {
            $marketing = User::query()->find($selectedId);
            if ($marketing && in_array($marketing->role, ['marketing', 'sales_field_executive'], true) && $marketing->stores()->where('stores.id', $storeId)->exists()) {
                $selectedMarketing = [
                    'id_user' => $marketing->id_user,
                    'nama' => $marketing->nama,
                    'role' => $marketing->role,
                ];
            }
        }

        return Inertia::render('Approvals/Index', [
            'takeRequests' => $takeRequests,
            'returnRequests' => $returnRequests,
            'selectedMarketing' => $selectedMarketing,
        ]);
    }
}

