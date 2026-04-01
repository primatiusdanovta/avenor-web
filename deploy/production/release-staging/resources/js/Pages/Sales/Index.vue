<template>
    <Head title="Penjualan Offline" />

    <div v-if="$page.props.errors.promo_id" class="alert alert-danger">{{ $page.props.errors.promo_id }}</div>
    <div v-if="$page.props.errors.items" class="alert alert-danger">{{ $page.props.errors.items }}</div>
    <div v-if="$page.props.errors.customer_no_telp" class="alert alert-danger">{{ $page.props.errors.customer_no_telp }}</div>
    <div v-if="$page.props.errors.bukti_pembelian" class="alert alert-danger">{{ $page.props.errors.bukti_pembelian }}</div>
    <div v-if="$page.props.errors.created_at" class="alert alert-danger">{{ $page.props.errors.created_at }}</div>

    <div class="row">
        <div class="col-md-12 col-lg-5">
            <div class="card card-outline card-primary">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h3 class="card-title">Input Penjualan Offline</h3>
                    <button class="btn btn-sm btn-outline-secondary" @click="addItem(saleForm)">Tambah Product</button>
                </div>
                <div class="card-body">
                    <div v-if="canManageAll" class="form-group">
                        <label>Tanggal Transaksi</label>
                        <input v-model="saleForm.created_at" type="datetime-local" class="form-control">
                        <small class="text-muted">Admin dan superadmin bisa menentukan tanggal transaksi secara manual.</small>
                    </div>

                    <div class="border rounded p-3 mb-3 bg-light position-relative">
                        <div class="font-weight-bold mb-2">Data Pelanggan</div>
                        <div class="form-group"><label>Nama Pembeli</label><input v-model="saleForm.customer_nama" type="text" class="form-control"></div>
                        <div class="form-group mb-1">
                            <label>No Telp</label>
                            <input v-model="saleForm.customer_no_telp" type="text" class="form-control" placeholder="Ketik no telp untuk cari pelanggan">
                        </div>
                        <div v-if="filteredCreateCustomers.length" class="list-group mb-3" style="max-height: 220px; overflow-y: auto;">
                            <button v-for="customer in filteredCreateCustomers" :key="customer.id_pelanggan" type="button" class="list-group-item list-group-item-action" @click="pickCustomerSuggestion(saleForm, customer)">
                                <div class="font-weight-bold">{{ customer.nama || 'Tanpa nama' }}</div>
                                <div class="small text-muted">{{ customer.no_telp || '-' }}<span v-if="customer.tiktok_instagram"> | {{ customer.tiktok_instagram }}</span></div>
                            </button>
                        </div>
                        <div class="form-group mb-0"><label>Tiktok / Instagram</label><input v-model="saleForm.customer_tiktok_instagram" type="text" class="form-control"></div>
                    </div>

                    <div v-for="(item, index) in saleForm.items" :key="item.key" class="border rounded p-3 mb-3 bg-light">
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <strong>Product {{ index + 1 }}</strong>
                            <button v-if="saleForm.items.length > 1" class="btn btn-xs btn-outline-danger" @click="removeItem(saleForm, index)">Hapus</button>
                        </div>
                        <div class="form-group mb-2">
                            <label>Product</label>
                            <Select2Input v-model="item.id_product" :options="products" value-key="id_product" label-key="option_label" placeholder="Cari lalu pilih product" />
                        </div>
                        <div class="form-group mb-2"><label>Quantity</label><input v-model="item.quantity" type="number" min="1" class="form-control"></div>
                        <div class="small text-muted">Harga Satuan: {{ toCurrency(itemState(item).hargaSatuan) }}</div>
                        <div class="small text-muted">Line Total: {{ toCurrency(itemState(item).lineTotal) }}</div>
                    </div>

                    <div class="form-group">
                        <label>Promo</label>
                        <Select2Input v-model="saleForm.promo_id" :options="promos" value-key="id" label-key="option_label" placeholder="Pilih promo" />
                    </div>
                    <div v-if="selectedCreatePromo" class="alert" :class="createPromoWarning ? 'alert-warning' : 'alert-info'">
                        <div><strong>Syarat Promo</strong></div>
                        <div>Minimal quantity: {{ selectedCreatePromo.minimal_quantity }}</div>
                        <div>Minimal pembelian: {{ toCurrency(selectedCreatePromo.minimal_belanja) }}</div>
                        <div v-if="createPromoWarning" class="mt-2">{{ createPromoWarning }}</div>
                    </div>
                    <div class="form-group">
                        <label>Total Harga</label>
                        <div class="form-control bg-white">
                            <span v-if="createPromoEligible && createDiscountedPrice < createBasePrice"><del class="text-muted mr-2">{{ toCurrency(createBasePrice) }}</del></span>
                            <strong>{{ toCurrency(createDisplayPrice) }}</strong>
                        </div>
                    </div>
                    <div class="form-group"><label>Bukti Pembelian</label><input type="file" class="form-control" accept="image/*" @input="saleForm.bukti_pembelian = $event.target.files[0]"></div>
                    <button class="btn btn-primary" style="margin-top: 10px;" :disabled="saleForm.processing || !hasValidItems(saleForm) || Boolean(createPromoWarning)" @click="submitSale">Simpan Penjualan</button>
                </div>
            </div>

            <div v-if="canManageAll && editForm.id_penjualan_offline" class="card card-outline card-warning">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h3 class="card-title">Edit Transaksi</h3>
                    <button class="btn btn-sm btn-outline-secondary" @click="addItem(editForm)">Tambah Product</button>
                </div>
                <div class="card-body">
                    <div class="form-group">
                        <label>Tanggal Transaksi</label>
                        <input v-model="editForm.created_at" type="datetime-local" class="form-control">
                    </div>

                    <div class="border rounded p-3 mb-3 bg-light position-relative">
                        <div class="font-weight-bold mb-2">Data Pelanggan</div>
                        <div class="form-group"><label>Nama Pembeli</label><input v-model="editForm.customer_nama" type="text" class="form-control"></div>
                        <div class="form-group mb-1">
                            <label>No Telp</label>
                            <input v-model="editForm.customer_no_telp" type="text" class="form-control" placeholder="Ketik no telp untuk cari pelanggan">
                        </div>
                        <div v-if="filteredEditCustomers.length" class="list-group mb-3" style="max-height: 220px; overflow-y: auto;">
                            <button v-for="customer in filteredEditCustomers" :key="customer.id_pelanggan" type="button" class="list-group-item list-group-item-action" @click="pickCustomerSuggestion(editForm, customer)">
                                <div class="font-weight-bold">{{ customer.nama || 'Tanpa nama' }}</div>
                                <div class="small text-muted">{{ customer.no_telp || '-' }}<span v-if="customer.tiktok_instagram"> | {{ customer.tiktok_instagram }}</span></div>
                            </button>
                        </div>
                        <div class="form-group mb-0"><label>Tiktok / Instagram</label><input v-model="editForm.customer_tiktok_instagram" type="text" class="form-control"></div>
                    </div>

                    <div v-for="(item, index) in editForm.items" :key="item.key" class="border rounded p-3 mb-3 bg-light">
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <strong>Product {{ index + 1 }}</strong>
                            <button v-if="editForm.items.length > 1" class="btn btn-xs btn-outline-danger" @click="removeItem(editForm, index)">Hapus</button>
                        </div>
                        <div class="form-group mb-2">
                            <label>Product</label>
                            <Select2Input v-model="item.id_product" :options="products" value-key="id_product" label-key="option_label" placeholder="Cari lalu pilih product" />
                        </div>
                        <div class="form-group mb-2"><label>Quantity</label><input v-model="item.quantity" type="number" min="1" class="form-control"></div>
                        <div class="small text-muted">Harga Satuan: {{ toCurrency(itemState(item).hargaSatuan) }}</div>
                        <div class="small text-muted">Line Total: {{ toCurrency(itemState(item).lineTotal) }}</div>
                    </div>

                    <div class="form-group">
                        <label>Promo</label>
                        <Select2Input v-model="editForm.promo_id" :options="promos" value-key="id" label-key="option_label" placeholder="Pilih promo" />
                    </div>
                    <div v-if="selectedEditPromo" class="alert" :class="editPromoWarning ? 'alert-warning' : 'alert-info'">
                        <div><strong>Syarat Promo</strong></div>
                        <div>Minimal quantity: {{ selectedEditPromo.minimal_quantity }}</div>
                        <div>Minimal pembelian: {{ toCurrency(selectedEditPromo.minimal_belanja) }}</div>
                        <div v-if="editPromoWarning" class="mt-2">{{ editPromoWarning }}</div>
                    </div>
                    <div class="form-group">
                        <label>Total Harga</label>
                        <div class="form-control bg-white">
                            <span v-if="editPromoEligible && editDiscountedPrice < editBasePrice"><del class="text-muted mr-2">{{ toCurrency(editBasePrice) }}</del></span>
                            <strong>{{ toCurrency(editDisplayPrice) }}</strong>
                        </div>
                    </div>
                    <button class="btn btn-warning mr-2" :disabled="editForm.processing || !hasValidItems(editForm) || Boolean(editPromoWarning)" @click="submitEdit">Update</button>
                    <button class="btn btn-secondary" @click="resetEdit">Batal</button>
                </div>
            </div>
        </div>

        <div class="col-md-12 col-lg-7">
            <div class="card card-outline card-success">
                <div class="card-header"><h3 class="card-title">Daftar Penjualan Offline</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Transaksi</th><th>Pelanggan</th><th>Item</th><th>Total Qty</th><th>Total Harga</th><th>Promo</th><th>Status</th><th>Bukti</th><th>Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in sales" :key="item.transaction_code || item.id_penjualan_offline">
                                <td>
                                    <div>{{ item.nama_penjual }}</div>
                                    <div class="small text-muted">{{ item.created_at }}</div>
                                    <div class="small text-muted">{{ item.transaction_code || '-' }}</div>
                                </td>
                                <td>
                                    <div>{{ item.nama_customer || '-' }}</div>
                                    <div class="small text-muted">{{ item.no_telp || '-' }}</div>
                                    <div class="small text-muted">{{ item.tiktok_instagram || '-' }}</div>
                                </td>
                                <td>
                                    <div v-for="detail in item.items" :key="detail.id_penjualan_offline" class="text-sm">
                                        {{ detail.nama_product }} x {{ detail.quantity }}
                                    </div>
                                </td>
                                <td>{{ item.total_quantity }}</td>
                                <td>{{ toCurrency(item.total_harga) }}</td>
                                <td>{{ item.promo || '-' }}</td>
                                <td>{{ item.approval_status }}</td>
                                <td>
                                    <button v-if="item.bukti_pembelian" type="button" class="btn btn-link btn-sm p-0" @click="openProof(item.bukti_pembelian)">Lihat</button>
                                    <span v-else>-</span>
                                </td>
                                <td>
                                    <template v-if="canApprove && item.approval_status === 'pending'">
                                        <button class="btn btn-xs btn-success mr-1" @click="approve(item)">Setujui</button>
                                        <button class="btn btn-xs btn-danger mr-1" @click="reject(item)">Tolak</button>
                                    </template>
                                    <button v-if="canManageAll" class="btn btn-xs btn-warning mr-1" @click="pickEdit(item)">Edit</button>
                                    <button v-if="canManageAll" class="btn btn-xs btn-outline-danger" @click="removeSale(item)">Hapus</button>
                                </td>
                            </tr>
                            <tr v-if="!sales.length"><td colspan="9" class="text-center text-muted">Belum ada penjualan offline.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

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
</template>

<script setup>
import { computed, ref } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import Select2Input from '../../Components/Select2Input.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({ sales: Array, products: Array, promos: Array, customers: Array, canApprove: Boolean, canManageAll: Boolean, currentRole: String, defaultCreatedAt: String });

const emptySaleItem = () => ({ key: `${Date.now()}-${Math.random()}`, id_product: '', quantity: 1 });
const defaultCreatedAt = props.defaultCreatedAt || new Date().toISOString().slice(0, 16);
const makeTransactionForm = (defaults = {}) => useForm({
    id_penjualan_offline: defaults.id_penjualan_offline ?? null,
    customer_nama: defaults.customer_nama ?? '',
    customer_no_telp: defaults.customer_no_telp ?? '',
    customer_tiktok_instagram: defaults.customer_tiktok_instagram ?? '',
    items: defaults.items ?? [emptySaleItem()],
    promo_id: defaults.promo_id ?? '',
    created_at: defaults.created_at ?? defaultCreatedAt,
    bukti_pembelian: defaults.bukti_pembelian ?? null,
});

const saleForm = makeTransactionForm();
const editForm = makeTransactionForm();
const proofUrl = ref('');
const showProofModal = ref(false);
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const deleteMessage = ref('');
const productMap = computed(() => Object.fromEntries(props.products.map((item) => [String(item.id_product), item])));
const promoById = (promoId) => props.promos.find((item) => Number(item.id) === Number(promoId)) || null;
const itemState = (item) => {
    const product = productMap.value[String(item.id_product)] ?? null;
    const hargaSatuan = Number(product?.harga || 0);
    const quantity = Number(item.quantity || 0);
    return {
        hargaSatuan,
        lineTotal: hargaSatuan * quantity,
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
const createBasePrice = computed(() => basePriceFor(saleForm));
const editBasePrice = computed(() => basePriceFor(editForm));
const createPromoEligible = computed(() => promoEligibleFor(saleForm));
const editPromoEligible = computed(() => promoEligibleFor(editForm));
const createDiscountedPrice = computed(() => displayPriceFor(saleForm));
const editDiscountedPrice = computed(() => displayPriceFor(editForm));
const createDisplayPrice = computed(() => displayPriceFor(saleForm));
const editDisplayPrice = computed(() => displayPriceFor(editForm));
const createPromoWarning = computed(() => promoWarningFor(saleForm));
const editPromoWarning = computed(() => promoWarningFor(editForm));
const filteredCustomersFor = (phone) => {
    const keyword = String(phone || '').trim();
    if (!keyword) return [];
    return props.customers.filter((item) => String(item.no_telp || '').includes(keyword)).slice(0, 6);
};
const filteredCreateCustomers = computed(() => filteredCustomersFor(saleForm.customer_no_telp));
const filteredEditCustomers = computed(() => filteredCustomersFor(editForm.customer_no_telp));
const hasValidItems = (form) => form.items.length > 0 && form.items.every((item) => item.id_product && Number(item.quantity || 0) > 0);
const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value || 0);
const addItem = (form) => form.items.push(emptySaleItem());
const removeItem = (form, index) => form.items.splice(index, 1);
const pickCustomerSuggestion = (form, customer) => {
    form.customer_nama = customer.nama || '';
    form.customer_no_telp = customer.no_telp || '';
    form.customer_tiktok_instagram = customer.tiktok_instagram || '';
};
const resetSaleForm = () => {
    saleForm.reset('id_penjualan_offline', 'customer_nama', 'customer_no_telp', 'customer_tiktok_instagram', 'promo_id', 'bukti_pembelian');
    saleForm.created_at = defaultCreatedAt;
    saleForm.items = [emptySaleItem()];
};
const submitSale = () => saleForm.post('/offline-sales', { forceFormData: true, preserveScroll: true, onSuccess: resetSaleForm });
const pickEdit = (item) => {
    editForm.id_penjualan_offline = item.id_penjualan_offline;
    editForm.customer_nama = item.nama_customer || '';
    editForm.customer_no_telp = item.no_telp || '';
    editForm.customer_tiktok_instagram = item.tiktok_instagram || '';
    editForm.promo_id = item.promo_id ? String(item.promo_id) : '';
    editForm.created_at = item.created_at_form || defaultCreatedAt;
    editForm.items = item.items.map((detail) => ({ key: `${detail.id_product}-${Math.random()}`, id_product: String(detail.id_product), quantity: detail.quantity }));
};
const submitEdit = () => editForm.put(`/offline-sales/${editForm.id_penjualan_offline}`, { preserveScroll: true, onSuccess: () => resetEdit() });
const resetEdit = () => {
    editForm.reset('id_penjualan_offline', 'customer_nama', 'customer_no_telp', 'customer_tiktok_instagram', 'promo_id', 'bukti_pembelian');
    editForm.created_at = defaultCreatedAt;
    editForm.items = [emptySaleItem()];
};
const approve = (item) => router.post(`/offline-sales/${item.id_penjualan_offline}/approve`, {}, { preserveScroll: true });
const reject = (item) => router.post(`/offline-sales/${item.id_penjualan_offline}/reject`, {}, { preserveScroll: true });
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
    router.delete(`/offline-sales/${id}`, { preserveScroll: true });
};
const openProof = (url) => {
    proofUrl.value = url;
    showProofModal.value = true;
};
</script>
