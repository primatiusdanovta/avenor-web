<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            if (! Schema::hasColumn('products', 'landing_theme_key')) {
                $table->string('landing_theme_key', 100)->nullable()->after('canonical_url');
            }

            if (! Schema::hasColumn('products', 'landing_seo_fallback_key')) {
                $table->string('landing_seo_fallback_key', 100)->nullable()->after('landing_theme_key');
            }
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $drops = [];

            if (Schema::hasColumn('products', 'landing_theme_key')) {
                $drops[] = 'landing_theme_key';
            }

            if (Schema::hasColumn('products', 'landing_seo_fallback_key')) {
                $drops[] = 'landing_seo_fallback_key';
            }

            if ($drops !== []) {
                $table->dropColumn($drops);
            }
        });
    }
};
