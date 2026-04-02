<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $items = [
            [
                'detail' => 'Powdery',
                'deskripsi' => 'Nuansa lembut, halus, dan clean seperti bedak mewah.',
            ],
            [
                'detail' => 'Musky',
                'deskripsi' => 'Nuansa musk yang hangat, bersih, dan sensual.',
            ],
            [
                'detail' => 'Amber',
                'deskripsi' => 'Nuansa amber yang hangat, manis, dan rich.',
            ],
        ];

        foreach ($items as $item) {
            $exists = DB::table('fragrance_details')
                ->where('detail', $item['detail'])
                ->exists();

            if (! $exists) {
                DB::table('fragrance_details')->insert([
                    'jenis' => 'fragrance family',
                    'detail' => $item['detail'],
                    'deskripsi' => $item['deskripsi'],
                    'created_at' => now(),
                ]);
            }
        }
    }

    public function down(): void
    {
        DB::table('fragrance_details')
            ->whereIn('detail', ['Powdery', 'Musky', 'Amber'])
            ->delete();
    }
};