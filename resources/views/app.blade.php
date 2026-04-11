<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <meta name="robots" content="noindex,nofollow">
    <title inertia>{{ config('app.name') }}</title>
    @inertiaHead
    @include('partials.google-tag')

    <link rel="icon" type="image/png" href="{{ asset('img/avenor_hitam.png') }}">
    <link rel="apple-touch-icon" href="{{ asset('img/avenor_hitam.png') }}">
    <link rel="stylesheet" href="{{ asset('vendor/fontawesome-free/css/all.min.css') }}">

    @php
        $hasViteAssets = file_exists(public_path('build/manifest.json')) || file_exists(public_path('hot'));
    @endphp

    @if (! app()->runningUnitTests() && $hasViteAssets)
        @vite(['resources/css/app.css', 'resources/js/app.js'])
    @endif
    <style>
        .global-loading-overlay {
            position: fixed;
            inset: 0;
            display: none;
            align-items: center;
            justify-content: center;
            background: rgba(15, 23, 42, 0.34);
            backdrop-filter: blur(2px);
            z-index: 2000;
        }

        .global-loading-overlay.is-visible {
            display: flex;
        }

        .global-loading-card {
            width: min(92vw, 420px);
            background: #ffffff;
            border-radius: 18px;
            padding: 1rem 1rem 0.9rem;
            box-shadow: 0 24px 60px rgba(15, 23, 42, 0.22);
        }

        .global-loading-label {
            font-size: 0.92rem;
            font-weight: 600;
            color: #1f2937;
            margin-bottom: 0.75rem;
        }

        .global-loading-progress {
            height: 0.7rem;
            border-radius: 999px;
            overflow: hidden;
            background: #e5e7eb;
        }

        .global-loading-bar {
            width: 0%;
            height: 100%;
            border-radius: 999px;
            background: linear-gradient(90deg, #0f766e 0%, #14b8a6 100%);
            transition: width 0.2s ease;
        }
    </style>
</head>
<body class="hold-transition layout-fixed sidebar-expand-lg bg-body-tertiary">
    <script>
        window.AVENOR_ADMIN_PREFIX = @json('/' . trim((string) env('ADMIN_ROUTE_PREFIX', 'administrator'), '/'));
    </script>
    <div id="global-loading-overlay" class="global-loading-overlay" aria-hidden="true">
        <div class="global-loading-card">
            <div class="global-loading-label">Memuat halaman...</div>
            <div class="global-loading-progress">
                <div id="global-loading-bar" class="global-loading-bar"></div>
            </div>
        </div>
    </div>
    @inertia
</body>
</html>
