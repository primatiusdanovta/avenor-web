<template>
    <AppLayout>
    <Head title="Users" />

    <template #actions>
        <button type="button" class="btn btn-primary" @click="openCreateModal">
            <i class="fas fa-plus mr-1"></i>
            Tambah User
        </button>
    </template>

    <div class="row">
        <div class="col-lg-12">
            <div class="card card-outline card-success">
                <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <h3 class="card-title mb-0">Daftar User</h3>
                    <div class="d-flex align-items-center flex-wrap gap-2">
                        <Select2Input v-model="searchForm.role" :options="roleOptions" value-key="value" label-key="label" placeholder="Semua role" />
                        <input v-model="searchForm.search" type="text" class="form-control form-control-sm user-search" placeholder="Cari username">
                        <button type="button" class="btn btn-sm btn-outline-primary" @click="submitSearch">Cari</button>
                    </div>
                </div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>ID</th><th>Username</th><th>Role</th><th>Status</th><th>Created At</th><th class="action-column">Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="user in users" :key="user.id_user">
                                <td>{{ user.id_user }}</td>
                                <td>
                                    <button type="button" class="btn btn-link p-0 font-weight-bold text-left" @click="openEditModal(user)">{{ user.nama }}</button>
                                </td>
                                <td><span class="text-dark font-weight-bold">{{ user.role_label || user.role }}</span></td>
                                <td><span class="text-dark font-weight-bold">{{ user.status }}</span></td>
                                <td>{{ user.created_at }}</td>
                                <td>
                                    <div class="action-group">
                                        <button type="button" class="btn btn-xs btn-warning" @click="openEditModal(user)"><i class="fas fa-pen mr-1"></i>Edit</button>
                                        <button type="button" class="btn btn-xs btn-danger" @click="removeUser(user)"><i class="fas fa-trash-alt mr-1"></i>Hapus</button>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="!users.length"><td colspan="6" class="text-center text-muted">Belum ada user.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showCreateModal" title="Tambah User" size="lg" @close="closeCreateModal">
        <div class="crud-modal-body">
            <div class="form-group">
                <label>Username</label>
                <input v-model="createForm.nama" type="text" class="form-control" placeholder="username baru">
                <small v-if="createForm.errors.nama" class="text-danger">{{ createForm.errors.nama }}</small>
            </div>
            <div class="form-group">
                <label>Role</label>
                <Select2Input v-model="createForm.role" :options="roleOptions" value-key="value" label-key="label" placeholder="Pilih role" />
            </div>
            <div class="form-group">
                <label>Status</label>
                <Select2Input v-model="createForm.status" :options="statuses" placeholder="Pilih status" />
            </div>
            <div class="form-group">
                <label>Password</label>
                <input v-model="createForm.password" type="password" class="form-control" placeholder="minimal 8 karakter">
                <small v-if="createForm.errors.password" class="text-danger">{{ createForm.errors.password }}</small>
            </div>
            <div class="form-group mb-0">
                <label>Konfirmasi Password</label>
                <input v-model="createForm.password_confirmation" type="password" class="form-control" placeholder="ulang password">
            </div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeCreateModal">Batal</button>
            <button type="button" class="btn btn-primary" :disabled="createForm.processing" @click="submitCreate">
                {{ createForm.processing ? 'Menyimpan...' : 'Tambah User' }}
            </button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showEditModal" title="Edit User" size="lg" @close="closeEditModal">
        <div class="crud-modal-body">
            <div class="form-group">
                <label>Username</label>
                <input v-model="editForm.nama" type="text" class="form-control">
            </div>
            <div class="form-group">
                <label>Role</label>
                <Select2Input v-model="editForm.role" :options="roleOptions" value-key="value" label-key="label" placeholder="Pilih role" />
            </div>
            <div class="form-group">
                <label>Status</label>
                <Select2Input v-model="editForm.status" :options="statuses" placeholder="Pilih status" />
            </div>
            <div class="form-group">
                <label>Password Baru</label>
                <input v-model="editForm.password" type="password" class="form-control" placeholder="kosongkan jika tidak diubah">
            </div>
            <div class="form-group mb-0">
                <label>Konfirmasi Password Baru</label>
                <input v-model="editForm.password_confirmation" type="password" class="form-control">
            </div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeEditModal">Batal</button>
            <button type="button" class="btn btn-warning" :disabled="editForm.processing || !editForm.id_user" @click="submitEdit">Simpan</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        Hapus user {{ deleteTarget?.nama }}?
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeDeleteModal">Batal</button>
            <button type="button" class="btn btn-danger" @click="confirmDelete">Hapus</button>
        </template>
    </BootstrapModal>

    </AppLayout>
</template>

<script setup>
import { ref } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import Select2Input from '../../Components/Select2Input.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';
import { adminUrl } from '../../utils/admin';

const props = defineProps({ filters: Object, users: Array, roles: Array, roleOptions: Array, statuses: Array });
const searchForm = useForm({ search: props.filters.search ?? '', role: props.filters.role ?? null });
const createForm = useForm({ nama: '', role: 'admin', status: 'aktif', password: '', password_confirmation: '' });
const editForm = useForm({ id_user: null, nama: '', role: 'admin', status: 'aktif', password: '', password_confirmation: '' });
const showCreateModal = ref(false);
const showEditModal = ref(false);
const showDeleteModal = ref(false);
const deleteTarget = ref(null);

const submitSearch = () => searchForm.get(adminUrl('/users'), { preserveState: true, preserveScroll: true, replace: true });
const openCreateModal = () => {
    createForm.reset();
    createForm.role = 'admin';
    showCreateModal.value = true;
};
const closeCreateModal = () => {
    showCreateModal.value = false;
    createForm.reset();
};
const submitCreate = () => createForm.post(adminUrl('/users'), {
    preserveScroll: true,
    onSuccess: () => closeCreateModal(),
});
const openEditModal = (user) => {
    editForm.id_user = user.id_user;
    editForm.nama = user.nama;
    editForm.role = user.role;
    editForm.status = user.status;
    editForm.password = '';
    editForm.password_confirmation = '';
    showEditModal.value = true;
};
const closeEditModal = () => {
    showEditModal.value = false;
    editForm.reset();
    editForm.id_user = null;
};
const submitEdit = () => editForm.put(adminUrl(`/users/${editForm.id_user}`), {
    preserveScroll: true,
    onSuccess: () => closeEditModal(),
});
const removeUser = (user) => {
    deleteTarget.value = user;
    showDeleteModal.value = true;
};
const closeDeleteModal = () => {
    showDeleteModal.value = false;
    deleteTarget.value = null;
};
const confirmDelete = () => {
    if (!deleteTarget.value) return;
    const id = deleteTarget.value.id_user;
    closeDeleteModal();
    router.delete(adminUrl(`/users/${id}`), { preserveScroll: true });
};
</script>

<style scoped>
.user-search {
    width: 220px;
}

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
    .user-search {
        width: 100%;
    }

    .action-group {
        grid-template-columns: 1fr;
    }
}
</style>
