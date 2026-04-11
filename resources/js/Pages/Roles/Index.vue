<template>
    <AppLayout title="Roles">
        <Head title="Roles" />

        <template #actions>
            <button v-if="canManage" type="button" class="btn btn-primary" @click="openCreateModal">Tambah Role</button>
        </template>

        <div class="card card-outline card-success">
            <div class="card-header"><h3 class="card-title mb-0">Role Checklist</h3></div>
            <div class="card-body table-responsive p-0">
                <table class="table table-hover mb-0">
                    <thead><tr><th>Nama</th><th>Legacy Role</th><th>Deskripsi</th><th>Jumlah Akses</th><th v-if="canManage">Aksi</th></tr></thead>
                    <tbody>
                        <tr v-for="role in roles" :key="role.id">
                            <td>{{ role.name }}</td>
                            <td>{{ role.legacy_role }}</td>
                            <td>{{ role.description || '-' }}</td>
                            <td>{{ role.permissions.length }}</td>
                            <td v-if="canManage" class="d-flex gap-2">
                                <button type="button" class="btn btn-sm btn-warning" @click="openEditModal(role)">Edit</button>
                                <button type="button" class="btn btn-sm btn-danger" :disabled="role.is_locked || role.users_count > 0" @click="removeRole(role)">Hapus</button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <BootstrapModal :show="showCreateModal" title="Tambah Role" size="xl" @close="closeCreateModal">
            <RoleForm :form="createForm" :permission-groups="permissionGroups" :legacy-role-options="legacyRoleOptions" />
            <template #footer>
                <button type="button" class="btn btn-secondary" @click="closeCreateModal">Batal</button>
                <button type="button" class="btn btn-primary" :disabled="createForm.processing" @click="submitCreate">Simpan</button>
            </template>
        </BootstrapModal>

        <BootstrapModal :show="showEditModal" title="Edit Role" size="xl" @close="closeEditModal">
            <RoleForm :form="editForm" :permission-groups="permissionGroups" :legacy-role-options="legacyRoleOptions" />
            <template #footer>
                <button type="button" class="btn btn-secondary" @click="closeEditModal">Batal</button>
                <button type="button" class="btn btn-warning" :disabled="editForm.processing" @click="submitEdit">Simpan</button>
            </template>
        </BootstrapModal>
    </AppLayout>
</template>

<script setup>
import { h, ref } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';
import { adminUrl } from '../../utils/admin';

const props = defineProps({ roles: Array, permissionGroups: Object, legacyRoleOptions: Array, canManage: Boolean });
const showCreateModal = ref(false);
const showEditModal = ref(false);

const emptyPermissions = () => [];
const createForm = useForm({ key: '', name: '', legacy_role: 'admin', description: '', permissions: emptyPermissions() });
const editForm = useForm({ id: null, key: '', name: '', legacy_role: 'admin', description: '', permissions: emptyPermissions() });

const RoleForm = {
    props: ['form', 'permissionGroups', 'legacyRoleOptions'],
    setup(componentProps) {
        const togglePermission = (permission) => {
            const current = componentProps.form.permissions || [];
            componentProps.form.permissions = current.includes(permission)
                ? current.filter((item) => item !== permission)
                : [...current, permission];
        };

        return () => h('div', { class: 'row g-3' }, [
            h('div', { class: 'col-md-6' }, [h('label', { class: 'form-label' }, 'Key'), h('input', { class: 'form-control', value: componentProps.form.key, onInput: (event) => componentProps.form.key = event.target.value })]),
            h('div', { class: 'col-md-6' }, [h('label', { class: 'form-label' }, 'Nama Role'), h('input', { class: 'form-control', value: componentProps.form.name, onInput: (event) => componentProps.form.name = event.target.value })]),
            h('div', { class: 'col-md-6' }, [h('label', { class: 'form-label' }, 'Legacy Role'), h('select', { class: 'form-select', value: componentProps.form.legacy_role, onChange: (event) => componentProps.form.legacy_role = event.target.value }, componentProps.legacyRoleOptions.map((option) => h('option', { value: option.value }, option.label)))]),
            h('div', { class: 'col-md-6' }, [h('label', { class: 'form-label' }, 'Deskripsi'), h('input', { class: 'form-control', value: componentProps.form.description, onInput: (event) => componentProps.form.description = event.target.value })]),
            h('div', { class: 'col-12' }, Object.entries(componentProps.permissionGroups).map(([group, permissions]) => h('div', { class: 'card mb-3' }, [
                h('div', { class: 'card-header fw-semibold' }, group),
                h('div', { class: 'card-body row g-2' }, Object.entries(permissions).map(([key, label]) => h('div', { class: 'col-md-6' }, [
                    h('label', { class: 'form-check d-flex gap-2 align-items-start' }, [
                        h('input', { class: 'form-check-input mt-1', type: 'checkbox', checked: componentProps.form.permissions.includes(key), onChange: () => togglePermission(key) }),
                        h('span', { class: 'form-check-label' }, label),
                    ]),
                ]))),
            ]))),
        ]);
    },
};

const openCreateModal = () => {
    createForm.reset();
    createForm.permissions = [];
    showCreateModal.value = true;
};
const closeCreateModal = () => { showCreateModal.value = false; createForm.reset(); createForm.permissions = []; };
const submitCreate = () => createForm.post(adminUrl('/roles'), { preserveScroll: true, onSuccess: () => closeCreateModal() });

const openEditModal = (role) => {
    editForm.id = role.id;
    editForm.key = role.key;
    editForm.name = role.name;
    editForm.legacy_role = role.legacy_role;
    editForm.description = role.description || '';
    editForm.permissions = [...role.permissions];
    showEditModal.value = true;
};
const closeEditModal = () => { showEditModal.value = false; editForm.reset(); editForm.id = null; editForm.permissions = []; };
const submitEdit = () => editForm.put(adminUrl(`/roles/${editForm.id}`), { preserveScroll: true, onSuccess: () => closeEditModal() });
const removeRole = (role) => router.delete(adminUrl(`/roles/${role.id}`), { preserveScroll: true });
</script>