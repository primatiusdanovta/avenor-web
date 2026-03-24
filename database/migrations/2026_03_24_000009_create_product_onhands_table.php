<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('product_onhands', function (Blueprint $table) {
            $table->id('id_product_onhand');
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('id_product');
            $table->string('nama_product');
            $table->unsignedInteger('quantity');
            $table->unsignedInteger('quantity_dikembalikan')->default(0);
            $table->string('return_status')->default('belum');
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->date('assignment_date');
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('user_id')->references('id_user')->on('users')->cascadeOnDelete();
            $table->foreign('approved_by')->references('id_user')->on('users')->nullOnDelete();
            $table->foreign('id_product')->references('id_product')->on('products')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('product_onhands');
    }
};