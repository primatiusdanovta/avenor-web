<?php

use App\Http\Controllers\Api\MasterGatewayContentController;
use App\Http\Controllers\Api\ProductLandingContentController;
use Illuminate\Support\Facades\Route;

Route::get('/master-gateway', MasterGatewayContentController::class);
Route::get('/landing-content/{slug}', ProductLandingContentController::class);
