<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('marketing_notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('created_by')->nullable()->constrained('users', 'id_user')->nullOnDelete();
            $table->string('title');
            $table->text('body');
            $table->string('target_role')->default('marketing');
            $table->string('status')->default('draft');
            $table->timestamp('scheduled_at')->nullable();
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('marketing_notifications');
    }
};
