<?php

namespace App\Models\Concerns;

use App\Models\Store;

trait DefaultsToAvenorStore
{
    protected static function bootDefaultsToAvenorStore(): void
    {
        static::creating(function ($model): void {
            if (! empty($model->store_id)) {
                return;
            }

            $storeId = Store::query()->where('code', 'avenor_perfume')->value('id');
            if ($storeId) {
                $model->store_id = $storeId;
            }
        });
    }
}
