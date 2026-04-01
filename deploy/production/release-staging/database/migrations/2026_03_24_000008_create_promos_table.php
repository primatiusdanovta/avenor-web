<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('promos', function (Blueprint $table) {
            $table->id();
            $table->string('kode_promo')->unique();
            $table->string('nama_promo');
            $table->decimal('potongan', 14, 2);
            $table->date('masa_aktif');
            $table->unsignedInteger('minimal_quantity')->default(1);
            $table->decimal('minimal_belanja', 14, 2)->default(0);
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('promos');
    }
};