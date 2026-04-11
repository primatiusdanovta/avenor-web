<?php

namespace App\Support;

class SalesRole
{
    public const MARKETING = 'marketing';

    public const SALES_FIELD_EXECUTIVE = 'sales_field_executive';

    public const OWNER = 'owner';

    public const KARYAWAN = 'karyawan';

    public static function fieldRoles(): array
    {
        return [
            self::MARKETING,
            self::SALES_FIELD_EXECUTIVE,
        ];
    }

    public static function mobileRoles(): array
    {
        return [
            ...self::fieldRoles(),
            self::OWNER,
            self::KARYAWAN,
        ];
    }

    public static function managedRoles(): array
    {
        return [
            ...self::fieldRoles(),
            self::OWNER,
            self::KARYAWAN,
        ];
    }

    public static function label(string $role): string
    {
        return match ($role) {
            self::MARKETING => 'Marketing',
            self::SALES_FIELD_EXECUTIVE => 'Sales Field Executive',
            self::OWNER => 'Owner',
            self::KARYAWAN => 'Karyawan',
            'superadmin' => 'Superadmin',
            'admin' => 'Admin',
            default => ucwords(str_replace('_', ' ', $role)),
        };
    }

    public static function isFieldRole(?string $role): bool
    {
        return in_array($role, [...self::fieldRoles(), self::OWNER, self::KARYAWAN], true);
    }

    public static function requiresAttendanceToSell(?string $role): bool
    {
        return in_array($role, [...self::fieldRoles(), self::OWNER, self::KARYAWAN], true);
    }

    public static function defaultRequireReturnBeforeCheckout(string $role): bool
    {
        return $role === self::MARKETING;
    }
}


