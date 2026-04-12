<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\AccountPayable;
use App\Models\AccountReceivable;
use App\Models\Customer;
use App\Models\Expense;
use App\Models\ExtraTopping;
use App\Models\HppCalculation;
use App\Models\MarketingNotification;
use App\Models\OfflineSale;
use App\Models\OnlineSale;
use App\Models\PermissionRole;
use App\Models\Product;
use App\Models\Promo;
use App\Models\RawMaterial;
use App\Models\SalesTarget;
use App\Models\Sop;
use App\Models\User;
use App\Support\RawMaterialUsage;
use App\Support\SalesRole;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class OwnerModuleController extends Controller
{
    public function index(Request $request, string $module): JsonResponse
    {
        $storeId = $this->authorizeOwner($request);

        return response()->json(match ($module) {
            'products' => $this->productsPayload($storeId),
            'product-knowledge' => $this->productKnowledgePayload($storeId),
            'raw-materials' => $this->rawMaterialsPayload($storeId),
            'extra-toppings' => $this->extraToppingsPayload($storeId),
            'expenses' => $this->expensesPayload($storeId),
            'account-receivables' => $this->accountReceivablesPayload($storeId),
            'account-payables' => $this->accountPayablesPayload($storeId),
            'online-sales' => $this->onlineSalesPayload($storeId),
            'promos' => $this->promosPayload(),
            'customers' => $this->customersPayload($storeId),
            'sops' => $this->sopsPayload($storeId),
            'users' => $this->usersPayload($storeId),
            'sales-targets' => $this->salesTargetsPayload(),
            'hpp' => $this->hppPayload($storeId),
            'notifications' => $this->notificationsPayload($storeId),
            default => abort(404),
        });
    }

    public function store(Request $request, string $module): JsonResponse
    {
        $storeId = $this->authorizeOwner($request);

        $message = match ($module) {
            'products' => $this->storeProduct($request, $storeId),
            'product-knowledge' => $this->storeProductKnowledge($request, $storeId),
            'raw-materials' => $this->storeRawMaterial($request, $storeId),
            'extra-toppings' => $this->storeExtraTopping($request, $storeId),
            'expenses' => $this->storeExpense($request, $storeId),
            'account-payables' => $this->storeAccountPayable($request, $storeId),
            'promos' => $this->storePromo($request),
            'customers' => $this->storeCustomer($request, $storeId),
            'sops' => $this->storeSop($request, $storeId),
            'users' => $this->storeUser($request, $storeId),
            'hpp' => $this->storeHpp($request, $storeId),
            default => abort(404),
        };

        return response()->json(['message' => $message], 201);
    }

    public function update(Request $request, string $module, string $record): JsonResponse
    {
        $storeId = $this->authorizeOwner($request);

        $message = match ($module) {
            'products' => $this->updateProduct($request, $storeId, (int) $record),
            'product-knowledge' => $this->updateProductKnowledge($request, $storeId, (int) $record),
            'raw-materials' => $this->updateRawMaterial($request, $storeId, (int) $record),
            'extra-toppings' => $this->updateExtraTopping($request, $storeId, (int) $record),
            'expenses' => $this->updateExpense($request, $storeId, (int) $record),
            'account-payables' => $this->updateAccountPayable($request, $storeId, (int) $record),
            'promos' => $this->updatePromo($request, (int) $record),
            'customers' => $this->updateCustomer($request, $storeId, (int) $record),
            'sops' => $this->updateSop($request, $storeId, (int) $record),
            'users' => $this->updateUser($request, $storeId, (int) $record),
            'sales-targets' => $this->updateSalesTarget($request, $record),
            'hpp' => $this->storeHpp($request, $storeId),
            default => abort(404),
        };

        return response()->json(['message' => $message]);
    }

    public function destroy(Request $request, string $module, string $record): JsonResponse
    {
        $storeId = $this->authorizeOwner($request);

        $message = match ($module) {
            'products' => $this->destroyProduct($storeId, (int) $record),
            'raw-materials' => $this->destroyRawMaterial($storeId, (int) $record),
            'extra-toppings' => $this->destroyExtraTopping($storeId, (int) $record),
            'expenses' => $this->destroyExpense($storeId, (int) $record),
            'account-payables' => $this->destroyAccountPayable($storeId, (int) $record),
            'promos' => $this->destroyPromo((int) $record),
            'customers' => $this->destroyCustomer($storeId, (int) $record),
            'sops' => $this->destroySop($storeId, (int) $record),
            'users' => $this->destroyUser($request, $storeId, (int) $record),
            'hpp' => $this->destroyHpp($storeId, (int) $record),
            default => abort(404),
        };

        return response()->json(['message' => $message]);
    }

    private function authorizeOwner(Request $request): int
    {
        abort_unless($request->user()?->role === SalesRole::OWNER, 403);
        abort_unless($this->isSmoothiesSweetieStore($request), 403);

        return $this->currentStoreId($request);
    }

    private function baseModulePayload(string $title, string $description, array $items, bool $readOnly = false): array
    {
        return [
            'title' => $title,
            'description' => $description,
            'items' => array_values($items),
            'read_only' => $readOnly,
        ];
    }

    private function productsPayload(int $storeId): array
    {
        return $this->baseModulePayload(
            'Product',
            'Kelola data product owner seperti di website melalui popup form mobile.',
            Product::query()
                ->where('store_id', $storeId)
                ->orderByDesc('created_at')
                ->orderByDesc('id_product')
                ->get()
                ->map(fn (Product $product) => [
                    'id' => $product->id_product,
                    'nama_product' => $product->nama_product,
                    'harga' => (float) $product->harga,
                    'harga_modal' => (float) $product->harga_modal,
                    'stock' => (int) $product->stock,
                    'deskripsi' => $product->deskripsi,
                    'created_at' => optional($product->created_at)->format('Y-m-d H:i:s'),
                ])
                ->all(),
        );
    }

    private function productKnowledgePayload(int $storeId): array
    {
        return $this->baseModulePayload(
            'Product Knowledge',
            'Owner mengelola panduan product dari data product yang sama dengan website.',
            Product::query()
                ->where('store_id', $storeId)
                ->orderBy('nama_product')
                ->get()
                ->map(fn (Product $product) => [
                    'id' => $product->id_product,
                    'nama_product' => $product->nama_product,
                    'deskripsi' => $product->deskripsi,
                    'harga' => (float) $product->harga,
                    'stock' => (int) $product->stock,
                ])
                ->all(),
        );
    }

    private function rawMaterialsPayload(int $storeId): array
    {
        return $this->baseModulePayload(
            'Raw Material',
            'Kelola bahan baku, stock, dan nilai waste seperti website.',
            RawMaterial::query()
                ->where('store_id', $storeId)
                ->orderByDesc('created_at')
                ->get()
                ->map(fn (RawMaterial $material) => [
                    'id' => $material->id_rm,
                    'nama_rm' => $material->nama_rm,
                    'satuan' => $material->satuan,
                    'harga' => (float) $material->harga,
                    'quantity' => RawMaterialUsage::displayQuantity((float) $material->quantity, $material->satuan),
                    'stock' => (float) $material->stock,
                    'total_quantity' => RawMaterialUsage::displayQuantity((float) $material->total_quantity, $material->satuan),
                    'waste_materials' => RawMaterialUsage::displayQuantity((float) $material->waste_materials, $material->satuan),
                    'harga_total' => (float) $material->harga_total,
                ])
                ->all(),
        );
    }

    private function extraToppingsPayload(int $storeId): array
    {
        return $this->baseModulePayload(
            'Extra Topping',
            'Kelola extra topping aktif untuk transaksi kasir.',
            ExtraTopping::query()
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
                ->all(),
        );
    }

    private function expensesPayload(int $storeId): array
    {
        return [
            ...$this->baseModulePayload(
                'Pengeluaran',
                'Kelola pengeluaran bahan baku dan operasional.',
                Expense::query()
                    ->where('store_id', $storeId)
                    ->with('creator')
                    ->orderByDesc('expense_date')
                    ->orderByDesc('id')
                    ->get()
                    ->map(fn (Expense $expense) => [
                        'id' => $expense->id,
                        'category' => $expense->category,
                        'title' => $expense->title,
                        'amount' => (float) $expense->amount,
                        'notes' => $expense->notes,
                        'expense_date' => optional($expense->expense_date)->format('Y-m-d'),
                        'created_by_name' => $expense->creator?->nama ?? '-',
                    ])
                    ->all(),
            ),
            'summary' => [
                'bahan_baku' => round((float) Expense::query()->where('store_id', $storeId)->where('category', 'bahan_baku')->sum('amount'), 2),
                'operasional' => round((float) Expense::query()->where('store_id', $storeId)->where('category', 'operasional')->sum('amount'), 2),
                'total' => round((float) Expense::query()->where('store_id', $storeId)->sum('amount'), 2),
            ],
        ];
    }

    private function accountReceivablesPayload(int $storeId): array
    {
        return $this->baseModulePayload(
            'Account Receivables',
            'Read only mengikuti website.',
            AccountReceivable::query()
                ->where('store_id', $storeId)
                ->latest('due_date')
                ->latest('id')
                ->get()
                ->map(fn (AccountReceivable $receivable) => [
                    'id' => $receivable->id,
                    'receivable_name' => $receivable->receivable_name,
                    'place_name' => $receivable->place_name,
                    'consignment_date' => optional($receivable->consignment_date)->format('Y-m-d'),
                    'due_date' => optional($receivable->due_date)->format('Y-m-d'),
                    'consigned_value' => (float) ($receivable->consigned_value ?? 0),
                    'total_value' => (float) $receivable->total_value,
                    'status' => $receivable->status,
                    'items_summary' => $receivable->items_summary,
                    'notes' => $receivable->notes,
                ])
                ->all(),
            true,
        );
    }

    private function accountPayablesPayload(int $storeId): array
    {
        return $this->baseModulePayload(
            'Account Payables',
            'Kelola hutang usaha seperti website.',
            AccountPayable::query()
                ->where('store_id', $storeId)
                ->latest('due_date')
                ->latest('id')
                ->get()
                ->map(fn (AccountPayable $payable) => [
                    'id' => $payable->id,
                    'account_payable' => $payable->account_payable,
                    'due_date' => optional($payable->due_date)->format('Y-m-d'),
                    'notes' => $payable->notes,
                ])
                ->all(),
        );
    }

    private function onlineSalesPayload(int $storeId): array
    {
        return $this->baseModulePayload(
            'Penjualan Online',
            'Read only mengikuti website.',
            OnlineSale::query()
                ->where('store_id', $storeId)
                ->with('items')
                ->orderByDesc('paid_time')
                ->orderByDesc('id')
                ->get()
                ->map(fn (OnlineSale $sale) => [
                    'id' => $sale->id,
                    'order_id' => $sale->order_id,
                    'order_status' => $sale->order_status,
                    'order_substatus' => $sale->order_substatus,
                    'province' => $sale->province,
                    'regency_city' => $sale->regency_city,
                    'paid_time' => optional($sale->paid_time)->format('Y-m-d H:i:s'),
                    'total_amount' => (float) $sale->total_amount,
                    'items' => $sale->items->map(fn ($item) => [
                        'raw_product_name' => $item->raw_product_name,
                        'nama_product' => $item->nama_product,
                        'quantity' => (int) $item->quantity,
                    ])->values()->all(),
                ])
                ->all(),
            true,
        );
    }

    private function promosPayload(): array
    {
        return $this->baseModulePayload(
            'Promo',
            'Kelola promo aktif kasir dan penjualan online.',
            Promo::query()
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
                ])
                ->all(),
        );
    }

    private function customersPayload(int $storeId): array
    {
        $latestPurchaseItems = OfflineSale::query()
            ->where('store_id', $storeId)
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

        return $this->baseModulePayload(
            'Customers',
            'Kelola data customer store Smoothies Sweetie.',
            Customer::query()
                ->where('store_id', $storeId)
                ->orderByDesc('pembelian_terakhir')
                ->orderByDesc('id_pelanggan')
                ->get()
                ->map(fn (Customer $customer) => [
                    'id' => $customer->id_pelanggan,
                    'nama' => $customer->nama,
                    'no_telp' => $customer->no_telp,
                    'tiktok_instagram' => $customer->tiktok_instagram,
                    'pembelian_terakhir' => optional($customer->pembelian_terakhir)->format('Y-m-d H:i:s'),
                    'latest_purchase_items' => $latestPurchaseItems->get($customer->id_pelanggan, '-'),
                ])
                ->all(),
        );
    }

    private function sopsPayload(int $storeId): array
    {
        return $this->baseModulePayload(
            'SOP',
            'Kelola SOP umum dan SOP store seperti website.',
            Sop::query()
                ->where(function ($query) use ($storeId) {
                    $query->whereNull('store_id')
                        ->orWhere('store_id', $storeId);
                })
                ->orderBy('title')
                ->get()
                ->map(fn (Sop $item) => [
                    'id' => $item->id_sop,
                    'title' => $item->title,
                    'detail' => $item->detail,
                    'store_id' => $item->store_id,
                ])
                ->all(),
        );
    }

    private function usersPayload(int $storeId): array
    {
        $users = User::query()
            ->with(['permissionRole:id,name,legacy_role', 'stores:id,display_name'])
            ->whereHas('stores', fn ($query) => $query->where('stores.id', $storeId))
            ->orderBy('id_user')
            ->get(['id_user', 'nama', 'status', 'role', 'permission_role_id', 'created_at'])
            ->map(fn (User $user) => [
                'id' => $user->id_user,
                'nama' => $user->nama,
                'status' => $user->status,
                'role' => $user->role,
                'permission_role_id' => $user->permission_role_id,
                'role_label' => $user->permissionRole?->name ?? $user->role,
                'created_at' => optional($user->created_at)->format('Y-m-d H:i:s'),
            ])
            ->values()
            ->all();

        $roles = PermissionRole::query()
            ->whereIn('legacy_role', [SalesRole::OWNER, SalesRole::KARYAWAN])
            ->orderBy('name')
            ->get(['id', 'name', 'legacy_role'])
            ->map(fn (PermissionRole $role) => [
                'value' => $role->id,
                'label' => $role->name . ' | ' . ucfirst($role->legacy_role),
                'legacy_role' => $role->legacy_role,
            ])
            ->values()
            ->all();

        return [
            ...$this->baseModulePayload(
                'Users',
                'Kelola user owner dan karyawan yang terhubung ke store aktif.',
                $users,
            ),
            'role_options' => $roles,
            'status_options' => ['aktif', 'nonaktif'],
        ];
    }

    private function salesTargetsPayload(): array
    {
        return [
            'title' => 'Target Penjualan',
            'description' => 'Owner mengubah target quantity karyawan dan target revenue store.',
            'items' => collect(['karyawan', 'revenue_target'])
                ->map(function (string $role) {
                    $target = SalesTarget::query()->firstWhere('role', $role);

                    if ($role === 'revenue_target') {
                        return [
                            'id' => $role,
                            'role' => $role,
                            'label' => 'Target Revenue Karyawan',
                            'type' => 'revenue',
                            'monthly_target_revenue' => (float) ($target?->monthly_target_revenue ?? 0),
                            'minimum_kpi_value' => (float) ($target?->minimum_kpi_value ?? 0),
                            'maximum_late_days' => (int) ($target?->maximum_late_days ?? 0),
                            'minimum_attendance_percentage' => (float) ($target?->minimum_attendance_percentage ?? 0),
                            'revenue_bonus' => (float) ($target?->revenue_bonus ?? 0),
                        ];
                    }

                    return [
                        'id' => $role,
                        'role' => $role,
                        'label' => 'Target Quantity Karyawan',
                        'type' => 'quantity',
                        'daily_target_qty' => (int) ($target?->daily_target_qty ?? 0),
                        'daily_bonus' => (float) ($target?->daily_bonus ?? 0),
                        'weekly_target_qty' => (int) ($target?->weekly_target_qty ?? 0),
                        'weekly_bonus' => (float) ($target?->weekly_bonus ?? 0),
                        'monthly_target_qty' => (int) ($target?->monthly_target_qty ?? 0),
                        'monthly_bonus' => (float) ($target?->monthly_bonus ?? 0),
                    ];
                })
                ->values()
                ->all(),
        ];
    }

    private function hppPayload(int $storeId): array
    {
        return [
            'title' => 'HPP',
            'description' => 'Kelola perhitungan HPP product dengan raw material store aktif.',
            'products' => Product::query()
                ->where('store_id', $storeId)
                ->orderBy('nama_product')
                ->get(['id_product', 'nama_product', 'harga_modal'])
                ->map(fn (Product $product) => [
                    'id_product' => $product->id_product,
                    'nama_product' => $product->nama_product,
                    'harga_modal' => (float) $product->harga_modal,
                ])
                ->values()
                ->all(),
            'raw_materials' => RawMaterial::query()
                ->where('store_id', $storeId)
                ->orderBy('nama_rm')
                ->get(['id_rm', 'nama_rm', 'satuan', 'harga_satuan', 'total_quantity'])
                ->map(fn (RawMaterial $material) => [
                    'id_rm' => $material->id_rm,
                    'nama_rm' => $material->nama_rm,
                    'satuan' => $material->satuan,
                    'harga_satuan' => (float) $material->harga_satuan,
                    'total_quantity' => (float) $material->total_quantity,
                ])
                ->values()
                ->all(),
            'items' => HppCalculation::query()
                ->where('store_id', $storeId)
                ->with(['product', 'items'])
                ->orderByDesc('updated_at')
                ->get()
                ->map(fn (HppCalculation $calculation) => [
                    'id' => $calculation->id_hpp,
                    'id_product' => $calculation->id_product,
                    'nama_product' => $calculation->product?->nama_product,
                    'total_hpp' => (float) $calculation->total_hpp,
                    'updated_at' => optional($calculation->updated_at)->format('Y-m-d H:i:s'),
                    'details' => $calculation->items->map(fn ($item) => [
                        'id_rm' => $item->id_rm,
                        'nama_rm' => $item->nama_rm,
                        'presentase' => (float) $item->presentase,
                        'harga_final' => (float) $item->harga_final,
                    ])->values()->all(),
                ])
                ->values()
                ->all(),
        ];
    }

    private function notificationsPayload(int $storeId): array
    {
        return $this->baseModulePayload(
            'Notifications',
            'Riwayat notifikasi store untuk owner.',
            MarketingNotification::query()
                ->where('store_id', $storeId)
                ->latest('published_at')
                ->latest('created_at')
                ->get()
                ->map(fn (MarketingNotification $item) => [
                    'id' => $item->id,
                    'title' => $item->title,
                    'body' => $item->body,
                    'status' => $item->status,
                    'target_role' => $item->target_role,
                    'published_at' => optional($item->published_at)->format('Y-m-d H:i:s'),
                ])
                ->all(),
            true,
        );
    }

    private function storeProduct(Request $request, int $storeId): string
    {
        $validated = $request->validate([
            'nama_product' => ['required', 'string', 'max:255', Rule::unique('products', 'nama_product')->where(fn ($query) => $query->where('store_id', $storeId))],
            'harga' => ['required', 'numeric', 'min:0'],
            'stock' => ['nullable', 'integer', 'min:0'],
            'deskripsi' => ['nullable', 'string'],
        ]);

        Product::query()->create([
            'store_id' => $storeId,
            'nama_product' => $validated['nama_product'],
            'harga' => $validated['harga'],
            'harga_modal' => 0,
            'stock' => (int) ($validated['stock'] ?? 0),
            'deskripsi' => $validated['deskripsi'] ?? null,
            'created_at' => now(),
        ]);

        return 'Product berhasil ditambahkan.';
    }

    private function updateProduct(Request $request, int $storeId, int $id): string
    {
        $product = Product::query()->findOrFail($id);
        abort_unless((int) $product->store_id === $storeId, 404);

        $validated = $request->validate([
            'nama_product' => ['required', 'string', 'max:255', Rule::unique('products', 'nama_product')->where(fn ($query) => $query->where('store_id', $storeId))->ignore($product->id_product, 'id_product')],
            'harga' => ['required', 'numeric', 'min:0'],
            'stock' => ['required', 'integer', 'min:0'],
            'deskripsi' => ['nullable', 'string'],
        ]);

        $product->update([
            'nama_product' => $validated['nama_product'],
            'harga' => $validated['harga'],
            'stock' => $validated['stock'],
            'deskripsi' => $validated['deskripsi'] ?? null,
        ]);

        return 'Product berhasil diperbarui.';
    }

    private function destroyProduct(int $storeId, int $id): string
    {
        $product = Product::query()->findOrFail($id);
        abort_unless((int) $product->store_id === $storeId, 404);
        $product->delete();

        return 'Product berhasil dihapus.';
    }

    private function storeProductKnowledge(Request $request, int $storeId): string
    {
        return $this->storeProduct($request, $storeId);
    }

    private function updateProductKnowledge(Request $request, int $storeId, int $id): string
    {
        $product = Product::query()->findOrFail($id);
        abort_unless((int) $product->store_id === $storeId, 404);

        $validated = $request->validate([
            'nama_product' => ['required', 'string', 'max:255', Rule::unique('products', 'nama_product')->where(fn ($query) => $query->where('store_id', $storeId))->ignore($product->id_product, 'id_product')],
            'harga' => ['nullable', 'numeric', 'min:0'],
            'stock' => ['nullable', 'integer', 'min:0'],
            'deskripsi' => ['nullable', 'string'],
        ]);

        $product->update([
            'nama_product' => $validated['nama_product'],
            'harga' => $validated['harga'] ?? $product->harga,
            'stock' => $validated['stock'] ?? $product->stock,
            'deskripsi' => $validated['deskripsi'] ?? null,
        ]);

        return 'Product knowledge berhasil diperbarui.';
    }

    private function rawMaterialValidated(Request $request, int $storeId, ?int $ignoreId = null): array
    {
        return $request->validate([
            'nama_rm' => [
                'required',
                'string',
                'max:255',
                Rule::unique('raw_materials', 'nama_rm')
                    ->where(fn ($query) => $query->where('store_id', $storeId))
                    ->ignore($ignoreId, 'id_rm'),
            ],
            'satuan' => ['required', Rule::in(['pcs', 'ML', 'gram', 'kg'])],
            'harga' => ['required', 'numeric', 'min:0'],
            'quantity' => ['required', 'numeric', 'min:0.01'],
            'stock' => ['required', 'numeric', 'min:0'],
            'waste_materials' => ['nullable', 'numeric', 'min:0'],
        ]);
    }

    private function rawMaterialPayload(array $validated): array
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

    private function storeRawMaterial(Request $request, int $storeId): string
    {
        $validated = $this->rawMaterialValidated($request, $storeId);

        RawMaterial::query()->create($this->rawMaterialPayload($validated) + [
            'store_id' => $storeId,
            'created_at' => now(),
        ]);

        return 'Raw material berhasil ditambahkan.';
    }

    private function updateRawMaterial(Request $request, int $storeId, int $id): string
    {
        $material = RawMaterial::query()->findOrFail($id);
        abort_unless((int) $material->store_id === $storeId, 404);
        $validated = $this->rawMaterialValidated($request, $storeId, $material->id_rm);
        $material->update($this->rawMaterialPayload($validated));

        return 'Raw material berhasil diperbarui.';
    }

    private function destroyRawMaterial(int $storeId, int $id): string
    {
        $material = RawMaterial::query()->findOrFail($id);
        abort_unless((int) $material->store_id === $storeId, 404);
        $material->delete();

        return 'Raw material berhasil dihapus.';
    }

    private function storeExtraTopping(Request $request, int $storeId): string
    {
        $validated = $request->validate([
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('extra_toppings', 'name')->where(fn ($query) => $query->where('store_id', $storeId)),
            ],
            'price' => ['required', 'numeric', 'min:0'],
            'is_active' => ['required', 'boolean'],
        ]);

        ExtraTopping::query()->create([
            'store_id' => $storeId,
            ...$validated,
        ]);

        return 'Extra topping berhasil ditambahkan.';
    }

    private function updateExtraTopping(Request $request, int $storeId, int $id): string
    {
        $item = ExtraTopping::query()->findOrFail($id);
        abort_unless((int) $item->store_id === $storeId, 404);

        $validated = $request->validate([
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('extra_toppings', 'name')->where(fn ($query) => $query->where('store_id', $storeId))->ignore($item->id),
            ],
            'price' => ['required', 'numeric', 'min:0'],
            'is_active' => ['required', 'boolean'],
        ]);

        $item->update($validated);

        return 'Extra topping berhasil diperbarui.';
    }

    private function destroyExtraTopping(int $storeId, int $id): string
    {
        $item = ExtraTopping::query()->findOrFail($id);
        abort_unless((int) $item->store_id === $storeId, 404);
        $item->delete();

        return 'Extra topping berhasil dihapus.';
    }

    private function storeExpense(Request $request, int $storeId): string
    {
        $validated = $request->validate([
            'category' => ['required', 'in:bahan_baku,operasional'],
            'title' => ['required', 'string', 'max:255'],
            'amount' => ['required', 'numeric', 'min:0'],
            'expense_date' => ['required', 'date'],
            'notes' => ['nullable', 'string'],
        ]);

        Expense::query()->create([
            'store_id' => $storeId,
            'category' => $validated['category'],
            'title' => $validated['title'],
            'amount' => $validated['amount'],
            'expense_date' => $validated['expense_date'],
            'notes' => $validated['notes'] ?? null,
            'created_by' => $request->user()->id_user,
        ]);

        return 'Pengeluaran berhasil ditambahkan.';
    }

    private function updateExpense(Request $request, int $storeId, int $id): string
    {
        $expense = Expense::query()->findOrFail($id);
        abort_unless((int) $expense->store_id === $storeId, 404);
        $validated = $request->validate([
            'category' => ['required', 'in:bahan_baku,operasional'],
            'title' => ['required', 'string', 'max:255'],
            'amount' => ['required', 'numeric', 'min:0'],
            'expense_date' => ['required', 'date'],
            'notes' => ['nullable', 'string'],
        ]);

        $expense->update($validated);

        return 'Pengeluaran berhasil diperbarui.';
    }

    private function destroyExpense(int $storeId, int $id): string
    {
        $expense = Expense::query()->findOrFail($id);
        abort_unless((int) $expense->store_id === $storeId, 404);
        $expense->delete();

        return 'Pengeluaran berhasil dihapus.';
    }

    private function storeAccountPayable(Request $request, int $storeId): string
    {
        $validated = $request->validate([
            'account_payable' => ['required', 'string', 'max:255'],
            'due_date' => ['required', 'date'],
            'notes' => ['nullable', 'string'],
        ]);

        AccountPayable::query()->create([
            'store_id' => $storeId,
            ...$validated,
        ]);

        return 'Account payable berhasil ditambahkan.';
    }

    private function updateAccountPayable(Request $request, int $storeId, int $id): string
    {
        $payable = AccountPayable::query()->findOrFail($id);
        abort_unless((int) $payable->store_id === $storeId, 404);
        $validated = $request->validate([
            'account_payable' => ['required', 'string', 'max:255'],
            'due_date' => ['required', 'date'],
            'notes' => ['nullable', 'string'],
        ]);

        $payable->update($validated);

        return 'Account payable berhasil diperbarui.';
    }

    private function destroyAccountPayable(int $storeId, int $id): string
    {
        $payable = AccountPayable::query()->findOrFail($id);
        abort_unless((int) $payable->store_id === $storeId, 404);
        $payable->delete();

        return 'Account payable berhasil dihapus.';
    }

    private function storePromo(Request $request): string
    {
        $validated = $request->validate([
            'nama_promo' => ['required', 'string', 'max:255'],
            'potongan' => ['required', 'numeric', 'min:0'],
            'masa_aktif' => ['required', 'date', 'after_or_equal:today'],
            'minimal_quantity' => ['required', 'integer', 'min:1'],
            'minimal_belanja' => ['required', 'numeric', 'min:0'],
        ]);

        Promo::query()->create([
            'kode_promo' => Str::limit(
                Str::of($validated['nama_promo'])
                    ->upper()
                    ->replaceMatches('/[^A-Z0-9 ]/', '')
                    ->explode(' ')
                    ->filter()
                    ->map(fn (string $part) => Str::substr($part, 0, 1))
                    ->join('') ?: 'PR',
                5,
                '',
            ) . now()->format('Ymd'),
            ...$validated,
            'created_at' => now(),
        ]);

        return 'Promo berhasil ditambahkan.';
    }

    private function updatePromo(Request $request, int $id): string
    {
        $promo = Promo::query()->findOrFail($id);
        $validated = $request->validate([
            'nama_promo' => ['required', 'string', 'max:255'],
            'potongan' => ['required', 'numeric', 'min:0'],
            'masa_aktif' => ['required', 'date'],
            'minimal_quantity' => ['required', 'integer', 'min:1'],
            'minimal_belanja' => ['required', 'numeric', 'min:0'],
        ]);

        $promo->update($validated);

        return 'Promo berhasil diperbarui.';
    }

    private function destroyPromo(int $id): string
    {
        Promo::query()->findOrFail($id)->delete();

        return 'Promo berhasil dihapus.';
    }

    private function customerValidated(Request $request, int $storeId, ?int $ignoreId = null): array
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
                Rule::unique('customers', 'no_telp')
                    ->where(fn ($query) => $query->where('store_id', $storeId))
                    ->ignore($ignoreId, 'id_pelanggan'),
            ],
            'tiktok_instagram' => ['nullable', 'string', 'max:255'],
            'pembelian_terakhir' => ['nullable', 'date'],
        ]);
    }

    private function storeCustomer(Request $request, int $storeId): string
    {
        $validated = $this->customerValidated($request, $storeId);

        Customer::query()->create([
            'store_id' => $storeId,
            'nama' => $validated['nama'] ?: null,
            'no_telp' => $validated['no_telp'] ?: null,
            'tiktok_instagram' => $validated['tiktok_instagram'] ?: null,
            'created_at' => now(),
            'pembelian_terakhir' => $validated['pembelian_terakhir'] ?: null,
        ]);

        return 'Customer berhasil ditambahkan.';
    }

    private function updateCustomer(Request $request, int $storeId, int $id): string
    {
        $customer = Customer::query()->findOrFail($id);
        abort_unless((int) $customer->store_id === $storeId, 404);
        $validated = $this->customerValidated($request, $storeId, $customer->id_pelanggan);

        $customer->update([
            'nama' => $validated['nama'] ?: null,
            'no_telp' => $validated['no_telp'] ?: null,
            'tiktok_instagram' => $validated['tiktok_instagram'] ?: null,
            'pembelian_terakhir' => $validated['pembelian_terakhir'] ?: null,
        ]);

        return 'Customer berhasil diperbarui.';
    }

    private function destroyCustomer(int $storeId, int $id): string
    {
        $customer = Customer::query()->findOrFail($id);
        abort_unless((int) $customer->store_id === $storeId, 404);
        $customer->delete();

        return 'Customer berhasil dihapus.';
    }

    private function storeSop(Request $request, int $storeId): string
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'detail' => ['required', 'string'],
        ]);

        Sop::query()->create([
            'store_id' => $storeId,
            ...$validated,
        ]);

        return 'SOP berhasil ditambahkan.';
    }

    private function updateSop(Request $request, int $storeId, int $id): string
    {
        $sop = Sop::query()->findOrFail($id);
        if ($sop->store_id !== null) {
            abort_unless((int) $sop->store_id === $storeId, 404);
        }

        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'detail' => ['required', 'string'],
        ]);
        $sop->update($validated);

        return 'SOP berhasil diperbarui.';
    }

    private function destroySop(int $storeId, int $id): string
    {
        $sop = Sop::query()->findOrFail($id);
        if ($sop->store_id !== null) {
            abort_unless((int) $sop->store_id === $storeId, 404);
        }
        $sop->delete();

        return 'SOP berhasil dihapus.';
    }

    private function storeUser(Request $request, int $storeId): string
    {
        $validated = $request->validate([
            'nama' => ['required', 'string', 'max:255', 'unique:users,nama'],
            'permission_role_id' => ['required', 'integer', Rule::exists('permission_roles', 'id')->where(fn ($query) => $query->whereIn('legacy_role', [SalesRole::OWNER, SalesRole::KARYAWAN]))],
            'status' => ['required', Rule::in(['aktif', 'nonaktif'])],
            'password' => ['required', 'string', 'min:8'],
        ]);

        $role = PermissionRole::query()->findOrFail($validated['permission_role_id']);

        $user = User::query()->create([
            'nama' => $validated['nama'],
            'status' => $validated['status'],
            'role' => $role->legacy_role,
            'permission_role_id' => $role->id,
            'password' => $validated['password'],
            'created_at' => now(),
            'require_return_before_checkout' => false,
        ]);

        $user->stores()->sync([$storeId => ['is_primary' => true]]);

        return 'User berhasil ditambahkan.';
    }

    private function updateUser(Request $request, int $storeId, int $id): string
    {
        $user = User::query()->with('stores')->findOrFail($id);
        abort_unless($user->stores()->where('stores.id', $storeId)->exists(), 404);

        $validated = $request->validate([
            'nama' => ['required', 'string', 'max:255', Rule::unique('users', 'nama')->ignore($user->id_user, 'id_user')],
            'permission_role_id' => ['required', 'integer', Rule::exists('permission_roles', 'id')->where(fn ($query) => $query->whereIn('legacy_role', [SalesRole::OWNER, SalesRole::KARYAWAN]))],
            'status' => ['required', Rule::in(['aktif', 'nonaktif'])],
            'password' => ['nullable', 'string', 'min:8'],
        ]);

        $role = PermissionRole::query()->findOrFail($validated['permission_role_id']);

        $user->update([
            'nama' => $validated['nama'],
            'status' => $validated['status'],
            'role' => $role->legacy_role,
            'permission_role_id' => $role->id,
            'password' => $validated['password'] ?: $user->password,
            'require_return_before_checkout' => false,
        ]);

        $user->stores()->sync([$storeId => ['is_primary' => true]]);

        return 'User berhasil diperbarui.';
    }

    private function destroyUser(Request $request, int $storeId, int $id): string
    {
        $user = User::query()->with('stores')->findOrFail($id);
        abort_unless($user->stores()->where('stores.id', $storeId)->exists(), 404);
        abort_if((int) $request->user()->id_user === (int) $user->id_user, 422, 'User yang sedang login tidak dapat dihapus.');

        $user->delete();

        return 'User berhasil dihapus.';
    }

    private function updateSalesTarget(Request $request, string $role): string
    {
        abort_unless(in_array($role, ['karyawan', 'revenue_target'], true), 404);

        if ($role === 'revenue_target') {
            $validated = $request->validate([
                'monthly_target_revenue' => ['required', 'numeric', 'min:0'],
                'minimum_kpi_value' => ['required', 'numeric', 'min:0', 'max:100'],
                'maximum_late_days' => ['required', 'integer', 'min:0'],
                'minimum_attendance_percentage' => ['required', 'numeric', 'min:0', 'max:100'],
                'revenue_bonus' => ['required', 'numeric', 'min:0'],
            ]);
        } else {
            $validated = $request->validate([
                'daily_target_qty' => ['required', 'integer', 'min:0'],
                'daily_bonus' => ['required', 'numeric', 'min:0'],
                'weekly_target_qty' => ['required', 'integer', 'min:0'],
                'weekly_bonus' => ['required', 'numeric', 'min:0'],
                'monthly_target_qty' => ['required', 'integer', 'min:0'],
                'monthly_bonus' => ['required', 'numeric', 'min:0'],
            ]);
        }

        SalesTarget::query()->updateOrCreate(['role' => $role], $validated);

        return 'Target penjualan berhasil diperbarui.';
    }

    private function storeHpp(Request $request, int $storeId): string
    {
        $validated = $request->validate([
            'id_product' => ['required', Rule::exists('products', 'id_product')->where(fn ($query) => $query->where('store_id', $storeId))],
            'items' => ['required', 'array', 'min:1'],
            'items.*.id_rm' => ['required', 'distinct', Rule::exists('raw_materials', 'id_rm')->where(fn ($query) => $query->where('store_id', $storeId))],
            'items.*.presentase' => ['required', 'numeric', 'min:0.01'],
        ], [
            'items.*.id_rm.distinct' => 'Raw material tidak boleh dipilih lebih dari sekali.',
        ]);

        DB::transaction(function () use ($validated, $storeId): void {
            $product = Product::query()->lockForUpdate()->findOrFail($validated['id_product']);
            abort_unless((int) $product->store_id === $storeId, 404);

            $rawMaterials = RawMaterial::query()
                ->whereIn('id_rm', collect($validated['items'])->pluck('id_rm')->all())
                ->get()
                ->keyBy('id_rm');

            $calculation = HppCalculation::query()->firstOrNew([
                'store_id' => $storeId,
                'id_product' => $product->id_product,
            ]);

            $total = collect($validated['items'])->sum(function (array $item) use ($rawMaterials) {
                $rawMaterial = $rawMaterials->get($item['id_rm']);

                return RawMaterialUsage::calculateItemCost(
                    (float) $item['presentase'],
                    (float) ($rawMaterial?->harga_satuan ?? 0),
                    (string) ($rawMaterial?->satuan ?? ''),
                    null
                );
            });

            $calculation->total_hpp = $total;
            $calculation->store_id = $storeId;
            if (! $calculation->exists) {
                $calculation->created_at = now();
            }
            $calculation->updated_at = now();
            $calculation->save();

            $calculation->items()->delete();
            foreach ($validated['items'] as $item) {
                $rawMaterial = $rawMaterials->get($item['id_rm']);
                $inputValue = (float) $item['presentase'];
                $hargaSatuan = (float) ($rawMaterial?->harga_satuan ?? 0);
                $hargaFinal = RawMaterialUsage::calculateItemCost(
                    $inputValue,
                    $hargaSatuan,
                    (string) ($rawMaterial?->satuan ?? ''),
                    null
                );

                $calculation->items()->create([
                    'id_rm' => $rawMaterial?->id_rm,
                    'nama_rm' => $rawMaterial?->nama_rm,
                    'satuan' => $rawMaterial?->satuan,
                    'presentase' => $inputValue,
                    'harga_satuan' => $hargaSatuan,
                    'harga_final' => $hargaFinal,
                    'total_stock' => (float) ($rawMaterial?->total_quantity ?? 0),
                    'created_at' => now(),
                ]);
            }

            $product->update(['harga_modal' => $calculation->total_hpp]);
        });

        return 'Perhitungan HPP berhasil disimpan.';
    }

    private function destroyHpp(int $storeId, int $id): string
    {
        $hpp = HppCalculation::query()->findOrFail($id);
        abort_unless((int) $hpp->store_id === $storeId, 404);

        DB::transaction(function () use ($hpp): void {
            $product = Product::query()->find($hpp->id_product);
            $hpp->delete();

            if ($product) {
                $product->update(['harga_modal' => 0]);
            }
        });

        return 'Perhitungan HPP berhasil dihapus.';
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
