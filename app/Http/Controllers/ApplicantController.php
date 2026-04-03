<?php

namespace App\Http\Controllers;

use App\Models\CareerApplication;
use App\Models\ContentCreator;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Inertia\Inertia;
use Inertia\Response;

class ApplicantController extends Controller
{
    private const DEFAULT_BIDANG = 'Lifestyle';

    private const BIDANG_OPTIONS = [
        'Travel',
        'Lifestyle',
        'Perfume',
        'Fashion',
        'Body Care',
        'Hair care',
        'Skincare',
        'Daily Activities',
    ];

    public function index(Request $request): Response
    {
        $this->authorizeSuperadmin($request);

        $applications = CareerApplication::query()
            ->with('contentCreator')
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->get()
            ->map(fn (CareerApplication $application) => $this->transformApplication($application))
            ->values();

        return Inertia::render('Applicants/Index', [
            'applicants' => $applications,
        ]);
    }

    public function connectToContentCreator(Request $request): RedirectResponse
    {
        $this->authorizeSuperadmin($request);

        $validated = $request->validate([
            'application_ids' => ['required', 'array', 'min:1'],
            'application_ids.*' => ['required', 'integer', 'exists:career_applications,id'],
        ]);

        $applications = CareerApplication::query()
            ->whereIn('id', $validated['application_ids'])
            ->get()
            ->keyBy('id');

        $connectedCount = 0;
        $skippedCount = 0;

        DB::transaction(function () use ($validated, $applications, &$connectedCount, &$skippedCount) {
            foreach ($validated['application_ids'] as $applicationId) {
                /** @var CareerApplication|null $application */
                $application = $applications->get($applicationId);

                if (! $application || $application->content_creator_id) {
                    $skippedCount++;
                    continue;
                }

                $creator = ContentCreator::query()->create([
                    ...$this->buildContentCreatorPayload($application),
                    'created_at' => now(),
                ]);

                $application->update([
                    'status' => 'connected_to_content_creator',
                    'content_creator_id' => $creator->getKey(),
                    'transferred_to_content_creator_at' => now(),
                ]);

                $connectedCount++;
            }
        });

        if ($connectedCount === 0) {
            return redirect()
                ->route('applicants.index')
                ->with('warning', $skippedCount > 0
                    ? 'Tidak ada applicant baru yang dipindahkan. Data yang dipilih sudah pernah terhubung ke Content Creator.'
                    : 'Tidak ada applicant yang berhasil dipindahkan.');
        }

        $message = $connectedCount === 1
            ? '1 applicant berhasil dipindahkan ke Content Creator.'
            : "{$connectedCount} applicant berhasil dipindahkan ke Content Creator.";

        if ($skippedCount > 0) {
            $message .= " {$skippedCount} data dilewati karena sudah pernah terhubung.";
        }

        return redirect()
            ->route('applicants.index')
            ->with('success', $message);
    }

    private function authorizeSuperadmin(Request $request): void
    {
        abort_unless($request->user()?->role === 'superadmin', 403);
    }

    private function transformApplication(CareerApplication $application): array
    {
        $responses = collect($application->responses ?? []);
        $uploadedFiles = collect($application->uploaded_files ?? []);

        return [
            'id' => $application->id,
            'job_title' => $application->job_title,
            'status' => $application->status,
            'created_at' => optional($application->created_at)->format('Y-m-d H:i:s'),
            'transferred_to_content_creator_at' => optional($application->transferred_to_content_creator_at)->format('Y-m-d H:i:s'),
            'content_creator_id' => $application->content_creator_id,
            'content_creator' => $application->contentCreator ? [
                'id_contentcreator' => $application->contentCreator->id_contentcreator,
                'nama' => $application->contentCreator->nama,
            ] : null,
            'preview' => [
                'name' => $this->extractValue($responses, ['full_name', 'name', 'nama', 'applicant_name']) ?: 'Applicant #' . $application->id,
                'phone' => $this->extractValue($responses, ['phone', 'phone_number', 'mobile_phone', 'whatsapp', 'no_telp', 'nomor_telepon']),
                'instagram' => $this->extractValue($responses, ['instagram', 'instagram_username', 'username_instagram']),
                'tiktok' => $this->extractValue($responses, ['tiktok', 'tiktok_username', 'username_tiktok']),
                'wilayah' => $this->extractValue($responses, ['wilayah', 'domisili', 'city', 'location', 'alamat']),
            ],
            'responses' => $responses
                ->map(function (array $item, string $key) {
                    return [
                        'key' => $key,
                        'label' => trim((string) data_get($item, 'label', $key)),
                        'value' => is_array(data_get($item, 'value'))
                            ? implode(', ', data_get($item, 'value'))
                            : (string) data_get($item, 'value'),
                    ];
                })
                ->values()
                ->all(),
            'uploaded_files' => $uploadedFiles
                ->map(function (array $item, string $key) {
                    $path = (string) data_get($item, 'path', '');

                    return [
                        'key' => $key,
                        'label' => trim((string) data_get($item, 'label', $key)),
                        'original_name' => (string) data_get($item, 'original_name', basename($path)),
                        'url' => $path !== '' ? Storage::disk('public')->url($path) : null,
                    ];
                })
                ->values()
                ->all(),
        ];
    }

    private function buildContentCreatorPayload(CareerApplication $application): array
    {
        $responses = collect($application->responses ?? []);
        $name = $this->extractValue($responses, ['full_name', 'name', 'nama', 'applicant_name']) ?: 'Applicant #' . $application->id;
        $bidang = $this->extractBidang($responses);

        return [
            'nama' => $name,
            'bidang' => $bidang !== [] ? $bidang : [self::DEFAULT_BIDANG],
            'username_instagram' => $this->normalizeSocialHandle($this->extractValue($responses, ['instagram', 'instagram_username', 'username_instagram'])),
            'username_tiktok' => $this->normalizeSocialHandle($this->extractValue($responses, ['tiktok', 'tiktok_username', 'username_tiktok'])),
            'followers_instagram' => $this->normalizeFollowers($this->extractValue($responses, ['followers_instagram', 'instagram_followers'])),
            'followers_tiktok' => $this->normalizeFollowers($this->extractValue($responses, ['followers_tiktok', 'tiktok_followers'])),
            'range_fee_percontent' => $this->extractValue($responses, ['fee_range', 'range_fee', 'range_fee_percontent', 'rate_card']),
            'jenis_konten' => $this->extractValue($responses, ['jenis_konten', 'content_type', 'niche', 'specialty']),
            'no_telp' => $this->normalizePhone($this->extractValue($responses, ['phone', 'phone_number', 'mobile_phone', 'whatsapp', 'no_telp', 'nomor_telepon'])),
            'wilayah' => $this->extractValue($responses, ['wilayah', 'domisili', 'city', 'location', 'alamat']),
        ];
    }

    private function extractValue(Collection $responses, array $keys): ?string
    {
        foreach ($keys as $key) {
            $candidate = data_get($responses->get($key), 'value');
            if (is_string($candidate) && trim($candidate) !== '') {
                return trim($candidate);
            }
        }

        return null;
    }

    private function extractBidang(Collection $responses): array
    {
        $raw = $this->extractValue($responses, ['bidang', 'category', 'kategori', 'niche', 'specialty']);
        if ($raw === null) {
            return [];
        }

        $parts = preg_split('/[,\/\n]+/', $raw) ?: [];

        return collect($parts)
            ->map(fn ($part) => trim($part))
            ->filter()
            ->map(function (string $part) {
                $match = collect(self::BIDANG_OPTIONS)->first(
                    fn (string $option) => strcasecmp($option, $part) === 0
                );

                return $match ?: null;
            })
            ->filter()
            ->unique()
            ->values()
            ->all();
    }

    private function normalizePhone(?string $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $normalized = preg_replace('/\D+/', '', $value) ?? '';

        return $normalized !== '' ? $normalized : null;
    }

    private function normalizeSocialHandle(?string $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $normalized = ltrim(trim($value), '@');

        return $normalized !== '' ? $normalized : null;
    }

    private function normalizeFollowers(?string $value): int
    {
        if ($value === null) {
            return 0;
        }

        $numeric = preg_replace('/\D+/', '', $value) ?? '';

        return $numeric !== '' ? (int) $numeric : 0;
    }
}
