<?php

namespace App\Http\Middleware;

use App\Models\MobileAccessToken;
use App\Support\SalesRole;
use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class AuthenticateMobileToken
{
    public function handle(Request $request, Closure $next): Response
    {
        $plainToken = $request->bearerToken();

        if (! $plainToken) {
            return $this->unauthorized('Token tidak ditemukan.');
        }

        $accessToken = MobileAccessToken::query()
            ->with('user')
            ->where('token', hash('sha256', $plainToken))
            ->first();

        $user = $accessToken?->user;

        if (! $accessToken || ! $user) {
            return $this->unauthorized('Token tidak valid.');
        }

        if ($user->status !== 'aktif' || ! SalesRole::isFieldRole($user->role)) {
            return $this->unauthorized('Akun tidak diizinkan mengakses aplikasi sales lapangan.');
        }

        if ($accessToken->expires_at && $accessToken->expires_at->isPast()) {
            $accessToken->delete();

            return $this->unauthorized('Token sudah kedaluwarsa. Silakan login ulang.');
        }

        $request->setUserResolver(static fn () => $user);
        $request->attributes->set('mobileAccessToken', $accessToken);
        Auth::setUser($user);

        $accessToken->forceFill([
            'last_used_at' => now(),
        ])->save();

        return $next($request);
    }

    private function unauthorized(string $message): JsonResponse
    {
        return response()->json([
            'message' => $message,
        ], 401);
    }
}
