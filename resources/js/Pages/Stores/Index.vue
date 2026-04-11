<template>
    <AppLayout title="Master Store">
        <Head title="Master Store" />

        <template #actions>
            <button v-if="canManage" type="button" class="btn btn-primary" @click="openCreateModal">Tambah Store</button>
        </template>

        <div class="card card-outline card-success">
            <div class="card-header">
                <h3 class="card-title mb-0">Daftar Store</h3>
            </div>
            <div class="card-body p-0 table-responsive">
                <table class="table table-hover mb-0">
                    <thead>
                        <tr>
                            <th>Kode</th>
                            <th>Nama Sistem</th>
                            <th>Nama Tampil</th>
                            <th>Status</th>
                            <th>Timezone</th>
                            <th>Mata Uang</th>
                            <th v-if="canManage">Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="store in stores" :key="store.id">
                            <td>{{ store.code }}</td>
                            <td>{{ store.name }}</td>
                            <td>{{ store.display_name }}</td>
                            <td>{{ store.status }}</td>
                            <td>{{ store.timezone }}</td>
                            <td>{{ store.currency }}</td>
                            <td v-if="canManage">
                                <button type="button" class="btn btn-sm btn-warning" @click="openEditModal(store)">Edit</button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <BootstrapModal :show="showCreateModal" title="Tambah Store" size="lg" @close="closeCreateModal">
            <div class="row g-3">
                <div class="col-md-6"><label class="form-label">Code</label><input v-model="createForm.code" type="text" class="form-control"></div>
                <div class="col-md-6"><label class="form-label">Name</label><input v-model="createForm.name" type="text" class="form-control"></div>
                <div class="col-md-6"><label class="form-label">Display Name</label><input v-model="createForm.display_name" type="text" class="form-control"></div>
                <div class="col-md-6"><label class="form-label">Status</label><select v-model="createForm.status" class="form-select"><option value="active">Active</option><option value="inactive">Inactive</option></select></div>
                <div class="col-md-6"><label class="form-label">Timezone</label><input v-model="createForm.timezone" type="text" class="form-control"></div>
                <div class="col-md-6"><label class="form-label">Currency</label><input v-model="createForm.currency" type="text" class="form-control"></div>
                <div class="col-12"><label class="form-label">Address</label><textarea v-model="createForm.address" class="form-control" rows="3"></textarea></div>
                <div class="col-md-6"><label class="form-label">Brand Title</label><input v-model="createForm.brand_title" type="text" class="form-control"></div>
                <div class="col-md-6"><label class="form-label">Web Title</label><input v-model="createForm.web_title" type="text" class="form-control"></div>
                <div class="col-md-6"><label class="form-label">Brand Image URL</label><input v-model="createForm.brand_image" type="text" class="form-control" placeholder="/img/logo.png"></div>
                <div class="col-md-6"><label class="form-label">Favicon URL</label><input v-model="createForm.favicon" type="text" class="form-control" placeholder="/favicon.ico"></div>
            </div>
            <template #footer>
                <button type="button" class="btn btn-secondary" @click="closeCreateModal">Batal</button>
                <button type="button" class="btn btn-primary" :disabled="createForm.processing" @click="submitCreate">Simpan</button>
            </template>
        </BootstrapModal>

        <BootstrapModal :show="showEditModal" title="Edit Store" size="lg" @close="closeEditModal">
            <div class="row g-3">
                <div class="col-md-6"><label class="form-label">Code</label><input v-model="editForm.code" type="text" class="form-control"></div>
                <div class="col-md-6"><label class="form-label">Name</label><input v-model="editForm.name" type="text" class="form-control"></div>
                <div class="col-md-6"><label class="form-label">Display Name</label><input v-model="editForm.display_name" type="text" class="form-control"></div>
                <div class="col-md-6"><label class="form-label">Status</label><select v-model="editForm.status" class="form-select"><option value="active">Active</option><option value="inactive">Inactive</option></select></div>
                <div class="col-md-6"><label class="form-label">Timezone</label><input v-model="editForm.timezone" type="text" class="form-control"></div>
                <div class="col-md-6"><label class="form-label">Currency</label><input v-model="editForm.currency" type="text" class="form-control"></div>
                <div class="col-12"><label class="form-label">Address</label><textarea v-model="editForm.address" class="form-control" rows="3"></textarea></div>
                <div class="col-md-6"><label class="form-label">Brand Title</label><input v-model="editForm.brand_title" type="text" class="form-control"></div>
                <div class="col-md-6"><label class="form-label">Web Title</label><input v-model="editForm.web_title" type="text" class="form-control"></div>
                <div class="col-md-6"><label class="form-label">Brand Image URL</label><input v-model="editForm.brand_image" type="text" class="form-control" placeholder="/img/logo.png"></div>
                <div class="col-md-6"><label class="form-label">Favicon URL</label><input v-model="editForm.favicon" type="text" class="form-control" placeholder="/favicon.ico"></div>
            </div>
            <template #footer>
                <button type="button" class="btn btn-secondary" @click="closeEditModal">Batal</button>
                <button type="button" class="btn btn-warning" :disabled="editForm.processing" @click="submitEdit">Simpan</button>
            </template>
        </BootstrapModal>
    </AppLayout>
</template>

<script setup>
import { ref } from 'vue';
import { Head, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';
import { adminUrl } from '../../utils/admin';

const props = defineProps({ stores: Array, canManage: Boolean });
const showCreateModal = ref(false);
const showEditModal = ref(false);

const createForm = useForm({ code: '', name: '', display_name: '', status: 'active', timezone: 'Asia/Jakarta', currency: 'IDR', address: '', brand_title: '', brand_image: '', favicon: '', web_title: '' });
const editForm = useForm({ id: null, code: '', name: '', display_name: '', status: 'active', timezone: 'Asia/Jakarta', currency: 'IDR', address: '', brand_title: '', brand_image: '', favicon: '', web_title: '' });

const openCreateModal = () => {
    createForm.reset();
    createForm.status = 'active';
    createForm.timezone = 'Asia/Jakarta';
    createForm.currency = 'IDR';
    createForm.brand_title = '';
    createForm.brand_image = '';
    createForm.favicon = '';
    createForm.web_title = '';
    showCreateModal.value = true;
};
const closeCreateModal = () => { showCreateModal.value = false; createForm.reset(); };
const submitCreate = () => createForm.post(adminUrl('/stores'), { preserveScroll: true, onSuccess: () => closeCreateModal() });

const openEditModal = (store) => {
    editForm.id = store.id;
    editForm.code = store.code;
    editForm.name = store.name;
    editForm.display_name = store.display_name;
    editForm.status = store.status;
    editForm.timezone = store.timezone;
    editForm.currency = store.currency;
    editForm.address = store.address || '';
    editForm.brand_title = store.brand_title || '';
    editForm.brand_image = store.brand_image || '';
    editForm.favicon = store.favicon || '';
    editForm.web_title = store.web_title || '';
    showEditModal.value = true;
};
const closeEditModal = () => { showEditModal.value = false; editForm.reset(); editForm.id = null; };
const submitEdit = () => editForm.put(adminUrl(`/stores/${editForm.id}`), { preserveScroll: true, onSuccess: () => closeEditModal() });
</script>
