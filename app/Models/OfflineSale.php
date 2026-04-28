<?php

namespace App\Models;

use App\Models\Concerns\DefaultsToAvenorStore;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OfflineSale extends Model
{
    use DefaultsToAvenorStore, HasFactory;

    protected $primaryKey = 'id_penjualan_offline';
    public $timestamps = false;

    protected $fillable = [
        'store_id',
        'transaction_code',
        'sale_number',
        'id_user',
        'id_pelanggan',
        'id_product',
        'product_variant_id',
        'product_variant_name',
        'unit_price',
        'extra_topping_total',
        'extra_toppings',
        'sugar_level',
        'payment_method',
        'payment_status',
        'paid_at',
        'closed_at',
        'id_product_onhand',
        'promo_id',
        'nama',
        'nama_product',
        'quantity',
        'harga',
        'total_hpp',
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
            'total_hpp' => 'decimal:2',
            'unit_price' => 'decimal:2',
            'extra_topping_total' => 'decimal:2',
            'extra_toppings' => 'array',
            'created_at' => 'datetime',
            'approved_at' => 'datetime',
            'paid_at' => 'datetime',
            'closed_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'id_user', 'id_user');
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class, 'id_pelanggan', 'id_pelanggan');
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'id_product', 'id_product');
    }

    public function productVariant(): BelongsTo
    {
        return $this->belongsTo(ProductVariant::class, 'product_variant_id');
    }

    public function onhand(): BelongsTo
    {
        return $this->belongsTo(ProductOnhand::class, 'id_product_onhand', 'id_product_onhand');
    }

    public function promoModel(): BelongsTo
    {
        return $this->belongsTo(Promo::class, 'promo_id');
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }
}
