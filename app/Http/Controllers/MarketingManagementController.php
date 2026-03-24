<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\MarketingLocation;
use App\Models\OfflineSale;
use App\Models\ProductOnhand;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class MarketingManagementController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        $search = trim((string) $request->string('search'));
        $selectedId = (int) $request->integer('selected');

        $marketers = User::query()
            ->where('role', 'marketing')
            ->when($search !== '', fn ($query) => $query->where('nama', 'like', "%{$search}%"))
            ->orderBy('nama')
            ->get(['id_user', 'nama', 'status', 'created_at'])
            ->map(function (User $marketing) {
                $todayAttendance = Attendance::query()
                    ->where('user_id', $marketing->id_user)
                    ->whereDate('attendance_date', now()->toDateString())
                    ->first();

                $todayOnhands = ProductOnhand::query()
                    ->where('user_id', $marketing->id_user)
                    ->whereDate('assignment_date', now()->toDateString())
                    ->get();

                return [
                    'id_user' => $marketing->id_user,
                    'nama' => $marketing->nama,
                    'status' => $marketing->status,
                    'created_at' => optional($marketing->created_at)->format('Y-m-d H:i:s'),
                    'today_status' => $todayAttendance?->status ?? 'belum absen',
                    'carried_items' => $todayOnhands->map(function (ProductOnhand $onhand) {
                        $remaining = $this->remainingForOnhand($onhand);

                        return [
                            'nama_product' => $onhand->nama_product,
                            'quantity' => (int) $onhand->quantity,
                            'quantity_dikembalikan' => (int) $onhand->quantity_dikembalikan,
                            'remaining_quantity' => $remaining,
                            'take_status' => $onhand->take_status,
                            'return_status' => $onhand->return_status,
                        ];
                    })->values(),
                ];
            })
            ->values();

        $selectedMarketing = null;

        if ($selectedId > 0) {
            $marketing = User::query()->where('role', 'marketing')->find($selectedId);

            if ($marketing) {
                $todayAttendance = Attendance::query()
                    ->where('user_id', $marketing->id_user)
                    ->whereDate('attendance_date', now()->toDateString())
                    ->first();
                $latestLocation = MarketingLocation::query()
                    ->where('user_id', $marketing->id_user)
                    ->latest('recorded_at')
                    ->first();
                $todayOnhands = ProductOnhand::query()
                    ->where('user_id', $marketing->id_user)
                    ->whereDate('assignment_date', now()->toDateString())
                    ->orderByDesc('id_product_onhand')
                    ->get();

                $selectedMarketing = [
                    'id_user' => $marketing->id_user,
                    'nama' => $marketing->nama,
                    'status' => $marketing->status,
                    'today_attendance' => $todayAttendance ? [
                        'status' => $todayAttendance->status,
                        'check_in' => $todayAttendance->check_in,
                        'check_out' => $todayAttendance->check_out,
                        'notes' => $todayAttendance->notes,
                    ] : null,
                    'latest_location' => $latestLocation ? [
                        'latitude' => $latestLocation->latitude,
                        'longitude' => $latestLocation->longitude,
                        'recorded_at' => optional($latestLocation->recorded_at)->format('Y-m-d H:i:s'),
                        'source' => $latestLocation->source,
                        'map_url' => $this->mapUrl((float) $latestLocation->latitude, (float) $latestLocation->longitude),
                    ] : null,
                    'carried_items' => $todayOnhands->map(function (ProductOnhand $onhand) {
                        return [
                            'id_product_onhand' => $onhand->id_product_onhand,
                            'nama_product' => $onhand->nama_product,
                            'quantity' => (int) $onhand->quantity,
                            'quantity_dikembalikan' => (int) $onhand->quantity_dikembalikan,
                            'remaining_quantity' => $this->remainingForOnhand($onhand),
                            'take_status' => $onhand->take_status,
                            'return_status' => $onhand->return_status,
                            'assignment_date' => optional($onhand->assignment_date)->format('Y-m-d'),
                        ];
                    })->values(),
                ];
            }
        }

        return Inertia::render('Marketing/Index', [
            'filters' => ['search' => $search, 'selected' => $selectedId ?: null],
            'marketers' => $marketers,
            'selectedMarketing' => $selectedMarketing,
            'statuses' => ['aktif', 'nonaktif'],
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        $validated = $request->validate([
            'nama' => ['required', 'string', 'max:255', 'unique:users,nama'],
            'status' => ['required', Rule::in(['aktif', 'nonaktif'])],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        User::create([
            'nama' => $validated['nama'],
            'status' => $validated['status'],
            'role' => 'marketing',
            'password' => $validated['password'],
            'created_at' => now(),
        ]);

        return redirect()->route('marketing.index')->with('success', 'Akun marketing berhasil ditambahkan.');
    }

    public function update(Request $request, User $user): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);
        abort_unless($user->role === 'marketing', 404);

        $validated = $request->validate([
            'nama' => ['required', 'string', 'max:255', Rule::unique('users', 'nama')->ignore($user->id_user, 'id_user')],
            'status' => ['required', Rule::in(['aktif', 'nonaktif'])],
            'password' => ['nullable', 'string', 'min:8', 'confirmed'],
        ]);

        if (empty($validated['password'])) {
            unset($validated['password']);
        }

        $user->update($validated);

        return redirect()->route('marketing.index', ['selected' => $user->id_user])->with('success', 'Akun marketing berhasil diperbarui.');
    }

    public function destroy(Request $request, User $user): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);
        abort_unless($user->role === 'marketing', 404);

        $user->delete();

        return redirect()->route('marketing.index')->with('success', 'Akun marketing berhasil dihapus.');
    }

    private function remainingForOnhand(ProductOnhand $onhand): int
    {
        if ($onhand->take_status !== 'disetujui') {
            return 0;
        }

        $sold = (int) OfflineSale::query()
            ->where('id_product_onhand', $onhand->id_product_onhand)
            ->where('approval_status', '!=', 'ditolak')
            ->sum('quantity');

        $returned = in_array($onhand->return_status, ['pending', 'disetujui'], true)
            ? (int) $onhand->quantity_dikembalikan
            : 0;

        return max((int) $onhand->quantity - $sold - $returned, 0);
    }

    private function mapUrl(float $latitude, float $longitude): string
    {
        $bbox = implode(',', [
            $longitude - 0.01,
            $latitude - 0.01,
            $longitude + 0.01,
            $latitude + 0.01,
        ]);

        return "https://www.openstreetmap.org/export/embed.html?bbox={$bbox}&layer=mapnik&marker={$latitude},{$longitude}";
    }
}
