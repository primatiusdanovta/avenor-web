<?php

namespace App\Http\Controllers;

use App\Models\Article;
use App\Models\GlobalSetting;
use App\Support\SeoSchemaBuilder;
use Illuminate\Contracts\View\View;
use Illuminate\Http\Request;

class ArticlesLandingController extends Controller
{
    public function __invoke(Request $request): View
    {
        $articles = Article::query()
            ->where('is_published', true)
            ->orderByDesc('published_at')
            ->orderByDesc('created_at')
            ->paginate(5)
            ->through(fn (Article $article) => [
                'title' => $article->title,
                'slug' => $article->slug,
                'excerpt' => $article->excerpt,
                'author' => $article->author,
                'published_at' => optional($article->published_at)->translatedFormat('d M Y'),
                'image_url' => $article->public_image_url ?: asset('img/logo.png'),
                'url' => url('/article/' . $article->slug),
            ]);

        $socialHub = GlobalSetting::masterSocialHub();
        $seoTitle = 'Article | Avenor Perfume';
        $seoDescription = 'Editorial notes, fragrance stories, and discovery articles from Avenor Perfume.';

        $currentPage = max(1, (int) $request->integer('page', 1));
        $canonicalUrl = $currentPage > 1 ? url('/articles?page=' . $currentPage) : url('/articles');

        return view('landing', [
            'pageType' => 'articles',
            'initialContent' => [
                'page_type' => 'articles',
                'social_hub' => $socialHub,
                'articles_page' => [
                    'hero' => [
                        'eyebrow' => 'Journal',
                        'title' => 'Stories that slow the scroll and deepen discovery.',
                        'description' => 'A curated line of articles about scent mood, ritual, and the details behind the Avenor atmosphere.',
                    ],
                    'pagination' => [
                        'current_page' => $articles->currentPage(),
                        'last_page' => $articles->lastPage(),
                        'prev_page_url' => $articles->previousPageUrl(),
                        'next_page_url' => $articles->nextPageUrl(),
                        'from' => $articles->firstItem(),
                        'to' => $articles->lastItem(),
                        'total' => $articles->total(),
                    ],
                    'cards' => $articles->items(),
                ],
                'tracking' => [
                    'ga4_measurement_id' => config('services.analytics.ga4_measurement_id'),
                    'facebook_pixel_id' => config('services.meta.pixel_id'),
                ],
            ],
            'fallbackContent' => [
                'page_type' => 'articles',
                'social_hub' => $socialHub,
                'articles_page' => [
                    'hero' => [
                        'eyebrow' => 'Journal',
                        'title' => 'Stories that slow the scroll and deepen discovery.',
                        'description' => 'A curated line of articles about scent mood, ritual, and the details behind the Avenor atmosphere.',
                    ],
                    'pagination' => [
                        'current_page' => 1,
                        'last_page' => 1,
                        'prev_page_url' => null,
                        'next_page_url' => null,
                        'from' => null,
                        'to' => null,
                        'total' => 0,
                    ],
                    'cards' => [],
                ],
            ],
            'seo' => [
                'title' => $seoTitle,
                'description' => $seoDescription,
                'meta_keywords' => 'avenor article, parfum article, fragrance journal, avenor perfume journal',
                'canonical_url' => $canonicalUrl,
                'robots' => 'index,follow',
                'author' => 'Avenor Perfume',
                'og_title' => $seoTitle,
                'og_description' => $seoDescription,
                'og_image' => asset('img/logo.png'),
                'og_image_alt' => 'Avenor Articles',
                'twitter_site' => '@avenorperfume',
                'twitter_creator' => '@avenorperfume',
            ],
            'schemas' => [
                SeoSchemaBuilder::organization(),
                [
                    '@context' => 'https://schema.org',
                    '@type' => 'CollectionPage',
                    'name' => $seoTitle,
                    'url' => url('/articles'),
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
