<?php

namespace App\Models;

use App\Models\Concerns\DefaultsToAvenorStore;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class Product extends Model
{
    use DefaultsToAvenorStore, HasFactory;

    protected $primaryKey = 'id_product';
    public $timestamps = false;

    protected $fillable = [
        'store_id',
        'nama_product',
        'harga',
        'harga_modal',
        'stock',
        'gambar',
        'bottle_image',
        'deskripsi',
        'landing_page_active',
        'seo_title',
        'seo_description',
        'canonical_url',
        'landing_theme_key',
        'landing_seo_fallback_key',
        'top_notes_text',
        'heart_notes_text',
        'base_notes_text',
        'education_content',
        'faq_data',
        'educational_blocks',
        'narrative_scroll',
    ];

    protected $appends = [
        'landing_slug',
    ];

    protected function casts(): array
    {
        return [
            'harga' => 'decimal:2',
            'harga_modal' => 'decimal:2',
            'landing_page_active' => 'boolean',
            'education_content' => 'array',
            'faq_data' => 'array',
            'educational_blocks' => 'array',
            'narrative_scroll' => 'array',
            'created_at' => 'datetime',
        ];
    }

    public function images(): HasMany
    {
        return $this->hasMany(ProductImage::class, 'product_id', 'id_product')
            ->orderBy('sort_order')
            ->orderBy('id');
    }

    public function onhands(): HasMany
    {
        return $this->hasMany(ProductOnhand::class, 'id_product', 'id_product');
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function hppCalculation(): HasOne
    {
        return $this->hasOne(HppCalculation::class, 'id_product', 'id_product');
    }

    public function variants(): HasMany
    {
        return $this->hasMany(ProductVariant::class, 'product_id', 'id_product')
            ->orderByDesc('is_default')
            ->orderBy('name');
    }

    public function fragranceDetails(): BelongsToMany
    {
        return $this->belongsToMany(FragranceDetail::class, 'product_fragrance_details', 'id_product', 'id_fd', 'id_product', 'id_fd');
    }

    public function getLandingSlugAttribute(): string
    {
        return Str::slug((string) $this->nama_product);
    }

    public function getPublicImageUrlAttribute(): ?string
    {
        $primaryGalleryImage = $this->images->first();

        if ($primaryGalleryImage?->public_url) {
            return $primaryGalleryImage->public_url;
        }

        if (! $this->gambar) {
            return null;
        }

        if (Str::startsWith($this->gambar, ['http://', 'https://'])) {
            return $this->gambar;
        }

        if (! $this->normalized_image_path || ! Storage::disk('public')->exists($this->normalized_image_path)) {
            return null;
        }

        return route('products.public-image', [
            'product' => $this,
            'v' => md5((string) $this->gambar),
        ]);
    }

    public function getNormalizedImagePathAttribute(): ?string
    {
        if (! $this->gambar || Str::startsWith($this->gambar, ['http://', 'https://'])) {
            return null;
        }

        return ltrim(Str::replaceFirst('storage/', '', str_replace('\\', '/', (string) $this->gambar)), '/');
    }

    public function getPublicBottleImageUrlAttribute(): ?string
    {
        if (! $this->bottle_image) {
            return null;
        }

        if (Str::startsWith($this->bottle_image, ['http://', 'https://'])) {
            return $this->bottle_image;
        }

        if (! $this->normalized_bottle_image_path || ! Storage::disk('public')->exists($this->normalized_bottle_image_path)) {
            return null;
        }

        return route('products.public-bottle-image', [
            'product' => $this,
            'v' => md5((string) $this->bottle_image),
        ]);
    }

    public function getNormalizedBottleImagePathAttribute(): ?string
    {
        if (! $this->bottle_image || Str::startsWith($this->bottle_image, ['http://', 'https://'])) {
            return null;
        }

        return ltrim(Str::replaceFirst('storage/', '', str_replace('\\', '/', (string) $this->bottle_image)), '/');
    }

    public function getGalleryImageUrlsAttribute(): array
    {
        $urls = $this->images
            ->map(fn (ProductImage $image) => $image->public_url)
            ->filter()
            ->values()
            ->all();

        if ($urls !== []) {
            return $urls;
        }

        return $this->public_image_url ? [$this->public_image_url] : [];
    }
}
