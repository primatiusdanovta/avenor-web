<?php

namespace App\Http\Controllers;

use App\Models\Store;
use App\Support\StoreFeature;
use App\Support\StoreContext;
use Illuminate\Http\Request;

abstract class Controller
{
    protected function currentStore(Request $request): Store
    {
        $store = StoreContext::currentStore($request);
        abort_unless($store, 403, 'Store aktif tidak ditemukan.');

        return $store;
    }

    protected function currentStoreId(Request $request): int
    {
        return (int) $this->currentStore($request)->id;
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        abort_unless($request->user()?->hasPermission($permission), 403);
        abort_unless(StoreContext::currentStore($request), 403, 'Store aktif tidak ditemukan.');
    }

    protected function ensureStoreMatch(Request $request, object $model, string $column = 'store_id'): void
    {
        $modelStoreId = (int) data_get($model, $column);
        abort_unless($modelStoreId > 0 && $modelStoreId === $this->currentStoreId($request), 404);
    }

    protected function isSmoothiesSweetieStore(Request $request): bool
    {
        return StoreFeature::isSmoothiesSweetie($request);
    }

    protected function abortIfStoreDisablesOnhandAndConsignment(Request $request): void
    {
        abort_if(
            StoreFeature::disablesOnhandAndConsignment($request),
            404,
            'Fitur ini dinonaktifkan untuk store Smoothies Sweetie.'
        );
    }
}
