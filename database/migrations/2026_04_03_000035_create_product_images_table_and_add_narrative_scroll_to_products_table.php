<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('product_images', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('product_id');
            $table->string('image_path');
            $table->unsignedInteger('sort_order')->default(1);
            $table->timestamps();

            $table->foreign('product_id')
                ->references('id_product')
                ->on('products')
                ->cascadeOnDelete();
        });

        Schema::table('products', function (Blueprint $table) {
            $table->json('narrative_scroll')->nullable()->after('educational_blocks');
        });

        $products = DB::table('products')
            ->select('id_product', 'gambar')
            ->whereNotNull('gambar')
            ->get();

        foreach ($products as $product) {
            DB::table('product_images')->insert([
                'product_id' => $product->id_product,
                'image_path' => $product->gambar,
                'sort_order' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn('narrative_scroll');
        });

        Schema::dropIfExists('product_images');
    }
};
