<template>
    <Head title="User Management" />

    <div class="row">
        <div class="col-lg-4">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Tambah User</h3></div>
                <div class="card-body">
                    <div class="form-group">
                        <label>Username</label>
                        <input v-model="createForm.nama" type="text" class="form-control" placeholder="username baru">
                        <small v-if="createForm.errors.nama" class="text-danger">{{ createForm.errors.nama }}</small>
                    </div>
                    <div class="form-group">
                        <label>Role</label>
                        <Select2Input v-model="createForm.role" :options="roles" placeholder="Pilih role" />
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
                    <div class="form-group">
                        <label>Konfirmasi Password</label>
                        <input v-model="createForm.password_confirmation" type="password" class="form-control" placeholder="ulang password">
                    </div>
                    <button type="button" class="btn btn-primary" style="margin-top: 10px;" :disabled="createForm.processing" @click="submitCreate">
                        {{ createForm.processing ? 'Menyimpan...' : 'Tambah User' }}
                    </button>
                </div>
            </div>

            <div class="card card-outline card-warning">
                <div class="card-header"><h3 class="card-title">Edit User</h3></div>
                <div v-if="selectedUser" class="card-body">
                    <div class="form-group">
                        <label>Username</label>
                        <input v-model="editForm.nama" type="text" class="form-control">
                    </div>
                    <div class="form-group">
                        <label>Role</label>
                        <Select2Input v-model="editForm.role" :options="roles" placeholder="Pilih role" />
                    </div>
                    <div class="form-group">
                        <label>Status</label>
                        <Select2Input v-model="editForm.status" :options="statuses" placeholder="Pilih status" />
                    </div>
                    <div class="form-group">
                        <label>Password Baru</label>
                        <input v-model="editForm.password" type="password" class="form-control" placeholder="kosongkan jika tidak diubah">
                    </div>
                    <div class="form-group">
                        <label>Konfirmasi Password Baru</label>
                        <input v-model="editForm.password_confirmation" type="password" class="form-control">
                    </div>
                    <div class="d-flex flex-wrap">
                        <button type="button" class="btn btn-warning mr-2 mb-2" :disabled="editForm.processing" @click="submitEdit">Simpan</button>
                        <button type="button" class="btn btn-secondary mb-2" @click="clearSelection">Batal</button>
                    </div>
                </div>
                <div v-else class="card-body text-muted">Pilih user dari tabel untuk mulai edit.</div>
            </div>
        </div>

        <div class="col-lg-8">
            <div class="card card-outline card-success">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h3 class="card-title">Daftar User</h3>
                    <div class="d-flex align-items-center">
                        <input v-model="searchForm.search" type="text" class="form-control form-control-sm mr-2" placeholder="Cari username">
                        <button type="button" class="btn btn-sm btn-outline-primary" @click="submitSearch">Cari</button>
                    </div>
                </div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>ID</th><th>Username</th><th>Role</th><th>Status</th><th>Created At</th><th>Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="user in users" :key="user.id_user">
                                <td>{{ user.id_user }}</td>
                                <td>
                                    <button type="button" class="btn btn-link p-0 font-weight-bold text-left" @click="selectUser(user)">{{ user.nama }}</button>
                                </td>
                                <td><span class="text-dark text-capitalize font-weight-bold">{{ user.role }}</span></td>
                                <td><span class="text-dark font-weight-bold">{{ user.status }}</span></td>
                                <td>{{ user.created_at }}</td>
                                <td>
                                    <button type="button" class="btn btn-xs btn-warning mr-1" @click="selectUser(user)">Edit</button>
                                    <button type="button" class="btn btn-xs btn-danger" @click="removeUser(user)">Hapus</button>
                                </td>
                            </tr>
                            <tr v-if="!users.length"><td colspan="6" class="text-center text-muted">Belum ada user.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <div class="card card-outline card-info" v-if="selectedUser">
                <div class="card-header"><h3 class="card-title">Ringkasan User Terpilih</h3></div>
                <div class="card-body">
                    <p><strong>ID:</strong> {{ selectedUser.id_user }}</p>
                    <p><strong>Username:</strong> {{ selectedUser.nama }}</p>
                    <p><strong>Role:</strong> {{ selectedUser.role }}</p>
                    <p><strong>Status:</strong> {{ selectedUser.status }}</p>
                    <p class="mb-0"><strong>Dibuat:</strong> {{ selectedUser.created_at }}</p>
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

const props = defineProps({ filters: Object, users: Array, roles: Array, statuses: Array });
const searchForm = useForm({ search: props.filters.search ?? '' });
const createForm = useForm({ nama: '', role: 'admin', status: 'aktif', password: '', password_confirmation: '' });
const editForm = useForm({ id_user: null, nama: '', role: 'admin', status: 'aktif', password: '', password_confirmation: '' });
const selectedUser = computed(() => props.users.find((item) => item.id_user === editForm.id_user) ?? null);

const submitSearch = () => searchForm.get('/users', { preserveState: true, preserveScroll: true, replace: true });
const submitCreate = () => createForm.post('/users', { preserveScroll: true, onSuccess: () => createForm.reset() });
const selectUser = (user) => {
    editForm.id_user = user.id_user;
    editForm.nama = user.nama;
    editForm.role = user.role;
    editForm.status = user.status;
    editForm.password = '';
    editForm.password_confirmation = '';
};
const clearSelection = () => {
    editForm.reset();
    editForm.id_user = null;
};
const submitEdit = () => editForm.put(`/users/${editForm.id_user}`, { preserveScroll: true, onSuccess: () => clearSelection() });
const removeUser = (user) => {
    if (!window.confirm(`Hapus user ${user.nama}?`)) return;
    router.delete(`/users/${user.id_user}`, { preserveScroll: true });
};
</script>
