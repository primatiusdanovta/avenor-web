<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->boolean('landing_page_active')->default(false)->after('deskripsi');
            $table->string('seo_title')->nullable()->after('landing_page_active');
            $table->text('seo_description')->nullable()->after('seo_title');
            $table->string('canonical_url')->nullable()->after('seo_description');
            $table->text('top_notes_text')->nullable()->after('canonical_url');
            $table->text('heart_notes_text')->nullable()->after('top_notes_text');
            $table->text('base_notes_text')->nullable()->after('heart_notes_text');
            $table->json('education_content')->nullable()->after('base_notes_text');
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn([
                'landing_page_active',
                'seo_title',
                'seo_description',
                'canonical_url',
                'top_notes_text',
                'heart_notes_text',
                'base_notes_text',
                'education_content',
            ]);
        });
    }
};
