<?php

namespace App\Support;

use App\Models\ConsignmentItem;
use App\Models\OfflineSale;
use App\Models\ProductOnhand;

class ProductOnhandStock
{
    public static function actualSoldQuantity(ProductOnhand $onhand, ?int $ignoreSaleId = null): int
    {
        return (int) OfflineSale::query()
            ->where('id_product_onhand', $onhand->id_product_onhand)
            ->when($ignoreSaleId, fn ($query) => $query->where('id_penjualan_offline', '!=', $ignoreSaleId))
            ->where('approval_status', '!=', 'ditolak')
            ->sum('quantity');
    }

    public static function manualSoldQuantity(ProductOnhand $onhand): int
    {
        return (int) ($onhand->manual_sold_quantity ?? 0);
    }

    public static function soldQuantity(ProductOnhand $onhand, ?int $ignoreSaleId = null): int
    {
        return self::actualSoldQuantity($onhand, $ignoreSaleId)
            + self::manualSoldQuantity($onhand)
            + self::consignmentSoldQuantity($onhand);
    }

    public static function pendingReturnQuantity(ProductOnhand $onhand): int
    {
        return $onhand->return_status === 'pending'
            ? (int) $onhand->quantity_dikembalikan
            : 0;
    }

    public static function approvedReturnQuantity(ProductOnhand $onhand): int
    {
        return (int) ($onhand->approved_return_quantity ?? 0);
    }

    public static function maxSoldQuantity(ProductOnhand $onhand): int
    {
        return max(
            (int) $onhand->quantity - self::approvedReturnQuantity($onhand) - self::pendingReturnQuantity($onhand),
            0,
        );
    }

    public static function availableQuantity(ProductOnhand $onhand, ?int $ignoreSaleId = null): int
    {
        return max(
            (int) $onhand->quantity
                - self::soldQuantity($onhand, $ignoreSaleId)
                - self::approvedReturnQuantity($onhand)
                - self::pendingReturnQuantity($onhand),
                - self::consignmentActiveQuantity($onhand),
            0,
        );
    }

    public static function consignmentSoldQuantity(ProductOnhand $onhand): int
    {
        return (int) ConsignmentItem::query()
            ->where('product_onhand_id', $onhand->id_product_onhand)
            ->sum('sold_quantity');
    }

    public static function consignmentActiveQuantity(ProductOnhand $onhand): int
    {
        return (int) ConsignmentItem::query()
            ->where('product_onhand_id', $onhand->id_product_onhand)
            ->get()
            ->sum(function (ConsignmentItem $item) {
                return max((int) $item->quantity - (int) $item->sold_quantity - (int) $item->returned_quantity, 0);
            });
    }
}
