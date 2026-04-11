<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\OfflineSale;
use App\Models\ProductOnhand;
use App\Support\MarketingMobileSupport;
use App\Support\SalesRole;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless(in_array($user?->role, SalesRole::mobileRoles(), true), 403);
        $storeId = MarketingMobileSupport::currentStoreId($user);

        $monthStart = Carbon::now()->startOfMonth();
        $monthEnd = Carbon::now()->endOfMonth();
        $attendanceContext = MarketingMobileSupport::attendanceContext($user);
        $marketingKpi = MarketingMobileSupport::buildMarketingKpi($user->id_user, $monthStart, $monthEnd);
        $targetSummary = MarketingMobileSupport::buildTargetSummary($user, $monthStart, $monthEnd);

        $recentSales = OfflineSale::query()
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
            ->where('id_user', $user->id_user)
            ->orderByDesc('created_at')
            ->limit(5)
            ->get()
            ->map(fn (OfflineSale $sale) => [
                'id_penjualan_offline' => $sale->id_penjualan_offline,
                'transaction_code' => $sale->transaction_code,
                'nama_product' => $sale->nama_product,
                'quantity' => (int) $sale->quantity,
                'harga' => (float) $sale->harga,
                'approval_status' => $sale->approval_status,
                'created_at' => optional($sale->created_at)->format('Y-m-d H:i:s'),
            ])
            ->values();

        $onhands = MarketingMobileSupport::isSmoothiesSweetieUser($user)
            ? collect()
            : ProductOnhand::query()
                ->with('user')
                ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
                ->where('user_id', $user->id_user)
                ->whereDate('assignment_date', now()->toDateString())
                ->orderByDesc('id_product_onhand')
                ->get()
                ->map(fn (ProductOnhand $onhand) => MarketingMobileSupport::transformOnhand($onhand))
                ->values();

        $activeOnhands = $onhands
            ->filter(fn (array $onhand) => MarketingMobileSupport::countsAsActiveOnhand($onhand))
            ->values();

        return response()->json([
            'user' => [
                'nama' => $user->nama,
                'role' => $user->role,
            ],
            'today_attendance' => $attendanceContext['todayAttendance'],
            'attendance_ready' => $attendanceContext['attendanceReady'],
            'attendance_blocked_reason' => $attendanceContext['attendanceBlockedReason'],
            'marketing_kpi' => $marketingKpi,
            'target_summary' => $targetSummary,
            'stats' => [
                'onhand_count' => (int) $activeOnhands->sum(fn (array $onhand) => (int) ($onhand['remaining_quantity'] ?? 0)),
                'pending_return_count' => $onhands->where('return_status', 'pending')->count(),
                'pending_take_count' => $onhands->where('take_status', 'pending')->count(),
                'approved_sales_count' => OfflineSale::query()
                    ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
                    ->where('id_user', $user->id_user)
                    ->where('approval_status', 'disetujui')
                    ->whereBetween('created_at', [$monthStart->copy()->startOfDay(), $monthEnd->copy()->endOfDay()])
                    ->count(),
            ],
            'recent_sales' => $recentSales,
            'active_onhands' => $activeOnhands,
        ]);
    }
}

