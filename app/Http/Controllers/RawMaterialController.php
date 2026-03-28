<?php

namespace App\Http\Controllers;

use App\Models\HppCalculationItem;
use App\Models\RawMaterial;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
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
                'quantity' => (float) $material->quantity,
                'harga_satuan' => (float) $material->harga_satuan,
                'stock' => (float) $material->stock,
                'total_quantity' => (float) $material->total_quantity,
                'harga_total' => (float) $material->harga_total,
                'created_at' => optional($material->created_at)->format('Y-m-d H:i:s'),
                'option_label' => $material->nama_rm . ' | ' . $material->satuan,
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

        DB::transaction(function () use ($validated): void {
            RawMaterial::query()->create($this->buildPayload($validated) + ['created_at' => now()]);
        });

        return redirect()->route('raw-materials.index')->with('success', 'Raw material berhasil ditambahkan.');
    }

    public function update(Request $request, RawMaterial $rawMaterial): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $validated = $this->validatePayload($request, $rawMaterial);

        DB::transaction(function () use ($validated, $rawMaterial): void {
            $rawMaterial->update($this->buildPayload($validated));
            $this->syncHppItemStock($rawMaterial->fresh());
        });

        return redirect()->route('raw-materials.index')->with('success', 'Raw material berhasil diperbarui.');
    }

    public function restock(Request $request): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $validated = $request->validate([
            'id_rm' => ['required', 'exists:raw_materials,id_rm'],
            'stock' => ['required', 'numeric', 'min:0.01'],
        ]);

        DB::transaction(function () use ($validated): void {
            $rawMaterial = RawMaterial::query()->lockForUpdate()->findOrFail($validated['id_rm']);
            $stockToAdd = round((float) $validated['stock'], 2);
            $newStock = round((float) $rawMaterial->stock + $stockToAdd, 2);
            $newTotalQuantity = round((float) $rawMaterial->total_quantity + ($stockToAdd * (float) $rawMaterial->quantity), 2);

            $rawMaterial->update([
                'stock' => $newStock,
                'total_quantity' => $newTotalQuantity,
                'harga_total' => round($newStock * (float) $rawMaterial->harga, 2),
            ]);

            $this->syncHppItemStock($rawMaterial->fresh());
        });

        return redirect()->route('raw-materials.index')->with('success', 'Stock raw material berhasil ditambahkan.');
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
            'quantity' => ['required', 'numeric', 'min:0.01'],
            'stock' => ['required', 'numeric', 'min:0'],
        ]);
    }

    private function buildPayload(array $validated): array
    {
        $hargaSatuan = (float) $validated['quantity'] > 0 ? (float) $validated['harga'] / (float) $validated['quantity'] : 0;
        $totalQuantity = round((float) $validated['stock'] * (float) $validated['quantity'], 2);
        $hargaTotal = round((float) $validated['stock'] * (float) $validated['harga'], 2);

        return [
            'nama_rm' => $validated['nama_rm'],
            'satuan' => $validated['satuan'],
            'harga' => $validated['harga'],
            'quantity' => $validated['quantity'],
            'harga_satuan' => $hargaSatuan,
            'stock' => round((float) $validated['stock'], 2),
            'total_quantity' => $totalQuantity,
            'harga_total' => $hargaTotal,
        ];
    }

    private function syncHppItemStock(RawMaterial $rawMaterial): void
    {
        HppCalculationItem::query()
            ->where('id_rm', $rawMaterial->id_rm)
            ->update(['total_stock' => $rawMaterial->total_quantity]);
    }
}
