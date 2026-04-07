<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('consignment_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('consignment_id')->constrained('consignments')->cascadeOnDelete();
            $table->unsignedBigInteger('product_onhand_id');
            $table->unsignedBigInteger('product_id');
            $table->string('product_name');
            $table->string('pickup_batch_code')->nullable();
            $table->unsignedInteger('quantity');
            $table->unsignedInteger('sold_quantity')->default(0);
            $table->unsignedInteger('returned_quantity')->default(0);
            $table->string('status')->default('dititipkan');
            $table->text('status_notes')->nullable();
            $table->timestamps();

            $table->foreign('product_onhand_id')->references('id_product_onhand')->on('product_onhands')->cascadeOnDelete();
            $table->foreign('product_id')->references('id_product')->on('products')->cascadeOnDelete();
            $table->index(['product_onhand_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('consignment_items');
    }
};
