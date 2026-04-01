<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('product_fragrance_details', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('id_product');
            $table->unsignedBigInteger('id_fd');
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('id_product')->references('id_product')->on('products')->cascadeOnDelete();
            $table->foreign('id_fd')->references('id_fd')->on('fragrance_details')->cascadeOnDelete();
            $table->unique(['id_product', 'id_fd']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('product_fragrance_details');
    }
};
