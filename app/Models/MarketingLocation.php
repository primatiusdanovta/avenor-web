<?php

namespace App\Models;

use App\Models\Concerns\DefaultsToAvenorStore;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MarketingLocation extends Model
{
    use DefaultsToAvenorStore, HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'store_id',
        'user_id',
        'latitude',
        'longitude',
        'source',
        'recorded_at',
    ];

    protected function casts(): array
    {
        return [
            'recorded_at' => 'datetime',
            'latitude' => 'float',
            'longitude' => 'float',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id', 'id_user');
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }
}
