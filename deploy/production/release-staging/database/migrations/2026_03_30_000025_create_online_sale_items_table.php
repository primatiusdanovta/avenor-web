<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('online_sale_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('online_sale_id')->constrained('online_sales')->cascadeOnDelete();
            $table->unsignedBigInteger('id_product')->nullable();
            $table->string('raw_product_name');
            $table->string('nama_product');
            $table->unsignedInteger('quantity')->default(0);
            $table->decimal('harga', 15, 2)->default(0);
            $table->dateTime('created_at')->nullable();
            $table->dateTime('updated_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('online_sale_items');
    }
};
