<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use App\Models\OfflineSale;
use App\Models\Product;
use App\Models\ProductOnhand;
use App\Models\Promo;
use App\Models\User;
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
        $isManager = in_array($user->role, ['superadmin', 'admin'], true);

        $sales = OfflineSale::query()
            ->with('customer')
            ->when(! $isManager, fn ($query) => $query->where('id_user', $user->id_user))
            ->orderByDesc('created_at')
            ->orderByDesc('id_penjualan_offline')
            ->get();

        $transactions = $this->transformTransactions($sales);

        $products = $isManager
            ? Product::query()->orderBy('nama_product')->get(['id_product', 'nama_product', 'harga'])
            : $this->availableOnhandProducts($user->id_user);

        $products = collect($products)->map(fn ($product) => [
            'id_product' => $product->id_product,
            'nama_product' => $product->nama_product,
            'harga' => (float) $product->harga,
            'remaining' => data_get($product, 'remaining'),
            'option_label' => $product->nama_product . (data_get($product, 'remaining') !== null ? ' | sisa ' . data_get($product, 'remaining') : ''),
        ])->values();

        $promos = Promo::query()
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

        return Inertia::render('Sales/Index', [
            'sales' => $transactions,
            'products' => $products,
            'promos' => $promos,
            'customers' => $customers,
            'canApprove' => $isManager,
            'canManageAll' => $isManager,
            'currentRole' => $user->role,
            'defaultCreatedAt' => now()->format('Y-m-d\TH:i'),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $user = $request->user();
        $isManager = in_array($user->role, ['superadmin', 'admin'], true);
        $validated = $this->validateTransactionPayload($request, true, $isManager);

        [$products, $promo, $lineSubtotals, $onhands, $totalQuantity, $subtotal] = $this->prepareTransactionContext($validated, $user->id_user, $isManager);

        $this->validatePromoEligibility($promo, $totalQuantity, $subtotal);

        $path = $request->file('bukti_pembelian')?->store('offline-sales', 'public');
        $timestamp = $this->resolveTransactionTimestamp($validated, $isManager);
        $transactionCode = $this->generateTransactionCode();
        $discounts = $this->allocateDiscounts($lineSubtotals, (float) ($promo?->potongan ?? 0));

        DB::transaction(function () use ($validated, $user, $isManager, $products, $promo, $path, $timestamp, $discounts, $lineSubtotals, $onhands, $transactionCode): void {
            $customer = $this->resolveCustomer($validated, $timestamp);

            foreach ($validated['items'] as $index => $item) {
                $product = $products->get($item['id_product']);
                $lineSubtotal = $lineSubtotals[$index] ?? 0;
                $lineDiscount = $discounts[$index] ?? 0;

                OfflineSale::query()->create([
                    'transaction_code' => $transactionCode,
                    'id_user' => $user->id_user,
                    'id_pelanggan' => $customer?->id_pelanggan,
                    'id_product' => $product?->id_product,
                    'id_product_onhand' => $isManager ? null : ($onhands[(int) $item['id_product']]?->id_product_onhand ?? null),
                    'promo_id' => $promo?->id,
                    'nama' => $user->nama,
                    'nama_product' => $product?->nama_product,
                    'quantity' => (int) $item['quantity'],
                    'harga' => max($lineSubtotal - $lineDiscount, 0),
                    'kode_promo' => $promo?->kode_promo,
                    'promo' => $promo?->nama_promo,
                    'bukti_pembelian' => $path,
                    'approval_status' => $isManager ? 'disetujui' : 'pending',
                    'approved_by' => $isManager ? $user->id_user : null,
                    'approved_at' => $isManager ? $timestamp : null,
                    'created_at' => $timestamp,
                ]);
            }
        });

        return redirect()->route('offline-sales.index')->with('success', 'Penjualan offline berhasil disimpan.');
    }

    public function update(Request $request, OfflineSale $sale): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        $validated = $this->validateTransactionPayload($request, false, true);
        $transactionSales = $this->transactionSales($sale);
        $userId = (int) $sale->id_user;

        [$products, $promo, $lineSubtotals, $onhands, $totalQuantity, $subtotal] = $this->prepareTransactionContext(
            $validated,
            $userId,
            true,
            $transactionSales
        );

        $this->validatePromoEligibility($promo, $totalQuantity, $subtotal);

        $timestamp = $this->resolveTransactionTimestamp($validated, true, $sale->created_at);
        $discounts = $this->allocateDiscounts($lineSubtotals, (float) ($promo?->potongan ?? 0));

        DB::transaction(function () use ($validated, $sale, $transactionSales, $products, $promo, $timestamp, $discounts, $lineSubtotals): void {
            $customer = $this->resolveCustomer($validated, $timestamp);
            $existingByProduct = $transactionSales->keyBy('id_product');
            $keepIds = [];

            foreach ($validated['items'] as $index => $item) {
                $product = $products->get($item['id_product']);
                $lineSubtotal = $lineSubtotals[$index] ?? 0;
                $lineDiscount = $discounts[$index] ?? 0;
                $existing = $existingByProduct->get((int) $item['id_product']);

                if ($existing) {
                    $existing->update([
                        'id_pelanggan' => $customer?->id_pelanggan,
                        'promo_id' => $promo?->id,
                        'nama_product' => $product?->nama_product,
                        'quantity' => (int) $item['quantity'],
                        'harga' => max($lineSubtotal - $lineDiscount, 0),
                        'kode_promo' => $promo?->kode_promo,
                        'promo' => $promo?->nama_promo,
                        'created_at' => $timestamp,
                        'approved_at' => $existing->approval_status === 'disetujui' ? $timestamp : $existing->approved_at,
                    ]);

                    $keepIds[] = $existing->id_penjualan_offline;
                    continue;
                }

                $created = OfflineSale::query()->create([
                    'transaction_code' => $sale->transaction_code,
                    'id_user' => $sale->id_user,
                    'id_pelanggan' => $customer?->id_pelanggan,
                    'id_product' => $product?->id_product,
                    'id_product_onhand' => null,
                    'promo_id' => $promo?->id,
                    'nama' => $sale->nama,
                    'nama_product' => $product?->nama_product,
                    'quantity' => (int) $item['quantity'],
                    'harga' => max($lineSubtotal - $lineDiscount, 0),
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
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

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
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        $this->transactionSales($sale)->each->update([
            'approval_status' => 'disetujui',
            'approved_by' => $request->user()->id_user,
            'approved_at' => now(),
        ]);

        return redirect()->route('offline-sales.index')->with('success', 'Penjualan offline disetujui.');
    }

    public function reject(Request $request, OfflineSale $sale): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

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

        abort_unless($isManager || (int) $sale->id_user === (int) $user->id_user, 403);
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
                    'id_penjualan_offline' => $first->id_penjualan_offline,
                    'id_user' => $first->id_user,
                    'nama_penjual' => $first->nama,
                    'nama_customer' => $first->customer?->nama,
                    'no_telp' => $first->customer?->no_telp,
                    'tiktok_instagram' => $first->customer?->tiktok_instagram,
                    'promo_id' => $first->promo_id,
                    'promo' => $first->promo,
                    'kode_promo' => $first->kode_promo,
                    'approval_status' => $first->approval_status,
                    'bukti_pembelian' => $first->bukti_pembelian ? route('offline-sales.proof', $first) : null,
                    'created_at' => optional($first->created_at)->format('Y-m-d H:i:s'),
                    'created_at_form' => optional($first->created_at)->format('Y-m-d\TH:i'),
                    'total_quantity' => (int) $items->sum('quantity'),
                    'total_harga' => (float) $items->sum('harga'),
                    'items' => $items->map(fn (OfflineSale $sale) => [
                        'id_penjualan_offline' => $sale->id_penjualan_offline,
                        'id_product' => $sale->id_product,
                        'nama_product' => $sale->nama_product,
                        'quantity' => (int) $sale->quantity,
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

        $rules = [
            'customer_nama' => ['nullable', 'string', 'max:255'],
            'customer_no_telp' => ['nullable', 'string', 'max:30'],
            'customer_tiktok_instagram' => ['nullable', 'string', 'max:255'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.id_product' => ['required', 'distinct', 'exists:products,id_product'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
            'promo_id' => ['nullable', 'exists:promos,id'],
            'bukti_pembelian' => [$requireReceipt ? 'required' : 'nullable', 'image', 'max:4096'],
            'created_at' => [$allowManualTimestamp ? 'required' : 'nullable', 'date'],
        ];

        return $request->validate($rules, [
            'items.*.id_product.distinct' => 'Product tidak boleh dipilih lebih dari sekali dalam satu transaksi.',
            'created_at.required' => 'Tanggal transaksi wajib diisi untuk admin dan superadmin.',
        ]);
    }

    private function prepareTransactionContext(array $validated, int $userId, bool $isManager, ?Collection $existingSales = null): array
    {
        $productIds = collect($validated['items'])->pluck('id_product')->all();
        $products = Product::query()->whereIn('id_product', $productIds)->get()->keyBy('id_product');
        $promo = empty($validated['promo_id']) ? null : Promo::query()->findOrFail($validated['promo_id']);

        $lineSubtotals = [];
        $onhands = [];
        $totalQuantity = 0;
        $subtotal = 0.0;

        foreach ($validated['items'] as $item) {
            $product = $products->get($item['id_product']);
            $quantity = (int) $item['quantity'];
            $lineSubtotal = (float) ($product?->harga ?? 0) * $quantity;

            $lineSubtotals[] = $lineSubtotal;
            $totalQuantity += $quantity;
            $subtotal += $lineSubtotal;

            if (! $isManager) {
                $ignoreSaleId = $existingSales?->firstWhere('id_product', (int) $item['id_product'])?->id_penjualan_offline;
                $onhand = $this->resolveOnhandForSale($userId, (int) $item['id_product']);

                if (! $onhand) {
                    throw ValidationException::withMessages(['items' => 'Ada product yang belum diambil untuk hari ini.']);
                }

                if ($quantity > $this->availableForOnhand($onhand, $ignoreSaleId)) {
                    throw ValidationException::withMessages(['items' => 'Quantity penjualan melebihi barang yang dibawa.']);
                }

                $onhands[(int) $item['id_product']] = $onhand;
            }
        }

        return [$products, $promo, $lineSubtotals, $onhands, $totalQuantity, $subtotal];
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

    private function resolveCustomer(array $validated, $timestamp): ?Customer
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
            ? Customer::query()->where('no_telp', $noTelp)->first()
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
            ->where('transaction_code', $sale->transaction_code)
            ->orderBy('id_penjualan_offline')
            ->get();
    }

    private function availableOnhandProducts(int $userId)
    {
        return Product::query()
            ->select('products.id_product', 'products.nama_product', 'products.harga')
            ->join('product_onhands', 'product_onhands.id_product', '=', 'products.id_product')
            ->where('product_onhands.user_id', $userId)
            ->whereDate('product_onhands.assignment_date', today()->toDateString())
            ->where('product_onhands.take_status', 'disetujui')
            ->groupBy('products.id_product', 'products.nama_product', 'products.harga')
            ->get()
            ->map(function (Product $product) use ($userId) {
                $onhand = $this->resolveOnhandForSale($userId, $product->id_product);
                $product->remaining = $onhand ? $this->availableForOnhand($onhand) : 0;
                return $product;
            })
            ->filter(fn ($product) => $product->remaining > 0)
            ->values();
    }

    private function resolveOnhandForSale(int $userId, int $productId): ?ProductOnhand
    {
        return ProductOnhand::query()
            ->where('user_id', $userId)
            ->where('id_product', $productId)
            ->whereDate('assignment_date', today()->toDateString())
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

        $soldQty = (int) OfflineSale::query()
            ->where('id_product_onhand', $onhand->id_product_onhand)
            ->when($ignoreSaleId, fn ($query) => $query->where('id_penjualan_offline', '!=', $ignoreSaleId))
            ->where('approval_status', '!=', 'ditolak')
            ->sum('quantity');

        $returnedQty = in_array($onhand->return_status, ['pending', 'disetujui'], true)
            ? (int) $onhand->quantity_dikembalikan
            : 0;

        return max((int) $onhand->quantity - $soldQty - $returnedQty, 0);
    }
}
