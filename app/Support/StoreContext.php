<?php

namespace App\Support;

use App\Models\Store;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;

class StoreContext
{
    public const SESSION_KEY = 'active_store_id';

    public static function storesForUser(?User $user): Collection
    {
        if (! $user) {
            return collect();
        }

        if ($user->role === 'superadmin') {
            return Store::query()->orderBy('display_name')->get();
        }

        return $user->stores()->orderBy('display_name')->get();
    }

    public static function currentStore(?Request $request): ?Store
    {
        $user = $request?->user();
        $stores = self::storesForUser($user);

        if ($stores->isEmpty()) {
            return null;
        }

        $activeStoreId = 0;
        if ($request && $request->hasSession()) {
            $activeStoreId = (int) ($request->session()->get(self::SESSION_KEY) ?? 0);
        }
        $activeStore = $stores->firstWhere('id', $activeStoreId);

        if ($activeStore) {
            return $activeStore;
        }

        $primaryStore = $user?->stores()->wherePivot('is_primary', true)->first();

        return $stores->firstWhere('id', $primaryStore?->id) ?? $stores->first();
    }

    public static function initializeSession(Request $request): void
    {
        if (! $request->hasSession()) {
            return;
        }

        $currentStore = self::currentStore($request);
        if ($currentStore) {
            $request->session()->put(self::SESSION_KEY, $currentStore->id);
        }
    }

    public static function setCurrentStore(Request $request, int $storeId): bool
    {
        if (! $request->hasSession()) {
            return false;
        }

        $allowed = self::storesForUser($request->user())->contains(fn (Store $store) => (int) $store->id === $storeId);

        if (! $allowed) {
            return false;
        }

        $request->session()->put(self::SESSION_KEY, $storeId);

        return true;
    }
}
