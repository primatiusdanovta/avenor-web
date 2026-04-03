<?php

namespace App\Support;

use App\Models\FragranceDetail;
use App\Models\GlobalSetting;
use App\Models\Product;
use Illuminate\Support\Arr;
use Illuminate\Support\Str;

class ProductLandingData
{
    public static function findActiveProductBySlug(string $slug): ?Product
    {
        return Product::query()
            ->with(['fragranceDetails', 'images'])
            ->get()
            ->first(fn (Product $product) => $product->landing_slug === $slug);
    }

    public static function firstActiveProduct(): ?Product
    {
        return Product::query()
            ->orderBy('nama_product')
            ->first();
    }

    public static function buildPayload(Product $product): array
    {
        $socialHub = GlobalSetting::masterSocialHub();
        $productPage = data_get($socialHub, 'product_page', GlobalSetting::defaultMasterSocialHub()['product_page']);
        $theme = static::resolveTheme($product, $productPage);
        $education = static::normalizeEducationContent($product, $productPage);
        $faqItems = static::normalizeFaqData($product);
        $seo = static::buildSeo($product, $productPage);
        $bottle = static::resolveBottleConfig($productPage, $product);
        [$storySection, $noteSections] = static::resolveNarrativeSections($product, $productPage, $theme, $bottle);

        return [
            'product' => [
                'id_product' => $product->id_product,
                'name' => $product->nama_product,
                'slug' => $product->landing_slug,
                'price' => (float) $product->harga,
                'stock' => (int) $product->stock,
                'description' => $product->deskripsi,
                'image_url' => $product->public_image_url,
                'images' => $product->gallery_image_urls,
                'bottle_image_url' => $product->public_bottle_image_url,
                'whatsapp_url' => static::whatsAppUrl($product, $socialHub),
                'theme_key' => $product->landing_theme_key ?: data_get($productPage, 'default_theme_key'),
                'seo_fallback_key' => $product->landing_seo_fallback_key ?: data_get($productPage, 'default_seo_fallback_key'),
            ],
            'hero' => [
                'is_active' => true,
                'title' => $product->nama_product,
                'description' => $product->deskripsi ?: data_get($productPage, 'hero.description_fallback'),
                'meta_data' => [
                    'eyebrow' => data_get($theme, 'eyebrow') ?: data_get($productPage, 'hero.eyebrow_default'),
                    'badge' => data_get($productPage, 'hero.badge'),
                    'price_label' => data_get($productPage, 'hero.price_label'),
                    'stock_label' => data_get($productPage, 'hero.stock_label'),
                    'stock_ready_suffix' => data_get($productPage, 'hero.stock_ready_suffix'),
                    'stock_preorder_label' => data_get($productPage, 'hero.stock_preorder_label'),
                    'cta_label' => data_get($productPage, 'hero.primary_cta_label'),
                    'cta_href' => data_get($productPage, 'hero.primary_cta_href'),
                    'secondary_label' => data_get($productPage, 'hero.secondary_cta_label'),
                    'secondary_href' => data_get($productPage, 'hero.secondary_cta_href'),
                    'whatsapp_label' => data_get($productPage, 'hero.whatsapp_label'),
                    'buy_options_label' => data_get($productPage, 'hero.buy_options_label'),
                    'share_facebook_label' => data_get($productPage, 'hero.share_facebook_label'),
                    'share_instagram_label' => data_get($productPage, 'hero.share_instagram_label'),
                    'share_tiktok_label' => data_get($productPage, 'hero.share_tiktok_label'),
                    'bottle' => $bottle,
                ],
            ],
            'story' => $storySection,
            'notes' => $noteSections,
            'ingredients_intro' => [
                'is_active' => true,
                'title' => data_get($productPage, 'ingredients.title'),
                'description' => static::applyTemplate((string) data_get($productPage, 'ingredients.description_template'), $product),
                'meta_data' => [
                    'kicker' => data_get($productPage, 'ingredients.section_kicker'),
                    'card_eyebrow' => data_get($productPage, 'ingredients.card_eyebrow'),
                ],
            ],
            'ingredients' => $product->fragranceDetails
                ->sortBy(['jenis', 'detail'])
                ->values()
                ->map(fn (FragranceDetail $detail) => [
                    'id' => $detail->id_fd,
                    'title' => $detail->detail,
                    'description' => $detail->deskripsi ?: data_get($productPage, 'ingredients.item_fallback_description'),
                    'is_active' => true,
                    'meta_data' => [
                        'icon' => static::iconForDetailType($detail->jenis),
                    ],
                ])
                ->all(),
            'education' => [
                'is_active' => true,
                'title' => data_get($education, 'title'),
                'description' => data_get($education, 'body'),
                'meta_data' => [
                    'kicker' => data_get($productPage, 'education.section_kicker'),
                    'card_eyebrow' => data_get($productPage, 'education.card_eyebrow'),
                    'tips' => data_get($education, 'tips', []),
                ],
            ],
            'faq' => $faqItems,
            'ui_labels' => [
                'navigation' => [
                    'home_label' => data_get($productPage, 'navigation.home_label'),
                    'brand_label' => data_get($productPage, 'navigation.brand_label'),
                    'collection_label' => data_get($productPage, 'navigation.collection_label'),
                    'discovery_label' => data_get($productPage, 'navigation.discovery_label'),
                    'contact_label' => data_get($productPage, 'navigation.contact_label'),
                ],
                'faq' => [
                    'kicker' => data_get($productPage, 'faq.kicker'),
                    'title' => data_get($productPage, 'faq.title'),
                    'description' => data_get($productPage, 'faq.description'),
                ],
                'marketplace' => [
                    'title' => data_get($productPage, 'marketplace.title'),
                    'tokopedia_label' => data_get($productPage, 'marketplace.tokopedia_label'),
                    'tiktok_shop_label' => data_get($productPage, 'marketplace.tiktok_shop_label'),
                    'empty_state' => data_get($productPage, 'marketplace.empty_state'),
                ],
                'sticky_cta' => [
                    'label' => data_get($productPage, 'sticky_cta.label'),
                ],
                'system_messages' => [
                    'loading' => data_get($productPage, 'system_messages.loading'),
                    'error' => data_get($productPage, 'system_messages.error'),
                ],
                'share_text_prefix' => data_get($productPage, 'hero.share_text_prefix'),
            ],
            'seo' => $seo,
            'schemas' => SeoSchemaBuilder::product($product, $seo, $faqItems),
            'theme' => $theme,
            'tracking' => [
                'ga4_measurement_id' => config('services.analytics.ga4_measurement_id'),
                'facebook_pixel_id' => config('services.meta.pixel_id'),
            ],
            'social_hub' => $socialHub,
        ];
    }

    public static function buildSeo(Product $product, ?array $productPage = null): array
    {
        $productPage ??= data_get(GlobalSetting::masterSocialHub(), 'product_page', GlobalSetting::defaultMasterSocialHub()['product_page']);
        $seoPreset = static::resolveSeoFallback($product, $productPage);
        $canonicalUrl = $product->canonical_url ?: url('/product/' . $product->landing_slug);
        $title = $product->seo_title ?: static::applyTemplate((string) data_get($seoPreset, 'title_template'), $product);
        $description = $product->seo_description ?: static::applyTemplate((string) data_get($seoPreset, 'description_template'), $product);
        $ogTitle = static::applyTemplate((string) data_get($seoPreset, 'og_title_template', data_get($seoPreset, 'title_template')), $product);
        $ogDescription = static::applyTemplate((string) data_get($seoPreset, 'og_description_template', data_get($seoPreset, 'description_template')), $product);
        $image = $product->public_image_url ?: data_get($seoPreset, 'og_image_url');

        return [
            'title' => $title,
            'description' => Str::limit($description, 160, ''),
            'meta_keywords' => static::buildProductKeywords($product),
            'canonical_url' => $canonicalUrl,
            'robots' => data_get($seoPreset, 'robots'),
            'author' => 'Avenor Perfume',
            'og_title' => $ogTitle,
            'og_description' => Str::limit($ogDescription, 200, ''),
            'og_image' => $image,
            'og_image_alt' => $product->nama_product,
            'twitter_site' => '@avenorperfume',
            'twitter_creator' => '@avenorperfume',
            'product' => [
                'brand' => 'Avenor Perfume',
                'availability' => $product->stock > 0 ? 'in stock' : 'preorder',
                'price' => [
                    'amount' => number_format((float) $product->harga, 0, '.', ''),
                    'currency' => 'IDR',
                ],
            ],
        ];
    }

    private static function fallbackNoteText(Product $product, string $type, array $productPage): string
    {
        $matched = $product->fragranceDetails
            ->first(fn (FragranceDetail $detail) => Str::lower((string) $detail->jenis) === $type);

        if ($matched) {
            return $matched->deskripsi ?: trim($matched->detail . ' ' . data_get($productPage, 'notes.detail_fallback_suffix'));
        }

        return match ($type) {
            'top' => (string) data_get($productPage, 'notes.top_fallback_description'),
            'middle' => (string) data_get($productPage, 'notes.middle_fallback_description'),
            default => (string) data_get($productPage, 'notes.base_fallback_description'),
        };
    }

    private static function normalizeEducationContent(Product $product, array $productPage): array
    {
        $content = $product->educational_blocks ?: $product->education_content;

        if (is_array($content)) {
            return [
                'title' => data_get($content, 'title', data_get($productPage, 'education.default_title')),
                'body' => data_get($content, 'body', data_get($productPage, 'education.default_description')),
                'tips' => collect(data_get($content, 'tips', data_get($productPage, 'education.default_tips', [])))
                    ->filter(fn ($tip) => filled($tip))
                    ->values()
                    ->all(),
            ];
        }

        return [
            'title' => (string) data_get($productPage, 'education.default_title'),
            'body' => (string) data_get($productPage, 'education.default_description'),
            'tips' => collect(data_get($productPage, 'education.default_tips', []))
                ->filter(fn ($tip) => filled($tip))
                ->values()
                ->all(),
        ];
    }

    private static function normalizeFaqData(Product $product): array
    {
        return collect($product->faq_data ?? [])
            ->map(fn ($item) => [
                'question' => trim((string) data_get($item, 'question', '')),
                'answer' => trim((string) data_get($item, 'answer', '')),
            ])
            ->filter(fn (array $item) => filled($item['question']) && filled($item['answer']))
            ->values()
            ->all();
    }

    private static function resolveBottleConfig(array $productPage, Product $product): array
    {
        return [
            'image_url' => $product->public_bottle_image_url,
            'use_product_image_when_available' => (bool) data_get($productPage, 'story.bottle.use_product_image_when_available', true),
            'floating_mobile' => (bool) data_get($productPage, 'story.bottle.floating_mobile', true),
            'tilt_desktop' => (bool) data_get($productPage, 'story.bottle.tilt_desktop', true),
            'show_glow' => (bool) data_get($productPage, 'story.bottle.show_glow', true),
            'show_shadow' => (bool) data_get($productPage, 'story.bottle.show_shadow', true),
            'show_liquid' => (bool) data_get($productPage, 'story.bottle.show_liquid', true),
            'show_label' => (bool) data_get($productPage, 'story.bottle.show_label', true),
            'brand_label' => (string) data_get($productPage, 'story.bottle.brand_label', 'AVENOR'),
            'cap_top' => (string) data_get($productPage, 'story.bottle.cap_top', '#f3e5b0'),
            'cap_middle' => (string) data_get($productPage, 'story.bottle.cap_middle', '#d4af37'),
            'cap_bottom' => (string) data_get($productPage, 'story.bottle.cap_bottom', '#8d6a1f'),
            'liquid_from' => (string) data_get($productPage, 'story.bottle.liquid_from', 'rgba(241,215,122,.12)'),
            'liquid_to' => (string) data_get($productPage, 'story.bottle.liquid_to', 'rgba(212,175,55,.52)'),
            'label_background' => (string) data_get($productPage, 'story.bottle.label_background', 'rgba(10,10,10,.34)'),
            'label_border' => (string) data_get($productPage, 'story.bottle.label_border', 'rgba(212,175,55,.18)'),
        ];
    }

    private static function resolveTheme(Product $product, array $productPage): array
    {
        $themePresets = data_get($productPage, 'theme_presets', []);
        $preferredKey = static::normalizePresetKey($product->landing_theme_key ?: data_get($productPage, 'default_theme_key'));

        return data_get($themePresets, $preferredKey, Arr::first($themePresets, default: []));
    }

    private static function resolveSeoFallback(Product $product, array $productPage): array
    {
        $fallbacks = data_get($productPage, 'seo_fallbacks', []);
        $preferredKey = static::normalizePresetKey($product->landing_seo_fallback_key ?: data_get($productPage, 'default_seo_fallback_key'));

        return data_get($fallbacks, $preferredKey, Arr::first($fallbacks, default: []));
    }

    public static function themeOptions(array $productPage): array
    {
        return collect(data_get($productPage, 'theme_presets', []))
            ->map(fn (array $preset, string $key) => [
                'value' => $key,
                'label' => data_get($preset, 'label', Str::headline($key)),
            ])
            ->values()
            ->all();
    }

    public static function seoFallbackOptions(array $productPage): array
    {
        return collect(data_get($productPage, 'seo_fallbacks', []))
            ->map(fn (array $preset, string $key) => [
                'value' => $key,
                'label' => data_get($preset, 'label', Str::headline($key)),
            ])
            ->values()
            ->all();
    }

    public static function scentTags(Product $product, int $limit = 3): array
    {
        $haystack = Str::lower(implode(' ', array_filter([
            $product->nama_product,
            $product->deskripsi,
            $product->top_notes_text,
            $product->heart_notes_text,
            $product->base_notes_text,
            $product->fragranceDetails->pluck('detail')->implode(' '),
        ])));

        $tagMap = [
            'Woody' => ['wood', 'woody', 'sandal', 'cedar', 'amber', 'patchouli', 'oud', 'leather'],
            'Fresh' => ['fresh', 'citrus', 'bergamot', 'aquatic', 'marine', 'ocean', 'clean', 'mint'],
            'Sweet' => ['sweet', 'vanilla', 'caramel', 'praline', 'honey', 'sugar', 'tonka'],
            'Floral' => ['floral', 'rose', 'jasmine', 'bloom', 'lily', 'peony', 'white flower'],
            'Musky' => ['musk', 'musky', 'powdery'],
            'Spicy' => ['spicy', 'pepper', 'cardamom', 'cinnamon', 'clove'],
            'Smoky' => ['smoky', 'smoke', 'incense'],
            'Fruity' => ['fruity', 'berry', 'apple', 'pear', 'peach', 'plum'],
            'Green' => ['green', 'herbal', 'tea', 'leaf', 'grass'],
        ];

        $tags = collect($tagMap)
            ->filter(fn (array $keywords) => Str::contains($haystack, $keywords))
            ->keys()
            ->take($limit)
            ->values();

        if ($tags->isEmpty()) {
            $tags = collect(['Signature']);
        }

        return $tags->all();
    }

    private static function iconForDetailType(?string $type): string
    {
        return match (Str::lower((string) $type)) {
            'top' => 'citrus',
            'middle', 'heart' => 'bloom',
            'base' => 'wood',
            default => 'spark',
        };
    }

    private static function whatsAppUrl(Product $product, array $socialHub = []): string
    {
        $productPage = data_get($socialHub, 'product_page', GlobalSetting::defaultMasterSocialHub()['product_page']);
        $messageTemplate = (string) data_get($productPage, 'contact.whatsapp_message_template');
        $message = rawurlencode(static::applyTemplate($messageTemplate, $product));
        $configuredUrl = (string) data_get($socialHub, 'product_whatsapp_url', '');

        if ($configuredUrl === '') {
            $configuredUrl = (string) data_get($socialHub, 'whatsapp_url', '');
        }

        if ($configuredUrl !== '') {
            $separator = str_contains($configuredUrl, '?') ? '&' : '?';

            return $configuredUrl . $separator . 'text=' . $message;
        }

        $phone = preg_replace('/\D+/', '', (string) env('LANDING_WHATSAPP_NUMBER', ''));

        return $phone
            ? 'https://wa.me/' . $phone . '?text=' . $message
            : 'https://wa.me/?text=' . $message;
    }

    private static function applyTemplate(string $template, Product $product): string
    {
        return str_replace('{product_name}', $product->nama_product, $template);
    }

    private static function buildProductKeywords(Product $product): string
    {
        $keywords = collect([
            $product->nama_product,
            'Avenor Perfume',
            'parfum premium',
            'luxury fragrance',
            ...$product->fragranceDetails->pluck('detail')->all(),
            ...static::scentTags($product, 5),
        ])
            ->map(fn ($item) => trim((string) $item))
            ->filter()
            ->unique()
            ->values();

        return $keywords->implode(', ');
    }

    private static function normalizePresetKey(?string $value): string
    {
        return Str::of((string) $value)->trim()->lower()->replace(' ', '_')->value();
    }

    private static function resolveNarrativeSections(Product $product, array $productPage, array $theme, array $bottle): array
    {
        $narrative = $product->narrative_scroll ?? [];
        $stages = collect(data_get($narrative, 'stages', []))
            ->map(function ($item, $index) use ($theme) {
                $accents = [
                    data_get($theme, 'accent'),
                    data_get($theme, 'accentSoft'),
                    data_get($theme, 'accentDeep'),
                ];

                return [
                    'section_name' => trim((string) data_get($item, 'section_name', 'stage_' . ($index + 1))),
                    'title' => trim((string) data_get($item, 'title', '')),
                    'description' => trim((string) data_get($item, 'description', '')),
                    'is_active' => data_get($item, 'is_active', true) !== false,
                    'meta_data' => [
                        'accent' => data_get($item, 'accent', $accents[$index % count($accents)]),
                    ],
                ];
            })
            ->filter(fn (array $item) => filled($item['title']) && filled($item['description']))
            ->values()
            ->all();

        if ($stages !== []) {
            return [[
                'is_active' => true,
                'title' => trim((string) data_get($narrative, 'title', static::applyTemplate((string) data_get($productPage, 'story.title_template'), $product))),
                'description' => trim((string) data_get($narrative, 'description', data_get($productPage, 'story.description'))),
                'meta_data' => [
                    'kicker' => trim((string) data_get($narrative, 'kicker', data_get($productPage, 'story.kicker'))),
                    'bottle_fallback_name' => data_get($productPage, 'story.bottle_fallback_name'),
                    'bottle' => $bottle,
                ],
            ], $stages];
        }

        return [[
            'is_active' => true,
            'title' => static::applyTemplate((string) data_get($productPage, 'story.title_template'), $product),
            'description' => data_get($productPage, 'story.description'),
            'meta_data' => [
                'kicker' => data_get($productPage, 'story.kicker'),
                'bottle_fallback_name' => data_get($productPage, 'story.bottle_fallback_name'),
                'bottle' => $bottle,
            ],
        ], [
            [
                'section_name' => 'top_notes',
                'title' => data_get($productPage, 'notes.top_title'),
                'description' => $product->top_notes_text ?: static::fallbackNoteText($product, 'top', $productPage),
                'is_active' => true,
                'meta_data' => ['accent' => data_get($theme, 'accent')],
            ],
            [
                'section_name' => 'heart_notes',
                'title' => data_get($productPage, 'notes.middle_title'),
                'description' => $product->heart_notes_text ?: static::fallbackNoteText($product, 'middle', $productPage),
                'is_active' => true,
                'meta_data' => ['accent' => data_get($theme, 'accentSoft')],
            ],
            [
                'section_name' => 'base_notes',
                'title' => data_get($productPage, 'notes.base_title'),
                'description' => $product->base_notes_text ?: static::fallbackNoteText($product, 'base', $productPage),
                'is_active' => true,
                'meta_data' => ['accent' => data_get($theme, 'accentDeep')],
            ],
        ]];
    }
}
