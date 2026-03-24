<?php

namespace App\Http\Controllers;

use App\Models\RawMaterial;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class RawMaterialController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $materials = RawMaterial::query()
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (RawMaterial $material) => [
                'id_rm' => $material->id_rm,
                'nama_rm' => $material->nama_rm,
                'satuan' => $material->satuan,
                'harga' => (float) $material->harga,
                'quantity' => (int) $material->quantity,
                'harga_satuan' => (float) $material->harga_satuan,
                'stock' => (int) $material->stock,
                'total_quantity' => (int) $material->total_quantity,
                'harga_total' => (float) $material->harga_total,
                'created_at' => optional($material->created_at)->format('Y-m-d H:i:s'),
            ])
            ->values();

        return Inertia::render('RawMaterials/Index', [
            'materials' => $materials,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $validated = $this->validatePayload($request);

        RawMaterial::query()->create($this->buildPayload($validated) + ['created_at' => now()]);

        return redirect()->route('raw-materials.index')->with('success', 'Raw material berhasil ditambahkan.');
    }

    public function update(Request $request, RawMaterial $rawMaterial): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $validated = $this->validatePayload($request, $rawMaterial);
        $rawMaterial->update($this->buildPayload($validated));

        return redirect()->route('raw-materials.index')->with('success', 'Raw material berhasil diperbarui.');
    }

    public function destroy(Request $request, RawMaterial $rawMaterial): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $rawMaterial->delete();

        return redirect()->route('raw-materials.index')->with('success', 'Raw material berhasil dihapus.');
    }

    private function validatePayload(Request $request, ?RawMaterial $rawMaterial = null): array
    {
        return $request->validate([
            'nama_rm' => [
                'required',
                'string',
                'max:255',
                Rule::unique('raw_materials', 'nama_rm')->ignore($rawMaterial?->id_rm, 'id_rm'),
            ],
            'satuan' => ['required', Rule::in(['pcs', 'ML'])],
            'harga' => ['required', 'numeric', 'min:0'],
            'quantity' => ['required', 'integer', 'min:1'],
            'stock' => ['required', 'integer', 'min:0'],
        ]);
    }

    private function buildPayload(array $validated): array
    {
        $hargaSatuan = $validated['harga'] / $validated['quantity'];
        $totalQuantity = $validated['stock'] * $validated['quantity'];
        $hargaTotal = $validated['stock'] * $validated['harga'];

        return [
            'nama_rm' => $validated['nama_rm'],
            'satuan' => $validated['satuan'],
            'harga' => $validated['harga'],
            'quantity' => $validated['quantity'],
            'harga_satuan' => $hargaSatuan,
            'stock' => $validated['stock'],
            'total_quantity' => $totalQuantity,
            'harga_total' => $hargaTotal,
        ];
    }
}
