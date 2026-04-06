<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\MarketingBonusAdjustment;
use App\Models\MarketingLocation;
use App\Models\OfflineSale;
use App\Models\ProductOnhand;
use App\Models\SalesTarget;
use App\Models\User;
use App\Support\MarketingBonusSupport;
use App\Support\ProductOnhandStock;
use Carbon\Carbon;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
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
        [$periodStart, $periodEnd, $periodFilters] = $this->resolvePeriod($request);

        $marketers = User::query()
            ->where('role', 'marketing')
            ->when($search !== '', fn ($query) => $query->where('nama', 'like', "%{$search}%"))
            ->orderBy('nama')
            ->get(['id_user', 'nama', 'status', 'created_at'])
            ->map(function (User $marketing) use ($periodStart, $periodEnd) {
                $todayAttendance = Attendance::query()
                    ->where('user_id', $marketing->id_user)
                    ->whereDate('attendance_date', now()->toDateString())
                    ->first();

                return [
                    'id_user' => $marketing->id_user,
                    'nama' => $marketing->nama,
                    'status' => $marketing->status,
                    'require_return_before_checkout' => (bool) $marketing->require_return_before_checkout,
                    'created_at' => optional($marketing->created_at)->format('Y-m-d H:i:s'),
                    'today_status' => $todayAttendance?->status ?? 'belum absen',
                    'kpi' => $this->buildMarketingKpi($marketing->id_user, $periodStart, $periodEnd),
                    'carried_items' => $this->activeCarriedItems($marketing->id_user),
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

                $selectedMarketing = [
                    'id_user' => $marketing->id_user,
                    'nama' => $marketing->nama,
                    'status' => $marketing->status,
                    'require_return_before_checkout' => (bool) $marketing->require_return_before_checkout,
                    'today_attendance' => $todayAttendance ? [
                        'status' => $todayAttendance->status,
                        'check_in' => $todayAttendance->check_in,
                        'check_out' => $todayAttendance->check_out,
                        'notes' => $todayAttendance->notes,
                    ] : null,
                    'current_kpi' => $this->buildMarketingKpi($marketing->id_user, $periodStart, $periodEnd),
                    'bonus_summary' => MarketingBonusSupport::buildTargetSummary(
                        $marketing,
                        $periodStart,
                        $periodEnd,
                        SalesTarget::query()->firstWhere('role', 'marketing')
                    ),
                    'kpi_history' => $this->buildKpiHistory($marketing->id_user, $periodStart),
                    'latest_location' => $latestLocation ? [
                        'latitude' => $latestLocation->latitude,
                        'longitude' => $latestLocation->longitude,
                        'recorded_at' => optional($latestLocation->recorded_at)->format('Y-m-d H:i:s'),
                        'source' => $latestLocation->source,
                        'map_url' => $this->mapUrl((float) $latestLocation->latitude, (float) $latestLocation->longitude),
                    ] : null,
                    'carried_items' => $this->activeCarriedItems($marketing->id_user),
                ];
            }
        }

        return Inertia::render('Marketing/Index', [
            'filters' => [
                'search' => $search,
                'selected' => $selectedId ?: null,
                'month' => $periodFilters['month'],
                'year' => $periodFilters['year'],
            ],
            'marketers' => $marketers,
            'selectedMarketing' => $selectedMarketing,
            'statuses' => ['aktif', 'nonaktif'],
            'periodFilters' => $periodFilters,
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

    public function show(Request $request, User $user): JsonResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);
        abort_unless($user->role === 'marketing', 404);

        [$periodStart] = $this->resolvePeriod($request);
        $todayAttendance = Attendance::query()
            ->where('user_id', $user->id_user)
            ->whereDate('attendance_date', now()->toDateString())
            ->first();
        $latestLocation = MarketingLocation::query()
            ->where('user_id', $user->id_user)
            ->latest('recorded_at')
            ->first();

        return response()->json([
            'id_user' => $user->id_user,
            'nama' => $user->nama,
            'status' => $user->status,
            'require_return_before_checkout' => (bool) $user->require_return_before_checkout,
            'today_attendance' => $todayAttendance ? [
                'status' => $todayAttendance->status,
                'check_in' => $todayAttendance->check_in,
                'check_out' => $todayAttendance->check_out,
                'notes' => $todayAttendance->notes,
            ] : null,
            'current_kpi' => $this->buildMarketingKpi($user->id_user, $periodStart, $periodStart->copy()->endOfMonth()),
            'bonus_summary' => MarketingBonusSupport::buildTargetSummary(
                $user,
                $periodStart,
                $periodStart->copy()->endOfMonth(),
                SalesTarget::query()->firstWhere('role', 'marketing')
            ),
            'kpi_history' => $this->buildKpiHistory($user->id_user, $periodStart),
            'latest_location' => $latestLocation ? [
                'latitude' => $latestLocation->latitude,
                'longitude' => $latestLocation->longitude,
                'recorded_at' => optional($latestLocation->recorded_at)->format('Y-m-d H:i:s'),
                'source' => $latestLocation->source,
                'map_url' => $this->mapUrl((float) $latestLocation->latitude, (float) $latestLocation->longitude),
            ] : null,
            'carried_items' => $this->activeCarriedItems($user->id_user),
        ]);
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

    public function updateReturnPolicy(Request $request, User $user): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);
        abort_unless($user->role === 'marketing', 404);

        $validated = $request->validate([
            'require_return_before_checkout' => ['required', 'boolean'],
        ]);

        $user->update([
            'require_return_before_checkout' => (bool) $validated['require_return_before_checkout'],
        ]);

        return redirect()
            ->route('marketing.index', ['selected' => $user->id_user])
            ->with('success', 'Pengaturan pengembalian barang marketing berhasil diperbarui.');
    }

    public function storeManualBonus(Request $request, User $user): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);
        abort_unless($user->role === 'marketing', 404);

        $validated = $request->validate([
            'bonus_month' => ['required', 'date_format:Y-m'],
            'amount' => ['required', 'numeric', 'gt:0'],
            'note' => ['nullable', 'string', 'max:1000'],
        ]);

        $bonusMonth = Carbon::createFromFormat('Y-m', $validated['bonus_month'])->startOfMonth();

        MarketingBonusAdjustment::query()->create([
            'user_id' => $user->id_user,
            'created_by' => $request->user()->id_user,
            'bonus_month' => $bonusMonth->toDateString(),
            'amount' => (float) $validated['amount'],
            'note' => $validated['note'] ?? null,
        ]);

        return redirect()
            ->route('marketing.index', [
                'selected' => $user->id_user,
                'month' => $bonusMonth->month,
                'year' => $bonusMonth->year,
            ])
            ->with('success', 'Bonus manual marketing berhasil ditambahkan.');
    }

    private function transformOnhand(ProductOnhand $onhand): array
    {
        $state = $this->stateForOnhand($onhand);
        $approvedReturnQuantity = (int) ($onhand->approved_return_quantity ?? 0);
        $pendingReturnQuantity = $onhand->return_status === 'pending'
            ? (int) $onhand->quantity_dikembalikan
            : 0;

        return [
            'id_product_onhand' => $onhand->id_product_onhand,
            'nama_product' => $onhand->nama_product,
            'quantity' => (int) $onhand->quantity,
            'quantity_dikembalikan' => $approvedReturnQuantity + $pendingReturnQuantity,
            'remaining_quantity' => $state['remaining_quantity'],
            'take_status' => $onhand->take_status,
            'take_status_label' => $this->takeStatusLabel($onhand->take_status),
            'return_status' => $onhand->return_status,
            'status_label' => $state['status_label'],
            'assignment_date' => optional($onhand->assignment_date)->format('Y-m-d'),
        ];
    }

    private function activeCarriedItems(int $userId)
    {
        return ProductOnhand::query()
            ->where('user_id', $userId)
            ->orderByDesc('assignment_date')
            ->orderByDesc('id_product_onhand')
            ->get()
            ->map(fn (ProductOnhand $onhand) => $this->transformOnhand($onhand))
            ->filter(function (array $onhand) {
                if (($onhand['take_status'] ?? null) !== 'disetujui') {
                    return false;
                }

                return (int) ($onhand['remaining_quantity'] ?? 0) > 0
                    || (int) ($onhand['quantity_dikembalikan'] ?? 0) > 0
                    || ($onhand['return_status'] ?? null) === 'pending';
            })
            ->values();
    }

    private function stateForOnhand(ProductOnhand $onhand): array
    {
        if ($onhand->take_status !== 'disetujui') {
            return [
                'remaining_quantity' => 0,
                'status_label' => $this->takeStatusLabel($onhand->take_status),
            ];
        }

        $sold = ProductOnhandStock::soldQuantity($onhand);

        $approvedReturnQuantity = ProductOnhandStock::approvedReturnQuantity($onhand);
        $pendingReturnQuantity = ProductOnhandStock::pendingReturnQuantity($onhand);

        $remaining = ProductOnhandStock::availableQuantity($onhand);
        $soldOut = $sold >= (int) $onhand->quantity;
        $statusLabel = $this->returnStatusLabel($onhand->return_status);

        if ($soldOut) {
            $statusLabel = 'Habis Terjual';
        } elseif ($approvedReturnQuantity > 0 && $remaining === 0) {
            $statusLabel = 'Dikembalikan';
        } elseif ($approvedReturnQuantity > 0) {
            $statusLabel = 'Sebagian Dikembalikan';
        }

        return [
            'remaining_quantity' => $remaining,
            'status_label' => $statusLabel,
        ];
    }

    private function takeStatusLabel(string $status): string
    {
        return match ($status) {
            'pending' => 'Menunggu Persetujuan',
            'ditolak' => 'Request Ditolak',
            default => 'Disetujui',
        };
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
        $bbox = implode(',', [
            $longitude - 0.01,
            $latitude - 0.01,
            $longitude + 0.01,
            $latitude + 0.01,
        ]);

        return "https://www.openstreetmap.org/export/embed.html?bbox={$bbox}&layer=mapnik&marker={$latitude},{$longitude}";
    }

    private function buildMarketingKpi(int $userId, Carbon $periodStart, Carbon $periodEnd): array
    {
        $salesQuantity = (int) OfflineSale::query()
            ->where('id_user', $userId)
            ->where('approval_status', '!=', 'ditolak')
            ->whereBetween('created_at', [$periodStart->copy()->startOfDay(), $periodEnd->copy()->endOfDay()])
            ->sum('quantity');

        $attendances = Attendance::query()
            ->where('user_id', $userId)
            ->whereBetween('attendance_date', [$periodStart->toDateString(), $periodEnd->toDateString()])
            ->whereNotNull('check_in')
            ->get();

        $attendanceDays = $attendances->count();
        $totalHours = round($attendances->sum(function (Attendance $attendance) {
            if (! $attendance->check_in || ! $attendance->check_out) {
                return 0;
            }

            $checkIn = strtotime((string) $attendance->check_in);
            $checkOut = strtotime((string) $attendance->check_out);

            if ($checkIn === false || $checkOut === false) {
                return 0;
            }

            return max(($checkOut - $checkIn) / 3600, 0);
        }), 2);

        $salesTarget = (int) (SalesTarget::query()->firstWhere('role', 'marketing')?->monthly_target_qty ?? 100);
        $attendanceTarget = 24;
        $hoursTarget = 8;
        $averageHoursPerDay = $attendanceDays > 0 ? round($totalHours / $attendanceDays, 2) : 0.0;
        $salesScore = $salesTarget > 0 ? round(min(($salesQuantity / $salesTarget) * 100, 100) * 0.7, 2) : 0.0;
        $attendanceScore = round(min(($attendanceDays / $attendanceTarget) * 100, 100) * 0.2, 2);
        $hoursScore = round(min(($averageHoursPerDay / $hoursTarget) * 100, 100) * 0.1, 2);

        return [
            'quantity_sold' => $salesQuantity,
            'sales_target' => $salesTarget,
            'attendance_days' => $attendanceDays,
            'attendance_target' => $attendanceTarget,
            'total_hours' => $totalHours,
            'average_hours_per_day' => $averageHoursPerDay,
            'hours_target' => $hoursTarget,
            'sales_score' => $salesScore,
            'attendance_score' => $attendanceScore,
            'hours_score' => $hoursScore,
            'total_score' => round($salesScore + $attendanceScore + $hoursScore, 2),
        ];
    }

    private function buildKpiHistory(int $userId, Carbon $referenceMonth): array
    {
        return collect(range(0, 5))
            ->map(function (int $offset) use ($userId, $referenceMonth) {
                $monthStart = $referenceMonth->copy()->subMonths($offset)->startOfMonth();
                $monthEnd = $monthStart->copy()->endOfMonth();
                $kpi = $this->buildMarketingKpi($userId, $monthStart, $monthEnd);

                return [
                    'period_label' => $monthStart->copy()->locale('id')->translatedFormat('F Y'),
                    'quantity_sold' => $kpi['quantity_sold'],
                    'attendance_days' => $kpi['attendance_days'],
                    'total_hours' => $kpi['total_hours'],
                    'average_hours_per_day' => $kpi['average_hours_per_day'],
                    'total_score' => $kpi['total_score'],
                ];
            })
            ->values()
            ->all();
    }

    private function resolvePeriod(Request $request): array
    {
        $validated = $request->validate([
            'month' => ['nullable', 'integer', 'between:1,12'],
            'year' => ['nullable', 'integer', 'between:2020,2100'],
        ]);

        $selectedMonth = (int) ($validated['month'] ?? now()->month);
        $selectedYear = (int) ($validated['year'] ?? now()->year);
        $periodStart = Carbon::create($selectedYear, $selectedMonth, 1)->startOfMonth();
        $currentYear = now()->year;

        return [
            $periodStart,
            $periodStart->copy()->endOfMonth(),
            [
                'month' => $selectedMonth,
                'year' => $selectedYear,
                'period_label' => $periodStart->copy()->locale('id')->translatedFormat('F Y'),
                'months' => collect(range(1, 12))->map(fn (int $month) => ['value' => $month, 'label' => Carbon::create($selectedYear, $month, 1)->locale('id')->translatedFormat('F')])->all(),
                'years' => collect(range($currentYear - 5, $currentYear + 1))->map(fn (int $year) => ['value' => $year, 'label' => (string) $year])->all(),
            ],
        ];
    }
}

