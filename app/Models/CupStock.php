<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CupStock extends Model
{
    use HasFactory;

    protected $fillable = [
        'store_id',
        'stock_date',
        'variant_name',
        'stock_cup',
        'used_cup',
        'remaining_cup',
        'finalized_at',
    ];

    protected function casts(): array
    {
        return [
            'stock_date' => 'date',
            'stock_cup' => 'integer',
            'used_cup' => 'integer',
            'remaining_cup' => 'integer',
            'finalized_at' => 'datetime',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }
}
