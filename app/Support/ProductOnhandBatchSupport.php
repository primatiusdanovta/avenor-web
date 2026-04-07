<?php

namespace App\Support;

use App\Models\ProductOnhand;

class ProductOnhandBatchSupport
{
    public static function generate(ProductOnhand $onhand): string
    {
        $date = optional($onhand->assignment_date)->format('Ymd') ?? now()->format('Ymd');

        return sprintf('PICK-%s-U%s-O%s', $date, $onhand->user_id, $onhand->id_product_onhand);
    }
}
