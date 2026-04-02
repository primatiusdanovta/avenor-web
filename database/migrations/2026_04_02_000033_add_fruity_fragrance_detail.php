<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $exists = DB::table('fragrance_details')
            ->where('detail', 'Fruity')
            ->exists();

        if (! $exists) {
            DB::table('fragrance_details')->insert([
                'jenis' => 'fragrance family',
                'detail' => 'Fruity',
                'deskripsi' => 'Nuansa buah yang juicy, manis, dan cerah.',
                'created_at' => now(),
            ]);
        }
    }

    public function down(): void
    {
        DB::table('fragrance_details')
            ->where('detail', 'Fruity')
            ->delete();
    }
};