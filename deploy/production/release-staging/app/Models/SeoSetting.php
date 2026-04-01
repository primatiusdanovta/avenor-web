<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SeoSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'page_key',
        'title',
        'meta_description',
        'meta_keywords',
        'canonical_url',
        'og_title',
        'og_description',
        'og_image',
        'robots',
        'schema_json',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    public static function ensureDefaults(): void
    {
        foreach (static::defaultRows() as $row) {
            static::query()->firstOrCreate(
                ['page_key' => $row['page_key']],
                $row
            );
        }
    }

    public static function defaultRows(): array
    {
        return [
            [
                'page_key' => 'landing',
                'title' => 'Avenor Perfume | Luxury Fragrance Experience',
                'meta_description' => 'Discover Avenor Perfume through a modern dark luxury landing page featuring scent stages, ingredients, and a refined fragrance narrative.',
                'meta_keywords' => 'avenor perfume, parfum mewah, luxury perfume, fragrance notes, parfum premium',
                'canonical_url' => null,
                'og_title' => 'Avenor Perfume | Luxury Fragrance Experience',
                'og_description' => 'A modern dark luxury fragrance discovery experience with immersive notes and ingredient storytelling.',
                'og_image' => null,
                'robots' => 'index,follow',
                'schema_json' => json_encode([
                    '@context' => 'https://schema.org',
                    '@type' => 'WebPage',
                    'name' => 'Avenor Perfume',
                    'description' => 'Luxury fragrance experience by Avenor Perfume.',
                ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES),
                'is_active' => true,
            ],
        ];
    }

    public static function forPage(string $pageKey): ?self
    {
        static::ensureDefaults();

        return static::query()->firstWhere('page_key', $pageKey);
    }
}
