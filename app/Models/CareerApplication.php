<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CareerApplication extends Model
{
    use HasFactory;

    protected $fillable = [
        'job_title',
        'responses',
        'uploaded_files',
        'status',
        'content_creator_id',
        'transferred_to_content_creator_at',
    ];

    protected function casts(): array
    {
        return [
            'responses' => 'array',
            'uploaded_files' => 'array',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
            'transferred_to_content_creator_at' => 'datetime',
        ];
    }

    public function contentCreator()
    {
        return $this->belongsTo(ContentCreator::class, 'content_creator_id', 'id_contentcreator');
    }
}
