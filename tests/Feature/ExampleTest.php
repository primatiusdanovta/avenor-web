<?php

namespace Tests\Feature;

use App\Models\Attendance;
use App\Models\MarketingLocation;
use App\Models\OfflineSale;
use App\Models\Product;
use App\Models\ProductOnhand;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Inertia\Testing\AssertableInertia as Assert;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_page_renders_inertia_component(): void
    {
        $this->get(route('login'))
            ->assertInertia(fn (Assert $page) => $page->component('Auth/Login')->etc());
    }

    public function test_superadmin_can_view_marketing_monitoring_page(): void
    {
        $this->seed();
        $user = User::where('nama', 'superadmin')->firstOrFail();

        $this->actingAs($user)
            ->get(route('marketing.index'))
            ->assertInertia(fn (Assert $page) => $page->component('Marketing/Index')->has('marketers')->etc());
    }

    public function test_admin_can_create_product(): void
    {
        Storage::fake('public');
        $this->seed();
        $user = User::where('nama', 'admin')->firstOrFail();

        $this->actingAs($user)
            ->post(route('products.store'), [
                'nama_product' => 'ONT Baru',
                'harga' => 650000,
                'harga_modal' => 500000,
                'stock' => 8,
                'gambar' => UploadedFile::fake()->create('ont.jpg', 10, 'image/jpeg'),
            ])
            ->assertRedirectToRoute('products.index');

        $this->assertDatabaseHas('products', ['nama_product' => 'ONT Baru']);
    }

    public function test_marketing_can_take_product_after_checkin(): void
    {
        $this->seed();
        $user = User::where('nama', 'marketing')->firstOrFail();
        $product = $this->createProduct();

        Attendance::query()->create([
            'user_id' => $user->id_user,
            'attendance_date' => now()->toDateString(),
            'check_in' => '08:00:00',
            'check_in_latitude' => -6.2,
            'check_in_longitude' => 106.8,
            'status' => 'hadir',
            'created_at' => now(),
        ]);

        $this->actingAs($user)
            ->post(route('products.take'), [
                'id_product' => $product->id_product,
                'quantity' => 2,
            ])
            ->assertRedirectToRoute('products.index');

        $this->assertDatabaseHas('product_onhands', ['user_id' => $user->id_user, 'id_product' => $product->id_product, 'quantity' => 2]);
    }

    public function test_marketing_checkout_is_blocked_when_product_remains(): void
    {
        $this->seed();
        $user = User::where('nama', 'marketing')->firstOrFail();
        $product = $this->createProduct();

        ProductOnhand::query()->create([
            'user_id' => $user->id_user,
            'id_product' => $product->id_product,
            'nama_product' => $product->nama_product,
            'quantity' => 3,
            'quantity_dikembalikan' => 0,
            'return_status' => 'belum',
            'assignment_date' => now()->toDateString(),
            'created_at' => now(),
        ]);

        $this->actingAs($user)
            ->from(route('marketing.attendance.index'))
            ->post(route('marketing.attendance.check-out'), [
                'status' => 'hadir',
                'notes' => 'Pulang',
                'latitude' => -6.2,
                'longitude' => 106.8,
            ])
            ->assertRedirect(route('marketing.attendance.index'));

        $this->assertTrue(session()->has('errors'));
        $this->assertStringContainsString('Barang belum dikembalikan', session('errors')->first('checkout'));
    }

    public function test_marketing_cannot_send_second_return_request_while_pending(): void
    {
        $this->seed();
        $user = User::where('nama', 'marketing')->firstOrFail();
        $product = $this->createProduct();
        $onhand = ProductOnhand::query()->create([
            'user_id' => $user->id_user,
            'id_product' => $product->id_product,
            'nama_product' => $product->nama_product,
            'quantity' => 3,
            'quantity_dikembalikan' => 1,
            'return_status' => 'pending',
            'assignment_date' => now()->toDateString(),
            'created_at' => now(),
        ]);

        $this->actingAs($user)
            ->from(route('products.index'))
            ->put(route('products.onhand.return', $onhand), [
                'quantity_dikembalikan' => 1,
            ])
            ->assertRedirect(route('products.index'));

        $this->assertStringContainsString('Masih ada antrian yang belum disetujui', session('errors')->first('quantity_dikembalikan'));
    }

    public function test_marketing_can_checkout_when_product_is_fully_sold(): void
    {
        $this->seed();
        $user = User::where('nama', 'marketing')->firstOrFail();
        $product = $this->createProduct();
        $onhand = ProductOnhand::query()->create([
            'user_id' => $user->id_user,
            'id_product' => $product->id_product,
            'nama_product' => $product->nama_product,
            'quantity' => 2,
            'quantity_dikembalikan' => 0,
            'return_status' => 'belum',
            'assignment_date' => now()->toDateString(),
            'created_at' => now(),
        ]);

        OfflineSale::query()->create([
            'id_user' => $user->id_user,
            'id_product' => $product->id_product,
            'id_product_onhand' => $onhand->id_product_onhand,
            'nama' => $user->nama,
            'nama_product' => $product->nama_product,
            'quantity' => 2,
            'harga' => 100000,
            'approval_status' => 'pending',
            'created_at' => now(),
        ]);

        $this->actingAs($user)
            ->post(route('marketing.attendance.check-out'), [
                'status' => 'hadir',
                'notes' => 'Pulang',
                'latitude' => -6.2,
                'longitude' => 106.8,
            ])
            ->assertRedirectToRoute('marketing.attendance.index');
    }

    public function test_marketing_location_ping_is_saved(): void
    {
        $this->seed();
        $user = User::where('nama', 'marketing')->firstOrFail();

        $this->actingAs($user)
            ->post(route('marketing.location.store'), [
                'latitude' => -6.21,
                'longitude' => 106.81,
                'source' => 'heartbeat',
            ])
            ->assertStatus(303);

        $this->assertTrue(MarketingLocation::query()->where('user_id', $user->id_user)->where('source', 'heartbeat')->exists());
    }

    private function createProduct(): Product
    {
        return Product::query()->create([
            'nama_product' => 'Product Test',
            'harga' => 100000,
            'harga_modal' => 75000,
            'stock' => 20,
            'created_at' => now(),
        ]);
    }
}
