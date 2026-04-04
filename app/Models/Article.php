<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class Article extends Model
{
    use HasFactory;

    public const DEFAULT_CATEGORIES = [
        'Fragrance Guide',
        'Scent Story',
        'Layering Tips',
        'Brand Journal',
        'Product Spotlight',
    ];

    protected $fillable = [
        'title',
        'slug',
        'author',
        'category',
        'published_at',
        'excerpt',
        'body',
        'image_path',
        'seo_title',
        'seo_description',
        'seo_keywords',
        'seo_canonical_url',
        'seo_robots',
        'og_title',
        'og_description',
        'og_image_url',
        'og_image_alt',
        'is_published',
    ];

    protected $appends = [
        'public_image_url',
    ];

    protected function casts(): array
    {
        return [
            'published_at' => 'date',
            'is_published' => 'boolean',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function getNormalizedImagePathAttribute(): ?string
    {
        if (! $this->image_path || Str::startsWith($this->image_path, ['http://', 'https://'])) {
            return null;
        }

        return ltrim(Str::replaceFirst('storage/', '', str_replace('\\', '/', (string) $this->image_path)), '/');
    }

    public function getPublicImageUrlAttribute(): ?string
    {
        if (! $this->image_path) {
            return null;
        }

        if (Str::startsWith($this->image_path, ['http://', 'https://'])) {
            return $this->image_path;
        }

        if (! $this->normalized_image_path || ! Storage::disk('public')->exists($this->normalized_image_path)) {
            return null;
        }

        return route('articles.public-image', [
            'article' => $this,
            'v' => md5((string) $this->image_path),
        ]);
    }

    protected static function booted(): void
    {
        static::saving(function (Article $article): void {
            $article->slug = static::buildUniqueSlug($article->title, $article->slug, $article->id);
        });
    }

    private static function buildUniqueSlug(string $title, ?string $slug = null, ?int $ignoreId = null): string
    {
        $base = Str::slug($slug ?: $title);
        $base = $base !== '' ? $base : 'article';
        $candidate = $base;
        $suffix = 1;

        while (static::query()
            ->when($ignoreId, fn ($query) => $query->whereKeyNot($ignoreId))
            ->where('slug', $candidate)
            ->exists()) {
            $candidate = $base . '-' . $suffix;
            $suffix++;
        }

        return $candidate;
    }
}
