<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('marketing_locations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->string('source', 20)->default('heartbeat');
            $table->timestamp('recorded_at')->useCurrent();

            $table->foreign('user_id')->references('id_user')->on('users')->cascadeOnDelete();
            $table->index(['user_id', 'recorded_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('marketing_locations');
    }
};