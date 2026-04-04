<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('marketing_bonus_adjustments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users', 'id_user')->cascadeOnDelete();
            $table->foreignId('created_by')->nullable()->constrained('users', 'id_user')->nullOnDelete();
            $table->date('bonus_month');
            $table->decimal('amount', 15, 2);
            $table->text('note')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('marketing_bonus_adjustments');
    }
};
