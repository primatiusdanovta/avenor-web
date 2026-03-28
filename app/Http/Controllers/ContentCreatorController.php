<?php

namespace App\Http\Controllers;

use App\Models\ContentCreator;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class ContentCreatorController extends Controller
{
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
        $this->authorizeManagement($request);

        $contentCreators = ContentCreator::query()
            ->orderByDesc('id_contentcreator')
            ->get()
            ->map(fn (ContentCreator $creator) => [
                'id_contentcreator' => $creator->id_contentcreator,
                'nama' => $creator->nama,
                'bidang' => $creator->bidang ?? [],
                'username_instagram' => $creator->username_instagram,
                'username_tiktok' => $creator->username_tiktok,
                'followers_instagram' => (int) ($creator->followers_instagram ?? 0),
                'followers_tiktok' => (int) ($creator->followers_tiktok ?? 0),
                'range_fee_percontent' => $creator->range_fee_percontent,
                'jenis_konten' => $creator->jenis_konten,
                'no_telp' => $creator->no_telp,
                'wilayah' => $creator->wilayah,
                'created_at' => optional($creator->created_at)->format('Y-m-d H:i:s'),
            ])
            ->values();

        return Inertia::render('ContentCreators/Index', [
            'contentCreators' => $contentCreators,
            'bidangOptions' => self::BIDANG_OPTIONS,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->authorizeManagement($request);

        $validated = $this->validatePayload($request);

        ContentCreator::query()->create([
            ...$validated,
            'no_telp' => $this->normalizePhone($validated['no_telp'] ?? null),
            'created_at' => now(),
        ]);

        return redirect()->route('content-creators.index')->with('success', 'Content creator berhasil ditambahkan.');
    }

    public function update(Request $request, ContentCreator $contentCreator): RedirectResponse
    {
        $this->authorizeManagement($request);

        $validated = $this->validatePayload($request);

        $contentCreator->update([
            ...$validated,
            'no_telp' => $this->normalizePhone($validated['no_telp'] ?? null),
        ]);

        return redirect()->route('content-creators.index')->with('success', 'Content creator berhasil diperbarui.');
    }

    public function destroy(Request $request, ContentCreator $contentCreator): RedirectResponse
    {
        $this->authorizeManagement($request);

        $contentCreator->delete();

        return redirect()->route('content-creators.index')->with('success', 'Content creator berhasil dihapus.');
    }

    private function authorizeManagement(Request $request): void
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);
    }

    private function validatePayload(Request $request): array
    {
        return $request->validate([
            'nama' => ['required', 'string', 'max:255'],
            'bidang' => ['required', 'array', 'min:1'],
            'bidang.*' => ['required', 'string', Rule::in(self::BIDANG_OPTIONS)],
            'username_instagram' => ['nullable', 'string', 'max:255'],
            'username_tiktok' => ['nullable', 'string', 'max:255'],
            'followers_instagram' => ['nullable', 'integer', 'min:0'],
            'followers_tiktok' => ['nullable', 'integer', 'min:0'],
            'range_fee_percontent' => ['nullable', 'string', 'max:255'],
            'jenis_konten' => ['nullable', 'string', 'max:255'],
            'no_telp' => ['nullable', 'string', 'max:30'],
            'wilayah' => ['nullable', 'string', 'max:255'],
        ]);
    }

    private function normalizePhone(?string $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $normalized = preg_replace('/\D+/', '', $value) ?? '';

        return $normalized !== '' ? $normalized : null;
    }
}
