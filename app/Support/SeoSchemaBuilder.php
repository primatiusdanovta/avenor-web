<?php

namespace App\Support;

use App\Models\Product;

class SeoSchemaBuilder
{
    public static function product(Product $product, array $seo, array $faqItems = []): array
    {
        $schemas = [[
            '@context' => 'https://schema.org',
            '@type' => 'Product',
            'name' => $product->nama_product,
            'description' => $seo['description'] ?? '',
            'image' => $seo['og_image'] ?? asset('img/logo.png'),
            'url' => $seo['canonical_url'] ?? url()->current(),
            'brand' => [
                '@type' => 'Brand',
                'name' => 'Avenor Perfume',
            ],
            'offers' => [
                '@type' => 'Offer',
                'priceCurrency' => 'IDR',
                'price' => (float) $product->harga,
                'availability' => $product->stock > 0 ? 'https://schema.org/InStock' : 'https://schema.org/OutOfStock',
            ],
        ]];

        $faqSchema = static::faq($faqItems);
        if ($faqSchema) {
            $schemas[] = $faqSchema;
        }

        return $schemas;
    }

    public static function faq(array $faqItems): ?array
    {
        $mainEntity = collect($faqItems)
            ->map(fn ($item) => [
                '@type' => 'Question',
                'name' => trim((string) data_get($item, 'question', '')),
                'acceptedAnswer' => [
                    '@type' => 'Answer',
                    'text' => trim((string) data_get($item, 'answer', '')),
                ],
            ])
            ->filter(fn (array $item) => filled($item['name']) && filled(data_get($item, 'acceptedAnswer.text')))
            ->values()
            ->all();

        if (! $mainEntity) {
            return null;
        }

        return [
            '@context' => 'https://schema.org',
            '@type' => 'FAQPage',
            'mainEntity' => $mainEntity,
        ];
    }
}
