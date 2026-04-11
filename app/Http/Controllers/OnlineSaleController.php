<?php

namespace App\Http\Controllers;

use App\Models\OnlineSale;
use App\Services\OnlineSaleImportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class OnlineSaleController extends Controller
{
    public function __construct(private readonly OnlineSaleImportService $importService)
    {
    }

    public function index(Request $request): Response
    {
        $this->authorizeView($request);

        $sales = OnlineSale::query()
            ->where('store_id', $this->currentStoreId($request))
            ->with('items.product.hppCalculation')
            ->orderByDesc('paid_time')
            ->orderByDesc('id')
            ->get()
            ->map(fn (OnlineSale $sale) => [
                'id' => $sale->id,
                'order_id' => $sale->order_id,
                'order_status' => $sale->order_status,
                'order_substatus' => $sale->order_substatus,
                'cancelation' => $sale->cancelation,
                'province' => $sale->province,
                'regency_city' => $sale->regency_city,
                'paid_time' => optional($sale->paid_time)->format('Y-m-d H:i:s'),
                'total_amount' => (float) $sale->total_amount,
                'items' => $sale->items->map(fn ($item) => [
                    'id' => $item->id,
                    'id_product' => $item->id_product,
                    'raw_product_name' => $item->raw_product_name,
                    'nama_product' => $item->nama_product,
                    'quantity' => (int) $item->quantity,
                    'harga' => (float) $item->harga,
                    'total_hpp' => (float) ($item->product?->hppCalculation?->total_hpp ?? $item->product?->harga_modal ?? 0),
                ])->values(),
            ])
            ->values();

        return Inertia::render('OnlineSales/Index', [
            'sales' => $sales,
        ]);
    }

    public function import(Request $request): RedirectResponse
    {
        $this->authorizeManage($request);

        $validated = $request->validate([
            'orders_file' => ['required', 'file', 'mimes:csv,xlsx,txt'],
            'income_file' => ['required', 'file', 'mimes:csv,xlsx,txt'],
        ], [
            'orders_file.required' => 'File order wajib diupload.',
            'income_file.required' => 'File income wajib diupload.',
        ]);

        $result = $this->importService->import($validated['orders_file'], $validated['income_file'], $this->currentStoreId($request));

        if (($result['imported'] ?? 0) === 0) {
            return redirect()->route('online-sales.index')->with('warning', sprintf(
                'Import selesai tetapi belum ada data yang masuk. Total order terbaca %d, %d order dilewati karena status belum selesai, %d order tidak punya pasangan income.',
                $result['total_orders'] ?? 0,
                $result['skipped'] ?? 0,
                $result['missing_income'] ?? 0,
            ));
        }

        return redirect()->route('online-sales.index')->with('success', sprintf(
            'Import selesai. %d order berhasil disimpan, %d order dilewati karena status tidak selesai, %d order dilewati karena income tidak ditemukan.',
            $result['imported'],
            $result['skipped'],
            $result['missing_income'],
        ));
    }

    public function debugImport(Request $request): JsonResponse
    {
        $this->authorizeManage($request);

        $validated = $request->validate([
            'orders_file' => ['required', 'file', 'mimes:csv,xlsx,txt'],
            'income_file' => ['required', 'file', 'mimes:csv,xlsx,txt'],
        ], [
            'orders_file.required' => 'File order wajib diupload.',
            'income_file.required' => 'File income wajib diupload.',
        ]);

        return response()->json([
            'message' => 'Debug upload berhasil dibaca. Tidak ada data yang disimpan ke database.',
            'debug' => $this->importService->debug($validated['orders_file'], $validated['income_file']),
        ]);
    }

    private function authorizeView(Request $request): void
    {
        abort_unless($request->user()->hasPermission('online_sales.view'), 403);
    }

    private function authorizeManage(Request $request): void
    {
        abort_unless($request->user()->hasPermission('online_sales.manage'), 403);
    }
}
