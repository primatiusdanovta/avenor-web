<?php

namespace App\Http\Controllers;

use App\Models\GlobalSetting;
use App\Models\Product;
use App\Support\ProductLandingData;
use Illuminate\Contracts\View\View;

class MasterGatewayController extends Controller
{
    public function __invoke(): View
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

        return view('landing', [
            'pageType' => 'master',
            'initialContent' => [
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
            ],
            'seo' => [
                'title' => 'Avenor Perfume | Discover Your Signature',
                'description' => 'Explore the full Avenor perfume collection and discover your signature scent.',
                'canonical_url' => url('/'),
                'robots' => 'index,follow',
                'og_title' => 'Avenor Perfume | Discover Your Signature',
                'og_description' => 'Explore the full Avenor perfume collection and discover your signature scent.',
                'og_image' => asset('img/logo.png'),
            ],
            'schemas' => [[
                '@context' => 'https://schema.org',
                '@type' => 'WebPage',
                'name' => 'Avenor Perfume',
                'url' => url('/'),
                'description' => 'Explore the full Avenor perfume collection and discover your signature scent.',
            ]],
            'tracking' => [
                'ga4_measurement_id' => config('services.analytics.ga4_measurement_id'),
                'facebook_pixel_id' => config('services.meta.pixel_id'),
            ],
        ]);
    }
}

