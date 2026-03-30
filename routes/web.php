<?php

use App\Http\Controllers\ApprovalController;
use App\Http\Controllers\Auth\AuthenticatedSessionController;
use App\Http\Controllers\ContentCreatorController;
use App\Http\Controllers\CustomerController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\HppController;
use App\Http\Controllers\MarketingAttendanceController;
use App\Http\Controllers\MarketingManagementController;
use App\Http\Controllers\OfflineSaleController;
use App\Http\Controllers\OnlineSaleController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\ProductKnowledgeController;
use App\Http\Controllers\PromoController;
use App\Http\Controllers\RawMaterialController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\SalesTargetController;
use App\Http\Controllers\SuperAdminUserController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return auth()->check()
        ? redirect()->route('dashboard')
        : redirect()->route('login');
});

Route::middleware('guest')->group(function () {
    Route::get('/login', [AuthenticatedSessionController::class, 'create'])->name('login');
    Route::get('/login/captcha', [AuthenticatedSessionController::class, 'captcha'])->name('login.captcha');
    Route::post('/login', [AuthenticatedSessionController::class, 'store'])->name('login.store');
});

Route::middleware('auth')->group(function () {
    Route::get('/dashboard', DashboardController::class)->name('dashboard');

    Route::get('/users', [SuperAdminUserController::class, 'index'])->name('users.manage');
    Route::post('/users', [SuperAdminUserController::class, 'store'])->name('users.store');
    Route::put('/users/{user}', [SuperAdminUserController::class, 'update'])->name('users.update');
    Route::delete('/users/{user}', [SuperAdminUserController::class, 'destroy'])->name('users.destroy');

    Route::get('/marketing', [MarketingManagementController::class, 'index'])->name('marketing.index');
    Route::post('/marketing', [MarketingManagementController::class, 'store'])->name('marketing.store');
    Route::put('/marketing/{user}', [MarketingManagementController::class, 'update'])->name('marketing.update');
    Route::delete('/marketing/{user}', [MarketingManagementController::class, 'destroy'])->name('marketing.destroy');

    Route::get('/approvals', [ApprovalController::class, 'index'])->name('approvals.index');
    Route::get('/hpp', [HppController::class, 'index'])->name('hpp.index');
    Route::post('/hpp', [HppController::class, 'store'])->name('hpp.store');
    Route::delete('/hpp/{hppCalculation}', [HppController::class, 'destroy'])->name('hpp.destroy');
    Route::get('/raw-materials', [RawMaterialController::class, 'index'])->name('raw-materials.index');
    Route::post('/raw-materials', [RawMaterialController::class, 'store'])->name('raw-materials.store');
    Route::post('/raw-materials/restock', [RawMaterialController::class, 'restock'])->name('raw-materials.restock');
    Route::put('/raw-materials/{rawMaterial}', [RawMaterialController::class, 'update'])->name('raw-materials.update');
    Route::delete('/raw-materials/{rawMaterial}', [RawMaterialController::class, 'destroy'])->name('raw-materials.destroy');

    Route::get('/sales-targets', [SalesTargetController::class, 'index'])->name('sales-targets.index');
    Route::put('/sales-targets/{salesTarget}', [SalesTargetController::class, 'update'])->name('sales-targets.update');

    Route::get('/online-sales', [OnlineSaleController::class, 'index'])->name('online-sales.index');
    Route::post('/online-sales/import', [OnlineSaleController::class, 'import'])->name('online-sales.import');
    Route::post('/online-sales/debug-import', [OnlineSaleController::class, 'debugImport'])->name('online-sales.debug-import');

    Route::get('/reports', [ReportController::class, 'index'])->name('reports.index');
    Route::get('/reports/export-pdf', [ReportController::class, 'exportPdf'])->name('reports.export-pdf');

    Route::get('/marketing/attendance', [MarketingAttendanceController::class, 'index'])->name('marketing.attendance.index');
    Route::post('/marketing/attendance/check-in', [MarketingAttendanceController::class, 'checkIn'])->name('marketing.attendance.check-in');
    Route::post('/marketing/attendance/check-out', [MarketingAttendanceController::class, 'checkOut'])->name('marketing.attendance.check-out');
    Route::post('/marketing/location', [MarketingAttendanceController::class, 'storeLocation'])->name('marketing.location.store');

    Route::get('/products', [ProductController::class, 'index'])->name('products.index');
    Route::get('/product-knowledge', [ProductKnowledgeController::class, 'index'])->name('products.knowledge');
    Route::post('/products', [ProductController::class, 'store'])->name('products.store');
    Route::put('/products/{product}', [ProductController::class, 'update'])->name('products.update');
    Route::delete('/products/{product}', [ProductController::class, 'destroy'])->name('products.destroy');
    Route::post('/products/take', [ProductController::class, 'take'])->name('products.take');
    Route::post('/products/onhand/{onhand}/take-approve', [ProductController::class, 'approveTake'])->name('products.onhand.take-approve');
    Route::post('/products/onhand/{onhand}/take-reject', [ProductController::class, 'rejectTake'])->name('products.onhand.take-reject');
    Route::put('/products/onhand/{onhand}/return', [ProductController::class, 'requestReturn'])->name('products.onhand.return');
    Route::post('/products/onhand/{onhand}/approve', [ProductController::class, 'approveReturn'])->name('products.onhand.approve');
    Route::post('/products/onhand/{onhand}/reject', [ProductController::class, 'rejectReturn'])->name('products.onhand.reject');

    Route::get('/promos', [PromoController::class, 'index'])->name('promos.index');
    Route::post('/promos', [PromoController::class, 'store'])->name('promos.store');
    Route::put('/promos/{promo}', [PromoController::class, 'update'])->name('promos.update');
    Route::delete('/promos/{promo}', [PromoController::class, 'destroy'])->name('promos.destroy');

    Route::get('/customers', [CustomerController::class, 'index'])->name('customers.index');
    Route::post('/customers', [CustomerController::class, 'store'])->name('customers.store');
    Route::put('/customers/{customer}', [CustomerController::class, 'update'])->name('customers.update');
    Route::delete('/customers/{customer}', [CustomerController::class, 'destroy'])->name('customers.destroy');

    Route::get('/content-creators', [ContentCreatorController::class, 'index'])->name('content-creators.index');
    Route::post('/content-creators', [ContentCreatorController::class, 'store'])->name('content-creators.store');
    Route::put('/content-creators/{contentCreator}', [ContentCreatorController::class, 'update'])->name('content-creators.update');
    Route::delete('/content-creators/{contentCreator}', [ContentCreatorController::class, 'destroy'])->name('content-creators.destroy');

    Route::get('/offline-sales', [OfflineSaleController::class, 'index'])->name('offline-sales.index');
    Route::post('/offline-sales', [OfflineSaleController::class, 'store'])->name('offline-sales.store');
    Route::put('/offline-sales/{sale}', [OfflineSaleController::class, 'update'])->name('offline-sales.update');
    Route::delete('/offline-sales/{sale}', [OfflineSaleController::class, 'destroy'])->name('offline-sales.destroy');
    Route::post('/offline-sales/{sale}/approve', [OfflineSaleController::class, 'approve'])->name('offline-sales.approve');
    Route::post('/offline-sales/{sale}/reject', [OfflineSaleController::class, 'reject'])->name('offline-sales.reject');
    Route::get('/offline-sales/{sale}/proof', [OfflineSaleController::class, 'showProof'])->name('offline-sales.proof');

    Route::post('/logout', [AuthenticatedSessionController::class, 'destroy'])->name('logout');
});


