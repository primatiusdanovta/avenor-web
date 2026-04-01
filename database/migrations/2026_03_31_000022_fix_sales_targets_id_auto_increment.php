<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('sales_targets') || ! Schema::hasColumn('sales_targets', 'id')) {
            return;
        }

        if (DB::getDriverName() !== 'mysql') {
            return;
        }

        $database = DB::getDatabaseName();

        $hasPrimaryKey = DB::table('information_schema.TABLE_CONSTRAINTS')
            ->where('TABLE_SCHEMA', $database)
            ->where('TABLE_NAME', 'sales_targets')
            ->where('CONSTRAINT_TYPE', 'PRIMARY KEY')
            ->exists();

        if (! $hasPrimaryKey) {
            DB::statement('ALTER TABLE `sales_targets` ADD PRIMARY KEY (`id`)');
        }

        DB::statement('ALTER TABLE `sales_targets` MODIFY `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT');
    }

    public function down(): void
    {
    }
};
