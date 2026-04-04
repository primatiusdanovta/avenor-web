<template>
    <AppLayout>
    <Head title="Raw Material" />

    <template #actions>
        <div class="d-flex flex-wrap justify-content-end gap-2">
            <button type="button" class="btn btn-info" @click="openRestockModal">
                <i class="fas fa-boxes mr-1"></i>
                Tambah Stock
            </button>
            <button type="button" class="btn btn-primary" @click="openCreateModal">
                <i class="fas fa-plus mr-1"></i>
                Tambah Raw Material
            </button>
        </div>
    </template>

    <div class="row">
        <div class="col-lg-12">
            <div class="card card-outline card-success">
                <div class="card-header"><h3 class="card-title">Daftar Raw Material</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Nama</th><th>Satuan</th><th>Harga Pack</th><th>Harga Total</th><th>Qty/Pack</th><th>Harga Satuan</th><th>Stock Pack</th><th>Total Quantity</th><th>Dibuat</th><th class="action-column">Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in materials" :key="item.id_rm">
                                <td><button type="button" class="btn btn-link p-0 font-weight-bold text-left" @click="openEditModal(item)">{{ item.nama_rm }}</button></td>
                                <td>{{ item.satuan }}</td>
                                <td>{{ toCurrency(item.harga) }}</td>
                                <td>{{ toCurrency(item.harga_total) }}</td>
                                <td>{{ formatNumber(item.quantity) }}</td>
                                <td>{{ toCurrency(item.harga_satuan) }} / {{ item.satuan }}</td>
                                <td>{{ formatNumber(item.stock) }}</td>
                                <td>{{ formatNumber(item.total_quantity) }} / {{ item.satuan }}</td>
                                <td>{{ item.created_at }}</td>
                                <td>
                                    <div class="action-group">
                                        <button class="btn btn-xs btn-warning" @click="openEditModal(item)"><i class="fas fa-pen mr-1"></i>Edit</button>
                                        <button class="btn btn-xs btn-danger" @click="removeMaterial(item)"><i class="fas fa-trash-alt mr-1"></i>Hapus</button>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="!materials.length"><td colspan="10" class="text-center text-muted">Belum ada raw material.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showCreateModal" title="Tambah Raw Material" size="lg" @close="closeCreateModal">
        <div class="crud-modal-body">
            <div v-if="createErrorMessages.length" class="alert alert-danger mb-0">
                <div v-for="message in createErrorMessages" :key="`create-rm-${message}`">{{ message }}</div>
            </div>
            <div class="form-group mb-0"><label>Nama</label><input v-model="createForm.nama_rm" type="text" class="form-control" placeholder="Nama raw material" :class="{ 'is-invalid': createForm.errors.nama_rm }"><div v-if="createForm.errors.nama_rm" class="invalid-feedback d-block">{{ createForm.errors.nama_rm }}</div></div>
            <div class="form-group mb-0"><label>Harga per Pack</label><input v-model="createForm.harga" type="number" min="0" step="0.01" class="form-control" placeholder="0" :class="{ 'is-invalid': createForm.errors.harga }"><div v-if="createForm.errors.harga" class="invalid-feedback d-block">{{ createForm.errors.harga }}</div></div>
            <div class="form-group mb-0"><label>Quantity per Pack</label><input v-model="createForm.quantity" type="number" min="0.01" step="0.01" class="form-control" placeholder="0" :class="{ 'is-invalid': createForm.errors.quantity }"><div v-if="createForm.errors.quantity" class="invalid-feedback d-block">{{ createForm.errors.quantity }}</div></div>
            <div class="form-group mb-0"><label>Satuan</label><Select2Input v-model="createForm.satuan" :options="satuanOptions" placeholder="Pilih satuan" /><div v-if="createForm.errors.satuan" class="text-danger small mt-1">{{ createForm.errors.satuan }}</div></div>
            <div class="form-group mb-0"><label>Stock Pack</label><input v-model="createForm.stock" type="number" min="0" step="0.01" class="form-control" placeholder="0" :class="{ 'is-invalid': createForm.errors.stock }"><div v-if="createForm.errors.stock" class="invalid-feedback d-block">{{ createForm.errors.stock }}</div></div>
            <div class="alert alert-info mb-0">
                <div><strong>Harga Total:</strong> {{ toCurrency(createPreview.hargaTotal) }}</div>
                <div><strong>Harga Satuan:</strong> {{ toCurrency(createPreview.hargaSatuan) }}</div>
                <div><strong>Stock Pack:</strong> {{ formatNumber(createForm.stock) }}</div>
                <div><strong>Total Quantity:</strong> {{ formatNumber(createPreview.totalQuantity) }} {{ createPreview.satuan }}</div>
            </div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeCreateModal">Batal</button>
            <button type="button" class="btn btn-primary" :disabled="createForm.processing" @click="submitCreate">Simpan Raw Material</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showRestockModal" title="Tambah Stock Raw Material" size="lg" @close="closeRestockModal">
        <div class="crud-modal-body">
            <div v-if="restockErrorMessages.length" class="alert alert-danger mb-0">
                <div v-for="message in restockErrorMessages" :key="`restock-rm-${message}`">{{ message }}</div>
            </div>
            <div class="form-group mb-0"><label>Raw Material</label><Select2Input v-model="restockForm.id_rm" :options="materials" value-key="id_rm" label-key="option_label" placeholder="Pilih raw material" /><div v-if="restockForm.errors.id_rm" class="text-danger small mt-1">{{ restockForm.errors.id_rm }}</div></div>
            <div class="form-group mb-0"><label>Stock Pack Ditambahkan</label><input v-model="restockForm.stock" type="number" min="0.01" step="0.01" class="form-control" placeholder="0" :class="{ 'is-invalid': restockForm.errors.stock }"><div v-if="restockForm.errors.stock" class="invalid-feedback d-block">{{ restockForm.errors.stock }}</div></div>
            <div class="alert alert-info mb-0" v-if="selectedRestockMaterial">
                <div><strong>Nama:</strong> {{ selectedRestockMaterial.nama_rm }}</div>
                <div><strong>Stock Sekarang:</strong> {{ formatNumber(selectedRestockMaterial.stock) }}</div>
                <div><strong>Total Quantity Baru:</strong> {{ formatNumber(restockPreview) }} {{ selectedRestockMaterial.satuan }}</div>
            </div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeRestockModal">Batal</button>
            <button type="button" class="btn btn-info" :disabled="restockForm.processing || !restockForm.id_rm" @click="submitRestock">Tambah Stock</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showEditModal" title="Edit Raw Material" size="lg" @close="closeEditModal">
        <div class="crud-modal-body">
            <div v-if="editErrorMessages.length" class="alert alert-danger mb-0">
                <div v-for="message in editErrorMessages" :key="`edit-rm-${message}`">{{ message }}</div>
            </div>
            <div class="form-group mb-0"><label>Nama</label><input v-model="editForm.nama_rm" type="text" class="form-control" :class="{ 'is-invalid': editForm.errors.nama_rm }"><div v-if="editForm.errors.nama_rm" class="invalid-feedback d-block">{{ editForm.errors.nama_rm }}</div></div>
            <div class="form-group mb-0"><label>Harga per Pack</label><input v-model="editForm.harga" type="number" min="0" step="0.01" class="form-control" :class="{ 'is-invalid': editForm.errors.harga }"><div v-if="editForm.errors.harga" class="invalid-feedback d-block">{{ editForm.errors.harga }}</div></div>
            <div class="form-group mb-0"><label>Quantity per Pack</label><input v-model="editForm.quantity" type="number" min="0.01" step="0.01" class="form-control" :class="{ 'is-invalid': editForm.errors.quantity }"><div v-if="editForm.errors.quantity" class="invalid-feedback d-block">{{ editForm.errors.quantity }}</div></div>
            <div class="form-group mb-0"><label>Satuan</label><Select2Input v-model="editForm.satuan" :options="satuanOptions" placeholder="Pilih satuan" /><div v-if="editForm.errors.satuan" class="text-danger small mt-1">{{ editForm.errors.satuan }}</div></div>
            <div class="form-group mb-0"><label>Stock Pack</label><input v-model="editForm.stock" type="number" min="0" step="0.01" class="form-control" :class="{ 'is-invalid': editForm.errors.stock }"><div v-if="editForm.errors.stock" class="invalid-feedback d-block">{{ editForm.errors.stock }}</div></div>
            <div class="alert alert-warning mb-0">
                <div><strong>Harga Total:</strong> {{ toCurrency(editPreview.hargaTotal) }}</div>
                <div><strong>Harga Satuan:</strong> {{ toCurrency(editPreview.hargaSatuan) }}</div>
                <div><strong>Stock Pack:</strong> {{ formatNumber(editForm.stock) }}</div>
                <div><strong>Total Quantity:</strong> {{ formatNumber(editPreview.totalQuantity) }} {{ editPreview.satuan }}</div>
            </div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeEditModal">Batal</button>
            <button type="button" class="btn btn-warning" :disabled="editForm.processing || !editForm.id_rm" @click="submitEdit">Update Raw Material</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        Hapus raw material {{ deleteTarget?.nama_rm }}?
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

const props = defineProps({ materials: Array });
const satuanOptions = ['pcs', 'ML'];
const createForm = useForm({ nama_rm: '', harga: '', quantity: 1, satuan: '', stock: 0 });
const editForm = useForm({ id_rm: null, nama_rm: '', harga: '', quantity: 1, satuan: '', stock: 0 });
const restockForm = useForm({ id_rm: '', stock: 0 });
const showCreateModal = ref(false);
const showEditModal = ref(false);
const showRestockModal = ref(false);
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const createErrorMessages = computed(() => Object.values(createForm.errors || {}));
const editErrorMessages = computed(() => Object.values(editForm.errors || {}));
const restockErrorMessages = computed(() => Object.values(restockForm.errors || {}));

const previewFor = (form) => computed(() => {
    const harga = Number(form.harga || 0);
    const quantity = Number(form.quantity || 0);
    const stock = Number(form.stock || 0);

    return {
        hargaSatuan: quantity > 0 ? harga / quantity : 0,
        hargaTotal: stock * harga,
        totalQuantity: stock * quantity,
        satuan: form.satuan || '-',
    };
});

const createPreview = previewFor(createForm);
const editPreview = previewFor(editForm);
const selectedRestockMaterial = computed(() => props.materials.find((item) => Number(item.id_rm) === Number(restockForm.id_rm)) || null);
const restockPreview = computed(() => {
    if (!selectedRestockMaterial.value) return 0;
    return Number(selectedRestockMaterial.value.total_quantity || 0) + (Number(restockForm.stock || 0) * Number(selectedRestockMaterial.value.quantity || 0));
});

const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 2 }).format(value || 0);
const formatNumber = (value) => new Intl.NumberFormat('id-ID', { maximumFractionDigits: 2 }).format(Number(value || 0));

const openCreateModal = () => {
    createForm.reset();
    showCreateModal.value = true;
};
const closeCreateModal = () => {
    showCreateModal.value = false;
    createForm.reset();
};
const openRestockModal = () => {
    restockForm.reset();
    showRestockModal.value = true;
};
const closeRestockModal = () => {
    showRestockModal.value = false;
    restockForm.reset();
};
const openEditModal = (item) => {
    Object.assign(editForm, {
        id_rm: item.id_rm,
        nama_rm: item.nama_rm,
        harga: item.harga,
        quantity: item.quantity,
        satuan: item.satuan,
        stock: item.stock,
    });
    showEditModal.value = true;
};
const closeEditModal = () => {
    showEditModal.value = false;
    editForm.reset();
    editForm.id_rm = null;
};
const submitCreate = () => createForm.post(adminUrl('/raw-materials'), { preserveScroll: true, onSuccess: () => closeCreateModal() });
const submitRestock = () => restockForm.post(adminUrl('/raw-materials/restock'), { preserveScroll: true, onSuccess: () => closeRestockModal() });
const submitEdit = () => editForm.put(adminUrl(`/raw-materials/${editForm.id_rm}`), { preserveScroll: true, onSuccess: () => closeEditModal() });
const removeMaterial = (item) => {
    deleteTarget.value = item;
    showDeleteModal.value = true;
};
const closeDeleteModal = () => {
    showDeleteModal.value = false;
    deleteTarget.value = null;
};
const confirmDelete = () => {
    if (!deleteTarget.value) return;
    const id = deleteTarget.value.id_rm;
    closeDeleteModal();
    router.delete(adminUrl(`/raw-materials/${id}`), { preserveScroll: true });
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



