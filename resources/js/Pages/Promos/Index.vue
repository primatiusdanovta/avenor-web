<template>
    <AppLayout>
    <Head title="Promos" />

    <template #actions>
        <button type="button" class="btn btn-primary" @click="openCreateModal">
            <i class="fas fa-plus mr-1"></i>
            Tambah Promo
        </button>
    </template>

    <div class="row">
        <div class="col-lg-12">
            <div class="card card-outline card-success">
                <div class="card-header"><h3 class="card-title mb-0">Daftar Promo</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Kode</th><th>Nama</th><th>Potongan</th><th>Masa Aktif</th><th>Min Qty</th><th>Min Belanja</th><th>Status</th><th class="action-column">Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in promos" :key="item.id">
                                <td>{{ item.kode_promo }}</td>
                                <td><button type="button" class="btn btn-link p-0 font-weight-bold text-left" @click="openEditModal(item)">{{ item.nama_promo }}</button></td>
                                <td>{{ toCurrency(item.potongan) }}</td>
                                <td>{{ item.masa_aktif }}</td>
                                <td>{{ item.minimal_quantity }}</td>
                                <td>{{ toCurrency(item.minimal_belanja) }}</td>
                                <td>{{ item.is_active ? 'aktif' : 'expired' }}</td>
                                <td>
                                    <div class="action-group">
                                        <button class="btn btn-xs btn-warning" @click="openEditModal(item)"><i class="fas fa-pen mr-1"></i>Edit</button>
                                        <button class="btn btn-xs btn-danger" @click="removePromo(item)"><i class="fas fa-trash-alt mr-1"></i>Hapus</button>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="!promos.length"><td colspan="8" class="text-center text-muted">Belum ada promo.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showCreateModal" title="Tambah Promo" size="lg" @close="closeCreateModal">
        <div class="crud-modal-body">
            <div v-if="createErrorMessages.length" class="alert alert-danger mb-0">
                <div v-for="message in createErrorMessages" :key="`create-${message}`">{{ message }}</div>
            </div>
            <div class="form-group mb-0"><label>Nama Promo</label><input v-model="createForm.nama_promo" type="text" class="form-control" :class="{ 'is-invalid': createForm.errors.nama_promo }"><div v-if="createForm.errors.nama_promo" class="invalid-feedback d-block">{{ createForm.errors.nama_promo }}</div></div>
            <div class="form-group mb-0"><label>Potongan</label><input v-model="createForm.potongan" type="number" min="0" class="form-control" :class="{ 'is-invalid': createForm.errors.potongan }"><div v-if="createForm.errors.potongan" class="invalid-feedback d-block">{{ createForm.errors.potongan }}</div></div>
            <div class="form-group mb-0"><label>Masa Aktif</label><input v-model="createForm.masa_aktif" type="date" class="form-control" :class="{ 'is-invalid': createForm.errors.masa_aktif }"><div v-if="createForm.errors.masa_aktif" class="invalid-feedback d-block">{{ createForm.errors.masa_aktif }}</div></div>
            <div class="form-group mb-0"><label>Minimal Quantity</label><input v-model="createForm.minimal_quantity" type="number" min="1" class="form-control" :class="{ 'is-invalid': createForm.errors.minimal_quantity }"><div v-if="createForm.errors.minimal_quantity" class="invalid-feedback d-block">{{ createForm.errors.minimal_quantity }}</div></div>
            <div class="form-group mb-0"><label>Minimal Belanja</label><input v-model="createForm.minimal_belanja" type="number" min="0" class="form-control" :class="{ 'is-invalid': createForm.errors.minimal_belanja }"><div v-if="createForm.errors.minimal_belanja" class="invalid-feedback d-block">{{ createForm.errors.minimal_belanja }}</div></div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeCreateModal">Batal</button>
            <button type="button" class="btn btn-primary" :disabled="createForm.processing" @click="submitCreate">Simpan Promo</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showEditModal" title="Edit Promo" size="lg" @close="closeEditModal">
        <div class="crud-modal-body">
            <div v-if="editErrorMessages.length" class="alert alert-danger mb-0">
                <div v-for="message in editErrorMessages" :key="`edit-${message}`">{{ message }}</div>
            </div>
            <div class="form-group mb-0"><label>Nama Promo</label><input v-model="editForm.nama_promo" type="text" class="form-control" :class="{ 'is-invalid': editForm.errors.nama_promo }"><div v-if="editForm.errors.nama_promo" class="invalid-feedback d-block">{{ editForm.errors.nama_promo }}</div></div>
            <div class="form-group mb-0"><label>Potongan</label><input v-model="editForm.potongan" type="number" min="0" class="form-control" :class="{ 'is-invalid': editForm.errors.potongan }"><div v-if="editForm.errors.potongan" class="invalid-feedback d-block">{{ editForm.errors.potongan }}</div></div>
            <div class="form-group mb-0"><label>Masa Aktif</label><input v-model="editForm.masa_aktif" type="date" class="form-control" :class="{ 'is-invalid': editForm.errors.masa_aktif }"><div v-if="editForm.errors.masa_aktif" class="invalid-feedback d-block">{{ editForm.errors.masa_aktif }}</div></div>
            <div class="form-group mb-0"><label>Minimal Quantity</label><input v-model="editForm.minimal_quantity" type="number" min="1" class="form-control" :class="{ 'is-invalid': editForm.errors.minimal_quantity }"><div v-if="editForm.errors.minimal_quantity" class="invalid-feedback d-block">{{ editForm.errors.minimal_quantity }}</div></div>
            <div class="form-group mb-0"><label>Minimal Belanja</label><input v-model="editForm.minimal_belanja" type="number" min="0" class="form-control" :class="{ 'is-invalid': editForm.errors.minimal_belanja }"><div v-if="editForm.errors.minimal_belanja" class="invalid-feedback d-block">{{ editForm.errors.minimal_belanja }}</div></div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeEditModal">Batal</button>
            <button type="button" class="btn btn-warning" :disabled="editForm.processing || !editForm.id" @click="submitEdit">Update</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        Hapus promo {{ deleteTarget?.nama_promo }}?
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
import BootstrapModal from '../../Components/BootstrapModal.vue';
import { adminUrl } from '../../utils/admin';

defineProps({ promos: Array });
const createForm = useForm({ nama_promo: '', potongan: '', masa_aktif: '', minimal_quantity: 1, minimal_belanja: 0 });
const editForm = useForm({ id: null, nama_promo: '', potongan: '', masa_aktif: '', minimal_quantity: 1, minimal_belanja: 0 });
const showCreateModal = ref(false);
const showEditModal = ref(false);
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const createErrorMessages = computed(() => Object.values(createForm.errors || {}));
const editErrorMessages = computed(() => Object.values(editForm.errors || {}));
const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value || 0);
const openCreateModal = () => {
    createForm.reset();
    showCreateModal.value = true;
};
const closeCreateModal = () => {
    showCreateModal.value = false;
    createForm.reset();
};
const submitCreate = () => createForm.post(adminUrl('/promos'), { preserveScroll: true, onSuccess: () => closeCreateModal() });
const openEditModal = (item) => {
    Object.assign(editForm, item);
    showEditModal.value = true;
};
const closeEditModal = () => {
    showEditModal.value = false;
    editForm.reset();
    editForm.id = null;
};
const submitEdit = () => editForm.put(adminUrl(`/promos/${editForm.id}`), { preserveScroll: true, onSuccess: () => closeEditModal() });
const removePromo = (item) => {
    deleteTarget.value = item;
    showDeleteModal.value = true;
};
const closeDeleteModal = () => {
    showDeleteModal.value = false;
    deleteTarget.value = null;
};
const confirmDelete = () => {
    if (!deleteTarget.value) return;
    const id = deleteTarget.value.id;
    closeDeleteModal();
    router.delete(adminUrl(`/promos/${id}`), { preserveScroll: true });
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



