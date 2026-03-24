<?php

namespace App\Http\Middleware;

use Illuminate\Http\Request;
use Inertia\Middleware;

class HandleInertiaRequests extends Middleware
{
    protected $rootView = 'app';

    public function version(Request $request): ?string
    {
        return parent::version($request);
    }

    public function share(Request $request): array
    {
        $user = $request->user();
        $navigation = [['label' => 'Dashboard', 'href' => '/dashboard', 'icon' => 'fas fa-tachometer-alt']];

        if ($user?->role === 'superadmin') {
            $navigation[] = ['label' => 'User Management', 'href' => '/users', 'icon' => 'fas fa-users-cog'];
            $navigation[] = ['label' => 'Marketing', 'href' => '/marketing', 'icon' => 'fas fa-map-marker-alt'];
            $navigation[] = ['label' => 'Approvals', 'href' => '/approvals', 'icon' => 'fas fa-clipboard-check'];
            $navigation[] = ['label' => 'Products', 'href' => '/products', 'icon' => 'fas fa-boxes'];
            $navigation[] = ['label' => 'Promos', 'href' => '/promos', 'icon' => 'fas fa-tags'];
            $navigation[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales', 'icon' => 'fas fa-cash-register'];
        }

        if ($user?->role === 'admin') {
            $navigation[] = ['label' => 'Marketing', 'href' => '/marketing', 'icon' => 'fas fa-map-marker-alt'];
            $navigation[] = ['label' => 'Approvals', 'href' => '/approvals', 'icon' => 'fas fa-clipboard-check'];
            $navigation[] = ['label' => 'Products', 'href' => '/products', 'icon' => 'fas fa-boxes'];
            $navigation[] = ['label' => 'Promos', 'href' => '/promos', 'icon' => 'fas fa-tags'];
            $navigation[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales', 'icon' => 'fas fa-cash-register'];
        }

        if ($user?->role === 'marketing') {
            $navigation[] = ['label' => 'Absensi', 'href' => '/marketing/attendance', 'icon' => 'fas fa-user-check'];
            $navigation[] = ['label' => 'Products', 'href' => '/products', 'icon' => 'fas fa-box-open'];
            $navigation[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales', 'icon' => 'fas fa-shopping-bag'];
        }

        if ($user?->role === 'reseller') {
            $navigation[] = ['label' => 'Products', 'href' => '/products', 'icon' => 'fas fa-box-open'];
            $navigation[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales', 'icon' => 'fas fa-shopping-bag'];
        }

        return [
            ...parent::share($request),
            'appName' => config('app.name'),
            'navigation' => $navigation,
            'auth' => [
                'user' => $user ? [
                    'id_user' => $user->id_user,
                    'nama' => $user->nama,
                    'role' => $user->role,
                    'status' => $user->status,
                ] : null,
            ],
            'flash' => [
                'success' => fn () => $request->session()->get('success'),
            ],
        ];
    }
}
