<?php

namespace App\Http\Controllers;

use Illuminate\Contracts\View\View;
use Illuminate\Http\Request;

class ProductLandingController extends Controller
{
    public function __invoke(Request $request): View
    {
        $payload = $request->attributes->get('productLandingPayload');

        abort_if(! is_array($payload), 404);

        return view('landing', [
            'pageType' => 'product',
            'initialContent' => $payload,
            'seo' => $payload['seo'] ?? null,
            'schemas' => $payload['schemas'] ?? [],
            'tracking' => $payload['tracking'] ?? [],
            'socialHub' => $payload['social_hub'] ?? [],
        ]);
    }
}
