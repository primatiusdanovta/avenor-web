<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            if (! Schema::hasColumn('products', 'faq_data')) {
                $table->json('faq_data')->nullable()->after('education_content');
            }

            if (! Schema::hasColumn('products', 'educational_blocks')) {
                $table->json('educational_blocks')->nullable()->after('faq_data');
            }
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $drops = [];

            if (Schema::hasColumn('products', 'faq_data')) {
                $drops[] = 'faq_data';
            }

            if (Schema::hasColumn('products', 'educational_blocks')) {
                $drops[] = 'educational_blocks';
            }

            if ($drops) {
                $table->dropColumn($drops);
            }
        });
    }
};
