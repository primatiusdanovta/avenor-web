<?php

namespace App\Models;

use App\Models\Concerns\DefaultsToAvenorStore;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Promo extends Model
{
    use DefaultsToAvenorStore, HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'store_id',
        'kode_promo',
        'nama_promo',
        'potongan',
        'masa_aktif',
        'minimal_quantity',
        'minimal_belanja',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'potongan' => 'decimal:2',
            'masa_aktif' => 'date',
            'minimal_quantity' => 'integer',
            'minimal_belanja' => 'decimal:2',
            'created_at' => 'datetime',
        ];
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }
}
