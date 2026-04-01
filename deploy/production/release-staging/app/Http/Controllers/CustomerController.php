<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use App\Models\OfflineSale;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class CustomerController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorizeManagement($request);

        $latestPurchaseItems = OfflineSale::query()
            ->whereNotNull('id_pelanggan')
            ->whereNotNull('created_at')
            ->get(['id_pelanggan', 'nama_product', 'quantity', 'created_at'])
            ->groupBy('id_pelanggan')
            ->map(function ($sales) {
                $latestTimestamp = optional($sales->max('created_at'))?->format('Y-m-d H:i:s');

                return $sales
                    ->filter(fn (OfflineSale $sale) => optional($sale->created_at)->format('Y-m-d H:i:s') === $latestTimestamp)
                    ->groupBy('nama_product')
                    ->map(fn ($items, $productName) => trim(($productName ?: 'Produk') . ' (' . (int) $items->sum('quantity') . ')'))
                    ->values()
                    ->implode(', ');
            });

        $customers = Customer::query()
            ->orderByDesc('pembelian_terakhir')
            ->orderByDesc('id_pelanggan')
            ->get()
            ->map(fn (Customer $customer) => [
                'id_pelanggan' => $customer->id_pelanggan,
                'nama' => $customer->nama,
                'no_telp' => $customer->no_telp,
                'tiktok_instagram' => $customer->tiktok_instagram,
                'created_at' => optional($customer->created_at)->format('Y-m-d H:i:s'),
                'pembelian_terakhir' => optional($customer->pembelian_terakhir)->format('Y-m-d H:i:s'),
                'latest_purchase_items' => $latestPurchaseItems->get($customer->id_pelanggan, '-'),
            ])
            ->values();

        return Inertia::render('Customers/Index', [
            'customers' => $customers,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->authorizeManagement($request);

        $validated = $this->validatePayload($request);

        Customer::query()->create([
            'nama' => $validated['nama'] ?: null,
            'no_telp' => $validated['no_telp'] ?: null,
            'tiktok_instagram' => $validated['tiktok_instagram'] ?: null,
            'created_at' => now(),
            'pembelian_terakhir' => $validated['pembelian_terakhir'] ?: null,
        ]);

        return redirect()->route('customers.index')->with('success', 'Data pelanggan berhasil ditambahkan.');
    }

    public function update(Request $request, Customer $customer): RedirectResponse
    {
        $this->authorizeManagement($request);

        $validated = $this->validatePayload($request, $customer);

        $customer->update([
            'nama' => $validated['nama'] ?: null,
            'no_telp' => $validated['no_telp'] ?: null,
            'tiktok_instagram' => $validated['tiktok_instagram'] ?: null,
            'pembelian_terakhir' => $validated['pembelian_terakhir'] ?: null,
        ]);

        return redirect()->route('customers.index')->with('success', 'Data pelanggan berhasil diperbarui.');
    }

    public function destroy(Request $request, Customer $customer): RedirectResponse
    {
        $this->authorizeManagement($request);

        $customer->delete();

        return redirect()->route('customers.index')->with('success', 'Data pelanggan berhasil dihapus.');
    }

    private function authorizeManagement(Request $request): void
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);
    }

    private function validatePayload(Request $request, ?Customer $customer = null): array
    {
        $request->merge([
            'no_telp' => $this->normalizePhone($request->input('no_telp')),
        ]);

        return $request->validate([
            'nama' => ['nullable', 'string', 'max:255'],
            'no_telp' => [
                'nullable',
                'string',
                'max:30',
                Rule::unique('customers', 'no_telp')->ignore($customer?->id_pelanggan, 'id_pelanggan'),
            ],
            'tiktok_instagram' => ['nullable', 'string', 'max:255'],
            'pembelian_terakhir' => ['nullable', 'date'],
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
