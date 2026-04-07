<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ConsignmentItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'consignment_id',
        'product_onhand_id',
        'product_id',
        'product_name',
        'pickup_batch_code',
        'quantity',
        'sold_quantity',
        'returned_quantity',
        'status',
        'status_notes',
    ];

    protected function casts(): array
    {
        return [
            'quantity' => 'integer',
            'sold_quantity' => 'integer',
            'returned_quantity' => 'integer',
        ];
    }

    public function consignment(): BelongsTo
    {
        return $this->belongsTo(Consignment::class);
    }

    public function onhand(): BelongsTo
    {
        return $this->belongsTo(ProductOnhand::class, 'product_onhand_id', 'id_product_onhand');
    }
}
