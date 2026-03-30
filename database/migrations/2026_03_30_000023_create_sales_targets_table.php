<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sales_targets', function (Blueprint $table) {
            $table->id();
            $table->string('role')->unique();
            $table->unsignedInteger('daily_target_qty')->default(0);
            $table->decimal('daily_bonus', 15, 2)->default(0);
            $table->unsignedInteger('weekly_target_qty')->default(0);
            $table->decimal('weekly_bonus', 15, 2)->default(0);
            $table->unsignedInteger('monthly_target_qty')->default(0);
            $table->decimal('monthly_bonus', 15, 2)->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sales_targets');
    }
};
