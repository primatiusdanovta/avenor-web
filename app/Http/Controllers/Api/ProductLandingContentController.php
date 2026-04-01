<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\ProductLandingData;
use Illuminate\Http\JsonResponse;

class ProductLandingContentController extends Controller
{
    public function __invoke(string $slug): JsonResponse
    {
        $product = ProductLandingData::findActiveProductBySlug($slug);

        abort_if(! $product, 404);

        return response()->json(ProductLandingData::buildPayload($product));
    }
}
