<?php

namespace App\Http\Controllers;

use App\Models\Article;
use App\Models\Product;
use Illuminate\Http\Response;

class TechnicalSeoController extends Controller
{
    public function robots(): Response
    {
        $content = implode("\n", [
            'User-agent: *',
            'Allow: /',
            'Disallow: /administrator',
            'Disallow: /administrator/',
            'Disallow: /login',
            'Sitemap: ' . url('/sitemap.xml'),
            '',
        ]);

        return response($content, 200, [
            'Content-Type' => 'text/plain; charset=UTF-8',
        ]);
    }

    public function sitemap(): Response
    {
        $staticPages = [
            [
                'loc' => url('/'),
                'changefreq' => 'daily',
                'priority' => '1.0',
                'lastmod' => now()->toAtomString(),
            ],
            [
                'loc' => url('/carrers'),
                'changefreq' => 'weekly',
                'priority' => '0.8',
                'lastmod' => now()->toAtomString(),
            ],
            [
                'loc' => url('/articles'),
                'changefreq' => 'weekly',
                'priority' => '0.8',
                'lastmod' => now()->toAtomString(),
            ],
        ];

        $productPages = Product::query()
            ->where('landing_page_active', true)
            ->orderBy('nama_product')
            ->get()
            ->map(fn (Product $product) => [
                'loc' => url('/product/' . $product->landing_slug),
                'changefreq' => 'weekly',
                'priority' => '0.9',
                'lastmod' => optional($product->created_at)->toAtomString() ?: now()->toAtomString(),
            ])
            ->values()
            ->all();

        $articlePages = Article::query()
            ->where('is_published', true)
            ->orderByDesc('published_at')
            ->get()
            ->map(fn (Article $article) => [
                'loc' => url('/article/' . $article->slug),
                'changefreq' => 'monthly',
                'priority' => '0.7',
                'lastmod' => optional($article->updated_at)->toAtomString() ?: optional($article->created_at)->toAtomString() ?: now()->toAtomString(),
            ])
            ->values()
            ->all();

        $urls = [...$staticPages, ...$productPages, ...$articlePages];

        $xml = view('seo.sitemap', [
            'urls' => $urls,
        ])->render();

        return response($xml, 200, [
            'Content-Type' => 'application/xml; charset=UTF-8',
        ]);
    }
}
