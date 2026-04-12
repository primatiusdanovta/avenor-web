<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\MarketingLocation;
use App\Models\ProductOnhand;
use App\Support\MarketingMobileSupport;
use App\Support\SalesRole;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless(in_array($user?->role, SalesRole::mobileRoles(), true), 403);
        $storeId = MarketingMobileSupport::currentStoreId($user);

        if ($user->role === SalesRole::OWNER) {
            $selectedDate = Carbon::parse((string) $request->query('date', now()->toDateString()));
            $employeeAttendances = Attendance::query()
                ->with('user')
                ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
                ->whereDate('attendance_date', $selectedDate->toDateString())
                ->whereHas('user', fn ($query) => $query->whereIn('role', [
                    SalesRole::KARYAWAN,
                    SalesRole::MARKETING,
                    SalesRole::SALES_FIELD_EXECUTIVE,
                ]))
                ->orderBy('check_in')
                ->orderBy('attendance_date')
                ->get()
                ->map(fn (Attendance $attendance) => [
                    'id' => $attendance->id,
                    'employee_name' => $attendance->user?->nama,
                    'employee_role' => $attendance->user?->role,
                    'attendance_date' => optional($attendance->attendance_date)->format('Y-m-d'),
                    'check_in' => $attendance->check_in,
                    'check_out' => $attendance->check_out,
                    'status' => $attendance->status,
                    'notes' => $attendance->notes,
                    'late_minutes' => $this->resolveLateMinutes(
                        optional($attendance->attendance_date)->format('Y-m-d'),
                        $attendance->check_in
                    ),
                ])
                ->values();

            return response()->json([
                'selected_date' => $selectedDate->format('Y-m-d'),
                'employee_attendances' => $employeeAttendances,
                'today_attendance' => null,
                'recent_attendances' => [],
                'carried_products' => [],
                'latest_location' => null,
            ]);
        }

        $context = MarketingMobileSupport::attendanceContext($user);
        $recentAttendances = Attendance::query()
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
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
            ])
            ->values();

        $todayOnhands = MarketingMobileSupport::isSmoothiesSweetieUser($user)
            ? collect()
            : ProductOnhand::query()
                ->with('user')
                ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
                ->where('user_id', $user->id_user)
                ->whereDate('assignment_date', now()->toDateString())
                ->where('take_status', 'disetujui')
                ->orderByDesc('id_product_onhand')
                ->get()
                ->map(fn (ProductOnhand $onhand) => MarketingMobileSupport::transformOnhand($onhand))
                ->values();

        $latestLocation = optional(MarketingLocation::query()
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
            ->where('user_id', $user->id_user)
            ->latest('recorded_at')
            ->first(), fn ($location) => [
                'latitude' => $location->latitude,
                'longitude' => $location->longitude,
                'recorded_at' => optional($location->recorded_at)->format('Y-m-d H:i:s'),
                'source' => $location->source,
            ]);

        return response()->json([
            'today_attendance' => $context['todayAttendance'],
            'recent_attendances' => $recentAttendances,
            'carried_products' => $todayOnhands,
            'latest_location' => $latestLocation,
        ]);
    }

    public function checkIn(Request $request): JsonResponse
    {
        return $this->storeAttendanceEvent($request, 'check_in');
    }

    public function checkOut(Request $request): JsonResponse
    {
        $storeId = MarketingMobileSupport::currentStoreId($request->user());
        $blockingItems = SalesRole::defaultRequireReturnBeforeCheckout($request->user()->role)
            && ! MarketingMobileSupport::isSmoothiesSweetieUser($request->user())
            ? ProductOnhand::query()
                ->with('user')
                ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
                ->where('user_id', $request->user()->id_user)
                ->whereDate('assignment_date', now()->toDateString())
                ->where('take_status', 'disetujui')
                ->get()
                ->filter(fn (ProductOnhand $onhand) => ! MarketingMobileSupport::stateForOnhand($onhand)['can_checkout'])
                ->values()
            : collect();

        if ($blockingItems->isNotEmpty()) {
            return response()->json([
                'message' => 'Barang belum dikembalikan.',
            ], 422);
        }

        return $this->storeAttendanceEvent($request, 'check_out');
    }

    public function storeLocation(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'source' => ['required', 'in:heartbeat,check_in,check_out'],
        ]);

        MarketingLocation::create([
            'store_id' => MarketingMobileSupport::currentStoreId($request->user()),
            'user_id' => $request->user()->id_user,
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'source' => $validated['source'],
            'recorded_at' => now(),
        ]);

        return response()->json([
            'message' => 'Lokasi berhasil disimpan.',
        ], 201);
    }

    private function storeAttendanceEvent(Request $request, string $event): JsonResponse
    {
        if ($request->user()?->role === SalesRole::OWNER) {
            return response()->json([
                'message' => 'Owner hanya dapat melihat riwayat absensi karyawan di aplikasi mobile.',
            ], 422);
        }

        $validated = $request->validate([
            'status' => ['required', 'in:hadir,terlambat,izin,sakit'],
            'notes' => ['nullable', 'string', 'max:500'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
        ]);

        $now = now();
        $storeId = MarketingMobileSupport::currentStoreId($request->user());
        $attendance = Attendance::query()->firstOrNew([
            'store_id' => $storeId,
            'user_id' => $request->user()->id_user,
            'attendance_date' => $now->toDateString(),
        ]);

        if (! $attendance->exists) {
            $attendance->created_at = $now;
        }

        if ($event === 'check_in') {
            if ($attendance->check_out) {
                return response()->json(['message' => 'Anda sudah check in dan check out hari ini. Tidak bisa check in lagi.'], 422);
            }

            if ($attendance->check_in) {
                return response()->json(['message' => 'Anda sudah check in hari ini.'], 422);
            }
        }

        if ($event === 'check_out' && ! $attendance->check_in) {
            return response()->json(['message' => 'Harus check in terlebih dahulu sebelum check out.'], 422);
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
            'store_id' => $storeId,
            'user_id' => $request->user()->id_user,
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'source' => $event,
            'recorded_at' => $now,
        ]);

        return response()->json([
            'message' => $event === 'check_in' ? 'Check in berhasil disimpan.' : 'Check out berhasil disimpan.',
            'attendance' => [
                'date' => optional($attendance->attendance_date)->format('Y-m-d'),
                'status' => $attendance->status,
                'check_in' => $attendance->check_in,
                'check_out' => $attendance->check_out,
            ],
        ]);
    }

    private function resolveLateMinutes(?string $attendanceDate, ?string $checkIn): int
    {
        if (! $attendanceDate || ! $checkIn) {
            return 0;
        }

        $checkInAt = Carbon::parse($attendanceDate . ' ' . $checkIn);
        $shiftStart = Carbon::parse($attendanceDate . ' 09:00:00');

        return $checkInAt->greaterThan($shiftStart)
            ? $checkInAt->diffInMinutes($shiftStart)
            : 0;
    }
}

