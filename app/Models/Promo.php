<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Promo extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
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
}