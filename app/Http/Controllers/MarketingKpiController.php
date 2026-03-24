<?php

namespace App\Http\Controllers;

use App\Models\Area;
use App\Models\Attendance;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;
use Inertia\Response;

class MarketingKpiController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless($request->user()->role === 'marketing', 403);

        $user = $request->user();
        $start = Carbon::now()->startOfMonth()->toDateString();
        $end = Carbon::now()->endOfMonth()->toDateString();

        $attendanceQuery = Attendance::query()
            ->with('area:id,name,region,target_visits')
            ->where('user_id', $user->id_user)
            ->whereBetween('attendance_date', [$start, $end]);

        $attendanceCount = (clone $attendanceQuery)->count();
        $lateCount = (clone $attendanceQuery)->where('status', 'terlambat')->count();
        $izinCount = (clone $attendanceQuery)->where('status', 'izin')->count();
        $coveredAreas = (clone $attendanceQuery)->distinct('area_id')->count('area_id');
        $activeAreas = Area::query()->where('active', true)->count();

        $recentAttendances = Attendance::query()
            ->with('area:id,name,region,target_visits')
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
                'area' => [
                    'name' => $attendance->area?->name,
                    'region' => $attendance->area?->region,
                ],
            ]);

        return Inertia::render('Marketing/Kpi', [
            'kpis' => [
                ['label' => 'Absensi Bulan Ini', 'value' => $attendanceCount],
                ['label' => 'Tepat Waktu', 'value' => max($attendanceCount - $lateCount - $izinCount, 0)],
                ['label' => 'Terlambat', 'value' => $lateCount],
                ['label' => 'Coverage Area', 'value' => $activeAreas > 0 ? round(($coveredAreas / $activeAreas) * 100) . '%' : '0%'],
            ],
            'summary' => [
                'coveredAreas' => $coveredAreas,
                'activeAreas' => $activeAreas,
                'izinCount' => $izinCount,
            ],
            'areas' => Area::query()
                ->where('active', true)
                ->orderBy('name')
                ->get(['id', 'name', 'region', 'target_visits']),
            'recentAttendances' => $recentAttendances,
            'areaPerformance' => Inertia::defer(fn () => Attendance::query()
                ->select('areas.name', 'areas.region', DB::raw('COUNT(attendances.id) as total_visits'))
                ->join('areas', 'areas.id', '=', 'attendances.area_id')
                ->where('attendances.user_id', $user->id_user)
                ->whereBetween('attendances.attendance_date', [$start, $end])
                ->groupBy('areas.name', 'areas.region')
                ->orderByDesc('total_visits')
                ->get()
                ->map(fn ($row) => [
                    'name' => $row->name,
                    'region' => $row->region,
                    'total_visits' => (int) $row->total_visits,
                ])
                ->values()),
        ]);
    }

    public function storeAttendance(Request $request): RedirectResponse
    {
        abort_unless($request->user()->role === 'marketing', 403);

        $validated = $request->validate([
            'area_id' => ['required', 'exists:areas,id'],
            'attendance_date' => ['required', 'date'],
            'check_in' => ['required', 'date_format:H:i'],
            'check_out' => ['nullable', 'date_format:H:i'],
            'status' => ['required', 'in:hadir,terlambat,izin'],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);

        Attendance::updateOrCreate(
            [
                'user_id' => $request->user()->id_user,
                'area_id' => $validated['area_id'],
                'attendance_date' => $validated['attendance_date'],
            ],
            $validated + ['user_id' => $request->user()->id_user, 'created_at' => now()]
        );

        return redirect()->route('marketing.kpi')->with('success', 'Absensi marketing berhasil disimpan.');
    }
}