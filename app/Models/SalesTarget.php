<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SalesTarget extends Model
{
    use HasFactory;

    protected $fillable = [
        'role',
        'monthly_target_revenue',
        'minimum_kpi_value',
        'maximum_late_days',
        'minimum_attendance_percentage',
        'revenue_bonus',
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
            'monthly_target_revenue' => 'decimal:2',
            'minimum_kpi_value' => 'decimal:2',
            'maximum_late_days' => 'integer',
            'minimum_attendance_percentage' => 'decimal:2',
            'revenue_bonus' => 'decimal:2',
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
