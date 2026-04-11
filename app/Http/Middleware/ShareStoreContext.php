<?php

namespace App\Http\Middleware;

use App\Models\Attendance;
use App\Models\Customer;
use App\Models\Expense;
use App\Models\MarketingNotification;
use App\Models\PermissionRole;
use App\Models\Product;
use App\Models\RawMaterial;
use App\Models\User;
use App\Support\PermissionCatalog;
use App\Support\SalesRole;
use App\Support\StoreContext;
use App\Support\StoreFeature;
use Closure;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Symfony\Component\HttpFoundation\Response;

class ShareStoreContext
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        $currentStore = StoreContext::currentStore($request);
        $currentStoreId = $currentStore?->id;
        $stores = StoreContext::storesForUser($user);
        $isSmoothiesSweetie = StoreFeature::isSmoothiesSweetie($currentStore);

        Inertia::share([
            'navigation' => $this->navigation($user),
            'stores' => [
                'current' => $currentStore ? [
                    'id' => $currentStore->id,
                    'code' => $currentStore->code,
                    'name' => $currentStore->name,
                    'display_name' => $currentStore->display_name,
                    'settings' => $currentStore->settings ?? [],
                ] : null,
                'available' => $stores->map(fn ($store) => [
                    'id' => $store->id,
                    'code' => $store->code,
                    'name' => $store->name,
                    'display_name' => $store->display_name,
                    'settings' => $store->settings ?? [],
                ])->values(),
            ],
            'storeBranding' => $currentStore ? [
                'brand_title' => data_get($currentStore->settings, 'brand_title', $currentStore->display_name),
                'brand_image' => data_get($currentStore->settings, 'brand_image', $isSmoothiesSweetie ? '/img/sweetie.png' : '/img/avenor_hitam.png'),
                'favicon' => data_get($currentStore->settings, 'favicon', $isSmoothiesSweetie ? '/img/sweetie.png' : '/img/avenor_hitam.png'),
                'web_title' => data_get($currentStore->settings, 'web_title', $currentStore->display_name),
            ] : [
                'brand_title' => 'Avenor Perfume',
                'brand_image' => '/img/avenor_hitam.png',
                'favicon' => '/img/avenor_hitam.png',
                'web_title' => 'Avenor Web',
            ],
            'permissionCatalog' => PermissionCatalog::groups(),
            'roleOptionsShared' => PermissionRole::query()
                ->orderBy('name')
                ->get(['id', 'name', 'legacy_role', 'description', 'permissions', 'is_locked'])
                ->map(fn (PermissionRole $role) => [
                    'id' => $role->id,
                    'name' => $role->name,
                    'legacy_role' => $role->legacy_role,
                    'description' => $role->description,
                    'permissions' => $role->permissions ?? [],
                    'is_locked' => $role->is_locked,
                ])
                ->values(),
            'inventoryAlerts' => $currentStoreId && $user ? [
                'products' => Product::query()
                    ->where('store_id', $currentStoreId)
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
                    ->where('store_id', $currentStoreId)
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
                    'permission_role_id' => $user->permission_role_id,
                    'permission_role_name' => $user->permissionRole?->name,
                    'permissions' => $user->permissions(),
                    'status' => $user->status,
                ] : null,
            ],
            'storeSummary' => $currentStoreId ? [
                'activeUsers' => User::query()->whereHas('stores', fn ($query) => $query->where('stores.id', $currentStoreId))->count(),
                'attendanceToday' => Attendance::query()->where('store_id', $currentStoreId)->whereDate('attendance_date', now()->toDateString())->count(),
                'customers' => Customer::query()->where('store_id', $currentStoreId)->count(),
                'expenses' => Expense::query()->where('store_id', $currentStoreId)->count(),
                'notifications' => MarketingNotification::query()->where('store_id', $currentStoreId)->count(),
            ] : null,
        ]);

        return $next($request);
    }

    private function navigation(?User $user): array
    {
        $currentStore = request()?->user() ? StoreContext::currentStore(request()) : null;
        $isSmoothiesSweetie = StoreFeature::isSmoothiesSweetie($currentStore);
        $navigation = [['label' => 'Dashboard', 'href' => route('dashboard'), 'icon' => 'fas fa-tachometer-alt']];

        if (! $user) {
            return $navigation;
        }

        if ($user->hasPermission('products.view') || $user->hasPermission('products.manage')) {
            $salesFeatureChildren = array_values(array_filter([
                ! $isSmoothiesSweetie && $user->hasPermission('products.approve') ? ['label' => 'Approvals', 'href' => route('approvals.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                $user->role === 'superadmin' ? ['label' => 'Target Penjualan', 'href' => route('sales-targets.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                ! $isSmoothiesSweetie && in_array($user->role, ['superadmin', 'admin', SalesRole::SALES_FIELD_EXECUTIVE], true) ? ['label' => 'Consign', 'href' => route('consignments.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                in_array($user->role, ['superadmin', 'admin'], true) ? ['label' => 'Promos', 'href' => route('promos.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                $user->hasPermission('extra_toppings.view') ? ['label' => 'Extra Topping', 'href' => route('extra-toppings.index'), 'icon' => 'far fa-circle nav-icon'] : null,
            ]));
            if ($salesFeatureChildren !== []) {
                $navigation[] = [
                    'label' => 'Sales Feature',
                    'icon' => 'fas fa-receipt',
                    'children' => $salesFeatureChildren,
                ];
            }

            $inventoryChildren = array_values(array_filter([
                $user->hasPermission('products.view') ? ['label' => 'Products', 'href' => route('products.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                ! $isSmoothiesSweetie && $user->hasPermission('products.approve') ? ['label' => 'Barang Onhand', 'href' => route('product-onhands.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                $user->hasPermission('hpp.view') ? ['label' => 'Hpp', 'href' => route('hpp.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                $user->hasPermission('raw_materials.view') ? ['label' => 'Raw Material', 'href' => route('raw-materials.index'), 'icon' => 'far fa-circle nav-icon'] : null,
            ]));
            if ($inventoryChildren !== []) {
                $navigation[] = [
                    'label' => 'Stock and Inventory',
                    'icon' => 'fas fa-boxes',
                    'children' => $inventoryChildren,
                ];
            }

            $financeChildren = array_values(array_filter([
                $user->hasPermission('expenses.view') ? ['label' => 'Pengeluaran', 'href' => route('expenses.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                $user->hasPermission('account_receivables.view') ? ['label' => 'Account Receiveables', 'href' => route('account-receivables.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                $user->hasPermission('account_payables.view') ? ['label' => 'Account Payables', 'href' => route('account-payables.index'), 'icon' => 'far fa-circle nav-icon'] : null,
            ]));
            if ($financeChildren !== []) {
                $navigation[] = [
                    'label' => 'Finance',
                    'icon' => 'fas fa-wallet',
                    'children' => $financeChildren,
                ];
            }

            $userManagementChildren = array_values(array_filter([
                $user->role === 'superadmin' ? ['label' => 'Master Store', 'href' => route('stores.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                $user->role === 'superadmin' ? ['label' => 'Roles', 'href' => route('roles.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                $user->hasPermission('users.view') ? ['label' => 'Users', 'href' => route('users.manage'), 'icon' => 'far fa-circle nav-icon'] : null,
                ! $isSmoothiesSweetie && in_array($user->role, ['superadmin', 'admin'], true) ? ['label' => 'Field Team', 'href' => route('field-team.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                $user->hasPermission('customers.view') ? ['label' => 'Customers', 'href' => route('customers.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                ! $isSmoothiesSweetie && in_array($user->role, ['superadmin', 'admin'], true) ? ['label' => 'Content Creator', 'href' => route('content-creators.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                $user->role === 'superadmin' ? ['label' => 'Applicant', 'href' => route('applicants.index'), 'icon' => 'far fa-circle nav-icon'] : null,
                $user->role === 'superadmin' ? ['label' => 'Article', 'href' => route('articles.manage'), 'icon' => 'far fa-circle nav-icon'] : null,
            ]));
            if ($userManagementChildren !== []) {
                $navigation[] = [
                    'label' => 'User Management',
                    'icon' => 'fas fa-users-cog',
                    'children' => $userManagementChildren,
                ];
            }
            if ($user->role === 'superadmin') {
                $navigation[] = ['label' => 'Landing Page Builder', 'href' => route('landing-page-builder.index'), 'icon' => 'fas fa-gem'];
                $navigation[] = ['label' => 'Global Settings', 'href' => route('global-settings.index'), 'icon' => 'fas fa-sliders-h'];
                $navigation[] = ['label' => 'SEO Manager', 'href' => route('seo-settings.index'), 'icon' => 'fas fa-search'];
            }
            if ($user->hasPermission('notifications.view')) {
                $navigation[] = ['label' => 'Notifications', 'href' => route('notifications.index'), 'icon' => 'fas fa-bell'];
            }
            if ($user->hasPermission('offline_sales.view')) {
                $navigation[] = ['label' => 'Penjualan Offline', 'href' => route('offline-sales.index'), 'icon' => 'fas fa-shopping-bag'];
                $navigation[] = ['label' => 'Queue Board', 'href' => route('queue-board'), 'icon' => 'fas fa-list-ol'];
            }
            if ($user->hasPermission('online_sales.view')) {
                $navigation[] = ['label' => 'Penjualan Online', 'href' => route('online-sales.index'), 'icon' => 'fas fa-cart-arrow-down'];
            }
            if ($user->hasPermission('sops.view')) {
                $navigation[] = ['label' => 'SOP', 'href' => route('sops.index'), 'icon' => 'fas fa-clipboard-list'];
            }
            $navigation[] = ['label' => 'Product Knowledge', 'href' => route('products.knowledge'), 'icon' => 'fas fa-book-open'];
        }

        if (SalesRole::isFieldRole($user->role) && $user->hasPermission('attendance.view')) {
            $navigation[] = ['label' => 'Absensi', 'href' => route('marketing.attendance.index'), 'icon' => 'fas fa-user-check'];
            if (! $isSmoothiesSweetie) {
                $navigation[] = ['label' => 'Products', 'href' => route('products.index'), 'icon' => 'fas fa-box-open'];
            }
            $navigation[] = ['label' => 'Product Knowledge', 'href' => route('products.knowledge'), 'icon' => 'fas fa-book-open'];
            $navigation[] = ['label' => 'Penjualan Offline', 'href' => route('offline-sales.index'), 'icon' => 'fas fa-shopping-bag'];
            $navigation[] = ['label' => 'Queue Board', 'href' => route('queue-board'), 'icon' => 'fas fa-list-ol'];
            if (! $isSmoothiesSweetie && $user->role === SalesRole::SALES_FIELD_EXECUTIVE) {
                $navigation[] = ['label' => 'Consign', 'href' => route('consignments.index'), 'icon' => 'fas fa-store'];
            }
        }

        return $this->dedupeNavigation($navigation);
    }

    private function dedupeNavigation(array $items): array
    {
        $seen = [];
        $deduped = [];

        foreach ($items as $item) {
            $children = isset($item['children']) && is_array($item['children'])
                ? $this->dedupeNavigation($item['children'])
                : [];

            if (isset($item['children']) && $children === []) {
                continue;
            }

            if ($children !== []) {
                $item['children'] = $children;
            }

            $key = ($item['label'] ?? '') . '|' . ($item['href'] ?? '');
            if (isset($seen[$key])) {
                continue;
            }

            $seen[$key] = true;
            $deduped[] = $item;
        }

        return $deduped;
    }
}
