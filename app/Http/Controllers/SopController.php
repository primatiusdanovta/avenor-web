<?php

namespace App\Http\Controllers;

use App\Models\Sop;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class SopController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorizePermission($request, 'sops.view');
        $storeId = $this->currentStoreId($request);

        return Inertia::render('Sops/Index', [
            'items' => Sop::query()
                ->where(function ($query) use ($storeId) {
                    $query->whereNull('store_id')
                        ->orWhere('store_id', $storeId);
                })
                ->orderBy('title')
                ->get()
                ->map(fn (Sop $item) => [
                    'id_sop' => $item->id_sop,
                    'title' => $item->title,
                    'detail' => $item->detail,
                    'store_id' => $item->store_id,
                ])
                ->values(),
            'canManage' => $request->user()->hasPermission('sops.manage'),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->authorizePermission($request, 'sops.manage');
        $validated = $this->validatePayload($request);

        Sop::query()->create([
            'store_id' => $this->currentStoreId($request),
            ...$validated,
        ]);

        return redirect()->route('sops.index')->with('success', 'SOP berhasil ditambahkan.');
    }

    public function update(Request $request, Sop $sop): RedirectResponse
    {
        $this->authorizePermission($request, 'sops.manage');
        if ($sop->store_id !== null) {
            $this->ensureStoreMatch($request, $sop);
        }

        $sop->update($this->validatePayload($request));

        return redirect()->route('sops.index')->with('success', 'SOP berhasil diperbarui.');
    }

    public function destroy(Request $request, Sop $sop): RedirectResponse
    {
        $this->authorizePermission($request, 'sops.manage');
        if ($sop->store_id !== null) {
            $this->ensureStoreMatch($request, $sop);
        }

        $sop->delete();

        return redirect()->route('sops.index')->with('success', 'SOP berhasil dihapus.');
    }

    private function validatePayload(Request $request): array
    {
        return $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'detail' => ['required', 'string'],
        ]);
    }
}
