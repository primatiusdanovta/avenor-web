<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LandingPageSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'slug',
        'hero_badge',
        'hero_title',
        'hero_subtitle',
        'hero_primary_label',
        'hero_primary_href',
        'hero_secondary_label',
        'hero_secondary_href',
        'story_title',
        'story_body',
        'collection_title',
        'collection_body',
        'ritual_title',
        'ritual_body',
        'cta_title',
        'cta_body',
        'cta_button_label',
        'cta_button_href',
        'section_visibility',
        'scent_profiles',
    ];

    protected function casts(): array
    {
        return [
            'section_visibility' => 'array',
            'scent_profiles' => 'array',
        ];
    }
}
