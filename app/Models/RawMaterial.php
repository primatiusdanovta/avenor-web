<?php

namespace App\Models;

use App\Models\Concerns\DefaultsToAvenorStore;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RawMaterial extends Model
{
    use DefaultsToAvenorStore, HasFactory;

    protected $primaryKey = 'id_rm';

    public $timestamps = false;

    protected $fillable = [
        'store_id',
        'nama_rm',
        'satuan',
        'harga',
        'quantity',
        'harga_satuan',
        'stock',
        'total_quantity',
        'waste_materials',
        'waste_percentage',
        'waste_loss_percentage',
        'waste_loss_amount',
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
            'waste_materials' => 'decimal:2',
            'waste_percentage' => 'decimal:2',
            'waste_loss_percentage' => 'decimal:2',
            'waste_loss_amount' => 'decimal:2',
            'created_at' => 'datetime',
        ];
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }
}
