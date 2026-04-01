<?php

namespace App\Http\Controllers;

use App\Models\FragranceDetail;
use App\Models\GlobalSetting;
use App\Models\Product;
use App\Support\ProductLandingData;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class LandingPageBuilderController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $productPage = data_get(GlobalSetting::masterSocialHub(), 'product_page', GlobalSetting::defaultMasterSocialHub()['product_page']);

        $products = Product::query()
            ->with('fragranceDetails')
            ->orderBy('nama_product')
            ->get()
            ->map(fn (Product $product) => [
                'id_product' => $product->id_product,
                'nama_product' => $product->nama_product,
                'landing_slug' => $product->landing_slug,
                'landing_page_active' => (bool) $product->landing_page_active,
                'seo_title' => $product->seo_title,
                'seo_description' => $product->seo_description,
                'canonical_url' => $product->canonical_url,
                'landing_theme_key' => $product->landing_theme_key ?: data_get($productPage, 'default_theme_key'),
                'landing_seo_fallback_key' => $product->landing_seo_fallback_key ?: data_get($productPage, 'default_seo_fallback_key'),
                'top_notes_text' => $product->top_notes_text,
                'heart_notes_text' => $product->heart_notes_text,
                'base_notes_text' => $product->base_notes_text,
                'education_content' => ($product->educational_blocks ?: $product->education_content) ?? [
                    'title' => data_get($productPage, 'education.default_title'),
                    'body' => '',
                    'tips' => [],
                ],
                'faq_data' => $product->faq_data ?? [],
                'preview_url' => url('/product/' . $product->landing_slug),
                'fragrance_details' => $product->fragranceDetails
                    ->sortBy(['jenis', 'detail'])
                    ->map(fn (FragranceDetail $detail) => [
                        'id_fd' => $detail->id_fd,
                        'jenis' => $detail->jenis,
                        'detail' => $detail->detail,
                    ])
                    ->values(),
            ])
            ->values();

        return Inertia::render('LandingPageBuilder/Index', [
            'products' => $products,
            'themeOptions' => ProductLandingData::themeOptions($productPage),
            'seoFallbackOptions' => ProductLandingData::seoFallbackOptions($productPage),
        ]);
    }

    public function update(Request $request, Product $product): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $validated = $request->validate([
            'landing_page_active' => ['required', 'boolean'],
            'seo_title' => ['nullable', 'string', 'max:255'],
            'seo_description' => ['nullable', 'string', 'max:5000'],
            'canonical_url' => ['nullable', 'string', 'max:2048'],
            'landing_theme_key' => ['nullable', 'string', 'max:100'],
            'landing_seo_fallback_key' => ['nullable', 'string', 'max:100'],
            'top_notes_text' => ['nullable', 'string', 'max:5000'],
            'heart_notes_text' => ['nullable', 'string', 'max:5000'],
            'base_notes_text' => ['nullable', 'string', 'max:5000'],
            'education_content' => ['nullable', 'array'],
            'education_content.title' => ['nullable', 'string', 'max:255'],
            'education_content.body' => ['nullable', 'string', 'max:10000'],
            'education_content.tips' => ['nullable', 'array'],
            'education_content.tips.*' => ['nullable', 'string', 'max:500'],
            'faq_data' => ['nullable', 'array'],
            'faq_data.*.question' => ['nullable', 'string', 'max:1000'],
            'faq_data.*.answer' => ['nullable', 'string', 'max:5000'],
        ]);

        $product->update([
            'landing_page_active' => (bool) $validated['landing_page_active'],
            'seo_title' => $validated['seo_title'] ?: null,
            'seo_description' => $validated['seo_description'] ?: null,
            'canonical_url' => $validated['canonical_url'] ?: null,
            'landing_theme_key' => $validated['landing_theme_key'] ?: null,
            'landing_seo_fallback_key' => $validated['landing_seo_fallback_key'] ?: null,
            'top_notes_text' => $validated['top_notes_text'] ?: null,
            'heart_notes_text' => $validated['heart_notes_text'] ?: null,
            'base_notes_text' => $validated['base_notes_text'] ?: null,
            'educational_blocks' => [
                'title' => data_get($validated, 'education_content.title'),
                'body' => data_get($validated, 'education_content.body'),
                'tips' => collect(data_get($validated, 'education_content.tips', []))
                    ->filter(fn ($tip) => filled($tip))
                    ->values()
                    ->all(),
            ],
            'education_content' => [
                'title' => data_get($validated, 'education_content.title'),
                'body' => data_get($validated, 'education_content.body'),
                'tips' => collect(data_get($validated, 'education_content.tips', []))
                    ->filter(fn ($tip) => filled($tip))
                    ->values()
                    ->all(),
            ],
            'faq_data' => collect(data_get($validated, 'faq_data', []))
                ->map(fn ($item) => [
                    'question' => trim((string) data_get($item, 'question', '')),
                    'answer' => trim((string) data_get($item, 'answer', '')),
                ])
                ->filter(fn ($item) => filled($item['question']) && filled($item['answer']))
                ->values()
                ->all(),
        ]);

        return redirect()->route('landing-page-builder.index')->with('success', 'Landing page variant berhasil diperbarui.');
    }
}
