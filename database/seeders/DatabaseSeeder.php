<?php

namespace Database\Seeders;

use App\Models\Area;
use App\Models\Attendance;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

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

        $areas = [
            ['name' => 'Jakarta Barat', 'region' => 'DKI Jakarta', 'target_visits' => 24, 'active' => true],
            ['name' => 'Bandung Kota', 'region' => 'Jawa Barat', 'target_visits' => 18, 'active' => true],
            ['name' => 'Bekasi Timur', 'region' => 'Jawa Barat', 'target_visits' => 20, 'active' => true],
        ];

        foreach ($areas as $area) {
            Area::query()->updateOrCreate(['name' => $area['name']], $area + ['created_at' => now()]);
        }

        $marketing = User::query()->where('nama', 'marketing')->first();
        $areaIds = Area::query()->pluck('id')->all();

        if (! $marketing || empty($areaIds)) {
            return;
        }

        foreach (range(1, 6) as $offset) {
            $date = Carbon::now()->subDays($offset);
            $areaId = $areaIds[$offset % count($areaIds)];
            $status = $offset % 4 === 0 ? 'terlambat' : 'hadir';

            Attendance::query()->updateOrCreate(
                [
                    'user_id' => $marketing->id_user,
                    'area_id' => $areaId,
                    'attendance_date' => $date->toDateString(),
                ],
                [
                    'check_in' => $status === 'terlambat' ? '09:15:00' : '08:10:00',
                    'check_out' => '17:00:00',
                    'status' => $status,
                    'notes' => 'Seeded attendance for KPI dashboard.',
                    'created_at' => $date->copy()->setTime(8, 0),
                ],
            );
        }
    }
}