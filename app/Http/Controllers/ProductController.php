<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\ProductVariant;
use App\Models\FragranceDetail;
use App\Models\HppCalculationItem;
use App\Models\OfflineSale;
use App\Models\Product;
use App\Models\ProductImage;
use App\Models\ProductOnhand;
use App\Models\RawMaterial;
use App\Support\RawMaterialUsage;
use App\Support\ProductOnhandBatchSupport;
use App\Support\SalesRole;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use App\Support\ProductOnhandStock;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;
use Inertia\Response;
use Throwable;

class ProductController extends Controller
{
    public function index(Request $request): Response
    {
        $user = $request->user();
        $storeId = $this->currentStoreId($request);

        if (in_array($user->role, ['superadmin', 'admin', SalesRole::OWNER], true) && $user->hasPermission('products.manage')) {
            $this->authorizePermission($request, 'products.view');

            $products = Product::query()
                ->where('store_id', $storeId)
                ->with(['fragranceDetails', 'images', 'variants'])
                ->orderByDesc('created_at')
                ->orderByDesc('id_product')
                ->get()
                ->map(fn (Product $product) => [
                    'id_product' => $product->id_product,
                    'nama_product' => $product->nama_product,
                    'harga' => (float) $product->harga,
                    'harga_modal' => (float) $product->harga_modal,
                    'stock' => (int) $product->stock,
                    'gambar' => $this->productImageUrl($product),
                    'gallery_images' => $product->images
                        ->map(fn (ProductImage $image) => [
                            'id' => $image->id,
                            'image_url' => $image->public_url,
                            'sort_order' => (int) $image->sort_order,
                        ])
                        ->values(),
                    'deskripsi' => $product->deskripsi,
                    'fragrance_details' => $product->fragranceDetails
                        ->sortBy(['jenis', 'detail'])
                        ->map(fn (FragranceDetail $detail) => [
                            'id_fd' => $detail->id_fd,
                            'jenis' => $detail->jenis,
                            'detail' => $detail->detail,
                            'deskripsi' => $detail->deskripsi,
                        ])
                        ->values(),
                    'variants' => $product->variants->map(fn (ProductVariant $variant) => [
                        'id' => $variant->id,
                        'name' => $variant->name,
                        'price' => (float) $variant->price,
                        'total_satuan_ml' => (float) $variant->total_satuan_ml,
                        'is_default' => (bool) $variant->is_default,
                    ])->values(),
                    'created_at' => optional($product->created_at)->format('Y-m-d H:i:s'),
                ])
                ->values();

            $fragranceDetails = FragranceDetail::query()
                ->orderBy('jenis')
                ->orderBy('detail')
                ->get()
                ->map(fn (FragranceDetail $detail) => [
                    'id_fd' => $detail->id_fd,
                    'jenis' => $detail->jenis,
                    'detail' => $detail->detail,
                    'deskripsi' => $detail->deskripsi,
                    'option_label' => ucfirst($detail->jenis) . ' - ' . $detail->detail,
                ])
                ->values();

            return Inertia::render('Products/Manage', [
                'products' => $products,
                'fragranceDetails' => $this->isSmoothiesSweetieStore($request) ? [] : $fragranceDetails,
                'isSmoothiesSweetie' => $this->isSmoothiesSweetieStore($request),
            ]);
        }

        abort_unless(SalesRole::isFieldRole($user->role) && $user->hasPermission('products.view'), 403);
        $this->abortIfStoreDisablesOnhandAndConsignment($request);

        $todayAttendance = null;
        $attendanceReady = true;
        $attendanceBlockedReason = null;

        if ($user->role === 'marketing') {
            $todayAttendance = Attendance::query()
                ->where('user_id', $user->id_user)
                ->whereDate('attendance_date', now()->toDateString())
                ->first();

            $attendanceReady = (bool) $todayAttendance?->check_in && ! $todayAttendance?->check_out;

            if (! $todayAttendance?->check_in) {
                $attendanceBlockedReason = 'Sales lapangan wajib check in terlebih dahulu sebelum mengambil barang.';
            } elseif ($todayAttendance?->check_out) {
                $attendanceBlockedReason = 'User yang sudah check out tidak bisa request barang lagi hari ini.';
            }
        }

        $products = Product::query()
            ->where('store_id', $storeId)
            ->where('stock', '>', 0)
            ->orderBy('nama_product')
            ->get(['id_product', 'nama_product', 'stock', 'harga'])
            ->map(fn (Product $product) => [
                'id_product' => $product->id_product,
                'nama_product' => $product->nama_product,
                'stock' => (int) $product->stock,
                'harga' => (float) $product->harga,
                'option_label' => $product->nama_product . ' | stock ' . (int) $product->stock,
            ])
            ->values();

        $onhands = ProductOnhand::query()
            ->where('store_id', $storeId)
            ->where('user_id', $user->id_user)
            ->orderByDesc('assignment_date')
            ->orderByDesc('id_product_onhand')
            ->get()
            ->map(fn (ProductOnhand $onhand) => $this->transformOnhand($onhand))
            ->values();

        $todayReturnItems = ProductOnhand::query()
            ->where('store_id', $storeId)
            ->where('user_id', $user->id_user)
            ->orderByDesc('assignment_date')
            ->orderByDesc('id_product_onhand')
            ->get()
            ->map(fn (ProductOnhand $onhand) => $this->transformOnhand($onhand))
            ->filter(fn (array $onhand) => $onhand['take_status'] !== 'ditolak' && (
                $onhand['take_status'] !== 'disetujui'
                || ! $onhand['sold_out']
                || $onhand['quantity_dikembalikan'] > 0
            ))
            ->values();

        $historyOnhands = $onhands
            ->filter(fn (array $onhand) => $onhand['take_status'] === 'disetujui' && $onhand['remaining_quantity'] <= 0)
            ->values();

        return Inertia::render('Products/Onhand', [
            'products' => $products,
            'attendanceReady' => $attendanceReady,
            'attendanceBlockedReason' => $attendanceBlockedReason,
            'todayAttendance' => $todayAttendance ? [
                'status' => $todayAttendance->status,
                'check_in' => $todayAttendance->check_in,
                'check_out' => $todayAttendance->check_out,
            ] : null,
            'onhands' => $onhands,
            'todayReturnItems' => $todayReturnItems,
            'historyOnhands' => $historyOnhands,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->authorizeManagement($request);
        $storeId = $this->currentStoreId($request);

        $validated = $request->validate([
            'nama_product' => ['required', 'string', 'max:255', Rule::unique('products', 'nama_product')->where(fn ($query) => $query->where('store_id', $storeId))],
            'harga' => ['required', 'numeric', 'min:0'],
            'stock' => ['required', 'integer', 'min:0'],
            'gambar' => ['nullable', 'image', 'max:3072'],
            'deskripsi' => ['nullable', 'string'],
            'fragrance_details' => ['nullable', 'array'],
            'fragrance_details.*' => ['integer', 'exists:fragrance_details,id_fd'],
            'variants' => ['nullable', 'array'],
            'variants.*.name' => ['required_with:variants', 'string', 'max:255'],
            'variants.*.price' => ['required_with:variants', 'numeric', 'min:0'],
            'variants.*.total_satuan_ml' => ['nullable', 'numeric', 'min:0'],
            'variants.*.is_default' => ['nullable', 'boolean'],
        ]);

        if ((int) $validated['stock'] > 0) {
            throw ValidationException::withMessages([
                'stock' => 'Product baru harus dibuat dengan stock 0. Setelah HPP dibuat, tambahkan stock melalui edit product.',
            ]);
        }

        $path = $request->file('gambar')?->store('products', 'public');

        try {
            DB::transaction(function () use ($validated, $path, $storeId): void {
                $product = Product::query()->create([
                    'store_id' => $storeId,
                    'nama_product' => $validated['nama_product'],
                    'harga' => $validated['harga'],
                    'harga_modal' => 0,
                    'stock' => $validated['stock'],
                    'gambar' => $path,
                    'deskripsi' => $validated['deskripsi'] ?? null,
                    'created_at' => now(),
                ]);

                $product->fragranceDetails()->sync($validated['fragrance_details'] ?? []);
                $this->syncVariants($product, $validated['variants'] ?? [], true);
            });
        } catch (Throwable $exception) {
            if ($path) {
                Storage::disk('public')->delete($path);
            }

            throw $exception;
        }

        return redirect()->route('products.index')->with('success', 'Product berhasil ditambahkan.');
    }

    public function update(Request $request, Product $product): RedirectResponse
    {
        $this->authorizeManagement($request);
        $this->ensureStoreMatch($request, $product);
        $storeId = $this->currentStoreId($request);

        $validated = $request->validate([
            'nama_product' => ['required', 'string', 'max:255', Rule::unique('products', 'nama_product')->where(fn ($query) => $query->where('store_id', $storeId))->ignore($product->id_product, 'id_product')],
            'harga' => ['required', 'numeric', 'min:0'],
            'stock' => ['required', 'integer', 'min:0'],
            'gambar' => ['nullable', 'image', 'max:3072'],
            'deskripsi' => ['nullable', 'string'],
            'fragrance_details' => ['nullable', 'array'],
            'fragrance_details.*' => ['integer', 'exists:fragrance_details,id_fd'],
            'variants' => ['nullable', 'array'],
            'variants.*.id' => ['nullable', 'integer', 'exists:product_variants,id'],
            'variants.*.name' => ['required_with:variants', 'string', 'max:255'],
            'variants.*.price' => ['required_with:variants', 'numeric', 'min:0'],
            'variants.*.total_satuan_ml' => ['nullable', 'numeric', 'min:0'],
            'variants.*.is_default' => ['nullable', 'boolean'],
        ]);

        $payload = [
            'nama_product' => $validated['nama_product'],
            'harga' => $validated['harga'],
            'stock' => $validated['stock'],
            'deskripsi' => $validated['deskripsi'] ?? null,
        ];

        $newImagePath = null;
        $oldImagePath = $product->gambar;

        if ($request->hasFile('gambar')) {
            $newImagePath = $request->file('gambar')->store('products', 'public');
            $payload['gambar'] = $newImagePath;
        }

        try {
            DB::transaction(function () use ($product, $payload, $validated): void {
                $previousStock = (int) $product->stock;
                $stockIncrease = max((int) $validated['stock'] - $previousStock, 0);

                if ($stockIncrease > 0) {
                    $this->consumeRawMaterialsForProduct($product, $stockIncrease);
                }

                $product->update($payload);
                $product->fragranceDetails()->sync($validated['fragrance_details'] ?? []);
                $this->syncVariants($product, $validated['variants'] ?? []);
            });
        } catch (Throwable $exception) {
            if ($newImagePath) {
                Storage::disk('public')->delete($newImagePath);
            }

            throw $exception;
        }

        if ($newImagePath && $oldImagePath) {
            Storage::disk('public')->delete($oldImagePath);
        }

        return redirect()->route('products.index')->with('success', 'Product berhasil diperbarui.');
    }

    public function destroy(Request $request, Product $product): RedirectResponse
    {
        $this->authorizeManagement($request);
        $this->ensureStoreMatch($request, $product);

        if ($product->gambar) {
            Storage::disk('public')->delete($product->gambar);
        }

        if ($product->normalized_bottle_image_path && Storage::disk('public')->exists($product->normalized_bottle_image_path)) {
            Storage::disk('public')->delete($product->normalized_bottle_image_path);
        }

        $product->load('images');
        $product->images->each(function (ProductImage $image): void {
            if ($image->normalized_image_path && Storage::disk('public')->exists($image->normalized_image_path)) {
                Storage::disk('public')->delete($image->normalized_image_path);
            }
        });

        $product->delete();

        return redirect()->route('products.index')->with('success', 'Product berhasil dihapus.');
    }

    public function showImage(Request $request, Product $product)
    {
        abort_unless($request->user(), 403);
        abort_if(! $product->normalized_image_path, 404);
        abort_unless(Storage::disk('public')->exists($product->normalized_image_path), 404);

        return Storage::disk('public')->response($product->normalized_image_path);
    }

    public function showPublicImage(Product $product)
    {
        if (! $product->normalized_image_path || ! Storage::disk('public')->exists($product->normalized_image_path)) {
            return $this->publicFallbackImageResponse();
        }

        return Storage::disk('public')->response($product->normalized_image_path);
    }

    public function showPublicBottleImage(Product $product)
    {
        if (! $product->normalized_bottle_image_path || ! Storage::disk('public')->exists($product->normalized_bottle_image_path)) {
            return $this->publicFallbackImageResponse();
        }

        return Storage::disk('public')->response($product->normalized_bottle_image_path);
    }

    public function showPublicGalleryImage(ProductImage $image)
    {
        if (! $image->normalized_image_path || ! Storage::disk('public')->exists($image->normalized_image_path)) {
            return $this->publicFallbackImageResponse();
        }

        return Storage::disk('public')->response($image->normalized_image_path);
    }

    public function take(Request $request): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, [SalesRole::MARKETING, SalesRole::SALES_FIELD_EXECUTIVE], true) && $request->user()->hasPermission('products.take'), 403);
        $storeId = $this->currentStoreId($request);

        if (SalesRole::requiresAttendanceToSell($request->user()->role)) {
            $attendance = Attendance::query()
                ->where('user_id', $request->user()->id_user)
                ->whereDate('attendance_date', now()->toDateString())
                ->first();

            if (! $attendance?->check_in) {
                return back()->withErrors(['request_product' => 'Sales lapangan wajib check in terlebih dahulu sebelum mengambil barang.']);
            }

            if ($attendance?->check_out) {
                return back()->withErrors(['request_product' => 'User yang sudah check out tidak bisa request barang lagi hari ini.']);
            }
        }

        $validated = $request->validate([
            'id_product' => ['required', 'exists:products,id_product'],
            'quantity' => ['required', 'integer', 'min:1'],
        ]);

        $pendingRequest = ProductOnhand::query()
            ->where('user_id', $request->user()->id_user)
            ->where('id_product', $validated['id_product'])
            ->whereDate('assignment_date', now()->toDateString())
            ->where('take_status', 'pending')
            ->exists();

        if ($pendingRequest) {
            return back()->withErrors(['id_product' => 'Masih ada antrian yang belum disetujui']);
        }

        $product = Product::query()->findOrFail($validated['id_product']);
        abort_unless((int) $product->store_id === $storeId, 404);

        if ($product->stock <= 0) {
            return back()->withErrors(['stock_empty' => 'Stock Kosong, Silahkan Hubungi Admin!']);
        }

        if ($product->stock < $validated['quantity']) {
            return back()->withErrors(['quantity' => 'Stock product tidak mencukupi.']);
        }

        $onhand = ProductOnhand::query()->create([
            'store_id' => $storeId,
            'user_id' => $request->user()->id_user,
            'id_product' => $product->id_product,
            'nama_product' => $product->nama_product,
            'quantity' => $validated['quantity'],
            'quantity_dikembalikan' => 0,
            'take_status' => 'pending',
            'return_status' => 'belum',
            'assignment_date' => now()->toDateString(),
            'created_at' => now(),
            'take_requested_at' => now(),
        ]);

        $onhand->update(['pickup_batch_code' => ProductOnhandBatchSupport::generate($onhand)]);

        return redirect()->route('products.index')->with('success', 'Request pengambilan barang berhasil dikirim.');
    }

    public function requestReturn(Request $request, ProductOnhand $onhand): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, [SalesRole::MARKETING, SalesRole::SALES_FIELD_EXECUTIVE], true) && $request->user()->hasPermission('products.take'), 403);
        $this->ensureStoreMatch($request, $onhand);
        abort_unless($onhand->user_id === $request->user()->id_user, 404);

        if ($onhand->take_status !== 'disetujui') {
            return back()->withErrors(['quantity_dikembalikan' => 'Barang belum disetujui untuk dibawa.']);
        }

        $state = $this->stateForOnhand($onhand);

        if ($onhand->return_status === 'pending') {
            return back()->withErrors(['quantity_dikembalikan' => 'Masih ada antrian yang belum disetujui']);
        }

        if ($state['sold_out']) {
            return back()->withErrors(['quantity_dikembalikan' => 'Barang sudah habis terjual, tidak wajib pengembalian.']);
        }

        $validated = $request->validate([
            'quantity_dikembalikan' => ['required', 'integer', 'min:1'],
        ]);

        if ($validated['quantity_dikembalikan'] > (int) $onhand->quantity) {
            return back()->withErrors(['quantity_dikembalikan' => 'Quantity pengembalian tidak boleh melebihi quantity pengambilan.']);
        }

        if ($validated['quantity_dikembalikan'] > $state['max_return']) {
            return back()->withErrors(['quantity_dikembalikan' => 'Quantity pengembalian melebihi sisa barang yang belum terjual.']);
        }

        $onhand->update([
            'quantity_dikembalikan' => $validated['quantity_dikembalikan'],
            'return_status' => $validated['quantity_dikembalikan'] > 0 ? 'pending' : 'belum',
            'approved_by' => null,
        ]);

        return redirect()->route('products.index')->with('success', 'Request pengembalian barang berhasil dikirim.');
    }

    public function approveReturn(Request $request, ProductOnhand $onhand): RedirectResponse
    {
        $this->authorizeApproval($request);
        $this->ensureStoreMatch($request, $onhand);
        abort_unless($onhand->quantity_dikembalikan > 0, 422);

        DB::transaction(function () use ($request, $onhand): void {
            $product = Product::query()->lockForUpdate()->findOrFail($onhand->id_product);
            $product->increment('stock', $onhand->quantity_dikembalikan);

            $onhand->update([
                'approved_return_quantity' => (int) ($onhand->approved_return_quantity ?? 0) + (int) $onhand->quantity_dikembalikan,
                'quantity_dikembalikan' => 0,
                'return_status' => 'disetujui',
                'approved_by' => $request->user()->id_user,
            ]);
        });

        return $this->managerRedirect($onhand, 'Pengembalian barang disetujui.');
    }

    public function rejectReturn(Request $request, ProductOnhand $onhand): RedirectResponse
    {
        $this->authorizeApproval($request);
        $this->ensureStoreMatch($request, $onhand);

        $onhand->update([
            'quantity_dikembalikan' => 0,
            'return_status' => 'tidak_disetujui',
            'approved_by' => $request->user()->id_user,
        ]);

        return $this->managerRedirect($onhand, 'Pengembalian barang ditolak.');
    }

    public function approveTake(Request $request, ProductOnhand $onhand): RedirectResponse
    {
        $this->authorizeApproval($request);
        $this->ensureStoreMatch($request, $onhand);
        abort_unless($onhand->take_status === 'pending', 422);

        DB::transaction(function () use ($request, $onhand): void {
            $product = Product::query()->lockForUpdate()->findOrFail($onhand->id_product);

            if ($product->stock < $onhand->quantity) {
                abort(422, 'Stock product tidak mencukupi untuk menyetujui request ini.');
            }

            $product->decrement('stock', $onhand->quantity);

            $onhand->update([
                'take_status' => 'disetujui',
                'take_approved_by' => $request->user()->id_user,
                'take_reviewed_at' => now(),
            ]);
        });

        return $this->managerRedirect($onhand, 'Request pengambilan barang disetujui.');
    }

    public function rejectTake(Request $request, ProductOnhand $onhand): RedirectResponse
    {
        $this->authorizeApproval($request);
        $this->ensureStoreMatch($request, $onhand);
        abort_unless($onhand->take_status === 'pending', 422);

        $onhand->update([
            'take_status' => 'ditolak',
            'take_approved_by' => $request->user()->id_user,
            'take_reviewed_at' => now(),
        ]);

        return $this->managerRedirect($onhand, 'Request pengambilan barang ditolak.');
    }

    private function authorizeManagement(Request $request): void
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin', SalesRole::OWNER], true) && $request->user()->hasPermission('products.manage'), 403);
    }

    private function authorizeApproval(Request $request): void
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true) && $request->user()->hasPermission('products.approve'), 403);
    }

    private function transformOnhand(ProductOnhand $onhand): array
    {
        $state = $this->stateForOnhand($onhand);
        $approvedReturnQuantity = ProductOnhandStock::approvedReturnQuantity($onhand);
        $pendingReturnQuantity = ProductOnhandStock::pendingReturnQuantity($onhand);

        return [
            'id_product_onhand' => $onhand->id_product_onhand,
            'id_product' => $onhand->id_product,
            'nama_product' => $onhand->nama_product,
            'quantity' => (int) $onhand->quantity,
            'quantity_dikembalikan' => $approvedReturnQuantity + $pendingReturnQuantity,
            'approved_return_quantity' => $approvedReturnQuantity,
            'pending_return_quantity' => $pendingReturnQuantity,
            'take_status' => $onhand->take_status,
            'take_status_label' => $this->takeStatusLabel($onhand->take_status),
            'return_status' => $onhand->return_status,
            'return_status_label' => $this->returnStatusLabel($onhand->return_status),
            'status_label' => $state['status_label'],
            'assignment_date' => optional($onhand->assignment_date)->format('Y-m-d'),
            'sold_quantity' => $state['sold_quantity'],
            'remaining_quantity' => $state['remaining_quantity'],
            'max_return' => $state['max_return'],
            'requires_return' => $state['requires_return'],
            'can_checkout' => $state['can_checkout'],
            'has_pending_request' => $onhand->return_status === 'pending',
            'sold_out' => $state['sold_out'],
            'can_request_return' => $onhand->take_status === 'disetujui' && ! $state['sold_out'],
        ];
    }

    private function stateForOnhand(ProductOnhand $onhand): array
    {
        if ($onhand->take_status !== 'disetujui') {
            return [
                'sold_quantity' => 0,
                'remaining_quantity' => 0,
                'max_return' => 0,
                'requires_return' => false,
                'can_checkout' => true,
                'sold_out' => false,
                'status_label' => $this->takeStatusLabel($onhand->take_status),
            ];
        }

        $soldQuantity = $this->soldForOnhand($onhand);
        $approvedReturnQuantity = ProductOnhandStock::approvedReturnQuantity($onhand);
        $pendingReturnQuantity = ProductOnhandStock::pendingReturnQuantity($onhand);
        $soldOut = $soldQuantity >= (int) $onhand->quantity;
        $remainingQuantity = max((int) $onhand->quantity - $soldQuantity - $approvedReturnQuantity - $pendingReturnQuantity, 0);
        $maxReturn = max((int) $onhand->quantity - $soldQuantity - $approvedReturnQuantity, 0);
        $requiresReturn = (bool) ($onhand->user?->require_return_before_checkout ?? true)
            && ! $soldOut
            && $maxReturn > 0;
        $canCheckout = ! $requiresReturn
            || (($soldQuantity + $approvedReturnQuantity) >= (int) $onhand->quantity);

        $statusLabel = $this->returnStatusLabel($onhand->return_status);
        if ($soldOut) {
            $statusLabel = 'Habis Terjual';
        } elseif ($approvedReturnQuantity > 0 && $remainingQuantity === 0) {
            $statusLabel = 'Dikembalikan';
        } elseif ($approvedReturnQuantity > 0) {
            $statusLabel = 'Sebagian Dikembalikan';
        }

        return [
            'sold_quantity' => $soldQuantity,
            'remaining_quantity' => $remainingQuantity,
            'max_return' => $maxReturn,
            'requires_return' => $requiresReturn,
            'can_checkout' => $canCheckout,
            'sold_out' => $soldOut,
            'status_label' => $statusLabel,
        ];
    }

    private function returnStatusLabel(string $status): string
    {
        return match ($status) {
            'belum' => 'Belum Dikembalikan',
            'pending' => 'Pending',
            'tidak_disetujui' => 'Tidak Disetujui',
            'disetujui' => 'Dikembalikan',
            default => $status,
        };
    }

    private function consumeRawMaterialsForProduct(Product $product, int $stockIncrease): void
    {
        if ($stockIncrease <= 0) {
            return;
        }

        $calculation = $product->hppCalculation()
            ->with('items')
            ->first();

        if (! $calculation || $calculation->items->isEmpty()) {
            throw ValidationException::withMessages([
                'stock' => 'HPP product belum dibuat. Buat HPP terlebih dahulu sebelum menambah stock product.',
            ]);
        }

        foreach ($calculation->items as $item) {
            $rawMaterial = RawMaterial::query()
                ->lockForUpdate()
                ->findOrFail($item->id_rm);
            abort_unless((int) $rawMaterial->store_id === (int) $product->store_id, 404);

            $usagePerProduct = RawMaterialUsage::calculateUsageQuantity((float) $item->presentase, $item->satuan);
            $requiredQuantity = round($usagePerProduct * $stockIncrease, 2);
            $availableQuantity = (float) $rawMaterial->total_quantity;

            if ($requiredQuantity > $availableQuantity) {
                $requiredDisplayQuantity = RawMaterialUsage::displayQuantity($requiredQuantity, $rawMaterial->satuan);
                $availableDisplayQuantity = RawMaterialUsage::displayQuantity($availableQuantity, $rawMaterial->satuan);
                $displayUnit = RawMaterialUsage::stockDisplayUnit($rawMaterial->satuan);

                throw ValidationException::withMessages([
                    'stock' => sprintf(
                        'Stock raw material %s tidak mencukupi. Dibutuhkan %s %s, tersedia %s %s.',
                        $rawMaterial->nama_rm,
                        number_format($requiredDisplayQuantity, 2, '.', ''),
                        $displayUnit,
                        number_format($availableDisplayQuantity, 2, '.', ''),
                        $displayUnit
                    ),
                ]);
            }

            $remainingQuantity = round($availableQuantity - $requiredQuantity, 2);
            $remainingStock = RawMaterialUsage::recalculatePackageStock($remainingQuantity, (float) $rawMaterial->quantity);

            $rawMaterial->update([
                'total_quantity' => $remainingQuantity,
                'stock' => $remainingStock,
                'harga_total' => round($remainingStock * (float) $rawMaterial->harga, 2),
            ]);

            HppCalculationItem::query()
                ->where('id_rm', $rawMaterial->id_rm)
                ->update(['total_stock' => $remainingQuantity]);
        }
    }

    private function syncVariants(Product $product, array $variants, bool $createDefaultWhenEmpty = false): void
    {
        $normalized = collect($variants)
            ->map(function (array $variant, int $index) {
                return [
                    'id' => isset($variant['id']) ? (int) $variant['id'] : null,
                    'name' => trim((string) ($variant['name'] ?? '')),
                    'price' => round((float) ($variant['price'] ?? 0), 2),
                    'total_satuan_ml' => round((float) ($variant['total_satuan_ml'] ?? 0), 2),
                    'is_default' => (bool) ($variant['is_default'] ?? false),
                    'sort_index' => $index,
                ];
            })
            ->filter(fn (array $variant) => $variant['name'] !== '')
            ->values();

        if ($normalized->isEmpty() && $createDefaultWhenEmpty) {
            $normalized = collect([[
                'id' => null,
                'name' => 'Reguler',
                'price' => (float) $product->harga,
                'total_satuan_ml' => 0,
                'is_default' => true,
                'sort_index' => 0,
            ]]);
        }

        if ($normalized->isEmpty()) {
            $product->variants()->delete();

            return;
        }

        if (! $normalized->contains(fn (array $variant) => $variant['is_default'])) {
            $normalized = $normalized->values()->map(fn (array $variant, int $index) => [
                ...$variant,
                'is_default' => $index === 0,
            ]);
        }

        $keepIds = [];

        foreach ($normalized as $variant) {
            $model = $variant['id']
                ? $product->variants()->whereKey($variant['id'])->first()
                : null;

            if (! $model) {
                $model = $product->variants()->create([
                    'name' => $variant['name'],
                    'price' => $variant['price'],
                    'total_satuan_ml' => $variant['total_satuan_ml'],
                    'is_default' => $variant['is_default'],
                ]);
            } else {
                $model->update([
                    'name' => $variant['name'],
                    'price' => $variant['price'],
                    'total_satuan_ml' => $variant['total_satuan_ml'],
                    'is_default' => $variant['is_default'],
                ]);
            }

            $keepIds[] = $model->id;
        }

        $product->variants()->whereNotIn('id', $keepIds)->delete();

        $defaultId = $product->variants()->where('is_default', true)->value('id');
        if (! $defaultId && isset($keepIds[0])) {
            $product->variants()->whereKey($keepIds[0])->update(['is_default' => true]);
        }
    }

    private function soldForOnhand(ProductOnhand $onhand): int
    {
        return ProductOnhandStock::soldQuantity($onhand);
    }

    private function takeStatusLabel(string $status): string
    {
        return match ($status) {
            'pending' => 'Menunggu Persetujuan',
            'ditolak' => 'Request Ditolak',
            default => 'Disetujui',
        };
    }

    private function managerRedirect(ProductOnhand $onhand, string $message): RedirectResponse
    {
        return redirect()
            ->route('approvals.index', ['selected' => $onhand->user_id])
            ->with('success', $message);
    }

    private function productImageUrl(Product $product): ?string
    {
        return $product->public_image_url;
    }

    private function publicFallbackImageResponse()
    {
        $fallbackPath = public_path('img/logo.png');
        abort_unless(is_file($fallbackPath), 404);

        return response()->file($fallbackPath, [
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }
}









