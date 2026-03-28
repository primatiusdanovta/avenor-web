<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::getConnection()->getDriverName() !== 'sqlite') {
            DB::statement('ALTER TABLE raw_materials ALTER COLUMN quantity TYPE numeric(15,2) USING quantity::numeric');
            DB::statement('ALTER TABLE raw_materials ALTER COLUMN stock TYPE numeric(15,2) USING stock::numeric');
            DB::statement('ALTER TABLE raw_materials ALTER COLUMN total_quantity TYPE numeric(15,2) USING total_quantity::numeric');
        }

        Schema::table('hpp_calculation_items', function (Blueprint $table) {
            $table->decimal('total_stock', 15, 2)->default(0)->after('harga_final');
        });

        DB::table('hpp_calculation_items')
            ->orderBy('id_hpp_item')
            ->get(['id_hpp_item', 'id_rm'])
            ->each(function (object $item): void {
                $totalStock = (float) (DB::table('raw_materials')
                    ->where('id_rm', $item->id_rm)
                    ->value('total_quantity') ?? 0);

                DB::table('hpp_calculation_items')
                    ->where('id_hpp_item', $item->id_hpp_item)
                    ->update(['total_stock' => $totalStock]);
            });
    }

    public function down(): void
    {
        Schema::table('hpp_calculation_items', function (Blueprint $table) {
            $table->dropColumn('total_stock');
        });

        if (Schema::getConnection()->getDriverName() !== 'sqlite') {
            DB::statement('ALTER TABLE raw_materials ALTER COLUMN quantity TYPE integer USING ROUND(quantity)::integer');
            DB::statement('ALTER TABLE raw_materials ALTER COLUMN stock TYPE integer USING ROUND(stock)::integer');
            DB::statement('ALTER TABLE raw_materials ALTER COLUMN total_quantity TYPE integer USING ROUND(total_quantity)::integer');
        }
    }
};
