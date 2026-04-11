<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Product;
use App\Models\ProductOnhand;
use App\Support\MarketingMobileSupport;
use App\Support\ProductOnhandBatchSupport;
use App\Support\SalesRole;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless(in_array($user?->role, SalesRole::mobileRoles(), true), 403);
        $storeId = MarketingMobileSupport::currentStoreId($user);

        $attendanceContext = MarketingMobileSupport::attendanceContext($user);

        $products = Product::query()
            ->with(['fragranceDetails', 'images'])
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
            ->where('stock', '>', 0)
            ->orderBy('nama_product')
            ->get(['id_product', 'nama_product', 'stock', 'harga', 'gambar', 'deskripsi'])
            ->map(fn (Product $product) => [
                'id_product' => $product->id_product,
                'nama_product' => $product->nama_product,
                'stock' => (int) $product->stock,
                'harga' => (float) $product->harga,
                'deskripsi' => $product->deskripsi,
                'image_url' => $product->public_image_url,
                'badge_labels' => $product->fragranceDetails
                    ->pluck('detail')
                    ->filter()
                    ->map(fn ($detail) => (string) $detail)
                    ->unique()
                    ->values(),
                'option_label' => $product->nama_product . ' | stock ' . (int) $product->stock,
            ])
            ->values();

        $onhands = MarketingMobileSupport::isSmoothiesSweetieUser($user)
            ? collect()
            : ProductOnhand::query()
                ->with('user')
                ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
                ->where('user_id', $user->id_user)
                ->orderByDesc('assignment_date')
                ->orderByDesc('id_product_onhand')
                ->get()
                ->map(fn (ProductOnhand $onhand) => MarketingMobileSupport::transformOnhand($onhand))
                ->values();

        $todayReturnItems = $onhands
            ->filter(fn (array $onhand) => $onhand['take_status'] !== 'ditolak' && (
                $onhand['take_status'] !== 'disetujui'
                || ! $onhand['sold_out']
                || $onhand['quantity_dikembalikan'] > 0
            ))
            ->values();

        $historyOnhands = $onhands
            ->filter(fn (array $onhand) => $onhand['take_status'] === 'disetujui'
                && ! MarketingMobileSupport::countsAsActiveOnhand($onhand))
            ->values();

        return response()->json([
            'products' => $products,
            'attendance_ready' => $attendanceContext['attendanceReady'],
            'attendance_blocked_reason' => $attendanceContext['attendanceBlockedReason'],
            'today_attendance' => $attendanceContext['todayAttendance'],
            'onhands' => $onhands,
            'today_return_items' => $todayReturnItems,
            'history_onhands' => $historyOnhands,
        ]);
    }

    public function take(Request $request): JsonResponse
    {
        abort_if(
            MarketingMobileSupport::isSmoothiesSweetieUser($request->user()),
            404,
            'Fitur onhand dinonaktifkan untuk store Smoothies Sweetie.'
        );

        $storeId = MarketingMobileSupport::currentStoreId($request->user());
        $attendance = Attendance::query()
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
            ->where('user_id', $request->user()->id_user)
            ->whereDate('attendance_date', now()->toDateString())
            ->first();

        if (! $attendance?->check_in) {
            return response()->json(['message' => 'Sales lapangan wajib check in terlebih dahulu sebelum mengambil barang.'], 422);
        }

        if ($attendance?->check_out) {
            return response()->json(['message' => 'User yang sudah check out tidak bisa request barang lagi hari ini.'], 422);
        }

        $validated = $request->validate([
            'id_product' => ['required', 'exists:products,id_product'],
            'quantity' => ['required', 'integer', 'min:1'],
        ]);

        $pendingRequest = ProductOnhand::query()
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
            ->where('user_id', $request->user()->id_user)
            ->where('id_product', $validated['id_product'])
            ->whereDate('assignment_date', now()->toDateString())
            ->where('take_status', 'pending')
            ->exists();

        if ($pendingRequest) {
            return response()->json(['message' => 'Masih ada antrian yang belum disetujui.'], 422);
        }

        $product = Product::query()
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
            ->findOrFail($validated['id_product']);

        if ($product->stock <= 0) {
            return response()->json(['message' => 'Stock kosong, silakan hubungi admin.'], 422);
        }

        if ($product->stock < $validated['quantity']) {
            return response()->json(['message' => 'Stock product tidak mencukupi.'], 422);
        }

        $onhand = ProductOnhand::query()->create([
            'store_id' => $storeId,
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

        $onhand->update([
            'pickup_batch_code' => ProductOnhandBatchSupport::generate($onhand),
        ]);

        return response()->json([
            'message' => 'Request pengambilan barang berhasil dikirim.',
            'onhand' => MarketingMobileSupport::transformOnhand($onhand->fresh('user')),
        ], 201);
    }

    public function requestReturn(Request $request, int $onhand): JsonResponse
    {
        abort_if(
            MarketingMobileSupport::isSmoothiesSweetieUser($request->user()),
            404,
            'Fitur onhand dinonaktifkan untuk store Smoothies Sweetie.'
        );

        $onhand = ProductOnhand::query()
            ->with('user')
            ->when(MarketingMobileSupport::currentStoreId($request->user()), fn ($query, $storeId) => $query->where('store_id', $storeId))
            ->where('id_product_onhand', $onhand)
            ->where('user_id', $request->user()->id_user)
            ->firstOrFail();

        if ($onhand->take_status !== 'disetujui') {
            return response()->json(['message' => 'Barang belum disetujui untuk dibawa.'], 422);
        }

        $state = MarketingMobileSupport::stateForOnhand($onhand);

        if ($onhand->return_status === 'pending') {
            return response()->json(['message' => 'Masih ada antrian yang belum disetujui.'], 422);
        }

        if ($state['sold_out']) {
            return response()->json(['message' => 'Barang sudah habis terjual, tidak wajib pengembalian.'], 422);
        }

        $validated = $request->validate([
            'quantity_dikembalikan' => ['required', 'integer', 'min:1'],
        ]);

        if ($validated['quantity_dikembalikan'] > (int) $onhand->quantity) {
            return response()->json(['message' => 'Quantity pengembalian tidak boleh melebihi quantity pengambilan.'], 422);
        }

        if ($validated['quantity_dikembalikan'] > $state['max_return']) {
            return response()->json(['message' => 'Quantity pengembalian melebihi sisa barang yang belum terjual.'], 422);
        }

        $onhand->update([
            'quantity_dikembalikan' => $validated['quantity_dikembalikan'],
            'return_status' => $validated['quantity_dikembalikan'] > 0 ? 'pending' : 'belum',
            'approved_by' => null,
        ]);

        return response()->json([
            'message' => 'Request pengembalian barang berhasil dikirim.',
            'onhand' => MarketingMobileSupport::transformOnhand($onhand->fresh('user')),
        ]);
    }
}

