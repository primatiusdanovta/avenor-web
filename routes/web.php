<?php

use App\Http\Controllers\Auth\AuthenticatedSessionController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\MarketingKpiController;
use App\Http\Controllers\SuperAdminUserController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return auth()->check()
        ? redirect()->route('dashboard')
        : redirect()->route('login');
});

Route::middleware('guest')->group(function () {
    Route::get('/login', [AuthenticatedSessionController::class, 'create'])->name('login');
    Route::post('/login', [AuthenticatedSessionController::class, 'store'])->name('login.store');
});

Route::middleware('auth')->group(function () {
    Route::get('/dashboard', DashboardController::class)->name('dashboard');

    Route::get('/users', [SuperAdminUserController::class, 'index'])->name('users.manage');
    Route::post('/users', [SuperAdminUserController::class, 'store'])->name('users.store');
    Route::put('/users/{user}', [SuperAdminUserController::class, 'update'])->name('users.update');
    Route::delete('/users/{user}', [SuperAdminUserController::class, 'destroy'])->name('users.destroy');

    Route::get('/marketing/kpi', [MarketingKpiController::class, 'index'])->name('marketing.kpi');
    Route::post('/marketing/attendance', [MarketingKpiController::class, 'storeAttendance'])->name('marketing.attendance.store');

    Route::post('/logout', [AuthenticatedSessionController::class, 'destroy'])->name('logout');
});