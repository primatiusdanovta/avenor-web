<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Consignment extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'place_name',
        'address',
        'consignment_date',
        'submitted_at',
        'latitude',
        'longitude',
        'notes',
        'handover_proof_photo',
    ];

    protected function casts(): array
    {
        return [
            'consignment_date' => 'date',
            'submitted_at' => 'datetime',
            'latitude' => 'float',
            'longitude' => 'float',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id', 'id_user');
    }

    public function items(): HasMany
    {
        return $this->hasMany(ConsignmentItem::class);
    }
}
