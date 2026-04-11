<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\FragranceDetail;
use App\Models\Product;
use App\Support\MarketingMobileSupport;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductKnowledgeController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();
        $storeId = MarketingMobileSupport::currentStoreId($user);
        $isSmoothiesSweetie = MarketingMobileSupport::isSmoothiesSweetieUser($user);

        $products = Product::query()
            ->with(['fragranceDetails', 'images'])
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
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

        return response()->json([
            'products' => $products,
            'fragrance_filters' => $filters,
            'is_smoothies_sweetie' => $isSmoothiesSweetie,
        ]);
    }
}
