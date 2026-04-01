<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class HppCalculation extends Model
{
    use HasFactory;

    protected $primaryKey = 'id_hpp';

    public $timestamps = false;

    protected $fillable = [
        'id_product',
        'total_hpp',
        'created_at',
        'updated_at',
    ];

    protected function casts(): array
    {
        return [
            'total_hpp' => 'decimal:2',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'id_product', 'id_product');
    }

    public function items(): HasMany
    {
        return $this->hasMany(HppCalculationItem::class, 'id_hpp', 'id_hpp');
    }
}
