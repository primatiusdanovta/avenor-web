<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('offline_sales', function (Blueprint $table) {
            $table->text('notes')->nullable()->after('sugar_level');
            $table->decimal('cash_received', 14, 2)->nullable()->after('payment_status');
            $table->decimal('change_amount', 14, 2)->nullable()->after('cash_received');
        });
    }

    public function down(): void
    {
        Schema::table('offline_sales', function (Blueprint $table) {
            $table->dropColumn([
                'notes',
                'cash_received',
                'change_amount',
            ]);
        });
    }
};
