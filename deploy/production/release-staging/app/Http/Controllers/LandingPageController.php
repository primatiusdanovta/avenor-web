<?php

namespace App\Http\Controllers;

use App\Models\LandingPageContent;
use App\Models\SeoSetting;
use Illuminate\Contracts\View\View;

class LandingPageController extends Controller
{
    public function __invoke(): View
    {
        LandingPageContent::ensureDefaults();
        SeoSetting::ensureDefaults();

        return view('landing', [
            'initialContent' => LandingPageContent::groupedForFrontend(),
            'seo' => SeoSetting::forPage('landing'),
        ]);
    }
}
