<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('online_sales', function (Blueprint $table) {
            $table->id();
            $table->string('order_id')->unique();
            $table->string('order_status')->nullable();
            $table->string('order_substatus')->nullable();
            $table->string('cancelation')->nullable();
            $table->string('province')->nullable();
            $table->string('regency_city')->nullable();
            $table->dateTime('paid_time')->nullable();
            $table->decimal('total_amount', 15, 2)->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('online_sales');
    }
};
