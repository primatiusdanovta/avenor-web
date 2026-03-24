<?php

namespace App\Http\Controllers;

use App\Models\OfflineSale;
use App\Models\Product;
use App\Models\ProductOnhand;
use App\Models\Promo;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Inertia\Inertia;
use Inertia\Response;

class OfflineSaleController extends Controller
{
    public function index(Request $request): Response
    {
        $user = $request->user();
        $isManager = in_array($user->role, ['superadmin', 'admin'], true);

        $sales = OfflineSale::query()
            ->when(! $isManager, fn ($query) => $query->where('id_user', $user->id_user))
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (OfflineSale $sale) => [
                'id_penjualan_offline' => $sale->id_penjualan_offline,
                'id_user' => $sale->id_user,
                'nama' => $sale->nama,
                'nama_product' => $sale->nama_product,
                'quantity' => (int) $sale->quantity,
                'harga' => (float) $sale->harga,
                'kode_promo' => $sale->kode_promo,
                'promo' => $sale->promo,
                'approval_status' => $sale->approval_status,
                'bukti_pembelian' => $sale->bukti_pembelian ? Storage::disk('public')->url($sale->bukti_pembelian) : null,
                'created_at' => optional($sale->created_at)->format('Y-m-d H:i:s'),
            ])
            ->values();

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

        return Inertia::render('Sales/Index', [
            'sales' => $sales,
            'products' => $products,
            'promos' => $promos,
            'canApprove' => $isManager,
            'canManageAll' => $isManager,
            'currentRole' => $user->role,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $user = $request->user();
        $isManager = in_array($user->role, ['superadmin', 'admin'], true);

        $validated = $request->validate([
            'id_product' => ['required', 'exists:products,id_product'],
            'quantity' => ['required', 'integer', 'min:1'],
            'promo_id' => ['nullable', 'exists:promos,id'],
            'bukti_pembelian' => ['required', 'image', 'max:4096'],
        ]);

        $product = Product::query()->findOrFail($validated['id_product']);
        $promo = empty($validated['promo_id']) ? null : Promo::query()->findOrFail($validated['promo_id']);
        $subtotal = (float) $product->harga * (int) $validated['quantity'];

        if ($promo && $promo->masa_aktif->lt(today())) {
            return back()->withErrors(['promo_id' => 'Promo sudah tidak aktif.']);
        }

        if ($promo && $validated['quantity'] < $promo->minimal_quantity) {
            return back()->withErrors(['promo_id' => 'Pembelian belum mencapai syarat']);
        }

        if ($promo && $subtotal < (float) $promo->minimal_belanja) {
            return back()->withErrors(['promo_id' => 'Pembelian belum mencapai syarat']);
        }

        $onhand = null;
        if (! $isManager) {
            $onhand = $this->resolveOnhandForSale($user->id_user, $product->id_product);

            if (! $onhand) {
                return back()->withErrors(['id_product' => 'Barang belum diambil untuk hari ini.']);
            }

            $available = $this->availableForOnhand($onhand);
            if ($validated['quantity'] > $available) {
                return back()->withErrors(['quantity' => 'Quantity penjualan melebihi barang yang dibawa.']);
            }
        }

        $total = max($subtotal - ($promo ? (float) $promo->potongan : 0), 0);
        $path = $request->file('bukti_pembelian')->store('offline-sales', 'public');

        OfflineSale::query()->create([
            'id_user' => $user->id_user,
            'id_product' => $product->id_product,
            'id_product_onhand' => $onhand?->id_product_onhand,
            'promo_id' => $promo?->id,
            'nama' => $user->nama,
            'nama_product' => $product->nama_product,
            'quantity' => $validated['quantity'],
            'harga' => $total,
            'kode_promo' => $promo?->kode_promo,
            'promo' => $promo?->nama_promo,
            'bukti_pembelian' => $path,
            'approval_status' => $isManager ? 'disetujui' : 'pending',
            'approved_by' => $isManager ? $user->id_user : null,
            'approved_at' => $isManager ? now() : null,
            'created_at' => now(),
        ]);

        return redirect()->route('offline-sales.index')->with('success', 'Penjualan offline berhasil disimpan.');
    }

    public function update(Request $request, OfflineSale $sale): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        $validated = $request->validate([
            'quantity' => ['required', 'integer', 'min:1'],
        ]);

        $product = Product::query()->find($sale->id_product);
        $promo = $sale->promo_id ? Promo::query()->find($sale->promo_id) : null;
        $subtotal = (float) ($product?->harga ?? 0) * $validated['quantity'];

        if ($promo && $validated['quantity'] < $promo->minimal_quantity) {
            return back()->withErrors(['quantity' => 'Pembelian belum mencapai syarat']);
        }

        if ($promo && $subtotal < (float) $promo->minimal_belanja) {
            return back()->withErrors(['quantity' => 'Pembelian belum mencapai syarat']);
        }

        $owner = User::query()->find($sale->id_user);
        if ($sale->id_product_onhand && $owner && in_array($owner->role, ['marketing', 'reseller'], true)) {
            $available = $this->availableForOnhand($sale->onhand, $sale->id_penjualan_offline) + $sale->quantity;
            if ($validated['quantity'] > $available) {
                return back()->withErrors(['quantity' => 'Quantity penjualan melebihi barang yang dibawa.']);
            }
        }

        $sale->update([
            'quantity' => $validated['quantity'],
            'harga' => max($subtotal - ($promo ? (float) $promo->potongan : 0), 0),
        ]);

        return redirect()->route('offline-sales.index')->with('success', 'Penjualan offline berhasil diperbarui.');
    }

    public function destroy(Request $request, OfflineSale $sale): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        if ($sale->bukti_pembelian) {
            Storage::disk('public')->delete($sale->bukti_pembelian);
        }

        $sale->delete();

        return redirect()->route('offline-sales.index')->with('success', 'Penjualan offline berhasil dihapus.');
    }

    public function approve(Request $request, OfflineSale $sale): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        $sale->update([
            'approval_status' => 'disetujui',
            'approved_by' => $request->user()->id_user,
            'approved_at' => now(),
        ]);

        return redirect()->route('offline-sales.index')->with('success', 'Penjualan offline disetujui.');
    }

    public function reject(Request $request, OfflineSale $sale): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        $sale->update([
            'approval_status' => 'ditolak',
            'approved_by' => $request->user()->id_user,
            'approved_at' => now(),
        ]);

        return redirect()->route('offline-sales.index')->with('success', 'Penjualan offline ditolak.');
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
