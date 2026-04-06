<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\MarketingLocation;
use App\Models\OfflineSale;
use App\Models\ProductOnhand;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use App\Support\ProductOnhandStock;
use Inertia\Inertia;
use Inertia\Response;

class MarketingAttendanceController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless($request->user()->role === 'marketing', 403);

        $user = $request->user();
        $start = Carbon::now()->startOfMonth()->toDateString();
        $end = Carbon::now()->endOfMonth()->toDateString();
        $attendanceQuery = Attendance::query()
            ->where('user_id', $user->id_user)
            ->whereBetween('attendance_date', [$start, $end]);
        $today = Attendance::query()
            ->where('user_id', $user->id_user)
            ->whereDate('attendance_date', now()->toDateString())
            ->first();

        $recentAttendances = Attendance::query()
            ->where('user_id', $user->id_user)
            ->latest('attendance_date')
            ->limit(8)
            ->get()
            ->map(fn (Attendance $attendance) => [
                'id' => $attendance->id,
                'attendance_date' => optional($attendance->attendance_date)->format('Y-m-d'),
                'check_in' => $attendance->check_in,
                'check_out' => $attendance->check_out,
                'status' => $attendance->status,
                'notes' => $attendance->notes,
                'check_in_location' => $attendance->check_in_latitude && $attendance->check_in_longitude ? $attendance->check_in_latitude . ', ' . $attendance->check_in_longitude : '-',
                'check_out_location' => $attendance->check_out_latitude && $attendance->check_out_longitude ? $attendance->check_out_latitude . ', ' . $attendance->check_out_longitude : '-',
            ]);

        $todayOnhands = ProductOnhand::query()
            ->where('user_id', $user->id_user)
            ->whereDate('assignment_date', now()->toDateString())
            ->where('take_status', 'disetujui')
            ->orderByDesc('id_product_onhand')
            ->get()
            ->map(fn (ProductOnhand $onhand) => $this->transformOnhand($onhand))
            ->values();

        return Inertia::render('Marketing/Attendance', [
            'kpis' => [
                ['label' => 'Absensi Bulan Ini', 'value' => (clone $attendanceQuery)->count()],
                ['label' => 'Terlambat', 'value' => (clone $attendanceQuery)->where('status', 'terlambat')->count()],
                ['label' => 'Izin', 'value' => (clone $attendanceQuery)->where('status', 'izin')->count()],
                ['label' => 'Sakit', 'value' => (clone $attendanceQuery)->where('status', 'sakit')->count()],
            ],
            'todayAttendance' => $today ? [
                'date' => optional($today->attendance_date)->format('Y-m-d'),
                'status' => $today->status,
                'check_in' => $today->check_in,
                'check_out' => $today->check_out,
                'check_in_location' => $today->check_in_latitude && $today->check_in_longitude ? $today->check_in_latitude . ', ' . $today->check_in_longitude : '-',
                'check_out_location' => $today->check_out_latitude && $today->check_out_longitude ? $today->check_out_latitude . ', ' . $today->check_out_longitude : '-',
            ] : null,
            'recentAttendances' => $recentAttendances,
            'carriedProducts' => $todayOnhands,
            'latestLocation' => Inertia::defer(fn () => optional(MarketingLocation::query()
                ->where('user_id', $user->id_user)
                ->latest('recorded_at')
                ->first(), fn ($location) => [
                    'latitude' => $location->latitude,
                    'longitude' => $location->longitude,
                    'recorded_at' => optional($location->recorded_at)->format('Y-m-d H:i:s'),
                    'source' => $location->source,
                    'map_url' => $this->mapUrl((float) $location->latitude, (float) $location->longitude),
                ])),
        ]);
    }

    public function checkIn(Request $request): RedirectResponse
    {
        return $this->storeAttendanceEvent($request, 'check_in');
    }

    public function checkOut(Request $request): RedirectResponse
    {
        abort_unless($request->user()->role === 'marketing', 403);

        $blockingItems = ProductOnhand::query()
            ->with('user')
            ->where('user_id', $request->user()->id_user)
            ->whereDate('assignment_date', now()->toDateString())
            ->where('take_status', 'disetujui')
            ->get()
            ->filter(fn (ProductOnhand $onhand) => ! $this->stateForOnhand($onhand)['can_checkout'])
            ->values();

        if ($blockingItems->isNotEmpty()) {
            return back()->withErrors(['checkout' => 'Barang belum dikembalikan']);
        }

        return $this->storeAttendanceEvent($request, 'check_out');
    }

    public function storeLocation(Request $request): RedirectResponse
    {
        abort_unless($request->user()->role === 'marketing', 403);

        $validated = $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'source' => ['required', 'in:heartbeat,check_in,check_out'],
        ]);

        MarketingLocation::create([
            'user_id' => $request->user()->id_user,
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'source' => $validated['source'],
            'recorded_at' => now(),
        ]);

        return back(303);
    }

    private function storeAttendanceEvent(Request $request, string $event): RedirectResponse
    {
        abort_unless($request->user()->role === 'marketing', 403);

        $validated = $request->validate([
            'status' => ['required', 'in:hadir,terlambat,izin,sakit'],
            'notes' => ['nullable', 'string', 'max:500'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
        ]);

        $now = now();
        $attendance = Attendance::query()->firstOrNew([
            'user_id' => $request->user()->id_user,
            'attendance_date' => $now->toDateString(),
        ]);

        if (! $attendance->exists) {
            $attendance->created_at = $now;
        }

        if ($event === 'check_in') {
            if ($attendance->check_out) {
                return back()->withErrors(['checkin' => 'Anda sudah check in dan check out hari ini. Tidak bisa check in lagi.']);
            }

            if ($attendance->check_in) {
                return back()->withErrors(['checkin' => 'Anda sudah check in hari ini.']);
            }
        }

        if ($event === 'check_out' && ! $attendance->check_in) {
            return back()->withErrors(['checkout' => 'Harus check in terlebih dahulu sebelum check out.']);
        }

        $attendance->status = $validated['status'];
        $attendance->notes = $validated['notes'] ?? null;

        if ($event === 'check_in') {
            $attendance->check_in = $now->format('H:i:s');
            $attendance->check_in_latitude = $validated['latitude'];
            $attendance->check_in_longitude = $validated['longitude'];
        }

        if ($event === 'check_out') {
            $attendance->check_out = $now->format('H:i:s');
            $attendance->check_out_latitude = $validated['latitude'];
            $attendance->check_out_longitude = $validated['longitude'];
        }

        $attendance->save();

        MarketingLocation::create([
            'user_id' => $request->user()->id_user,
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'source' => $event,
            'recorded_at' => $now,
        ]);

        return redirect()->route('marketing.attendance.index')->with('success', $event === 'check_in' ? 'Check in berhasil disimpan.' : 'Check out berhasil disimpan.');
    }

    private function transformOnhand(ProductOnhand $onhand): array
    {
        $state = $this->stateForOnhand($onhand);
        $approvedReturnQuantity = ProductOnhandStock::approvedReturnQuantity($onhand);
        $pendingReturnQuantity = ProductOnhandStock::pendingReturnQuantity($onhand);

        return [
            'id_product_onhand' => $onhand->id_product_onhand,
            'nama_product' => $onhand->nama_product,
            'quantity' => (int) $onhand->quantity,
            'sold_quantity' => $state['sold_quantity'],
            'quantity_dikembalikan' => $approvedReturnQuantity + $pendingReturnQuantity,
            'return_status' => $onhand->return_status,
            'status_label' => $state['status_label'],
            'remaining_quantity' => $state['remaining_quantity'],
            'assignment_date' => optional($onhand->assignment_date)->format('Y-m-d'),
        ];
    }

    private function stateForOnhand(ProductOnhand $onhand): array
    {
        $soldQuantity = ProductOnhandStock::soldQuantity($onhand);
        $approvedReturnQuantity = ProductOnhandStock::approvedReturnQuantity($onhand);
        $pendingReturnQuantity = ProductOnhandStock::pendingReturnQuantity($onhand);
        $soldOut = $soldQuantity >= (int) $onhand->quantity;
        $remainingQuantity = ProductOnhandStock::availableQuantity($onhand);
        $requiresReturn = (bool) ($onhand->user?->require_return_before_checkout ?? true)
            && ! $soldOut
            && ((int) $onhand->quantity - $soldQuantity - $approvedReturnQuantity) > 0;
        $canCheckout = ! $requiresReturn || (($soldQuantity + $approvedReturnQuantity) >= (int) $onhand->quantity);
        $statusLabel = $soldOut
            ? 'Habis Terjual'
            : ($approvedReturnQuantity > 0 && $remainingQuantity === 0
                ? 'Dikembalikan'
                : ($approvedReturnQuantity > 0
                    ? 'Sebagian Dikembalikan'
                    : $this->returnStatusLabel($onhand->return_status)));

        return [
            'sold_quantity' => $soldQuantity,
            'remaining_quantity' => $remainingQuantity,
            'can_checkout' => $canCheckout,
            'status_label' => $statusLabel,
        ];
    }

    private function returnStatusLabel(string $status): string
    {
        return match ($status) {
            'belum' => 'Belum Dikembalikan',
            'pending' => 'Pending',
            'tidak_disetujui' => 'Tidak Disetujui',
            'disetujui' => 'Dikembalikan',
            default => $status,
        };
    }

    private function mapUrl(float $latitude, float $longitude): string
    {
        $bbox = implode(',', [$longitude - 0.01, $latitude - 0.01, $longitude + 0.01, $latitude + 0.01]);
        return "https://www.openstreetmap.org/export/embed.html?bbox={$bbox}&layer=mapnik&marker={$latitude},{$longitude}";
    }
}

