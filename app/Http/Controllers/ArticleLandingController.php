<?php

namespace App\Http\Controllers;

use App\Models\Article;
use App\Models\GlobalSetting;
use App\Support\ArticleContentFormatter;
use App\Support\SeoSchemaBuilder;
use Illuminate\Contracts\View\View;

class ArticleLandingController extends Controller
{
    public function __invoke(string $slug): View
    {
        $article = Article::query()
            ->where('slug', $slug)
            ->where('is_published', true)
            ->firstOrFail();

        $socialHub = GlobalSetting::masterSocialHub();
        $seoTitle = $article->title . ' | Avenor Perfume';
        $seoDescription = $article->excerpt;
        $canonicalUrl = url('/article/' . $article->slug);
        $image = $article->public_image_url ?: asset('img/logo.png');

        return view('landing', [
            'pageType' => 'article',
            'initialContent' => [
                'page_type' => 'article',
                'social_hub' => $socialHub,
                'article' => [
                    'title' => $article->title,
                    'slug' => $article->slug,
                    'excerpt' => $article->excerpt,
                    'body' => $article->body,
                    'body_html' => ArticleContentFormatter::toHtml($article->body),
                    'author' => $article->author,
                    'published_at' => optional($article->published_at)->translatedFormat('d F Y'),
                    'image_url' => $image,
                ],
                'tracking' => [
                    'ga4_measurement_id' => config('services.analytics.ga4_measurement_id'),
                    'facebook_pixel_id' => config('services.meta.pixel_id'),
                ],
            ],
            'fallbackContent' => [
                'page_type' => 'article',
                'social_hub' => $socialHub,
                'article' => [
                    'title' => $article->title,
                    'slug' => $article->slug,
                    'excerpt' => $article->excerpt,
                    'body' => $article->body,
                    'body_html' => ArticleContentFormatter::toHtml($article->body),
                    'author' => $article->author,
                    'published_at' => optional($article->published_at)->translatedFormat('d F Y'),
                    'image_url' => $image,
                ],
            ],
            'seo' => [
                'title' => $seoTitle,
                'description' => $seoDescription,
                'meta_keywords' => trim(implode(', ', array_filter([
                    'article avenor perfume',
                    $article->title,
                    $article->author,
                ])), ', '),
                'canonical_url' => $canonicalUrl,
                'robots' => 'index,follow',
                'author' => $article->author ?: 'Avenor Perfume',
                'og_title' => $seoTitle,
                'og_description' => $seoDescription,
                'og_image' => $image,
                'og_image_alt' => $article->title,
                'twitter_site' => '@avenorperfume',
                'twitter_creator' => '@avenorperfume',
                'article' => [
                    'published_time' => optional($article->published_at)->toDateString(),
                    'modified_time' => optional($article->updated_at)->toAtomString() ?: optional($article->created_at)->toAtomString(),
                    'author' => $article->author ?: 'Avenor Perfume',
                    'section' => 'Article',
                ],
            ],
            'schemas' => [
                SeoSchemaBuilder::organization(),
                [
                    '@context' => 'https://schema.org',
                    '@type' => 'Article',
                    'headline' => $article->title,
                    'description' => $article->excerpt,
                    'author' => [
                        '@type' => 'Person',
                        'name' => $article->author,
                    ],
                    'datePublished' => optional($article->published_at)->toDateString(),
                    'image' => [$image],
                    'mainEntityOfPage' => $canonicalUrl,
                    'publisher' => [
                        '@type' => 'Organization',
                        'name' => 'Avenor Perfume',
                        'logo' => [
                            '@type' => 'ImageObject',
                            'url' => asset('img/logo.png'),
                        ],
                    ],
                ],
            ],
            'tracking' => [
                'ga4_measurement_id' => config('services.analytics.ga4_measurement_id'),
                'facebook_pixel_id' => config('services.meta.pixel_id'),
            ],
        ]);
    }
}
