<?php

namespace App\Models;

use App\Models\Concerns\DefaultsToAvenorStore;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Attendance extends Model
{
    use DefaultsToAvenorStore, HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'store_id',
        'user_id',
        'attendance_date',
        'check_in',
        'check_in_latitude',
        'check_in_longitude',
        'check_out',
        'check_out_latitude',
        'check_out_longitude',
        'status',
        'notes',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'attendance_date' => 'date',
            'created_at' => 'datetime',
            'check_in_latitude' => 'float',
            'check_in_longitude' => 'float',
            'check_out_latitude' => 'float',
            'check_out_longitude' => 'float',
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
