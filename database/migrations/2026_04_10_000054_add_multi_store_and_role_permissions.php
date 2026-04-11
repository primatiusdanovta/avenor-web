<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('stores', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('name');
            $table->string('display_name');
            $table->string('status')->default('active');
            $table->string('timezone')->default('Asia/Jakarta');
            $table->string('currency')->default('IDR');
            $table->text('address')->nullable();
            $table->json('settings')->nullable();
            $table->timestamps();
        });

        Schema::create('permission_roles', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->string('name');
            $table->string('legacy_role');
            $table->text('description')->nullable();
            $table->json('permissions');
            $table->boolean('is_locked')->default(false);
            $table->timestamps();
        });

        Schema::create('store_user_assignments', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('store_id');
            $table->boolean('is_primary')->default(false);
            $table->timestamps();

            $table->unique(['user_id', 'store_id']);
            $table->foreign('user_id')->references('id_user')->on('users')->cascadeOnDelete();
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->unsignedBigInteger('permission_role_id')->nullable()->after('role');
            $table->foreign('permission_role_id')->references('id')->on('permission_roles')->nullOnDelete();
        });

        Schema::table('products', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('id_product');
            $table->index('store_id');
        });

        Schema::table('raw_materials', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('id_rm');
            $table->index('store_id');
        });

        Schema::table('hpp_calculations', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('id_hpp');
            $table->index('store_id');
        });

        Schema::table('promos', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('id');
            $table->index('store_id');
        });

        Schema::table('product_onhands', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('id_product_onhand');
            $table->index('store_id');
        });

        Schema::table('offline_sales', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('id_penjualan_offline');
            $table->index('store_id');
        });

        Schema::table('online_sales', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('id');
            $table->index('store_id');
        });

        Schema::table('online_sale_items', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('id');
            $table->index('store_id');
        });

        Schema::table('expenses', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('id');
            $table->index('store_id');
        });

        Schema::table('account_payables', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('id');
            $table->index('store_id');
        });

        Schema::table('account_receivables', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('id');
            $table->index('store_id');
        });

        Schema::table('customers', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('id_pelanggan');
            $table->index('store_id');
        });

        Schema::table('attendances', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('id');
            $table->index('store_id');
        });

        Schema::table('marketing_locations', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('id');
            $table->index('store_id');
        });

        Schema::table('marketing_notifications', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('id');
            $table->index('store_id');
        });

        Schema::table('consignments', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('id');
            $table->index('store_id');
        });

        Schema::table('products', function (Blueprint $table) {
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::table('raw_materials', function (Blueprint $table) {
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::table('hpp_calculations', function (Blueprint $table) {
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::table('promos', function (Blueprint $table) {
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::table('product_onhands', function (Blueprint $table) {
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::table('offline_sales', function (Blueprint $table) {
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::table('online_sales', function (Blueprint $table) {
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::table('online_sale_items', function (Blueprint $table) {
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::table('expenses', function (Blueprint $table) {
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::table('account_payables', function (Blueprint $table) {
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::table('account_receivables', function (Blueprint $table) {
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::table('customers', function (Blueprint $table) {
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::table('attendances', function (Blueprint $table) {
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::table('marketing_locations', function (Blueprint $table) {
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::table('marketing_notifications', function (Blueprint $table) {
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        Schema::table('consignments', function (Blueprint $table) {
            $table->foreign('store_id')->references('id')->on('stores')->cascadeOnDelete();
        });

        if (Schema::hasTable('products')) {
            Schema::table('products', function (Blueprint $table) {
                $table->dropUnique('products_nama_product_unique');
                $table->unique(['store_id', 'nama_product']);
            });
        }

        if (Schema::hasTable('raw_materials')) {
            Schema::table('raw_materials', function (Blueprint $table) {
                $table->dropUnique('raw_materials_nama_rm_unique');
                $table->unique(['store_id', 'nama_rm']);
            });
        }

        if (Schema::hasTable('customers')) {
            Schema::table('customers', function (Blueprint $table) {
                $table->dropUnique('customers_no_telp_unique');
                $table->unique(['store_id', 'no_telp']);
            });
        }

        $now = now();

        $avenorStoreId = DB::table('stores')->insertGetId([
            'code' => 'avenor_perfume',
            'name' => 'avenor_perfume',
            'display_name' => 'Avenor Perfume',
            'status' => 'active',
            'timezone' => 'Asia/Jakarta',
            'currency' => 'IDR',
            'settings' => json_encode([
                'brand_title' => 'Avenor Perfume',
                'brand_image' => '/img/avenor_hitam.png',
                'favicon' => '/img/avenor_hitam.png',
                'web_title' => 'Avenor Perfume',
            ], JSON_THROW_ON_ERROR),
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $smoothiesStoreId = DB::table('stores')->insertGetId([
            'code' => 'smoothies_sweetie',
            'name' => 'smoothies_sweetie',
            'display_name' => 'Smoothies Sweetie',
            'status' => 'active',
            'timezone' => 'Asia/Jakarta',
            'currency' => 'IDR',
            'settings' => json_encode([
                'brand_title' => 'Smoothies Sweetie',
                'brand_image' => '/img/sweetie.png',
                'favicon' => '/img/sweetie.png',
                'web_title' => 'Smoothies Sweetie',
            ], JSON_THROW_ON_ERROR),
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $allPermissions = [
            'dashboard.view',
            'stores.view',
            'stores.manage',
            'roles.view',
            'roles.manage',
            'users.view',
            'users.manage',
            'products.view',
            'products.manage',
            'products.take',
            'products.approve',
            'raw_materials.view',
            'raw_materials.manage',
            'hpp.view',
            'hpp.manage',
            'offline_sales.view',
            'offline_sales.manage',
            'offline_sales.approve',
            'online_sales.view',
            'online_sales.manage',
            'expenses.view',
            'expenses.manage',
            'account_receivables.view',
            'account_receivables.manage',
            'account_payables.view',
            'account_payables.manage',
            'customers.view',
            'customers.manage',
            'notifications.view',
            'notifications.manage',
            'attendance.view',
            'attendance.manage',
            'attendance.checkin',
            'attendance.checkout',
        ];

        $adminPermissions = array_values(array_diff($allPermissions, ['stores.manage']));
        $fieldPermissions = [
            'dashboard.view',
            'products.view',
            'products.take',
            'offline_sales.view',
            'offline_sales.manage',
            'attendance.view',
            'attendance.manage',
            'attendance.checkin',
            'attendance.checkout',
        ];

        $roles = [
            [
                'key' => 'superadmin',
                'name' => 'Superadmin',
                'legacy_role' => 'superadmin',
                'description' => 'Akses penuh seluruh store dan master store.',
                'permissions' => json_encode($allPermissions, JSON_THROW_ON_ERROR),
                'is_locked' => true,
            ],
            [
                'key' => 'admin_full_access',
                'name' => 'Admin Full Access',
                'legacy_role' => 'admin',
                'description' => 'Akses penuh menu operasional store termasuk user dan role checklist.',
                'permissions' => json_encode($adminPermissions, JSON_THROW_ON_ERROR),
                'is_locked' => true,
            ],
            [
                'key' => 'marketing_default',
                'name' => 'Marketing Default',
                'legacy_role' => 'marketing',
                'description' => 'Akses marketing untuk absensi, barang, dan penjualan offline.',
                'permissions' => json_encode($fieldPermissions, JSON_THROW_ON_ERROR),
                'is_locked' => true,
            ],
            [
                'key' => 'sales_field_default',
                'name' => 'Sales Field Executive Default',
                'legacy_role' => 'sales_field_executive',
                'description' => 'Akses sales field executive untuk absensi, barang, dan penjualan offline.',
                'permissions' => json_encode($fieldPermissions, JSON_THROW_ON_ERROR),
                'is_locked' => true,
            ],
        ];

        foreach ($roles as $role) {
            DB::table('permission_roles')->insert([
                ...$role,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }

        $roleIds = DB::table('permission_roles')->pluck('id', 'key');

        DB::table('products')->update(['store_id' => $avenorStoreId]);
        DB::table('raw_materials')->update(['store_id' => $avenorStoreId]);
        DB::table('hpp_calculations')->update(['store_id' => $avenorStoreId]);
        DB::table('promos')->update(['store_id' => $avenorStoreId]);
        DB::table('product_onhands')->update(['store_id' => $avenorStoreId]);
        DB::table('offline_sales')->update(['store_id' => $avenorStoreId]);
        DB::table('online_sales')->update(['store_id' => $avenorStoreId]);
        DB::table('online_sale_items')->update(['store_id' => $avenorStoreId]);
        DB::table('expenses')->update(['store_id' => $avenorStoreId]);
        DB::table('account_payables')->update(['store_id' => $avenorStoreId]);
        DB::table('account_receivables')->update(['store_id' => $avenorStoreId]);
        DB::table('customers')->update(['store_id' => $avenorStoreId]);
        DB::table('attendances')->update(['store_id' => $avenorStoreId]);
        DB::table('marketing_locations')->update(['store_id' => $avenorStoreId]);
        DB::table('marketing_notifications')->update(['store_id' => $avenorStoreId]);
        DB::table('consignments')->update(['store_id' => $avenorStoreId]);

        DB::table('users')
            ->where('role', 'superadmin')
            ->update(['permission_role_id' => $roleIds['superadmin'] ?? null]);
        DB::table('users')
            ->where('role', 'admin')
            ->update(['permission_role_id' => $roleIds['admin_full_access'] ?? null]);
        DB::table('users')
            ->where('role', 'marketing')
            ->update(['permission_role_id' => $roleIds['marketing_default'] ?? null]);
        DB::table('users')
            ->where('role', 'sales_field_executive')
            ->update(['permission_role_id' => $roleIds['sales_field_default'] ?? null]);

        $existingUsers = DB::table('users')->select('id_user')->get();
        foreach ($existingUsers as $user) {
            DB::table('store_user_assignments')->updateOrInsert(
                ['user_id' => $user->id_user, 'store_id' => $avenorStoreId],
                ['is_primary' => true, 'created_at' => $now, 'updated_at' => $now]
            );
        }

        $sweetieAdminId = DB::table('users')->insertGetId([
            'nama' => 'admin_swetiee',
            'status' => 'aktif',
            'role' => 'admin',
            'permission_role_id' => $roleIds['admin_full_access'] ?? null,
            'password' => Hash::make('AdminSweetie123!'),
            'remember_token' => null,
            'created_at' => $now,
        ], 'id_user');

        DB::table('store_user_assignments')->insert([
            'user_id' => $sweetieAdminId,
            'store_id' => $smoothiesStoreId,
            'is_primary' => true,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $superadminIds = DB::table('users')->where('role', 'superadmin')->pluck('id_user');
        foreach ($superadminIds as $superadminId) {
            DB::table('store_user_assignments')->updateOrInsert(
                ['user_id' => $superadminId, 'store_id' => $smoothiesStoreId],
                ['is_primary' => false, 'created_at' => $now, 'updated_at' => $now]
            );
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('raw_materials')) {
            Schema::table('raw_materials', function (Blueprint $table) {
                $table->dropUnique(['store_id', 'nama_rm']);
                $table->unique('nama_rm');
            });
        }

        if (Schema::hasTable('products')) {
            Schema::table('products', function (Blueprint $table) {
                $table->dropUnique(['store_id', 'nama_product']);
                $table->unique('nama_product');
            });
        }

        if (Schema::hasTable('customers')) {
            Schema::table('customers', function (Blueprint $table) {
                $table->dropUnique(['store_id', 'no_telp']);
                $table->unique('no_telp');
            });
        }

        Schema::table('consignments', function (Blueprint $table) {
            $table->dropForeign(['store_id']);
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });

        Schema::table('marketing_notifications', function (Blueprint $table) {
            $table->dropForeign(['store_id']);
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });

        Schema::table('marketing_locations', function (Blueprint $table) {
            $table->dropForeign(['store_id']);
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });

        Schema::table('attendances', function (Blueprint $table) {
            $table->dropForeign(['store_id']);
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });

        Schema::table('customers', function (Blueprint $table) {
            $table->dropForeign(['store_id']);
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });

        Schema::table('account_receivables', function (Blueprint $table) {
            $table->dropForeign(['store_id']);
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });

        Schema::table('account_payables', function (Blueprint $table) {
            $table->dropForeign(['store_id']);
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });

        Schema::table('expenses', function (Blueprint $table) {
            $table->dropForeign(['store_id']);
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });

        Schema::table('online_sale_items', function (Blueprint $table) {
            $table->dropForeign(['store_id']);
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });

        Schema::table('online_sales', function (Blueprint $table) {
            $table->dropForeign(['store_id']);
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });

        Schema::table('offline_sales', function (Blueprint $table) {
            $table->dropForeign(['store_id']);
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });

        Schema::table('product_onhands', function (Blueprint $table) {
            $table->dropForeign(['store_id']);
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });

        Schema::table('promos', function (Blueprint $table) {
            $table->dropForeign(['store_id']);
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });

        Schema::table('hpp_calculations', function (Blueprint $table) {
            $table->dropForeign(['store_id']);
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });

        Schema::table('raw_materials', function (Blueprint $table) {
            $table->dropForeign(['store_id']);
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });

        Schema::table('products', function (Blueprint $table) {
            $table->dropForeign(['store_id']);
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['permission_role_id']);
            $table->dropColumn('permission_role_id');
        });

        Schema::dropIfExists('store_user_assignments');
        Schema::dropIfExists('permission_roles');
        Schema::dropIfExists('stores');
    }
};
