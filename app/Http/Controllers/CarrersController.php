<?php

namespace App\Http\Controllers;

use App\Models\GlobalSetting;
use App\Support\SeoSchemaBuilder;
use Illuminate\Contracts\View\View;

class CarrersController extends Controller
{
    public function __invoke(): View
    {
        $socialHub = GlobalSetting::masterSocialHub();
        $careersPage = data_get($socialHub, 'careers_page', []);
        $hero = data_get($careersPage, 'hero', []);
        $seoTitle = trim(((string) data_get($hero, 'eyebrow', 'Carrers')) . ' | ' . ((string) data_get($hero, 'title', 'Join Avenor')), ' |');
        $seoDescription = (string) data_get($hero, 'description', '');

        return view('landing', [
            'pageType' => 'carrers',
            'initialContent' => [
                'page_type' => 'carrers',
                'social_hub' => $socialHub,
                'careers_page' => $careersPage,
                'tracking' => [
                    'ga4_measurement_id' => config('services.analytics.ga4_measurement_id'),
                    'facebook_pixel_id' => config('services.meta.pixel_id'),
                ],
            ],
            'fallbackContent' => [
                'page_type' => 'carrers',
                'social_hub' => $socialHub,
                'careers_page' => $careersPage,
            ],
            'seo' => [
                'title' => $seoTitle,
                'description' => $seoDescription,
                'meta_keywords' => 'avenor careers, lowongan avenor, karir parfum, career perfume brand, recruitment avenor',
                'canonical_url' => url('/carrers'),
                'robots' => 'index,follow',
                'author' => 'Avenor Perfume',
                'og_title' => $seoTitle,
                'og_description' => $seoDescription,
                'og_image' => asset('img/logo.png'),
                'og_image_alt' => 'Avenor Careers',
                'twitter_site' => '@avenorperfume',
                'twitter_creator' => '@avenorperfume',
                'article' => [
                    'section' => 'Careers',
                ],
            ],
            'schemas' => [
                SeoSchemaBuilder::organization(),
                [
                    '@context' => 'https://schema.org',
                    '@type' => 'CollectionPage',
                    'name' => $seoTitle,
                    'url' => url('/carrers'),
                    'description' => $seoDescription,
                ],
            ],
            'tracking' => [
                'ga4_measurement_id' => config('services.analytics.ga4_measurement_id'),
                'facebook_pixel_id' => config('services.meta.pixel_id'),
            ],
        ]);
    }
}
