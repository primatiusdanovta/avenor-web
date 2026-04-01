<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class Product extends Model
{
    use HasFactory;

    protected $primaryKey = 'id_product';
    public $timestamps = false;

    protected $fillable = [
        'nama_product',
        'harga',
        'harga_modal',
        'stock',
        'gambar',
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
            'created_at' => 'datetime',
        ];
    }

    public function onhands(): HasMany
    {
        return $this->hasMany(ProductOnhand::class, 'id_product', 'id_product');
    }

    public function hppCalculation(): HasOne
    {
        return $this->hasOne(HppCalculation::class, 'id_product', 'id_product');
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
        if (! $this->gambar) {
            return null;
        }

        if (Str::startsWith($this->gambar, ['http://', 'https://'])) {
            return $this->gambar;
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
}
