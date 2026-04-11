<?php

namespace App\Http\Controllers;

use App\Models\Promo;
use App\Support\SalesRole;
use App\Support\StoreFeature;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class PromoController extends Controller
{
    public function index(Request $request): Response
    {
        $isSmoothiesSweetie = StoreFeature::isSmoothiesSweetie($request);
        $isAllowedRole = in_array($request->user()->role, ['superadmin', 'admin'], true) || ($isSmoothiesSweetie && $request->user()->role === SalesRole::OWNER);
        abort_unless($isAllowedRole, 403);

        $promos = Promo::query()
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (Promo $promo) => [
                'id' => $promo->id,
                'kode_promo' => $promo->kode_promo,
                'nama_promo' => $promo->nama_promo,
                'potongan' => (float) $promo->potongan,
                'masa_aktif' => optional($promo->masa_aktif)->format('Y-m-d'),
                'minimal_quantity' => (int) $promo->minimal_quantity,
                'minimal_belanja' => (float) $promo->minimal_belanja,
                'is_active' => optional($promo->masa_aktif)?->gte(today()) ?? false,
                'created_at' => optional($promo->created_at)->format('Y-m-d H:i:s'),
            ])
            ->values();

        return Inertia::render('Promos/Index', ['promos' => $promos]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->authorizeManagement($request);

        $validated = $request->validate([
            'nama_promo' => ['required', 'string', 'max:255'],
            'potongan' => ['required', 'numeric', 'min:0'],
            'masa_aktif' => ['required', 'date', 'after_or_equal:today'],
            'minimal_quantity' => ['required', 'integer', 'min:1'],
            'minimal_belanja' => ['required', 'numeric', 'min:0'],
        ]);

        Promo::query()->create([
            'kode_promo' => $this->generateCode($validated['nama_promo']),
            'nama_promo' => $validated['nama_promo'],
            'potongan' => $validated['potongan'],
            'masa_aktif' => $validated['masa_aktif'],
            'minimal_quantity' => $validated['minimal_quantity'],
            'minimal_belanja' => $validated['minimal_belanja'],
            'created_at' => now(),
        ]);

        return redirect()->route('promos.index')->with('success', 'Promo berhasil ditambahkan.');
    }

    public function update(Request $request, Promo $promo): RedirectResponse
    {
        $this->authorizeManagement($request);

        $validated = $request->validate([
            'nama_promo' => ['required', 'string', 'max:255'],
            'potongan' => ['required', 'numeric', 'min:0'],
            'masa_aktif' => ['required', 'date'],
            'minimal_quantity' => ['required', 'integer', 'min:1'],
            'minimal_belanja' => ['required', 'numeric', 'min:0'],
        ]);

        $promo->update($validated);

        return redirect()->route('promos.index')->with('success', 'Promo berhasil diperbarui.');
    }

    public function destroy(Request $request, Promo $promo): RedirectResponse
    {
        $this->authorizeManagement($request);

        $promo->delete();

        return redirect()->route('promos.index')->with('success', 'Promo berhasil dihapus.');
    }

    private function authorizeManagement(Request $request): void
    {
        $isSmoothiesSweetie = StoreFeature::isSmoothiesSweetie($request);
        $isAllowedRole = in_array($request->user()->role, ['superadmin', 'admin'], true) || ($isSmoothiesSweetie && $request->user()->role === SalesRole::OWNER);
        abort_unless($isAllowedRole, 403);
    }

    private function generateCode(string $namaPromo): string
    {
        $initials = Str::of($namaPromo)
            ->upper()
            ->replaceMatches('/[^A-Z0-9 ]/', '')
            ->explode(' ')
            ->filter()
            ->map(fn (string $part) => Str::substr($part, 0, 1))
            ->join('');

        return Str::limit($initials ?: 'PR', 5, '') . now()->format('Ymd');
    }
}