<template>
    <AppLayout>
    <Head title="Penjualan Offline" />

    <template #actions>
        <button type="button" class="btn btn-primary" @click="openCreateModal">
            <i class="fas fa-plus mr-1"></i>
            Tambah Penjualan
        </button>
    </template>

    <div v-if="$page.props.errors.promo_id" class="alert alert-danger">{{ $page.props.errors.promo_id }}</div>
    <div v-if="$page.props.errors.items" class="alert alert-danger">{{ $page.props.errors.items }}</div>
    <div v-if="$page.props.errors.customer_no_telp" class="alert alert-danger">{{ $page.props.errors.customer_no_telp }}</div>
    <div v-if="$page.props.errors.bukti_pembelian" class="alert alert-danger">{{ $page.props.errors.bukti_pembelian }}</div>
    <div v-if="$page.props.errors.created_at" class="alert alert-danger">{{ $page.props.errors.created_at }}</div>
    <div v-if="saleSummary" class="alert alert-success smoothies-sale-summary">
        <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-center gap-3">
            <div>
                <div class="font-weight-bold">Pembayaran {{ saleSummary.payment_method || 'Cash' }} berhasil ditutup</div>
                <div class="small text-muted">No. antrian {{ saleSummary.sale_number || '-' }} • {{ saleSummary.transaction_code || '-' }}</div>
                <div class="small text-muted">Total {{ toCurrency(saleSummary.total_harga) }} • {{ saleSummary.total_quantity || 0 }} item<span v-if="saleSummary.promo"> • Promo {{ saleSummary.promo }}</span></div>
            </div>
            <div class="d-flex gap-2 flex-wrap">
                <span class="badge bg-success-subtle text-success border px-3 py-2 text-uppercase">{{ saleSummary.payment_status || 'paid' }}</span>
                <button type="button" class="btn btn-sm btn-success" @click="openCreateModal">Transaksi Baru</button>
            </div>
        </div>
    </div>
    <div v-if="isSmoothiesSweetie && latestClosedSale" class="alert alert-info border smoothies-sale-summary">
        <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-center gap-3">
            <div>
                <div class="font-weight-bold">Antrian terakhir selesai di board</div>
                <div class="small text-muted">{{ latestClosedSale.sale_number || '-' }} • {{ latestClosedSale.transaction_code || '-' }}</div>
                <div class="small text-muted">Closed pada {{ latestClosedSale.closed_at || '-' }}</div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-lg-12">
            <div class="card card-outline card-success">
                <div class="card-header"><h3 class="card-title">Daftar Penjualan Offline</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Transaksi</th><th>Pelanggan</th><th>Item</th><th>Total Qty</th><th>Total Harga</th><th>Promo</th><th>Pembayaran</th><th>Status</th><th v-if="!isSmoothiesSweetie">Bukti</th><th class="action-column">Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in sales" :key="item.transaction_code || item.id_penjualan_offline" :class="{ 'table-success': item.payment_status === 'closed' }">
                                <td>
                                    <div>{{ item.nama_penjual }}</div>
                                    <div class="small text-muted">{{ item.created_at }}</div>
                                    <div class="small text-muted">{{ item.transaction_code || '-' }}</div>
                                    <div class="small text-muted">{{ item.sale_number || '-' }}</div>
                                </td>
                                <td>
                                    <div><button v-if="canManageAll" type="button" class="btn btn-link p-0 font-weight-bold text-left" @click="openEditModal(item)">{{ item.nama_customer || '-' }}</button><span v-else>{{ item.nama_customer || '-' }}</span></div>
                                    <div v-if="!isSmoothiesSweetie" class="small text-muted">{{ item.no_telp || '-' }}</div>
                                    <div v-if="!isSmoothiesSweetie" class="small text-muted">{{ item.tiktok_instagram || '-' }}</div>
                                </td>
                                <td>
                                    <div v-for="detail in item.items" :key="detail.id_penjualan_offline" class="text-sm">
                                        {{ detail.nama_product }} x {{ detail.quantity }}
                                        <span v-if="detail.extra_toppings?.length"> | {{ detail.extra_toppings.map((topping) => topping.name).join(', ') }}</span>
                                    </div>
                                </td>
                                <td>{{ item.total_quantity }}</td>
                                <td>{{ toCurrency(item.total_harga) }}</td>
                                <td>{{ item.promo || '-' }}</td>
                                <td>
                                    <div>{{ item.payment_method || '-' }} / {{ item.payment_status || '-' }}</div>
                                    <div v-if="item.closed_at" class="small text-muted">Closed {{ item.closed_at }}</div>
                                </td>
                                <td>{{ item.approval_status }}</td>
                                <td v-if="!isSmoothiesSweetie">
                                    <button v-if="item.bukti_pembelian" type="button" class="btn btn-link btn-sm p-0" @click="openProof(item.bukti_pembelian)">Lihat</button>
                                    <span v-else>-</span>
                                </td>
                                <td>
                                    <div class="action-group" :class="canApprove && item.approval_status === 'pending' && canManageAll ? 'action-group--four' : canApprove && item.approval_status === 'pending' ? 'action-group--three' : canManageAll ? 'action-group--two' : 'action-group--one'">
                                        <button v-if="canApprove && item.approval_status === 'pending'" class="btn btn-xs btn-success" @click="approve(item)">Setujui</button>
                                        <button v-if="canApprove && item.approval_status === 'pending'" class="btn btn-xs btn-danger" @click="reject(item)">Tolak</button>
                                        <button v-if="canManageAll" class="btn btn-xs btn-warning" @click="openEditModal(item)"><i class="fas fa-pen mr-1"></i>Edit</button>
                                        <button v-if="canManageAll" class="btn btn-xs btn-outline-danger" @click="removeSale(item)"><i class="fas fa-trash-alt mr-1"></i>Hapus</button>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="!sales.length"><td :colspan="isSmoothiesSweetie ? 9 : 10" class="text-center text-muted">Belum ada penjualan offline.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showFormModal" :title="formMode === 'create' ? 'Tambah Penjualan Offline' : 'Edit Transaksi'" size="xl" @close="closeFormModal">
        <div v-if="isSmoothiesSweetie && formMode === 'create'" class="crud-modal-body smoothies-crud-modal-body">
            <div class="border rounded p-3 bg-light position-relative">
                <div class="font-weight-bold mb-2">Data Pelanggan</div>
                <div class="form-group"><label>Nama Pembeli</label><input v-model="saleForm.customer_nama" type="text" class="form-control" placeholder="Opsional"></div>
                <div v-if="!isSmoothiesSweetie" class="form-group mb-1">
                    <label>No Telp</label>
                    <input v-model="saleForm.customer_no_telp" type="text" class="form-control" placeholder="Ketik no telp untuk cari pelanggan">
                </div>
                <div v-if="!isSmoothiesSweetie && activeCustomerSuggestions.length" class="list-group mb-3 suggestion-list">
                    <button v-for="customer in activeCustomerSuggestions" :key="customer.id_pelanggan" type="button" class="list-group-item list-group-item-action" @click="pickCustomerSuggestion(saleForm, customer)">
                        <div class="font-weight-bold">{{ customer.nama || 'Tanpa nama' }}</div>
                        <div class="small text-muted">{{ customer.no_telp || '-' }}<span v-if="customer.tiktok_instagram"> | {{ customer.tiktok_instagram }}</span></div>
                    </button>
                </div>
                <div v-if="!isSmoothiesSweetie" class="form-group mb-0"><label>Tiktok / Instagram</label><input v-model="saleForm.customer_tiktok_instagram" type="text" class="form-control" placeholder="Opsional"></div>
            </div>

            <div class="smoothies-pos-layout">
                <div class="smoothies-catalog card card-outline card-success">
                    <div class="card-header">
                        <h3 class="card-title mb-0">Pilih Menu</h3>
                    </div>
                    <div class="card-body">
                        <div v-if="products.length" class="smoothies-product-grid">
                            <button
                                v-for="product in products"
                                :key="product.id_product"
                                type="button"
                                class="smoothies-product-card"
                                @click="openSmoothiesVariantModal(product)"
                            >
                                <div class="smoothies-product-visual">
                                    <img v-if="product.image_url" :src="product.image_url" :alt="product.nama_product" class="smoothies-product-image">
                                    <div v-else class="smoothies-product-fallback">{{ productInitials(product.nama_product) }}</div>
                                </div>
                                <div class="smoothies-product-name">{{ product.nama_product }}</div>
                                <div class="smoothies-product-price">{{ toCurrency(product.harga) }}</div>
                                <div class="smoothies-product-caption">{{ plainDescription(product.deskripsi) || 'Klik untuk pilih size dan topping.' }}</div>
                            </button>
                        </div>
                        <div v-else class="alert alert-warning mb-0">
                            Produk Smoothies belum tersedia. Tambahkan product dulu agar kasir bisa membuat penjualan.
                        </div>
                    </div>
                </div>

                <div class="smoothies-cart card card-outline card-primary">
                    <div class="card-header">
                        <h3 class="card-title mb-0">Pesanan Kasir</h3>
                    </div>
                    <div class="card-body smoothies-cart-body">
                        <div v-if="saleForm.items.length" class="smoothies-cart-list">
                            <div v-for="(item, index) in saleForm.items" :key="item.key" class="smoothies-cart-item">
                                <div class="d-flex justify-content-between align-items-start gap-2">
                                    <div>
                                        <div class="font-weight-bold">{{ productName(item.id_product) }}</div>
                                        <div class="small text-muted">{{ itemState(item).variantName || 'Varian default' }}</div>
                                        <div v-if="item.extra_topping_ids?.length" class="small text-muted">{{ toppingSummary(item.extra_topping_ids) }}</div>
                                    </div>
                                    <button type="button" class="btn btn-xs btn-outline-danger" @click="removeItem(saleForm, index)">Hapus</button>
                                </div>
                                <div class="smoothies-cart-controls">
                                    <div class="btn-group btn-group-sm" role="group" :aria-label="`Atur quantity ${productName(item.id_product)}`">
                                        <button type="button" class="btn btn-outline-secondary" @click="decreaseItemQuantity(saleForm, index)">-</button>
                                        <button type="button" class="btn btn-light" disabled>{{ item.quantity }}</button>
                                        <button type="button" class="btn btn-outline-secondary" @click="increaseItemQuantity(item)">+</button>
                                    </div>
                                    <button type="button" class="btn btn-sm btn-outline-primary" @click="openSmoothiesToppingModal(item)">Ubah Topping</button>
                                </div>
                                <div class="small font-weight-bold text-right">{{ toCurrency(itemState(item).lineTotal) }}</div>
                            </div>
                        </div>
                        <div v-else class="smoothies-empty-cart">
                            Pilih menu dari kartu di sebelah kiri untuk mulai menambah pesanan.
                        </div>

                        <div class="border rounded p-3 bg-light">
                            <div class="form-group mb-0">
                                <label>Promo</label>
                                <Select2Input v-model="saleForm.promo_id" :options="promos" value-key="id" label-key="option_label" placeholder="Pilih promo" />
                            </div>
                            <div v-if="selectedCreatePromo" class="alert mt-3 mb-0" :class="createPromoWarning ? 'alert-warning' : 'alert-info'">
                                <div><strong>Syarat Promo</strong></div>
                                <div>Minimal quantity: {{ selectedCreatePromo.minimal_quantity }}</div>
                                <div>Minimal pembelian: {{ toCurrency(selectedCreatePromo.minimal_belanja) }}</div>
                                <div v-if="createPromoWarning" class="mt-2">{{ createPromoWarning }}</div>
                            </div>
                        </div>

                        <div class="border rounded p-3 bg-light">
                            <div class="font-weight-bold mb-2">Pembayaran</div>
                            <div class="form-group mb-0">
                                <label>Metode Pembayaran</label>
                                <select v-model="saleForm.payment_method" class="form-control">
                                    <option value="Cash">Cash</option>
                                    <option value="Qris">Qris</option>
                                </select>
                            </div>
                            <div v-if="saleForm.payment_method === 'Qris'" class="alert alert-info mt-3 mb-0 text-center">
                                <div class="font-weight-bold mb-2">Scan QRIS</div>
                                <img v-if="qrisImageUrl" :src="qrisImageUrl" alt="QRIS" class="img-fluid rounded border smoothies-qris-image">
                                <div v-else class="small text-muted">Gambar QRIS belum tersedia di pengaturan global.</div>
                            </div>
                        </div>

                        <div class="smoothies-total-box">
                            <div class="small text-muted">Total Item {{ totalQuantityFor(saleForm) }}</div>
                            <div class="h4 mb-0">{{ toCurrency(createDisplayPrice) }}</div>
                            <div v-if="createPromoEligible && createDiscountedPrice < createBasePrice" class="small text-muted">
                                <del>{{ toCurrency(createBasePrice) }}</del>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div v-else class="crud-modal-body">
            <div v-if="canManageAll" class="form-group mb-0">
                <label>Tanggal Transaksi</label>
                <input v-model="activeForm.created_at" type="datetime-local" class="form-control">
                <small class="text-muted">Admin dan superadmin bisa menentukan tanggal transaksi secara manual.</small>
            </div>

            <div class="border rounded p-3 bg-light position-relative">
                <div class="font-weight-bold mb-2">Data Pelanggan</div>
                <div class="form-group"><label>Nama Pembeli</label><input v-model="activeForm.customer_nama" type="text" class="form-control"></div>
                <div v-if="!isSmoothiesSweetie" class="form-group mb-1">
                    <label>No Telp</label>
                    <input v-model="activeForm.customer_no_telp" type="text" class="form-control" placeholder="Ketik no telp untuk cari pelanggan">
                </div>
                <div v-if="!isSmoothiesSweetie && activeCustomerSuggestions.length" class="list-group mb-3 suggestion-list">
                    <button v-for="customer in activeCustomerSuggestions" :key="customer.id_pelanggan" type="button" class="list-group-item list-group-item-action" @click="pickCustomerSuggestion(activeForm, customer)">
                        <div class="font-weight-bold">{{ customer.nama || 'Tanpa nama' }}</div>
                        <div class="small text-muted">{{ customer.no_telp || '-' }}<span v-if="customer.tiktok_instagram"> | {{ customer.tiktok_instagram }}</span></div>
                    </button>
                </div>
                <div v-if="!isSmoothiesSweetie" class="form-group mb-0"><label>Tiktok / Instagram</label><input v-model="activeForm.customer_tiktok_instagram" type="text" class="form-control"></div>
            </div>

            <div v-if="!canManageAll && !products.length" class="alert alert-warning mb-0">
                Produk belum bisa dipilih karena belum ada barang on hand yang disetujui dan masih punya sisa stok untuk dijual.
            </div>

            <div v-for="(item, index) in activeForm.items" :key="item.key" class="border rounded p-3 bg-light">
                <div class="d-flex justify-content-between align-items-center mb-2">
                    <strong>Product {{ index + 1 }}</strong>
                    <button v-if="activeForm.items.length > 1" class="btn btn-xs btn-outline-danger" @click="removeItem(activeForm, index)">Hapus</button>
                </div>
                <div class="form-group mb-2">
                    <label>Product</label>
                    <Select2Input v-model="item.id_product" :options="products" value-key="id_product" label-key="option_label" placeholder="Cari lalu pilih product" />
                </div>
                <div v-if="variantsForProduct(item.id_product).length" class="form-group mb-2">
                    <label>Size / Varian</label>
                    <Select2Input v-model="item.product_variant_id" :options="variantsForProduct(item.id_product)" value-key="id" label-key="option_label" placeholder="Pilih size" />
                </div>
                <div v-if="isSmoothiesSweetie && item.quantity > 0" class="form-group mb-2">
                    <label>Extra Topping</label>
                    <div class="border rounded p-2 bg-white">
                        <div v-for="topping in extraToppings" :key="`${item.key}-${topping.id}`" class="custom-control custom-checkbox">
                            <input :id="`${item.key}-${topping.id}`" v-model="item.extra_topping_ids" :value="topping.id" type="checkbox" class="custom-control-input">
                            <label class="custom-control-label" :for="`${item.key}-${topping.id}`">{{ topping.name }} | {{ toCurrency(topping.price) }}</label>
                        </div>
                    </div>
                </div>
                <div class="form-group mb-2"><label>Quantity</label><input v-model="item.quantity" type="number" min="1" class="form-control"></div>
                <div v-if="itemState(item).variantName" class="small text-muted">Varian: {{ itemState(item).variantName }}</div>
                <div class="small text-muted">Harga Satuan: {{ toCurrency(itemState(item).hargaSatuan) }}</div>
                <div v-if="itemState(item).toppingTotalPerUnit > 0" class="small text-muted">Extra Topping / item: {{ toCurrency(itemState(item).toppingTotalPerUnit) }}</div>
                <div class="small text-muted">Line Total: {{ toCurrency(itemState(item).lineTotal) }}</div>
            </div>

            <div class="d-flex justify-content-end">
                <button type="button" class="btn btn-sm btn-outline-secondary" @click="addItem(activeForm)">Tambah Product</button>
            </div>

            <div class="form-group mb-0">
                <label>Promo</label>
                <Select2Input v-model="activeForm.promo_id" :options="promos" value-key="id" label-key="option_label" placeholder="Pilih promo" />
            </div>
            <div v-if="selectedActivePromo" class="alert mb-0" :class="activePromoWarning ? 'alert-warning' : 'alert-info'">
                <div><strong>Syarat Promo</strong></div>
                <div>Minimal quantity: {{ selectedActivePromo.minimal_quantity }}</div>
                <div>Minimal pembelian: {{ toCurrency(selectedActivePromo.minimal_belanja) }}</div>
                <div v-if="activePromoWarning" class="mt-2">{{ activePromoWarning }}</div>
            </div>
            <div class="form-group mb-0">
                <label>Total Harga</label>
                <div class="form-control bg-white">
                    <span v-if="activePromoEligible && activeDiscountedPrice < activeBasePrice"><del class="text-muted mr-2">{{ toCurrency(activeBasePrice) }}</del></span>
                    <strong>{{ toCurrency(activeDisplayPrice) }}</strong>
                </div>
            </div>
            <div class="form-group mb-0">
                <label>Metode Pembayaran</label>
                <select v-model="activeForm.payment_method" class="form-control">
                    <option value="Cash">Cash</option>
                    <option value="Qris">Qris</option>
                </select>
            </div>
            <div v-if="activeForm.payment_method === 'Qris'" class="alert alert-info mb-0 text-center">
                <div class="font-weight-bold mb-2">QRIS</div>
                <img v-if="qrisImageUrl" :src="qrisImageUrl" alt="QRIS" class="img-fluid rounded border" style="max-height:280px">
                <div v-else class="small text-muted">Gambar QRIS belum tersedia di pengaturan global.</div>
            </div>
            <div v-if="formMode === 'create' && !isSmoothiesSweetie" class="form-group mb-0"><label>Bukti Pembelian</label><input type="file" class="form-control" accept="image/*" @input="saleForm.bukti_pembelian = $event.target.files[0]"></div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeFormModal">Batal</button>
            <button v-if="formMode === 'create'" type="button" class="btn btn-primary" :disabled="saleForm.processing || !hasValidItems(saleForm) || Boolean(createPromoWarning)" @click="submitSale">{{ isSmoothiesSweetie ? 'Sudah Bayar' : 'Simpan Penjualan' }}</button>
            <button v-else type="button" class="btn btn-warning" :disabled="editForm.processing || !hasValidItems(editForm) || Boolean(editPromoWarning)" @click="submitEdit">Update</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showVariantModal" title="Pilih Size" size="lg" @close="closeVariantModal">
        <div class="crud-modal-body">
            <div v-if="pendingSmoothiesSelection" class="smoothies-selection-header">
                <div class="font-weight-bold">{{ pendingSmoothiesSelection.productName }}</div>
                <div class="small text-muted">Pilih size sebelum ditambahkan ke pesanan.</div>
            </div>
            <div v-if="pendingSmoothiesVariants.length" class="smoothies-option-grid">
                <button
                    v-for="variant in pendingSmoothiesVariants"
                    :key="variant.id"
                    type="button"
                    class="smoothies-option-card"
                    :class="{ 'smoothies-option-card--active': pendingSmoothiesSelection?.product_variant_id === String(variant.id) }"
                    @click="selectSmoothiesVariant(variant)"
                >
                    <div class="font-weight-bold">{{ variant.name }}</div>
                    <div class="small text-muted">{{ toCurrency(variant.price) }}</div>
                    <div v-if="variant.total_satuan_ml" class="small text-muted">{{ formatMl(variant.total_satuan_ml) }} ml</div>
                </button>
            </div>
            <div v-else class="alert alert-light border mb-0">Product ini belum punya varian.</div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeVariantModal">Batal</button>
            <button type="button" class="btn btn-primary" :disabled="!pendingSmoothiesSelection?.product_variant_id" @click="openSmoothiesToppingModal()">Lanjut Topping</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showToppingModal" title="Pilih Extra Topping" size="lg" @close="closeToppingModal">
        <div class="crud-modal-body">
            <div v-if="pendingSmoothiesSelection" class="smoothies-selection-header">
                <div class="font-weight-bold">{{ pendingSmoothiesSelection.productName }}</div>
                <div class="small text-muted">{{ pendingSmoothiesSelection.variantName || 'Varian default' }}</div>
            </div>
            <div v-if="extraToppings.length" class="smoothies-option-grid">
                <button
                    v-for="topping in extraToppings"
                    :key="topping.id"
                    type="button"
                    class="smoothies-option-card"
                    :class="{ 'smoothies-option-card--active': pendingSmoothiesSelection?.extra_topping_ids.includes(topping.id) }"
                    @click="togglePendingTopping(topping.id)"
                >
                    <div class="font-weight-bold">{{ topping.name }}</div>
                    <div class="small text-muted">{{ toCurrency(topping.price) }}</div>
                </button>
            </div>
            <div v-else class="alert alert-light border mb-0">Belum ada extra topping aktif.</div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeToppingModal">Batal</button>
            <button type="button" class="btn btn-primary" @click="commitSmoothiesSelection">Tambahkan ke Pesanan</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showProofModal" title="Bukti Pembelian" size="lg" @close="showProofModal = false">
        <div class="text-center">
            <img v-if="proofUrl" :src="proofUrl" alt="Bukti Pembelian" class="img-fluid rounded border">
        </div>
        <template #footer>
            <a v-if="proofUrl" :href="proofUrl" target="_blank" rel="noreferrer" class="btn btn-outline-primary">Buka Tab Baru</a>
            <button type="button" class="btn btn-secondary" @click="showProofModal = false">Tutup</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        {{ deleteMessage }}
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeDeleteModal">Batal</button>
            <button type="button" class="btn btn-danger" @click="confirmDeleteSale">Hapus</button>
        </template>
    </BootstrapModal>

    </AppLayout>
</template>

<script setup>
import { computed, ref } from 'vue';
import { Head, router, useForm, usePage } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import Select2Input from '../../Components/Select2Input.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';
import { adminUrl } from '../../utils/admin';

const props = defineProps({ sales: Array, products: Array, promos: Array, customers: Array, extraToppings: Array, canApprove: Boolean, canManageAll: Boolean, currentRole: String, defaultCreatedAt: String, isSmoothiesSweetie: Boolean, qrisImageUrl: String, lastClosedSale: Object });
const page = usePage();
const saleSummary = computed(() => page.props.flash?.saleSummary || null);
const latestClosedSale = computed(() => props.lastClosedSale || null);

const emptySaleItem = () => ({ key: `${Date.now()}-${Math.random()}`, id_product: '', product_variant_id: '', extra_topping_ids: [], quantity: 1 });
const defaultCreatedAt = props.defaultCreatedAt || new Date().toISOString().slice(0, 16);
const makeTransactionForm = (defaults = {}) => useForm({
    id_penjualan_offline: defaults.id_penjualan_offline ?? null,
    customer_nama: defaults.customer_nama ?? '',
    customer_no_telp: defaults.customer_no_telp ?? '',
    customer_tiktok_instagram: defaults.customer_tiktok_instagram ?? '',
    items: defaults.items ?? [emptySaleItem()],
    promo_id: defaults.promo_id ?? '',
    payment_method: defaults.payment_method ?? 'Cash',
    created_at: defaults.created_at ?? defaultCreatedAt,
    bukti_pembelian: defaults.bukti_pembelian ?? null,
});

const saleForm = makeTransactionForm();
const editForm = makeTransactionForm();
const formMode = ref('create');
const showFormModal = ref(false);
const showVariantModal = ref(false);
const showToppingModal = ref(false);
const proofUrl = ref('');
const showProofModal = ref(false);
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const deleteMessage = ref('');
const pendingSmoothiesSelection = ref(null);
const toppingEditTargetKey = ref(null);
const productMap = computed(() => Object.fromEntries(props.products.map((item) => [String(item.id_product), item])));
const extraToppingMap = computed(() => Object.fromEntries((props.extraToppings || []).map((item) => [String(item.id), item])));
const activeForm = computed(() => formMode.value === 'edit' ? editForm : saleForm);
const promoById = (promoId) => props.promos.find((item) => Number(item.id) === Number(promoId)) || null;
const variantsForProduct = (productId) => productMap.value[String(productId)]?.variants || [];
const variantById = (productId, variantId) => variantsForProduct(productId).find((item) => Number(item.id) === Number(variantId)) || null;
const itemState = (item) => {
    const product = productMap.value[String(item.id_product)] ?? null;
    const variant = variantById(item.id_product, item.product_variant_id) || variantsForProduct(item.id_product).find((entry) => entry.is_default) || null;
    const hargaSatuan = Number(variant?.price || product?.harga || 0);
    const quantity = Number(item.quantity || 0);
    const toppingTotalPerUnit = (item.extra_topping_ids || []).reduce((total, id) => total + Number(extraToppingMap.value[String(id)]?.price || 0), 0);
    return {
        hargaSatuan,
        variantName: variant?.name || '',
        toppingTotalPerUnit,
        lineTotal: (hargaSatuan + toppingTotalPerUnit) * quantity,
    };
};
const totalQuantityFor = (form) => form.items.reduce((total, item) => total + Number(item.quantity || 0), 0);
const basePriceFor = (form) => form.items.reduce((total, item) => total + itemState(item).lineTotal, 0);
const promoEligibleFor = (form) => {
    const selectedPromo = promoById(form.promo_id);
    if (!selectedPromo) return false;
    if (totalQuantityFor(form) < selectedPromo.minimal_quantity) return false;
    if (basePriceFor(form) < selectedPromo.minimal_belanja) return false;
    return true;
};
const displayPriceFor = (form) => {
    const selectedPromo = promoById(form.promo_id);
    return promoEligibleFor(form) ? Math.max(basePriceFor(form) - (selectedPromo?.potongan || 0), 0) : basePriceFor(form);
};
const promoWarningFor = (form) => {
    const selectedPromo = promoById(form.promo_id);
    if (!selectedPromo) return '';
    if (!promoEligibleFor(form)) return 'Pembelian belum mencapai syarat';
    return '';
};
const selectedCreatePromo = computed(() => promoById(saleForm.promo_id));
const selectedEditPromo = computed(() => promoById(editForm.promo_id));
const selectedActivePromo = computed(() => formMode.value === 'edit' ? selectedEditPromo.value : selectedCreatePromo.value);
const createBasePrice = computed(() => basePriceFor(saleForm));
const editBasePrice = computed(() => basePriceFor(editForm));
const activeBasePrice = computed(() => formMode.value === 'edit' ? editBasePrice.value : createBasePrice.value);
const createPromoEligible = computed(() => promoEligibleFor(saleForm));
const editPromoEligible = computed(() => promoEligibleFor(editForm));
const activePromoEligible = computed(() => formMode.value === 'edit' ? editPromoEligible.value : createPromoEligible.value);
const createDiscountedPrice = computed(() => displayPriceFor(saleForm));
const editDiscountedPrice = computed(() => displayPriceFor(editForm));
const activeDiscountedPrice = computed(() => formMode.value === 'edit' ? editDiscountedPrice.value : createDiscountedPrice.value);
const createDisplayPrice = computed(() => displayPriceFor(saleForm));
const editDisplayPrice = computed(() => displayPriceFor(editForm));
const activeDisplayPrice = computed(() => formMode.value === 'edit' ? editDisplayPrice.value : createDisplayPrice.value);
const createPromoWarning = computed(() => promoWarningFor(saleForm));
const editPromoWarning = computed(() => promoWarningFor(editForm));
const activePromoWarning = computed(() => formMode.value === 'edit' ? editPromoWarning.value : createPromoWarning.value);
const pendingSmoothiesVariants = computed(() => pendingSmoothiesSelection.value ? variantsForProduct(pendingSmoothiesSelection.value.id_product) : []);
const filteredCustomersFor = (phone) => {
    const keyword = String(phone || '').trim();
    if (!keyword) return [];
    return props.customers.filter((item) => String(item.no_telp || '').includes(keyword)).slice(0, 6);
};
const filteredCreateCustomers = computed(() => filteredCustomersFor(saleForm.customer_no_telp));
const filteredEditCustomers = computed(() => filteredCustomersFor(editForm.customer_no_telp));
const activeCustomerSuggestions = computed(() => formMode.value === 'edit' ? filteredEditCustomers.value : filteredCreateCustomers.value);
const hasValidItems = (form) => form.items.length > 0 && form.items.every((item) => item.id_product && Number(item.quantity || 0) > 0 && (!variantsForProduct(item.id_product).length || item.product_variant_id));
const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value || 0);
const plainDescription = (value) => String(value || '')
    .replace(/<[^>]*>/g, ' ')
    .replace(/&nbsp;/gi, ' ')
    .replace(/\s+/g, ' ')
    .trim();
const productName = (productId) => productMap.value[String(productId)]?.nama_product || 'Product';
const productInitials = (value) => String(value || '').trim().split(/\s+/).slice(0, 2).map((part) => part.charAt(0).toUpperCase()).join('') || 'SS';
const formatMl = (value) => new Intl.NumberFormat('id-ID', { maximumFractionDigits: 0 }).format(Number(value || 0));
const toppingSummary = (ids = []) => ids.map((id) => extraToppingMap.value[String(id)]?.name).filter(Boolean).join(', ');
const addItem = (form) => form.items.push(emptySaleItem());
const removeItem = (form, index) => form.items.splice(index, 1);
const increaseItemQuantity = (item) => {
    item.quantity = Number(item.quantity || 0) + 1;
};
const decreaseItemQuantity = (form, index) => {
    const item = form.items[index];
    if (!item) return;
    const nextQuantity = Number(item.quantity || 0) - 1;
    if (nextQuantity <= 0) {
        removeItem(form, index);
        return;
    }
    item.quantity = nextQuantity;
};
const pickCustomerSuggestion = (form, customer) => {
    form.customer_nama = customer.nama || '';
    form.customer_no_telp = customer.no_telp || '';
    form.customer_tiktok_instagram = customer.tiktok_instagram || '';
};
const resetSaleForm = () => {
    saleForm.reset('id_penjualan_offline', 'customer_nama', 'customer_no_telp', 'customer_tiktok_instagram', 'promo_id', 'payment_method', 'bukti_pembelian');
    saleForm.created_at = defaultCreatedAt;
    saleForm.payment_method = 'Cash';
    saleForm.items = props.isSmoothiesSweetie ? [] : [emptySaleItem()];
    pendingSmoothiesSelection.value = null;
    toppingEditTargetKey.value = null;
};
const resetEdit = () => {
    editForm.reset('id_penjualan_offline', 'customer_nama', 'customer_no_telp', 'customer_tiktok_instagram', 'promo_id', 'payment_method', 'bukti_pembelian');
    editForm.created_at = defaultCreatedAt;
    editForm.payment_method = 'Cash';
    editForm.items = [emptySaleItem()];
};
const openCreateModal = () => {
    formMode.value = 'create';
    resetSaleForm();
    showFormModal.value = true;
};
const openEditModal = (item) => {
    formMode.value = 'edit';
    editForm.id_penjualan_offline = item.id_penjualan_offline;
    editForm.customer_nama = item.nama_customer || '';
    editForm.customer_no_telp = item.no_telp || '';
    editForm.customer_tiktok_instagram = item.tiktok_instagram || '';
    editForm.promo_id = item.promo_id ? String(item.promo_id) : '';
    editForm.payment_method = item.payment_method || 'Cash';
    editForm.created_at = item.created_at_form || defaultCreatedAt;
    editForm.items = item.items.map((detail) => ({ key: `${detail.id_product}-${Math.random()}`, id_product: String(detail.id_product), product_variant_id: detail.product_variant_id ? String(detail.product_variant_id) : '', extra_topping_ids: detail.extra_topping_ids || [], quantity: detail.quantity }));
    showFormModal.value = true;
};
const closeFormModal = () => {
    showFormModal.value = false;
    formMode.value = 'create';
    showVariantModal.value = false;
    showToppingModal.value = false;
    resetSaleForm();
    resetEdit();
};
const closeVariantModal = () => {
    showVariantModal.value = false;
    pendingSmoothiesSelection.value = null;
};
const closeToppingModal = () => {
    showToppingModal.value = false;
    toppingEditTargetKey.value = null;
    pendingSmoothiesSelection.value = null;
};
const openSmoothiesVariantModal = (product) => {
    pendingSmoothiesSelection.value = {
        id_product: String(product.id_product),
        productName: product.nama_product,
        product_variant_id: '',
        variantName: '',
        extra_topping_ids: [],
    };
    toppingEditTargetKey.value = null;
    showVariantModal.value = true;
};
const selectSmoothiesVariant = (variant) => {
    if (!pendingSmoothiesSelection.value) return;
    pendingSmoothiesSelection.value.product_variant_id = String(variant.id);
    pendingSmoothiesSelection.value.variantName = variant.name;
};
const openSmoothiesToppingModal = (item = null) => {
    if (item) {
        pendingSmoothiesSelection.value = {
            id_product: String(item.id_product),
            productName: productName(item.id_product),
            product_variant_id: String(item.product_variant_id || ''),
            variantName: itemState(item).variantName,
            extra_topping_ids: [...(item.extra_topping_ids || [])],
        };
        toppingEditTargetKey.value = item.key;
        showToppingModal.value = true;
        return;
    }

    if (!pendingSmoothiesSelection.value?.product_variant_id) return;
    showVariantModal.value = false;
    showToppingModal.value = true;
};
const togglePendingTopping = (toppingId) => {
    if (!pendingSmoothiesSelection.value) return;
    const next = new Set(pendingSmoothiesSelection.value.extra_topping_ids || []);
    if (next.has(toppingId)) {
        next.delete(toppingId);
    } else {
        next.add(toppingId);
    }
    pendingSmoothiesSelection.value.extra_topping_ids = [...next];
};
const commitSmoothiesSelection = () => {
    const selection = pendingSmoothiesSelection.value;
    if (!selection?.id_product || !selection.product_variant_id) return;

    if (toppingEditTargetKey.value) {
        const item = saleForm.items.find((entry) => entry.key === toppingEditTargetKey.value);
        if (item) {
            item.extra_topping_ids = [...selection.extra_topping_ids];
        }
        toppingEditTargetKey.value = null;
        pendingSmoothiesSelection.value = null;
        showToppingModal.value = false;
        return;
    }

    const existing = saleForm.items.find((entry) => (
        String(entry.id_product) === String(selection.id_product)
        && String(entry.product_variant_id) === String(selection.product_variant_id)
        && JSON.stringify([...(entry.extra_topping_ids || [])].sort()) === JSON.stringify([...(selection.extra_topping_ids || [])].sort())
    ));

    if (existing) {
        existing.quantity = Number(existing.quantity || 0) + 1;
    } else {
        saleForm.items.push({
            key: `${Date.now()}-${Math.random()}`,
            id_product: String(selection.id_product),
            product_variant_id: String(selection.product_variant_id),
            extra_topping_ids: [...selection.extra_topping_ids],
            quantity: 1,
        });
    }

    pendingSmoothiesSelection.value = null;
    showToppingModal.value = false;
};
const submitSale = () => saleForm.transform((data) => ({
    ...data,
    items: data.items.map(({ id_product, product_variant_id, extra_topping_ids, quantity }) => ({ id_product, product_variant_id, extra_topping_ids, quantity })),
})).post(adminUrl('/offline-sales'), { forceFormData: true, preserveScroll: true, onSuccess: () => closeFormModal() });
const submitEdit = () => editForm.transform((data) => ({
    ...data,
    items: data.items.map(({ id_product, product_variant_id, extra_topping_ids, quantity }) => ({ id_product, product_variant_id, extra_topping_ids, quantity })),
})).put(adminUrl(`/offline-sales/${editForm.id_penjualan_offline}`), { preserveScroll: true, onSuccess: () => closeFormModal() });
const approve = (item) => router.post(adminUrl(`/offline-sales/${item.id_penjualan_offline}/approve`), {}, { preserveScroll: true });
const reject = (item) => router.post(adminUrl(`/offline-sales/${item.id_penjualan_offline}/reject`), {}, { preserveScroll: true });
const removeSale = (item) => {
    deleteTarget.value = item;
    deleteMessage.value = `Hapus transaksi ${item.transaction_code || item.id_penjualan_offline}?`;
    showDeleteModal.value = true;
};
const closeDeleteModal = () => {
    showDeleteModal.value = false;
    deleteTarget.value = null;
};
const confirmDeleteSale = () => {
    if (!deleteTarget.value) return;
    const id = deleteTarget.value.id_penjualan_offline;
    closeDeleteModal();
    router.delete(adminUrl(`/offline-sales/${id}`), { preserveScroll: true });
};
const openProof = (url) => {
    proofUrl.value = url;
    showProofModal.value = true;
};
</script>

<style scoped>
.action-column {
    min-width: 260px;
}

.action-group {
    display: grid;
    gap: 0.45rem;
}

.action-group--one {
    grid-template-columns: 1fr;
}

.action-group--two {
    grid-template-columns: repeat(2, minmax(0, 1fr));
}

.action-group--three {
    grid-template-columns: repeat(3, minmax(0, 1fr));
}

.action-group--four {
    grid-template-columns: repeat(4, minmax(0, 1fr));
}

.action-group .btn {
    width: 100%;
    min-width: 0;
    white-space: nowrap;
}

.crud-modal-body {
    display: grid;
    gap: 1rem;
}

.smoothies-crud-modal-body {
    gap: 1.25rem;
}

.smoothies-pos-layout {
    display: grid;
    grid-template-columns: minmax(0, 1.3fr) minmax(320px, 0.9fr);
    gap: 1rem;
}

.smoothies-catalog .card-body,
.smoothies-cart-body {
    display: grid;
    gap: 1rem;
}

.smoothies-product-grid,
.smoothies-option-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
    gap: 0.9rem;
}

.smoothies-product-card,
.smoothies-option-card {
    border: 1px solid #d7e6dd;
    border-radius: 1rem;
    background: linear-gradient(180deg, #ffffff 0%, #f4faf6 100%);
    padding: 0.9rem;
    text-align: left;
    transition: transform 0.15s ease, box-shadow 0.15s ease, border-color 0.15s ease;
}

.smoothies-product-card:hover,
.smoothies-option-card:hover,
.smoothies-option-card--active {
    transform: translateY(-2px);
    border-color: #4ea66c;
    box-shadow: 0 12px 24px rgba(26, 92, 49, 0.12);
}

.smoothies-product-visual {
    aspect-ratio: 1 / 1;
    border-radius: 0.9rem;
    overflow: hidden;
    background: linear-gradient(135deg, #dff5e5 0%, #f7fff8 100%);
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 0.75rem;
}

.smoothies-product-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

.smoothies-product-fallback {
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 2rem;
    font-weight: 800;
    color: #257147;
}

.smoothies-product-name {
    font-weight: 700;
}

.smoothies-product-price {
    color: #198754;
    font-weight: 700;
    margin-top: 0.2rem;
}

.smoothies-product-caption {
    color: #6c757d;
    font-size: 0.86rem;
    margin-top: 0.35rem;
}

.smoothies-cart-list {
    display: grid;
    gap: 0.85rem;
}

.smoothies-cart-item {
    border: 1px solid #dde7f1;
    border-radius: 0.9rem;
    padding: 0.9rem;
    background: #fff;
    display: grid;
    gap: 0.75rem;
}

.smoothies-cart-controls {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 0.75rem;
    flex-wrap: wrap;
}

.smoothies-empty-cart {
    border: 1px dashed #c6d7ca;
    border-radius: 1rem;
    padding: 1rem;
    text-align: center;
    color: #6c757d;
    background: #fbfdfb;
}

.smoothies-total-box {
    border-radius: 1rem;
    padding: 1rem;
    background: linear-gradient(135deg, #198754 0%, #289f65 100%);
    color: #fff;
}

.smoothies-sale-summary {
    border: 1px solid #bfdcc8;
    background: linear-gradient(135deg, #eef9f1 0%, #ffffff 100%);
}

.smoothies-qris-image {
    max-height: 260px;
}

.smoothies-selection-header {
    padding: 0.25rem 0;
}

.suggestion-list {
    max-height: 220px;
    overflow-y: auto;
}

@media (max-width: 767.98px) {
    .smoothies-pos-layout {
        grid-template-columns: 1fr;
    }

    .smoothies-product-grid,
    .smoothies-option-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .smoothies-cart-controls {
        align-items: stretch;
    }

    .action-group--four,
    .action-group--three,
    .action-group--two {
        grid-template-columns: 1fr;
    }
}

@media (max-width: 575.98px) {
    .smoothies-product-grid,
    .smoothies-option-grid {
        grid-template-columns: 1fr;
    }
}
</style>



