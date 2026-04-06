<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ProductOnhand extends Model
{
    use HasFactory;

    protected $primaryKey = 'id_product_onhand';
    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'id_product',
        'nama_product',
        'quantity',
        'quantity_dikembalikan',
        'approved_return_quantity',
        'manual_sold_quantity',
        'take_status',
        'return_status',
        'approved_by',
        'take_approved_by',
        'assignment_date',
        'created_at',
        'take_requested_at',
        'take_reviewed_at',
    ];

    protected function casts(): array
    {
        return [
            'quantity' => 'integer',
            'quantity_dikembalikan' => 'integer',
            'approved_return_quantity' => 'integer',
            'manual_sold_quantity' => 'integer',
            'assignment_date' => 'date',
            'created_at' => 'datetime',
            'take_requested_at' => 'datetime',
            'take_reviewed_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id', 'id_user');
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'id_product', 'id_product');
    }

    public function offlineSales(): HasMany
    {
        return $this->hasMany(OfflineSale::class, 'id_product_onhand', 'id_product_onhand');
    }
}

