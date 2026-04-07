<?php

namespace App\Support;

use App\Models\AccountReceivable;
use App\Models\Consignment;
use App\Models\Product;

class AccountReceivableSupport
{
    public static function syncFromConsignment(Consignment $consignment): ?AccountReceivable
    {
        $consignment->loadMissing('items');

        $items = $consignment->items;
        if ($items->isEmpty()) {
            return null;
        }

        $priceMap = Product::query()
            ->whereIn('id_product', $items->pluck('product_id')->filter()->unique()->values())
            ->pluck('harga', 'id_product');

        $consignedValue = 0.0;
        $receivableValue = 0.0;
        $itemSummaries = [];
        $totalQuantity = 0;
        $soldQuantity = 0;
        $returnedQuantity = 0;

        foreach ($items as $item) {
            $price = (float) ($priceMap[$item->product_id] ?? 0);
            $quantity = (int) $item->quantity;
            $sold = (int) $item->sold_quantity;
            $returned = (int) $item->returned_quantity;

            $consignedValue += $price * $quantity;
            $receivableValue += $price * $sold;
            $totalQuantity += $quantity;
            $soldQuantity += $sold;
            $returnedQuantity += $returned;

            $itemSummaries[] = sprintf(
                '%s titip %d | terjual %d | kembali %d',
                (string) $item->product_name,
                $quantity,
                $sold,
                $returned,
            );
        }

        $remainingQuantity = max($totalQuantity - $soldQuantity - $returnedQuantity, 0);

        $status = 'dititipkan';
        if ($soldQuantity === 0 && $returnedQuantity >= $totalQuantity) {
            $status = 'dikembalikan';
        } elseif ($soldQuantity >= $totalQuantity && $totalQuantity > 0) {
            $status = 'terjual';
        } elseif ($soldQuantity > 0 && $remainingQuantity > 0) {
            $status = 'sebagian_terjual';
        } elseif ($soldQuantity > 0 && $returnedQuantity > 0 && $remainingQuantity === 0) {
            $status = 'selesai';
        } elseif ($returnedQuantity > 0 && $remainingQuantity > 0) {
            $status = 'sebagian_dikembalikan';
        }

        return AccountReceivable::query()->updateOrCreate(
            ['consignment_id' => $consignment->id],
            [
                'receivable_name' => 'Titipan ' . $consignment->place_name,
                'place_name' => $consignment->place_name,
                'consignment_date' => $consignment->consignment_date,
                'due_date' => $consignment->consignment_date,
                'consigned_value' => round($consignedValue, 2),
                'total_value' => round($receivableValue, 2),
                'status' => $status,
                'items_summary' => implode(', ', $itemSummaries),
            ],
        );
    }
}
