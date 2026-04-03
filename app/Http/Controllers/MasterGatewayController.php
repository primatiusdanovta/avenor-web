<?php

namespace App\Http\Controllers;

use App\Models\GlobalSetting;
use App\Models\Product;
use App\Support\ProductLandingData;
use App\Support\SeoSchemaBuilder;
use Illuminate\Contracts\View\View;

class MasterGatewayController extends Controller
{
    public function __invoke(): View
    {
        $products = Product::query()
            ->with(['fragranceDetails', 'images'])
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
        $defaultHero = GlobalSetting::defaultMasterHero();
        $heroEyebrow = (string) data_get($masterPage, 'hero.eyebrow', data_get($defaultHero, 'eyebrow', ''));
        $heroTitle = (string) data_get($masterPage, 'hero.title', data_get($defaultHero, 'title', ''));
        $heroDescription = (string) data_get($masterPage, 'hero.description', data_get($defaultHero, 'description', ''));
        $seoTitle = trim($heroEyebrow . ' | ' . $heroTitle, ' |');

        $fallbackContent = [
            'page_type' => 'master',
            'hero' => [
                'eyebrow' => $heroEyebrow,
                'title' => $heroTitle,
                'description' => $heroDescription,
                'video_url' => data_get($socialHub, 'hero_video_url'),
            ],
            'products' => [],
            'social_hub' => $socialHub,
        ];

        return view('landing', [
            'pageType' => 'master',
            'initialContent' => [
                'page_type' => 'master',
                'hero' => [
                    'title' => $heroTitle,
                    'eyebrow' => $heroEyebrow,
                    'description' => $heroDescription,
                    'video_url' => data_get($socialHub, 'hero_video_url'),
                ],
                'products' => $products,
                'social_hub' => $socialHub,
                'tracking' => [
                    'ga4_measurement_id' => config('services.analytics.ga4_measurement_id'),
                    'facebook_pixel_id' => config('services.meta.pixel_id'),
                ],
            ],
            'fallbackContent' => $fallbackContent,
            'seo' => [
                'title' => $seoTitle,
                'description' => $heroDescription,
                'meta_keywords' => 'avenor perfume, parfum premium, parfum mewah, luxury fragrance, parfum indonesia',
                'canonical_url' => url('/'),
                'robots' => 'index,follow',
                'og_title' => $seoTitle,
                'og_description' => $heroDescription,
                'og_image' => asset('img/logo.png'),
            ],
            'schemas' => [
                SeoSchemaBuilder::organization(),
                SeoSchemaBuilder::website($heroDescription),
                [
                    '@context' => 'https://schema.org',
                    '@type' => 'WebPage',
                    'name' => $seoTitle,
                    'url' => url('/'),
                    'description' => $heroDescription,
                ],
            ],
            'tracking' => [
                'ga4_measurement_id' => config('services.analytics.ga4_measurement_id'),
                'facebook_pixel_id' => config('services.meta.pixel_id'),
            ],
        ]);
    }
}
