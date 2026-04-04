<?php

namespace App\Support;

use App\Models\MarketingBonusAdjustment;
use App\Models\OfflineSale;
use App\Models\SalesTarget;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class MarketingBonusSupport
{
    public static function buildTargetSummary(User $user, Carbon $periodStart, Carbon $periodEnd, ?SalesTarget $target = null): array
    {
        $today = now()->startOfDay();
        $effectiveEnd = $periodEnd->copy()->startOfDay()->gt($today) ? $today->copy() : $periodEnd->copy()->startOfDay();

        $sales = OfflineSale::query()
            ->where('id_user', $user->id_user)
            ->where('approval_status', '!=', 'ditolak')
            ->whereBetween('created_at', [$periodStart->copy()->startOfDay(), $effectiveEnd->copy()->endOfDay()])
            ->get();

        $dailyTargetQty = (int) ($target?->daily_target_qty ?? 0);
        $weeklyTargetQty = (int) ($target?->weekly_target_qty ?? 0);
        $monthlyTargetQty = (int) ($target?->monthly_target_qty ?? 0);
        $weeklyBonus = (float) ($target?->weekly_bonus ?? 0);
        $monthlyBonus = (float) ($target?->monthly_bonus ?? 0);

        $dailyTotals = $sales->groupBy(fn (OfflineSale $sale) => optional($sale->created_at)->toDateString())
            ->map(fn (Collection $items) => (int) $items->sum('quantity'));
        $periodDayCount = $periodStart->copy()->startOfDay()->gt($effectiveEnd)
            ? 0
            : $periodStart->copy()->startOfDay()->diffInDays($effectiveEnd) + 1;
        $dailyAchievedCount = $dailyTargetQty > 0
            ? $dailyTotals->filter(fn (int $quantity) => $quantity >= $dailyTargetQty)->count()
            : 0;

        $weeklyPeriods = self::buildWeeklyPeriods($periodStart, $effectiveEnd);
        $weeklyAchievedPeriods = [];

        foreach ($weeklyPeriods as $period) {
            $weekQuantity = (int) $sales
                ->filter(fn (OfflineSale $sale) => optional($sale->created_at)?->betweenIncluded($period['start'], $period['end']))
                ->sum('quantity');

            if ($weeklyTargetQty > 0 && $weekQuantity >= $weeklyTargetQty) {
                $weeklyAchievedPeriods[] = [
                    'start' => $period['start']->toDateString(),
                    'end' => $period['end']->toDateString(),
                    'quantity' => $weekQuantity,
                ];
            }
        }

        $weeklyAchievedCount = count($weeklyAchievedPeriods);
        $monthlyQuantity = (int) $sales->sum('quantity');
        $monthlyMet = $monthlyTargetQty > 0 && $monthlyQuantity >= $monthlyTargetQty;
        $todayQuantity = (int) ($dailyTotals[now()->toDateString()] ?? 0);
        $isCurrentMonth = $periodStart->isSameMonth(now()) && $periodStart->isSameYear(now());
        $manualBonuses = self::manualBonusEntries($user, $periodStart);
        $manualBonusTotal = round((float) $manualBonuses->sum('amount'), 2);
        $calculatedBonusTotal = $monthlyMet
            ? round($monthlyBonus, 2)
            : round($weeklyAchievedCount * $weeklyBonus, 2);

        return [
            'period_label' => $periodStart->copy()->locale('id')->translatedFormat('F Y'),
            'daily' => [
                'target_qty' => $dailyTargetQty,
                'achieved_count' => $dailyAchievedCount,
                'total_periods' => $periodDayCount,
                'bonus' => 0.0,
            ],
            'weekly' => [
                'target_qty' => $weeklyTargetQty,
                'achieved_count' => $weeklyAchievedCount,
                'total_periods' => count($weeklyPeriods),
                'bonus' => $monthlyMet ? 0.0 : round($weeklyAchievedCount * $weeklyBonus, 2),
                'suppressed_by_monthly_bonus' => $monthlyMet,
                'achieved_periods' => $weeklyAchievedPeriods,
            ],
            'monthly' => [
                'target_qty' => $monthlyTargetQty,
                'total_quantity' => $monthlyQuantity,
                'met' => $monthlyMet,
                'bonus' => $monthlyMet ? round($monthlyBonus, 2) : 0.0,
            ],
            'manual_bonus_total' => $manualBonusTotal,
            'manual_bonus_entries' => $manualBonuses
                ->map(fn (MarketingBonusAdjustment $bonus) => [
                    'id' => $bonus->id,
                    'amount' => round((float) $bonus->amount, 2),
                    'note' => $bonus->note,
                    'bonus_month' => optional($bonus->bonus_month)->format('Y-m'),
                    'created_at' => optional($bonus->created_at)->format('Y-m-d H:i:s'),
                    'created_by_name' => $bonus->creator?->nama,
                ])
                ->values()
                ->all(),
            'calculated_bonus_total' => $calculatedBonusTotal,
            'bonus_total' => round($calculatedBonusTotal + $manualBonusTotal, 2),
            'reminder' => $isCurrentMonth && $dailyTargetQty > 0 && $todayQuantity < $dailyTargetQty
                ? sprintf('Target anda %d/%d, Penuhi Target anda hari ini!', $todayQuantity, $dailyTargetQty)
                : null,
        ];
    }

    public static function manualBonusEntries(User $user, Carbon $periodStart): Collection
    {
        return MarketingBonusAdjustment::query()
            ->with('creator:id_user,nama')
            ->where('user_id', $user->id_user)
            ->whereDate('bonus_month', $periodStart->copy()->startOfMonth()->toDateString())
            ->orderByDesc('created_at')
            ->get();
    }

    public static function buildWeeklyPeriods(Carbon $periodStart, Carbon $periodEnd): array
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
