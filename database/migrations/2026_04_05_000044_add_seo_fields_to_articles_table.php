<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('articles', function (Blueprint $table) {
            $table->string('seo_title')->nullable()->after('image_path');
            $table->string('seo_description', 500)->nullable()->after('seo_title');
            $table->string('seo_keywords', 1000)->nullable()->after('seo_description');
            $table->string('seo_canonical_url', 2048)->nullable()->after('seo_keywords');
            $table->string('seo_robots')->nullable()->after('seo_canonical_url');
            $table->string('og_title')->nullable()->after('seo_robots');
            $table->string('og_description', 500)->nullable()->after('og_title');
            $table->string('og_image_url', 2048)->nullable()->after('og_description');
            $table->string('og_image_alt')->nullable()->after('og_image_url');
        });
    }

    public function down(): void
    {
        Schema::table('articles', function (Blueprint $table) {
            $table->dropColumn([
                'seo_title',
                'seo_description',
                'seo_keywords',
                'seo_canonical_url',
                'seo_robots',
                'og_title',
                'og_description',
                'og_image_url',
                'og_image_alt',
            ]);
        });
    }
};
