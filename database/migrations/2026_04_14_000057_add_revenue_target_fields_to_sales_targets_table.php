<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sales_targets', function (Blueprint $table) {
            $table->decimal('monthly_target_revenue', 15, 2)->default(0)->after('role');
            $table->decimal('minimum_kpi_value', 8, 2)->default(0)->after('monthly_target_revenue');
            $table->unsignedInteger('maximum_late_days')->default(0)->after('minimum_kpi_value');
            $table->decimal('minimum_attendance_percentage', 8, 2)->default(0)->after('maximum_late_days');
            $table->decimal('revenue_bonus', 15, 2)->default(0)->after('minimum_attendance_percentage');
        });
    }

    public function down(): void
    {
        Schema::table('sales_targets', function (Blueprint $table) {
            $table->dropColumn([
                'monthly_target_revenue',
                'minimum_kpi_value',
                'maximum_late_days',
                'minimum_attendance_percentage',
                'revenue_bonus',
            ]);
        });
    }
};
