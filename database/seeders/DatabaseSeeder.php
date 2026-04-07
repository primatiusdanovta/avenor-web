<?php

namespace Database\Seeders;

use App\Models\FragranceDetail;
use App\Models\GlobalSetting;
use App\Models\MarketingLocation;
use App\Models\OfflineSale;
use App\Models\Product;
use App\Models\ProductOnhand;
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
            ['nama' => 'field executive', 'status' => 'aktif', 'role' => 'sales_field_executive', 'password' => 'FieldExecutive123!'],
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

        foreach (['marketing', 'sales_field_executive'] as $role) {
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

        if (! app()->runningUnitTests()) {
            $this->seedReferenceProducts();
        }

        if (app()->environment('e2e')) {
            $this->seedE2eLandingContent();
            $this->seedE2eFieldTeamData();
        }

        if (! app()->runningUnitTests() && ! app()->environment('e2e')) {
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
            ['jenis' => 'fragrance family', 'detail' => 'Fruity', 'deskripsi' => 'Nuansa buah yang juicy, manis, dan cerah.'],
            ['jenis' => 'fragrance family', 'detail' => 'Powdery', 'deskripsi' => 'Nuansa lembut, halus, dan clean seperti bedak mewah.'],
            ['jenis' => 'fragrance family', 'detail' => 'Musky', 'deskripsi' => 'Nuansa musk yang hangat, bersih, dan sensual.'],
            ['jenis' => 'fragrance family', 'detail' => 'Amber', 'deskripsi' => 'Nuansa amber yang hangat, manis, dan rich.'],
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

    private function seedE2eLandingContent(): void
    {
        GlobalSetting::query()->updateOrCreate(
            ['key' => 'master_social_hub'],
            ['value' => [
                'tiktok_url' => 'https://www.tiktok.com/@avenor',
                'instagram_url' => 'https://www.instagram.com/avenor',
                'facebook_url' => 'https://www.facebook.com/avenor',
                'whatsapp_url' => 'https://wa.me/6281234567890',
                'tokopedia_url' => 'https://www.tokopedia.com/avenor/solair',
                'tiktok_shop_url' => 'https://shop.tiktok.com/view/product/172967172',
            ]]
        );

        $products = Product::query()
            ->whereIn('nama_product', ['Solair', 'Azalea', 'Sevon'])
            ->get()
            ->keyBy('nama_product');

        $e2eContent = [
            'Solair' => [
                'landing_page_active' => true,
                'seo_title' => 'Solair | Citrus Signature by Avenor',
                'seo_description' => 'Solair menghadirkan bukaan citrus cerah dengan dry down bersih dan elegan untuk pemakaian harian.',
                'landing_theme_key' => 'fresh',
                'landing_seo_fallback_key' => 'fresh',
                'top_notes_text' => 'Bergamot dan citrus segar membuka pengalaman dengan kesan terang, bersih, dan effortless.',
                'heart_notes_text' => 'Aromatic floral nuance di tengah menjaga karakter tetap modern dan wearable dari pagi sampai malam.',
                'base_notes_text' => 'Woody musk yang halus memberi trail yang rapi, dewasa, dan tidak berlebihan.',
                'education_content' => [
                    'title' => 'How to Make Solair Last Longer',
                    'body' => 'Gunakan pada kulit yang terhidrasi dan fokus di titik nadi untuk performa yang lebih stabil.',
                    'tips' => [
                        'Semprotkan pada pergelangan tangan, leher, dan area belakang telinga.',
                        'Gunakan setelah body lotion tanpa aroma agar aroma menempel lebih lama.',
                        'Jangan digosok setelah disemprot agar struktur notes tetap utuh.',
                    ],
                ],
                'faq_data' => [
                    ['question' => 'Apakah Solair cocok untuk daily use?', 'answer' => 'Ya, profil citrus woody-nya dibuat aman dan mudah dipakai untuk aktivitas harian.'],
                    ['question' => 'Lebih cocok siang atau malam?', 'answer' => 'Paling menonjol untuk siang hingga sore, tetapi masih nyaman dipakai malam hari.'],
                ],
                'details' => ['Citrus', 'Fresh', 'Versatile'],
            ],
            'Azalea' => [
                'landing_page_active' => true,
                'seo_title' => 'Azalea | Floral Sweet Luxury by Avenor',
                'seo_description' => 'Azalea menyatukan floral lembut dan nuansa sweet yang feminin untuk kesan mewah yang approachable.',
                'landing_theme_key' => 'floral',
                'landing_seo_fallback_key' => 'floral',
                'top_notes_text' => 'Nuansa floral manis membuka aroma dengan karakter lembut dan langsung terasa feminin.',
                'heart_notes_text' => 'Bagian tengah membawa body yang creamy, halus, dan romantis tanpa terasa berat.',
                'base_notes_text' => 'Dry down yang musky-soft menjaga aroma tetap elegan dan intim di kulit.',
                'education_content' => [
                    'title' => 'The Story Behind Azalea',
                    'body' => 'Azalea dirancang untuk pengguna yang menginginkan floral modern dengan kelembutan yang tetap punya presence.',
                    'tips' => [
                        'Cocok untuk meeting, brunch, dan acara semi-formal.',
                        'Layer dengan aroma body care netral untuk hasil yang lebih bersih.',
                    ],
                ],
                'faq_data' => [
                    ['question' => 'Apakah Azalea terlalu manis?', 'answer' => 'Tidak, sweetness-nya dijaga agar tetap lembut dan seimbang dengan floral accord.'],
                ],
                'details' => ['Floral', 'Sweet', 'Formal & Elegan'],
            ],
            'Sevon' => [
                'landing_page_active' => true,
                'seo_title' => 'Sevon | Woody Aromatic Elegance by Avenor',
                'seo_description' => 'Sevon menawarkan nuansa woody aromatic yang rapi, berkarakter, dan cocok untuk kesan elegan modern.',
                'landing_theme_key' => 'woody',
                'landing_seo_fallback_key' => 'woody',
                'top_notes_text' => 'Pembuka aromatic memberi kesan bersih, tegas, dan refined sejak semprotan pertama.',
                'heart_notes_text' => 'Intinya terasa woody-spiced dengan karakter maskulin yang tetap smooth.',
                'base_notes_text' => 'Akhiran amber woody membantu aroma bertahan dengan trail yang matang dan tenang.',
                'education_content' => [
                    'title' => 'When to Wear Sevon',
                    'body' => 'Sevon ideal dipakai ketika Anda ingin hadir dengan kesan rapi, tenang, dan berkelas.',
                    'tips' => [
                        'Paling cocok untuk kantor, dinner, atau evening gathering.',
                        'Gunakan 3-5 spray untuk hasil yang terasa namun tetap elegan.',
                    ],
                ],
                'faq_data' => [
                    ['question' => 'Apakah Sevon cocok untuk cuaca panas?', 'answer' => 'Masih cocok, terutama untuk penggunaan indoor atau malam hari dengan spray secukupnya.'],
                ],
                'details' => ['Woody', 'Spicy/Aromatic', 'Sensual/Intens'],
            ],
        ];

        foreach ($e2eContent as $name => $data) {
            $product = $products->get($name);

            if (! $product) {
                continue;
            }

            $product->update([
                'landing_page_active' => $data['landing_page_active'],
                'seo_title' => $data['seo_title'],
                'seo_description' => $data['seo_description'],
                'landing_theme_key' => $data['landing_theme_key'] ?? null,
                'landing_seo_fallback_key' => $data['landing_seo_fallback_key'] ?? null,
                'top_notes_text' => $data['top_notes_text'],
                'heart_notes_text' => $data['heart_notes_text'],
                'base_notes_text' => $data['base_notes_text'],
                'education_content' => $data['education_content'],
                'faq_data' => $data['faq_data'],
            ]);

            $detailIds = FragranceDetail::query()
                ->whereIn('detail', $data['details'])
                ->pluck('id_fd')
                ->all();

            $product->fragranceDetails()->syncWithoutDetaching($detailIds);
        }
    }

    private function seedE2eFieldTeamData(): void
    {
        $marketing = User::query()->where('nama', 'marketing')->first();
        $fieldExecutive = User::query()->where('role', 'sales_field_executive')->first();

        if (! $marketing || ! $fieldExecutive) {
            return;
        }

        $products = Product::query()
            ->whereIn('nama_product', ['Solair', 'Sevon'])
            ->get()
            ->keyBy('nama_product');

        $solair = $products->get('Solair');
        $sevon = $products->get('Sevon');

        if (! $solair || ! $sevon) {
            return;
        }

        $solair->update(['stock' => max((int) $solair->stock, 12)]);
        $sevon->update(['stock' => max((int) $sevon->stock, 10)]);

        MarketingLocation::query()->whereIn('user_id', [$marketing->id_user, $fieldExecutive->id_user])->delete();
        ProductOnhand::query()->whereIn('user_id', [$marketing->id_user, $fieldExecutive->id_user])->delete();

        MarketingLocation::query()->create([
            'user_id' => $marketing->id_user,
            'latitude' => -6.2088,
            'longitude' => 106.8456,
            'source' => 'gps',
            'recorded_at' => now()->subMinutes(8),
        ]);

        MarketingLocation::query()->create([
            'user_id' => $fieldExecutive->id_user,
            'latitude' => -6.2,
            'longitude' => 106.8166,
            'source' => 'gps',
            'recorded_at' => now()->subMinutes(5),
        ]);

        ProductOnhand::query()->create([
            'user_id' => $marketing->id_user,
            'id_product' => $solair->id_product,
            'nama_product' => $solair->nama_product,
            'quantity' => 4,
            'quantity_dikembalikan' => 0,
            'approved_return_quantity' => 0,
            'manual_sold_quantity' => 1,
            'pickup_batch_code' => 'E2E-MKT-SOLAIR-01',
            'take_status' => 'disetujui',
            'return_status' => 'belum',
            'approved_by' => null,
            'take_approved_by' => null,
            'assignment_date' => now()->toDateString(),
            'created_at' => now()->subHours(4),
            'take_requested_at' => now()->subHours(4),
            'take_reviewed_at' => now()->subHours(4),
        ]);

        ProductOnhand::query()->create([
            'user_id' => $fieldExecutive->id_user,
            'id_product' => $sevon->id_product,
            'nama_product' => $sevon->nama_product,
            'quantity' => 3,
            'quantity_dikembalikan' => 0,
            'approved_return_quantity' => 0,
            'manual_sold_quantity' => 1,
            'pickup_batch_code' => 'E2E-SFE-SEVON-01',
            'take_status' => 'disetujui',
            'return_status' => 'belum',
            'approved_by' => null,
            'take_approved_by' => null,
            'assignment_date' => now()->toDateString(),
            'created_at' => now()->subHours(3),
            'take_requested_at' => now()->subHours(3),
            'take_reviewed_at' => now()->subHours(3),
        ]);
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
