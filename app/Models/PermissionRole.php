<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PermissionRole extends Model
{
    use HasFactory;

    protected $table = 'permission_roles';

    protected $fillable = [
        'key',
        'name',
        'legacy_role',
        'description',
        'permissions',
        'is_locked',
    ];

    protected function casts(): array
    {
        return [
            'permissions' => 'array',
            'is_locked' => 'boolean',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function users(): HasMany
    {
        return $this->hasMany(User::class, 'permission_role_id', 'id');
    }
}
