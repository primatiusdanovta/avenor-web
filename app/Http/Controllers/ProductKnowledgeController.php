<?php

namespace App\Http\Controllers;

use App\Models\FragranceDetail;
use App\Models\Product;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class ProductKnowledgeController extends Controller
{
    public function index(Request $request): Response
    {
        $storeId = $this->currentStoreId($request);
        $isSmoothiesSweetie = $this->isSmoothiesSweetieStore($request);

        $products = Product::query()
            ->with(['fragranceDetails', 'images'])
            ->where('store_id', $storeId)
            ->orderByDesc('created_at')
            ->orderByDesc('id_product')
            ->get()
            ->map(fn (Product $product) => [
                'id_product' => $product->id_product,
                'nama_product' => $product->nama_product,
                'gambar' => $product->public_image_url,
                'image_url' => $product->public_image_url,
                'deskripsi' => $product->deskripsi,
                'created_at' => optional($product->created_at)->format('Y-m-d H:i:s'),
                'fragrance_details' => $product->fragranceDetails
                    ->sortBy(['jenis', 'detail'])
                    ->map(fn (FragranceDetail $detail) => [
                        'id_fd' => $detail->id_fd,
                        'jenis' => $detail->jenis,
                        'detail' => $detail->detail,
                        'deskripsi' => $detail->deskripsi,
                    ])
                    ->values(),
            ])
            ->values();

        $filters = $isSmoothiesSweetie
            ? collect()
            : FragranceDetail::query()
                ->orderBy('jenis')
                ->orderBy('detail')
                ->get()
                ->groupBy('jenis')
                ->map(fn ($items, $jenis) => [
                    'jenis' => $jenis,
                    'details' => $items->map(fn (FragranceDetail $detail) => [
                        'id_fd' => $detail->id_fd,
                        'detail' => $detail->detail,
                        'deskripsi' => $detail->deskripsi,
                    ])->values(),
                ])
                ->values();

        return Inertia::render('Products/Knowledge', [
            'products' => $products,
            'fragranceFilters' => $filters,
            'isSmoothiesSweetie' => $isSmoothiesSweetie,
        ]);
    }
}
