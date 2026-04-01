<template>
    <Head title="HPP" />

    <div class="row">
        <div class="col-md-12 col-lg-5">
            <div class="card card-outline card-primary">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h3 class="card-title">Perhitungan HPP</h3>
                    <button class="btn btn-sm btn-outline-secondary" @click="addItem">Tambah RM</button>
                </div>
                <div class="card-body">
                    <div class="form-group">
                        <label>Product</label>
                        <Select2Input v-model="form.id_product" :options="products" value-key="id_product" label-key="option_label" placeholder="Pilih product" />
                    </div>

                    <div v-for="(item, index) in form.items" :key="item.key" class="border rounded p-3 mb-3 bg-light">
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <strong>Raw Material {{ index + 1 }}</strong>
                            <button v-if="form.items.length > 1" class="btn btn-xs btn-outline-danger" @click="removeItem(index)">Hapus</button>
                        </div>
                        <div class="form-group mb-2">
                            <label>Raw Material</label>
                            <Select2Input v-model="item.id_rm" :options="rawMaterials" value-key="id_rm" label-key="option_label" placeholder="Pilih raw material" />
                        </div>
                        <div class="form-group mb-2">
                            <label>{{ itemLabel(item) }}</label>
                            <input v-model="item.presentase" type="number" min="0.01" step="0.01" class="form-control">
                        </div>
                        <div class="small text-muted">Harga Satuan: {{ toCurrency(itemState(item).hargaSatuan) }} / {{ itemState(item).satuan }}</div>
                        <div class="small text-muted">Pemakaian per Product: {{ formatNumber(itemState(item).usageQuantity) }} {{ itemState(item).satuan }}</div>
                        <div class="small text-muted">Total Stock RM: {{ formatNumber(itemState(item).totalStock) }} {{ itemState(item).satuan }}</div>
                        <div class="small text-muted">Harga Final: {{ toCurrency(itemState(item).hargaFinal) }}</div>
                    </div>

                    <div class="alert alert-info mb-0">
                        <div><strong>Harga Modal Product:</strong> {{ toCurrency(totalHpp) }}</div>
                        <div><strong>Jumlah RM:</strong> {{ form.items.length }}</div>
                    </div>

                    <button class="btn btn-primary mt-3" :disabled="form.processing || !form.id_product" @click="submitForm">Simpan HPP</button>
                </div>
            </div>
        </div>

        <div class="col-md-12 col-lg-7">
            <div class="card card-outline card-success">
                <div class="card-header"><h3 class="card-title">Daftar HPP Product</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Product</th><th>Total HPP</th><th>Detail RM</th><th>Update</th><th>Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in calculations" :key="item.id_hpp">
                                <td>{{ item.nama_product }}</td>
                                <td>{{ toCurrency(item.total_hpp) }}</td>
                                <td>
                                    <div v-for="detail in item.items" :key="`${item.id_hpp}-${detail.id_rm}`" class="text-sm">
                                        {{ detail.nama_rm }} - {{ detail.satuan === 'ML' ? `${detail.presentase}%` : `${formatNumber(detail.presentase)} pcs` }}
                                        | pakai {{ formatNumber(detail.usage_quantity) }} {{ detail.satuan }}
                                        | stock {{ formatNumber(detail.total_stock) }} {{ detail.satuan }}
                                        | {{ toCurrency(detail.harga_final) }}
                                    </div>
                                </td>
                                <td>{{ item.updated_at }}</td>
                                <td>
                                    <button class="btn btn-xs btn-warning mr-1" @click="pickEdit(item)">Edit</button>
                                    <button class="btn btn-xs btn-danger" @click="removeCalculation(item)">Hapus</button>
                                </td>
                            </tr>
                            <tr v-if="!calculations.length"><td colspan="5" class="text-center text-muted">Belum ada data HPP.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        Hapus HPP untuk {{ deleteTarget?.nama_product }}?
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeDeleteModal">Batal</button>
            <button type="button" class="btn btn-danger" @click="confirmDelete">Hapus</button>
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

const props = defineProps({ products: Array, rawMaterials: Array, calculations: Array });

const emptyItem = () => ({ key: `${Date.now()}-${Math.random()}`, id_rm: '', presentase: '' });
const form = useForm({ id_product: '', items: [emptyItem()] });
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const rawMaterialMap = computed(() => Object.fromEntries(props.rawMaterials.map((item) => [String(item.id_rm), item])));

const itemState = (item) => {
    const rawMaterial = rawMaterialMap.value[String(item.id_rm)] ?? null;
    const hargaSatuan = Number(rawMaterial?.harga_satuan || 0);
    const inputValue = Number(item.presentase || 0);
    const isMl = String(rawMaterial?.satuan || '').trim().toUpperCase() === 'ML';
    const usageQuantity = isMl ? ((inputValue / 100) * 50) : inputValue;
    return {
        satuan: rawMaterial?.satuan || '-',
        hargaSatuan,
        usageQuantity,
        totalStock: Number(rawMaterial?.total_quantity || 0),
        hargaFinal: usageQuantity * hargaSatuan,
    };
};

const itemLabel = (item) => {
    const satuan = String(rawMaterialMap.value[String(item.id_rm)]?.satuan || '').trim().toUpperCase();
    return satuan === 'ML' ? 'Presentase (%)' : 'Pemakaian (pcs)';
};
const totalHpp = computed(() => form.items.reduce((total, item) => total + itemState(item).hargaFinal, 0));
const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 2 }).format(value || 0);
const formatNumber = (value) => new Intl.NumberFormat('id-ID', { maximumFractionDigits: 2 }).format(Number(value || 0));
const addItem = () => form.items.push(emptyItem());
const removeItem = (index) => form.items.splice(index, 1);
const submitForm = () => form.post('/hpp', { preserveScroll: true, onSuccess: () => { form.reset(); form.items = [emptyItem()]; } });
const pickEdit = (item) => {
    form.id_product = item.id_product;
    form.items = item.items.map((detail) => ({ key: `${detail.id_rm}-${Math.random()}`, id_rm: String(detail.id_rm), presentase: detail.presentase }));
};
const removeCalculation = (item) => {
    deleteTarget.value = item;
    showDeleteModal.value = true;
};
const closeDeleteModal = () => {
    showDeleteModal.value = false;
    deleteTarget.value = null;
};
const confirmDelete = () => {
    if (!deleteTarget.value) return;
    const id = deleteTarget.value.id_hpp;
    closeDeleteModal();
    router.delete(`/hpp/${id}`, { preserveScroll: true });
};
</script>




