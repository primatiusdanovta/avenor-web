<template>
    <Head title="Promos" />

    <div class="row">
        <div class="col-md-12 col-lg-5">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Tambah Promo</h3></div>
                <div class="card-body">
                    <div v-if="createErrorMessages.length" class="alert alert-danger">
                        <div v-for="message in createErrorMessages" :key="`create-${message}`">{{ message }}</div>
                    </div>
                    <form @submit.prevent="submitCreate">
                        <div class="form-group"><label>Nama Promo</label><input v-model="createForm.nama_promo" type="text" class="form-control" :class="{ 'is-invalid': createForm.errors.nama_promo }"><div v-if="createForm.errors.nama_promo" class="invalid-feedback d-block">{{ createForm.errors.nama_promo }}</div></div>
                        <div class="form-group"><label>Potongan</label><input v-model="createForm.potongan" type="number" min="0" class="form-control" :class="{ 'is-invalid': createForm.errors.potongan }"><div v-if="createForm.errors.potongan" class="invalid-feedback d-block">{{ createForm.errors.potongan }}</div></div>
                        <div class="form-group"><label>Masa Aktif</label><input v-model="createForm.masa_aktif" type="date" class="form-control" :class="{ 'is-invalid': createForm.errors.masa_aktif }"><div v-if="createForm.errors.masa_aktif" class="invalid-feedback d-block">{{ createForm.errors.masa_aktif }}</div></div>
                        <div class="form-group"><label>Minimal Quantity</label><input v-model="createForm.minimal_quantity" type="number" min="1" class="form-control" :class="{ 'is-invalid': createForm.errors.minimal_quantity }"><div v-if="createForm.errors.minimal_quantity" class="invalid-feedback d-block">{{ createForm.errors.minimal_quantity }}</div></div>
                        <div class="form-group"><label>Minimal Belanja</label><input v-model="createForm.minimal_belanja" type="number" min="0" class="form-control" :class="{ 'is-invalid': createForm.errors.minimal_belanja }"><div v-if="createForm.errors.minimal_belanja" class="invalid-feedback d-block">{{ createForm.errors.minimal_belanja }}</div></div>
                        <button class="btn btn-primary" style="margin-top: 10px;" :disabled="createForm.processing">Simpan Promo</button>
                    </form>
                </div>
            </div>

            <div class="card card-outline card-warning">
                <div class="card-header"><h3 class="card-title">Edit Promo</h3></div>
                <div v-if="editForm.id" class="card-body">
                    <div v-if="editErrorMessages.length" class="alert alert-danger">
                        <div v-for="message in editErrorMessages" :key="`edit-${message}`">{{ message }}</div>
                    </div>
                    <div class="form-group"><label>Nama Promo</label><input v-model="editForm.nama_promo" type="text" class="form-control" :class="{ 'is-invalid': editForm.errors.nama_promo }"><div v-if="editForm.errors.nama_promo" class="invalid-feedback d-block">{{ editForm.errors.nama_promo }}</div></div>
                    <div class="form-group"><label>Potongan</label><input v-model="editForm.potongan" type="number" min="0" class="form-control" :class="{ 'is-invalid': editForm.errors.potongan }"><div v-if="editForm.errors.potongan" class="invalid-feedback d-block">{{ editForm.errors.potongan }}</div></div>
                    <div class="form-group"><label>Masa Aktif</label><input v-model="editForm.masa_aktif" type="date" class="form-control" :class="{ 'is-invalid': editForm.errors.masa_aktif }"><div v-if="editForm.errors.masa_aktif" class="invalid-feedback d-block">{{ editForm.errors.masa_aktif }}</div></div>
                    <div class="form-group"><label>Minimal Quantity</label><input v-model="editForm.minimal_quantity" type="number" min="1" class="form-control" :class="{ 'is-invalid': editForm.errors.minimal_quantity }"><div v-if="editForm.errors.minimal_quantity" class="invalid-feedback d-block">{{ editForm.errors.minimal_quantity }}</div></div>
                    <div class="form-group"><label>Minimal Belanja</label><input v-model="editForm.minimal_belanja" type="number" min="0" class="form-control" :class="{ 'is-invalid': editForm.errors.minimal_belanja }"><div v-if="editForm.errors.minimal_belanja" class="invalid-feedback d-block">{{ editForm.errors.minimal_belanja }}</div></div>
                    <button class="btn btn-warning mr-2" @click="submitEdit">Update</button>
                    <button class="btn btn-secondary" @click="editForm.reset()">Batal</button>
                </div>
                <div v-else class="card-body text-muted">Pilih promo dari tabel untuk edit.</div>
            </div>
        </div>

        <div class="col-md-12 col-lg-7">
            <div class="card card-outline card-success">
                <div class="card-header"><h3 class="card-title">Daftar Promo</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Kode</th><th>Nama</th><th>Potongan</th><th>Masa Aktif</th><th>Min Qty</th><th>Min Belanja</th><th>Status</th><th>Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in promos" :key="item.id">
                                <td>{{ item.kode_promo }}</td>
                                <td>{{ item.nama_promo }}</td>
                                <td>{{ toCurrency(item.potongan) }}</td>
                                <td>{{ item.masa_aktif }}</td>
                                <td>{{ item.minimal_quantity }}</td>
                                <td>{{ toCurrency(item.minimal_belanja) }}</td>
                                <td>{{ item.is_active ? 'aktif' : 'expired' }}</td>
                                <td>
                                    <button class="btn btn-xs btn-warning mr-1" @click="pickEdit(item)">Edit</button>
                                    <button class="btn btn-xs btn-danger" @click="removePromo(item)">Hapus</button>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        Hapus promo {{ deleteTarget?.nama_promo }}?
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

defineProps({ promos: Array });
const createForm = useForm({ nama_promo: '', potongan: '', masa_aktif: '', minimal_quantity: 1, minimal_belanja: 0 });
const editForm = useForm({ id: null, nama_promo: '', potongan: '', masa_aktif: '', minimal_quantity: 1, minimal_belanja: 0 });
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const createErrorMessages = computed(() => Object.values(createForm.errors || {}));
const editErrorMessages = computed(() => Object.values(editForm.errors || {}));
const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value || 0);
const submitCreate = () => createForm.post('/promos', { preserveScroll: true, onSuccess: () => createForm.reset() });
const pickEdit = (item) => Object.assign(editForm, item);
const submitEdit = () => editForm.put(`/promos/${editForm.id}`, { preserveScroll: true });
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
    router.delete(`/promos/${id}`, { preserveScroll: true });
};
</script>



