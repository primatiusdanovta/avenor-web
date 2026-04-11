<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\Expense;
use App\Models\GlobalSetting;
use App\Models\OfflineSale;
use App\Models\OnlineSaleItem;
use App\Models\Product;
use App\Models\ProductOnhand;
use App\Models\Promo;
use App\Models\RawMaterial;
use App\Models\SalesTarget;
use App\Models\User;
use App\Support\MarketingBonusSupport;
use App\Support\StoreFeature;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Inertia\Inertia;
use Inertia\Response;

class DashboardController extends Controller
{
    public function __invoke(Request $request): Response
    {
        $user = $request->user();
        $this->authorizePermission($request, 'dashboard.view');
        $storeId = $this->currentStoreId($request);
        [$monthStart, $monthEnd, $dashboardFilters] = $this->resolveDashboardPeriod($request);
        $quickActions = [['label' => 'Reload Dashboard', 'href' => route('dashboard')]];
        $roleHighlights = [];

        if ($user->role === 'superadmin') {
            $quickActions[] = ['label' => 'Kelola User', 'href' => route('users.manage')];
            $quickActions[] = ['label' => 'Monitoring Field Team', 'href' => route('field-team.index')];
            $quickActions[] = ['label' => 'Approvals', 'href' => route('approvals.index')];
            $quickActions[] = ['label' => 'Raw Material', 'href' => route('raw-materials.index')];
            $quickActions[] = ['label' => 'HPP', 'href' => route('hpp.index')];
            $quickActions[] = ['label' => 'Products', 'href' => route('products.index')];
            $quickActions[] = ['label' => 'Promos', 'href' => route('promos.index')];
            $quickActions[] = ['label' => 'Pelanggan', 'href' => route('customers.index')];
            $quickActions[] = ['label' => 'Content Creator', 'href' => route('content-creators.index')];
            $quickActions[] = ['label' => 'Applicant', 'href' => route('applicants.index')];
            $quickActions[] = ['label' => 'Penjualan Offline', 'href' => route('offline-sales.index')];
            $quickActions[] = ['label' => 'Penjualan Online', 'href' => route('online-sales.index')];
            $quickActions[] = ['label' => 'Pengeluaran', 'href' => route('expenses.index')];
            $quickActions[] = ['label' => 'Target Penjualan', 'href' => route('sales-targets.index')];
            $quickActions[] = ['label' => 'Report', 'href' => route('reports.index')];
            $roleHighlights = [
                ['title' => 'Kontrol Master Data', 'description' => 'Superadmin mengelola user, raw material, HPP product, promo, penjualan offline, penjualan online, target penjualan, report, serta approval pengambilan dan pengembalian barang.'],
                ['title' => 'Monitoring Field Team', 'description' => 'Pantau performa penjualan, profit, kehadiran, dan aktivitas tim lapangan secara real-time.'],
            ];
        } elseif ($user->role === 'marketing') {
            $quickActions[] = ['label' => 'Absensi', 'href' => route('marketing.attendance.index')];
            $quickActions[] = ['label' => 'Products', 'href' => route('products.index')];
            $quickActions[] = ['label' => 'Penjualan Offline', 'href' => route('offline-sales.index')];
            $roleHighlights = [
                ['title' => 'Absensi Otomatis', 'description' => 'Jam check in/check out dan lokasi terekam otomatis setiap kali absensi dijalankan.'],
                ['title' => 'Monitoring Performa', 'description' => 'Dashboard menampilkan target penjualan, bonus berjalan, jam kerja, dan produk terlaris Anda.'],
            ];
        } elseif ($user->role === 'admin') {
            $quickActions[] = ['label' => 'Monitoring Field Team', 'href' => route('field-team.index')];
            $quickActions[] = ['label' => 'Approvals', 'href' => route('approvals.index')];
            $quickActions[] = ['label' => 'Products', 'href' => route('products.index')];
            $quickActions[] = ['label' => 'Promos', 'href' => route('promos.index')];
            $quickActions[] = ['label' => 'Pelanggan', 'href' => route('customers.index')];
            $quickActions[] = ['label' => 'Content Creator', 'href' => route('content-creators.index')];
            $quickActions[] = ['label' => 'Penjualan Offline', 'href' => route('offline-sales.index')];
            $quickActions[] = ['label' => 'Pengeluaran', 'href' => route('expenses.index')];
            $quickActions[] = ['label' => 'Report', 'href' => route('reports.index')];
            $roleHighlights = [
                ['title' => 'Approval Operasional', 'description' => 'Admin menyetujui penjualan offline, pengambilan barang, dan pengembalian barang dari field team.'],
                ['title' => 'Profit Dashboard', 'description' => 'Admin melihat gross profit, net profit, ranking penjualan, serta produk terlaris bulan berjalan.'],
            ];
        } else {
            $quickActions[] = ['label' => 'Products', 'href' => route('products.index')];
            $quickActions[] = ['label' => 'Penjualan Offline', 'href' => route('offline-sales.index')];
            $roleHighlights = [
                ['title' => 'Stock On Hand', 'description' => 'Sales field executive melihat barang yang dibawa, menginput penjualan, melakukan consign, dan melanjutkan checkout tanpa wajib retur harian.'],
                ['title' => 'Ringkasan Performa', 'description' => 'Dashboard menampilkan target penjualan, bonus berjalan, grafik penjualan, dan produk terlaris Anda.'],
            ];
        }

        return Inertia::render('Dashboard', [
            'summary' => [
                'totalUsers' => User::count(),
                'activeUsers' => User::where('status', 'aktif')->count(),
                'inactiveUsers' => User::where('status', '!=', 'aktif')->count(),
                'currentRole' => $user->role,
            ],
            'quickActions' => $quickActions,
            'roleHighlights' => $roleHighlights,
            'dashboardFilters' => $dashboardFilters,
            'dashboardData' => $this->buildDashboardData($user, $monthStart, $monthEnd, $dashboardFilters['type'] ?? 'all', $storeId),
            'salesAppDownload' => $user->role === 'marketing'
                ? [
                    'url' => data_get(GlobalSetting::masterSocialHub(), 'sales_app_apk_url'),
                    'name' => data_get(GlobalSetting::masterSocialHub(), 'sales_app_apk_name'),
                ]
                : null,
            'inventorySummary' => $user->role === 'superadmin' ? [
                'products' => Product::query()->where('store_id', $storeId)->count(),
                'rawMaterials' => RawMaterial::query()->where('store_id', $storeId)->count(),
                'promos' => Promo::query()->where('store_id', $storeId)->whereDate('masa_aktif', '>=', today())->count(),
                'expenses' => Expense::query()->where('store_id', $storeId)->count(),
                'pendingReturns' => ProductOnhand::query()->where('store_id', $storeId)->where('return_status', 'pending')->count(),
                'pendingSales' => OfflineSale::query()->where('store_id', $storeId)->where('approval_status', 'pending')->count(),
            ] : null,
        ]);
    }

    private function buildDashboardData(User $user, Carbon $monthStart, Carbon $monthEnd, string $salesType = 'all', ?int $storeId = null): array
    {
        $offlineSales = OfflineSale::query()
            ->where('store_id', $storeId)
            ->with(['user', 'product.hppCalculation'])
            ->whereBetween('created_at', [$monthStart, $monthEnd])
            ->where('approval_status', '!=', 'ditolak')
            ->when(in_array($user->role, ['marketing', 'sales_field_executive'], true), fn ($query) => $query->where('id_user', $user->id_user))
            ->get();

        if (in_array($user->role, ['superadmin', 'admin'], true)) {
            $onlineSaleItems = OnlineSaleItem::query()
                ->where('store_id', $storeId)
                ->with(['product.hppCalculation'])
                ->whereBetween('created_at', [$monthStart, $monthEnd])
                ->get();

            return $this->buildManagerDashboardData($offlineSales, $onlineSaleItems, $monthStart, $monthEnd, $salesType);
        }

        return $this->buildSellerDashboardData($user, $offlineSales, $monthStart, $monthEnd);
    }

    private function buildManagerDashboardData(Collection $offlineSales, Collection $onlineSaleItems, Carbon $monthStart, Carbon $monthEnd, string $salesType = 'all'): array
    {
        $includeOffline = in_array($salesType, ['all', 'offline'], true);
        $includeOnline = in_array($salesType, ['all', 'online'], true);
        $filteredOfflineSales = $includeOffline ? $offlineSales : collect();
        $filteredOnlineSaleItems = $includeOnline ? $onlineSaleItems : collect();
        $operationalExpenseTotal = round((float) Expense::query()
            ->where('store_id', $this->currentStoreId(request()))
            ->where('category', 'operasional')
            ->whereBetween('expense_date', [$monthStart->copy()->toDateString(), $monthEnd->copy()->toDateString()])
            ->sum('amount'), 2);
        $wasteLossTotal = round((float) RawMaterial::query()
            ->where('store_id', $this->currentStoreId(request()))
            ->sum('waste_loss_amount'), 2);

        $offlineGross = round((float) $filteredOfflineSales->sum('harga'), 2);
        $onlineGross = round((float) $filteredOnlineSaleItems->sum('harga'), 2);
        $offlineHppTotal = round((float) $filteredOfflineSales->sum(fn ($sale) => $this->hppForSale($sale)), 2);
        $onlineHppTotal = round((float) $filteredOnlineSaleItems->sum(fn ($item) => $this->hppForOnlineItem($item)), 2);
        $offlineGrossProfit = round($offlineGross - $offlineHppTotal, 2);
        $onlineGrossProfit = round($onlineGross - $onlineHppTotal, 2);
        $revenueTotal = round($offlineGross + $onlineGross, 2);
        $grossProfitTotal = round($offlineGrossProfit + $onlineGrossProfit - $wasteLossTotal, 2);
        $netProfitTotal = round($grossProfitTotal - $operationalExpenseTotal, 2);
        $npmBase = round($revenueTotal - $netProfitTotal, 2);
        $npmPercent = $revenueTotal > 0 ? round(($npmBase / $revenueTotal) * 100, 2) : 0;

        $offlineRevenue = $this->filterEmptySeries(
            $this->buildDailySeries($filteredOfflineSales, $monthStart, $monthEnd, fn ($sale) => (float) $sale->harga)
        );
        $offlineNet = $this->filterEmptySeries(
            $this->buildDailySeries($filteredOfflineSales, $monthStart, $monthEnd, fn ($sale) => (float) $sale->harga - $this->hppForSale($sale))
        );
        $onlineRevenue = $this->filterEmptySeries(
            $this->buildDailySeries($filteredOnlineSaleItems, $monthStart, $monthEnd, fn ($item) => (float) $item->harga)
        );
        $onlineNet = $this->filterEmptySeries(
            $this->buildDailySeries($filteredOnlineSaleItems, $monthStart, $monthEnd, fn ($item) => (float) $item->harga - $this->hppForOnlineItem($item))
        );
        $offlineTopProducts = $this->buildTopProducts($filteredOfflineSales);
        $onlineTopProducts = $this->buildTopProducts($filteredOnlineSaleItems, 'nama_product', 'quantity', 'harga');
        $topMarketing = $this->buildTopSellers($filteredOfflineSales, 'marketing');
        $topResellers = $this->buildTopSellers($filteredOfflineSales, 'sales_field_executive');
        $onDutyCount = Attendance::query()
            ->where('store_id', $this->currentStoreId(request()))
            ->whereDate('attendance_date', now()->toDateString())
            ->whereNotNull('check_in')
            ->whereNull('check_out')
            ->whereHas('user', fn ($query) => $query->where('role', 'marketing'))
            ->count();

        return [
            'mode' => 'manager',
            'period_label' => $monthStart->copy()->locale('id')->translatedFormat('F Y'),
            'active_filter_type' => $salesType,
            'kpis' => [
                'marketing_count' => User::query()->where('role', 'marketing')->whereHas('stores', fn ($query) => $query->where('stores.id', $this->currentStoreId(request())))->count(),
                'seller_count' => User::query()->where('role', 'sales_field_executive')->whereHas('stores', fn ($query) => $query->where('stores.id', $this->currentStoreId(request())))->count(),
                'on_duty_marketing' => $onDutyCount,
                'product_sold_total' => (int) $filteredOfflineSales->sum('quantity') + (int) $filteredOnlineSaleItems->sum('quantity'),
                'product_sold_offline' => (int) $filteredOfflineSales->sum('quantity'),
                'product_sold_online' => (int) $filteredOnlineSaleItems->sum('quantity'),
                'gross_profit_offline_total' => $offlineGross,
                'net_profit_offline_total' => $offlineGrossProfit,
                'gross_profit_online_total' => $onlineGross,
                'net_profit_online_total' => $onlineGrossProfit,
                'revenue_total' => $revenueTotal,
                'gross_profit_total' => $grossProfitTotal,
                'net_profit_total' => $netProfitTotal,
                'operational_expense_total' => $operationalExpenseTotal,
                'waste_loss_total' => $wasteLossTotal,
                'npm_base' => $npmBase,
                'npm_percent' => $npmPercent,
            ],
            'gross_profit_offline_chart' => $offlineRevenue,
            'net_profit_offline_chart' => $offlineNet,
            'gross_profit_online_chart' => $onlineRevenue,
            'net_profit_online_chart' => $onlineNet,
            'top_products_offline_chart' => $this->buildPieSeries($offlineTopProducts),
            'top_products_offline_table' => $offlineTopProducts,
            'top_products_online_chart' => $this->buildPieSeries($onlineTopProducts),
            'top_products_online_table' => $onlineTopProducts,
            'top_marketing' => $topMarketing,
            'top_resellers' => $topResellers,
        ];
    }

    private function buildSellerDashboardData(User $user, Collection $sales, Carbon $monthStart, Carbon $monthEnd): array
    {
        $attendanceRecords = Attendance::query()
            ->where('user_id', $user->id_user)
            ->whereBetween('attendance_date', [$monthStart->toDateString(), $monthEnd->toDateString()])
            ->orderBy('attendance_date')
            ->get();

        $attendanceChart = $this->filterEmptySeries($this->buildAttendanceSeries($attendanceRecords, $monthStart, $monthEnd));
        $salesChart = $this->filterEmptySeries($this->buildDailySeries($sales, $monthStart, $monthEnd, fn ($sale) => (float) $sale->harga));
        $hoursChart = $this->filterEmptySeries($this->buildWorkHourSeries($attendanceRecords, $monthStart, $monthEnd));
        $personalRevenue = round((float) $sales->sum('harga'), 2);
        $topProducts = $this->buildTopProducts($sales);
        $target = SalesTarget::query()->firstWhere('role', $user->role);
        $previousMonthStart = $monthStart->copy()->subMonthNoOverflow()->startOfMonth();
        $previousMonthEnd = $monthStart->copy()->subMonthNoOverflow()->endOfMonth();
        $marketingKpi = $user->role === 'marketing'
            ? $this->buildMarketingKpi($user->id_user, $monthStart, $monthEnd)
            : null;

        return [
            'mode' => 'seller',
            'period_label' => $monthStart->copy()->locale('id')->translatedFormat('F Y'),
            'kpis' => [
                'monthly_hours' => round($hoursChart['total'], 2),
                'monthly_revenue' => $personalRevenue,
                'monthly_transactions' => $sales->pluck('transaction_code')->filter()->unique()->count(),
                'attendance_days' => (int) $attendanceRecords->count(),
                'total_kpi' => $marketingKpi['total_score'] ?? null,
            ],
            'attendance_chart' => $attendanceChart,
            'sales_chart' => $salesChart,
            'hours_chart' => $hoursChart,
            'top_products_chart' => $this->buildPieSeries($topProducts),
            'top_products_table' => $topProducts,
            'target_summary' => $this->buildTargetSummary($user, $monthStart, $monthEnd, $target),
            'previous_target_summary' => $this->buildTargetSummary($user, $previousMonthStart, $previousMonthEnd, $target),
            'marketing_kpi' => $marketingKpi,
        ];
    }

    private function buildDailySeries(Collection $rows, Carbon $monthStart, Carbon $monthEnd, callable $resolver): array
    {
        $labels = [];
        $values = [];
        $total = 0.0;

        for ($day = $monthStart->copy(); $day->lte($monthEnd); $day->addDay()) {
            $labels[] = $day->format('d');
            $value = round($rows->filter(fn ($row) => optional($row->created_at)->toDateString() === $day->toDateString())->sum($resolver), 2);
            $values[] = $value;
            $total += $value;
        }

        return [
            'labels' => $labels,
            'values' => $values,
            'total' => round($total, 2),
        ];
    }

    private function buildAttendanceSeries(Collection $attendanceRecords, Carbon $monthStart, Carbon $monthEnd): array
    {
        $labels = [];
        $values = [];
        $total = 0;

        for ($day = $monthStart->copy(); $day->lte($monthEnd); $day->addDay()) {
            $labels[] = $day->format('d');
            $present = $attendanceRecords->contains(fn (Attendance $attendance) => optional($attendance->attendance_date)->toDateString() === $day->toDateString() && $attendance->check_in);
            $values[] = $present ? 1 : 0;
            $total += $present ? 1 : 0;
        }

        return [
            'labels' => $labels,
            'values' => $values,
            'total' => $total,
        ];
    }

    private function buildWorkHourSeries(Collection $attendanceRecords, Carbon $monthStart, Carbon $monthEnd): array
    {
        $labels = [];
        $values = [];
        $total = 0.0;

        for ($day = $monthStart->copy(); $day->lte($monthEnd); $day->addDay()) {
            $labels[] = $day->format('d');
            $attendance = $attendanceRecords->first(fn (Attendance $item) => optional($item->attendance_date)->toDateString() === $day->toDateString());
            $hours = 0.0;

            if ($attendance?->check_in && $attendance?->check_out) {
                $checkIn = Carbon::parse($day->toDateString() . ' ' . $attendance->check_in);
                $checkOut = Carbon::parse($day->toDateString() . ' ' . $attendance->check_out);
                $hours = round(max($checkOut->diffInMinutes($checkIn), 0) / 60, 2);
            }

            $values[] = $hours;
            $total += $hours;
        }

        return [
            'labels' => $labels,
            'values' => $values,
            'total' => round($total, 2),
        ];
    }

    private function buildTopProducts(Collection $rows, string $labelField = 'nama_product', string $quantityField = 'quantity', string $revenueField = 'harga'): array
    {
        return $rows
            ->groupBy(fn ($item) => (string) data_get($item, $labelField))
            ->map(function (Collection $items) use ($labelField, $quantityField, $revenueField) {
                $first = $items->first();

                return [
                    'label' => (string) data_get($first, $labelField),
                    'quantity' => (int) $items->sum($quantityField),
                    'revenue' => round((float) $items->sum($revenueField), 2),
                ];
            })
            ->filter(fn (array $item) => $item['label'] !== '')
            ->sortByDesc('quantity')
            ->take(5)
            ->values()
            ->all();
    }

    private function buildTopSellers(Collection $sales, string $role): array
    {
        return $sales
            ->filter(fn (OfflineSale $sale) => $sale->user?->role === $role)
            ->groupBy('id_user')
            ->map(function (Collection $items) {
                $first = $items->first();

                return [
                    'name' => $first->user?->nama ?? '-',
                    'quantity' => (int) $items->sum('quantity'),
                    'revenue' => round((float) $items->sum('harga'), 2),
                ];
            })
            ->sortByDesc('revenue')
            ->take(10)
            ->values()
            ->all();
    }

    private function buildPieSeries(array $rows): array
    {
        return [
            'labels' => collect($rows)->pluck('label')->all(),
            'values' => collect($rows)->pluck('quantity')->all(),
        ];
    }

    private function filterEmptySeries(array $series): array
    {
        $labels = [];
        $values = [];

        foreach ($series['values'] as $index => $value) {
            if ((float) $value === 0.0) {
                continue;
            }

            $labels[] = $series['labels'][$index] ?? '';
            $values[] = $value;
        }

        return [
            'labels' => $labels,
            'values' => $values,
            'total' => $series['total'],
        ];
    }

    private function hppForSale(OfflineSale $sale): float
    {
        return $this->resolveOfflineUnitHpp($sale) * (int) $sale->quantity;
    }

    private function hppForOnlineItem(OnlineSaleItem $item): float
    {
        $hpp = (float) ($item->product?->hppCalculation?->total_hpp ?? $item->product?->harga_modal ?? 0);
        return $hpp * (int) $item->quantity;
    }

    private function resolveOfflineUnitHpp(OfflineSale $sale): float
    {
        $storedHpp = (float) ($sale->total_hpp ?? 0);
        if ($storedHpp > 0) {
            return $storedHpp;
        }

        return (float) ($sale->product?->hppCalculation?->total_hpp ?? $sale->product?->harga_modal ?? 0);
    }

    private function buildTargetSummary(User $user, Carbon $periodStart, Carbon $periodEnd, ?SalesTarget $target): array
    {
        return MarketingBonusSupport::buildTargetSummary($user, $periodStart, $periodEnd, $target);
    }

    private function buildMarketingKpi(int $userId, Carbon $periodStart, Carbon $periodEnd): array
    {
        $salesQuantity = (int) OfflineSale::query()
            ->where('store_id', $this->currentStoreId(request()))
            ->where('id_user', $userId)
            ->where('approval_status', '!=', 'ditolak')
            ->whereBetween('created_at', [$periodStart->copy()->startOfDay(), $periodEnd->copy()->endOfDay()])
            ->sum('quantity');

        $attendances = Attendance::query()
            ->where('store_id', $this->currentStoreId(request()))
            ->where('user_id', $userId)
            ->whereBetween('attendance_date', [$periodStart->toDateString(), $periodEnd->toDateString()])
            ->whereNotNull('check_in')
            ->get();

        $attendanceDays = $attendances->count();
        $totalHours = round($attendances->sum(function (Attendance $attendance) {
            if (! $attendance->check_in || ! $attendance->check_out) {
                return 0;
            }

            $checkIn = strtotime((string) $attendance->check_in);
            $checkOut = strtotime((string) $attendance->check_out);

            if ($checkIn === false || $checkOut === false) {
                return 0;
            }

            return max(($checkOut - $checkIn) / 3600, 0);
        }), 2);

        $salesTargetRole = StoreFeature::isSmoothiesSweetie(request()) ? 'karyawan' : 'marketing';
        $salesTarget = (int) (SalesTarget::query()->firstWhere('role', $salesTargetRole)?->monthly_target_qty ?? 100);
        $attendanceTarget = 24;
        $hoursTarget = 8;
        $averageHoursPerDay = $attendanceDays > 0 ? round($totalHours / $attendanceDays, 2) : 0.0;
        $salesScore = $salesTarget > 0 ? round(min(($salesQuantity / $salesTarget) * 100, 100) * 0.7, 2) : 0.0;
        $attendanceScore = round(min(($attendanceDays / $attendanceTarget) * 100, 100) * 0.2, 2);
        $hoursScore = round(min(($averageHoursPerDay / $hoursTarget) * 100, 100) * 0.1, 2);

        return [
            'quantity_sold' => $salesQuantity,
            'sales_target' => $salesTarget,
            'attendance_days' => $attendanceDays,
            'attendance_target' => $attendanceTarget,
            'total_hours' => $totalHours,
            'average_hours_per_day' => $averageHoursPerDay,
            'hours_target' => $hoursTarget,
            'sales_score' => $salesScore,
            'attendance_score' => $attendanceScore,
            'hours_score' => $hoursScore,
            'total_score' => round($salesScore + $attendanceScore + $hoursScore, 2),
        ];
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
                'months' => collect(range(1, 12))->map(fn (int $month) => ['value' => $month, 'label' => Carbon::create($selectedYear, $month, 1)->locale('id')->translatedFormat('F')])->all(),
                'years' => collect(range($currentYear - 5, $currentYear + 1))->map(fn (int $year) => ['value' => $year, 'label' => (string) $year])->all(),
            ],
        ];
    }
}







