<?php

namespace App\Http\Controllers;

use App\Models\FragranceDetail;
use App\Models\GlobalSetting;
use App\Models\Product;
use App\Models\ProductImage;
use App\Support\ProductLandingData;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Inertia\Inertia;
use Inertia\Response;

class LandingPageBuilderController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $productPage = data_get(GlobalSetting::masterSocialHub(), 'product_page', GlobalSetting::defaultMasterSocialHub()['product_page']);

        $products = Product::query()
            ->with(['fragranceDetails', 'images'])
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
                'narrative_scroll' => $product->narrative_scroll ?? [
                    'kicker' => data_get($productPage, 'story.kicker'),
                    'title' => '',
                    'description' => '',
                    'stages' => [],
                ],
                'bottle_image_url' => $product->public_bottle_image_url,
                'gallery_images' => $product->images
                    ->map(fn (ProductImage $image) => [
                        'id' => $image->id,
                        'image_url' => $image->public_url,
                        'sort_order' => (int) $image->sort_order,
                    ])
                    ->values()
                    ->all(),
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
            'narrative_scroll' => ['nullable', 'array'],
            'narrative_scroll.kicker' => ['nullable', 'string', 'max:255'],
            'narrative_scroll.title' => ['nullable', 'string', 'max:255'],
            'narrative_scroll.description' => ['nullable', 'string', 'max:5000'],
            'narrative_scroll.stages' => ['nullable', 'array'],
            'narrative_scroll.stages.*.section_name' => ['nullable', 'string', 'max:100'],
            'narrative_scroll.stages.*.title' => ['nullable', 'string', 'max:255'],
            'narrative_scroll.stages.*.description' => ['nullable', 'string', 'max:5000'],
            'remove_bottle_image' => ['nullable', 'boolean'],
            'bottle_image' => ['nullable', 'image', 'max:4096'],
            'gallery_sequence' => ['nullable', 'array'],
            'gallery_sequence.*' => ['string', 'max:100'],
            'gallery_image_order' => ['nullable', 'array'],
            'gallery_image_order.*' => ['integer'],
            'remove_gallery_image_ids' => ['nullable', 'array'],
            'remove_gallery_image_ids.*' => ['integer'],
            'gallery_new_image_keys' => ['nullable', 'array'],
            'gallery_new_image_keys.*' => ['string', 'max:100'],
            'gallery_images' => ['nullable', 'array'],
            'gallery_images.*' => ['image', 'max:4096'],
        ]);

        $uploadedPaths = [];
        $newBottleImagePath = null;
        $oldBottleImagePath = $product->normalized_bottle_image_path;

        if ($request->hasFile('bottle_image')) {
            $newBottleImagePath = $request->file('bottle_image')->store('products/bottles', 'public');
            $uploadedPaths[] = $newBottleImagePath;
        }

        try {
            DB::transaction(function () use ($product, $validated, $request, &$uploadedPaths, $newBottleImagePath): void {
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
                    'narrative_scroll' => $this->normalizeNarrativeScroll(data_get($validated, 'narrative_scroll', [])),
                    'bottle_image' => $newBottleImagePath
                        ?: ((bool) data_get($validated, 'remove_bottle_image', false) ? null : $product->bottle_image),
                ]);

                $this->syncGalleryImages($product, $request, $validated, $uploadedPaths);
            });
        } catch (\Throwable $exception) {
            foreach ($uploadedPaths as $path) {
                if (Storage::disk('public')->exists($path)) {
                    Storage::disk('public')->delete($path);
                }
            }

            throw $exception;
        }

        if (($newBottleImagePath || (bool) data_get($validated, 'remove_bottle_image', false)) && $oldBottleImagePath && Storage::disk('public')->exists($oldBottleImagePath)) {
            Storage::disk('public')->delete($oldBottleImagePath);
        }

        return redirect()->route('landing-page-builder.index')->with('success', 'Landing page variant berhasil diperbarui.');
    }

    private function normalizeNarrativeScroll(array $narrative): ?array
    {
        $stages = collect(data_get($narrative, 'stages', []))
            ->map(function ($item, $index) {
                return [
                    'section_name' => trim((string) data_get($item, 'section_name', 'stage_' . ($index + 1))),
                    'title' => trim((string) data_get($item, 'title', '')),
                    'description' => trim((string) data_get($item, 'description', '')),
                ];
            })
            ->filter(fn (array $item) => filled($item['title']) && filled($item['description']))
            ->values()
            ->all();

        if ($stages === [] && ! filled(data_get($narrative, 'title')) && ! filled(data_get($narrative, 'description')) && ! filled(data_get($narrative, 'kicker'))) {
            return null;
        }

        return [
            'kicker' => trim((string) data_get($narrative, 'kicker', '')),
            'title' => trim((string) data_get($narrative, 'title', '')),
            'description' => trim((string) data_get($narrative, 'description', '')),
            'stages' => $stages,
        ];
    }

    private function syncGalleryImages(Product $product, Request $request, array $validated, array &$uploadedPaths): void
    {
        $existingImages = $product->images()->get()->keyBy('id');
        $removeIds = collect(data_get($validated, 'remove_gallery_image_ids', []))
            ->map(fn ($id) => (int) $id)
            ->filter()
            ->values();

        foreach ($removeIds as $id) {
            $image = $existingImages->get($id);
            if (! $image) {
                continue;
            }

            if ($image->normalized_image_path && Storage::disk('public')->exists($image->normalized_image_path)) {
                Storage::disk('public')->delete($image->normalized_image_path);
            }

            $image->delete();
        }

        $orderedIds = collect(data_get($validated, 'gallery_image_order', []))
            ->map(fn ($id) => (int) $id)
            ->filter(fn ($id) => $product->images()->whereKey($id)->exists())
            ->values();

        $remainingImages = $product->images()->orderBy('sort_order')->orderBy('id')->get();

        if ($orderedIds->isEmpty()) {
            $orderedIds = $remainingImages->pluck('id')->values();
        } else {
            $missingIds = $remainingImages->pluck('id')->diff($orderedIds);
            $orderedIds = $orderedIds->merge($missingIds)->values();
        }

        foreach ($orderedIds as $index => $id) {
            $product->images()->whereKey($id)->update([
                'sort_order' => $index + 1,
            ]);
        }

        $newKeyToImageId = [];
        $galleryFiles = collect($request->file('gallery_images', []));
        $galleryFileKeys = collect(data_get($validated, 'gallery_new_image_keys', []));

        foreach ($galleryFiles as $index => $file) {
            $path = $file->store('products/gallery', 'public');
            $uploadedPaths[] = $path;

            $created = $product->images()->create([
                'image_path' => $path,
                'sort_order' => 9999 + $index,
            ]);

            $key = (string) $galleryFileKeys->get($index, '');
            if ($key !== '') {
                $newKeyToImageId[$key] = $created->id;
            }
        }

        $sequence = collect(data_get($validated, 'gallery_sequence', []))
            ->map(function ($token) use ($newKeyToImageId) {
                $token = (string) $token;
                if (str_starts_with($token, 'existing:')) {
                    return (int) substr($token, strlen('existing:'));
                }
                if (str_starts_with($token, 'new:')) {
                    return $newKeyToImageId[substr($token, strlen('new:'))] ?? null;
                }

                return null;
            })
            ->filter()
            ->values();

        if ($sequence->isNotEmpty()) {
            foreach ($sequence as $index => $id) {
                $product->images()->whereKey($id)->update([
                    'sort_order' => $index + 1,
                ]);
            }
        }
    }
}
