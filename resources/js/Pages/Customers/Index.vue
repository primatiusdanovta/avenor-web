<template>
    <AppLayout>
    <Head title="Pelanggan" />

    <template #actions>
        <button type="button" class="btn btn-primary" @click="openCreateModal">
            <i class="fas fa-plus mr-1"></i>
            Tambah Pelanggan
        </button>
    </template>

    <div class="row">
        <div class="col-lg-12">
            <div class="card card-outline card-success">
                <div class="card-header"><h3 class="card-title mb-0">Daftar Pelanggan</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Nama</th><th>No Telp</th><th>Tiktok / Instagram</th><th>Dibuat</th><th>Pembelian Terakhir</th><th>Item</th><th class="action-column">Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in customers" :key="item.id_pelanggan">
                                <td><button type="button" class="btn btn-link p-0 font-weight-bold text-left" @click="openEditModal(item)">{{ item.nama || '-' }}</button></td>
                                <td>{{ item.no_telp || '-' }}</td>
                                <td>{{ item.tiktok_instagram || '-' }}</td>
                                <td>{{ item.created_at || '-' }}</td>
                                <td>{{ item.pembelian_terakhir || '-' }}</td>
                                <td>{{ item.latest_purchase_items || '-' }}</td>
                                <td>
                                    <div class="action-group">
                                        <button class="btn btn-xs btn-warning" @click="openEditModal(item)"><i class="fas fa-pen mr-1"></i>Edit</button>
                                        <button class="btn btn-xs btn-outline-danger" @click="removeCustomer(item)"><i class="fas fa-trash-alt mr-1"></i>Hapus</button>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="!customers.length"><td colspan="7" class="text-center text-muted">Belum ada data pelanggan.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showCreateModal" title="Tambah Pelanggan" size="lg" @close="closeCreateModal">
        <div class="crud-modal-body">
            <div v-if="createErrorMessages.length" class="alert alert-danger mb-0">
                <div v-for="message in createErrorMessages" :key="`create-customer-${message}`">{{ message }}</div>
            </div>
            <div class="form-group mb-0"><label>Nama</label><input v-model="createForm.nama" type="text" class="form-control" :class="{ 'is-invalid': createForm.errors.nama }"><div v-if="createForm.errors.nama" class="invalid-feedback d-block">{{ createForm.errors.nama }}</div></div>
            <div class="form-group mb-0"><label>No Telp</label><input v-model="createForm.no_telp" type="text" class="form-control" :class="{ 'is-invalid': createForm.errors.no_telp }"><div v-if="createForm.errors.no_telp" class="invalid-feedback d-block">{{ createForm.errors.no_telp }}</div></div>
            <div class="form-group mb-0"><label>Tiktok / Instagram</label><input v-model="createForm.tiktok_instagram" type="text" class="form-control" :class="{ 'is-invalid': createForm.errors.tiktok_instagram }"><div v-if="createForm.errors.tiktok_instagram" class="invalid-feedback d-block">{{ createForm.errors.tiktok_instagram }}</div></div>
            <div class="form-group mb-0"><label>Pembelian Terakhir</label><input v-model="createForm.pembelian_terakhir" type="datetime-local" class="form-control" :class="{ 'is-invalid': createForm.errors.pembelian_terakhir }"><div v-if="createForm.errors.pembelian_terakhir" class="invalid-feedback d-block">{{ createForm.errors.pembelian_terakhir }}</div></div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeCreateModal">Batal</button>
            <button type="button" class="btn btn-primary" :disabled="createForm.processing" @click="submitCreate">Simpan Pelanggan</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showEditModal" title="Edit Pelanggan" size="lg" @close="closeEditModal">
        <div class="crud-modal-body">
            <div v-if="editErrorMessages.length" class="alert alert-danger mb-0">
                <div v-for="message in editErrorMessages" :key="`edit-customer-${message}`">{{ message }}</div>
            </div>
            <div class="form-group mb-0"><label>Nama</label><input v-model="editForm.nama" type="text" class="form-control" :class="{ 'is-invalid': editForm.errors.nama }"><div v-if="editForm.errors.nama" class="invalid-feedback d-block">{{ editForm.errors.nama }}</div></div>
            <div class="form-group mb-0"><label>No Telp</label><input v-model="editForm.no_telp" type="text" class="form-control" :class="{ 'is-invalid': editForm.errors.no_telp }"><div v-if="editForm.errors.no_telp" class="invalid-feedback d-block">{{ editForm.errors.no_telp }}</div></div>
            <div class="form-group mb-0"><label>Tiktok / Instagram</label><input v-model="editForm.tiktok_instagram" type="text" class="form-control" :class="{ 'is-invalid': editForm.errors.tiktok_instagram }"><div v-if="editForm.errors.tiktok_instagram" class="invalid-feedback d-block">{{ editForm.errors.tiktok_instagram }}</div></div>
            <div class="form-group mb-0"><label>Pembelian Terakhir</label><input v-model="editForm.pembelian_terakhir" type="datetime-local" class="form-control" :class="{ 'is-invalid': editForm.errors.pembelian_terakhir }"><div v-if="editForm.errors.pembelian_terakhir" class="invalid-feedback d-block">{{ editForm.errors.pembelian_terakhir }}</div></div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeEditModal">Batal</button>
            <button type="button" class="btn btn-warning" :disabled="editForm.processing || !editForm.id_pelanggan" @click="submitEdit">Update</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        Hapus pelanggan {{ deleteTarget?.nama || deleteTarget?.no_telp || deleteTarget?.id_pelanggan }}?
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

defineProps({ customers: Array });

const createForm = useForm({ nama: '', no_telp: '', tiktok_instagram: '', pembelian_terakhir: '' });
const editForm = useForm({ id_pelanggan: null, nama: '', no_telp: '', tiktok_instagram: '', pembelian_terakhir: '' });
const showCreateModal = ref(false);
const showEditModal = ref(false);
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const createErrorMessages = computed(() => Object.values(createForm.errors || {}));
const editErrorMessages = computed(() => Object.values(editForm.errors || {}));

const toDateTimeLocal = (value) => value ? value.replace(' ', 'T').slice(0, 16) : '';
const openCreateModal = () => {
    createForm.reset();
    showCreateModal.value = true;
};
const closeCreateModal = () => {
    showCreateModal.value = false;
    createForm.reset();
};
const submitCreate = () => createForm.post(adminUrl('/customers'), { preserveScroll: true, onSuccess: () => closeCreateModal() });
const openEditModal = (item) => {
    Object.assign(editForm, {
        id_pelanggan: item.id_pelanggan,
        nama: item.nama || '',
        no_telp: item.no_telp || '',
        tiktok_instagram: item.tiktok_instagram || '',
        pembelian_terakhir: toDateTimeLocal(item.pembelian_terakhir),
    });
    showEditModal.value = true;
};
const submitEdit = () => editForm.put(adminUrl(`/customers/${editForm.id_pelanggan}`), { preserveScroll: true, onSuccess: () => closeEditModal() });
const closeEditModal = () => {
    showEditModal.value = false;
    editForm.reset();
    editForm.id_pelanggan = null;
};
const removeCustomer = (item) => {
    deleteTarget.value = item;
    showDeleteModal.value = true;
};
const closeDeleteModal = () => {
    showDeleteModal.value = false;
    deleteTarget.value = null;
};
const confirmDelete = () => {
    if (!deleteTarget.value) return;
    const id = deleteTarget.value.id_pelanggan;
    closeDeleteModal();
    router.delete(adminUrl(`/customers/${id}`), { preserveScroll: true });
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



