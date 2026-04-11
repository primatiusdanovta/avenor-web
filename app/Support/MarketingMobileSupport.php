<?php

namespace App\Support;

use App\Models\Attendance;
use App\Models\OfflineSale;
use App\Models\ProductOnhand;
use App\Models\SalesTarget;
use App\Models\Store;
use App\Models\User;
use App\Support\ProductOnhandStock;
use Carbon\Carbon;

class MarketingMobileSupport
{
    public static function currentStore(User $user): ?Store
    {
        return $user->stores()->wherePivot('is_primary', true)->first()
            ?? $user->stores()->first();
    }

    public static function currentStoreId(User $user): ?int
    {
        return self::currentStore($user)?->id;
    }

    public static function isSmoothiesSweetieUser(User $user): bool
    {
        return StoreFeature::isSmoothiesSweetie(self::currentStore($user));
    }

    public static function attendanceContext(User $user): array
    {
        $storeId = self::currentStoreId($user);
        $todayAttendance = Attendance::query()
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
            ->where('user_id', $user->id_user)
            ->whereDate('attendance_date', now()->toDateString())
            ->first();

        $attendanceReady = (bool) $todayAttendance?->check_in && ! $todayAttendance?->check_out;
        $attendanceBlockedReason = null;

        if (! $todayAttendance?->check_in) {
            $attendanceBlockedReason = self::isSmoothiesSweetieUser($user)
                ? 'Karyawan wajib check in terlebih dahulu sebelum melakukan penjualan.'
                : 'Sales lapangan wajib check in terlebih dahulu sebelum mengambil barang.';
        } elseif ($todayAttendance?->check_out) {
            $attendanceBlockedReason = 'User yang sudah check out tidak bisa request barang lagi hari ini.';
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
        $user = User::query()->find($userId);
        $storeId = $user ? self::currentStoreId($user) : null;
        $salesQuantity = (int) OfflineSale::query()
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
            ->where('id_user', $userId)
            ->where('approval_status', '!=', 'ditolak')
            ->whereBetween('created_at', [$periodStart->copy()->startOfDay(), $periodEnd->copy()->endOfDay()])
            ->sum('quantity');

        $attendances = Attendance::query()
            ->when($storeId, fn ($query) => $query->where('store_id', $storeId))
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

        $salesTarget = (int) (SalesTarget::query()->firstWhere('role', $user?->role ?? 'marketing')?->monthly_target_qty ?? 100);
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
        return MarketingBonusSupport::buildTargetSummary(
            $user,
            $periodStart,
            $periodEnd,
            SalesTarget::query()->firstWhere('role', $user->role),
            self::currentStoreId($user)
        );
    }

    public static function transformOnhand(ProductOnhand $onhand): array
    {
        $state = self::stateForOnhand($onhand);
        $approvedReturnQuantity = ProductOnhandStock::approvedReturnQuantity($onhand);
        $pendingReturnQuantity = ProductOnhandStock::pendingReturnQuantity($onhand);

        return [
            'id_product_onhand' => $onhand->id_product_onhand,
            'id_product' => $onhand->id_product,
            'nama_product' => $onhand->nama_product,
            'pickup_batch_code' => $onhand->pickup_batch_code,
            'quantity' => (int) $onhand->quantity,
            'quantity_dikembalikan' => $approvedReturnQuantity + $pendingReturnQuantity,
            'approved_return_quantity' => $approvedReturnQuantity,
            'pending_return_quantity' => $pendingReturnQuantity,
            'take_status' => $onhand->take_status,
            'take_status_label' => self::takeStatusLabel($onhand->take_status),
            'return_status' => $onhand->return_status,
            'return_status_label' => self::returnStatusLabel($onhand->return_status),
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

    public static function countsAsActiveOnhand(array $onhand): bool
    {
        return ($onhand['take_status'] ?? null) === 'disetujui'
            && ! ($onhand['sold_out'] ?? false)
            && (int) ($onhand['remaining_quantity'] ?? 0) > 0;
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
        $approvedReturnQuantity = ProductOnhandStock::approvedReturnQuantity($onhand);
        $pendingReturnQuantity = ProductOnhandStock::pendingReturnQuantity($onhand);
        $soldOut = $soldQuantity >= (int) $onhand->quantity;
        $remainingQuantity = max((int) $onhand->quantity - $soldQuantity - $approvedReturnQuantity - $pendingReturnQuantity, 0);
        $maxReturn = max((int) $onhand->quantity - $soldQuantity - $approvedReturnQuantity, 0);
        $requiresReturn = (bool) ($onhand->user?->require_return_before_checkout ?? true)
            && ! $soldOut
            && $maxReturn > 0;
        $canCheckout = ! $requiresReturn
            || (($soldQuantity + $approvedReturnQuantity) >= (int) $onhand->quantity);

        $statusLabel = self::returnStatusLabel($onhand->return_status);
        if ($soldOut) {
            $statusLabel = 'Habis Terjual';
        } elseif ($approvedReturnQuantity > 0 && $remainingQuantity === 0) {
            $statusLabel = 'Dikembalikan';
        } elseif ($approvedReturnQuantity > 0) {
            $statusLabel = 'Sebagian Dikembalikan';
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
        return ProductOnhandStock::soldQuantity($onhand);
    }

    public static function resolveOnhandForSale(int $userId, int $productId): ?ProductOnhand
    {
        $user = User::query()->find($userId);
        if ($user && self::isSmoothiesSweetieUser($user)) {
            return null;
        }

        return ProductOnhand::query()
            ->with('user')
            ->where('user_id', $userId)
            ->where('id_product', $productId)
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

        return ProductOnhandStock::availableQuantity($onhand, $ignoreSaleId);
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
}

