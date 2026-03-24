<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
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
            $roleHighlights = [
                ['title' => 'CRUD User', 'description' => 'Tambah, edit, dan hapus user langsung dari panel Inertia.'],
                ['title' => 'Kontrol Akses', 'description' => 'Superadmin menjadi satu-satunya role yang bisa mengakses modul user management.'],
            ];
        } elseif ($user->role === 'marketing') {
            $quickActions[] = ['label' => 'Lihat KPI Marketing', 'href' => '/marketing/kpi'];
            $roleHighlights = [
                ['title' => 'KPI Personal', 'description' => 'Pantau absensi, coverage area, dan performa kunjungan area aktif.'],
                ['title' => 'Absensi Area', 'description' => 'Input absensi marketing terhubung langsung dengan area yang dikunjungi.'],
            ];
        } elseif ($user->role === 'admin') {
            $roleHighlights = [
                ['title' => 'Monitoring Operasional', 'description' => 'Gunakan dashboard untuk memantau kondisi user dan distribusi role.'],
                ['title' => 'Akses Terbatas', 'description' => 'Admin tidak memiliki akses CRUD user dan KPI marketing.'],
            ];
        } else {
            $roleHighlights = [
                ['title' => 'Akses Ringkas', 'description' => 'Reseller hanya melihat dashboard utama sesuai izin akses yang tersedia.'],
                ['title' => 'Status Akun', 'description' => 'Pastikan akun aktif untuk menjaga akses ke sistem.'],
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
            'canViewMarketingKpi' => $user->role === 'marketing',
            'roleStats' => Inertia::defer(fn () => User::query()
                ->select('role', DB::raw('COUNT(*) as total'))
                ->groupBy('role')
                ->orderBy('role')
                ->get()
                ->map(fn ($row) => ['role' => $row->role, 'total' => (int) $row->total])
                ->values()),
            'systemInfo' => Inertia::defer(fn () => [
                'database' => config('database.default'),
                'sessionDriver' => config('session.driver'),
                'queue' => config('queue.default'),
                'locale' => config('app.locale'),
            ]),
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
            'marketingSnapshot' => $user->role === 'marketing'
                ? Inertia::defer(fn () => [
                    'attendanceCount' => Attendance::query()->where('user_id', $user->id_user)->count(),
                    'lateCount' => Attendance::query()->where('user_id', $user->id_user)->where('status', 'terlambat')->count(),
                ])
                : null,
        ]);
    }
}