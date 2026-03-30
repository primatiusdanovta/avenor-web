<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Inertia\Inertia;
use Inertia\Response;

class AuthenticatedSessionController extends Controller
{
    public function create(Request $request): Response
    {
        return Inertia::render('Auth/Login', [
            'branding' => [
                'logo' => asset('img/primatama.png'),
                'title' => config('app.name'),
                'subtitle' => 'Login menggunakan username dan password.',
            ],
            'captcha' => $this->issueCaptcha($request),
        ]);
    }

    public function captcha(Request $request): JsonResponse
    {
        return response()->json($this->issueCaptcha($request));
    }

    public function store(LoginRequest $request): RedirectResponse
    {
        $request->authenticate();
        $request->session()->regenerate();
        $request->session()->forget('login_captcha_answer');

        return redirect()->intended(route('dashboard'));
    }

    public function destroy(Request $request): RedirectResponse
    {
        Auth::guard('web')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('login');
    }

    private function issueCaptcha(Request $request): array
    {
        $left = random_int(1, 9);
        $right = random_int(1, 9);
        $request->session()->put('login_captcha_answer', (string) ($left + $right));

        return [
            'question' => sprintf('%d + %d = ?', $left, $right),
        ];
    }
}
