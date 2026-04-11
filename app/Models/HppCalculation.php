<?php

namespace App\Models;

use App\Models\Concerns\DefaultsToAvenorStore;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class HppCalculation extends Model
{
    use DefaultsToAvenorStore, HasFactory;

    protected $primaryKey = 'id_hpp';

    public $timestamps = false;

    protected $fillable = [
        'store_id',
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

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }
}
