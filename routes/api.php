<?php

use App\Http\Controllers\Api\MasterGatewayContentController;
use App\Http\Controllers\Api\Mobile\AttendanceController as MobileAttendanceController;
use App\Http\Controllers\Api\Mobile\AuthController as MobileAuthController;
use App\Http\Controllers\Api\Mobile\ConsignmentController as MobileConsignmentController;
use App\Http\Controllers\Api\Mobile\DashboardController as MobileDashboardController;
use App\Http\Controllers\Api\Mobile\MarketingNotificationController as MobileMarketingNotificationController;
use App\Http\Controllers\Api\Mobile\OfflineSaleController as MobileOfflineSaleController;
use App\Http\Controllers\Api\Mobile\OwnerModuleController as MobileOwnerModuleController;
use App\Http\Controllers\Api\Mobile\ProductController as MobileProductController;
use App\Http\Controllers\Api\Mobile\ProductKnowledgeController as MobileProductKnowledgeController;
use App\Http\Controllers\Api\ProductLandingContentController;
use Illuminate\Support\Facades\Route;

Route::get('/master-gateway', MasterGatewayContentController::class);
Route::get('/landing-content/{slug}', ProductLandingContentController::class);

Route::prefix('mobile')->name('api.mobile.')->group(function () {
    Route::post('/auth/login', [MobileAuthController::class, 'login'])->name('auth.login');

    Route::middleware('mobile.auth')->group(function () {
        Route::get('/auth/me', [MobileAuthController::class, 'me'])->name('auth.me');
        Route::post('/auth/logout', [MobileAuthController::class, 'logout'])->name('auth.logout');
        Route::get('/dashboard', MobileDashboardController::class)->name('dashboard');
        Route::get('/notifications', [MobileMarketingNotificationController::class, 'index'])->name('notifications.index');
        Route::post('/notifications/token', [MobileMarketingNotificationController::class, 'registerToken'])->name('notifications.token');
        Route::get('/attendance', [MobileAttendanceController::class, 'index'])->name('attendance.index');
        Route::post('/attendance/check-in', [MobileAttendanceController::class, 'checkIn'])->name('attendance.check-in');
        Route::post('/attendance/check-out', [MobileAttendanceController::class, 'checkOut'])->name('attendance.check-out');
        Route::post('/attendance/location', [MobileAttendanceController::class, 'storeLocation'])->name('attendance.location.store');
        Route::get('/products', [MobileProductController::class, 'index'])->name('products.index');
        Route::post('/products/take', [MobileProductController::class, 'take'])->name('products.take');
        Route::post('/products/onhand/{onhand}/return', [MobileProductController::class, 'requestReturn'])->name('products.onhand.return');
        Route::get('/product-knowledge', MobileProductKnowledgeController::class)->name('product-knowledge.index');
        Route::get('/consignments', [MobileConsignmentController::class, 'index'])->name('consignments.index');
        Route::post('/consignments', [MobileConsignmentController::class, 'store'])->name('consignments.store');
        Route::put('/consignment-items/{item}', [MobileConsignmentController::class, 'updateItem'])->name('consignment-items.update');
        Route::get('/offline-sales', [MobileOfflineSaleController::class, 'index'])->name('offline-sales.index');
        Route::get('/offline-sales/customer', [MobileOfflineSaleController::class, 'findCustomer'])->name('offline-sales.customer');
        Route::post('/offline-sales', [MobileOfflineSaleController::class, 'store'])->name('offline-sales.store');
        Route::put('/offline-sales/{sale}', [MobileOfflineSaleController::class, 'update'])->name('offline-sales.update');
        Route::delete('/offline-sales/{sale}', [MobileOfflineSaleController::class, 'destroy'])->name('offline-sales.destroy');
        Route::get('/offline-sales/{sale}/proof', [MobileOfflineSaleController::class, 'showProof'])->name('offline-sales.proof');
        Route::get('/queue', [MobileOfflineSaleController::class, 'queue'])->name('queue.index');
        Route::post('/queue/close', [MobileOfflineSaleController::class, 'closeQueue'])->name('queue.close');
        Route::get('/owner/modules/{module}', [MobileOwnerModuleController::class, 'index'])->name('owner.modules.index');
        Route::post('/owner/modules/{module}', [MobileOwnerModuleController::class, 'store'])->name('owner.modules.store');
        Route::put('/owner/modules/{module}/{record}', [MobileOwnerModuleController::class, 'update'])->name('owner.modules.update');
        Route::delete('/owner/modules/{module}/{record}', [MobileOwnerModuleController::class, 'destroy'])->name('owner.modules.destroy');
    });
});
