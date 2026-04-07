<?php

use App\Models\Consignment;
use App\Models\MarketingNotification;
use App\Models\Product;
use App\Models\ProductImage;
use App\Services\MarketingPushNotificationService;
use App\Support\AccountReceivableSupport;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('media:audit-product-images {--clean : Bersihkan referensi image yang path filenya sudah tidak ada}', function () {
    $disk = Storage::disk('public');
    $shouldClean = (bool) $this->option('clean');
    $hasBottleImageColumn = Schema::hasColumn('products', 'bottle_image');

    $missingMainImages = Product::query()
        ->whereNotNull('gambar')
        ->get()
        ->filter(fn (Product $product) => $product->normalized_image_path && ! $disk->exists($product->normalized_image_path))
        ->values();

    $missingBottleImages = $hasBottleImageColumn
        ? Product::query()
            ->whereNotNull('bottle_image')
            ->get()
            ->filter(fn (Product $product) => $product->normalized_bottle_image_path && ! $disk->exists($product->normalized_bottle_image_path))
            ->values()
        : collect();

    $missingGalleryImages = ProductImage::query()
        ->with('product:id_product,nama_product')
        ->get()
        ->filter(fn (ProductImage $image) => $image->normalized_image_path && ! $disk->exists($image->normalized_image_path))
        ->values();

    $this->info('Audit image selesai.');
    $this->newLine();
    $this->line('Ringkasan:');
    $this->line('- Main image hilang: ' . $missingMainImages->count());
    $this->line('- Bottle image hilang: ' . $missingBottleImages->count());
    $this->line('- Gallery image hilang: ' . $missingGalleryImages->count());
    $this->newLine();

    if (! $hasBottleImageColumn) {
        $this->comment('Kolom bottle_image belum ada di database saat ini, jadi audit bottle image dilewati. Jalankan migration terbaru jika fitur bottle image ingin ikut diaudit.');
        $this->newLine();
    }

    if ($missingMainImages->isNotEmpty()) {
        $this->warn('Main image bermasalah:');
        foreach ($missingMainImages as $product) {
            $this->line("  - Product #{$product->id_product} {$product->nama_product} | {$product->gambar}");
        }
        $this->newLine();
    }

    if ($missingBottleImages->isNotEmpty()) {
        $this->warn('Bottle image bermasalah:');
        foreach ($missingBottleImages as $product) {
            $this->line("  - Product #{$product->id_product} {$product->nama_product} | {$product->bottle_image}");
        }
        $this->newLine();
    }

    if ($missingGalleryImages->isNotEmpty()) {
        $this->warn('Gallery image bermasalah:');
        foreach ($missingGalleryImages as $image) {
            $productName = $image->product?->nama_product ?: 'Unknown Product';
            $this->line("  - Gallery #{$image->id} | Product {$productName} | {$image->image_path}");
        }
        $this->newLine();
    }

    if (! $shouldClean) {
        $this->comment('Mode audit saja. Jalankan lagi dengan --clean untuk membersihkan referensi invalid dari database.');
        return self::SUCCESS;
    }

    DB::transaction(function () use ($missingMainImages, $missingBottleImages, $missingGalleryImages): void {
        foreach ($missingMainImages as $product) {
            $product->update([
                'gambar' => null,
            ]);
        }

        foreach ($missingBottleImages as $product) {
            $product->update([
                'bottle_image' => null,
            ]);
        }

        foreach ($missingGalleryImages as $image) {
            $image->delete();
        }
    });

    $this->info('Referensi invalid berhasil dibersihkan dari database.');

    return self::SUCCESS;
})->purpose('Audit dan opsional membersihkan referensi image product yang file fisiknya hilang');

Artisan::command('marketing-notifications:dispatch-scheduled', function (MarketingPushNotificationService $pushNotificationService) {
    $dueNotifications = MarketingNotification::query()
        ->where('status', 'scheduled')
        ->whereNotNull('scheduled_at')
        ->where('scheduled_at', '<=', now())
        ->get();

    if ($dueNotifications->isEmpty()) {
        $this->info('Tidak ada notifikasi terjadwal yang perlu dipublikasikan.');
        return self::SUCCESS;
    }

    foreach ($dueNotifications as $notification) {
        $notification->update([
            'status' => 'published',
            'published_at' => now(),
        ]);

        $result = $pushNotificationService->sendPublishedNotification($notification->fresh());
        $this->line("Notification #{$notification->id} dipublikasikan. Push terkirim: {$result['sent']}");
    }

    return self::SUCCESS;
})->purpose('Publikasikan notifikasi marketing terjadwal dan kirim push notification');

Artisan::command('account-receivables:backfill {--chunk=100 : Jumlah consignments yang diproses per batch}', function () {
    if (! Schema::hasTable('consignments') || ! Schema::hasTable('consignment_items') || ! Schema::hasTable('account_receivables')) {
        $this->error('Table consignments, consignment_items, atau account_receivables belum tersedia.');
        return self::FAILURE;
    }

    $chunkSize = max((int) $this->option('chunk'), 1);
    $processed = 0;
    $createdOrUpdated = 0;
    $skipped = 0;

    Consignment::query()
        ->with('items')
        ->orderBy('id')
        ->chunk($chunkSize, function ($consignments) use (&$processed, &$createdOrUpdated, &$skipped) {
            foreach ($consignments as $consignment) {
                $processed++;

                if ($consignment->items->isEmpty()) {
                    $skipped++;
                    continue;
                }

                $receivable = AccountReceivableSupport::syncFromConsignment($consignment);
                if ($receivable) {
                    $createdOrUpdated++;
                } else {
                    $skipped++;
                }
            }
        });

    $this->info('Backfill account receivables selesai.');
    $this->line('Consign diproses: ' . $processed);
    $this->line('AR dibuat/diperbarui: ' . $createdOrUpdated);
    $this->line('Dilewati: ' . $skipped);

    return self::SUCCESS;
})->purpose('Backfill atau sinkron ulang account receivables dari seluruh data consign');
