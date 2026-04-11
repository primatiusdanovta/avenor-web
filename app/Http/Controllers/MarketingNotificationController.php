<?php

namespace App\Http\Controllers;

use App\Models\MarketingNotification;
use App\Services\MarketingPushNotificationService;
use App\Support\MarketingNotificationSupport;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class MarketingNotificationController extends Controller
{
    public function __construct(
        private readonly MarketingPushNotificationService $pushNotificationService
    ) {
    }

    public function index(Request $request): Response
    {
        $this->authorizePermission($request, 'notifications.view');
        $storeId = $this->currentStoreId($request);

        MarketingNotificationSupport::publishDueNotifications();

        $notifications = MarketingNotification::query()
            ->where('store_id', $storeId)
            ->with('creator')
            ->orderByRaw("case when status = 'published' then 0 when status = 'scheduled' then 1 else 2 end")
            ->orderByDesc('published_at')
            ->orderByDesc('scheduled_at')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (MarketingNotification $notification) => [
                'id' => $notification->id,
                'title' => $notification->title,
                'body' => $notification->body,
                'excerpt' => MarketingNotificationSupport::excerpt($notification->body),
                'target_role' => $notification->target_role,
                'status' => $notification->status,
                'scheduled_at' => optional($notification->scheduled_at)->format('Y-m-d\TH:i'),
                'published_at' => optional($notification->published_at)->format('Y-m-d H:i:s'),
                'created_at' => optional($notification->created_at)->format('Y-m-d H:i:s'),
                'creator_name' => $notification->creator?->nama,
            ])
            ->values();

        return Inertia::render('Notifications/Index', [
            'notifications' => $notifications,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->authorizePermission($request, 'notifications.manage');

        $validated = $this->validatePayload($request);

        $isScheduled = $validated['delivery_type'] === 'scheduled';

        $notification = MarketingNotification::query()->create([
            'store_id' => $this->currentStoreId($request),
            'created_by' => $request->user()->id_user,
            'title' => $validated['title'],
            'body' => $validated['body'],
            'target_role' => $validated['target_role'],
            'status' => $isScheduled ? 'scheduled' : 'published',
            'scheduled_at' => $isScheduled ? $validated['scheduled_at'] : null,
            'published_at' => $isScheduled ? null : now(),
        ]);

        if (! $isScheduled) {
            $this->pushNotificationService->sendPublishedNotification($notification);
        }

        return redirect()->route('notifications.index')->with(
            'success',
            $isScheduled ? 'Notifikasi berhasil dijadwalkan.' : 'Notifikasi berhasil dikirim.'
        );
    }

    public function update(Request $request, MarketingNotification $notification): RedirectResponse
    {
        $this->authorizePermission($request, 'notifications.manage');
        $this->ensureStoreMatch($request, $notification);

        $validated = $this->validatePayload($request);
        $isScheduled = $validated['delivery_type'] === 'scheduled';

        $notification->update([
            'title' => $validated['title'],
            'body' => $validated['body'],
            'target_role' => $validated['target_role'],
            'status' => $isScheduled ? 'scheduled' : 'draft',
            'scheduled_at' => $isScheduled ? $validated['scheduled_at'] : null,
            'published_at' => null,
        ]);

        return redirect()->route('notifications.index')->with('success', 'Notifikasi berhasil diperbarui.');
    }

    public function publish(Request $request, MarketingNotification $notification): RedirectResponse
    {
        $this->authorizePermission($request, 'notifications.manage');
        $this->ensureStoreMatch($request, $notification);

        $notification->update([
            'status' => 'published',
            'published_at' => now(),
            'scheduled_at' => null,
        ]);

        $this->pushNotificationService->sendPublishedNotification($notification->fresh());

        return redirect()->route('notifications.index')->with('success', 'Notifikasi berhasil dipublikasikan.');
    }

    public function destroy(Request $request, MarketingNotification $notification): RedirectResponse
    {
        $this->authorizePermission($request, 'notifications.manage');
        $this->ensureStoreMatch($request, $notification);

        $notification->delete();

        return redirect()->route('notifications.index')->with('success', 'Notifikasi berhasil dihapus.');
    }

    private function validatePayload(Request $request): array
    {
        return $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'body' => ['required', 'string', 'max:5000'],
            'target_role' => ['required', 'in:marketing'],
            'delivery_type' => ['required', 'in:now,scheduled'],
            'scheduled_at' => ['nullable', 'date', 'after:now'],
        ]);
    }
}
