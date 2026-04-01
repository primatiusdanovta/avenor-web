<?php

namespace App\Http\Controllers;

use App\Models\SeoSetting;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class SeoSettingController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        return Inertia::render('SeoSettings/Index', [
            'seo' => SeoSetting::forPage('landing'),
        ]);
    }

    public function update(Request $request): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'meta_description' => ['nullable', 'string', 'max:5000'],
            'meta_keywords' => ['nullable', 'string', 'max:5000'],
            'canonical_url' => ['nullable', 'string', 'max:2048'],
            'og_title' => ['nullable', 'string', 'max:255'],
            'og_description' => ['nullable', 'string', 'max:5000'],
            'og_image' => ['nullable', 'string', 'max:2048'],
            'robots' => ['required', 'string', 'max:255'],
            'schema_json' => ['nullable', 'string'],
            'is_active' => ['required', 'boolean'],
        ]);

        if (! empty($validated['schema_json'])) {
            json_decode($validated['schema_json'], true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                return back()->withErrors([
                    'schema_json' => 'Schema JSON tidak valid.',
                ]);
            }
        }

        $seo = SeoSetting::forPage('landing');

        $seo?->update($validated);

        return redirect()->route('seo-settings.index')->with('success', 'Pengaturan SEO berhasil diperbarui.');
    }
}
