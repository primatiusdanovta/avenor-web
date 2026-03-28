<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('offline_sales', function (Blueprint $table) {
            $table->string('transaction_code')->nullable()->after('id_penjualan_offline');
        });

        $rows = DB::table('offline_sales')
            ->select('id_penjualan_offline', 'id_user', 'id_pelanggan', 'promo_id', 'bukti_pembelian', 'created_at')
            ->orderBy('id_penjualan_offline')
            ->get();

        $groups = [];

        foreach ($rows as $row) {
            $signature = implode('|', [
                $row->id_user,
                $row->id_pelanggan ?? 'null',
                $row->promo_id ?? 'null',
                $row->bukti_pembelian ?? 'null',
                (string) $row->created_at,
            ]);

            if (! isset($groups[$signature])) {
                $groups[$signature] = 'TRX-' . now()->format('YmdHis') . '-' . strtoupper(Str::random(8));
            }

            DB::table('offline_sales')
                ->where('id_penjualan_offline', $row->id_penjualan_offline)
                ->update(['transaction_code' => $groups[$signature]]);
        }

        Schema::table('offline_sales', function (Blueprint $table) {
            $table->index('transaction_code');
        });
    }

    public function down(): void
    {
        Schema::table('offline_sales', function (Blueprint $table) {
            $table->dropIndex(['transaction_code']);
            $table->dropColumn('transaction_code');
        });
    }
};
