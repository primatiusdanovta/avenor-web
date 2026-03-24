<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('raw_materials', function (Blueprint $table) {
            $table->id('id_rm');
            $table->string('nama_rm')->unique();
            $table->decimal('harga', 15, 2);
            $table->unsignedInteger('quantity');
            $table->decimal('harga_satuan', 15, 2);
            $table->unsignedInteger('stock');
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('raw_materials');
    }
};
