<template>
    <Head title="Penjualan Offline" />

    <div v-if="$page.props.errors.promo_id" class="alert alert-danger">{{ $page.props.errors.promo_id }}</div>
    <div v-if="$page.props.errors.quantity" class="alert alert-danger">{{ $page.props.errors.quantity }}</div>
    <div v-if="$page.props.errors.id_product" class="alert alert-danger">{{ $page.props.errors.id_product }}</div>

    <div class="row">
        <div class="col-lg-5">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Input Penjualan Offline</h3></div>
                <div class="card-body">
                    <div class="form-group">
                        <label>Product</label>
                        <Select2Input v-model="saleForm.id_product" :options="products" value-key="id_product" label-key="option_label" placeholder="Cari lalu pilih product" />
                    </div>
                    <div class="form-group"><label>Quantity</label><input v-model="saleForm.quantity" type="number" min="1" class="form-control"></div>
                    <div class="form-group">
                        <label>Promo</label>
                        <Select2Input v-model="saleForm.promo_id" :options="promos" value-key="id" label-key="option_label" placeholder="Pilih promo" />
                    </div>
                    <div v-if="selectedPromo" class="alert" :class="promoWarning ? 'alert-warning' : 'alert-info'">
                        <div><strong>Syarat Promo</strong></div>
                        <div>Minimal quantity: {{ selectedPromo.minimal_quantity }}</div>
                        <div>Minimal pembelian: {{ toCurrency(selectedPromo.minimal_belanja) }}</div>
                        <div v-if="promoWarning" class="mt-2">{{ promoWarning }}</div>
                    </div>
                    <div class="form-group">
                        <label>Harga</label>
                        <div class="form-control bg-white">
                            <span v-if="promoEligible && discountedPrice < basePrice"><del class="text-muted mr-2">{{ toCurrency(basePrice) }}</del></span>
                            <strong>{{ toCurrency(displayPrice) }}</strong>
                        </div>
                    </div>
                    <div class="form-group"><label>Bukti Pembelian</label><input type="file" class="form-control" accept="image/*" @input="saleForm.bukti_pembelian = $event.target.files[0]"></div>
                    <button class="btn btn-primary" :disabled="saleForm.processing || !selectedProduct || Boolean(promoWarning)" @click="submitSale">Simpan Penjualan</button>
                </div>
            </div>

            <div v-if="canManageAll && editForm.id_penjualan_offline" class="card card-outline card-warning">
                <div class="card-header"><h3 class="card-title">Edit Penjualan</h3></div>
                <div class="card-body">
                    <div class="form-group"><label>Nama Product</label><input :value="editForm.nama_product" type="text" class="form-control" disabled></div>
                    <div class="form-group"><label>Quantity</label><input v-model="editForm.quantity" type="number" min="1" class="form-control"></div>
                    <button class="btn btn-warning mr-2" @click="submitEdit">Update</button>
                    <button class="btn btn-secondary" @click="resetEdit">Batal</button>
                </div>
            </div>
        </div>

        <div class="col-lg-7">
            <div class="card card-outline card-success">
                <div class="card-header"><h3 class="card-title">Daftar Penjualan Offline</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Nama</th><th>Product</th><th>Qty</th><th>Harga</th><th>Promo</th><th>Status</th><th>Bukti</th><th>Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in sales" :key="item.id_penjualan_offline">
                                <td>{{ item.nama }}</td>
                                <td>{{ item.nama_product }}</td>
                                <td>{{ item.quantity }}</td>
                                <td>{{ toCurrency(item.harga) }}</td>
                                <td>{{ item.promo || '-' }}</td>
                                <td>{{ item.approval_status }}</td>
                                <td><a v-if="item.bukti_pembelian" :href="item.bukti_pembelian" target="_blank" rel="noreferrer">Lihat</a></td>
                                <td>
                                    <template v-if="canApprove && item.approval_status === 'pending'">
                                        <button class="btn btn-xs btn-success mr-1" @click="approve(item)">Setujui</button>
                                        <button class="btn btn-xs btn-danger mr-1" @click="reject(item)">Tolak</button>
                                    </template>
                                    <button v-if="canManageAll" class="btn btn-xs btn-warning mr-1" @click="pickEdit(item)">Edit</button>
                                    <button v-if="canManageAll" class="btn btn-xs btn-outline-danger" @click="removeSale(item)">Hapus</button>
                                </td>
                            </tr>
                            <tr v-if="!sales.length"><td colspan="8" class="text-center text-muted">Belum ada penjualan offline.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import Select2Input from '../../Components/Select2Input.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({ sales: Array, products: Array, promos: Array, canApprove: Boolean, canManageAll: Boolean, currentRole: String });
const saleForm = useForm({ id_product: '', quantity: 1, promo_id: '', bukti_pembelian: null });
const editForm = useForm({ id_penjualan_offline: null, nama_product: '', quantity: 1 });
const selectedProduct = computed(() => props.products.find((item) => Number(item.id_product) === Number(saleForm.id_product)) || null);
const selectedPromo = computed(() => props.promos.find((item) => Number(item.id) === Number(saleForm.promo_id)) || null);
const basePrice = computed(() => (selectedProduct.value ? selectedProduct.value.harga * Number(saleForm.quantity || 0) : 0));
const promoEligible = computed(() => {
    if (!selectedPromo.value) return false;
    if (Number(saleForm.quantity || 0) < selectedPromo.value.minimal_quantity) return false;
    if (basePrice.value < selectedPromo.value.minimal_belanja) return false;
    return true;
});
const discountedPrice = computed(() => promoEligible.value ? Math.max(basePrice.value - (selectedPromo.value?.potongan || 0), 0) : basePrice.value);
const displayPrice = computed(() => promoEligible.value ? discountedPrice.value : basePrice.value);
const promoWarning = computed(() => {
    if (!selectedPromo.value) return '';
    if (!promoEligible.value) return 'Pembelian belum mencapai syarat';
    return '';
});
const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value || 0);
const submitSale = () => saleForm.post('/offline-sales', { forceFormData: true, preserveScroll: true, onSuccess: () => saleForm.reset('id_product', 'quantity', 'promo_id', 'bukti_pembelian') });
const pickEdit = (item) => Object.assign(editForm, { id_penjualan_offline: item.id_penjualan_offline, nama_product: item.nama_product, quantity: item.quantity });
const submitEdit = () => editForm.put(`/offline-sales/${editForm.id_penjualan_offline}`, { preserveScroll: true, onSuccess: () => editForm.reset() });
const resetEdit = () => editForm.reset();
const approve = (item) => router.post(`/offline-sales/${item.id_penjualan_offline}/approve`, {}, { preserveScroll: true });
const reject = (item) => router.post(`/offline-sales/${item.id_penjualan_offline}/reject`, {}, { preserveScroll: true });
const removeSale = (item) => { if (window.confirm(`Hapus penjualan ${item.nama_product}?`)) router.delete(`/offline-sales/${item.id_penjualan_offline}`, { preserveScroll: true }); };
</script>
