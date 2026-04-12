<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Expense;
use App\Models\OfflineSale;
use App\Models\OnlineSaleItem;
use App\Models\ProductOnhand;
use App\Models\RawMaterial;
use App\Models\User;
use App\Support\MarketingMobileSupport;
use App\Support\SalesRole;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Collection;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless(in_array($user?->role, SalesRole::mobileRoles(), true), 403);
        $storeId = MarketingMobileSupport::currentStoreId($user);

        if ($user->role === SalesRole::OWNER) {
            [$monthStart, $monthEnd, $dashboardFilters] = $this->resolveDashboardPeriod($request);
            $dashboardData = $this->buildOwnerDashboardData(
                $storeId,
                $monthStart,
                $monthEnd,
                (string) ($dashboardFilters['type'] ?? 'all')
            );

            return response()->json([
                'user' => [
                    'nama' => $user->nama,
                    'role' => $user->role,
                ],
                'dashboard_filters' => $dashboardFilters,
                'dashboard_data' => $dashboardData,
            ]);
        }

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

    private function buildOwnerDashboardData(?int $storeId, Carbon $monthStart, Carbon $monthEnd, string $salesType): array
    {
        $includeOffline = in_array($salesType, ['all', 'offline'], true);
        $includeOnline = in_array($salesType, ['all', 'online'], true);
        $offlineSales = $includeOffline
            ? OfflineSale::query()
                ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
                ->where('approval_status', '!=', 'ditolak')
                ->whereBetween('created_at', [$monthStart, $monthEnd])
                ->get()
            : collect();
        $onlineItems = $includeOnline
            ? OnlineSaleItem::query()
                ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
                ->whereBetween('created_at', [$monthStart, $monthEnd])
                ->get()
            : collect();
        $operationalExpenseTotal = round((float) Expense::query()
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
            ->where('category', 'operasional')
            ->whereBetween('expense_date', [$monthStart->toDateString(), $monthEnd->toDateString()])
            ->sum('amount'), 2);
        $wasteLossTotal = round((float) RawMaterial::query()
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
            ->sum('waste_loss_amount'), 2);

        $offlineRevenue = round((float) $offlineSales->sum('harga'), 2);
        $onlineRevenue = round((float) $onlineItems->sum('harga'), 2);
        $offlineHpp = round((float) $offlineSales->sum(fn ($sale) => ((float) ($sale->total_hpp ?? 0)) * (int) ($sale->quantity ?? 0)), 2);
        $onlineHpp = round((float) $onlineItems->sum(fn ($item) => ((float) ($item->product?->hppCalculation?->total_hpp ?? $item->product?->harga_modal ?? 0)) * (int) ($item->quantity ?? 0)), 2);
        $revenueTotal = round($offlineRevenue + $onlineRevenue, 2);
        $grossProfitTotal = round(($offlineRevenue - $offlineHpp) + ($onlineRevenue - $onlineHpp) - $wasteLossTotal, 2);
        $netProfitTotal = round($grossProfitTotal - $operationalExpenseTotal, 2);
        $teamPerformance = $this->buildTeamPerformance($storeId, $monthStart, $monthEnd);
        $onDutyCount = Attendance::query()
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
            ->whereDate('attendance_date', now()->toDateString())
            ->whereNotNull('check_in')
            ->whereNull('check_out')
            ->whereHas('user', fn ($query) => $query->whereIn('role', [
                SalesRole::KARYAWAN,
                SalesRole::MARKETING,
                SalesRole::SALES_FIELD_EXECUTIVE,
            ]))
            ->count();

        return [
            'mode' => 'manager',
            'period_label' => $monthStart->copy()->locale('id')->translatedFormat('F Y'),
            'active_filter_type' => $salesType,
            'kpis' => [
                'gross_profit_offline_total' => $offlineRevenue,
                'gross_profit_online_total' => $onlineRevenue,
                'revenue_total' => $revenueTotal,
                'gross_profit_total' => $grossProfitTotal,
                'net_profit_total' => $netProfitTotal,
                'product_sold_offline' => (int) $offlineSales->sum('quantity'),
                'product_sold_online' => (int) $onlineItems->sum('quantity'),
                'marketing_count' => User::query()->where('role', SalesRole::MARKETING)->when($storeId, fn ($query) => $query->whereHas('stores', fn ($stores) => $stores->where('stores.id', $storeId)))->count(),
                'seller_count' => User::query()->where('role', SalesRole::SALES_FIELD_EXECUTIVE)->when($storeId, fn ($query) => $query->whereHas('stores', fn ($stores) => $stores->where('stores.id', $storeId)))->count(),
                'employee_count' => User::query()->where('role', SalesRole::KARYAWAN)->when($storeId, fn ($query) => $query->whereHas('stores', fn ($stores) => $stores->where('stores.id', $storeId)))->count(),
                'on_duty_marketing' => $onDutyCount,
                'operational_expense_total' => $operationalExpenseTotal,
                'waste_loss_total' => $wasteLossTotal,
            ],
            'team_summary' => [
                'marketing' => User::query()->where('role', SalesRole::MARKETING)->when($storeId, fn ($query) => $query->whereHas('stores', fn ($stores) => $stores->where('stores.id', $storeId)))->count(),
                'sales_field_executive' => User::query()->where('role', SalesRole::SALES_FIELD_EXECUTIVE)->when($storeId, fn ($query) => $query->whereHas('stores', fn ($stores) => $stores->where('stores.id', $storeId)))->count(),
                'karyawan' => User::query()->where('role', SalesRole::KARYAWAN)->when($storeId, fn ($query) => $query->whereHas('stores', fn ($stores) => $stores->where('stores.id', $storeId)))->count(),
                'on_duty' => $onDutyCount,
            ],
            'team_performance' => $teamPerformance,
        ];
    }

    private function buildTeamPerformance(?int $storeId, Carbon $monthStart, Carbon $monthEnd): array
    {
        $users = User::query()
            ->when($storeId, fn ($query) => $query->whereHas('stores', fn ($stores) => $stores->where('stores.id', $storeId)))
            ->whereIn('role', [SalesRole::KARYAWAN, SalesRole::MARKETING, SalesRole::SALES_FIELD_EXECUTIVE])
            ->orderBy('nama')
            ->get();

        return $users->map(function (User $member) use ($storeId, $monthStart, $monthEnd) {
            $memberSales = OfflineSale::query()
                ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
                ->where('id_user', $member->id_user)
                ->where('approval_status', '!=', 'ditolak')
                ->whereBetween('created_at', [$monthStart, $monthEnd])
                ->get();
            $attendanceDays = Attendance::query()
                ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
                ->where('user_id', $member->id_user)
                ->whereBetween('attendance_date', [$monthStart->toDateString(), $monthEnd->toDateString()])
                ->whereNotNull('check_in')
                ->count();

            return [
                'user_id' => $member->id_user,
                'name' => $member->nama,
                'role' => $member->role,
                'attendance_days' => $attendanceDays,
                'quantity_sold' => (int) $memberSales->sum('quantity'),
                'revenue_total' => round((float) $memberSales->sum('harga'), 2),
            ];
        })->values()->all();
    }

    private function resolveDashboardPeriod(Request $request): array
    {
        $validated = $request->validate([
            'type' => ['nullable', 'in:all,offline,online'],
            'month' => ['nullable', 'integer', 'between:1,12'],
            'year' => ['nullable', 'integer', 'between:2020,2100'],
        ]);

        $selectedType = (string) ($validated['type'] ?? 'all');
        $selectedMonth = (int) ($validated['month'] ?? now()->month);
        $selectedYear = (int) ($validated['year'] ?? now()->year);
        $monthStart = Carbon::create($selectedYear, $selectedMonth, 1)->startOfMonth();
        $monthEnd = $monthStart->copy()->endOfMonth();
        $currentYear = now()->year;

        return [
            $monthStart,
            $monthEnd,
            [
                'type' => $selectedType,
                'month' => $selectedMonth,
                'year' => $selectedYear,
                'period_label' => $monthStart->copy()->locale('id')->translatedFormat('F Y'),
                'types' => [
                    ['value' => 'all', 'label' => 'All Selling'],
                    ['value' => 'offline', 'label' => 'Offline Selling'],
                    ['value' => 'online', 'label' => 'Online Selling'],
                ],
                'months' => collect(range(1, 12))->map(fn (int $month) => [
                    'value' => $month,
                    'label' => Carbon::create($selectedYear, $month, 1)->locale('id')->translatedFormat('F'),
                ])->values()->all(),
                'years' => collect(range($currentYear - 5, $currentYear + 1))->map(fn (int $year) => [
                    'value' => $year,
                    'label' => (string) $year,
                ])->values()->all(),
            ],
        ];
    }
}

