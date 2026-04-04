<?php

namespace App\Support;

use App\Models\MarketingNotification;

class MarketingNotificationSupport
{
    public static function publishDueNotifications(): void
    {
        MarketingNotification::query()
            ->where('status', 'scheduled')
            ->whereNotNull('scheduled_at')
            ->where('scheduled_at', '<=', now())
            ->update([
                'status' => 'published',
                'published_at' => now(),
                'updated_at' => now(),
            ]);
    }

    public static function excerpt(string $body, int $limit = 90): string
    {
        $plain = trim(preg_replace('/\s+/', ' ', strip_tags($body)) ?? '');

        if (mb_strlen($plain) <= $limit) {
            return $plain;
        }

        return rtrim(mb_substr($plain, 0, $limit - 3)) . '...';
    }
}
