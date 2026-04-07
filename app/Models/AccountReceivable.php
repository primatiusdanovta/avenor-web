<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AccountReceivable extends Model
{
    use HasFactory;

    protected $fillable = [
        'consignment_id',
        'receivable_name',
        'place_name',
        'consignment_date',
        'due_date',
        'consigned_value',
        'total_value',
        'status',
        'notes',
        'items_summary',
    ];

    protected function casts(): array
    {
        return [
            'consignment_date' => 'date',
            'due_date' => 'date',
            'consigned_value' => 'decimal:2',
            'total_value' => 'decimal:2',
        ];
    }
}
