<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $users = [
            ['nama' => 'superadmin', 'status' => 'aktif', 'role' => 'superadmin', 'password' => 'Superadmin123!'],
            ['nama' => 'admin', 'status' => 'aktif', 'role' => 'admin', 'password' => 'Admin123!'],
            ['nama' => 'marketing', 'status' => 'aktif', 'role' => 'marketing', 'password' => 'Marketing123!'],
            ['nama' => 'reseller', 'status' => 'aktif', 'role' => 'reseller', 'password' => 'Reseller123!'],
        ];

        foreach ($users as $user) {
            User::query()->updateOrCreate(
                ['nama' => $user['nama']],
                [
                    'status' => $user['status'],
                    'role' => $user['role'],
                    'password' => $user['password'],
                    'created_at' => now(),
                ],
            );
        }
    }
}
