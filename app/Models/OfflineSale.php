<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OfflineSale extends Model
{
    use HasFactory;

    protected $primaryKey = 'id_penjualan_offline';
    public $timestamps = false;

    protected $fillable = [
        'id_user',
        'id_product',
        'id_product_onhand',
        'promo_id',
        'nama',
        'nama_product',
        'quantity',
        'harga',
        'kode_promo',
        'promo',
        'bukti_pembelian',
        'approval_status',
        'approved_by',
        'approved_at',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'quantity' => 'integer',
            'harga' => 'decimal:2',
            'created_at' => 'datetime',
            'approved_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'id_user', 'id_user');
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'id_product', 'id_product');
    }

    public function onhand(): BelongsTo
    {
        return $this->belongsTo(ProductOnhand::class, 'id_product_onhand', 'id_product_onhand');
    }

    public function promoModel(): BelongsTo
    {
        return $this->belongsTo(Promo::class, 'promo_id');
    }
}