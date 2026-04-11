<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('product_variants', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('product_id');
            $table->string('name');
            $table->decimal('price', 14, 2)->default(0);
            $table->decimal('total_satuan_ml', 14, 2)->default(0);
            $table->boolean('is_default')->default(false);
            $table->timestamps();

            $table->unique(['product_id', 'name']);
            $table->foreign('product_id')->references('id_product')->on('products')->cascadeOnDelete();
        });

        Schema::create('extra_toppings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('store_id');
            $table->string('name');
            $table->decimal('price', 14, 2)->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['store_id', 'name']);
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::create('sops', function (Blueprint $table) {
            $table->id('id_sop');
            $table->unsignedBigInteger('store_id')->nullable();
            $table->string('title');
            $table->text('detail');
            $table->timestamps();

            $table->foreign('store_id')->references('id')->on('stores')->nullOnDelete();
        });

        Schema::table('offline_sales', function (Blueprint $table) {
            $table->string('sale_number')->nullable()->after('transaction_code');
            $table->unsignedBigInteger('product_variant_id')->nullable()->after('id_product');
            $table->string('product_variant_name')->nullable()->after('product_variant_id');
            $table->decimal('unit_price', 14, 2)->default(0)->after('product_variant_name');
            $table->decimal('extra_topping_total', 14, 2)->default(0)->after('unit_price');
            $table->json('extra_toppings')->nullable()->after('extra_topping_total');
            $table->string('payment_method')->nullable()->after('extra_toppings');
            $table->string('payment_status')->default('pending')->after('payment_method');
            $table->timestamp('paid_at')->nullable()->after('payment_status');

            $table->foreign('product_variant_id')->references('id')->on('product_variants')->nullOnDelete();
            $table->index('sale_number');
            $table->index('payment_status');
        });
    }

    public function down(): void
    {
        Schema::table('offline_sales', function (Blueprint $table) {
            $table->dropForeign(['product_variant_id']);
            $table->dropIndex(['sale_number']);
            $table->dropIndex(['payment_status']);
            $table->dropColumn([
                'sale_number',
                'product_variant_id',
                'product_variant_name',
                'unit_price',
                'extra_topping_total',
                'extra_toppings',
                'payment_method',
                'payment_status',
                'paid_at',
            ]);
        });

        Schema::dropIfExists('sops');
        Schema::dropIfExists('extra_toppings');
        Schema::dropIfExists('product_variants');
    }
};
