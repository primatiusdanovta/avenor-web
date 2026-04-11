<?php

namespace App\Models;

use App\Models\Concerns\DefaultsToAvenorStore;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Customer extends Model
{
    use DefaultsToAvenorStore, HasFactory;

    protected $primaryKey = 'id_pelanggan';
    public $timestamps = false;

    protected $fillable = [
        'store_id',
        'nama',
        'no_telp',
        'tiktok_instagram',
        'created_at',
        'pembelian_terakhir',
    ];

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
            'pembelian_terakhir' => 'datetime',
        ];
    }

    public function offlineSales(): HasMany
    {
        return $this->hasMany(OfflineSale::class, 'id_pelanggan', 'id_pelanggan');
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }
}
