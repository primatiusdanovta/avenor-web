<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Customer;
use App\Models\OfflineSale;
use App\Models\Product;
use App\Models\Promo;
use App\Support\MarketingMobileSupport;
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
        abort_unless(SalesRole::isFieldRole($user?->role), 403);

        $sales = OfflineSale::query()
            ->with('customer')
            ->where('id_user', $user->id_user)
            ->orderByDesc('created_at')
            ->orderByDesc('id_penjualan_offline')
            ->get();

        $transactions = $this->transformTransactions($sales);

        $products = Product::query()
            ->select('products.id_product', 'products.nama_product', 'products.harga')
            ->join('product_onhands', 'product_onhands.id_product', '=', 'products.id_product')
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
                    'option_label' => $product->nama_product . ' | Sisa ' . $remaining,
                ];
            })
            ->filter(fn (array $product) => $product['remaining'] > 0)
            ->values();

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

        return response()->json([
            'sales' => $transactions,
            'products' => $products,
            'promos' => $promos,
        ]);
    }

    public function findCustomer(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless(SalesRole::isFieldRole($user?->role), 403);

        $phone = MarketingMobileSupport::normalizePhone($request->query('phone'));

        if (! $phone) {
            return response()->json(['customer' => null]);
        }

        $customer = Customer::query()
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
        abort_unless(SalesRole::isFieldRole($user?->role), 403);

        $attendance = Attendance::query()
            ->where('user_id', $user->id_user)
            ->whereDate('attendance_date', now()->toDateString())
            ->first();

        if (! $attendance?->check_in) {
            return response()->json(['message' => 'Sales lapangan wajib check in terlebih dahulu sebelum melakukan penjualan.'], 422);
        }

        if ($attendance?->check_out) {
            return response()->json(['message' => 'Marketing yang sudah check out tidak bisa melakukan penjualan lagi hari ini.'], 422);
        }

        $validated = $this->validateTransactionPayload($request);
        [$products, $promo, $lineSubtotals, $onhands, $totalQuantity, $subtotal] = $this->prepareTransactionContext($validated, $user->id_user);
        $this->validatePromoEligibility($promo, $totalQuantity, $subtotal);

        $path = $request->file('bukti_pembelian')?->store('offline-sales', 'public');
        $timestamp = now();
        $transactionCode = $this->generateTransactionCode();
        $discounts = $this->allocateDiscounts($lineSubtotals, (float) ($promo?->potongan ?? 0));

        DB::transaction(function () use ($validated, $user, $products, $promo, $path, $timestamp, $discounts, $lineSubtotals, $onhands, $transactionCode): void {
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
                    'id_product_onhand' => $onhands[(int) $item['id_product']]?->id_product_onhand,
                    'promo_id' => $promo?->id,
                    'nama' => $user->nama,
                    'nama_product' => $product?->nama_product,
                    'quantity' => (int) $item['quantity'],
                    'harga' => max($lineSubtotal - $lineDiscount, 0),
                    'total_hpp' => (float) ($product?->hppCalculation?->total_hpp ?? $product?->harga_modal ?? 0),
                    'kode_promo' => $promo?->kode_promo,
                    'promo' => $promo?->nama_promo,
                    'bukti_pembelian' => $path,
                    'approval_status' => 'pending',
                    'approved_by' => null,
                    'approved_at' => null,
                    'created_at' => $timestamp,
                ]);
            }
        });

        return response()->json([
            'message' => 'Penjualan offline berhasil disimpan.',
            'transaction_code' => $transactionCode,
        ], 201);
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
                    'id_penjualan_offline' => $first->id_penjualan_offline,
                    'nama_customer' => $first->customer?->nama,
                    'no_telp' => $first->customer?->no_telp,
                    'tiktok_instagram' => $first->customer?->tiktok_instagram,
                    'promo_id' => $first->promo_id,
                    'promo' => $first->promo,
                    'kode_promo' => $first->kode_promo,
                    'approval_status' => $first->approval_status,
                    'bukti_pembelian_url' => $first->bukti_pembelian ? route('api.mobile.offline-sales.proof', ['sale' => $first]) : null,
                    'created_at' => optional($first->created_at)->format('Y-m-d H:i:s'),
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

    private function validateTransactionPayload(Request $request): array
    {
        $request->merge([
            'customer_no_telp' => MarketingMobileSupport::normalizePhone($request->input('customer_no_telp')),
        ]);

        return $request->validate([
            'customer_nama' => ['nullable', 'string', 'max:255'],
            'customer_no_telp' => ['nullable', 'string', 'max:30'],
            'customer_tiktok_instagram' => ['nullable', 'string', 'max:255'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.id_product' => ['required', 'distinct', 'exists:products,id_product'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
            'promo_id' => ['nullable', 'exists:promos,id'],
            'bukti_pembelian' => ['required', 'image', 'max:4096'],
        ], [
            'items.*.id_product.distinct' => 'Product tidak boleh dipilih lebih dari sekali dalam satu transaksi.',
        ]);
    }

    private function prepareTransactionContext(array $validated, int $userId): array
    {
        $productIds = collect($validated['items'])->pluck('id_product')->all();
        $products = Product::query()->with('hppCalculation')->whereIn('id_product', $productIds)->get()->keyBy('id_product');
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
        }

        return [$products, $promo, $lineSubtotals, $onhands, $totalQuantity, $subtotal];
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

    private function resolveCustomer(array $validated, Carbon $timestamp): ?Customer
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

        $customer = $noTelp ? Customer::query()->where('no_telp', $noTelp)->first() : null;

        if ($customer) {
            $updates = ['pembelian_terakhir' => $timestamp];

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

    private function generateTransactionCode(): string
    {
        return 'TRX-' . now()->format('YmdHis') . '-' . strtoupper(Str::random(8));
    }
}
