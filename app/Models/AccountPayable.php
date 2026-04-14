<?php

namespace App\Models;

use App\Models\Concerns\DefaultsToAvenorStore;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AccountPayable extends Model
{
    use DefaultsToAvenorStore, HasFactory;

    protected $fillable = [
        'store_id',
        'account_payable',
        'amount',
        'due_date',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'due_date' => 'date',
        ];
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }
}
