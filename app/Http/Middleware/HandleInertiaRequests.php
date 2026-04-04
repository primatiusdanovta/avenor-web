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
        $navigation = [['label' => 'Dashboard', 'href' => route('dashboard'), 'icon' => 'fas fa-tachometer-alt']];

        if (in_array($user?->role, ['superadmin', 'admin'], true)) {
            $navigation[] = [
                'label' => 'Sales Feature',
                'icon' => 'fas fa-receipt',
                'children' => array_values(array_filter([
                    ['label' => 'Approvals', 'href' => route('approvals.index'), 'icon' => 'far fa-circle nav-icon'],
                    $user?->role === 'superadmin' ? ['label' => 'Target Penjualan', 'href' => route('sales-targets.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                    ['label' => 'Promos', 'href' => route('promos.index'), 'icon' => 'far fa-circle nav-icon'],
                ])),
            ];
            $navigation[] = [
                'label' => 'Stock and Inventory',
                'icon' => 'fas fa-boxes',
                'children' => array_values(array_filter([
                    ['label' => 'Products', 'href' => route('products.index'), 'icon' => 'far fa-circle nav-icon'],
                    $user?->role === 'superadmin' ? ['label' => 'Hpp', 'href' => route('hpp.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                    $user?->role === 'superadmin' ? ['label' => 'Raw Material', 'href' => route('raw-materials.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                ])),
            ];
            $navigation[] = [
                'label' => 'Finance',
                'icon' => 'fas fa-wallet',
                'children' => array_values(array_filter([
                    ['label' => 'Pengeluaran', 'href' => route('expenses.index'), 'icon' => 'far fa-circle nav-icon'],
                    ['label' => 'Penjualan Offline', 'href' => route('offline-sales.index'), 'icon' => 'far fa-circle nav-icon'],
                    $user?->role === 'superadmin' ? ['label' => 'Penjualan Online', 'href' => route('online-sales.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                    ['label' => 'Account Payables', 'href' => route('account-payables.index'), 'icon' => 'far fa-circle nav-icon'],
                ])),
            ];
            $navigation[] = [
                'label' => 'User Management',
                'icon' => 'fas fa-users-cog',
                'children' => array_values(array_filter([
                    $user?->role === 'superadmin' ? ['label' => 'Users', 'href' => route('users.manage'), 'icon' => 'far fa-circle nav-icon'] : null,
                    ['label' => 'Marketing', 'href' => route('marketing.index'), 'icon' => 'far fa-circle nav-icon'],
                    $user?->role === 'superadmin' ? ['label' => 'Bonus Marketing', 'href' => route('marketing.index', ['mode' => 'bonus']), 'icon' => 'far fa-circle nav-icon'] : null,
                    ['label' => 'Customers', 'href' => route('customers.index'), 'icon' => 'far fa-circle nav-icon'],
                    ['label' => 'Content Creator', 'href' => route('content-creators.index'), 'icon' => 'far fa-circle nav-icon'],
                    $user?->role === 'superadmin' ? ['label' => 'Applicant', 'href' => route('applicants.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                    $user?->role === 'superadmin' ? ['label' => 'Article', 'href' => route('articles.manage'), 'icon' => 'far fa-circle nav-icon'] : null,
                ])),
            ];
            if ($user?->role === 'superadmin') {
                $navigation[] = ['label' => 'Landing Page Builder', 'href' => route('landing-page-builder.index'), 'icon' => 'fas fa-gem'];
                $navigation[] = ['label' => 'Global Settings', 'href' => route('global-settings.index'), 'icon' => 'fas fa-sliders-h'];
                $navigation[] = ['label' => 'SEO Manager', 'href' => route('seo-settings.index'), 'icon' => 'fas fa-search'];
                $navigation[] = ['label' => 'Notifications', 'href' => route('notifications.index'), 'icon' => 'fas fa-bell'];
            }
            $navigation[] = ['label' => 'Product Knowledge', 'href' => route('products.knowledge'), 'icon' => 'fas fa-book-open'];
        }

        if ($user?->role === 'marketing') {
            $navigation[] = ['label' => 'Absensi', 'href' => route('marketing.attendance.index'), 'icon' => 'fas fa-user-check'];
            $navigation[] = ['label' => 'Products', 'href' => route('products.index'), 'icon' => 'fas fa-box-open'];
            $navigation[] = ['label' => 'Product Knowledge', 'href' => route('products.knowledge'), 'icon' => 'fas fa-book-open'];
            $navigation[] = ['label' => 'Penjualan Offline', 'href' => route('offline-sales.index'), 'icon' => 'fas fa-shopping-bag'];
        }

        if ($user?->role === 'reseller') {
            $navigation[] = ['label' => 'Products', 'href' => route('products.index'), 'icon' => 'fas fa-box-open'];
            $navigation[] = ['label' => 'Product Knowledge', 'href' => route('products.knowledge'), 'icon' => 'fas fa-book-open'];
            $navigation[] = ['label' => 'Penjualan Offline', 'href' => route('offline-sales.index'), 'icon' => 'fas fa-shopping-bag'];
        }

        return [
            ...parent::share($request),
            'appName' => config('app.name'),
            'adminPrefix' => '/' . trim((string) env('ADMIN_ROUTE_PREFIX', 'administrator'), '/'),
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







