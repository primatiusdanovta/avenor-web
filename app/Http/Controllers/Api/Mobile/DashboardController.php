<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\OfflineSale;
use App\Models\ProductOnhand;
use App\Support\MarketingMobileSupport;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user?->role === 'marketing', 403);

        $monthStart = Carbon::now()->startOfMonth();
        $monthEnd = Carbon::now()->endOfMonth();
        $attendanceContext = MarketingMobileSupport::attendanceContext($user);
        $marketingKpi = MarketingMobileSupport::buildMarketingKpi($user->id_user, $monthStart, $monthEnd);
        $targetSummary = MarketingMobileSupport::buildTargetSummary($user, $monthStart, $monthEnd);

        $recentSales = OfflineSale::query()
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

        $activeOnhands = ProductOnhand::query()
            ->with('user')
            ->where('user_id', $user->id_user)
            ->whereDate('assignment_date', now()->toDateString())
            ->orderByDesc('id_product_onhand')
            ->get()
            ->map(fn (ProductOnhand $onhand) => MarketingMobileSupport::transformOnhand($onhand))
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
                'onhand_count' => $activeOnhands->count(),
                'pending_return_count' => $activeOnhands->where('return_status', 'pending')->count(),
                'pending_take_count' => $activeOnhands->where('take_status', 'pending')->count(),
                'approved_sales_count' => OfflineSale::query()
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
