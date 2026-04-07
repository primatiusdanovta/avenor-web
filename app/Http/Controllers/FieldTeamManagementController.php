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
use App\Support\SalesRole;
use Carbon\Carbon;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class FieldTeamManagementController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        $managedRole = $this->managedRole($request);
        $search = trim((string) $request->string('search'));
        $selectedId = (int) $request->integer('selected');
        [$periodStart, $periodEnd, $periodFilters] = $this->resolvePeriod($request);

        $fieldMembers = User::query()
            ->where('role', $managedRole)
            ->when($search !== '', fn ($query) => $query->where('nama', 'like', "%{$search}%"))
            ->orderBy('nama')
            ->get(['id_user', 'nama', 'status', 'created_at', 'role', 'require_return_before_checkout'])
            ->map(function (User $fieldMember) use ($periodStart, $periodEnd) {
                $todayAttendance = Attendance::query()
                    ->where('user_id', $fieldMember->id_user)
                    ->whereDate('attendance_date', now()->toDateString())
                    ->first();

                return [
                    'id_user' => $fieldMember->id_user,
                    'nama' => $fieldMember->nama,
                    'status' => $fieldMember->status,
                    'role' => $fieldMember->role,
                    'require_return_before_checkout' => (bool) $fieldMember->require_return_before_checkout,
                    'created_at' => optional($fieldMember->created_at)->format('Y-m-d H:i:s'),
                    'today_status' => $todayAttendance?->status ?? 'belum absen',
                    'kpi' => $this->buildMarketingKpi($fieldMember->id_user, $periodStart, $periodEnd, $fieldMember->role),
                    'carried_items' => $this->activeCarriedItems($fieldMember->id_user),
                    'movement_status' => $this->movementStatus($fieldMember->id_user),
                    'latest_location_summary' => $this->latestLocationSummary($fieldMember->id_user),
                ];
            })
            ->values();

        $selectedMember = null;

        if ($selectedId > 0) {
            $fieldMember = User::query()->where('role', $managedRole)->find($selectedId);

            if ($fieldMember) {
                $todayAttendance = Attendance::query()
                    ->where('user_id', $fieldMember->id_user)
                    ->whereDate('attendance_date', now()->toDateString())
                    ->first();
                $latestLocation = MarketingLocation::query()
                    ->where('user_id', $fieldMember->id_user)
                    ->latest('recorded_at')
                    ->first();

                $selectedMember = [
                    'id_user' => $fieldMember->id_user,
                    'nama' => $fieldMember->nama,
                    'status' => $fieldMember->status,
                    'role' => $fieldMember->role,
                    'require_return_before_checkout' => (bool) $fieldMember->require_return_before_checkout,
                    'movement_status' => $this->movementStatus($fieldMember->id_user),
                    'today_attendance' => $todayAttendance ? [
                        'status' => $todayAttendance->status,
                        'check_in' => $todayAttendance->check_in,
                        'check_out' => $todayAttendance->check_out,
                        'notes' => $todayAttendance->notes,
                    ] : null,
                    'current_kpi' => $this->buildMarketingKpi($fieldMember->id_user, $periodStart, $periodEnd, $fieldMember->role),
                    'bonus_summary' => MarketingBonusSupport::buildTargetSummary(
                        $fieldMember,
                        $periodStart,
                        $periodEnd,
                        SalesTarget::query()->firstWhere('role', $fieldMember->role)
                    ),
                    'kpi_history' => $this->buildKpiHistory($fieldMember->id_user, $periodStart, $fieldMember->role),
                    'latest_location' => $latestLocation ? [
                        'latitude' => $latestLocation->latitude,
                        'longitude' => $latestLocation->longitude,
                        'recorded_at' => optional($latestLocation->recorded_at)->format('Y-m-d H:i:s'),
                        'source' => $latestLocation->source,
                        'map_url' => $this->mapUrl((float) $latestLocation->latitude, (float) $latestLocation->longitude),
                    ] : null,
                    'carried_items' => $this->activeCarriedItems($fieldMember->id_user),
                ];
            }
        }

        return Inertia::render('FieldTeam/Index', [
            'filters' => [
                'search' => $search,
                'selected' => $selectedId ?: null,
                'month' => $periodFilters['month'],
                'year' => $periodFilters['year'],
                'role' => $managedRole,
            ],
            'fieldMembers' => $fieldMembers,
            'selectedMember' => $selectedMember,
            'statuses' => ['aktif', 'nonaktif'],
            'periodFilters' => $periodFilters,
            'entityLabel' => SalesRole::label($managedRole),
            'entityLabelPlural' => SalesRole::label($managedRole),
            'entityRole' => $managedRole,
            'roleOptions' => [
                ['value' => SalesRole::MARKETING, 'label' => SalesRole::label(SalesRole::MARKETING)],
                ['value' => SalesRole::SALES_FIELD_EXECUTIVE, 'label' => SalesRole::label(SalesRole::SALES_FIELD_EXECUTIVE)],
            ],
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        $managedRole = $this->managedRole($request);
        $validated = $request->validate([
            'nama' => ['required', 'string', 'max:255', 'unique:users,nama'],
            'status' => ['required', Rule::in(['aktif', 'nonaktif'])],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        User::create([
            'nama' => $validated['nama'],
            'status' => $validated['status'],
            'role' => $managedRole,
            'password' => $validated['password'],
            'require_return_before_checkout' => SalesRole::defaultRequireReturnBeforeCheckout($managedRole),
            'created_at' => now(),
        ]);

        return redirect()->route('field-team.index', ['role' => $managedRole])->with('success', SalesRole::label($managedRole) . ' berhasil ditambahkan.');
    }

    public function show(Request $request, User $user): JsonResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);
        abort_unless(SalesRole::isFieldRole($user->role), 404);

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
            'role' => $user->role,
            'require_return_before_checkout' => (bool) $user->require_return_before_checkout,
            'movement_status' => $this->movementStatus($user->id_user),
            'today_attendance' => $todayAttendance ? [
                'status' => $todayAttendance->status,
                'check_in' => $todayAttendance->check_in,
                'check_out' => $todayAttendance->check_out,
                'notes' => $todayAttendance->notes,
            ] : null,
            'current_kpi' => $this->buildMarketingKpi($user->id_user, $periodStart, $periodStart->copy()->endOfMonth(), $user->role),
            'bonus_summary' => MarketingBonusSupport::buildTargetSummary(
                $user,
                $periodStart,
                $periodStart->copy()->endOfMonth(),
                SalesTarget::query()->firstWhere('role', $user->role)
            ),
            'kpi_history' => $this->buildKpiHistory($user->id_user, $periodStart, $user->role),
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
        abort_unless(SalesRole::isFieldRole($user->role), 404);

        $validated = $request->validate([
            'nama' => ['required', 'string', 'max:255', Rule::unique('users', 'nama')->ignore($user->id_user, 'id_user')],
            'status' => ['required', Rule::in(['aktif', 'nonaktif'])],
            'password' => ['nullable', 'string', 'min:8', 'confirmed'],
        ]);

        if (empty($validated['password'])) {
            unset($validated['password']);
        }

        $user->update($validated);

        return redirect()->route('field-team.index', ['selected' => $user->id_user, 'role' => $user->role])->with('success', SalesRole::label($user->role) . ' berhasil diperbarui.');
    }

    public function destroy(Request $request, User $user): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);
        abort_unless(SalesRole::isFieldRole($user->role), 404);

        $role = $user->role;
        $user->delete();

        return redirect()->route('field-team.index', ['role' => $role])->with('success', SalesRole::label($role) . ' berhasil dihapus.');
    }

    public function updateReturnPolicy(Request $request, User $user): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);
        abort_unless(SalesRole::isFieldRole($user->role), 404);

        $validated = $request->validate([
            'require_return_before_checkout' => ['required', 'boolean'],
        ]);

        $user->update([
            'require_return_before_checkout' => (bool) $validated['require_return_before_checkout'],
        ]);

        return redirect()
            ->route('field-team.index', ['selected' => $user->id_user, 'role' => $user->role])
            ->with('success', 'Pengaturan pengembalian barang berhasil diperbarui.');
    }

    public function storeManualBonus(Request $request, User $user): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);
        abort_unless(SalesRole::isFieldRole($user->role), 404);

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
            ->route('field-team.index', [
                'selected' => $user->id_user,
                'month' => $bonusMonth->month,
                'year' => $bonusMonth->year,
                'role' => $user->role,
            ])
            ->with('success', 'Bonus manual berhasil ditambahkan.');
    }

    private function latestLocationSummary(int $userId): ?array
    {
        $latestLocation = MarketingLocation::query()
            ->where('user_id', $userId)
            ->latest('recorded_at')
            ->first();

        if (! $latestLocation) {
            return null;
        }

        return [
            'recorded_at' => optional($latestLocation->recorded_at)->format('Y-m-d H:i:s'),
            'source' => $latestLocation->source,
            'latitude' => (float) $latestLocation->latitude,
            'longitude' => (float) $latestLocation->longitude,
        ];
    }

    private function movementStatus(int $userId): array
    {
        $locations = MarketingLocation::query()
            ->where('user_id', $userId)
            ->where('recorded_at', '>=', now()->subMinutes(30))
            ->orderBy('recorded_at')
            ->get();

        $latest = $locations->last();
        $first = $locations->first();
        $moving = false;

        if ($latest && $first) {
            $moving = abs((float) $latest->latitude - (float) $first->latitude) > 0.0003
                || abs((float) $latest->longitude - (float) $first->longitude) > 0.0003;
        }

        return [
            'label' => $moving ? 'Bergerak' : 'Tidak Bergerak',
            'recorded_at' => optional($latest?->recorded_at)->format('Y-m-d H:i:s'),
            'samples' => $locations->count(),
        ];
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
            'pickup_batch_code' => $onhand->pickup_batch_code,
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

    private function buildMarketingKpi(int $userId, Carbon $periodStart, Carbon $periodEnd, string $role): array
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

        $salesTarget = (int) (SalesTarget::query()->firstWhere('role', $role)?->monthly_target_qty ?? 100);
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

    private function buildKpiHistory(int $userId, Carbon $referenceMonth, string $role): array
    {
        return collect(range(0, 5))
            ->map(function (int $offset) use ($userId, $referenceMonth, $role) {
                $monthStart = $referenceMonth->copy()->subMonths($offset)->startOfMonth();
                $monthEnd = $monthStart->copy()->endOfMonth();
                $kpi = $this->buildMarketingKpi($userId, $monthStart, $monthEnd, $role);

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

    private function managedRole(Request $request): string
    {
        $role = trim((string) $request->string('role')) ?: SalesRole::MARKETING;

        abort_unless(in_array($role, SalesRole::managedRoles(), true), 404);

        return $role;
    }
}


