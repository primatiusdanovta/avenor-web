<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('offline_sales', function (Blueprint $table) {
            $table->decimal('total_hpp', 15, 2)->default(0)->after('harga');
        });

        $driver = DB::connection()->getDriverName();

        if ($driver === 'pgsql') {
            DB::statement(<<<'SQL'
                UPDATE offline_sales
                SET total_hpp = COALESCE(hpp_calculations.total_hpp, products.harga_modal, 0)
                FROM products
                LEFT JOIN hpp_calculations ON hpp_calculations.id_product = products.id_product
                WHERE products.id_product = offline_sales.id_product
            SQL);

            return;
        }

        DB::table('offline_sales')
            ->orderBy('id_sale')
            ->get(['id_sale', 'id_product'])
            ->each(function (object $sale): void {
                $hargaModal = (float) (DB::table('products')
                    ->where('id_product', $sale->id_product)
                    ->value('harga_modal') ?? 0);

                $totalHpp = (float) (DB::table('hpp_calculations')
                    ->where('id_product', $sale->id_product)
                    ->value('total_hpp') ?? $hargaModal);

                DB::table('offline_sales')
                    ->where('id_sale', $sale->id_sale)
                    ->update(['total_hpp' => $totalHpp]);
            });
    }

    public function down(): void
    {
        Schema::table('offline_sales', function (Blueprint $table) {
            $table->dropColumn('total_hpp');
        });
    }
};
