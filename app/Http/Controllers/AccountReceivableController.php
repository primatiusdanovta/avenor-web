<?php

namespace App\Http\Controllers;

use App\Models\AccountReceivable;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class AccountReceivableController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorizePermission($request, 'account_receivables.view');

        return Inertia::render('AccountReceivables/Index', [
            'accountReceivables' => AccountReceivable::query()
                ->where('store_id', $this->currentStoreId($request))
                ->latest('due_date')
                ->latest('id')
                ->get()
                ->map(fn (AccountReceivable $receivable) => [
                    'id' => $receivable->id,
                    'receivable_name' => $receivable->receivable_name,
                    'place_name' => $receivable->place_name,
                    'consignment_date' => optional($receivable->consignment_date)->format('Y-m-d'),
                    'due_date' => optional($receivable->due_date)->format('Y-m-d'),
                    'consigned_value' => (float) ($receivable->consigned_value ?? 0),
                    'total_value' => (float) $receivable->total_value,
                    'status' => $receivable->status,
                    'items_summary' => $receivable->items_summary,
                    'notes' => $receivable->notes,
                    'created_at' => optional($receivable->created_at)->format('Y-m-d H:i:s'),
                ])
                ->values(),
        ]);
    }
}
