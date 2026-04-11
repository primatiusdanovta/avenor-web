<?php

namespace App\Support;

use App\Models\Store;
use Illuminate\Http\Request;

class StoreFeature
{
    public const SMOOTHIES_SWEETIE_CODE = 'smoothies_sweetie';

    public static function isSmoothiesSweetie(Request|Store|null $subject): bool
    {
        if ($subject instanceof Request) {
            $subject = StoreContext::currentStore($subject);
        }

        return (string) ($subject?->code ?? '') === self::SMOOTHIES_SWEETIE_CODE;
    }

    public static function disablesOnhandAndConsignment(Request|Store|null $subject): bool
    {
        return self::isSmoothiesSweetie($subject);
    }

    public static function requiresOnhandForOfflineSales(Request|Store|null $subject): bool
    {
        return ! self::isSmoothiesSweetie($subject);
    }

    public static function requiresReturnBeforeCheckout(Request|Store|null $subject): bool
    {
        return ! self::isSmoothiesSweetie($subject);
    }

    public static function usesLegacyMlBase(Request|Store|null $subject): bool
    {
        return ! self::isSmoothiesSweetie($subject);
    }
}
