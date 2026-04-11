<?php

namespace App\Http\Controllers;

use App\Models\HppCalculationItem;
use App\Models\RawMaterial;
use App\Support\RawMaterialUsage;
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
        $this->authorizePermission($request, 'raw_materials.view');
        $storeId = $this->currentStoreId($request);

        $materials = RawMaterial::query()
            ->where('store_id', $storeId)
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (RawMaterial $material) => [
                'id_rm' => $material->id_rm,
                'nama_rm' => $material->nama_rm,
                'satuan' => $material->satuan,
                'harga' => (float) $material->harga,
                'quantity' => RawMaterialUsage::displayQuantity((float) $material->quantity, $material->satuan),
                'harga_satuan' => (float) $material->harga_satuan,
                'stock' => (float) $material->stock,
                'total_quantity' => RawMaterialUsage::displayQuantity((float) $material->total_quantity, $material->satuan),
                'waste_materials' => RawMaterialUsage::displayQuantity((float) $material->waste_materials, $material->satuan),
                'waste_percentage' => (float) $material->waste_percentage,
                'waste_loss_percentage' => (float) $material->waste_loss_percentage,
                'waste_loss_amount' => (float) $material->waste_loss_amount,
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
        $this->authorizePermission($request, 'raw_materials.manage');
        $storeId = $this->currentStoreId($request);

        $validated = $this->validatePayload($request);

        DB::transaction(function () use ($validated, $storeId): void {
            RawMaterial::query()->create($this->buildPayload($validated) + [
                'store_id' => $storeId,
                'created_at' => now(),
            ]);
        });

        return redirect()->route('raw-materials.index')->with('success', 'Raw material berhasil ditambahkan.');
    }

    public function update(Request $request, RawMaterial $rawMaterial): RedirectResponse
    {
        $this->authorizePermission($request, 'raw_materials.manage');
        $this->ensureStoreMatch($request, $rawMaterial);

        $validated = $this->validatePayload($request, $rawMaterial);

        DB::transaction(function () use ($validated, $rawMaterial): void {
            $rawMaterial->update($this->buildPayload($validated));
            $this->syncHppItemStock($rawMaterial->fresh());
        });

        return redirect()->route('raw-materials.index')->with('success', 'Raw material berhasil diperbarui.');
    }

    public function restock(Request $request): RedirectResponse
    {
        $this->authorizePermission($request, 'raw_materials.manage');

        $validated = $request->validate([
            'id_rm' => ['required', 'exists:raw_materials,id_rm'],
            'stock' => ['required', 'numeric', 'min:0.01'],
        ]);

        $storeId = $this->currentStoreId($request);

        DB::transaction(function () use ($validated, $storeId): void {
            $rawMaterial = RawMaterial::query()->lockForUpdate()->findOrFail($validated['id_rm']);
            abort_unless((int) $rawMaterial->store_id === $storeId, 404);
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
        $this->authorizePermission($request, 'raw_materials.manage');
        $this->ensureStoreMatch($request, $rawMaterial);

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
                Rule::unique('raw_materials', 'nama_rm')
                    ->where(fn ($query) => $query->where('store_id', $this->currentStoreId($request)))
                    ->ignore($rawMaterial?->id_rm, 'id_rm'),
            ],
            'satuan' => ['required', Rule::in(['pcs', 'ML', 'gram', 'kg'])],
            'harga' => ['required', 'numeric', 'min:0'],
            'quantity' => ['required', 'numeric', 'min:0.01'],
            'stock' => ['required', 'numeric', 'min:0'],
            'waste_materials' => ['nullable', 'numeric', 'min:0'],
        ]);
    }

    private function buildPayload(array $validated): array
    {
        $normalizedQuantity = RawMaterialUsage::normalizeStoredQuantity((float) $validated['quantity'], (string) $validated['satuan']);
        $hargaSatuan = $normalizedQuantity > 0 ? (float) $validated['harga'] / $normalizedQuantity : 0;
        $totalQuantity = round((float) $validated['stock'] * $normalizedQuantity, 2);
        $hargaTotal = round((float) $validated['stock'] * (float) $validated['harga'], 2);
        $wasteMaterials = RawMaterialUsage::normalizeStoredQuantity((float) ($validated['waste_materials'] ?? 0), (string) $validated['satuan']);
        $wastePercentage = $totalQuantity > 0 ? round(($wasteMaterials / $totalQuantity) * 100, 2) : 0;
        $wasteLossAmount = round($wasteMaterials * $hargaSatuan, 2);
        $wasteLossPercentage = $hargaTotal > 0 ? round(($wasteLossAmount / $hargaTotal) * 100, 2) : 0;

        return [
            'nama_rm' => $validated['nama_rm'],
            'satuan' => $validated['satuan'],
            'harga' => $validated['harga'],
            'quantity' => $normalizedQuantity,
            'harga_satuan' => $hargaSatuan,
            'stock' => round((float) $validated['stock'], 2),
            'total_quantity' => $totalQuantity,
            'waste_materials' => $wasteMaterials,
            'waste_percentage' => $wastePercentage,
            'waste_loss_percentage' => $wasteLossPercentage,
            'waste_loss_amount' => $wasteLossAmount,
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
