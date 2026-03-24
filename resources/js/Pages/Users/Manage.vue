<template>
    <Head title="User Management" />

    <div class="stack">
        <section class="panel-grid users-admin-grid">
            <div class="panel-card">
                <div class="panel-head">
                    <div>
                        <h3>Tambah User Baru</h3>
                        <p>Form ini hanya tersedia untuk superadmin.</p>
                    </div>
                </div>

                <form class="stack" @submit.prevent="submitCreate">
                    <label class="field">
                        <span>Username</span>
                        <input v-model="createForm.nama" type="text" placeholder="username baru">
                        <small v-if="createForm.errors.nama" class="field-error">{{ createForm.errors.nama }}</small>
                    </label>

                    <label class="field">
                        <span>Role</span>
                        <select v-model="createForm.role">
                            <option v-for="role in roles" :key="role" :value="role">{{ role }}</option>
                        </select>
                    </label>

                    <label class="field">
                        <span>Status</span>
                        <select v-model="createForm.status">
                            <option v-for="status in statuses" :key="status" :value="status">{{ status }}</option>
                        </select>
                    </label>

                    <label class="field">
                        <span>Password</span>
                        <input v-model="createForm.password" type="password" placeholder="minimal 8 karakter">
                        <small v-if="createForm.errors.password" class="field-error">{{ createForm.errors.password }}</small>
                    </label>

                    <label class="field">
                        <span>Konfirmasi Password</span>
                        <input v-model="createForm.password_confirmation" type="password" placeholder="ulang password">
                    </label>

                    <button type="submit" class="primary-button" :disabled="createForm.processing">
                        {{ createForm.processing ? 'Menyimpan...' : 'Tambah User' }}
                    </button>
                </form>
            </div>

            <div class="panel-card">
                <div class="panel-head">
                    <div>
                        <h3>Edit User</h3>
                        <p>Pilih salah satu user dari tabel untuk diperbarui.</p>
                    </div>
                </div>

                <div v-if="selectedUser" class="stack">
                    <label class="field">
                        <span>Username</span>
                        <input v-model="editForm.nama" type="text">
                    </label>

                    <label class="field">
                        <span>Role</span>
                        <select v-model="editForm.role">
                            <option v-for="role in roles" :key="role" :value="role">{{ role }}</option>
                        </select>
                    </label>

                    <label class="field">
                        <span>Status</span>
                        <select v-model="editForm.status">
                            <option v-for="status in statuses" :key="status" :value="status">{{ status }}</option>
                        </select>
                    </label>

                    <label class="field">
                        <span>Password Baru</span>
                        <input v-model="editForm.password" type="password" placeholder="kosongkan jika tidak diubah">
                    </label>

                    <label class="field">
                        <span>Konfirmasi Password Baru</span>
                        <input v-model="editForm.password_confirmation" type="password">
                    </label>

                    <div class="filter-actions">
                        <button type="button" class="primary-button" @click="submitEdit" :disabled="editForm.processing">Simpan Perubahan</button>
                        <button type="button" class="ghost-button" @click="clearSelection">Batal</button>
                    </div>
                </div>

                <div v-else class="empty-state">
                    Pilih user dari tabel di bawah untuk memulai edit.
                </div>
            </div>
        </section>

        <section class="panel-card">
            <div class="panel-head">
                <div>
                    <h3>Daftar User</h3>
                    <p>CRUD Inertia hanya tersedia untuk superadmin.</p>
                </div>
                <div class="filter-actions">
                    <input v-model="searchForm.search" class="inline-input" type="text" placeholder="Cari username">
                    <button type="button" class="ghost-button" @click="submitSearch">Cari</button>
                </div>
            </div>

            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Username</th>
                            <th>Role</th>
                            <th>Status</th>
                            <th>Created At</th>
                            <th>Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="user in users" :key="user.id_user">
                            <td>{{ user.id_user }}</td>
                            <td>{{ user.nama }}</td>
                            <td>{{ user.role }}</td>
                            <td>{{ user.status }}</td>
                            <td>{{ user.created_at }}</td>
                            <td class="action-row">
                                <button type="button" class="ghost-button" @click="selectUser(user)">Edit</button>
                                <button type="button" class="danger-button" @click="removeUser(user)">Hapus</button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </section>
    </div>
</template>

<script setup>
import { computed } from 'vue';
import { Head, router, useForm, usePage } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    filters: Object,
    users: Array,
    roles: Array,
    statuses: Array,
});

const page = usePage();
const selectedUser = computed(() => props.users.find((item) => item.id_user === editForm.id_user) ?? null);

const searchForm = useForm({ search: props.filters.search ?? '' });
const createForm = useForm({ nama: '', role: 'admin', status: 'aktif', password: '', password_confirmation: '' });
const editForm = useForm({ id_user: null, nama: '', role: 'admin', status: 'aktif', password: '', password_confirmation: '' });

const submitSearch = () => {
    searchForm.get('/users', { preserveState: true, preserveScroll: true, replace: true });
};

const submitCreate = () => {
    createForm.post('/users', {
        preserveScroll: true,
        onSuccess: () => createForm.reset(),
    });
};

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

const submitEdit = () => {
    editForm.put(`/users/${editForm.id_user}`, {
        preserveScroll: true,
        onSuccess: () => clearSelection(),
    });
};

const removeUser = (user) => {
    if (!window.confirm(`Hapus user ${user.nama}?`)) {
        return;
    }

    router.delete(`/users/${user.id_user}`, { preserveScroll: true });
};
</script>