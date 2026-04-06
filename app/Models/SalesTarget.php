<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SalesTarget extends Model
{
    use HasFactory;

    protected $fillable = [
        'role',
        'daily_target_qty',
        'daily_bonus',
        'weekly_target_qty',
        'weekly_bonus',
        'monthly_target_qty',
        'monthly_bonus',
    ];

    protected function casts(): array
    {
        return [
            'daily_target_qty' => 'integer',
            'daily_bonus' => 'decimal:2',
            'weekly_target_qty' => 'integer',
            'weekly_bonus' => 'decimal:2',
            'monthly_target_qty' => 'integer',
            'monthly_bonus' => 'decimal:2',
        ];
    }

    public function getRouteKeyName(): string
    {
        return 'role';
    }
}
