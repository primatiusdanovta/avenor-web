<template>
    <AppLayout>
        <Head title="Account Payables" />

        <template #actions>
            <button type="button" class="btn btn-primary" @click="openCreateModal">
                <i class="fas fa-plus mr-1"></i>
                Tambah Account Payable
            </button>
        </template>

        <div class="row">
            <div class="col-lg-12">
                <div class="card card-outline card-primary">
                    <div class="card-header"><h3 class="card-title">Daftar Account Payables</h3></div>
                    <div class="card-body p-0 table-responsive">
                        <table class="table table-hover mb-0">
                            <thead>
                                <tr>
                                    <th>Account Payable</th>
                                    <th>Tanggal Tempo</th>
                                    <th>Catatan</th>
                                    <th>Dibuat</th>
                                    <th class="action-column">Aksi</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="item in accountPayables" :key="item.id">
                                    <td class="font-weight-bold">{{ item.account_payable }}</td>
                                    <td>{{ item.due_date }}</td>
                                    <td>{{ item.notes || '-' }}</td>
                                    <td>{{ item.created_at || '-' }}</td>
                                    <td>
                                        <div class="action-group">
                                            <button type="button" class="btn btn-xs btn-warning" @click="openEditModal(item)"><i class="fas fa-pen mr-1"></i>Edit</button>
                                            <button type="button" class="btn btn-xs btn-danger" @click="openDeleteModal(item)"><i class="fas fa-trash-alt mr-1"></i>Hapus</button>
                                        </div>
                                    </td>
                                </tr>
                                <tr v-if="!accountPayables.length">
                                    <td colspan="5" class="text-center text-muted py-4">Belum ada account payables.</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <BootstrapModal :show="showFormModal" :title="formMode === 'create' ? 'Tambah Account Payable' : 'Edit Account Payable'" @close="closeFormModal">
            <div class="crud-modal-body">
                <div class="form-group mb-0">
                    <label>Account Payable</label>
                    <input v-model="form.account_payable" type="text" class="form-control" placeholder="Masukkan account payable">
                    <small v-if="form.errors.account_payable" class="text-danger">{{ form.errors.account_payable }}</small>
                </div>
                <div class="form-group mb-0">
                    <label>Tanggal Tempo</label>
                    <input v-model="form.due_date" type="date" class="form-control">
                    <small v-if="form.errors.due_date" class="text-danger">{{ form.errors.due_date }}</small>
                </div>
                <div class="form-group mb-0">
                    <label>Catatan</label>
                    <textarea v-model="form.notes" rows="3" class="form-control" placeholder="Opsional"></textarea>
                    <small v-if="form.errors.notes" class="text-danger">{{ form.errors.notes }}</small>
                </div>
            </div>
            <template #footer>
                <button type="button" class="btn btn-secondary" @click="closeFormModal">Batal</button>
                <button type="button" class="btn btn-primary" :disabled="form.processing" @click="submitForm">{{ formMode === 'create' ? 'Simpan' : 'Update' }}</button>
            </template>
        </BootstrapModal>

        <BootstrapModal :show="showDeleteConfirm" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
            <div>Hapus account payable {{ deleteTarget?.account_payable }}?</div>
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
import BootstrapModal from '../../Components/BootstrapModal.vue';
import { adminUrl } from '../../utils/admin';

defineProps({ accountPayables: Array });

const showFormModal = ref(false);
const showDeleteConfirm = ref(false);
const deleteTarget = ref(null);
const formMode = ref('create');
const editingId = ref(null);
const form = useForm({ account_payable: '', due_date: '', notes: '' });

const resetForm = () => {
    form.reset();
    form.clearErrors();
    editingId.value = null;
    formMode.value = 'create';
};

const openCreateModal = () => {
    resetForm();
    showFormModal.value = true;
};

const openEditModal = (item) => {
    resetForm();
    formMode.value = 'edit';
    editingId.value = item.id;
    form.account_payable = item.account_payable;
    form.due_date = item.due_date;
    form.notes = item.notes || '';
    showFormModal.value = true;
};

const closeFormModal = () => {
    showFormModal.value = false;
    resetForm();
};

const submitForm = () => {
    if (formMode.value === 'create') {
        form.post(adminUrl('/account-payables'), { preserveScroll: true, onSuccess: () => closeFormModal() });
        return;
    }

    form.put(adminUrl(`/account-payables/${editingId.value}`), { preserveScroll: true, onSuccess: () => closeFormModal() });
};

const openDeleteModal = (item) => {
    deleteTarget.value = item;
    showDeleteConfirm.value = true;
};

const closeDeleteModal = () => {
    deleteTarget.value = null;
    showDeleteConfirm.value = false;
};

const confirmDelete = () => {
    if (!deleteTarget.value) return;
    const id = deleteTarget.value.id;
    closeDeleteModal();
    router.delete(adminUrl(`/account-payables/${id}`), { preserveScroll: true });
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


