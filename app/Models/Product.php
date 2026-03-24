<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Product extends Model
{
    use HasFactory;

    protected $primaryKey = 'id_product';
    public $timestamps = false;

    protected $fillable = ['nama_product', 'harga', 'harga_modal', 'stock', 'gambar'];

    protected function casts(): array
    {
        return [
            'harga' => 'decimal:2',
            'harga_modal' => 'decimal:2',
            'created_at' => 'datetime',
        ];
    }

    public function onhands(): HasMany
    {
        return $this->hasMany(ProductOnhand::class, 'id_product', 'id_product');
    }
}