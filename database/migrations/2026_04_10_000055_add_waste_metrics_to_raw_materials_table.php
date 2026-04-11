<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('raw_materials', function (Blueprint $table) {
            $table->decimal('waste_materials', 14, 2)->default(0)->after('total_quantity');
            $table->decimal('waste_percentage', 8, 2)->default(0)->after('waste_materials');
            $table->decimal('waste_loss_percentage', 8, 2)->default(0)->after('waste_percentage');
            $table->decimal('waste_loss_amount', 14, 2)->default(0)->after('waste_loss_percentage');
        });
    }

    public function down(): void
    {
        Schema::table('raw_materials', function (Blueprint $table) {
            $table->dropColumn([
                'waste_materials',
                'waste_percentage',
                'waste_loss_percentage',
                'waste_loss_amount',
            ]);
        });
    }
};
