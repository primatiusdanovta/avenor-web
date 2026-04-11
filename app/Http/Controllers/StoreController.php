<?php

namespace App\Http\Controllers;

use App\Models\Store;
use App\Support\StoreContext;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class StoreController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorizePermission($request, 'stores.view');

        $stores = Store::query()
            ->orderBy('display_name')
            ->get()
            ->map(fn (Store $store) => [
                'id' => $store->id,
                'code' => $store->code,
                'name' => $store->name,
                'display_name' => $store->display_name,
                'status' => $store->status,
                'timezone' => $store->timezone,
                'currency' => $store->currency,
                'address' => $store->address,
                'settings' => $store->settings ?? [],
                'brand_title' => data_get($store->settings, 'brand_title'),
                'brand_image' => data_get($store->settings, 'brand_image'),
                'favicon' => data_get($store->settings, 'favicon'),
                'web_title' => data_get($store->settings, 'web_title'),
                'created_at' => optional($store->created_at)->format('Y-m-d H:i:s'),
                'updated_at' => optional($store->updated_at)->format('Y-m-d H:i:s'),
            ])
            ->values();

        return Inertia::render('Stores/Index', [
            'stores' => $stores,
            'canManage' => $request->user()->hasPermission('stores.manage'),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->authorizePermission($request, 'stores.manage');

        Store::query()->create($this->validatePayload($request));

        return redirect()->route('stores.index')->with('success', 'Store baru berhasil ditambahkan.');
    }

    public function update(Request $request, Store $store): RedirectResponse
    {
        $this->authorizePermission($request, 'stores.manage');

        $store->update($this->validatePayload($request, $store));

        return redirect()->route('stores.index')->with('success', 'Master store berhasil diperbarui.');
    }

    public function switch(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'store_id' => ['required', 'integer', 'exists:stores,id'],
        ]);

        abort_unless(StoreContext::setCurrentStore($request, (int) $validated['store_id']), 403);

        return back(303);
    }

    private function validatePayload(Request $request, ?Store $store = null): array
    {
        $validated = $request->validate([
            'code' => ['required', 'string', 'max:255', Rule::unique('stores', 'code')->ignore($store?->id)],
            'name' => ['required', 'string', 'max:255', Rule::unique('stores', 'name')->ignore($store?->id)],
            'display_name' => ['required', 'string', 'max:255'],
            'status' => ['required', 'in:active,inactive'],
            'timezone' => ['required', 'string', 'max:255'],
            'currency' => ['required', 'string', 'max:10'],
            'address' => ['nullable', 'string'],
            'brand_title' => ['nullable', 'string', 'max:255'],
            'brand_image' => ['nullable', 'string', 'max:2048'],
            'favicon' => ['nullable', 'string', 'max:2048'],
            'web_title' => ['nullable', 'string', 'max:255'],
        ]);

        $validated['settings'] = array_filter([
            'brand_title' => $validated['brand_title'] ?? null,
            'brand_image' => $validated['brand_image'] ?? null,
            'favicon' => $validated['favicon'] ?? null,
            'web_title' => $validated['web_title'] ?? null,
        ], fn ($value) => $value !== null && $value !== '');

        unset($validated['brand_title'], $validated['brand_image'], $validated['favicon'], $validated['web_title']);

        return $validated;
    }
}
