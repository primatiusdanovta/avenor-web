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
            static::landingDefaultRow(),
        ];
    }

    public static function forPage(string $pageKey): ?self
    {
        static::ensureDefaults();

        $record = static::query()->firstWhere('page_key', $pageKey);

        if ($pageKey !== 'landing') {
            return $record;
        }

        $defaults = static::landingDefaultRow();
        $stored = $record?->toArray() ?? ['page_key' => $pageKey];
        $normalized = static::normalizeLandingStoredValues($stored);
        $resolved = array_replace($defaults, array_filter(
            $normalized,
            static fn ($value) => $value !== null && $value !== ''
        ));

        $instance = $record ?? new static();
        $instance->forceFill($resolved);

        return $instance;
    }

    private static function landingDefaultRow(): array
    {
        $socialHub = GlobalSetting::masterSocialHub();
        $masterPage = data_get($socialHub, 'master_page', []);
        $defaultHero = GlobalSetting::defaultMasterHero();
        $heroEyebrow = (string) data_get($masterPage, 'hero.eyebrow', data_get($defaultHero, 'eyebrow', ''));
        $heroTitle = (string) data_get($masterPage, 'hero.title', data_get($defaultHero, 'title', ''));
        $heroDescription = (string) data_get($masterPage, 'hero.description', data_get($defaultHero, 'description', ''));
        $title = trim($heroEyebrow . ' | ' . $heroTitle, ' |');

        return [
            'page_key' => 'landing',
            'title' => $title,
            'meta_description' => $heroDescription,
            'meta_keywords' => 'avenor perfume, parfum mewah, luxury perfume, fragrance notes, parfum premium',
            'canonical_url' => null,
            'og_title' => $title,
            'og_description' => $heroDescription,
            'og_image' => null,
            'robots' => 'index,follow',
            'schema_json' => json_encode([
                '@context' => 'https://schema.org',
                '@type' => 'WebPage',
                'name' => $title,
                'description' => $heroDescription,
            ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE),
            'is_active' => true,
        ];
    }

    private static function normalizeLandingStoredValues(array $stored): array
    {
        $legacy = static::legacyLandingDefaults();

        foreach (['title', 'meta_description', 'og_title', 'og_description', 'schema_json'] as $field) {
            if (($stored[$field] ?? null) === ($legacy[$field] ?? null)) {
                $stored[$field] = null;
            }
        }

        return $stored;
    }

    private static function legacyLandingDefaults(): array
    {
        return [
            'title' => 'Avenor Perfume | Luxury Fragrance Experience',
            'meta_description' => 'Discover Avenor Perfume through a modern dark luxury landing page featuring scent stages, ingredients, and a refined fragrance narrative.',
            'og_title' => 'Avenor Perfume | Luxury Fragrance Experience',
            'og_description' => 'A modern dark luxury fragrance discovery experience with immersive notes and ingredient storytelling.',
            'schema_json' => json_encode([
                '@context' => 'https://schema.org',
                '@type' => 'WebPage',
                'name' => 'Avenor Perfume',
                'description' => 'Luxury fragrance experience by Avenor Perfume.',
            ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES),
        ];
    }
}
