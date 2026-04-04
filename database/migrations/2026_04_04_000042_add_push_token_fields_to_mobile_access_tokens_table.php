<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('mobile_access_tokens', function (Blueprint $table) {
            $table->text('push_token')->nullable()->after('token');
            $table->string('push_platform', 20)->nullable()->after('push_token');
            $table->timestamp('push_token_updated_at')->nullable()->after('push_platform');
        });
    }

    public function down(): void
    {
        Schema::table('mobile_access_tokens', function (Blueprint $table) {
            $table->dropColumn([
                'push_token',
                'push_platform',
                'push_token_updated_at',
            ]);
        });
    }
};
