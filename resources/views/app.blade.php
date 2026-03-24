<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    @inertiaHead

    @php
        $hasViteAssets = file_exists(public_path('build/manifest.json')) || file_exists(public_path('hot'));
    @endphp

    @if (! app()->runningUnitTests() && $hasViteAssets)
        @vite(['resources/css/app.css', 'resources/js/app.js'])
    @endif
</head>
<body>
    @inertia
</body>
</html>