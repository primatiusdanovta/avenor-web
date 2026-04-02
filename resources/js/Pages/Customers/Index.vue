<template>
    <Head title="Pelanggan" />

    <div class="row">
        <div class="col-lg-5">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Input Pelanggan</h3></div>
                <div class="card-body">
                    <div v-if="createErrorMessages.length" class="alert alert-danger">
                        <div v-for="message in createErrorMessages" :key="`create-customer-${message}`">{{ message }}</div>
                    </div>
                    <div class="form-group"><label>Nama</label><input v-model="createForm.nama" type="text" class="form-control" :class="{ 'is-invalid': createForm.errors.nama }"><div v-if="createForm.errors.nama" class="invalid-feedback d-block">{{ createForm.errors.nama }}</div></div>
                    <div class="form-group"><label>No Telp</label><input v-model="createForm.no_telp" type="text" class="form-control" :class="{ 'is-invalid': createForm.errors.no_telp }"><div v-if="createForm.errors.no_telp" class="invalid-feedback d-block">{{ createForm.errors.no_telp }}</div></div>
                    <div class="form-group"><label>Tiktok / Instagram</label><input v-model="createForm.tiktok_instagram" type="text" class="form-control" :class="{ 'is-invalid': createForm.errors.tiktok_instagram }"><div v-if="createForm.errors.tiktok_instagram" class="invalid-feedback d-block">{{ createForm.errors.tiktok_instagram }}</div></div>
                    <div class="form-group"><label>Pembelian Terakhir</label><input v-model="createForm.pembelian_terakhir" type="datetime-local" class="form-control" :class="{ 'is-invalid': createForm.errors.pembelian_terakhir }"><div v-if="createForm.errors.pembelian_terakhir" class="invalid-feedback d-block">{{ createForm.errors.pembelian_terakhir }}</div></div>
                    <button class="btn btn-primary" style="margin-top: 10px;" :disabled="createForm.processing" @click="submitCreate">Simpan Pelanggan</button>
                </div>
            </div>

            <div v-if="editForm.id_pelanggan" class="card card-outline card-warning">
                <div class="card-header"><h3 class="card-title">Edit Pelanggan</h3></div>
                <div class="card-body">
                    <div v-if="editErrorMessages.length" class="alert alert-danger">
                        <div v-for="message in editErrorMessages" :key="`edit-customer-${message}`">{{ message }}</div>
                    </div>
                    <div class="form-group"><label>Nama</label><input v-model="editForm.nama" type="text" class="form-control" :class="{ 'is-invalid': editForm.errors.nama }"><div v-if="editForm.errors.nama" class="invalid-feedback d-block">{{ editForm.errors.nama }}</div></div>
                    <div class="form-group"><label>No Telp</label><input v-model="editForm.no_telp" type="text" class="form-control" :class="{ 'is-invalid': editForm.errors.no_telp }"><div v-if="editForm.errors.no_telp" class="invalid-feedback d-block">{{ editForm.errors.no_telp }}</div></div>
                    <div class="form-group"><label>Tiktok / Instagram</label><input v-model="editForm.tiktok_instagram" type="text" class="form-control" :class="{ 'is-invalid': editForm.errors.tiktok_instagram }"><div v-if="editForm.errors.tiktok_instagram" class="invalid-feedback d-block">{{ editForm.errors.tiktok_instagram }}</div></div>
                    <div class="form-group"><label>Pembelian Terakhir</label><input v-model="editForm.pembelian_terakhir" type="datetime-local" class="form-control" :class="{ 'is-invalid': editForm.errors.pembelian_terakhir }"><div v-if="editForm.errors.pembelian_terakhir" class="invalid-feedback d-block">{{ editForm.errors.pembelian_terakhir }}</div></div>
                    <button class="btn btn-warning mr-2" :disabled="editForm.processing" @click="submitEdit">Update</button>
                    <button class="btn btn-secondary" @click="resetEdit">Batal</button>
                </div>
            </div>
        </div>

        <div class="col-lg-7">
            <div class="card card-outline card-success">
                <div class="card-header"><h3 class="card-title">Daftar Pelanggan</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Nama</th><th>No Telp</th><th>Tiktok / Instagram</th><th>Dibuat</th><th>Pembelian Terakhir</th><th>Item</th><th>Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in customers" :key="item.id_pelanggan">
                                <td>{{ item.nama || '-' }}</td>
                                <td>{{ item.no_telp || '-' }}</td>
                                <td>{{ item.tiktok_instagram || '-' }}</td>
                                <td>{{ item.created_at || '-' }}</td>
                                <td>{{ item.pembelian_terakhir || '-' }}</td>
                                <td>{{ item.latest_purchase_items || '-' }}</td>
                                <td>
                                    <button class="btn btn-xs btn-warning mr-1" @click="pickEdit(item)">Edit</button>
                                    <button class="btn btn-xs btn-outline-danger" @click="removeCustomer(item)">Hapus</button>
                                </td>
                            </tr>
                            <tr v-if="!customers.length"><td colspan="7" class="text-center text-muted">Belum ada data pelanggan.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        Hapus pelanggan {{ deleteTarget?.nama || deleteTarget?.no_telp || deleteTarget?.id_pelanggan }}?
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
import BootstrapModal from '../../Components/BootstrapModal.vue';

defineOptions({ layout: AppLayout });

defineProps({ customers: Array });

const createForm = useForm({ nama: '', no_telp: '', tiktok_instagram: '', pembelian_terakhir: '' });
const editForm = useForm({ id_pelanggan: null, nama: '', no_telp: '', tiktok_instagram: '', pembelian_terakhir: '' });
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const createErrorMessages = computed(() => Object.values(createForm.errors || {}));
const editErrorMessages = computed(() => Object.values(editForm.errors || {}));

const toDateTimeLocal = (value) => value ? value.replace(' ', 'T').slice(0, 16) : '';
const submitCreate = () => createForm.post('/customers', { preserveScroll: true, onSuccess: () => createForm.reset() });
const pickEdit = (item) => Object.assign(editForm, {
    id_pelanggan: item.id_pelanggan,
    nama: item.nama || '',
    no_telp: item.no_telp || '',
    tiktok_instagram: item.tiktok_instagram || '',
    pembelian_terakhir: toDateTimeLocal(item.pembelian_terakhir),
});
const submitEdit = () => editForm.put(`/customers/${editForm.id_pelanggan}`, { preserveScroll: true, onSuccess: () => editForm.reset() });
const resetEdit = () => editForm.reset();
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
    router.delete(`/customers/${id}`, { preserveScroll: true });
};
</script>



