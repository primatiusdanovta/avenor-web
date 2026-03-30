<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title inertia>{{ config('app.name') }}</title>
    @inertiaHead

    <link rel="stylesheet" href="{{ asset('vendor/fontawesome-free/css/all.min.css') }}">

    @php
        $hasViteAssets = file_exists(public_path('build/manifest.json')) || file_exists(public_path('hot'));
    @endphp

    @if (! app()->runningUnitTests() && $hasViteAssets)
        @vite(['resources/css/app.css', 'resources/js/app.js'])
    @endif
</head>
<body class="hold-transition layout-fixed sidebar-expand-lg bg-body-tertiary">
    @inertia
</body>
</html>
