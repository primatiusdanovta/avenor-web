<?php

namespace App\Support;

class RawMaterialUsage
{
    public static function normalizeUnit(?string $satuan): string
    {
        return strtoupper(trim((string) $satuan));
    }

    public static function isMilliliter(?string $satuan): bool
    {
        return self::normalizeUnit($satuan) === 'ML';
    }

    public static function calculateUsageQuantity(float $inputValue, ?string $satuan, ?float $mlBase = null): float
    {
        if (self::isMilliliter($satuan)) {
            $base = max((float) ($mlBase ?? 50), 0);

            return ($inputValue / 100) * $base;
        }

        return $inputValue;
    }

    public static function calculateItemCost(float $inputValue, float $hargaSatuan, ?string $satuan, ?float $mlBase = null): float
    {
        return self::calculateUsageQuantity($inputValue, $satuan, $mlBase) * $hargaSatuan;
    }

    public static function recalculatePackageStock(float $totalQuantity, float $quantityPerPack): float
    {
        if ($quantityPerPack <= 0) {
            return 0;
        }

        return round($totalQuantity / $quantityPerPack, 2);
    }
}
