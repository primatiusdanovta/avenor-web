<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RawMaterial extends Model
{
    use HasFactory;

    protected $primaryKey = 'id_rm';

    public $timestamps = false;

    protected $fillable = [
        'nama_rm',
        'satuan',
        'harga',
        'quantity',
        'harga_satuan',
        'stock',
        'total_quantity',
        'harga_total',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'harga' => 'decimal:2',
            'harga_satuan' => 'decimal:2',
            'harga_total' => 'decimal:2',
            'quantity' => 'decimal:2',
            'stock' => 'decimal:2',
            'total_quantity' => 'decimal:2',
            'created_at' => 'datetime',
        ];
    }
}

