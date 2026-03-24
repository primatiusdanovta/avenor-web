<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('product_onhands', function (Blueprint $table) {
            $table->string('take_status')->default('disetujui')->after('quantity_dikembalikan');
            $table->unsignedBigInteger('take_approved_by')->nullable()->after('approved_by');
            $table->timestamp('take_requested_at')->nullable()->after('take_approved_by');
            $table->timestamp('take_reviewed_at')->nullable()->after('take_requested_at');

            $table->foreign('take_approved_by')->references('id_user')->on('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('product_onhands', function (Blueprint $table) {
            $table->dropConstrainedForeignId('take_approved_by');
            $table->dropColumn(['take_status', 'take_requested_at', 'take_reviewed_at']);
        });
    }
};
