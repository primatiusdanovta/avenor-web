<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\OfflineSale;
use App\Models\Product;
use App\Models\ProductOnhand;
use App\Models\Promo;
use App\Models\RawMaterial;
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
            $roleHighlights = [
                ['title' => 'Kontrol Master Data', 'description' => 'Superadmin mengelola user, raw material, HPP product, promo, penjualan offline, serta approval pengambilan dan pengembalian barang.'],
                ['title' => 'Monitoring Marketing', 'description' => 'Pantau performa penjualan, profit, kehadiran, dan aktivitas on duty marketing secara real-time.'],
            ];
        } elseif ($user->role === 'marketing') {
            $quickActions[] = ['label' => 'Absensi', 'href' => '/marketing/attendance'];
            $quickActions[] = ['label' => 'Products', 'href' => '/products'];
            $quickActions[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales'];
            $roleHighlights = [
                ['title' => 'Absensi Otomatis', 'description' => 'Jam check in/check out dan lokasi terekam otomatis setiap kali absensi dijalankan.'],
                ['title' => 'Monitoring Performa', 'description' => 'Dashboard menampilkan akumulasi jam kerja, penjualan bulanan, dan produk terlaris Anda.'],
            ];
        } elseif ($user->role === 'admin') {
            $quickActions[] = ['label' => 'Monitoring Marketing', 'href' => '/marketing'];
            $quickActions[] = ['label' => 'Approvals', 'href' => '/approvals'];
            $quickActions[] = ['label' => 'Products', 'href' => '/products'];
            $quickActions[] = ['label' => 'Promos', 'href' => '/promos'];
            $quickActions[] = ['label' => 'Pelanggan', 'href' => '/customers'];
            $quickActions[] = ['label' => 'Content Creator', 'href' => '/content-creators'];
            $quickActions[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales'];
            $roleHighlights = [
                ['title' => 'Approval Operasional', 'description' => 'Admin menyetujui penjualan offline, pengambilan barang, dan pengembalian barang dari marketing dan reseller.'],
                ['title' => 'Profit Dashboard', 'description' => 'Admin melihat gross profit, net profit, ranking penjualan, serta produk terlaris bulan berjalan.'],
            ];
        } else {
            $quickActions[] = ['label' => 'Products', 'href' => '/products'];
            $quickActions[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales'];
            $roleHighlights = [
                ['title' => 'Stock On Hand', 'description' => 'Reseller melihat barang yang dibawa, menginput penjualan, dan mengirim request pengembalian jika ada sisa.'],
                ['title' => 'Ringkasan Performa', 'description' => 'Dashboard menampilkan akumulasi jam kerja bulanan, grafik penjualan, dan produk terlaris Anda.'],
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
            'dashboardData' => $this->buildDashboardData($user),
            'inventorySummary' => [
                'products' => Product::count(),
                'rawMaterials' => RawMaterial::count(),
                'promos' => Promo::query()->whereDate('masa_aktif', '>=', today())->count(),
                'pendingReturns' => ProductOnhand::query()->where('return_status', 'pending')->count(),
                'pendingSales' => OfflineSale::query()->where('approval_status', 'pending')->count(),
            ],
        ]);
    }

    private function buildDashboardData(User $user): array
    {
        $monthStart = now()->startOfMonth();
        $monthEnd = now()->endOfMonth();
        $salesQuery = OfflineSale::query()
            ->with(['user', 'product'])
            ->whereBetween('created_at', [$monthStart, $monthEnd])
            ->where('approval_status', '!=', 'ditolak');

        if (in_array($user->role, ['marketing', 'reseller'], true)) {
            $salesQuery->where('id_user', $user->id_user);
        }

        $sales = $salesQuery->get();

        return in_array($user->role, ['superadmin', 'admin'], true)
            ? $this->buildManagerDashboardData($sales, $monthStart, $monthEnd)
            : $this->buildSellerDashboardData($user, $sales, $monthStart, $monthEnd);
    }

    private function buildManagerDashboardData(Collection $sales, Carbon $monthStart, Carbon $monthEnd): array
    {
        $dailyRevenue = $this->filterEmptySeries(
            $this->buildDailySeries($sales, $monthStart, $monthEnd, fn (OfflineSale $sale) => (float) $sale->harga)
        );
        $dailyNet = $this->filterEmptySeries(
            $this->buildDailySeries($sales, $monthStart, $monthEnd, fn (OfflineSale $sale) => (float) $sale->harga - ((float) ($sale->product?->harga_modal ?? 0) * (int) $sale->quantity))
        );
        $topProducts = $this->buildTopProducts($sales);
        $topMarketing = $this->buildTopSellers($sales, 'marketing');
        $topResellers = $this->buildTopSellers($sales, 'reseller');
        $onDutyCount = Attendance::query()
            ->whereDate('attendance_date', now()->toDateString())
            ->whereNotNull('check_in')
            ->whereNull('check_out')
            ->whereHas('user', fn ($query) => $query->where('role', 'marketing'))
            ->count();

        return [
            'mode' => 'manager',
            'kpis' => [
                'marketing_count' => User::query()->where('role', 'marketing')->count(),
                'seller_count' => User::query()->where('role', 'reseller')->count(),
                'on_duty_marketing' => $onDutyCount,
                'gross_profit_total' => round($dailyRevenue['total'], 2),
                'net_profit_total' => round($dailyNet['total'], 2),
            ],
            'gross_profit_chart' => $dailyRevenue,
            'net_profit_chart' => $dailyNet,
            'top_products_chart' => $this->buildPieSeries($topProducts),
            'top_products_table' => $topProducts,
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

        $attendanceChart = $this->buildAttendanceSeries($attendanceRecords, $monthStart, $monthEnd);
        $salesChart = $this->buildDailySeries($sales, $monthStart, $monthEnd, fn (OfflineSale $sale) => (float) $sale->harga);
        $hoursChart = $this->buildWorkHourSeries($attendanceRecords, $monthStart, $monthEnd);
        $topProducts = $this->buildTopProducts($sales);

        return [
            'mode' => 'seller',
            'kpis' => [
                'monthly_hours' => round($hoursChart['total'], 2),
                'monthly_revenue' => round($salesChart['total'], 2),
                'monthly_transactions' => $sales->pluck('transaction_code')->filter()->unique()->count(),
                'attendance_days' => (int) $attendanceRecords->count(),
            ],
            'attendance_chart' => $attendanceChart,
            'sales_chart' => $salesChart,
            'hours_chart' => $hoursChart,
            'top_products_chart' => $this->buildPieSeries($topProducts),
            'top_products_table' => $topProducts,
        ];
    }

    private function buildDailySeries(Collection $sales, Carbon $monthStart, Carbon $monthEnd, callable $resolver): array
    {
        $labels = [];
        $values = [];
        $total = 0.0;

        for ($day = $monthStart->copy(); $day->lte($monthEnd); $day->addDay()) {
            $labels[] = $day->format('d');
            $value = round($sales->filter(fn (OfflineSale $sale) => optional($sale->created_at)->toDateString() === $day->toDateString())->sum($resolver), 2);
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

    private function buildTopProducts(Collection $sales): array
    {
        return $sales
            ->groupBy('id_product')
            ->map(function (Collection $items) {
                /** @var OfflineSale $first */
                $first = $items->first();

                return [
                    'label' => $first->nama_product,
                    'quantity' => (int) $items->sum('quantity'),
                    'revenue' => round((float) $items->sum('harga'), 2),
                ];
            })
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
                /** @var OfflineSale $first */
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
}

