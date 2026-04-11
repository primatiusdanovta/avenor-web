<template>
    <AppLayout title="Users">
        <Head title="Users" />

        <template #actions>
            <button v-if="canManageUsers" type="button" class="btn btn-primary" @click="openCreateModal">Tambah User</button>
        </template>

        <div class="card card-outline card-success">
            <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                <h3 class="card-title mb-0">Daftar User</h3>
                <div class="d-flex align-items-center flex-wrap gap-2">
                    <select v-model="searchForm.role_id" class="form-select form-select-sm">
                        <option :value="null">Semua role</option>
                        <option v-for="role in roleOptions" :key="role.value" :value="role.value">{{ role.label }}</option>
                    </select>
                    <input v-model="searchForm.search" type="text" class="form-control form-control-sm" placeholder="Cari username">
                    <button type="button" class="btn btn-sm btn-outline-primary" @click="submitSearch">Cari</button>
                </div>
            </div>
            <div class="card-body table-responsive p-0">
                <table class="table table-hover mb-0">
                    <thead><tr><th>ID</th><th>Username</th><th>Role Checklist</th><th>Stores</th><th>Status</th><th>Created At</th><th v-if="canManageUsers">Aksi</th></tr></thead>
                    <tbody>
                        <tr v-for="user in users" :key="user.id_user">
                            <td>{{ user.id_user }}</td>
                            <td>{{ user.nama }}</td>
                            <td>
                                <div class="fw-semibold">{{ user.role_label }}</div>
                                <div class="small text-muted">{{ user.role }}</div>
                            </td>
                            <td>{{ user.stores.map((store) => store.display_name).join(', ') }}</td>
                            <td>{{ user.status }}</td>
                            <td>{{ user.created_at }}</td>
                            <td v-if="canManageUsers" class="d-flex gap-2">
                                <button type="button" class="btn btn-sm btn-warning" @click="openEditModal(user)">Edit</button>
                                <button type="button" class="btn btn-sm btn-danger" @click="removeUser(user)">Hapus</button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <BootstrapModal :show="showCreateModal" title="Tambah User" size="xl" @close="closeCreateModal">
            <UserForm :form="createForm" :roles="roles" :store-options="storeOptions" :statuses="statuses" :can-assign-stores="canAssignStores" />
            <template #footer>
                <button type="button" class="btn btn-secondary" @click="closeCreateModal">Batal</button>
                <button type="button" class="btn btn-primary" :disabled="createForm.processing" @click="submitCreate">Simpan</button>
            </template>
        </BootstrapModal>

        <BootstrapModal :show="showEditModal" title="Edit User" size="xl" @close="closeEditModal">
            <UserForm :form="editForm" :roles="roles" :store-options="storeOptions" :statuses="statuses" :is-edit="true" :can-assign-stores="canAssignStores" />
            <template #footer>
                <button type="button" class="btn btn-secondary" @click="closeEditModal">Batal</button>
                <button type="button" class="btn btn-warning" :disabled="editForm.processing" @click="submitEdit">Simpan</button>
            </template>
        </BootstrapModal>
    </AppLayout>
</template>

<script setup>
import { computed, h, ref } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';
import { adminUrl } from '../../utils/admin';

const props = defineProps({ filters: Object, users: Array, roles: Array, roleOptions: Array, storeOptions: Array, statuses: Array, canManageUsers: Boolean, canAssignStores: Boolean });
const searchForm = useForm({ search: props.filters.search ?? '', role_id: props.filters.role_id ?? null });
const showCreateModal = ref(false);
const showEditModal = ref(false);
const deleteTarget = ref(null);

const createForm = useForm({ nama: '', permission_role_id: props.roles[0]?.id ?? null, store_ids: [], status: 'aktif', password: '', password_confirmation: '' });
const editForm = useForm({ id_user: null, nama: '', permission_role_id: props.roles[0]?.id ?? null, store_ids: [], status: 'aktif', password: '', password_confirmation: '' });

const selectedRolePermissions = (form) => computed(() => props.roles.find((role) => role.id === Number(form.permission_role_id))?.permissions ?? []);

const UserForm = {
    props: ['form', 'roles', 'storeOptions', 'statuses', 'isEdit', 'canAssignStores'],
    setup(componentProps) {
        const permissions = computed(() => componentProps.roles.find((role) => role.id === Number(componentProps.form.permission_role_id))?.permissions ?? []);
        const roleInfo = computed(() => componentProps.roles.find((role) => role.id === Number(componentProps.form.permission_role_id)) ?? null);
        const toggleStore = (storeId) => {
            const current = componentProps.form.store_ids || [];
            componentProps.form.store_ids = current.includes(storeId)
                ? current.filter((item) => item !== storeId)
                : [...current, storeId];
        };

        return () => h('div', { class: 'row g-3' }, [
            h('div', { class: 'col-md-6' }, [h('label', { class: 'form-label' }, 'Username'), h('input', { class: 'form-control', value: componentProps.form.nama, onInput: (event) => componentProps.form.nama = event.target.value })]),
            h('div', { class: 'col-md-6' }, [h('label', { class: 'form-label' }, 'Status'), h('select', { class: 'form-select', value: componentProps.form.status, onChange: (event) => componentProps.form.status = event.target.value }, componentProps.statuses.map((status) => h('option', { value: status }, status)))]),
            h('div', { class: 'col-md-6' }, [h('label', { class: 'form-label' }, 'Role Checklist'), h('select', { class: 'form-select', value: componentProps.form.permission_role_id, onChange: (event) => componentProps.form.permission_role_id = Number(event.target.value) }, componentProps.roles.map((role) => h('option', { value: role.id }, `${role.name} | ${role.legacy_role}`))), roleInfo.value ? h('div', { class: 'small text-muted mt-1' }, roleInfo.value.description || '-') : null]),
            componentProps.canAssignStores
                ? h('div', { class: 'col-md-6' }, [h('label', { class: 'form-label d-block' }, 'Store Access'), ...componentProps.storeOptions.map((store) => h('label', { class: 'form-check d-flex gap-2 align-items-center mb-2' }, [h('input', { class: 'form-check-input', type: 'checkbox', checked: componentProps.form.store_ids.includes(store.value), onChange: () => toggleStore(store.value) }), h('span', { class: 'form-check-label' }, store.label)]))])
                : null,
            h('div', { class: 'col-md-6' }, [h('label', { class: 'form-label' }, componentProps.isEdit ? 'Password Baru' : 'Password'), h('input', { class: 'form-control', type: 'password', value: componentProps.form.password, onInput: (event) => componentProps.form.password = event.target.value })]),
            h('div', { class: 'col-md-6' }, [h('label', { class: 'form-label' }, componentProps.isEdit ? 'Konfirmasi Password Baru' : 'Konfirmasi Password'), h('input', { class: 'form-control', type: 'password', value: componentProps.form.password_confirmation, onInput: (event) => componentProps.form.password_confirmation = event.target.value })]),
            h('div', { class: 'col-12' }, [
                h('div', { class: 'card' }, [
                    h('div', { class: 'card-header fw-semibold' }, 'Checklist Akses Role Terpilih'),
                    h('div', { class: 'card-body' }, permissions.value.length
                        ? permissions.value.map((permission) => h('label', { class: 'form-check d-flex gap-2 align-items-center mb-2' }, [h('input', { class: 'form-check-input', type: 'checkbox', checked: true, disabled: true }), h('span', { class: 'form-check-label' }, permission)]))
                        : [h('div', { class: 'text-muted' }, 'Belum ada akses di role ini.')]),
                ]),
            ]),
        ]);
    },
};

const submitSearch = () => searchForm.get(adminUrl('/users'), { preserveState: true, preserveScroll: true, replace: true });
const openCreateModal = () => {
    createForm.reset();
    createForm.permission_role_id = props.roles[0]?.id ?? null;
    createForm.store_ids = props.storeOptions.length ? [props.storeOptions[0].value] : [];
    showCreateModal.value = true;
};
const closeCreateModal = () => { showCreateModal.value = false; createForm.reset(); createForm.store_ids = []; };
const submitCreate = () => createForm.post(adminUrl('/users'), { preserveScroll: true, onSuccess: () => closeCreateModal() });
const openEditModal = (user) => {
    editForm.id_user = user.id_user;
    editForm.nama = user.nama;
    editForm.permission_role_id = user.role_id;
    editForm.store_ids = user.stores.map((store) => store.id);
    editForm.status = user.status;
    editForm.password = '';
    editForm.password_confirmation = '';
    showEditModal.value = true;
};
const closeEditModal = () => { showEditModal.value = false; editForm.reset(); editForm.id_user = null; editForm.store_ids = []; };
const submitEdit = () => editForm.put(adminUrl(`/users/${editForm.id_user}`), { preserveScroll: true, onSuccess: () => closeEditModal() });
const removeUser = (user) => router.delete(adminUrl(`/users/${user.id_user}`), { preserveScroll: true });
</script>
