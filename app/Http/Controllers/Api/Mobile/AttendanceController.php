<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\MarketingLocation;
use App\Models\ProductOnhand;
use App\Support\MarketingMobileSupport;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user?->role === 'marketing', 403);

        $context = MarketingMobileSupport::attendanceContext($user);
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
            ])
            ->values();

        $todayOnhands = ProductOnhand::query()
            ->with('user')
            ->where('user_id', $user->id_user)
            ->whereDate('assignment_date', now()->toDateString())
            ->where('take_status', 'disetujui')
            ->orderByDesc('id_product_onhand')
            ->get()
            ->map(fn (ProductOnhand $onhand) => MarketingMobileSupport::transformOnhand($onhand))
            ->values();

        $latestLocation = optional(MarketingLocation::query()
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
        $blockingItems = ProductOnhand::query()
            ->with('user')
            ->where('user_id', $request->user()->id_user)
            ->whereDate('assignment_date', now()->toDateString())
            ->where('take_status', 'disetujui')
            ->get()
            ->filter(fn (ProductOnhand $onhand) => ! MarketingMobileSupport::stateForOnhand($onhand)['can_checkout'])
            ->values();

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
}
