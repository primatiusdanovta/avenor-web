<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('hpp_calculation_items', function (Blueprint $table) {
            $table->id('id_hpp_item');
            $table->unsignedBigInteger('id_hpp');
            $table->unsignedBigInteger('id_rm');
            $table->string('nama_rm');
            $table->string('satuan');
            $table->decimal('presentase', 8, 2);
            $table->decimal('harga_satuan', 15, 2);
            $table->decimal('harga_final', 15, 2);
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('id_hpp')->references('id_hpp')->on('hpp_calculations')->cascadeOnDelete();
            $table->foreign('id_rm')->references('id_rm')->on('raw_materials')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('hpp_calculation_items');
    }
};
