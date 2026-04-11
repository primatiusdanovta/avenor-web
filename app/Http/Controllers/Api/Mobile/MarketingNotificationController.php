<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\MarketingNotification;
use App\Support\MarketingNotificationSupport;
use App\Support\MarketingMobileSupport;
use App\Support\SalesRole;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MarketingNotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless(in_array($user?->role, SalesRole::mobileRoles(), true), 403);

        MarketingNotificationSupport::publishDueNotifications();

        $notifications = MarketingNotification::query()
            ->where('store_id', MarketingMobileSupport::currentStoreId($user))
            ->where('target_role', $user->role)
            ->where('status', 'published')
            ->whereNotNull('published_at')
            ->where('published_at', '<=', now())
            ->orderByDesc('published_at')
            ->orderByDesc('id')
            ->limit(30)
            ->get()
            ->map(fn (MarketingNotification $notification) => [
                'id' => $notification->id,
                'title' => $notification->title,
                'body' => $notification->body,
                'excerpt' => MarketingNotificationSupport::excerpt($notification->body, 120),
                'published_at' => optional($notification->published_at)->format('Y-m-d H:i:s'),
            ])
            ->values();

        return response()->json([
            'notifications' => $notifications,
        ]);
    }

    public function registerToken(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless(in_array($user?->role, SalesRole::mobileRoles(), true), 403);

        $validated = $request->validate([
            'push_token' => ['required', 'string', 'max:2048'],
            'platform' => ['required', 'in:android,ios'],
        ]);

        $accessToken = $request->attributes->get('mobileAccessToken');
        abort_unless($accessToken, 401);

        $accessToken->update([
            'push_token' => $validated['push_token'],
            'push_platform' => $validated['platform'],
            'push_token_updated_at' => now(),
        ]);

        return response()->json([
            'message' => 'Push token berhasil disimpan.',
        ]);
    }
}

