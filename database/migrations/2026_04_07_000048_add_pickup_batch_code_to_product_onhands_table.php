<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('product_onhands', function (Blueprint $table) {
            $table->string('pickup_batch_code')->nullable()->after('manual_sold_quantity');
        });
    }

    public function down(): void
    {
        Schema::table('product_onhands', function (Blueprint $table) {
            $table->dropColumn('pickup_batch_code');
        });
    }
};
