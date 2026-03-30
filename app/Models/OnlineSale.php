<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class OnlineSale extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'order_status',
        'order_substatus',
        'cancelation',
        'province',
        'regency_city',
        'paid_time',
        'total_amount',
        'created_at',
        'updated_at',
    ];

    protected function casts(): array
    {
        return [
            'paid_time' => 'datetime',
            'total_amount' => 'decimal:2',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function items(): HasMany
    {
        return $this->hasMany(OnlineSaleItem::class);
    }
}
