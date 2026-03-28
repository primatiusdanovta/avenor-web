<?php

namespace App\Http\Controllers;

use App\Models\HppCalculation;
use App\Models\Product;
use App\Models\RawMaterial;
use App\Support\RawMaterialUsage;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;
use Inertia\Response;

class HppController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $products = Product::query()
            ->orderBy('nama_product')
            ->get(['id_product', 'nama_product', 'harga_modal'])
            ->map(fn (Product $product) => [
                'id_product' => $product->id_product,
                'nama_product' => $product->nama_product,
                'harga_modal' => (float) $product->harga_modal,
                'option_label' => $product->nama_product,
            ])
            ->values();

        $rawMaterials = RawMaterial::query()
            ->orderBy('nama_rm')
            ->get(['id_rm', 'nama_rm', 'satuan', 'harga_satuan', 'total_quantity'])
            ->map(fn (RawMaterial $material) => [
                'id_rm' => $material->id_rm,
                'nama_rm' => $material->nama_rm,
                'satuan' => $material->satuan,
                'harga_satuan' => (float) $material->harga_satuan,
                'total_quantity' => (float) $material->total_quantity,
                'option_label' => $material->nama_rm . ' | ' . $material->satuan,
            ])
            ->values();

        $calculations = HppCalculation::query()
            ->with(['product', 'items'])
            ->orderByDesc('updated_at')
            ->get()
            ->map(fn (HppCalculation $calculation) => [
                'id_hpp' => $calculation->id_hpp,
                'id_product' => $calculation->id_product,
                'nama_product' => $calculation->product?->nama_product,
                'total_hpp' => (float) $calculation->total_hpp,
                'updated_at' => optional($calculation->updated_at)->format('Y-m-d H:i:s'),
                'items' => $calculation->items->map(fn ($item) => [
                    'id_rm' => $item->id_rm,
                    'nama_rm' => $item->nama_rm,
                    'satuan' => $item->satuan,
                    'presentase' => (float) $item->presentase,
                    'usage_quantity' => RawMaterialUsage::calculateUsageQuantity((float) $item->presentase, $item->satuan),
                    'harga_satuan' => (float) $item->harga_satuan,
                    'harga_final' => (float) $item->harga_final,
                    'total_stock' => (float) $item->total_stock,
                ])->values(),
            ])
            ->values();

        return Inertia::render('Hpp/Index', [
            'products' => $products,
            'rawMaterials' => $rawMaterials,
            'calculations' => $calculations,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $validated = $this->validatePayload($request);

        DB::transaction(function () use ($validated): void {
            $product = Product::query()->lockForUpdate()->findOrFail($validated['id_product']);
            $calculation = HppCalculation::query()->firstOrNew(['id_product' => $product->id_product]);
            $calculation->total_hpp = $this->calculateTotal($validated['items']);
            if (! $calculation->exists) {
                $calculation->created_at = now();
            }
            $calculation->updated_at = now();
            $calculation->save();

            $calculation->items()->delete();
            foreach ($validated['items'] as $item) {
                $rawMaterial = RawMaterial::query()->findOrFail($item['id_rm']);
                $inputValue = (float) $item['presentase'];
                $hargaSatuan = (float) $rawMaterial->harga_satuan;
                $hargaFinal = RawMaterialUsage::calculateItemCost($inputValue, $hargaSatuan, (string) $rawMaterial->satuan);

                $calculation->items()->create([
                    'id_rm' => $rawMaterial->id_rm,
                    'nama_rm' => $rawMaterial->nama_rm,
                    'satuan' => $rawMaterial->satuan,
                    'presentase' => $inputValue,
                    'harga_satuan' => $hargaSatuan,
                    'harga_final' => $hargaFinal,
                    'total_stock' => (float) $rawMaterial->total_quantity,
                    'created_at' => now(),
                ]);
            }

            $product->update(['harga_modal' => $calculation->total_hpp]);
        });

        return redirect()->route('hpp.index')->with('success', 'Perhitungan HPP berhasil disimpan.');
    }

    public function destroy(Request $request, HppCalculation $hppCalculation): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        DB::transaction(function () use ($hppCalculation): void {
            $product = Product::query()->find($hppCalculation->id_product);
            $hppCalculation->delete();

            if ($product) {
                $product->update(['harga_modal' => 0]);
            }
        });

        return redirect()->route('hpp.index')->with('success', 'Perhitungan HPP berhasil dihapus.');
    }

    private function validatePayload(Request $request): array
    {
        return $request->validate([
            'id_product' => ['required', 'exists:products,id_product'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.id_rm' => ['required', 'distinct', 'exists:raw_materials,id_rm'],
            'items.*.presentase' => ['required', 'numeric', 'min:0.01'],
        ], [
            'items.*.id_rm.distinct' => 'Raw material tidak boleh dipilih lebih dari sekali.',
        ]);
    }

    private function calculateTotal(array $items): float
    {
        $rawMaterials = RawMaterial::query()
            ->whereIn('id_rm', collect($items)->pluck('id_rm')->all())
            ->get()
            ->keyBy('id_rm');

        return collect($items)->sum(function (array $item) use ($rawMaterials) {
            $rawMaterial = $rawMaterials->get($item['id_rm']);
            $hargaSatuan = (float) ($rawMaterial?->harga_satuan ?? 0);

            return RawMaterialUsage::calculateItemCost(
                (float) $item['presentase'],
                $hargaSatuan,
                (string) ($rawMaterial?->satuan ?? '')
            );
        });
    }
}
