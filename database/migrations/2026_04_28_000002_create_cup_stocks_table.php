<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cup_stocks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('store_id')->constrained()->cascadeOnDelete();
            $table->date('stock_date');
            $table->string('variant_name');
            $table->unsignedInteger('stock_cup')->default(0);
            $table->unsignedInteger('used_cup')->default(0);
            $table->unsignedInteger('remaining_cup')->nullable();
            $table->timestamp('finalized_at')->nullable();
            $table->timestamps();

            $table->unique(['store_id', 'stock_date', 'variant_name']);
            $table->index(['store_id', 'stock_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cup_stocks');
    }
};
