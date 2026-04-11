<?php

namespace App\Http\Controllers;

use App\Models\ExtraTopping;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class ExtraToppingController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorizePermission($request, 'extra_toppings.view');
        $storeId = $this->currentStoreId($request);

        return Inertia::render('ExtraToppings/Index', [
            'items' => ExtraTopping::query()
                ->where('store_id', $storeId)
                ->orderByDesc('is_active')
                ->orderBy('name')
                ->get()
                ->map(fn (ExtraTopping $item) => [
                    'id' => $item->id,
                    'name' => $item->name,
                    'price' => (float) $item->price,
                    'is_active' => (bool) $item->is_active,
                ])
                ->values(),
            'canManage' => $request->user()->hasPermission('extra_toppings.manage'),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->authorizePermission($request, 'extra_toppings.manage');
        $storeId = $this->currentStoreId($request);
        $validated = $this->validatePayload($request, $storeId);

        ExtraTopping::query()->create([
            'store_id' => $storeId,
            ...$validated,
        ]);

        return redirect()->route('extra-toppings.index')->with('success', 'Extra topping berhasil ditambahkan.');
    }

    public function update(Request $request, ExtraTopping $extraTopping): RedirectResponse
    {
        $this->authorizePermission($request, 'extra_toppings.manage');
        $this->ensureStoreMatch($request, $extraTopping);
        $validated = $this->validatePayload($request, $this->currentStoreId($request), $extraTopping);

        $extraTopping->update($validated);

        return redirect()->route('extra-toppings.index')->with('success', 'Extra topping berhasil diperbarui.');
    }

    public function destroy(Request $request, ExtraTopping $extraTopping): RedirectResponse
    {
        $this->authorizePermission($request, 'extra_toppings.manage');
        $this->ensureStoreMatch($request, $extraTopping);
        $extraTopping->delete();

        return redirect()->route('extra-toppings.index')->with('success', 'Extra topping berhasil dihapus.');
    }

    private function validatePayload(Request $request, int $storeId, ?ExtraTopping $extraTopping = null): array
    {
        return $request->validate([
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('extra_toppings', 'name')
                    ->where(fn ($query) => $query->where('store_id', $storeId))
                    ->ignore($extraTopping?->id),
            ],
            'price' => ['required', 'numeric', 'min:0'],
            'is_active' => ['required', 'boolean'],
        ]);
    }
}
