<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('offline_sales', function (Blueprint $table) {
            $table->id('id_penjualan_offline');
            $table->unsignedBigInteger('id_user');
            $table->unsignedBigInteger('id_product')->nullable();
            $table->unsignedBigInteger('promo_id')->nullable();
            $table->string('nama');
            $table->string('nama_product');
            $table->unsignedInteger('quantity');
            $table->decimal('harga', 14, 2);
            $table->string('kode_promo')->nullable();
            $table->string('promo')->nullable();
            $table->string('bukti_pembelian')->nullable();
            $table->string('approval_status')->default('pending');
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('id_user')->references('id_user')->on('users')->cascadeOnDelete();
            $table->foreign('id_product')->references('id_product')->on('products')->nullOnDelete();
            $table->foreign('promo_id')->references('id')->on('promos')->nullOnDelete();
            $table->foreign('approved_by')->references('id_user')->on('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('offline_sales');
    }
};