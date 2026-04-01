<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('content_creators', function (Blueprint $table) {
            $table->id('id_contentcreator');
            $table->string('nama');
            $table->json('bidang');
            $table->string('username_instagram')->nullable();
            $table->string('username_tiktok')->nullable();
            $table->unsignedBigInteger('followers_instagram')->default(0);
            $table->unsignedBigInteger('followers_tiktok')->default(0);
            $table->string('range_fee_percontent')->nullable();
            $table->string('jenis_konten')->nullable();
            $table->string('no_telp', 30)->nullable();
            $table->string('wilayah')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('content_creators');
    }
};
