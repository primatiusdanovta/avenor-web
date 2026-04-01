<?php

namespace App\Http\Middleware;

use App\Support\ProductLandingData;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\View;
use Symfony\Component\HttpFoundation\Response;

class InjectProductLandingSeo
{
    public function handle(Request $request, Closure $next): Response
    {
        $slug = (string) $request->route('slug');
        $product = ProductLandingData::findActiveProductBySlug($slug);

        abort_if(! $product, 404);

        $landingPayload = ProductLandingData::buildPayload($product);

        $request->attributes->set('productLandingPayload', $landingPayload);
        View::share('productLandingPayload', $landingPayload);
        View::share('productLandingSeo', $landingPayload['seo']);
        View::share('productLandingTracking', $landingPayload['tracking']);

        return $next($request);
    }
}

