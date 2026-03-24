<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('raw_materials', function (Blueprint $table) {
            $table->unsignedInteger('total_quantity')->default(0)->after('stock');
            $table->decimal('harga_total', 15, 2)->default(0)->after('total_quantity');
        });

        DB::table('raw_materials')
            ->orderBy('id_rm')
            ->get()
            ->each(function (object $material): void {
                $quantity = max((int) $material->quantity, 1);
                $storedStock = (int) $material->stock;
                $manualStock = intdiv($storedStock, $quantity);
                $manualStock = $storedStock > 0 && $manualStock === 0 ? 1 : $manualStock;

                DB::table('raw_materials')
                    ->where('id_rm', $material->id_rm)
                    ->update([
                        'stock' => $manualStock,
                        'total_quantity' => $manualStock * $quantity,
                        'harga_total' => $manualStock * (float) $material->harga,
                    ]);
            });
    }

    public function down(): void
    {
        DB::table('raw_materials')
            ->orderBy('id_rm')
            ->get()
            ->each(function (object $material): void {
                DB::table('raw_materials')
                    ->where('id_rm', $material->id_rm)
                    ->update([
                        'stock' => (int) $material->stock * (int) $material->quantity,
                    ]);
            });

        Schema::table('raw_materials', function (Blueprint $table) {
            $table->dropColumn(['total_quantity', 'harga_total']);
        });
    }
};
