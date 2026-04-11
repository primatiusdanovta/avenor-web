<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\GlobalSetting;
use App\Models\MobileAccessToken;
use App\Models\User;
use App\Support\MarketingMobileSupport;
use App\Support\SalesRole;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'nama' => ['required', 'string'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:120'],
        ]);

        $user = User::query()
            ->where('nama', $validated['nama'])
            ->whereIn('role', SalesRole::mobileRoles())
            ->where('status', 'aktif')
            ->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'nama' => 'Username atau password salah, atau akun tidak aktif.',
            ]);
        }

        $plainTextToken = Str::random(80);
        $expiresAt = now()->addDays((int) env('MOBILE_TOKEN_EXPIRES_DAYS', 30));

        MobileAccessToken::query()->create([
            'user_id' => $user->id_user,
            'name' => $validated['device_name'] ?? 'Sales Lapangan App',
            'token' => hash('sha256', $plainTextToken),
            'expires_at' => $expiresAt,
            'last_used_at' => now(),
        ]);

        return response()->json([
            'token' => $plainTextToken,
            'token_type' => 'Bearer',
            'expires_at' => $expiresAt->toIso8601String(),
            'user' => [
                'id_user' => $user->id_user,
                'nama' => $user->nama,
                'role' => $user->role,
                'status' => $user->status,
                'store' => optional(MarketingMobileSupport::currentStore($user), fn ($store) => [
                    'id' => $store->id,
                    'code' => $store->code,
                    'name' => $store->name,
                    'display_name' => $store->display_name,
                    'settings' => $store->settings ?? [],
                ]),
            ],
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();
        $socialHub = GlobalSetting::masterSocialHub();

        return response()->json([
            'user' => [
                'id_user' => $user->id_user,
                'nama' => $user->nama,
                'role' => $user->role,
                'status' => $user->status,
                'require_return_before_checkout' => (bool) $user->require_return_before_checkout,
                'sales_qr_url' => data_get($socialHub, 'sales_qr_url'),
                'sales_qr_name' => data_get($socialHub, 'sales_qr_name'),
                'store' => optional(MarketingMobileSupport::currentStore($user), fn ($store) => [
                    'id' => $store->id,
                    'code' => $store->code,
                    'name' => $store->name,
                    'display_name' => $store->display_name,
                    'settings' => $store->settings ?? [],
                ]),
            ],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $token = $request->attributes->get('mobileAccessToken');
        $token?->delete();

        return response()->json([
            'message' => 'Logout berhasil.',
        ]);
    }
}
