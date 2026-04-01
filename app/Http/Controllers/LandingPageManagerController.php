<?php

namespace App\Http\Controllers;

use App\Models\LandingPageContent;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class LandingPageManagerController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        return Inertia::render('LandingPageManager/Index', [
            'content' => LandingPageContent::groupedForManager(),
            'iconOptions' => ['spark', 'bloom', 'wood', 'pepper', 'amber', 'smoke', 'citrus', 'leaf'],
        ]);
    }

    public function updateSection(Request $request, string $section): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $allowedSections = ['hero', 'story', 'top_notes', 'heart_notes', 'base_notes', 'ingredients_intro'];
        abort_unless(in_array($section, $allowedSections, true), 404);

        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string', 'max:5000'],
            'image_path' => ['nullable', 'string', 'max:2048'],
            'is_active' => ['required', 'boolean'],
            'meta_data' => ['nullable', 'array'],
        ]);

        $row = LandingPageContent::query()->firstOrCreate(
            ['section_name' => $section],
            ['title' => $validated['title'], 'description' => $validated['description']]
        );

        $row->update([
            'title' => $validated['title'],
            'description' => $validated['description'],
            'image_path' => $validated['image_path'] ?: null,
            'is_active' => (bool) $validated['is_active'],
            'meta_data' => $validated['meta_data'] ?? ($row->meta_data ?? []),
        ]);

        return redirect()->route('landing-page-manager.index')->with('success', 'Konten section berhasil diperbarui.');
    }

    public function storeIngredient(Request $request): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string', 'max:2000'],
            'icon' => ['required', 'string', Rule::in(['spark', 'bloom', 'wood', 'pepper', 'amber', 'smoke', 'citrus', 'leaf'])],
            'is_active' => ['required', 'boolean'],
        ]);

        $order = (int) LandingPageContent::query()
            ->where('section_name', 'ingredient')
            ->get()
            ->max(fn (LandingPageContent $row) => (int) data_get($row->meta_data, 'order', 0)) + 1;

        LandingPageContent::query()->create([
            'section_name' => 'ingredient',
            'title' => $validated['title'],
            'description' => $validated['description'],
            'image_path' => null,
            'is_active' => (bool) $validated['is_active'],
            'meta_data' => [
                'key' => 'ingredient-' . Str::slug($validated['title']) . '-' . Str::lower(Str::random(5)),
                'icon' => $validated['icon'],
                'order' => $order,
            ],
        ]);

        return redirect()->route('landing-page-manager.index')->with('success', 'Ingredient baru berhasil ditambahkan.');
    }

    public function updateIngredient(Request $request, LandingPageContent $ingredient): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);
        abort_unless($ingredient->section_name === 'ingredient', 404);

        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string', 'max:2000'],
            'icon' => ['required', 'string', Rule::in(['spark', 'bloom', 'wood', 'pepper', 'amber', 'smoke', 'citrus', 'leaf'])],
            'is_active' => ['required', 'boolean'],
        ]);

        $ingredient->update([
            'title' => $validated['title'],
            'description' => $validated['description'],
            'is_active' => (bool) $validated['is_active'],
            'meta_data' => array_merge($ingredient->meta_data ?? [], [
                'icon' => $validated['icon'],
            ]),
        ]);

        return redirect()->route('landing-page-manager.index')->with('success', 'Ingredient berhasil diperbarui.');
    }

    public function destroyIngredient(Request $request, LandingPageContent $ingredient): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);
        abort_unless($ingredient->section_name === 'ingredient', 404);

        $ingredient->delete();

        return redirect()->route('landing-page-manager.index')->with('success', 'Ingredient berhasil dihapus.');
    }

    public function updateVisibility(Request $request): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $validated = $request->validate([
            'hero' => ['required', 'boolean'],
            'story' => ['required', 'boolean'],
            'notes' => ['required', 'boolean'],
            'ingredients' => ['required', 'boolean'],
        ]);

        $this->setSectionActive('hero', (bool) $validated['hero']);
        $this->setSectionActive('story', (bool) $validated['story']);
        foreach (['top_notes', 'heart_notes', 'base_notes'] as $section) {
            $this->setSectionActive($section, (bool) $validated['notes']);
        }
        $this->setSectionActive('ingredients_intro', (bool) $validated['ingredients']);

        return redirect()->route('landing-page-manager.index')->with('success', 'Visibility landing page berhasil diperbarui.');
    }

    private function setSectionActive(string $section, bool $isActive): void
    {
        $row = LandingPageContent::query()->firstWhere('section_name', $section);

        if ($row) {
            $row->update(['is_active' => $isActive]);
        }
    }
}
