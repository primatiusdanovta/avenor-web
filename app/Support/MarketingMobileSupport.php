<?php

namespace App\Support;

use App\Models\Attendance;
use App\Models\OfflineSale;
use App\Models\ProductOnhand;
use App\Models\SalesTarget;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class MarketingMobileSupport
{
    public static function attendanceContext(User $user): array
    {
        $todayAttendance = Attendance::query()
            ->where('user_id', $user->id_user)
            ->whereDate('attendance_date', now()->toDateString())
            ->first();

        $attendanceReady = (bool) $todayAttendance?->check_in && ! $todayAttendance?->check_out;
        $attendanceBlockedReason = null;

        if (! $todayAttendance?->check_in) {
            $attendanceBlockedReason = 'Marketing wajib check in terlebih dahulu sebelum mengambil barang.';
        } elseif ($todayAttendance?->check_out) {
            $attendanceBlockedReason = 'Marketing yang sudah check out tidak bisa request barang lagi hari ini.';
        }

        return [
            'attendanceReady' => $attendanceReady,
            'attendanceBlockedReason' => $attendanceBlockedReason,
            'todayAttendance' => $todayAttendance ? [
                'status' => $todayAttendance->status,
                'check_in' => $todayAttendance->check_in,
                'check_out' => $todayAttendance->check_out,
                'check_in_location' => $todayAttendance->check_in_latitude && $todayAttendance->check_in_longitude
                    ? $todayAttendance->check_in_latitude . ', ' . $todayAttendance->check_in_longitude
                    : '-',
                'check_out_location' => $todayAttendance->check_out_latitude && $todayAttendance->check_out_longitude
                    ? $todayAttendance->check_out_latitude . ', ' . $todayAttendance->check_out_longitude
                    : '-',
            ] : null,
        ];
    }

    public static function buildMarketingKpi(int $userId, Carbon $periodStart, Carbon $periodEnd): array
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

    public static function buildTargetSummary(User $user, Carbon $periodStart, Carbon $periodEnd): array
    {
        $today = now()->startOfDay();
        $effectiveEnd = $periodEnd->copy()->startOfDay()->gt($today) ? $today->copy() : $periodEnd->copy()->startOfDay();
        $target = SalesTarget::query()->firstWhere('role', 'marketing');

        $sales = OfflineSale::query()
            ->where('id_user', $user->id_user)
            ->where('approval_status', '!=', 'ditolak')
            ->whereBetween('created_at', [$periodStart->copy()->startOfDay(), $effectiveEnd->copy()->endOfDay()])
            ->get();

        $dailyTargetQty = (int) ($target?->daily_target_qty ?? 0);
        $weeklyTargetQty = (int) ($target?->weekly_target_qty ?? 0);
        $monthlyTargetQty = (int) ($target?->monthly_target_qty ?? 0);
        $dailyBonus = (float) ($target?->daily_bonus ?? 0);
        $weeklyBonus = (float) ($target?->weekly_bonus ?? 0);
        $monthlyBonus = (float) ($target?->monthly_bonus ?? 0);

        $dailyTotals = $sales->groupBy(fn (OfflineSale $sale) => optional($sale->created_at)->toDateString())
            ->map(fn (Collection $items) => (int) $items->sum('quantity'));
        $periodDayCount = $periodStart->copy()->startOfDay()->gt($effectiveEnd) ? 0 : $periodStart->copy()->startOfDay()->diffInDays($effectiveEnd) + 1;
        $dailyAchievedCount = $dailyTargetQty > 0 ? $dailyTotals->filter(fn (int $quantity) => $quantity >= $dailyTargetQty)->count() : 0;

        $weeklyPeriods = self::buildWeeklyPeriods($periodStart, $effectiveEnd);
        $weeklyAchievedCount = 0;

        foreach ($weeklyPeriods as $period) {
            $weekQuantity = (int) $sales
                ->filter(fn (OfflineSale $sale) => optional($sale->created_at)?->betweenIncluded($period['start'], $period['end']))
                ->sum('quantity');
            if ($weeklyTargetQty > 0 && $weekQuantity >= $weeklyTargetQty) {
                $weeklyAchievedCount++;
            }
        }

        $monthlyQuantity = (int) $sales->sum('quantity');
        $monthlyMet = $monthlyTargetQty > 0 && $monthlyQuantity >= $monthlyTargetQty;
        $todayQuantity = (int) ($dailyTotals[now()->toDateString()] ?? 0);
        $isCurrentMonth = $periodStart->isSameMonth(now()) && $periodStart->isSameYear(now());
        $bonusTotal = ($dailyAchievedCount * $dailyBonus) + ($weeklyAchievedCount * $weeklyBonus) + ($monthlyMet ? $monthlyBonus : 0);

        return [
            'period_label' => $periodStart->copy()->locale('id')->translatedFormat('F Y'),
            'daily' => [
                'target_qty' => $dailyTargetQty,
                'achieved_count' => $dailyAchievedCount,
                'total_periods' => $periodDayCount,
                'bonus' => round($dailyAchievedCount * $dailyBonus, 2),
            ],
            'weekly' => [
                'target_qty' => $weeklyTargetQty,
                'achieved_count' => $weeklyAchievedCount,
                'total_periods' => count($weeklyPeriods),
                'bonus' => round($weeklyAchievedCount * $weeklyBonus, 2),
            ],
            'monthly' => [
                'target_qty' => $monthlyTargetQty,
                'total_quantity' => $monthlyQuantity,
                'met' => $monthlyMet,
                'bonus' => $monthlyMet ? round($monthlyBonus, 2) : 0,
            ],
            'bonus_total' => round($bonusTotal, 2),
            'reminder' => $isCurrentMonth && $dailyTargetQty > 0 && $todayQuantity < $dailyTargetQty
                ? sprintf('Target anda %d/%d, Penuhi Target anda hari ini!', $todayQuantity, $dailyTargetQty)
                : null,
        ];
    }

    public static function transformOnhand(ProductOnhand $onhand): array
    {
        $state = self::stateForOnhand($onhand);

        return [
            'id_product_onhand' => $onhand->id_product_onhand,
            'id_product' => $onhand->id_product,
            'nama_product' => $onhand->nama_product,
            'quantity' => (int) $onhand->quantity,
            'quantity_dikembalikan' => (int) $onhand->quantity_dikembalikan,
            'take_status' => $onhand->take_status,
            'take_status_label' => self::takeStatusLabel($onhand->take_status),
            'return_status' => $onhand->return_status,
            'status_label' => $state['status_label'],
            'assignment_date' => optional($onhand->assignment_date)->format('Y-m-d'),
            'sold_quantity' => $state['sold_quantity'],
            'remaining_quantity' => $state['remaining_quantity'],
            'max_return' => $state['max_return'],
            'requires_return' => $state['requires_return'],
            'can_checkout' => $state['can_checkout'],
            'has_pending_request' => $onhand->return_status === 'pending',
            'sold_out' => $state['sold_out'],
            'can_request_return' => $onhand->take_status === 'disetujui' && ! $state['sold_out'],
        ];
    }

    public static function stateForOnhand(ProductOnhand $onhand): array
    {
        if ($onhand->take_status !== 'disetujui') {
            return [
                'sold_quantity' => 0,
                'remaining_quantity' => 0,
                'max_return' => 0,
                'requires_return' => false,
                'can_checkout' => true,
                'sold_out' => false,
                'status_label' => self::takeStatusLabel($onhand->take_status),
            ];
        }

        $soldQuantity = self::soldForOnhand($onhand);
        $countedReturn = in_array($onhand->return_status, ['pending', 'disetujui'], true) ? (int) $onhand->quantity_dikembalikan : 0;
        $soldOut = $soldQuantity >= (int) $onhand->quantity;
        $remainingQuantity = max((int) $onhand->quantity - $soldQuantity - $countedReturn, 0);
        $maxReturn = max((int) $onhand->quantity - $soldQuantity, 0);
        $requiresReturn = (bool) ($onhand->user?->require_return_before_checkout ?? true) && ! $soldOut;
        $canCheckout = ! $requiresReturn || ($countedReturn > 0 && ($soldQuantity + $countedReturn) >= (int) $onhand->quantity);

        $statusLabel = self::returnStatusLabel($onhand->return_status);
        if ($soldOut) {
            $statusLabel = 'Habis Terjual';
        } elseif ($countedReturn > 0 && $onhand->return_status === 'disetujui') {
            $statusLabel = 'Dikembalikan';
        }

        return [
            'sold_quantity' => $soldQuantity,
            'remaining_quantity' => $remainingQuantity,
            'max_return' => $maxReturn,
            'requires_return' => $requiresReturn,
            'can_checkout' => $canCheckout,
            'sold_out' => $soldOut,
            'status_label' => $statusLabel,
        ];
    }

    public static function soldForOnhand(ProductOnhand $onhand): int
    {
        return (int) OfflineSale::query()
            ->where('id_product_onhand', $onhand->id_product_onhand)
            ->where('approval_status', '!=', 'ditolak')
            ->sum('quantity');
    }

    public static function resolveOnhandForSale(int $userId, int $productId): ?ProductOnhand
    {
        return ProductOnhand::query()
            ->with('user')
            ->where('user_id', $userId)
            ->where('id_product', $productId)
            ->whereDate('assignment_date', today()->toDateString())
            ->where('take_status', 'disetujui')
            ->orderByDesc('id_product_onhand')
            ->get()
            ->first(function (ProductOnhand $onhand) {
                return $onhand->return_status !== 'pending' && self::availableForOnhand($onhand) > 0;
            });
    }

    public static function availableForOnhand(?ProductOnhand $onhand, ?int $ignoreSaleId = null): int
    {
        if (! $onhand) {
            return 0;
        }

        $soldQty = (int) OfflineSale::query()
            ->where('id_product_onhand', $onhand->id_product_onhand)
            ->when($ignoreSaleId, fn ($query) => $query->where('id_penjualan_offline', '!=', $ignoreSaleId))
            ->where('approval_status', '!=', 'ditolak')
            ->sum('quantity');

        $returnedQty = in_array($onhand->return_status, ['pending', 'disetujui'], true)
            ? (int) $onhand->quantity_dikembalikan
            : 0;

        return max((int) $onhand->quantity - $soldQty - $returnedQty, 0);
    }

    public static function normalizePhone(?string $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $normalized = preg_replace('/\D+/', '', $value) ?? '';

        return $normalized !== '' ? $normalized : null;
    }

    public static function takeStatusLabel(string $status): string
    {
        return match ($status) {
            'pending' => 'Menunggu Persetujuan',
            'ditolak' => 'Request Ditolak',
            default => 'Disetujui',
        };
    }

    public static function returnStatusLabel(string $status): string
    {
        return match ($status) {
            'belum' => 'Belum Dikembalikan',
            'pending' => 'Pending',
            'tidak_disetujui' => 'Tidak Disetujui',
            'disetujui' => 'Dikembalikan',
            default => $status,
        };
    }

    private static function buildWeeklyPeriods(Carbon $periodStart, Carbon $periodEnd): array
    {
        if ($periodStart->copy()->startOfDay()->gt($periodEnd->copy()->startOfDay())) {
            return [];
        }

        $periods = [];
        $cursor = $periodStart->copy()->startOfDay();

        while ($cursor->lte($periodEnd)) {
            $weekEnd = $cursor->copy()->endOfWeek(Carbon::SUNDAY);
            if ($weekEnd->gt($periodEnd)) {
                $weekEnd = $periodEnd->copy()->endOfDay();
            }

            $periods[] = [
                'start' => $cursor->copy()->startOfDay(),
                'end' => $weekEnd->copy()->endOfDay(),
            ];
            $cursor = $weekEnd->copy()->addDay()->startOfDay();
        }

        return $periods;
    }
}
