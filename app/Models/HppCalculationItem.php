<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HppCalculationItem extends Model
{
    use HasFactory;

    protected $primaryKey = 'id_hpp_item';

    public $timestamps = false;

    protected $fillable = [
        'id_hpp',
        'id_rm',
        'nama_rm',
        'satuan',
        'presentase',
        'harga_satuan',
        'harga_final',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'presentase' => 'decimal:2',
            'harga_satuan' => 'decimal:2',
            'harga_final' => 'decimal:2',
            'created_at' => 'datetime',
        ];
    }

    public function calculation(): BelongsTo
    {
        return $this->belongsTo(HppCalculation::class, 'id_hpp', 'id_hpp');
    }

    public function rawMaterial(): BelongsTo
    {
        return $this->belongsTo(RawMaterial::class, 'id_rm', 'id_rm');
    }
}
