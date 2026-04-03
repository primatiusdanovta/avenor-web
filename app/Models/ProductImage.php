<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ProductImage extends Model
{
    use HasFactory;

    protected $fillable = [
        'product_id',
        'image_path',
        'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'sort_order' => 'integer',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'product_id', 'id_product');
    }

    public function getNormalizedImagePathAttribute(): ?string
    {
        if (! $this->image_path || Str::startsWith($this->image_path, ['http://', 'https://'])) {
            return null;
        }

        return ltrim(Str::replaceFirst('storage/', '', str_replace('\\', '/', (string) $this->image_path)), '/');
    }

    public function getPublicUrlAttribute(): ?string
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

        return route('product-images.public', [
            'image' => $this,
            'v' => md5((string) $this->image_path),
        ]);
    }
}
