<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $this->syncUserRoleConstraint([
            'superadmin',
            'admin',
            'marketing',
            'sales_field_executive',
            'owner',
            'karyawan',
        ]);
    }

    public function down(): void
    {
        $this->syncUserRoleConstraint([
            'superadmin',
            'admin',
            'marketing',
            'sales_field_executive',
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
            DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');
            DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ({$quotedRoles}))");
        }
    }
};
