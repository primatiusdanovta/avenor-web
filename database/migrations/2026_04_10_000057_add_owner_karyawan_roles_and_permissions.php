<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (! DB::getSchemaBuilder()->hasTable('permission_roles')) {
            return;
        }

        $now = now();
        $ownerPermissions = json_encode([
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
        ], JSON_THROW_ON_ERROR);

        $karyawanPermissions = json_encode([
            'dashboard.view',
            'products.view',
            'offline_sales.view',
            'offline_sales.manage',
            'attendance.view',
            'attendance.manage',
            'attendance.checkin',
            'attendance.checkout',
            'sops.view',
        ], JSON_THROW_ON_ERROR);

        DB::table('permission_roles')->updateOrInsert(
            ['key' => 'owner_default'],
            [
                'name' => 'Owner Default',
                'legacy_role' => 'owner',
                'description' => 'Akses owner Smoothies Sweetie untuk operasional dan SOP.',
                'permissions' => $ownerPermissions,
                'is_locked' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ]
        );

        DB::table('permission_roles')->updateOrInsert(
            ['key' => 'karyawan_default'],
            [
                'name' => 'Karyawan Default',
                'legacy_role' => 'karyawan',
                'description' => 'Akses karyawan Smoothies Sweetie untuk absensi, penjualan, dan SOP.',
                'permissions' => $karyawanPermissions,
                'is_locked' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ]
        );
    }

    public function down(): void
    {
        if (! DB::getSchemaBuilder()->hasTable('permission_roles')) {
            return;
        }

        DB::table('permission_roles')
            ->whereIn('key', ['owner_default', 'karyawan_default'])
            ->delete();
    }
};
