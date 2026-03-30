<?php

namespace App\Http\Middleware;

use App\Models\Product;
use App\Models\RawMaterial;
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
            $navigation[] = ['label' => 'Raw Material', 'href' => '/raw-materials', 'icon' => 'fas fa-industry'];
            $navigation[] = ['label' => 'HPP', 'href' => '/hpp', 'icon' => 'fas fa-calculator'];
            $navigation[] = ['label' => 'Products', 'href' => '/products', 'icon' => 'fas fa-boxes'];
            $navigation[] = ['label' => 'Product Knowledge', 'href' => '/product-knowledge', 'icon' => 'fas fa-book-open'];
            $navigation[] = ['label' => 'Promos', 'href' => '/promos', 'icon' => 'fas fa-tags'];
            $navigation[] = ['label' => 'Pelanggan', 'href' => '/customers', 'icon' => 'fas fa-address-book'];
            $navigation[] = ['label' => 'Content Creator', 'href' => '/content-creators', 'icon' => 'fas fa-photo-video'];
            $navigation[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales', 'icon' => 'fas fa-cash-register'];
            $navigation[] = ['label' => 'Penjualan Online', 'href' => '/online-sales', 'icon' => 'fas fa-file-import'];
            $navigation[] = ['label' => 'Target Penjualan', 'href' => '/sales-targets', 'icon' => 'fas fa-bullseye'];
            $navigation[] = ['label' => 'Report', 'href' => '/reports', 'icon' => 'fas fa-chart-line'];
        }

        if ($user?->role === 'admin') {
            $navigation[] = ['label' => 'Marketing', 'href' => '/marketing', 'icon' => 'fas fa-map-marker-alt'];
            $navigation[] = ['label' => 'Approvals', 'href' => '/approvals', 'icon' => 'fas fa-clipboard-check'];
            $navigation[] = ['label' => 'Products', 'href' => '/products', 'icon' => 'fas fa-boxes'];
            $navigation[] = ['label' => 'Product Knowledge', 'href' => '/product-knowledge', 'icon' => 'fas fa-book-open'];
            $navigation[] = ['label' => 'Promos', 'href' => '/promos', 'icon' => 'fas fa-tags'];
            $navigation[] = ['label' => 'Pelanggan', 'href' => '/customers', 'icon' => 'fas fa-address-book'];
            $navigation[] = ['label' => 'Content Creator', 'href' => '/content-creators', 'icon' => 'fas fa-photo-video'];
            $navigation[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales', 'icon' => 'fas fa-cash-register'];
            $navigation[] = ['label' => 'Report', 'href' => '/reports', 'icon' => 'fas fa-chart-line'];
        }

        if ($user?->role === 'marketing') {
            $navigation[] = ['label' => 'Absensi', 'href' => '/marketing/attendance', 'icon' => 'fas fa-user-check'];
            $navigation[] = ['label' => 'Products', 'href' => '/products', 'icon' => 'fas fa-box-open'];
            $navigation[] = ['label' => 'Product Knowledge', 'href' => '/product-knowledge', 'icon' => 'fas fa-book-open'];
            $navigation[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales', 'icon' => 'fas fa-shopping-bag'];
        }

        if ($user?->role === 'reseller') {
            $navigation[] = ['label' => 'Products', 'href' => '/products', 'icon' => 'fas fa-box-open'];
            $navigation[] = ['label' => 'Product Knowledge', 'href' => '/product-knowledge', 'icon' => 'fas fa-book-open'];
            $navigation[] = ['label' => 'Penjualan Offline', 'href' => '/offline-sales', 'icon' => 'fas fa-shopping-bag'];
        }

        return [
            ...parent::share($request),
            'appName' => config('app.name'),
            'navigation' => $navigation,
            'inventoryAlerts' => in_array($user?->role, ['superadmin', 'admin'], true) ? [
                'products' => Product::query()
                    ->where('stock', '<', 20)
                    ->orderBy('stock')
                    ->orderBy('nama_product')
                    ->get(['id_product', 'nama_product', 'stock'])
                    ->map(fn (Product $product) => [
                        'id' => $product->id_product,
                        'name' => $product->nama_product,
                        'value' => (int) $product->stock,
                        'unit' => 'pcs',
                    ])
                    ->values(),
                'rawMaterials' => RawMaterial::query()
                    ->where('total_quantity', '<', 200)
                    ->orderBy('total_quantity')
                    ->orderBy('nama_rm')
                    ->get(['id_rm', 'nama_rm', 'total_quantity', 'satuan'])
                    ->map(fn (RawMaterial $material) => [
                        'id' => $material->id_rm,
                        'name' => $material->nama_rm,
                        'value' => (float) $material->total_quantity,
                        'unit' => $material->satuan,
                    ])
                    ->values(),
            ] : null,
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
                'warning' => fn () => $request->session()->get('warning'),
                'error' => fn () => $request->session()->get('error'),
            ],
        ];
    }
}

