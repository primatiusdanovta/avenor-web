<?php

namespace App\Models;

use App\Support\PermissionCatalog;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasFactory, Notifiable;

    protected $primaryKey = 'id_user';

    public $timestamps = false;

    protected $fillable = [
        'nama',
        'status',
        'role',
        'permission_role_id',
        'password',
        'require_return_before_checkout',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'password' => 'hashed',
            'created_at' => 'datetime',
            'require_return_before_checkout' => 'boolean',
        ];
    }

    public function permissionRole(): BelongsTo
    {
        return $this->belongsTo(PermissionRole::class, 'permission_role_id');
    }

    public function stores(): BelongsToMany
    {
        return $this->belongsToMany(Store::class, 'store_user_assignments', 'user_id', 'store_id', 'id_user', 'id')
            ->withPivot(['is_primary'])
            ->withTimestamps();
    }

    public function attendances(): HasMany
    {
        return $this->hasMany(Attendance::class, 'user_id', 'id_user');
    }

    public function marketingLocations(): HasMany
    {
        return $this->hasMany(MarketingLocation::class, 'user_id', 'id_user');
    }

    public function productOnhands(): HasMany
    {
        return $this->hasMany(ProductOnhand::class, 'user_id', 'id_user');
    }

    public function offlineSales(): HasMany
    {
        return $this->hasMany(OfflineSale::class, 'id_user', 'id_user');
    }

    public function mobileAccessTokens(): HasMany
    {
        return $this->hasMany(MobileAccessToken::class, 'user_id', 'id_user');
    }

    public function marketingNotifications(): HasMany
    {
        return $this->hasMany(MarketingNotification::class, 'created_by', 'id_user');
    }

    public function marketingBonusAdjustments(): HasMany
    {
        return $this->hasMany(MarketingBonusAdjustment::class, 'user_id', 'id_user');
    }

    public function consignments(): HasMany
    {
        return $this->hasMany(Consignment::class, 'user_id', 'id_user');
    }

    public function permissions(): array
    {
        $permissions = $this->permissionRole?->permissions;

        if (is_array($permissions) && $permissions !== []) {
            return $permissions;
        }

        return PermissionCatalog::defaultPermissionsForLegacyRole($this->getRawOriginal('role'));
    }

    public function hasPermission(string $permission): bool
    {
        if ($this->getRawOriginal('role') === 'superadmin') {
            return true;
        }

        return in_array($permission, $this->permissions(), true);
    }
}
