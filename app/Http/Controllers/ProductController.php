<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\OfflineSale;
use App\Models\Product;
use App\Models\ProductOnhand;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class ProductController extends Controller
{
    public function index(Request $request): Response
    {
        $user = $request->user();

        if (in_array($user->role, ['superadmin', 'admin'], true)) {
            $products = Product::query()
                ->orderByDesc('created_at')
                ->get()
                ->map(fn (Product $product) => [
                    'id_product' => $product->id_product,
                    'nama_product' => $product->nama_product,
                    'harga' => (float) $product->harga,
                    'harga_modal' => (float) $product->harga_modal,
                    'stock' => (int) $product->stock,
                    'gambar' => $product->gambar ? Storage::disk('public')->url($product->gambar) : null,
                    'created_at' => optional($product->created_at)->format('Y-m-d H:i:s'),
                ])
                ->values();

            return Inertia::render('Products/Manage', ['products' => $products]);
        }

        abort_unless(in_array($user->role, ['marketing', 'reseller'], true), 403);

        $todayAttendance = null;
        if ($user->role === 'marketing') {
            $todayAttendance = Attendance::query()
                ->where('user_id', $user->id_user)
                ->whereDate('attendance_date', now()->toDateString())
                ->first();
        }

        $products = Product::query()
            ->where('stock', '>', 0)
            ->orderBy('nama_product')
            ->get(['id_product', 'nama_product', 'stock', 'harga'])
            ->map(fn (Product $product) => [
                'id_product' => $product->id_product,
                'nama_product' => $product->nama_product,
                'stock' => (int) $product->stock,
                'harga' => (float) $product->harga,
                'option_label' => $product->nama_product . ' | stock ' . (int) $product->stock,
            ])
            ->values();

        $onhands = ProductOnhand::query()
            ->where('user_id', $user->id_user)
            ->orderByDesc('assignment_date')
            ->orderByDesc('id_product_onhand')
            ->get()
            ->map(fn (ProductOnhand $onhand) => $this->transformOnhand($onhand))
            ->values();

        $todayReturnItems = ProductOnhand::query()
            ->where('user_id', $user->id_user)
            ->whereDate('assignment_date', now()->toDateString())
            ->orderByDesc('id_product_onhand')
            ->get()
            ->map(fn (ProductOnhand $onhand) => $this->transformOnhand($onhand))
            ->values();

        return Inertia::render('Products/Onhand', [
            'products' => $products,
            'attendanceReady' => $user->role !== 'marketing' || (bool) $todayAttendance?->check_in,
            'todayAttendance' => $todayAttendance ? [
                'status' => $todayAttendance->status,
                'check_in' => $todayAttendance->check_in,
                'check_out' => $todayAttendance->check_out,
            ] : null,
            'onhands' => $onhands,
            'todayReturnItems' => $todayReturnItems,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->authorizeManagement($request);

        $validated = $request->validate([
            'nama_product' => ['required', 'string', 'max:255', 'unique:products,nama_product'],
            'harga' => ['required', 'numeric', 'min:0'],
            'stock' => ['required', 'integer', 'min:0'],
            'gambar' => ['nullable', 'image', 'max:3072'],
        ]);

        $path = $request->file('gambar')?->store('products', 'public');

        Product::query()->create([
            'nama_product' => $validated['nama_product'],
            'harga' => $validated['harga'],
            'harga_modal' => 0,
            'stock' => $validated['stock'],
            'gambar' => $path,
            'created_at' => now(),
        ]);

        return redirect()->route('products.index')->with('success', 'Product berhasil ditambahkan.');
    }

    public function update(Request $request, Product $product): RedirectResponse
    {
        $this->authorizeManagement($request);

        $validated = $request->validate([
            'nama_product' => ['required', 'string', 'max:255', Rule::unique('products', 'nama_product')->ignore($product->id_product, 'id_product')],
            'harga' => ['required', 'numeric', 'min:0'],
            'stock' => ['required', 'integer', 'min:0'],
            'gambar' => ['nullable', 'image', 'max:3072'],
        ]);

        $payload = [
            'nama_product' => $validated['nama_product'],
            'harga' => $validated['harga'],
            'stock' => $validated['stock'],
        ];

        if ($request->hasFile('gambar')) {
            if ($product->gambar) {
                Storage::disk('public')->delete($product->gambar);
            }

            $payload['gambar'] = $request->file('gambar')->store('products', 'public');
        }

        $product->update($payload);

        return redirect()->route('products.index')->with('success', 'Product berhasil diperbarui.');
    }

    public function destroy(Request $request, Product $product): RedirectResponse
    {
        $this->authorizeManagement($request);

        if ($product->gambar) {
            Storage::disk('public')->delete($product->gambar);
        }

        $product->delete();

        return redirect()->route('products.index')->with('success', 'Product berhasil dihapus.');
    }

    public function take(Request $request): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['marketing', 'reseller'], true), 403);

        if ($request->user()->role === 'marketing') {
            $attendance = Attendance::query()
                ->where('user_id', $request->user()->id_user)
                ->whereDate('attendance_date', now()->toDateString())
                ->first();

            abort_unless($attendance?->check_in, 403, 'Marketing wajib check in sebelum mengambil barang.');
        }

        $validated = $request->validate([
            'id_product' => ['required', 'exists:products,id_product'],
            'quantity' => ['required', 'integer', 'min:1'],
        ]);

        $pendingRequest = ProductOnhand::query()
            ->where('user_id', $request->user()->id_user)
            ->where('id_product', $validated['id_product'])
            ->whereDate('assignment_date', now()->toDateString())
            ->where('take_status', 'pending')
            ->exists();

        if ($pendingRequest) {
            return back()->withErrors(['id_product' => 'Masih ada antrian yang belum disetujui']);
        }

        $product = Product::query()->findOrFail($validated['id_product']);

        if ($product->stock < $validated['quantity']) {
            return back()->withErrors(['quantity' => 'Stock product tidak mencukupi.']);
        }

        ProductOnhand::query()->create([
            'user_id' => $request->user()->id_user,
            'id_product' => $product->id_product,
            'nama_product' => $product->nama_product,
            'quantity' => $validated['quantity'],
            'quantity_dikembalikan' => 0,
            'take_status' => 'pending',
            'return_status' => 'belum',
            'assignment_date' => now()->toDateString(),
            'created_at' => now(),
            'take_requested_at' => now(),
        ]);

        return redirect()->route('products.index')->with('success', 'Request pengambilan barang berhasil dikirim.');
    }

    public function requestReturn(Request $request, ProductOnhand $onhand): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['marketing', 'reseller'], true), 403);
        abort_unless($onhand->user_id === $request->user()->id_user, 404);

        if ($onhand->take_status !== 'disetujui') {
            return back()->withErrors(['quantity_dikembalikan' => 'Barang belum disetujui untuk dibawa.']);
        }

        $state = $this->stateForOnhand($onhand);

        if ($onhand->return_status === 'pending') {
            return back()->withErrors(['quantity_dikembalikan' => 'Masih ada antrian yang belum disetujui']);
        }

        if ($state['sold_out']) {
            return back()->withErrors(['quantity_dikembalikan' => 'Barang sudah habis terjual, tidak wajib pengembalian.']);
        }

        $validated = $request->validate([
            'quantity_dikembalikan' => ['required', 'integer', 'min:0'],
        ]);

        if ($validated['quantity_dikembalikan'] > (int) $onhand->quantity) {
            return back()->withErrors(['quantity_dikembalikan' => 'Quantity pengembalian tidak boleh melebihi quantity pengambilan.']);
        }

        if ($validated['quantity_dikembalikan'] > $state['max_return']) {
            return back()->withErrors(['quantity_dikembalikan' => 'Quantity pengembalian melebihi sisa barang yang belum terjual.']);
        }

        $onhand->update([
            'quantity_dikembalikan' => $validated['quantity_dikembalikan'],
            'return_status' => $validated['quantity_dikembalikan'] > 0 ? 'pending' : 'belum',
            'approved_by' => null,
        ]);

        return redirect()->route('products.index')->with('success', 'Request pengembalian barang berhasil dikirim.');
    }

    public function approveReturn(Request $request, ProductOnhand $onhand): RedirectResponse
    {
        $this->authorizeManagement($request);
        abort_unless($onhand->quantity_dikembalikan > 0, 422);

        DB::transaction(function () use ($request, $onhand): void {
            $product = Product::query()->lockForUpdate()->findOrFail($onhand->id_product);

            if ($onhand->return_status !== 'disetujui') {
                $product->increment('stock', $onhand->quantity_dikembalikan);
            }

            $onhand->update([
                'return_status' => 'disetujui',
                'approved_by' => $request->user()->id_user,
            ]);
        });

        return $this->managerRedirect($onhand, 'Pengembalian barang disetujui.');
    }

    public function rejectReturn(Request $request, ProductOnhand $onhand): RedirectResponse
    {
        $this->authorizeManagement($request);

        $onhand->update([
            'quantity_dikembalikan' => 0,
            'return_status' => 'tidak_disetujui',
            'approved_by' => $request->user()->id_user,
        ]);

        return $this->managerRedirect($onhand, 'Pengembalian barang ditolak.');
    }

    public function approveTake(Request $request, ProductOnhand $onhand): RedirectResponse
    {
        $this->authorizeManagement($request);
        abort_unless($onhand->take_status === 'pending', 422);

        DB::transaction(function () use ($request, $onhand): void {
            $product = Product::query()->lockForUpdate()->findOrFail($onhand->id_product);

            if ($product->stock < $onhand->quantity) {
                abort(422, 'Stock product tidak mencukupi untuk menyetujui request ini.');
            }

            $product->decrement('stock', $onhand->quantity);

            $onhand->update([
                'take_status' => 'disetujui',
                'take_approved_by' => $request->user()->id_user,
                'take_reviewed_at' => now(),
            ]);
        });

        return $this->managerRedirect($onhand, 'Request pengambilan barang disetujui.');
    }

    public function rejectTake(Request $request, ProductOnhand $onhand): RedirectResponse
    {
        $this->authorizeManagement($request);
        abort_unless($onhand->take_status === 'pending', 422);

        $onhand->update([
            'take_status' => 'ditolak',
            'take_approved_by' => $request->user()->id_user,
            'take_reviewed_at' => now(),
        ]);

        return $this->managerRedirect($onhand, 'Request pengambilan barang ditolak.');
    }

    private function authorizeManagement(Request $request): void
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);
    }

    private function transformOnhand(ProductOnhand $onhand): array
    {
        $state = $this->stateForOnhand($onhand);

        return [
            'id_product_onhand' => $onhand->id_product_onhand,
            'id_product' => $onhand->id_product,
            'nama_product' => $onhand->nama_product,
            'quantity' => (int) $onhand->quantity,
            'quantity_dikembalikan' => (int) $onhand->quantity_dikembalikan,
            'take_status' => $onhand->take_status,
            'take_status_label' => $this->takeStatusLabel($onhand->take_status),
            'return_status' => $onhand->return_status,
            'status_label' => $state['status_label'],
            'assignment_date' => optional($onhand->assignment_date)->format('Y-m-d'),
            'sold_quantity' => $state['sold_quantity'],
            'remaining_quantity' => $state['remaining_quantity'],
            'max_return' => $state['max_return'],
            'requires_return' => $state['requires_return'],
            'can_checkout' => $state['can_checkout'],
            'has_pending_request' => $onhand->return_status === 'pending',
            'sold_out' => $state['sold_out'],
            'can_request_return' => $onhand->take_status === 'disetujui' && ! $state['sold_out'],
        ];
    }

    private function stateForOnhand(ProductOnhand $onhand): array
    {
        if ($onhand->take_status !== 'disetujui') {
            return [
                'sold_quantity' => 0,
                'remaining_quantity' => 0,
                'max_return' => 0,
                'requires_return' => false,
                'can_checkout' => true,
                'sold_out' => false,
                'status_label' => $this->takeStatusLabel($onhand->take_status),
            ];
        }

        $soldQuantity = $this->soldForOnhand($onhand);
        $countedReturn = in_array($onhand->return_status, ['pending', 'disetujui'], true) ? (int) $onhand->quantity_dikembalikan : 0;
        $soldOut = $soldQuantity >= (int) $onhand->quantity;
        $remainingQuantity = max((int) $onhand->quantity - $soldQuantity - $countedReturn, 0);
        $maxReturn = max((int) $onhand->quantity - $soldQuantity, 0);
        $canCheckout = $soldOut || ($countedReturn > 0 && ($soldQuantity + $countedReturn) >= (int) $onhand->quantity);

        $statusLabel = $onhand->return_status;
        if ($soldOut) {
            $statusLabel = 'selesai_terjual';
        } elseif ($countedReturn > 0 && $onhand->return_status === 'disetujui') {
            $statusLabel = 'dikembalikan';
        }

        return [
            'sold_quantity' => $soldQuantity,
            'remaining_quantity' => $remainingQuantity,
            'max_return' => $maxReturn,
            'requires_return' => ! $soldOut,
            'can_checkout' => $canCheckout,
            'sold_out' => $soldOut,
            'status_label' => $statusLabel,
        ];
    }

    private function soldForOnhand(ProductOnhand $onhand): int
    {
        return (int) OfflineSale::query()
            ->where('id_product_onhand', $onhand->id_product_onhand)
            ->where('approval_status', '!=', 'ditolak')
            ->sum('quantity');
    }

    private function takeStatusLabel(string $status): string
    {
        return match ($status) {
            'pending' => 'menunggu_persetujuan',
            'ditolak' => 'request_ditolak',
            default => 'disetujui',
        };
    }

    private function managerRedirect(ProductOnhand $onhand, string $message): RedirectResponse
    {
        return redirect()
            ->route('approvals.index', ['selected' => $onhand->user_id])
            ->with('success', $message);
    }
}
