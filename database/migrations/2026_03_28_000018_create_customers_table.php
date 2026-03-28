<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customers', function (Blueprint $table) {
            $table->id('id_pelanggan');
            $table->string('nama')->nullable();
            $table->string('no_telp')->nullable()->unique();
            $table->string('tiktok_instagram')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('pembelian_terakhir')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('customers');
    }
};
