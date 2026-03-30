<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\OfflineSale;
use App\Models\OnlineSaleItem;
use App\Models\Product;
use App\Models\ProductOnhand;
use App\Models\Promo;
use App\Models\RawMaterial;
use App\Models\SalesTarget;
use App\Models\User;
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
        [$monthStart, $monthEnd, $dashboardFilters] = $this->resolveDashboardPeriod($request);
        $quickActions = [['label' => 'Reload Dashboard', 'href' => '/dashboard']];
        $roleHighlights = [];

        if ($user->role === 'superadmin') {
            $quickActions[] = ['label' => 'Kelola User', 'href' => '/users'];
            $quickActions[] = ['label' => 'Monitoring Marketing', 'href' => '/marketing'];
            $quickActions[] = ['label' => 'Approvals', 'href' => '/approvals'];
            $quickActions[] = ['label' => 'Raw Material', 'href' => '/raw-materials'];
            $quickActions[] = ['label' => 'HPP', 'href' => '/hpp'];
            $quickActions[] = ['label' => 'Products', 'href' => '/products'];
            $quickActions[] = ['label' => 'Promos', 'href' => '/promos'];
            $quickActions[] = ['label' => 'Pelanggan', 'href' => '/customers'];
            $quickActions[] = ['label' => 'Content Creator', 'href' => '/content-creators'];
            $quickActions[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales'];
            $quickActions[] = ['label' => 'Penjualan Online', 'href' => '/online-sales'];
            $quickActions[] = ['label' => 'Target Penjualan', 'href' => '/sales-targets'];
            $quickActions[] = ['label' => 'Report', 'href' => '/reports'];
            $roleHighlights = [
                ['title' => 'Kontrol Master Data', 'description' => 'Superadmin mengelola user, raw material, HPP product, promo, penjualan offline, penjualan online, target penjualan, report, serta approval pengambilan dan pengembalian barang.'],
                ['title' => 'Monitoring Marketing', 'description' => 'Pantau performa penjualan, profit, kehadiran, dan aktivitas on duty marketing secara real-time.'],
            ];
        } elseif ($user->role === 'marketing') {
            $quickActions[] = ['label' => 'Absensi', 'href' => '/marketing/attendance'];
            $quickActions[] = ['label' => 'Products', 'href' => '/products'];
            $quickActions[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales'];
            $roleHighlights = [
                ['title' => 'Absensi Otomatis', 'description' => 'Jam check in/check out dan lokasi terekam otomatis setiap kali absensi dijalankan.'],
                ['title' => 'Monitoring Performa', 'description' => 'Dashboard menampilkan target penjualan, bonus berjalan, jam kerja, dan produk terlaris Anda.'],
            ];
        } elseif ($user->role === 'admin') {
            $quickActions[] = ['label' => 'Monitoring Marketing', 'href' => '/marketing'];
            $quickActions[] = ['label' => 'Approvals', 'href' => '/approvals'];
            $quickActions[] = ['label' => 'Products', 'href' => '/products'];
            $quickActions[] = ['label' => 'Promos', 'href' => '/promos'];
            $quickActions[] = ['label' => 'Pelanggan', 'href' => '/customers'];
            $quickActions[] = ['label' => 'Content Creator', 'href' => '/content-creators'];
            $quickActions[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales'];
            $quickActions[] = ['label' => 'Report', 'href' => '/reports'];
            $roleHighlights = [
                ['title' => 'Approval Operasional', 'description' => 'Admin menyetujui penjualan offline, pengambilan barang, dan pengembalian barang dari marketing dan reseller.'],
                ['title' => 'Profit Dashboard', 'description' => 'Admin melihat gross profit, net profit, ranking penjualan, serta produk terlaris bulan berjalan.'],
            ];
        } else {
            $quickActions[] = ['label' => 'Products', 'href' => '/products'];
            $quickActions[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales'];
            $roleHighlights = [
                ['title' => 'Stock On Hand', 'description' => 'Reseller melihat barang yang dibawa, menginput penjualan, dan mengirim request pengembalian jika ada sisa.'],
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
            'dashboardData' => $this->buildDashboardData($user, $monthStart, $monthEnd),
            'inventorySummary' => $user->role === 'superadmin' ? [
                'products' => Product::count(),
                'rawMaterials' => RawMaterial::count(),
                'promos' => Promo::query()->whereDate('masa_aktif', '>=', today())->count(),
                'pendingReturns' => ProductOnhand::query()->where('return_status', 'pending')->count(),
                'pendingSales' => OfflineSale::query()->where('approval_status', 'pending')->count(),
            ] : null,
        ]);
    }

    private function buildDashboardData(User $user, Carbon $monthStart, Carbon $monthEnd): array
    {
        $offlineSales = OfflineSale::query()
            ->with(['user', 'product.hppCalculation'])
            ->whereBetween('created_at', [$monthStart, $monthEnd])
            ->where('approval_status', '!=', 'ditolak')
            ->when(in_array($user->role, ['marketing', 'reseller'], true), fn ($query) => $query->where('id_user', $user->id_user))
            ->get();

        if (in_array($user->role, ['superadmin', 'admin'], true)) {
            $onlineSaleItems = OnlineSaleItem::query()
                ->with(['product.hppCalculation'])
                ->whereBetween('created_at', [$monthStart, $monthEnd])
                ->get();

            return $this->buildManagerDashboardData($offlineSales, $onlineSaleItems, $monthStart, $monthEnd);
        }

        return $this->buildSellerDashboardData($user, $offlineSales, $monthStart, $monthEnd);
    }

    private function buildManagerDashboardData(Collection $offlineSales, Collection $onlineSaleItems, Carbon $monthStart, Carbon $monthEnd): array
    {
        $offlineGross = round((float) $offlineSales->sum('harga'), 2);
        $offlineNetTotal = round((float) $offlineSales->sum(fn ($sale) => $this->netProfitForSale($sale)), 2);
        $onlineGross = round((float) $onlineSaleItems->sum('harga'), 2);
        $onlineNetTotal = round((float) $onlineSaleItems->sum(fn ($item) => $this->netProfitForOnlineItem($item)), 2);
        $revenueTotal = round($offlineGross + $onlineGross, 2);
        $netProfitTotal = round($offlineNetTotal + $onlineNetTotal, 2);
        $npmBase = round($revenueTotal - $netProfitTotal, 2);
        $npmPercent = $revenueTotal > 0 ? round(($npmBase / $revenueTotal) * 100, 2) : 0;

        $offlineRevenue = $this->filterEmptySeries(
            $this->buildDailySeries($offlineSales, $monthStart, $monthEnd, fn ($sale) => (float) $sale->harga)
        );
        $offlineNet = $this->filterEmptySeries(
            $this->buildDailySeries($offlineSales, $monthStart, $monthEnd, fn ($sale) => $this->netProfitForSale($sale))
        );
        $onlineRevenue = $this->filterEmptySeries(
            $this->buildDailySeries($onlineSaleItems, $monthStart, $monthEnd, fn ($item) => (float) $item->harga)
        );
        $onlineNet = $this->filterEmptySeries(
            $this->buildDailySeries($onlineSaleItems, $monthStart, $monthEnd, fn ($item) => $this->netProfitForOnlineItem($item))
        );
        $offlineTopProducts = $this->buildTopProducts($offlineSales);
        $onlineTopProducts = $this->buildTopProducts($onlineSaleItems, 'nama_product', 'quantity', 'harga');
        $topMarketing = $this->buildTopSellers($offlineSales, 'marketing');
        $topResellers = $this->buildTopSellers($offlineSales, 'reseller');
        $onDutyCount = Attendance::query()
            ->whereDate('attendance_date', now()->toDateString())
            ->whereNotNull('check_in')
            ->whereNull('check_out')
            ->whereHas('user', fn ($query) => $query->where('role', 'marketing'))
            ->count();

        return [
            'mode' => 'manager',
            'period_label' => $monthStart->copy()->locale('id')->translatedFormat('F Y'),
            'kpis' => [
                'marketing_count' => User::query()->where('role', 'marketing')->count(),
                'seller_count' => User::query()->where('role', 'reseller')->count(),
                'on_duty_marketing' => $onDutyCount,
                'product_sold_total' => (int) $offlineSales->sum('quantity') + (int) $onlineSaleItems->sum('quantity'),
                'product_sold_offline' => (int) $offlineSales->sum('quantity'),
                'product_sold_online' => (int) $onlineSaleItems->sum('quantity'),
                'gross_profit_offline_total' => $offlineGross,
                'net_profit_offline_total' => $offlineNetTotal,
                'gross_profit_online_total' => $onlineGross,
                'net_profit_online_total' => $onlineNetTotal,
                'revenue_total' => $revenueTotal,
                'net_profit_total' => $netProfitTotal,
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

    private function netProfitForSale(OfflineSale $sale): float
    {
        $hpp = (float) ($sale->product?->hppCalculation?->total_hpp ?? $sale->product?->harga_modal ?? 0);
        return (float) $sale->harga - ($hpp * (int) $sale->quantity);
    }

    private function netProfitForOnlineItem(OnlineSaleItem $item): float
    {
        $hpp = (float) ($item->product?->hppCalculation?->total_hpp ?? $item->product?->harga_modal ?? 0);
        return (float) $item->harga - ($hpp * (int) $item->quantity);
    }

    private function buildTargetSummary(User $user, Carbon $periodStart, Carbon $periodEnd, ?SalesTarget $target): array
    {
        $today = now()->startOfDay();
        $effectiveEnd = $periodEnd->copy()->startOfDay()->gt($today) ? $today->copy() : $periodEnd->copy()->startOfDay();

        $sales = OfflineSale::query()
            ->where('id_user', $user->id_user)
            ->where('approval_status', '!=', 'ditolak')
            ->whereBetween('created_at', [$periodStart->copy()->startOfDay(), $effectiveEnd->copy()->endOfDay()])
            ->get();

        $dailyTargetQty = (int) ($target?->daily_target_qty ?? 0);
        $weeklyTargetQty = (int) ($target?->weekly_target_qty ?? 0);
        $monthlyTargetQty = (int) ($target?->monthly_target_qty ?? 0);
        $dailyBonus = (float) ($target?->daily_bonus ?? 0);
        $weeklyBonus = (float) ($target?->weekly_bonus ?? 0);
        $monthlyBonus = (float) ($target?->monthly_bonus ?? 0);

        $dailyTotals = $sales->groupBy(fn (OfflineSale $sale) => optional($sale->created_at)->toDateString())->map(fn (Collection $items) => (int) $items->sum('quantity'));
        $periodDayCount = $periodStart->copy()->startOfDay()->gt($effectiveEnd) ? 0 : $periodStart->copy()->startOfDay()->diffInDays($effectiveEnd) + 1;
        $dailyAchievedCount = $dailyTargetQty > 0 ? $dailyTotals->filter(fn (int $quantity) => $quantity >= $dailyTargetQty)->count() : 0;

        $weeklyPeriods = $this->buildWeeklyPeriods($periodStart, $effectiveEnd);
        $weeklyAchievedCount = 0;

        foreach ($weeklyPeriods as $period) {
            $weekQuantity = (int) $sales->filter(fn (OfflineSale $sale) => optional($sale->created_at)?->betweenIncluded($period['start'], $period['end']))->sum('quantity');
            if ($weeklyTargetQty > 0 && $weekQuantity >= $weeklyTargetQty) {
                $weeklyAchievedCount++;
            }
        }

        $monthlyQuantity = (int) $sales->sum('quantity');
        $monthlyMet = $monthlyTargetQty > 0 && $monthlyQuantity >= $monthlyTargetQty;
        $todayQuantity = (int) ($dailyTotals[now()->toDateString()] ?? 0);
        $isCurrentMonth = $periodStart->isSameMonth(now()) && $periodStart->isSameYear(now());
        $bonusTotal = ($dailyAchievedCount * $dailyBonus) + ($weeklyAchievedCount * $weeklyBonus) + ($monthlyMet ? $monthlyBonus : 0);

        return [
            'period_label' => $periodStart->copy()->locale('id')->translatedFormat('F Y'),
            'daily' => ['target_qty' => $dailyTargetQty, 'achieved_count' => $dailyAchievedCount, 'total_periods' => $periodDayCount, 'bonus' => round($dailyAchievedCount * $dailyBonus, 2)],
            'weekly' => ['target_qty' => $weeklyTargetQty, 'achieved_count' => $weeklyAchievedCount, 'total_periods' => count($weeklyPeriods), 'bonus' => round($weeklyAchievedCount * $weeklyBonus, 2)],
            'monthly' => ['target_qty' => $monthlyTargetQty, 'total_quantity' => $monthlyQuantity, 'met' => $monthlyMet, 'bonus' => $monthlyMet ? round($monthlyBonus, 2) : 0],
            'bonus_total' => round($bonusTotal, 2),
            'reminder' => $isCurrentMonth && $dailyTargetQty > 0 && $todayQuantity < $dailyTargetQty ? sprintf('Target anda %d/%d, Penuhi Target anda hari ini!', $todayQuantity, $dailyTargetQty) : null,
        ];
    }

    private function buildWeeklyPeriods(Carbon $periodStart, Carbon $periodEnd): array
    {
        if ($periodStart->copy()->startOfDay()->gt($periodEnd->copy()->startOfDay())) {
            return [];
        }

        $periods = [];
        $cursor = $periodStart->copy()->startOfDay();

        while ($cursor->lte($periodEnd)) {
            $weekEnd = $cursor->copy()->endOfWeek(Carbon::SUNDAY);
            if ($weekEnd->gt($periodEnd)) {
                $weekEnd = $periodEnd->copy()->endOfDay();
            }

            $periods[] = ['start' => $cursor->copy()->startOfDay(), 'end' => $weekEnd->copy()->endOfDay()];
            $cursor = $weekEnd->copy()->addDay()->startOfDay();
        }

        return $periods;
    }

    private function buildMarketingKpi(int $userId, Carbon $periodStart, Carbon $periodEnd): array
    {
        $salesQuantity = (int) OfflineSale::query()
            ->where('id_user', $userId)
            ->where('approval_status', '!=', 'ditolak')
            ->whereBetween('created_at', [$periodStart->copy()->startOfDay(), $periodEnd->copy()->endOfDay()])
            ->sum('quantity');

        $attendances = Attendance::query()
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

        $salesTarget = (int) (SalesTarget::query()->firstWhere('role', 'marketing')?->monthly_target_qty ?? 100);
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
            'month' => ['nullable', 'integer', 'between:1,12'],
            'year' => ['nullable', 'integer', 'between:2020,2100'],
        ]);

        $selectedMonth = (int) ($validated['month'] ?? now()->month);
        $selectedYear = (int) ($validated['year'] ?? now()->year);
        $monthStart = Carbon::create($selectedYear, $selectedMonth, 1)->startOfMonth();
        $monthEnd = $monthStart->copy()->endOfMonth();
        $currentYear = now()->year;

        return [
            $monthStart,
            $monthEnd,
            [
                'month' => $selectedMonth,
                'year' => $selectedYear,
                'period_label' => $monthStart->copy()->locale('id')->translatedFormat('F Y'),
                'months' => collect(range(1, 12))->map(fn (int $month) => ['value' => $month, 'label' => Carbon::create($selectedYear, $month, 1)->locale('id')->translatedFormat('F')])->all(),
                'years' => collect(range($currentYear - 5, $currentYear + 1))->map(fn (int $year) => ['value' => $year, 'label' => (string) $year])->all(),
            ],
        ];
    }
}







