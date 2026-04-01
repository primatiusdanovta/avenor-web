<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OnlineSaleItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'online_sale_id',
        'id_product',
        'raw_product_name',
        'nama_product',
        'quantity',
        'harga',
        'created_at',
        'updated_at',
    ];

    protected function casts(): array
    {
        return [
            'quantity' => 'integer',
            'harga' => 'decimal:2',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function onlineSale(): BelongsTo
    {
        return $this->belongsTo(OnlineSale::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'id_product', 'id_product');
    }
}
