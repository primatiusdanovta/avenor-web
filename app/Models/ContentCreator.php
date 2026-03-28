<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ContentCreator extends Model
{
    use HasFactory;

    protected $primaryKey = 'id_contentcreator';

    public $timestamps = false;

    protected $fillable = [
        'nama',
        'bidang',
        'username_instagram',
        'username_tiktok',
        'followers_instagram',
        'followers_tiktok',
        'range_fee_percontent',
        'jenis_konten',
        'no_telp',
        'wilayah',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'bidang' => 'array',
            'followers_instagram' => 'integer',
            'followers_tiktok' => 'integer',
            'created_at' => 'datetime',
        ];
    }
}
