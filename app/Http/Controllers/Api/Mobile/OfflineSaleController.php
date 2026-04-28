<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Customer;
use App\Models\ExtraTopping;
use App\Models\GlobalSetting;
use App\Models\OfflineSale;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\Promo;
use App\Models\Sop;
use App\Models\User;
use App\Support\MarketingMobileSupport;
use App\Support\RawMaterialUsage;
use App\Support\SalesRole;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class OfflineSaleController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless(in_array($user?->role, SalesRole::mobileRoles(), true), 403);
        $storeId = MarketingMobileSupport::currentStoreId($user);

        $sales = OfflineSale::query()
            ->with('customer')
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
            ->where('id_user', $user->id_user)
            ->orderByDesc('created_at')
            ->orderByDesc('id_penjualan_offline')
            ->get();

        $transactions = $this->transformTransactions($sales);
        $products = MarketingMobileSupport::isSmoothiesSweetieUser($user)
            ? Product::query()
                ->with('images')
                ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
                ->where('stock', '>', 0)
                ->orderBy('nama_product')
                ->get(['id_product', 'nama_product', 'harga', 'stock', 'gambar'])
                ->map(fn (Product $product) => [
                    'id_product' => $product->id_product,
                    'nama_product' => $product->nama_product,
                    'harga' => (float) $product->harga,
                    'stock' => (int) $product->stock,
                    'remaining' => (int) $product->stock,
                    'gambar' => $product->public_image_url,
                    'image_url' => $product->public_image_url,
                    'option_label' => $product->nama_product . ' | stock ' . (int) $product->stock,
                    'variants' => ProductVariant::query()
                        ->where('product_id', $product->id_product)
                        ->orderByDesc('is_default')
                        ->orderBy('name')
                        ->get()
                        ->map(fn (ProductVariant $variant) => [
                            'id' => $variant->id,
                            'name' => $variant->name,
                            'price' => (float) $variant->price,
                            'total_satuan_ml' => (float) $variant->total_satuan_ml,
                            'is_default' => (bool) $variant->is_default,
                        ])
                        ->values(),
                ])
                ->values()
            : Product::query()
                ->with('images')
                ->select('products.id_product', 'products.nama_product', 'products.harga', 'products.gambar')
                ->join('product_onhands', 'product_onhands.id_product', '=', 'products.id_product')
                ->when($storeId, fn ($query) => $query->where('products.store_id', $storeId)->where('product_onhands.store_id', $storeId))
                ->where('product_onhands.user_id', $user->id_user)
                ->where('product_onhands.take_status', 'disetujui')
                ->groupBy('products.id_product', 'products.nama_product', 'products.harga')
                ->get()
                ->map(function (Product $product) use ($user) {
                    $onhand = MarketingMobileSupport::resolveOnhandForSale($user->id_user, $product->id_product);
                    $remaining = $onhand ? MarketingMobileSupport::availableForOnhand($onhand) : 0;

                    return [
                        'id_product' => $product->id_product,
                        'nama_product' => $product->nama_product,
                        'harga' => (float) $product->harga,
                        'remaining' => $remaining,
                        'gambar' => $product->public_image_url,
                        'image_url' => $product->public_image_url,
                        'option_label' => $product->nama_product . ' | Sisa ' . $remaining,
                        'variants' => ProductVariant::query()
                            ->where('product_id', $product->id_product)
                            ->orderByDesc('is_default')
                            ->orderBy('name')
                            ->get()
                            ->map(fn (ProductVariant $variant) => [
                                'id' => $variant->id,
                                'name' => $variant->name,
                                'price' => (float) $variant->price,
                                'total_satuan_ml' => (float) $variant->total_satuan_ml,
                                'is_default' => (bool) $variant->is_default,
                            ])
                            ->values(),
                    ];
                })
                ->filter(fn (array $product) => $product['remaining'] > 0)
                ->values();

        $promos = Promo::query()
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
            ->whereDate('masa_aktif', '>=', today())
            ->orderBy('nama_promo')
            ->get()
            ->map(fn (Promo $promo) => [
                'id' => $promo->id,
                'kode_promo' => $promo->kode_promo,
                'nama_promo' => $promo->nama_promo,
                'potongan' => (float) $promo->potongan,
                'masa_aktif' => optional($promo->masa_aktif)->format('Y-m-d'),
                'minimal_quantity' => (int) $promo->minimal_quantity,
                'minimal_belanja' => (float) $promo->minimal_belanja,
                'option_label' => $promo->nama_promo . ' | ' . $promo->kode_promo,
            ])
            ->values();

        return response()->json([
            'sales' => $transactions,
            'products' => $products,
            'promos' => $promos,
            'extra_toppings' => ExtraTopping::query()
                ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
                ->where('is_active', true)
                ->orderBy('name')
                ->get()
                ->map(fn (ExtraTopping $item) => [
                    'id' => $item->id,
                    'name' => $item->name,
                    'price' => (float) $item->price,
                ])
                ->values(),
            'sops' => Sop::query()
                ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
                ->orderBy('title')
                ->get()
                ->map(fn (Sop $item) => [
                    'id_sop' => $item->id_sop,
                    'title' => $item->title,
                    'detail' => $item->detail,
                ])
                ->values(),
            'qris_image_url' => data_get(GlobalSetting::masterSocialHub(), 'sales_qr_url'),
            'is_smoothies_sweetie' => MarketingMobileSupport::isSmoothiesSweetieUser($user),
        ]);
    }

    public function findCustomer(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless(in_array($user?->role, SalesRole::mobileRoles(), true), 403);

        $phone = MarketingMobileSupport::normalizePhone($request->query('phone'));

        if (! $phone) {
            return response()->json(['customer' => null]);
        }

        $customer = Customer::query()
            ->when(MarketingMobileSupport::currentStoreId($user), fn ($query, $storeId) => $query->where('store_id', $storeId))
            ->where('no_telp', $phone)
            ->first();

        return response()->json([
            'customer' => $customer ? [
                'id_pelanggan' => $customer->id_pelanggan,
                'nama' => $customer->nama,
                'no_telp' => $customer->no_telp,
                'tiktok_instagram' => $customer->tiktok_instagram,
                'pembelian_terakhir' => optional($customer->pembelian_terakhir)->format('Y-m-d H:i:s'),
            ] : null,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless(in_array($user?->role, SalesRole::mobileRoles(), true), 403);

        $requiresAttendance = $user?->role !== SalesRole::OWNER;

        if ($requiresAttendance) {
            $attendance = Attendance::query()
                ->when(MarketingMobileSupport::currentStoreId($user), fn ($query, $storeId) => $query->where('store_id', $storeId))
                ->where('user_id', $user->id_user)
                ->whereDate('attendance_date', now()->toDateString())
                ->first();

            if (! $attendance?->check_in) {
                return response()->json(['message' => 'Sales lapangan wajib check in terlebih dahulu sebelum melakukan penjualan.'], 422);
            }

            if ($attendance?->check_out) {
                return response()->json(['message' => 'Marketing yang sudah check out tidak bisa melakukan penjualan lagi hari ini.'], 422);
            }
        }

        $validated = $this->validateTransactionPayload($request, ! MarketingMobileSupport::isSmoothiesSweetieUser($user));
        [$products, $promo, $lineSubtotals, $onhands, $totalQuantity, $subtotal, $storeId, $variants, $extraToppings] = $this->prepareTransactionContext($validated, $user->id_user);
        $this->validatePromoEligibility($promo, $totalQuantity, $subtotal);

        $path = $request->file('bukti_pembelian')?->store('offline-sales', 'public');
        $timestamp = now();
        $transactionCode = $this->generateTransactionCode();
        $saleNumber = $this->generateSaleNumber($storeId, $timestamp);
        $discounts = $this->allocateDiscounts($lineSubtotals, (float) ($promo?->potongan ?? 0));

        DB::transaction(function () use ($validated, $user, $products, $promo, $path, $timestamp, $discounts, $lineSubtotals, $onhands, $transactionCode, $saleNumber, $storeId, $variants, $extraToppings): void {
            $customer = $this->resolveCustomer($validated, $timestamp, $storeId);

            foreach ($validated['items'] as $index => $item) {
                $product = $products->get($item['id_product']);
                $variant = $variants[(int) ($item['product_variant_id'] ?? 0)] ?? null;
                $selectedExtraToppings = collect($item['extra_topping_ids'] ?? [])
                    ->map(fn ($id) => $extraToppings[(int) $id] ?? null)
                    ->filter()
                    ->values();
                $extraToppingTotal = round($selectedExtraToppings->sum('price') * (int) $item['quantity'], 2);
                $lineSubtotal = $lineSubtotals[$index] ?? 0;
                $lineDiscount = $discounts[$index] ?? 0;

                OfflineSale::query()->create([
                    'store_id' => $storeId,
                    'transaction_code' => $transactionCode,
                    'sale_number' => $saleNumber,
                    'id_user' => $user->id_user,
                    'id_pelanggan' => $customer?->id_pelanggan,
                    'id_product' => $product?->id_product,
                    'product_variant_id' => $variant?->id,
                    'product_variant_name' => $variant?->name,
                    'unit_price' => (float) ($variant?->price ?? $product?->harga ?? 0),
                    'extra_topping_total' => $extraToppingTotal,
                    'extra_toppings' => $selectedExtraToppings->map(fn ($topping) => ['id' => $topping->id, 'name' => $topping->name, 'price' => (float) $topping->price])->all(),
                    'sugar_level' => $this->normalizeSugarLevel($item['sugar_level'] ?? null),
                    'payment_method' => $validated['payment_method'] ?? 'Cash',
                    'payment_status' => 'paid',
                    'paid_at' => $timestamp,
                    'id_product_onhand' => $onhands[(int) $item['id_product']]?->id_product_onhand ?? null,
                    'promo_id' => $promo?->id,
                    'nama' => $user->nama,
                    'nama_product' => trim(($product?->nama_product ?? '') . ($variant?->name ? ' - ' . $variant->name : '')),
                    'quantity' => (int) $item['quantity'],
                    'harga' => max($lineSubtotal - $lineDiscount, 0),
                    'total_hpp' => $this->resolveProductHpp($product, $variant),
                    'kode_promo' => $promo?->kode_promo,
                    'promo' => $promo?->nama_promo,
                    'bukti_pembelian' => $path,
                    'approval_status' => MarketingMobileSupport::isSmoothiesSweetieUser($user) ? 'disetujui' : 'pending',
                    'approved_by' => MarketingMobileSupport::isSmoothiesSweetieUser($user) ? $user->id_user : null,
                    'approved_at' => MarketingMobileSupport::isSmoothiesSweetieUser($user) ? $timestamp : null,
                    'created_at' => $timestamp,
                ]);
            }
        });

        return response()->json([
            'message' => 'Penjualan offline berhasil disimpan.',
            'transaction_code' => $transactionCode,
            'sale_number' => $saleNumber,
            'created_at' => $timestamp->format('Y-m-d H:i:s'),
            'customer_name' => trim((string) ($validated['customer_nama'] ?? '')) ?: null,
            'total_amount' => max(round($subtotal - (float) ($promo?->potongan ?? 0), 2), 0),
        ], 201);
    }

    public function update(Request $request, OfflineSale $sale): JsonResponse
    {
        $user = $request->user();
        abort_unless($sale->store_id === MarketingMobileSupport::currentStoreId($user), 403);

        $transactionSales = $this->transactionSales($sale, $user);
        abort_unless($this->canManageTransaction($user, $transactionSales), 403);

        $validated = $this->validateTransactionPayload($request, ! MarketingMobileSupport::isSmoothiesSweetieUser($user));
        [$products, $promo, $lineSubtotals, $onhands, $totalQuantity, $subtotal, $storeId, $variants, $extraToppings] = $this->prepareTransactionContext(
            $validated,
            (int) $sale->id_user
        );

        $this->validatePromoEligibility($promo, $totalQuantity, $subtotal);

        $timestamp = $sale->created_at ?? now();
        $discounts = $this->allocateDiscounts($lineSubtotals, (float) ($promo?->potongan ?? 0));

        DB::transaction(function () use ($validated, $sale, $transactionSales, $products, $promo, $timestamp, $discounts, $lineSubtotals, $storeId, $variants, $extraToppings): void {
            $customer = $this->resolveCustomer($validated, $timestamp instanceof Carbon ? $timestamp : Carbon::parse($timestamp), $storeId);
            $existingById = $transactionSales->keyBy('id_penjualan_offline');
            $keepIds = [];

            foreach ($validated['items'] as $index => $item) {
                $product = $products->get($item['id_product']);
                $variant = $variants[(int) ($item['product_variant_id'] ?? 0)] ?? null;
                $selectedExtraToppings = collect($item['extra_topping_ids'] ?? [])
                    ->map(fn ($id) => $extraToppings[(int) $id] ?? null)
                    ->filter()
                    ->values();
                $lineSubtotal = $lineSubtotals[$index] ?? 0;
                $lineDiscount = $discounts[$index] ?? 0;
                $lineHpp = $this->resolveProductHpp($product, $variant);
                $existing = $existingById->get((int) ($item['id_penjualan_offline'] ?? 0));
                $extraToppingTotal = round($selectedExtraToppings->sum('price') * (int) $item['quantity'], 2);
                $sugarLevel = $this->normalizeSugarLevel($item['sugar_level'] ?? null);

                if ($existing) {
                    $existing->update([
                        'id_pelanggan' => $customer?->id_pelanggan,
                        'promo_id' => $promo?->id,
                        'product_variant_id' => $variant?->id,
                        'product_variant_name' => $variant?->name,
                        'unit_price' => (float) ($variant?->price ?? $product?->harga ?? 0),
                        'extra_topping_total' => $extraToppingTotal,
                        'extra_toppings' => $selectedExtraToppings->map(fn ($topping) => [
                            'id' => $topping->id,
                            'name' => $topping->name,
                            'price' => (float) $topping->price,
                        ])->all(),
                        'sugar_level' => $sugarLevel,
                        'payment_method' => $validated['payment_method'] ?? $existing->payment_method ?? 'Cash',
                        'nama_product' => trim(($product?->nama_product ?? '') . ($variant?->name ? ' - ' . $variant->name : '')),
                        'quantity' => (int) $item['quantity'],
                        'harga' => max($lineSubtotal - $lineDiscount, 0),
                        'total_hpp' => $lineHpp,
                        'kode_promo' => $promo?->kode_promo,
                        'promo' => $promo?->nama_promo,
                    ]);

                    $keepIds[] = $existing->id_penjualan_offline;
                    continue;
                }

                $created = OfflineSale::query()->create([
                    'store_id' => $storeId,
                    'transaction_code' => $sale->transaction_code,
                    'sale_number' => $sale->sale_number,
                    'id_user' => $sale->id_user,
                    'id_pelanggan' => $customer?->id_pelanggan,
                    'id_product' => $product?->id_product,
                    'product_variant_id' => $variant?->id,
                    'product_variant_name' => $variant?->name,
                    'unit_price' => (float) ($variant?->price ?? $product?->harga ?? 0),
                    'extra_topping_total' => $extraToppingTotal,
                    'extra_toppings' => $selectedExtraToppings->map(fn ($topping) => [
                        'id' => $topping->id,
                        'name' => $topping->name,
                        'price' => (float) $topping->price,
                    ])->all(),
                    'sugar_level' => $sugarLevel,
                    'payment_method' => $validated['payment_method'] ?? $sale->payment_method ?? 'Cash',
                    'payment_status' => $sale->payment_status,
                    'paid_at' => $sale->paid_at,
                    'id_product_onhand' => $sale->id_product_onhand,
                    'promo_id' => $promo?->id,
                    'nama' => $sale->nama,
                    'nama_product' => trim(($product?->nama_product ?? '') . ($variant?->name ? ' - ' . $variant->name : '')),
                    'quantity' => (int) $item['quantity'],
                    'harga' => max($lineSubtotal - $lineDiscount, 0),
                    'total_hpp' => $lineHpp,
                    'kode_promo' => $promo?->kode_promo,
                    'promo' => $promo?->nama_promo,
                    'bukti_pembelian' => $sale->bukti_pembelian,
                    'approval_status' => $sale->approval_status,
                    'approved_by' => $sale->approved_by,
                    'approved_at' => $sale->approved_at,
                    'created_at' => $sale->created_at,
                    'closed_at' => $sale->closed_at,
                ]);

                $keepIds[] = $created->id_penjualan_offline;
            }

            $transactionSales
                ->whereNotIn('id_penjualan_offline', $keepIds)
                ->each
                ->delete();
        });

        return response()->json([
            'message' => 'Transaksi penjualan offline berhasil diperbarui.',
        ]);
    }

    public function destroy(Request $request, OfflineSale $sale): JsonResponse
    {
        $user = $request->user();
        abort_unless($sale->store_id === MarketingMobileSupport::currentStoreId($user), 403);

        $transactionSales = $this->transactionSales($sale, $user);
        abort_unless($this->canManageTransaction($user, $transactionSales), 403);

        $receiptPath = $sale->bukti_pembelian;

        DB::transaction(function () use ($transactionSales): void {
            $transactionSales->each->delete();
        });

        if ($receiptPath) {
            $isSharedReceipt = OfflineSale::query()
                ->where('bukti_pembelian', $receiptPath)
                ->exists();

            if (! $isSharedReceipt) {
                Storage::disk('public')->delete($receiptPath);
            }
        }

        return response()->json([
            'message' => 'Transaksi penjualan offline berhasil dihapus.',
        ]);
    }

    public function queue(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless(in_array($user?->role, SalesRole::mobileRoles(), true), 403);

        $storeId = MarketingMobileSupport::currentStoreId($user);
        $items = OfflineSale::query()
            ->with('customer')
            ->where('store_id', $storeId)
            ->whereNotNull('sale_number')
            ->where('payment_status', '!=', 'closed')
            ->orderBy('created_at')
            ->get()
            ->groupBy('sale_number')
            ->map(function (Collection $sales, string $saleNumber) {
                $first = $sales->first();
                $queueNumber = (int) trim((string) str($saleNumber)->afterLast('-'));

                return [
                    'sale_number' => $saleNumber,
                    'queue_number' => $queueNumber,
                    'transaction_code' => $first?->transaction_code,
                    'customer_name' => $first?->customer?->nama,
                    'payment_status' => $first?->payment_status,
                    'created_at' => optional($first?->created_at)->format('Y-m-d H:i:s'),
                    'details' => $sales->map(fn (OfflineSale $sale) => [
                        'nama_product' => $sale->nama_product,
                        'product_variant_name' => $sale->product_variant_name,
                        'quantity' => (int) $sale->quantity,
                        'sugar_level' => $this->normalizeSugarLevel($sale->sugar_level),
                        'extra_toppings' => collect($sale->extra_toppings ?? [])
                            ->pluck('name')
                            ->filter()
                            ->values()
                            ->all(),
                    ])->values()->all(),
                ];
            })
            ->sortBy('queue_number')
            ->values()
            ->all();

        return response()->json([
            'items' => $items,
            'can_close' => in_array($user->role, [SalesRole::OWNER, SalesRole::KARYAWAN], true),
        ]);
    }

    public function closeQueue(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless(in_array($user?->role, [SalesRole::OWNER, SalesRole::KARYAWAN], true), 403);

        $validated = $request->validate([
            'sale_number' => ['required', 'string'],
        ]);

        OfflineSale::query()
            ->where('store_id', MarketingMobileSupport::currentStoreId($user))
            ->where('sale_number', trim((string) $validated['sale_number']))
            ->update([
                'payment_status' => 'closed',
                'closed_at' => now(),
            ]);

        return response()->json([
            'message' => 'Antrian selesai dan sudah ditutup.',
        ]);
    }

    public function showProof(Request $request, OfflineSale $sale)
    {
        abort_unless((int) $sale->id_user === (int) $request->user()->id_user, 403);
        abort_if(! $sale->bukti_pembelian, 404);
        abort_unless(Storage::disk('public')->exists($sale->bukti_pembelian), 404);

        return Storage::disk('public')->response($sale->bukti_pembelian);
    }

    private function transformTransactions(Collection $sales): Collection
    {
        return $sales
            ->groupBy(fn (OfflineSale $sale) => $sale->transaction_code ?: 'legacy-' . $sale->id_penjualan_offline)
            ->map(function (Collection $items) {
                $first = $items->first();

                return [
                    'transaction_code' => $first->transaction_code,
                    'sale_number' => $first->sale_number,
                    'id_penjualan_offline' => $first->id_penjualan_offline,
                    'nama_customer' => $first->customer?->nama,
                    'no_telp' => $first->customer?->no_telp,
                    'tiktok_instagram' => $first->customer?->tiktok_instagram,
                    'promo_id' => $first->promo_id,
                    'promo' => $first->promo,
                    'kode_promo' => $first->kode_promo,
                    'payment_method' => $first->payment_method,
                    'payment_status' => $first->payment_status,
                    'approval_status' => $first->approval_status,
                    'bukti_pembelian_url' => $first->bukti_pembelian ? route('api.mobile.offline-sales.proof', ['sale' => $first]) : null,
                    'created_at' => optional($first->created_at)->format('Y-m-d H:i:s'),
                    'total_quantity' => (int) $items->sum('quantity'),
                    'total_harga' => (float) $items->sum('harga'),
                    'items' => $items->map(fn (OfflineSale $sale) => [
                        'id_penjualan_offline' => $sale->id_penjualan_offline,
                        'id_product' => $sale->id_product,
                        'nama_product' => $sale->nama_product,
                        'product_variant_id' => $sale->product_variant_id,
                        'product_variant_name' => $sale->product_variant_name,
                        'extra_topping_ids' => collect($sale->extra_toppings ?? [])->pluck('id')->values()->all(),
                        'sugar_level' => $this->normalizeSugarLevel($sale->sugar_level),
                        'extra_toppings' => collect($sale->extra_toppings ?? [])->map(fn ($topping) => [
                            'id' => $topping['id'] ?? null,
                            'name' => $topping['name'] ?? null,
                            'price' => (float) ($topping['price'] ?? 0),
                        ])->values()->all(),
                        'quantity' => (int) $sale->quantity,
                        'harga' => (float) $sale->harga,
                    ])->values(),
                ];
            })
            ->sortByDesc('created_at')
            ->values();
    }

    private function validateTransactionPayload(Request $request, bool $requireReceipt = true): array
    {
        return $request->validate([
            'customer_nama' => ['nullable', 'string', 'max:255'],
            'customer_no_telp' => ['nullable', 'string', 'max:30'],
            'customer_tiktok_instagram' => ['nullable', 'string', 'max:255'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.id_product' => ['required', 'exists:products,id_product'],
            'items.*.product_variant_id' => ['nullable', 'exists:product_variants,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
            'items.*.extra_topping_ids' => ['nullable', 'array'],
            'items.*.extra_topping_ids.*' => ['integer', 'exists:extra_toppings,id'],
            'items.*.sugar_level' => ['nullable', 'in:Normal,Less,No Sugar'],
            'promo_id' => ['nullable', 'exists:promos,id'],
            'payment_method' => ['nullable', 'in:Cash,Qris'],
        ], [
        ]);
    }

    private function normalizeSugarLevel(?string $value): string
    {
        $normalized = trim((string) $value);

        return in_array($normalized, ['Normal', 'Less', 'No Sugar'], true)
            ? $normalized
            : 'Normal';
    }

    private function transactionSales(OfflineSale $sale, User $user): Collection
    {
        return OfflineSale::query()
            ->where('store_id', MarketingMobileSupport::currentStoreId($user))
            ->where('transaction_code', $sale->transaction_code)
            ->orderBy('id_penjualan_offline')
            ->get();
    }

    private function canManageTransaction(User $user, Collection $transactionSales): bool
    {
        if ($user->role === SalesRole::OWNER) {
            return true;
        }

        return $transactionSales->every(
            fn (OfflineSale $item) => (int) $item->id_user === (int) $user->id_user
        );
    }

    private function prepareTransactionContext(array $validated, int $userId): array
    {
        $productIds = collect($validated['items'])->pluck('id_product')->all();
        $requestedByProduct = collect($validated['items'])
            ->groupBy('id_product')
            ->map(fn (Collection $items) => (int) $items->sum(fn ($item) => (int) ($item['quantity'] ?? 0)))
            ->all();
        $user = \App\Models\User::query()->find($userId);
        $storeId = $user ? MarketingMobileSupport::currentStoreId($user) : null;
        $products = Product::query()
            ->with('hppCalculation')
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
            ->whereIn('id_product', $productIds)
            ->get()
            ->keyBy('id_product');
        $promo = empty($validated['promo_id'])
            ? null
            : Promo::query()
                ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
                ->findOrFail($validated['promo_id']);
        $requiresOnhand = $user ? ! MarketingMobileSupport::isSmoothiesSweetieUser($user) : true;
        $variantIds = collect($validated['items'])->pluck('product_variant_id')->filter()->map(fn ($id) => (int) $id)->all();
        $variants = ProductVariant::query()->whereIn('id', $variantIds)->get()->keyBy('id')->all();
        $extraToppingIds = collect($validated['items'])->flatMap(fn ($item) => $item['extra_topping_ids'] ?? [])->filter()->map(fn ($id) => (int) $id)->all();
        $extraToppings = ExtraTopping::query()->whereIn('id', $extraToppingIds)->get()->keyBy('id')->all();

        $lineSubtotals = [];
        $onhands = [];
        $totalQuantity = 0;
        $subtotal = 0.0;

        foreach ($validated['items'] as $item) {
            $product = $products->get($item['id_product']);
            $quantity = (int) $item['quantity'];
            $variant = $variants[(int) ($item['product_variant_id'] ?? 0)] ?? null;
            $unitPrice = (float) ($variant?->price ?? $product?->harga ?? 0);
            $extraToppingTotal = collect($item['extra_topping_ids'] ?? [])
                ->sum(fn ($id) => (float) ($extraToppings[(int) $id]?->price ?? 0)) * $quantity;
            $lineSubtotal = ($unitPrice * $quantity) + $extraToppingTotal;

            $lineSubtotals[] = $lineSubtotal;
            $totalQuantity += $quantity;
            $subtotal += $lineSubtotal;

            if ($requiresOnhand) {
                $onhand = MarketingMobileSupport::resolveOnhandForSale($userId, (int) $item['id_product']);

                if (! $onhand) {
                    throw ValidationException::withMessages([
                        'items' => 'Ada product yang belum tersedia di on hand untuk dijual.',
                    ]);
                }

                if ($quantity > MarketingMobileSupport::availableForOnhand($onhand)) {
                    throw ValidationException::withMessages([
                        'items' => 'Quantity penjualan melebihi barang yang dibawa.',
                    ]);
                }

                $onhands[(int) $item['id_product']] = $onhand;
            } elseif ($product && ((int) ($requestedByProduct[(int) $item['id_product']] ?? 0)) > (int) $product->stock) {
                throw ValidationException::withMessages([
                    'items' => 'Quantity penjualan melebihi stok product yang tersedia di toko.',
                ]);
            }
        }

        return [$products, $promo, $lineSubtotals, $onhands, $totalQuantity, $subtotal, $storeId, $variants, $extraToppings];
    }

    private function validatePromoEligibility(?Promo $promo, int $totalQuantity, float $subtotal): void
    {
        if (! $promo) {
            return;
        }

        if ($promo->masa_aktif->lt(today())) {
            throw ValidationException::withMessages([
                'promo_id' => 'Promo sudah tidak aktif.',
            ]);
        }

        if ($totalQuantity < $promo->minimal_quantity || $subtotal < (float) $promo->minimal_belanja) {
            throw ValidationException::withMessages([
                'promo_id' => 'Pembelian belum mencapai syarat.',
            ]);
        }
    }

    private function resolveCustomer(array $validated, Carbon $timestamp, ?int $storeId): ?Customer
    {
        $nama = trim((string) ($validated['customer_nama'] ?? ''));
        $phone = MarketingMobileSupport::normalizePhone($validated['customer_no_telp'] ?? null);
        $social = trim((string) ($validated['customer_tiktok_instagram'] ?? ''));

        if ($nama === '' && $phone === '') {
            return null;
        }

        $payload = [
            'store_id' => $storeId,
            'nama' => $nama !== '' ? $nama : null,
            'no_telp' => $phone !== '' ? $phone : null,
            'tiktok_instagram' => $social !== '' ? $social : null,
            'pembelian_terakhir' => $timestamp,
        ];

        $customerQuery = Customer::query()
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId));

        $customer = $phone !== ''
            ? (clone $customerQuery)->where('no_telp', $phone)->first()
            : null;

        if (! $customer && $nama !== '') {
            $customer = (clone $customerQuery)->where('nama', $nama)->first();
        }

        if ($customer) {
            $customer->update([
                'nama' => $payload['nama'] ?? $customer->nama,
                'no_telp' => $payload['no_telp'] ?? $customer->no_telp,
                'tiktok_instagram' => $payload['tiktok_instagram'] ?? $customer->tiktok_instagram,
                'pembelian_terakhir' => $timestamp,
            ]);

            return $customer->fresh();
        }

        $payload['created_at'] = $timestamp;

        return Customer::query()->create($payload);
    }

    private function allocateDiscounts(array $lineSubtotals, float $discount): array
    {
        $discount = max(round($discount, 2), 0);
        $subtotal = array_sum($lineSubtotals);

        if ($discount <= 0 || $subtotal <= 0) {
            return array_fill(0, count($lineSubtotals), 0.0);
        }

        $allocated = [];
        $remaining = $discount;
        $lastIndex = array_key_last($lineSubtotals);

        foreach ($lineSubtotals as $index => $lineSubtotal) {
            if ($index === $lastIndex) {
                $allocated[$index] = min($remaining, $lineSubtotal);
                continue;
            }

            $portion = round(($lineSubtotal / $subtotal) * $discount, 2);
            $portion = min($portion, $lineSubtotal, $remaining);
            $allocated[$index] = $portion;
            $remaining = round($remaining - $portion, 2);
        }

        return $allocated;
    }

    private function generateTransactionCode(): string
    {
        return 'TRX-' . now()->format('YmdHis') . '-' . strtoupper(Str::random(8));
    }

    private function resolveProductHpp(?Product $product, ?ProductVariant $variant = null): float
    {
        if (! $product) {
            return 0;
        }

        $product->loadMissing('hppCalculation.items');

        if ($product->hppCalculation?->items?->isNotEmpty()) {
            return round((float) $product->hppCalculation->items->sum(function ($item) use ($variant) {
                return RawMaterialUsage::calculateItemCost(
                    (float) $item->presentase,
                    (float) $item->harga_satuan,
                    (string) $item->satuan,
                    (float) ($variant?->total_satuan_ml ?? 50)
                );
            }), 2);
        }

        return (float) ($product->hppCalculation?->total_hpp ?? $product->harga_modal ?? 0);
    }

    private function generateSaleNumber(?int $storeId, Carbon $timestamp): ?string
    {
        if (! $storeId) {
            return null;
        }

        $nextNumber = OfflineSale::query()
            ->where('store_id', $storeId)
            ->whereDate('created_at', $timestamp->toDateString())
            ->select('sale_number')
            ->distinct()
            ->get()
            ->count() + 1;

        return $timestamp->format('d/m/y') . ' - ' . $nextNumber;
    }
}

