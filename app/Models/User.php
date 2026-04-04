<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
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
}
