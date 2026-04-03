<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('career_applications', function (Blueprint $table) {
            $table->unsignedBigInteger('content_creator_id')->nullable()->after('status');
            $table->timestamp('transferred_to_content_creator_at')->nullable()->after('content_creator_id');
        });
    }

    public function down(): void
    {
        Schema::table('career_applications', function (Blueprint $table) {
            $table->dropColumn(['content_creator_id', 'transferred_to_content_creator_at']);
        });
    }
};
