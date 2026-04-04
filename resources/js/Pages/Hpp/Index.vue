<template>
    <AppLayout>
    <Head title="HPP" />

    <template #actions>
        <button type="button" class="btn btn-primary" @click="openCreateModal">
            <i class="fas fa-plus mr-1"></i>
            Tambah HPP
        </button>
    </template>

    <div class="row">
        <div class="col-lg-12">
            <div class="card card-outline card-success">
                <div class="card-header"><h3 class="card-title">Daftar HPP Product</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Product</th><th>Total HPP</th><th>Detail RM</th><th>Update</th><th class="action-column">Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in calculations" :key="item.id_hpp">
                                <td><button type="button" class="btn btn-link p-0 font-weight-bold text-left" @click="openEditModal(item)">{{ item.nama_product }}</button></td>
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
                                    <div class="action-group">
                                        <button class="btn btn-xs btn-warning" @click="openEditModal(item)"><i class="fas fa-pen mr-1"></i>Edit</button>
                                        <button class="btn btn-xs btn-danger" @click="removeCalculation(item)"><i class="fas fa-trash-alt mr-1"></i>Hapus</button>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="!calculations.length"><td colspan="5" class="text-center text-muted">Belum ada data HPP.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showFormModal" :title="form.id_product && formMode === 'edit' ? 'Edit HPP' : 'Tambah HPP'" size="xl" @close="closeFormModal">
        <div class="crud-modal-body">
            <div class="form-group mb-0">
                <label>Product</label>
                <Select2Input v-model="form.id_product" :options="products" value-key="id_product" label-key="option_label" placeholder="Pilih product" />
            </div>

            <div v-for="(item, index) in form.items" :key="item.key" class="border rounded p-3 bg-light">
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

            <div class="d-flex justify-content-end">
                <button type="button" class="btn btn-sm btn-outline-secondary" @click="addItem">Tambah RM</button>
            </div>

            <div class="alert alert-info mb-0">
                <div><strong>Harga Modal Product:</strong> {{ toCurrency(totalHpp) }}</div>
                <div><strong>Jumlah RM:</strong> {{ form.items.length }}</div>
            </div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeFormModal">Batal</button>
            <button type="button" class="btn btn-primary" :disabled="form.processing || !form.id_product" @click="submitForm">Simpan HPP</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        Hapus HPP untuk {{ deleteTarget?.nama_product }}?
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeDeleteModal">Batal</button>
            <button type="button" class="btn btn-danger" @click="confirmDelete">Hapus</button>
        </template>
    </BootstrapModal>

    </AppLayout>
</template>

<script setup>
import { computed, ref } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import Select2Input from '../../Components/Select2Input.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';
import { adminUrl } from '../../utils/admin';

const props = defineProps({ products: Array, rawMaterials: Array, calculations: Array });

const emptyItem = () => ({ key: `${Date.now()}-${Math.random()}`, id_rm: '', presentase: '' });
const form = useForm({ id_product: '', items: [emptyItem()] });
const formMode = ref('create');
const showFormModal = ref(false);
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
const resetForm = () => {
    form.reset();
    form.id_product = '';
    form.items = [emptyItem()];
    formMode.value = 'create';
};
const openCreateModal = () => {
    resetForm();
    showFormModal.value = true;
};
const openEditModal = (item) => {
    formMode.value = 'edit';
    form.id_product = item.id_product;
    form.items = item.items.map((detail) => ({ key: `${detail.id_rm}-${Math.random()}`, id_rm: String(detail.id_rm), presentase: detail.presentase }));
    showFormModal.value = true;
};
const closeFormModal = () => {
    showFormModal.value = false;
    resetForm();
};
const submitForm = () => form.post(adminUrl('/hpp'), { preserveScroll: true, onSuccess: () => closeFormModal() });
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
    router.delete(adminUrl(`/hpp/${id}`), { preserveScroll: true });
};
</script>

<style scoped>
.action-column {
    min-width: 170px;
}

.action-group {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 0.45rem;
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

@media (max-width: 575.98px) {
    .action-group {
        grid-template-columns: 1fr;
    }
}
</style>



