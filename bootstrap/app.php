<?php

use App\Http\Middleware\AuthenticateMobileToken;
use App\Http\Middleware\EnsureSuperadmin;
use App\Http\Middleware\HandleInertiaRequests;
use App\Http\Middleware\SecurityHeaders;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Console\Scheduling\Schedule;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withSchedule(function (Schedule $schedule): void {
        $schedule->command('marketing-notifications:dispatch-scheduled')->everyMinute();
    })
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'superadmin' => EnsureSuperadmin::class,
            'mobile.auth' => AuthenticateMobileToken::class,
        ]);

        $middleware->web(append: [
            SecurityHeaders::class,
            HandleInertiaRequests::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })->create();
