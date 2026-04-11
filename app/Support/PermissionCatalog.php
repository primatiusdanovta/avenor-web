<?php

namespace App\Support;

class PermissionCatalog
{
    public static function groups(): array
    {
        return [
            'Master Store' => [
                'stores.view' => 'Lihat daftar store',
                'stores.manage' => 'Tambah dan ubah data master store',
            ],
            'Dashboard' => [
                'dashboard.view' => 'Lihat dashboard store aktif',
            ],
            'Roles' => [
                'roles.view' => 'Lihat daftar role checklist',
                'roles.manage' => 'Tambah dan ubah role checklist',
            ],
            'Users' => [
                'users.view' => 'Lihat daftar user',
                'users.manage' => 'Tambah dan ubah user berdasarkan store dan role',
            ],
            'Products' => [
                'products.view' => 'Lihat produk store aktif',
                'products.manage' => 'Tambah, ubah, dan hapus produk',
                'products.take' => 'Request pengambilan barang',
                'products.approve' => 'Approve pengambilan dan pengembalian barang',
            ],
            'Raw Materials' => [
                'raw_materials.view' => 'Lihat raw materials',
                'raw_materials.manage' => 'Tambah, restock, ubah, dan hapus raw materials',
            ],
            'HPP' => [
                'hpp.view' => 'Lihat perhitungan HPP',
                'hpp.manage' => 'Tambah dan hapus perhitungan HPP',
            ],
            'Offline Sales' => [
                'offline_sales.view' => 'Lihat penjualan offline',
                'offline_sales.manage' => 'Input dan ubah penjualan offline',
                'offline_sales.approve' => 'Approve penjualan offline',
            ],
            'Extra Toppings' => [
                'extra_toppings.view' => 'Lihat extra topping',
                'extra_toppings.manage' => 'Tambah, ubah, dan hapus extra topping',
            ],
            'Online Sales' => [
                'online_sales.view' => 'Lihat penjualan online',
                'online_sales.manage' => 'Import penjualan online',
            ],
            'Expenses' => [
                'expenses.view' => 'Lihat pengeluaran',
                'expenses.manage' => 'Tambah, ubah, dan hapus pengeluaran',
            ],
            'Account Receivables' => [
                'account_receivables.view' => 'Lihat account receivables',
                'account_receivables.manage' => 'Kelola account receivables',
            ],
            'Account Payables' => [
                'account_payables.view' => 'Lihat account payables',
                'account_payables.manage' => 'Kelola account payables',
            ],
            'Customers' => [
                'customers.view' => 'Lihat customers',
                'customers.manage' => 'Tambah, ubah, dan hapus customers',
            ],
            'Notifications' => [
                'notifications.view' => 'Lihat notifications',
                'notifications.manage' => 'Buat, ubah, publish, dan hapus notifications',
            ],
            'Attendance' => [
                'attendance.view' => 'Lihat absensi',
                'attendance.manage' => 'Lihat detail absensi dan barang bawaan',
                'attendance.checkin' => 'Melakukan check in',
                'attendance.checkout' => 'Melakukan check out',
            ],
            'SOP' => [
                'sops.view' => 'Lihat SOP',
                'sops.manage' => 'Tambah, ubah, dan hapus SOP',
            ],
        ];
    }

    public static function flat(): array
    {
        return collect(self::groups())
            ->flatMap(fn (array $permissions, string $group) => collect($permissions)->map(
                fn (string $label, string $key) => ['key' => $key, 'label' => $label, 'group' => $group]
            ))
            ->values()
            ->all();
    }

    public static function defaultPermissionsForLegacyRole(?string $legacyRole): array
    {
        $all = array_map(fn (array $item) => $item['key'], self::flat());

        return match ($legacyRole) {
            'superadmin' => $all,
            'admin' => array_values(array_diff($all, ['stores.manage'])),
            'marketing', 'sales_field_executive' => [
                'dashboard.view',
                'products.view',
                'products.take',
                'offline_sales.view',
                'offline_sales.manage',
                'attendance.view',
                'attendance.manage',
                'attendance.checkin',
                'attendance.checkout',
            ],
            'owner' => [
                'dashboard.view',
                'products.view',
                'products.manage',
                'raw_materials.view',
                'raw_materials.manage',
                'hpp.view',
                'hpp.manage',
                'offline_sales.view',
                'offline_sales.manage',
                'customers.view',
                'customers.manage',
                'attendance.view',
                'attendance.manage',
                'attendance.checkin',
                'attendance.checkout',
                'extra_toppings.view',
                'extra_toppings.manage',
                'sops.view',
                'sops.manage',
            ],
            'karyawan' => [
                'dashboard.view',
                'products.view',
                'offline_sales.view',
                'offline_sales.manage',
                'attendance.view',
                'attendance.manage',
                'attendance.checkin',
                'attendance.checkout',
                'sops.view',
            ],
            default => [],
        };
    }
}
