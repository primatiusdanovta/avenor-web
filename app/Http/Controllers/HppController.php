<?php

namespace App\Http\Controllers;

use App\Models\HppCalculation;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\RawMaterial;
use App\Support\RawMaterialUsage;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class HppController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorizePermission($request, 'hpp.view');
        $storeId = $this->currentStoreId($request);

        $products = Product::query()
            ->where('store_id', $storeId)
            ->orderBy('nama_product')
            ->with('variants')
            ->get(['id_product', 'nama_product', 'harga_modal'])
            ->map(fn (Product $product) => [
                'id_product' => $product->id_product,
                'nama_product' => $product->nama_product,
                'harga_modal' => (float) $product->harga_modal,
                'option_label' => $product->nama_product,
                'variants' => $product->variants->map(fn (ProductVariant $variant) => [
                    'id' => $variant->id,
                    'name' => $variant->name,
                    'price' => (float) $variant->price,
                    'total_satuan_ml' => (float) $variant->total_satuan_ml,
                    'is_default' => (bool) $variant->is_default,
                ])->values(),
            ])
            ->values();

        $rawMaterials = RawMaterial::query()
            ->where('store_id', $storeId)
            ->orderBy('nama_rm')
            ->get(['id_rm', 'nama_rm', 'satuan', 'harga_satuan', 'total_quantity'])
            ->map(fn (RawMaterial $material) => [
                'id_rm' => $material->id_rm,
                'nama_rm' => $material->nama_rm,
                'satuan' => $material->satuan,
                'harga_satuan' => (float) $material->harga_satuan,
                'total_quantity' => (float) $material->total_quantity,
                'display_total_quantity' => RawMaterialUsage::displayQuantity((float) $material->total_quantity, $material->satuan),
                'stock_display_unit' => RawMaterialUsage::stockDisplayUnit($material->satuan),
                'usage_input_unit' => RawMaterialUsage::usageInputUnit($material->satuan),
                'option_label' => $material->nama_rm . ' | ' . $material->satuan,
            ])
            ->values();

        $calculations = HppCalculation::query()
            ->where('store_id', $storeId)
            ->with(['product', 'items'])
            ->orderByDesc('updated_at')
            ->get()
            ->map(fn (HppCalculation $calculation) => [
                'id_hpp' => $calculation->id_hpp,
                'id_product' => $calculation->id_product,
                'nama_product' => $calculation->product?->nama_product,
                'total_hpp' => (float) $calculation->total_hpp,
                'updated_at' => optional($calculation->updated_at)->format('Y-m-d H:i:s'),
                'variants' => $calculation->product?->variants->map(fn (ProductVariant $variant) => [
                    'id' => $variant->id,
                    'name' => $variant->name,
                    'price' => (float) $variant->price,
                    'total_satuan_ml' => (float) $variant->total_satuan_ml,
                    'is_default' => (bool) $variant->is_default,
                ])->values() ?? [],
                'items' => $calculation->items->map(fn ($item) => [
                    'id_rm' => $item->id_rm,
                    'nama_rm' => $item->nama_rm,
                    'satuan' => $item->satuan,
                    'presentase' => (float) $item->presentase,
                    'usage_quantity' => RawMaterialUsage::calculateUsageQuantity((float) $item->presentase, $item->satuan, $this->defaultMlBaseForProduct($calculation->product)),
                    'usage_display_unit' => RawMaterialUsage::usageInputUnit($item->satuan),
                    'harga_satuan' => (float) $item->harga_satuan,
                    'harga_final' => (float) $item->harga_final,
                    'total_stock' => (float) $item->total_stock,
                    'total_stock_display' => RawMaterialUsage::displayQuantity((float) $item->total_stock, $item->satuan),
                    'total_stock_unit' => RawMaterialUsage::stockDisplayUnit($item->satuan),
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
        $this->authorizePermission($request, 'hpp.manage');
        $storeId = $this->currentStoreId($request);

        $validated = $this->validatePayload($request);

        DB::transaction(function () use ($validated, $storeId): void {
            $product = Product::query()->lockForUpdate()->findOrFail($validated['id_product']);
            abort_unless((int) $product->store_id === $storeId, 404);
            $calculation = HppCalculation::query()->firstOrNew([
                'store_id' => $storeId,
                'id_product' => $product->id_product,
            ]);
            $calculation->total_hpp = $this->calculateTotal($validated['id_product'], $validated['items']);
            $calculation->store_id = $storeId;
            if (! $calculation->exists) {
                $calculation->created_at = now();
            }
            $calculation->updated_at = now();
            $calculation->save();

            $calculation->items()->delete();
            foreach ($validated['items'] as $item) {
                $rawMaterial = RawMaterial::query()->findOrFail($item['id_rm']);
                abort_unless((int) $rawMaterial->store_id === $storeId, 404);
                $inputValue = (float) $item['presentase'];
                $hargaSatuan = (float) $rawMaterial->harga_satuan;
                $hargaFinal = RawMaterialUsage::calculateItemCost(
                    $inputValue,
                    $hargaSatuan,
                    (string) $rawMaterial->satuan,
                    $this->defaultMlBaseForProduct($product)
                );

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
        $this->authorizePermission($request, 'hpp.manage');
        $this->ensureStoreMatch($request, $hppCalculation);

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
        $storeId = $this->currentStoreId($request);

        return $request->validate([
            'id_product' => ['required', Rule::exists('products', 'id_product')->where(fn ($query) => $query->where('store_id', $storeId))],
            'items' => ['required', 'array', 'min:1'],
            'items.*.id_rm' => ['required', 'distinct', Rule::exists('raw_materials', 'id_rm')->where(fn ($query) => $query->where('store_id', $storeId))],
            'items.*.presentase' => ['required', 'numeric', 'min:0.01'],
        ], [
            'items.*.id_rm.distinct' => 'Raw material tidak boleh dipilih lebih dari sekali.',
        ]);
    }

    private function calculateTotal(int $productId, array $items): float
    {
        $product = Product::query()->with('variants')->find($productId);
        $rawMaterials = RawMaterial::query()
            ->whereIn('id_rm', collect($items)->pluck('id_rm')->all())
            ->get()
            ->keyBy('id_rm');

        return collect($items)->sum(function (array $item) use ($rawMaterials, $product) {
            $rawMaterial = $rawMaterials->get($item['id_rm']);
            $hargaSatuan = (float) ($rawMaterial?->harga_satuan ?? 0);
            $mlBase = $this->defaultMlBaseForProduct($product);

            return RawMaterialUsage::calculateItemCost(
                (float) $item['presentase'],
                $hargaSatuan,
                (string) ($rawMaterial?->satuan ?? ''),
                $mlBase
            );
        });
    }

    private function defaultMlBaseForProduct(?Product $product): ?float
    {
        if (! $product) {
            return null;
        }

        $product->loadMissing('variants');
        $defaultVariant = $product->variants->firstWhere('is_default', true) ?? $product->variants->first();

        return $defaultVariant ? (float) $defaultVariant->total_satuan_ml : null;
    }
}
