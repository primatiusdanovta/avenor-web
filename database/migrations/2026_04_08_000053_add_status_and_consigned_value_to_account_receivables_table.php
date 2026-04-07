<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('account_receivables', function (Blueprint $table) {
            $table->decimal('consigned_value', 14, 2)->default(0)->after('due_date');
            $table->string('status')->default('dititipkan')->after('total_value');
        });

        DB::table('account_receivables')->update([
            'consigned_value' => DB::raw('total_value'),
            'status' => 'dititipkan',
        ]);
    }

    public function down(): void
    {
        Schema::table('account_receivables', function (Blueprint $table) {
            $table->dropColumn(['consigned_value', 'status']);
        });
    }
};
