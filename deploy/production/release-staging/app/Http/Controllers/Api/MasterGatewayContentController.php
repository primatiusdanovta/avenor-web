<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GlobalSetting;
use App\Models\Product;
use App\Support\ProductLandingData;
use Illuminate\Http\JsonResponse;

class MasterGatewayContentController extends Controller
{
    public function __invoke(): JsonResponse
    {
        $products = Product::query()
            ->with('fragranceDetails')
            ->orderBy('nama_product')
            ->get()
            ->map(fn (Product $product) => [
                'id_product' => $product->id_product,
                'name' => $product->nama_product,
                'slug' => $product->landing_slug,
                'price' => (float) $product->harga,
                'stock' => (int) $product->stock,
                'image_url' => $product->public_image_url,
                'is_active' => (bool) $product->landing_page_active,
                'url' => url('/product/' . $product->landing_slug),
                'scent_tags' => ProductLandingData::scentTags($product),
            ])
            ->values()
            ->all();

        $socialHub = GlobalSetting::masterSocialHub();
        $masterPage = data_get($socialHub, 'master_page', []);

        return response()->json([
            'page_type' => 'master',
            'hero' => [
                'title' => data_get($masterPage, 'hero.title'),
                'eyebrow' => data_get($masterPage, 'hero.eyebrow'),
                'description' => data_get($masterPage, 'hero.description'),
                'video_url' => data_get($socialHub, 'hero_video_url'),
            ],
            'products' => $products,
            'social_hub' => $socialHub,
            'tracking' => [
                'ga4_measurement_id' => config('services.analytics.ga4_measurement_id'),
                'facebook_pixel_id' => config('services.meta.pixel_id'),
            ],
        ]);
    }
}

