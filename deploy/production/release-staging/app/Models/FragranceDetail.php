<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class FragranceDetail extends Model
{
    use HasFactory;

    protected $primaryKey = 'id_fd';
    public $timestamps = false;

    protected $fillable = [
        'jenis',
        'detail',
        'deskripsi',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
        ];
    }

    public function products(): BelongsToMany
    {
        return $this->belongsToMany(Product::class, 'product_fragrance_details', 'id_fd', 'id_product', 'id_fd', 'id_product');
    }
}
