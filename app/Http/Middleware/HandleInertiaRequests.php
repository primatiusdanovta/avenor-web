<?php

namespace App\Http\Middleware;

use Illuminate\Http\Request;
use Inertia\Middleware;

class HandleInertiaRequests extends Middleware
{
    protected $rootView = 'app';

    public function version(Request $request): ?string
    {
        return parent::version($request);
    }

    public function share(Request $request): array
    {
        $user = $request->user();
        $navigation = [['label' => 'Dashboard', 'href' => '/dashboard']];

        if ($user?->role === 'superadmin') {
            $navigation[] = ['label' => 'User Management', 'href' => '/users'];
        }

        if ($user?->role === 'marketing') {
            $navigation[] = ['label' => 'Marketing KPI', 'href' => '/marketing/kpi'];
        }

        return [
            ...parent::share($request),
            'appName' => config('app.name'),
            'navigation' => $navigation,
            'auth' => [
                'user' => $user
                    ? [
                        'id_user' => $user->id_user,
                        'nama' => $user->nama,
                        'role' => $user->role,
                        'status' => $user->status,
                    ]
                    : null,
            ],
            'flash' => [
                'success' => fn () => $request->session()->get('success'),
            ],
        ];
    }
}