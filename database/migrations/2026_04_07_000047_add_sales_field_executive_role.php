<?php

use App\Support\SalesRole;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $this->dropUserRoleConstraint();

        DB::table('users')
            ->where('role', 'reseller')
            ->update([
                'role' => SalesRole::SALES_FIELD_EXECUTIVE,
                'require_return_before_checkout' => false,
            ]);

        if (DB::getSchemaBuilder()->hasTable('sales_targets')) {
            DB::table('sales_targets')
                ->where('role', 'reseller')
                ->update(['role' => SalesRole::SALES_FIELD_EXECUTIVE]);
        }

        $this->syncUserRoleConstraint([
            'superadmin',
            'admin',
            'marketing',
            SalesRole::SALES_FIELD_EXECUTIVE,
        ]);
    }

    public function down(): void
    {
        $this->dropUserRoleConstraint();

        DB::table('users')
            ->where('role', SalesRole::SALES_FIELD_EXECUTIVE)
            ->update(['role' => 'reseller']);

        if (DB::getSchemaBuilder()->hasTable('sales_targets')) {
            DB::table('sales_targets')
                ->where('role', SalesRole::SALES_FIELD_EXECUTIVE)
                ->update(['role' => 'reseller']);
        }

        $this->syncUserRoleConstraint([
            'superadmin',
            'admin',
            'marketing',
            'reseller',
        ]);
    }

    private function syncUserRoleConstraint(array $roles): void
    {
        $driver = DB::getDriverName();
        $quotedRoles = implode(',', array_map(
            fn (string $role) => "'" . str_replace("'", "''", $role) . "'",
            $roles
        ));

        if (in_array($driver, ['mysql', 'mariadb'], true)) {
            DB::statement("ALTER TABLE users MODIFY role ENUM({$quotedRoles}) NOT NULL");
            return;
        }

        if ($driver === 'pgsql') {
            DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ({$quotedRoles}))");
        }
    }

    private function dropUserRoleConstraint(): void
    {
        if (DB::getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');
        }
    }
};
