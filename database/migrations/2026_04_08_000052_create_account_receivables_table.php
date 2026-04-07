<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('account_receivables', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('consignment_id')->nullable();
            $table->string('receivable_name');
            $table->string('place_name');
            $table->date('consignment_date');
            $table->date('due_date');
            $table->decimal('total_value', 14, 2)->default(0);
            $table->text('items_summary')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('consignment_id')->references('id')->on('consignments')->nullOnDelete();
            $table->index(['due_date', 'place_name']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('account_receivables');
    }
};
