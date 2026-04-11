<?php

namespace App\Services;

use App\Models\MarketingNotification;
use App\Models\MobileAccessToken;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class MarketingPushNotificationService
{
    public function sendPublishedNotification(MarketingNotification $notification): array
    {
        $serverKey = trim((string) env('FCM_SERVER_KEY', ''));

        if ($serverKey === '') {
            Log::info('FCM_SERVER_KEY belum diatur. Push notification dilewati.', [
                'notification_id' => $notification->id,
            ]);

            return ['sent' => 0, 'skipped' => true];
        }

        $tokens = MobileAccessToken::query()
            ->with('user:id_user,role,status')
            ->whereNotNull('push_token')
            ->where(function ($query) {
                $query->whereNull('expires_at')
                    ->orWhere('expires_at', '>', now());
            })
            ->get()
            ->filter(fn (MobileAccessToken $token) => $token->user?->status === 'aktif'
                && $token->user?->role === $notification->target_role)
            ->filter(fn (MobileAccessToken $token) => $token->user?->stores()
                ->where('stores.id', $notification->store_id)
                ->exists())
            ->pluck('push_token')
            ->filter()
            ->unique()
            ->values();

        if ($tokens->isEmpty()) {
            return ['sent' => 0, 'skipped' => false];
        }

        $sent = 0;

        foreach ($tokens->chunk(500) as $chunk) {
            $response = Http::withHeaders([
                'Authorization' => 'key=' . $serverKey,
                'Content-Type' => 'application/json',
            ])->post('https://fcm.googleapis.com/fcm/send', [
                'registration_ids' => $chunk->all(),
                'priority' => 'high',
                'notification' => [
                    'title' => $notification->title,
                    'body' => $notification->body,
                    'sound' => 'default',
                ],
                'data' => [
                    'notification_id' => (string) $notification->id,
                    'target_role' => $notification->target_role,
                ],
            ]);

            if (! $response->successful()) {
                Log::warning('Gagal mengirim FCM notification.', [
                    'notification_id' => $notification->id,
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);

                continue;
            }

            $sent += count($chunk);
        }

        return ['sent' => $sent, 'skipped' => false];
    }
}
