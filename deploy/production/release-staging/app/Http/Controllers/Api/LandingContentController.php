<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LandingPageContent;
use App\Models\SeoSetting;
use Illuminate\Http\JsonResponse;

class LandingContentController extends Controller
{
    public function __invoke(): JsonResponse
    {
        return response()->json([
            'data' => LandingPageContent::groupedForFrontend(),
            'seo' => SeoSetting::forPage('landing'),
        ]);
    }
}
