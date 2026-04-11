<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use App\Models\ExtraTopping;
use App\Models\GlobalSetting;
use App\Models\OfflineSale;
use App\Models\Product;
use App\Models\ProductOnhand;
use App\Models\ProductVariant;
use App\Models\Promo;
use App\Models\User;
use App\Support\RawMaterialUsage;
use App\Support\ProductOnhandStock;
use App\Support\StoreFeature;
use Carbon\Carbon;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;
use Inertia\Response;

class OfflineSaleController extends Controller
{
    public function index(Request $request): Response
    {
        $user = $request->user();
        $storeId = $this->currentStoreId($request);
        $isManager = in_array($user->role, ['superadmin', 'admin'], true);
        abort_unless($user->hasPermission('offline_sales.view'), 403);

        $sales = OfflineSale::query()
            ->where('store_id', $storeId)
            ->with('customer')
            ->when(! $isManager, fn ($query) => $query->where('id_user', $user->id_user))
            ->orderByDesc('created_at')
            ->orderByDesc('id_penjualan_offline')
            ->get();

        $transactions = $this->transformTransactions($sales);

        $products = $isManager
            ? Product::query()->where('store_id', $storeId)->orderBy('nama_product')->get(['id_product', 'nama_product', 'harga', 'gambar', 'deskripsi'])
            : (
                StoreFeature::requiresOnhandForOfflineSales($request)
                    ? $this->availableOnhandProducts($user->id_user, $storeId)
                    : Product::query()->where('store_id', $storeId)->orderBy('nama_product')->get(['id_product', 'nama_product', 'harga', 'gambar', 'deskripsi'])
            );

        $products = collect($products)->map(fn ($product) => [
            'id_product' => $product->id_product,
            'nama_product' => $product->nama_product,
            'harga' => (float) $product->harga,
            'deskripsi' => $product->deskripsi ?? null,
            'image_url' => $product->public_image_url,
            'remaining' => data_get($product, 'remaining'),
            'option_label' => $product->nama_product . (data_get($product, 'remaining') !== null ? ' | sisa ' . data_get($product, 'remaining') : ''),
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
                    'option_label' => $variant->name . ' | ' . number_format((float) $variant->price, 0, ',', '.'),
                ])
                ->values(),
        ])->values();

        $promos = Promo::query()
            ->where('store_id', $storeId)
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

        $customers = Customer::query()
            ->where('store_id', $storeId)
            ->orderByDesc('pembelian_terakhir')
            ->orderByDesc('id_pelanggan')
            ->get()
            ->map(fn (Customer $customer) => [
                'id_pelanggan' => $customer->id_pelanggan,
                'nama' => $customer->nama,
                'no_telp' => $customer->no_telp,
                'tiktok_instagram' => $customer->tiktok_instagram,
                'pembelian_terakhir' => optional($customer->pembelian_terakhir)->format('Y-m-d H:i:s'),
            ])
            ->values();

        $extraToppings = ExtraTopping::query()
            ->where('store_id', $storeId)
            ->where('is_active', true)
            ->orderBy('name')
            ->get()
            ->map(fn (ExtraTopping $item) => [
                'id' => $item->id,
                'name' => $item->name,
                'price' => (float) $item->price,
                'option_label' => $item->name . ' | ' . number_format((float) $item->price, 0, ',', '.'),
            ])
            ->values();

        $lastClosedSale = OfflineSale::query()
            ->where('store_id', $storeId)
            ->whereNotNull('sale_number')
            ->where('payment_status', 'closed')
            ->whereNotNull('closed_at')
            ->orderByDesc('closed_at')
            ->first();

        return Inertia::render('Sales/Index', [
            'sales' => $transactions,
            'products' => $products,
            'promos' => $promos,
            'customers' => $customers,
            'extraToppings' => $extraToppings,
            'canApprove' => $isManager,
            'canManageAll' => $isManager,
            'currentRole' => $user->role,
            'defaultCreatedAt' => now()->format('Y-m-d\TH:i'),
            'isSmoothiesSweetie' => StoreFeature::isSmoothiesSweetie($request),
            'qrisImageUrl' => data_get(GlobalSetting::masterSocialHub(), 'sales_qr_url'),
            'lastClosedSale' => $lastClosedSale ? [
                'sale_number' => $lastClosedSale->sale_number,
                'transaction_code' => $lastClosedSale->transaction_code,
                'closed_at' => optional($lastClosedSale->closed_at)->format('Y-m-d H:i:s'),
            ] : null,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $user = $request->user();
        $isManager = in_array($user->role, ['superadmin', 'admin'], true);
        abort_unless($user->hasPermission('offline_sales.manage'), 403);
        $validated = $this->validateTransactionPayload($request, ! StoreFeature::isSmoothiesSweetie($request), $isManager);
        $storeId = $this->currentStoreId($request);

        [$products, $promo, $lineSubtotals, $onhands, $totalQuantity, $subtotal, $variants, $extraToppings] = $this->prepareTransactionContext($validated, $user->id_user, $isManager, null, $storeId);

        $this->validatePromoEligibility($promo, $totalQuantity, $subtotal);

        $path = $request->file('bukti_pembelian')?->store('offline-sales', 'public');
        $timestamp = $this->resolveTransactionTimestamp($validated, $isManager);
        $transactionCode = $this->generateTransactionCode();
        $saleNumber = $this->generateSaleNumber($storeId, $timestamp);
        $discounts = $this->allocateDiscounts($lineSubtotals, (float) ($promo?->potongan ?? 0));
        $paymentMethod = $validated['payment_method'] ?? 'Cash';
        $paymentStatus = 'paid';
        $paidAt = $timestamp;
        $autoApproved = $isManager || StoreFeature::isSmoothiesSweetie($request);

        DB::transaction(function () use ($validated, $user, $autoApproved, $products, $promo, $path, $timestamp, $discounts, $lineSubtotals, $onhands, $transactionCode, $saleNumber, $paymentMethod, $paymentStatus, $paidAt, $storeId, $variants, $extraToppings): void {
            $customer = $this->resolveCustomer($validated, $timestamp, $storeId);

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
                $extraToppingTotal = round($selectedExtraToppings->sum('price') * (int) $item['quantity'], 2);

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
                    'extra_toppings' => $selectedExtraToppings->map(fn ($topping) => [
                        'id' => $topping->id,
                        'name' => $topping->name,
                        'price' => (float) $topping->price,
                    ])->all(),
                    'payment_method' => $paymentMethod,
                    'payment_status' => $paymentStatus,
                    'paid_at' => $paidAt,
                    'id_product_onhand' => $autoApproved ? null : ($onhands[(int) $item['id_product']]?->id_product_onhand ?? null),
                    'promo_id' => $promo?->id,
                    'nama' => $user->nama,
                    'nama_product' => trim(($product?->nama_product ?? '') . ($variant?->name ? ' - ' . $variant->name : '')),
                    'quantity' => (int) $item['quantity'],
                    'harga' => max($lineSubtotal - $lineDiscount, 0),
                    'total_hpp' => $lineHpp,
                    'kode_promo' => $promo?->kode_promo,
                    'promo' => $promo?->nama_promo,
                    'bukti_pembelian' => $path,
                    'approval_status' => $autoApproved ? 'disetujui' : 'pending',
                    'approved_by' => $autoApproved ? $user->id_user : null,
                    'approved_at' => $autoApproved ? $timestamp : null,
                    'created_at' => $timestamp,
                ]);
            }
        });

        return redirect()
            ->route('offline-sales.index')
            ->with('success', 'Penjualan offline berhasil disimpan.')
            ->with('saleSummary', [
                'transaction_code' => $transactionCode,
                'sale_number' => $saleNumber,
                'payment_method' => $paymentMethod,
                'payment_status' => $paymentStatus,
                'total_quantity' => $totalQuantity,
                'total_harga' => max(round($subtotal - (float) ($promo?->potongan ?? 0), 2), 0),
                'promo' => $promo?->nama_promo,
                'created_at' => $timestamp->format('Y-m-d H:i:s'),
            ]);
    }

    public function update(Request $request, OfflineSale $sale): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true) && $request->user()->hasPermission('offline_sales.manage'), 403);
        $this->ensureStoreMatch($request, $sale);

        $validated = $this->validateTransactionPayload($request, false, true);
        $transactionSales = $this->transactionSales($sale);
        $userId = (int) $sale->id_user;
        $storeId = $this->currentStoreId($request);

        [$products, $promo, $lineSubtotals, $onhands, $totalQuantity, $subtotal, $variants, $extraToppings] = $this->prepareTransactionContext(
            $validated,
            $userId,
            true,
            $transactionSales,
            $storeId
        );

        $this->validatePromoEligibility($promo, $totalQuantity, $subtotal);

        $timestamp = $this->resolveTransactionTimestamp($validated, true, $sale->created_at);
        $discounts = $this->allocateDiscounts($lineSubtotals, (float) ($promo?->potongan ?? 0));

        DB::transaction(function () use ($validated, $sale, $transactionSales, $products, $promo, $timestamp, $discounts, $lineSubtotals, $storeId, $variants, $extraToppings): void {
            $customer = $this->resolveCustomer($validated, $timestamp, $storeId);
            $existingByProduct = $transactionSales->keyBy('id_product');
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
                $existing = $existingByProduct->get((int) $item['id_product']);
                $extraToppingTotal = round($selectedExtraToppings->sum('price') * (int) $item['quantity'], 2);

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
                        'nama_product' => trim(($product?->nama_product ?? '') . ($variant?->name ? ' - ' . $variant->name : '')),
                        'quantity' => (int) $item['quantity'],
                        'harga' => max($lineSubtotal - $lineDiscount, 0),
                        'total_hpp' => $lineHpp,
                        'kode_promo' => $promo?->kode_promo,
                        'promo' => $promo?->nama_promo,
                        'created_at' => $timestamp,
                        'approved_at' => $existing->approval_status === 'disetujui' ? $timestamp : $existing->approved_at,
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
                    'payment_method' => $sale->payment_method,
                    'payment_status' => $sale->payment_status,
                    'paid_at' => $sale->paid_at,
                    'id_product_onhand' => null,
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
                    'approved_at' => $sale->approval_status === 'disetujui' ? $timestamp : $sale->approved_at,
                    'created_at' => $timestamp,
                ]);

                $keepIds[] = $created->id_penjualan_offline;
            }

            $toDelete = $transactionSales->whereNotIn('id_penjualan_offline', $keepIds);

            foreach ($toDelete as $row) {
                $row->delete();
            }
        });

        return redirect()->route('offline-sales.index')->with('success', 'Transaksi penjualan offline berhasil diperbarui.');
    }

    public function destroy(Request $request, OfflineSale $sale): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true) && $request->user()->hasPermission('offline_sales.manage'), 403);
        $this->ensureStoreMatch($request, $sale);

        $transactionSales = $this->transactionSales($sale);
        $receiptPath = $sale->bukti_pembelian;

        DB::transaction(function () use ($transactionSales): void {
            foreach ($transactionSales as $row) {
                $row->delete();
            }
        });

        if ($receiptPath) {
            $isSharedReceipt = OfflineSale::query()
                ->where('bukti_pembelian', $receiptPath)
                ->exists();

            if (! $isSharedReceipt) {
                Storage::disk('public')->delete($receiptPath);
            }
        }

        return redirect()->route('offline-sales.index')->with('success', 'Transaksi penjualan offline berhasil dihapus.');
    }

    public function approve(Request $request, OfflineSale $sale): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true) && $request->user()->hasPermission('offline_sales.approve'), 403);
        $this->ensureStoreMatch($request, $sale);

        $this->transactionSales($sale)->each->update([
            'approval_status' => 'disetujui',
            'approved_by' => $request->user()->id_user,
            'approved_at' => now(),
        ]);

        return redirect()->route('offline-sales.index')->with('success', 'Penjualan offline disetujui.');
    }

    public function reject(Request $request, OfflineSale $sale): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true) && $request->user()->hasPermission('offline_sales.approve'), 403);
        $this->ensureStoreMatch($request, $sale);

        $this->transactionSales($sale)->each->update([
            'approval_status' => 'ditolak',
            'approved_by' => $request->user()->id_user,
            'approved_at' => now(),
        ]);

        return redirect()->route('offline-sales.index')->with('success', 'Penjualan offline ditolak.');
    }

    public function showProof(Request $request, OfflineSale $sale)
    {
        $user = $request->user();
        $isManager = in_array($user->role, ['superadmin', 'admin'], true);
        $this->ensureStoreMatch($request, $sale);

        abort_unless($isManager || (int) $sale->id_user === (int) $user->id_user, 403);
        abort_if(! $sale->bukti_pembelian, 404);
        abort_unless(Storage::disk('public')->exists($sale->bukti_pembelian), 404);

        return Storage::disk('public')->response($sale->bukti_pembelian);
    }

    public function queueBoard(Request $request): Response
    {
        abort_unless($request->user()?->hasPermission('offline_sales.view'), 403);

        $storeId = $this->currentStoreId($request);

        $items = OfflineSale::query()
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
                    'payment_status' => $first?->payment_status,
                    'created_at' => optional($first?->created_at)->format('Y-m-d H:i:s'),
                    'details' => $sales->map(fn (OfflineSale $sale) => [
                        'nama_product' => $sale->nama_product,
                        'quantity' => (int) $sale->quantity,
                        'extra_toppings' => collect($sale->extra_toppings ?? [])
                            ->pluck('name')
                            ->filter()
                            ->values()
                            ->all(),
                    ])->values()->all(),
                ];
            })
            ->sortBy('queue_number')
            ->values();

        $lastClosedSale = OfflineSale::query()
            ->where('store_id', $storeId)
            ->whereNotNull('sale_number')
            ->where('payment_status', 'closed')
            ->whereNotNull('closed_at')
            ->orderByDesc('closed_at')
            ->first();

        return Inertia::render('Queue/Board', [
            'items' => $items,
            'canClose' => $request->user()?->hasPermission('offline_sales.manage') ?? false,
            'lastClosedSale' => $lastClosedSale ? [
                'sale_number' => $lastClosedSale->sale_number,
                'transaction_code' => $lastClosedSale->transaction_code,
                'closed_at' => optional($lastClosedSale->closed_at)->format('Y-m-d H:i:s'),
            ] : null,
        ]);
    }

    public function closeQueue(Request $request): RedirectResponse
    {
        abort_unless($request->user()?->hasPermission('offline_sales.manage'), 403);
        $validated = $request->validate([
            'sale_number' => ['required', 'string'],
        ]);
        $targetSaleNumber = trim((string) $validated['sale_number']);
        abort_if($targetSaleNumber === '', 422, 'Nomor antrian wajib diisi.');

        OfflineSale::query()
            ->where('store_id', $this->currentStoreId($request))
            ->where('sale_number', $targetSaleNumber)
            ->update([
                'payment_status' => 'closed',
                'closed_at' => now(),
            ]);

        return back()->with('success', 'Antrian selesai dan sudah ditutup.');
    }

    private function transformTransactions(Collection $sales): Collection
    {
        return $sales
            ->groupBy(fn (OfflineSale $sale) => $sale->transaction_code ?: 'legacy-' . $sale->id_penjualan_offline)
            ->map(function (Collection $items) {
                $first = $items->first();

                return [
                    'transaction_code' => $first->transaction_code,
                    'id_penjualan_offline' => $first->id_penjualan_offline,
                    'id_user' => $first->id_user,
                    'nama_penjual' => $first->nama,
                    'nama_customer' => $first->customer?->nama,
                    'no_telp' => $first->customer?->no_telp,
                    'tiktok_instagram' => $first->customer?->tiktok_instagram,
                    'sale_number' => $first->sale_number,
                    'promo_id' => $first->promo_id,
                    'promo' => $first->promo,
                    'kode_promo' => $first->kode_promo,
                    'approval_status' => $first->approval_status,
                    'payment_method' => $first->payment_method,
                    'payment_status' => $first->payment_status,
                    'closed_at' => optional($first->closed_at)->format('Y-m-d H:i:s'),
                    'bukti_pembelian' => $first->bukti_pembelian ? route('offline-sales.proof', $first) : null,
                    'created_at' => optional($first->created_at)->format('Y-m-d H:i:s'),
                    'created_at_form' => optional($first->created_at)->format('Y-m-d\TH:i'),
                    'total_quantity' => (int) $items->sum('quantity'),
                    'total_harga' => (float) $items->sum('harga'),
                    'items' => $items->map(fn (OfflineSale $sale) => [
                        'id_penjualan_offline' => $sale->id_penjualan_offline,
                        'id_product' => $sale->id_product,
                        'product_variant_id' => $sale->product_variant_id,
                        'product_variant_name' => $sale->product_variant_name,
                        'nama_product' => $sale->nama_product,
                        'quantity' => (int) $sale->quantity,
                        'unit_price' => (float) ($sale->unit_price ?? 0),
                        'extra_topping_ids' => collect($sale->extra_toppings ?? [])->pluck('id')->filter()->values()->all(),
                        'extra_toppings' => $sale->extra_toppings ?? [],
                        'harga' => (float) $sale->harga,
                    ])->values(),
                ];
            })
            ->sortByDesc('created_at')
            ->values();
    }

    private function validateTransactionPayload(Request $request, bool $requireReceipt = true, bool $allowManualTimestamp = false): array
    {
        $request->merge([
            'customer_no_telp' => $this->normalizePhone($request->input('customer_no_telp')),
        ]);
        $storeId = $this->currentStoreId($request);

        $rules = [
            'customer_nama' => ['nullable', 'string', 'max:255'],
            'customer_no_telp' => ['nullable', 'string', 'max:30'],
            'customer_tiktok_instagram' => ['nullable', 'string', 'max:255'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.id_product' => ['required', \Illuminate\Validation\Rule::exists('products', 'id_product')->where(fn ($query) => $query->where('store_id', $storeId))],
            'items.*.product_variant_id' => ['nullable', \Illuminate\Validation\Rule::exists('product_variants', 'id')->where(fn ($query) => $query->whereIn('product_id', Product::query()->where('store_id', $storeId)->select('id_product')))],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
            'items.*.extra_topping_ids' => ['nullable', 'array'],
            'items.*.extra_topping_ids.*' => ['integer', \Illuminate\Validation\Rule::exists('extra_toppings', 'id')->where(fn ($query) => $query->where('store_id', $storeId))],
            'promo_id' => ['nullable', \Illuminate\Validation\Rule::exists('promos', 'id')->where(fn ($query) => $query->where('store_id', $storeId))],
            'bukti_pembelian' => [$requireReceipt ? 'required' : 'nullable', 'image', 'max:4096'],
            'created_at' => [$allowManualTimestamp ? 'required' : 'nullable', 'date'],
            'payment_method' => ['nullable', 'in:Cash,Qris'],
        ];

        return $request->validate($rules, [
            'created_at.required' => 'Tanggal transaksi wajib diisi untuk admin dan superadmin.',
        ]);
    }

    private function prepareTransactionContext(array $validated, int $userId, bool $isManager, ?Collection $existingSales = null, ?int $storeId = null): array
    {
        $productIds = collect($validated['items'])->pluck('id_product')->all();
        $products = Product::query()->where('store_id', $storeId)->whereIn('id_product', $productIds)->get()->keyBy('id_product');
        $promo = empty($validated['promo_id']) ? null : Promo::query()->where('store_id', $storeId)->findOrFail($validated['promo_id']);
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

            if (! $isManager && StoreFeature::requiresOnhandForOfflineSales(request())) {
                $ignoreSaleId = $existingSales?->firstWhere('id_product', (int) $item['id_product'])?->id_penjualan_offline;
                $onhand = $this->resolveOnhandForSale($userId, (int) $item['id_product'], $storeId);

                if (! $onhand) {
                    throw ValidationException::withMessages(['items' => 'Ada product yang belum tersedia di on hand untuk dijual.']);
                }

                if ($quantity > $this->availableForOnhand($onhand, $ignoreSaleId)) {
                    throw ValidationException::withMessages(['items' => 'Quantity penjualan melebihi barang yang dibawa.']);
                }

                $onhands[(int) $item['id_product']] = $onhand;
            }
        }

        return [$products, $promo, $lineSubtotals, $onhands, $totalQuantity, $subtotal, $variants, $extraToppings];
    }

    private function validatePromoEligibility(?Promo $promo, int $totalQuantity, float $subtotal): void
    {
        if (! $promo) {
            return;
        }

        if ($promo->masa_aktif->lt(today())) {
            throw ValidationException::withMessages(['promo_id' => 'Promo sudah tidak aktif.']);
        }

        if ($totalQuantity < $promo->minimal_quantity || $subtotal < (float) $promo->minimal_belanja) {
            throw ValidationException::withMessages(['promo_id' => 'Pembelian belum mencapai syarat']);
        }
    }

    private function resolveCustomer(array $validated, $timestamp, int $storeId): ?Customer
    {
        $nama = trim((string) ($validated['customer_nama'] ?? ''));
        $noTelp = $validated['customer_no_telp'] ?? null;
        $social = trim((string) ($validated['customer_tiktok_instagram'] ?? ''));

        if ($nama === '' && empty($noTelp) && $social === '') {
            return null;
        }

        $payload = [
            'nama' => $nama !== '' ? $nama : null,
            'no_telp' => $noTelp ?: null,
            'tiktok_instagram' => $social !== '' ? $social : null,
            'pembelian_terakhir' => $timestamp,
        ];

        $customer = $noTelp
            ? Customer::query()->where('store_id', $storeId)->where('no_telp', $noTelp)->first()
            : null;

        if ($customer) {
            $updates = [
                'pembelian_terakhir' => $timestamp,
            ];

            if ($payload['nama']) {
                $updates['nama'] = $payload['nama'];
            }

            if ($payload['tiktok_instagram']) {
                $updates['tiktok_instagram'] = $payload['tiktok_instagram'];
            }

            $customer->update($updates);

            return $customer->fresh();
        }

        $payload['created_at'] = $timestamp;
        $payload['store_id'] = $storeId;

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

    private function normalizePhone(?string $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $normalized = preg_replace('/\D+/', '', $value) ?? '';

        return $normalized !== '' ? $normalized : null;
    }

    private function resolveTransactionTimestamp(array $validated, bool $allowManualTimestamp, $fallback = null): Carbon
    {
        if ($allowManualTimestamp && ! empty($validated['created_at'])) {
            return Carbon::parse($validated['created_at']);
        }

        if ($fallback) {
            return Carbon::parse($fallback);
        }

        return now();
    }

    private function generateTransactionCode(): string
    {
        return 'TRX-' . now()->format('YmdHis') . '-' . strtoupper(Str::random(8));
    }

    private function transactionSales(OfflineSale $sale): Collection
    {
        if (! $sale->transaction_code) {
            return collect([$sale]);
        }

        return OfflineSale::query()
            ->where('store_id', $sale->store_id)
            ->where('transaction_code', $sale->transaction_code)
            ->orderBy('id_penjualan_offline')
            ->get();
    }

    private function availableOnhandProducts(int $userId, int $storeId)
    {
        return Product::query()
            ->select('products.id_product', 'products.nama_product', 'products.harga')
            ->join('product_onhands', 'product_onhands.id_product', '=', 'products.id_product')
            ->where('products.store_id', $storeId)
            ->where('product_onhands.store_id', $storeId)
            ->where('product_onhands.user_id', $userId)
            ->where('product_onhands.take_status', 'disetujui')
            ->groupBy('products.id_product', 'products.nama_product', 'products.harga')
            ->get()
            ->map(function (Product $product) use ($userId, $storeId) {
                $onhand = $this->resolveOnhandForSale($userId, $product->id_product, $storeId);
                $product->remaining = $onhand ? $this->availableForOnhand($onhand) : 0;
                return $product;
            })
            ->filter(fn ($product) => $product->remaining > 0)
            ->values();
    }

    private function resolveOnhandForSale(int $userId, int $productId, ?int $storeId = null): ?ProductOnhand
    {
        return ProductOnhand::query()
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
            ->where('user_id', $userId)
            ->where('id_product', $productId)
            ->where('take_status', 'disetujui')
            ->orderByDesc('id_product_onhand')
            ->get()
            ->first(function (ProductOnhand $onhand) {
                return $onhand->return_status !== 'pending' && $this->availableForOnhand($onhand) > 0;
            });
    }

    private function availableForOnhand(?ProductOnhand $onhand, ?int $ignoreSaleId = null): int
    {
        if (! $onhand) {
            return 0;
        }

        return ProductOnhandStock::availableQuantity($onhand, $ignoreSaleId);
    }

    private function resolveProductHpp(?Product $product, ?ProductVariant $variant = null): float
    {
        if (! $product) {
            return 0;
        }

        $product->loadMissing('hppCalculation.items');

        if ($product->hppCalculation?->items?->isNotEmpty()) {
            $mlBase = (float) ($variant?->total_satuan_ml ?? 50);

            return round((float) $product->hppCalculation->items->sum(function ($item) use ($mlBase) {
                return RawMaterialUsage::calculateItemCost(
                    (float) $item->presentase,
                    (float) $item->harga_satuan,
                    (string) $item->satuan,
                    $mlBase
                );
            }), 2);
        }

        return round((float) ($product->hppCalculation?->total_hpp ?? $product->harga_modal ?? 0), 2);
    }

    private function generateSaleNumber(int $storeId, Carbon $timestamp): string
    {
        $nextNumber = OfflineSale::query()
            ->where('store_id', $storeId)
            ->whereDate('created_at', $timestamp->toDateString())
            ->select('sale_number')
            ->distinct()
            ->get()
            ->count() + 1;

        return $timestamp->format('d/m/Y') . ' - ' . $nextNumber;
    }
}


