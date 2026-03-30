<?php

namespace Database\Seeders;

use App\Models\FragranceDetail;
use App\Models\OfflineSale;
use App\Models\Product;
use App\Models\SalesTarget;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $users = [
            ['nama' => 'superadmin', 'status' => 'aktif', 'role' => 'superadmin', 'password' => 'Superadmin123!'],
            ['nama' => 'admin', 'status' => 'aktif', 'role' => 'admin', 'password' => 'Admin123!'],
            ['nama' => 'marketing', 'status' => 'aktif', 'role' => 'marketing', 'password' => 'Marketing123!'],
            ['nama' => 'reseller', 'status' => 'aktif', 'role' => 'reseller', 'password' => 'Reseller123!'],
        ];

        foreach ($users as $user) {
            User::query()->updateOrCreate(
                ['nama' => $user['nama']],
                [
                    'status' => $user['status'],
                    'role' => $user['role'],
                    'password' => $user['password'],
                    'created_at' => now(),
                ],
            );
        }

        foreach (['marketing', 'reseller'] as $role) {
            SalesTarget::query()->updateOrCreate(
                ['role' => $role],
                [
                    'daily_target_qty' => 0,
                    'daily_bonus' => 0,
                    'weekly_target_qty' => 0,
                    'weekly_bonus' => 0,
                    'monthly_target_qty' => 0,
                    'monthly_bonus' => 0,
                ],
            );
        }

        foreach ($this->defaultFragranceDetails() as $detail) {
            FragranceDetail::query()->updateOrCreate(
                ['detail' => $detail['detail']],
                [
                    'jenis' => $detail['jenis'],
                    'deskripsi' => $detail['deskripsi'],
                    'created_at' => now(),
                ],
            );
        }

        if (! app()->runningUnitTests() && ! app()->environment('e2e')) {
            $this->seedReferenceProducts();
            $this->seedOfflineSalesHistory();
        }
    }

    private function defaultFragranceDetails(): array
    {
        return [
            ['jenis' => 'universal', 'detail' => 'Wanita', 'deskripsi' => 'Aroma yang umum disukai untuk karakter feminin.'],
            ['jenis' => 'universal', 'detail' => 'Pria', 'deskripsi' => 'Aroma yang umum disukai untuk karakter maskulin.'],
            ['jenis' => 'universal', 'detail' => 'Unisex', 'deskripsi' => 'Aroma yang cocok digunakan pria maupun wanita.'],
            ['jenis' => 'fragrance family', 'detail' => 'Citrus', 'deskripsi' => 'Nuansa segar dari buah-buahan sitrus.'],
            ['jenis' => 'fragrance family', 'detail' => 'Woody', 'deskripsi' => 'Nuansa kayu yang hangat dan elegan.'],
            ['jenis' => 'fragrance family', 'detail' => 'Fresh', 'deskripsi' => 'Nuansa ringan, bersih, dan menyegarkan.'],
            ['jenis' => 'fragrance family', 'detail' => 'Aquatic', 'deskripsi' => 'Nuansa airy dan watery yang segar.'],
            ['jenis' => 'fragrance family', 'detail' => 'Gourmand', 'deskripsi' => 'Nuansa manis seperti dessert dan edible notes.'],
            ['jenis' => 'fragrance family', 'detail' => 'Sweet', 'deskripsi' => 'Nuansa manis yang dominan dan playful.'],
            ['jenis' => 'fragrance family', 'detail' => 'Floral', 'deskripsi' => 'Nuansa bunga yang lembut hingga mewah.'],
            ['jenis' => 'fragrance family', 'detail' => 'Green/Herbal', 'deskripsi' => 'Nuansa dedaunan, herbal, dan natural.'],
            ['jenis' => 'fragrance family', 'detail' => 'Spicy/Aromatic', 'deskripsi' => 'Nuansa rempah dan aromatic yang tegas.'],
            ['jenis' => 'fragrance family', 'detail' => 'Fougere', 'deskripsi' => 'Nuansa klasik aromatic dengan herbal dan woody.'],
            ['jenis' => 'fragrance family', 'detail' => 'Chypre', 'deskripsi' => 'Nuansa elegan dengan balance citrus, moss, dan woody.'],
            ['jenis' => 'activities', 'detail' => 'Versatile', 'deskripsi' => 'Cocok dipakai di banyak suasana dan waktu.'],
            ['jenis' => 'activities', 'detail' => 'Formal & Elegan', 'deskripsi' => 'Cocok untuk acara resmi dan kesan sophisticated.'],
            ['jenis' => 'activities', 'detail' => 'Hangout/Daily', 'deskripsi' => 'Nyaman untuk aktivitas santai dan harian.'],
            ['jenis' => 'activities', 'detail' => 'Sensual/Intens', 'deskripsi' => 'Karakter aroma yang lebih bold dan memikat.'],
            ['jenis' => 'activities', 'detail' => 'Sports', 'deskripsi' => 'Cocok untuk aktivitas aktif dan suasana energik.'],
        ];
    }

    private function seedReferenceProducts(): void
    {
        $products = [
            ['nama_product' => 'Solair', 'harga' => 75000, 'deskripsi' => 'Fresh citrus perfume untuk pemakaian harian.'],
            ['nama_product' => 'Sevon', 'harga' => 75000, 'deskripsi' => 'Woody aromatic perfume dengan karakter elegan.'],
            ['nama_product' => 'Azalea', 'harga' => 75000, 'deskripsi' => 'Floral sweet perfume dengan kesan lembut.'],
            ['nama_product' => 'Athena', 'harga' => 75000, 'deskripsi' => 'Fresh floral perfume untuk kesan modern.'],
            ['nama_product' => 'Helios', 'harga' => 79000, 'deskripsi' => 'Citrus spicy perfume dengan karakter energik.'],
            ['nama_product' => 'Odysseia', 'harga' => 79000, 'deskripsi' => 'Aquatic woody perfume yang versatile.'],
            ['nama_product' => 'Elysia', 'harga' => 79000, 'deskripsi' => 'Sweet gourmand perfume dengan kesan playful.'],
        ];

        foreach ($products as $product) {
            Product::query()->updateOrCreate(
                ['nama_product' => $product['nama_product']],
                [
                    'harga' => $product['harga'],
                    'harga_modal' => 0,
                    'stock' => Product::query()->where('nama_product', $product['nama_product'])->value('stock') ?? 0,
                    'deskripsi' => $product['deskripsi'],
                    'created_at' => Product::query()->where('nama_product', $product['nama_product'])->value('created_at') ?? now(),
                ],
            );
        }
    }

    private function seedOfflineSalesHistory(): void
    {
        $marketing = User::query()->where('nama', 'marketing')->first();
        $approver = User::query()->where('nama', 'superadmin')->first() ?? User::query()->where('nama', 'admin')->first();

        if (! $marketing || ! $approver) {
            return;
        }

        OfflineSale::query()->where('transaction_code', 'like', 'SEEDED-OFFLINE-%')->delete();

        $products = Product::query()
            ->whereIn('nama_product', ['Solair', 'Sevon', 'Azalea', 'Athena', 'Helios', 'Odysseia', 'Elysia'])
            ->get()
            ->keyBy('nama_product');

        $weights = [
            'Solair' => 24,
            'Sevon' => 22,
            'Azalea' => 20,
            'Athena' => 18,
            'Helios' => 6,
            'Odysseia' => 5,
            'Elysia' => 5,
        ];

        $monthlyTargets = [
            '2025-04' => 63,
            '2025-05' => 91,
            '2025-06' => 147,
            '2025-07' => 152,
            '2025-08' => 368,
            '2025-09' => 224,
            '2025-10' => 289,
            '2025-11' => 248,
            '2025-12' => 315,
            '2026-01' => 306,
            '2026-02' => 483,
            '2026-03' => 417,
        ];

        $sequence = 1;

        foreach ($monthlyTargets as $month => $totalQuantity) {
            $periodStart = Carbon::createFromFormat('Y-m', $month)->startOfMonth();
            $daysInMonth = $periodStart->daysInMonth;
            $dailyTotals = array_fill(0, $daysInMonth, 1);
            $remaining = $totalQuantity - $daysInMonth;

            while ($remaining > 0) {
                $index = random_int(0, $daysInMonth - 1);
                $add = min($remaining, random_int(1, min(8, $remaining)));
                $dailyTotals[$index] += $add;
                $remaining -= $add;
            }

            foreach ($dailyTotals as $dayIndex => $dayTotal) {
                $saleDate = $periodStart->copy()->addDays($dayIndex);
                $chunks = $this->splitQuantityIntoSales($dayTotal);

                foreach ($chunks as $chunk) {
                    $productName = $this->pickWeightedProduct($weights);
                    $product = $products->get($productName);

                    if (! $product) {
                        continue;
                    }

                    $hour = random_int(9, 20);
                    $minute = random_int(0, 59);
                    $second = random_int(0, 59);
                    $createdAt = $saleDate->copy()->setTime($hour, $minute, $second);

                    OfflineSale::query()->create([
                        'transaction_code' => sprintf('SEEDED-OFFLINE-%s-%04d', $saleDate->format('Ym'), $sequence),
                        'id_user' => $marketing->id_user,
                        'id_product' => $product->id_product,
                        'nama' => $marketing->nama,
                        'nama_product' => $product->nama_product,
                        'quantity' => $chunk,
                        'harga' => $chunk * (float) $product->harga,
                        'approval_status' => 'disetujui',
                        'approved_by' => $approver->id_user,
                        'approved_at' => $createdAt->copy()->addMinutes(random_int(1, 20)),
                        'created_at' => $createdAt,
                    ]);

                    $sequence++;
                }
            }
        }
    }

    private function splitQuantityIntoSales(int $quantity): array
    {
        $chunks = [];
        $remaining = $quantity;

        while ($remaining > 0) {
            if ($remaining <= 4) {
                $chunks[] = $remaining;
                break;
            }

            $maxChunk = min(6, $remaining - 1);
            $chunk = random_int(1, $maxChunk);
            $chunks[] = $chunk;
            $remaining -= $chunk;
        }

        return $chunks;
    }

    private function pickWeightedProduct(array $weights): string
    {
        $total = array_sum($weights);
        $roll = random_int(1, $total);
        $running = 0;

        foreach ($weights as $name => $weight) {
            $running += $weight;
            if ($roll <= $running) {
                return $name;
            }
        }

        return array_key_first($weights);
    }
}

