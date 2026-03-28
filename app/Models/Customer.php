<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Customer extends Model
{
    use HasFactory;

    protected $primaryKey = 'id_pelanggan';
    public $timestamps = false;

    protected $fillable = [
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
}
