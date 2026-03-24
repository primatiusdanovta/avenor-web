<?php

namespace Tests\Feature;

use App\Models\Area;
use App\Models\Attendance;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Inertia\Testing\AssertableInertia as Assert;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_is_redirected_to_login_page(): void
    {
        $this->get('/')->assertRedirectToRoute('login');
    }

    public function test_login_page_renders_inertia_component(): void
    {
        $this->get(route('login'))
            ->assertInertia(fn (Assert $page) => $page
                ->component('Auth/Login')
                ->where('branding.title', 'Avenor Web')
                ->etc());
    }

    public function test_superadmin_can_view_user_management_page(): void
    {
        $this->seed();
        $user = User::where('nama', 'superadmin')->firstOrFail();

        $this->actingAs($user)
            ->get(route('users.manage'))
            ->assertInertia(fn (Assert $page) => $page
                ->component('Users/Manage')
                ->has('users', 4)
                ->etc());
    }

    public function test_superadmin_can_create_user(): void
    {
        $this->seed();
        $user = User::where('nama', 'superadmin')->firstOrFail();

        $this->actingAs($user)
            ->post(route('users.store'), [
                'nama' => 'operator',
                'role' => 'admin',
                'status' => 'aktif',
                'password' => 'Operator123!',
                'password_confirmation' => 'Operator123!',
            ])
            ->assertRedirectToRoute('users.manage');

        $this->assertDatabaseHas('users', ['nama' => 'operator', 'role' => 'admin']);
    }

    public function test_marketing_can_view_kpi_page(): void
    {
        $this->seed();
        $user = User::where('nama', 'marketing')->firstOrFail();

        $this->actingAs($user)
            ->get(route('marketing.kpi'))
            ->assertInertia(fn (Assert $page) => $page
                ->component('Marketing/Kpi')
                ->has('kpis', 4)
                ->has('areas')
                ->has('recentAttendances')
                ->etc());
    }

    public function test_marketing_can_store_attendance(): void
    {
        $this->seed();
        $user = User::where('nama', 'marketing')->firstOrFail();
        $area = Area::firstOrFail();
        $date = now()->toDateString();

        $this->actingAs($user)
            ->post(route('marketing.attendance.store'), [
                'area_id' => $area->id,
                'attendance_date' => $date,
                'check_in' => '08:30',
                'check_out' => '17:10',
                'status' => 'hadir',
                'notes' => 'Kunjungan area baru.',
            ])
            ->assertRedirectToRoute('marketing.kpi');

        $this->assertTrue(
            Attendance::query()
                ->where('user_id', $user->id_user)
                ->where('area_id', $area->id)
                ->whereDate('attendance_date', $date)
                ->exists()
        );
    }

    public function test_non_marketing_cannot_access_marketing_kpi(): void
    {
        $this->seed();
        $user = User::where('nama', 'admin')->firstOrFail();

        $this->actingAs($user)
            ->get(route('marketing.kpi'))
            ->assertForbidden();
    }
}