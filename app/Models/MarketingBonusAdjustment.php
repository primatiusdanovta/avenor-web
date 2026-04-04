<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MarketingBonusAdjustment extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'created_by',
        'bonus_month',
        'amount',
        'note',
    ];

    protected function casts(): array
    {
        return [
            'bonus_month' => 'date',
            'amount' => 'decimal:2',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id', 'id_user');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by', 'id_user');
    }
}
