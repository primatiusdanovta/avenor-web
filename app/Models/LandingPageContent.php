<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Collection;

class LandingPageContent extends Model
{
    use HasFactory;

    protected $fillable = [
        'section_name',
        'title',
        'description',
        'image_path',
        'is_active',
        'meta_data',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'meta_data' => 'array',
        ];
    }

    public static function ensureDefaults(): void
    {
        if (static::query()->exists()) {
            return;
        }

        foreach (static::defaultRows() as $row) {
            static::query()->create($row);
        }
    }

    public static function defaultRows(): array
    {
        return [
            [
                'section_name' => 'hero',
                'title' => 'Avenor Nocturne',
                'description' => 'A fragrance study in gold, smoke, and midnight florals. Crafted as a modern luxury ritual for the senses.',
                'image_path' => null,
                'is_active' => true,
                'meta_data' => [
                    'badge' => 'Maison Avenor',
                    'eyebrow' => 'Modern Dark Luxury',
                    'cta_label' => 'Discover The Notes',
                    'cta_href' => '#notes-journey',
                    'secondary_label' => 'View Ingredients',
                    'secondary_href' => '#ingredients-bento',
                ],
            ],
            [
                'section_name' => 'story',
                'title' => 'A fragrance revealed in three luminous movements.',
                'description' => 'From the first sparkling release to the warm resinous trail, each accord is designed to unfold like a private gallery experience.',
                'image_path' => null,
                'is_active' => true,
                'meta_data' => [
                    'kicker' => 'Narrative Scroll',
                ],
            ],
            [
                'section_name' => 'top_notes',
                'title' => 'Top Notes',
                'description' => 'Bergamot zest, pink pepper, and saffron shimmer with a cold metallic glow before melting into skin.',
                'image_path' => null,
                'is_active' => true,
                'meta_data' => [
                    'order' => 1,
                    'short_label' => 'Top',
                    'accent' => '#d4af37',
                ],
            ],
            [
                'section_name' => 'heart_notes',
                'title' => 'Heart Notes',
                'description' => 'Dark rose and jasmine sambac bloom at the center, softened by incense smoke and velvet woods.',
                'image_path' => null,
                'is_active' => true,
                'meta_data' => [
                    'order' => 2,
                    'short_label' => 'Heart',
                    'accent' => '#b7922f',
                ],
            ],
            [
                'section_name' => 'base_notes',
                'title' => 'Base Notes',
                'description' => 'Amber, sandalwood, and patchouli settle into a long, tactile finish with warm leather depth.',
                'image_path' => null,
                'is_active' => true,
                'meta_data' => [
                    'order' => 3,
                    'short_label' => 'Base',
                    'accent' => '#8d6a1f',
                ],
            ],
            [
                'section_name' => 'ingredients_intro',
                'title' => 'Ingredient Bento',
                'description' => 'A precise composition of rare textures, sparkling spices, and lingering woods.',
                'image_path' => null,
                'is_active' => true,
                'meta_data' => [
                    'kicker' => 'Tap to Reveal',
                ],
            ],
            [
                'section_name' => 'ingredient',
                'title' => 'Saffron Thread',
                'description' => 'Adds a radiant, suede-like heat and metallic glow in the opening accord.',
                'image_path' => null,
                'is_active' => true,
                'meta_data' => [
                    'key' => 'ingredient-saffron-thread',
                    'icon' => 'spark',
                    'order' => 1,
                ],
            ],
            [
                'section_name' => 'ingredient',
                'title' => 'Rose Absolute',
                'description' => 'A deep floral heart that feels lush, nocturnal, and quietly dramatic.',
                'image_path' => null,
                'is_active' => true,
                'meta_data' => [
                    'key' => 'ingredient-rose-absolute',
                    'icon' => 'bloom',
                    'order' => 2,
                ],
            ],
            [
                'section_name' => 'ingredient',
                'title' => 'Sandalwood',
                'description' => 'Brings creamy depth and a polished, skin-close finish to the dry down.',
                'image_path' => null,
                'is_active' => true,
                'meta_data' => [
                    'key' => 'ingredient-sandalwood',
                    'icon' => 'wood',
                    'order' => 3,
                ],
            ],
            [
                'section_name' => 'ingredient',
                'title' => 'Pink Pepper',
                'description' => 'Lifts the composition with crisp sparkle and subtle contemporary spice.',
                'image_path' => null,
                'is_active' => true,
                'meta_data' => [
                    'key' => 'ingredient-pink-pepper',
                    'icon' => 'pepper',
                    'order' => 4,
                ],
            ],
            [
                'section_name' => 'ingredient',
                'title' => 'Amber Resin',
                'description' => 'Creates an enveloping glow that lingers with warmth and golden density.',
                'image_path' => null,
                'is_active' => true,
                'meta_data' => [
                    'key' => 'ingredient-amber-resin',
                    'icon' => 'amber',
                    'order' => 5,
                ],
            ],
            [
                'section_name' => 'ingredient',
                'title' => 'Incense Smoke',
                'description' => 'Adds a dark ceremonial trail that turns the scent into an atmosphere.',
                'image_path' => null,
                'is_active' => true,
                'meta_data' => [
                    'key' => 'ingredient-incense-smoke',
                    'icon' => 'smoke',
                    'order' => 6,
                ],
            ],
        ];
    }

    public static function groupedForFrontend(): array
    {
        static::ensureDefaults();

        $rows = static::sortedRows();

        $singleSections = $rows
            ->filter(fn (self $row) => $row->section_name !== 'ingredient')
            ->keyBy('section_name');

        $notes = collect(['top_notes', 'heart_notes', 'base_notes'])
            ->map(fn (string $key) => static::transformRow($singleSections->get($key)))
            ->filter()
            ->values()
            ->all();

        return [
            'hero' => static::transformRow($singleSections->get('hero')),
            'story' => static::transformRow($singleSections->get('story')),
            'notes' => $notes,
            'ingredients_intro' => static::transformRow($singleSections->get('ingredients_intro')),
            'ingredients' => $rows
                ->filter(fn (self $row) => $row->section_name === 'ingredient')
                ->map(fn (self $row) => static::transformRow($row))
                ->values()
                ->all(),
            'visibility' => [
                'hero' => (bool) ($singleSections->get('hero')?->is_active ?? true),
                'story' => (bool) ($singleSections->get('story')?->is_active ?? true),
                'notes' => collect(['top_notes', 'heart_notes', 'base_notes'])->contains(fn (string $key) => (bool) ($singleSections->get($key)?->is_active ?? false)),
                'ingredients' => (bool) ($singleSections->get('ingredients_intro')?->is_active ?? true),
            ],
        ];
    }

    public static function groupedForManager(): array
    {
        static::ensureDefaults();

        $rows = static::sortedRows();
        $singleSections = $rows
            ->filter(fn (self $row) => $row->section_name !== 'ingredient')
            ->keyBy('section_name');

        return [
            'hero' => static::transformRow($singleSections->get('hero')),
            'story' => static::transformRow($singleSections->get('story')),
            'notes' => collect(['top_notes', 'heart_notes', 'base_notes'])
                ->mapWithKeys(fn (string $key) => [$key => static::transformRow($singleSections->get($key))])
                ->all(),
            'ingredients_intro' => static::transformRow($singleSections->get('ingredients_intro')),
            'ingredients' => $rows
                ->filter(fn (self $row) => $row->section_name === 'ingredient')
                ->sortBy(fn (self $row) => (int) data_get($row->meta_data, 'order', 999))
                ->values()
                ->map(fn (self $row) => static::transformRow($row))
                ->all(),
            'visibility' => [
                'hero' => (bool) ($singleSections->get('hero')?->is_active ?? true),
                'story' => (bool) ($singleSections->get('story')?->is_active ?? true),
                'notes' => collect(['top_notes', 'heart_notes', 'base_notes'])->contains(fn (string $key) => (bool) ($singleSections->get($key)?->is_active ?? false)),
                'ingredients' => (bool) ($singleSections->get('ingredients_intro')?->is_active ?? true),
            ],
        ];
    }

    private static function transformRow(?self $row): ?array
    {
        if (! $row) {
            return null;
        }

        return [
            'id' => $row->id,
            'section_name' => $row->section_name,
            'title' => $row->title,
            'description' => $row->description,
            'image_path' => $row->image_path,
            'is_active' => (bool) $row->is_active,
            'meta_data' => $row->meta_data ?? [],
        ];
    }

    private static function sortedRows(): Collection
    {
        return static::query()
            ->orderBy('section_name')
            ->orderBy('id')
            ->get()
            ->sortBy([
                fn (self $row) => $row->section_name,
                fn (self $row) => (int) data_get($row->meta_data, 'order', 999),
                fn (self $row) => $row->id,
            ])
            ->values();
    }
}
