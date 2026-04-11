<?php

namespace App\Support;

class RawMaterialUsage
{
    private const KILOGRAM_IN_GRAMS = 1000;

    public static function normalizeUnit(?string $satuan): string
    {
        return strtoupper(trim((string) $satuan));
    }

    public static function isMilliliter(?string $satuan): bool
    {
        return self::normalizeUnit($satuan) === 'ML';
    }

    public static function isKilogram(?string $satuan): bool
    {
        return self::normalizeUnit($satuan) === 'KG';
    }

    public static function normalizeStoredQuantity(float $value, ?string $satuan): float
    {
        if (self::isKilogram($satuan)) {
            return round($value * self::KILOGRAM_IN_GRAMS, 2);
        }

        return round($value, 2);
    }

    public static function displayQuantity(float $value, ?string $satuan): float
    {
        if (self::isKilogram($satuan)) {
            return round($value / self::KILOGRAM_IN_GRAMS, 2);
        }

        return round($value, 2);
    }

    public static function usageInputUnit(?string $satuan): string
    {
        return self::isKilogram($satuan) ? 'gram' : (trim((string) $satuan) ?: '-');
    }

    public static function stockDisplayUnit(?string $satuan): string
    {
        return self::isKilogram($satuan) ? 'kg' : (trim((string) $satuan) ?: '-');
    }

    public static function calculateUsageQuantity(float $inputValue, ?string $satuan, ?float $mlBase = null): float
    {
        if (self::isMilliliter($satuan)) {
            $base = max((float) ($mlBase ?? 50), 0);

            return ($inputValue / 100) * $base;
        }

        // For KG, input is already in grams, return as-is
        // For other units (pcs, gram), return as-is
        return round($inputValue, 2);
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

    /**
     * Convert grams to kg for display
     */
    public static function gramToKg(float $grams): float
    {
        return round($grams / self::KILOGRAM_IN_GRAMS, 2);
    }

    /**
     * Convert kg to grams for storage
     */
    public static function kgToGram(float $kg): float
    {
        return round($kg * self::KILOGRAM_IN_GRAMS, 2);
    }

    /**
     * Convert harga_satuan to proper unit for display
     * For KG materials: hargaSatuan is stored per gram, user needs to see per-gram price
     */
    public static function displayHargaSatuan(float $hargaSatuan, ?string $satuan): float
    {
        if (self::isKilogram($satuan)) {
            return round($hargaSatuan / self::KILOGRAM_IN_GRAMS, 4);
        }
        return round($hargaSatuan, 4);
    }
}
