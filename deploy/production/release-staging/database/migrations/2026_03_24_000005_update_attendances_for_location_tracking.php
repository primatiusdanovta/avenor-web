<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('attendances')) {
            return;
        }

        if (DB::getDriverName() === 'sqlite') {
            Schema::dropIfExists('attendances');
            Schema::create('attendances', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->date('attendance_date');
                $table->time('check_in')->nullable();
                $table->decimal('check_in_latitude', 10, 7)->nullable();
                $table->decimal('check_in_longitude', 10, 7)->nullable();
                $table->time('check_out')->nullable();
                $table->decimal('check_out_latitude', 10, 7)->nullable();
                $table->decimal('check_out_longitude', 10, 7)->nullable();
                $table->string('status', 20);
                $table->text('notes')->nullable();
                $table->timestamp('created_at')->useCurrent();
                $table->foreign('user_id')->references('id_user')->on('users')->cascadeOnDelete();
                $table->unique(['user_id', 'attendance_date']);
            });

            return;
        }

        DB::statement('ALTER TABLE attendances DROP CONSTRAINT IF EXISTS attendances_user_id_area_id_attendance_date_unique');
        DB::statement('ALTER TABLE attendances DROP CONSTRAINT IF EXISTS attendances_area_id_foreign');
        DB::statement('ALTER TABLE attendances DROP CONSTRAINT IF EXISTS attendances_status_check');

        if (Schema::hasColumn('attendances', 'area_id')) {
            Schema::table('attendances', function (Blueprint $table) {
                $table->dropColumn('area_id');
            });
        }

        if (! Schema::hasColumn('attendances', 'check_in_latitude')) {
            Schema::table('attendances', function (Blueprint $table) {
                $table->decimal('check_in_latitude', 10, 7)->nullable()->after('check_in');
                $table->decimal('check_in_longitude', 10, 7)->nullable()->after('check_in_latitude');
                $table->decimal('check_out_latitude', 10, 7)->nullable()->after('check_out');
                $table->decimal('check_out_longitude', 10, 7)->nullable()->after('check_out_latitude');
            });
        }

        DB::statement("ALTER TABLE attendances ALTER COLUMN status TYPE VARCHAR(20)");
        DB::statement("ALTER TABLE attendances ADD CONSTRAINT attendances_status_check CHECK (status IN ('hadir', 'terlambat', 'izin', 'sakit'))");
        DB::statement('ALTER TABLE attendances DROP CONSTRAINT IF EXISTS attendances_user_id_attendance_date_unique');
        DB::statement('ALTER TABLE attendances ADD CONSTRAINT attendances_user_id_attendance_date_unique UNIQUE (user_id, attendance_date)');
    }

    public function down(): void
    {
        if (! Schema::hasTable('attendances')) {
            return;
        }

        if (DB::getDriverName() === 'sqlite') {
            Schema::dropIfExists('attendances');

            return;
        }

        DB::statement('ALTER TABLE attendances DROP CONSTRAINT IF EXISTS attendances_user_id_attendance_date_unique');
        DB::statement('ALTER TABLE attendances DROP CONSTRAINT IF EXISTS attendances_status_check');
    }
};