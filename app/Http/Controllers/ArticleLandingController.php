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

        $primaryRelated = Article::query()
            ->where('is_published', true)
            ->whereKeyNot($article->id)
            ->when($article->category, fn ($query) => $query->where('category', $article->category))
            ->orderByDesc('published_at')
            ->orderByDesc('created_at')
            ->limit(3)
            ->get();

        $fallbackRelated = collect();

        if ($primaryRelated->count() < 3) {
            $fallbackRelated = Article::query()
                ->where('is_published', true)
                ->whereKeyNot($article->id)
                ->whereNotIn('id', $primaryRelated->pluck('id'))
                ->orderByDesc('published_at')
                ->orderByDesc('created_at')
                ->limit(3 - $primaryRelated->count())
                ->get();
        }

        $relatedArticles = $primaryRelated
            ->concat($fallbackRelated)
            ->take(3)
            ->map(fn (Article $related) => [
                'title' => $related->title,
                'slug' => $related->slug,
                'excerpt' => $related->excerpt,
                'author' => $related->author,
                'category' => $related->category ?: 'Journal',
                'published_at' => optional($related->published_at)->translatedFormat('d M Y'),
                'image_url' => $related->public_image_url ?: asset('img/logo.png'),
                'url' => url('/article/' . $related->slug),
            ])
            ->values();

        $socialHub = GlobalSetting::masterSocialHub();
        $seoTitle = $article->seo_title ?: ($article->title . ' | Avenor Perfume');
        $seoDescription = $article->seo_description ?: $article->excerpt;
        $canonicalUrl = $article->seo_canonical_url ?: url('/article/' . $article->slug);
        $image = $article->og_image_url ?: ($article->public_image_url ?: asset('img/logo.png'));
        $ogTitle = $article->og_title ?: $seoTitle;
        $ogDescription = $article->og_description ?: $seoDescription;
        $robots = $article->seo_robots ?: 'index,follow';
        $keywords = trim((string) ($article->seo_keywords ?: implode(', ', array_filter([
            'article avenor perfume',
            $article->title,
            $article->author,
            $article->category,
        ]))), ', ');

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
                    'category' => $article->category ?: 'Journal',
                    'published_at' => optional($article->published_at)->translatedFormat('d F Y'),
                    'image_url' => $image,
                ],
                'related_articles' => $relatedArticles,
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
                    'category' => $article->category ?: 'Journal',
                    'published_at' => optional($article->published_at)->translatedFormat('d F Y'),
                    'image_url' => $image,
                ],
                'related_articles' => [],
            ],
            'seo' => [
                'title' => $seoTitle,
                'description' => $seoDescription,
                'meta_keywords' => $keywords,
                'canonical_url' => $canonicalUrl,
                'robots' => $robots,
                'author' => $article->author ?: 'Avenor Perfume',
                'og_title' => $ogTitle,
                'og_description' => $ogDescription,
                'og_image' => $image,
                'og_image_alt' => $article->og_image_alt ?: $article->title,
                'twitter_site' => '@avenorperfume',
                'twitter_creator' => '@avenorperfume',
                'article' => [
                    'published_time' => optional($article->published_at)->toDateString(),
                    'modified_time' => optional($article->updated_at)->toAtomString() ?: optional($article->created_at)->toAtomString(),
                    'author' => $article->author ?: 'Avenor Perfume',
                    'section' => $article->category ?: 'Article',
                ],
            ],
            'schemas' => [
                SeoSchemaBuilder::organization(),
                [
                    '@context' => 'https://schema.org',
                    '@type' => 'Article',
                    'headline' => $article->title,
                    'description' => $seoDescription,
                    'author' => [
                        '@type' => 'Person',
                        'name' => $article->author,
                    ],
                    'articleSection' => $article->category ?: 'Article',
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
