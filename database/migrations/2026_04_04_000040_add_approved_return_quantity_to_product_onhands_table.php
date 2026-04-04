<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('product_onhands', function (Blueprint $table) {
            $table->unsignedInteger('approved_return_quantity')
                ->default(0)
                ->after('quantity_dikembalikan');
        });
    }

    public function down(): void
    {
        Schema::table('product_onhands', function (Blueprint $table) {
            $table->dropColumn('approved_return_quantity');
        });
    }
};
