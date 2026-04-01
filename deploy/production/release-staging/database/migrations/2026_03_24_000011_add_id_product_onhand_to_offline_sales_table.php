<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('offline_sales', function (Blueprint $table) {
            $table->unsignedBigInteger('id_product_onhand')->nullable()->after('id_product');
            $table->foreign('id_product_onhand')->references('id_product_onhand')->on('product_onhands')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('offline_sales', function (Blueprint $table) {
            $table->dropForeign(['id_product_onhand']);
            $table->dropColumn('id_product_onhand');
        });
    }
};