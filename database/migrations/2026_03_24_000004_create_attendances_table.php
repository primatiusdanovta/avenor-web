<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('attendances', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->foreignId('area_id')->constrained('areas')->cascadeOnDelete();
            $table->date('attendance_date');
            $table->time('check_in');
            $table->time('check_out')->nullable();
            $table->enum('status', ['hadir', 'terlambat', 'izin']);
            $table->text('notes')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('user_id')->references('id_user')->on('users')->cascadeOnDelete();
            $table->unique(['user_id', 'area_id', 'attendance_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('attendances');
    }
};