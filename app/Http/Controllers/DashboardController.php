<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\MarketingLocation;
use App\Models\OfflineSale;
use App\Models\Product;
use App\Models\ProductOnhand;
use App\Models\Promo;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
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
            $quickActions[] = ['label' => 'Products', 'href' => '/products'];
            $quickActions[] = ['label' => 'Promos', 'href' => '/promos'];
            $quickActions[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales'];
            $roleHighlights = [
                ['title' => 'Kontrol Master Data', 'description' => 'Superadmin mengelola user, product, promo, penjualan offline, serta approval pengambilan dan pengembalian barang.'],
                ['title' => 'Monitoring Marketing', 'description' => 'Lihat lokasi terakhir, absensi hari ini, barang yang dibawa, dan status pengembalian marketing.'],
            ];
        } elseif ($user->role === 'marketing') {
            $quickActions[] = ['label' => 'Absensi', 'href' => '/marketing/attendance'];
            $quickActions[] = ['label' => 'Products', 'href' => '/products'];
            $quickActions[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales'];
            $roleHighlights = [
                ['title' => 'Absensi Otomatis', 'description' => 'Tanggal, jam check in/check out, dan koordinat lokasi diambil otomatis saat tombol dijalankan.'],
                ['title' => 'Barang On Hand', 'description' => 'Marketing dapat mengambil barang setelah check in, input penjualan, dan request pengembalian sebelum checkout.'],
            ];
        } elseif ($user->role === 'admin') {
            $quickActions[] = ['label' => 'Monitoring Marketing', 'href' => '/marketing'];
            $quickActions[] = ['label' => 'Approvals', 'href' => '/approvals'];
            $quickActions[] = ['label' => 'Products', 'href' => '/products'];
            $quickActions[] = ['label' => 'Promos', 'href' => '/promos'];
            $quickActions[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales'];
            $roleHighlights = [
                ['title' => 'Approval Operasional', 'description' => 'Admin menyetujui penjualan offline, pengambilan barang, dan pengembalian barang dari marketing/reseller.'],
                ['title' => 'Master Data', 'description' => 'Admin mengelola product, promo, dan akun marketing.'],
            ];
        } else {
            $quickActions[] = ['label' => 'Products', 'href' => '/products'];
            $quickActions[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales'];
            $roleHighlights = [
                ['title' => 'Stock On Hand', 'description' => 'Reseller melihat barang yang dibawa, menginput penjualan, dan mengirim request pengembalian jika ada sisa.'],
                ['title' => 'Akses Ringkas', 'description' => 'Reseller hanya melihat data miliknya sendiri untuk product dan penjualan offline.'],
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
            'canViewUsers' => $user->role === 'superadmin',
            'canManageMarketing' => in_array($user->role, ['superadmin', 'admin'], true),
            'canViewMarketingAttendance' => $user->role === 'marketing',
            'roleStats' => Inertia::defer(fn () => User::query()
                ->select('role', DB::raw('COUNT(*) as total'))
                ->groupBy('role')
                ->orderBy('role')
                ->get()
                ->map(fn ($row) => ['role' => $row->role, 'total' => (int) $row->total])
                ->values()),
            'recentUsers' => Inertia::optional(fn () => User::query()
                ->latest('created_at')
                ->limit(6)
                ->get(['id_user', 'nama', 'status', 'role', 'created_at'])
                ->map(fn (User $item) => [
                    'id_user' => $item->id_user,
                    'nama' => $item->nama,
                    'status' => $item->status,
                    'role' => $item->role,
                    'created_at' => optional($item->created_at)->format('Y-m-d H:i:s'),
                ])
                ->values()),
            'marketingSnapshot' => in_array($user->role, ['superadmin', 'admin'], true)
                ? Inertia::defer(fn () => [
                    'totalMarketing' => User::query()->where('role', 'marketing')->count(),
                    'activeToday' => Attendance::query()->whereDate('attendance_date', now()->toDateString())->count(),
                    'latestPing' => optional(MarketingLocation::query()->latest('recorded_at')->first()?->recorded_at)->format('Y-m-d H:i:s'),
                    'todayCarriedItems' => ProductOnhand::query()->whereDate('assignment_date', now()->toDateString())->count(),
                    'pendingSales' => OfflineSale::query()->where('approval_status', 'pending')->count(),
                ])
                : null,
            'inventorySummary' => Inertia::defer(fn () => [
                'products' => Product::count(),
                'promos' => Promo::query()->whereDate('masa_aktif', '>=', today())->count(),
                'pendingReturns' => ProductOnhand::query()->where('return_status', 'pending')->count(),
                'pendingSales' => OfflineSale::query()->where('approval_status', 'pending')->count(),
            ]),
        ]);
    }
}
