<template>
    <AppLayout>
        <Head title="Notifications" />

        <template #actions>
            <button type="button" class="btn btn-primary" @click="openCreateModal">
                <i class="fas fa-plus mr-1"></i>
                Tambah Notifikasi
            </button>
        </template>

        <div class="row">
            <div class="col-lg-12">
                <div class="card card-outline card-success">
                    <div class="card-header"><h3 class="card-title">Daftar Notifikasi</h3></div>
                    <div class="card-body p-0 table-responsive">
                        <table class="table table-hover mb-0">
                            <thead>
                                <tr>
                                    <th>Judul</th>
                                    <th>Status</th>
                                    <th>Jadwal</th>
                                    <th>Publish</th>
                                    <th>Pembuat</th>
                                    <th class="action-column">Aksi</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="item in notifications" :key="item.id">
                                    <td>
                                        <button type="button" class="btn btn-link p-0 font-weight-bold text-left" @click="openPreview(item)">{{ item.title }}</button>
                                        <div class="text-muted small">{{ item.excerpt }}</div>
                                    </td>
                                    <td>{{ statusLabel(item.status) }}</td>
                                    <td>{{ item.scheduled_at || '-' }}</td>
                                    <td>{{ item.published_at || '-' }}</td>
                                    <td>{{ item.creator_name || '-' }}</td>
                                    <td>
                                        <div class="action-group" :class="item.status === 'published' ? 'action-group--three' : 'action-group--four'">
                                            <button class="btn btn-xs btn-info" @click="openPreview(item)">Preview</button>
                                            <button v-if="item.status !== 'published'" class="btn btn-xs btn-warning" @click="openEditModal(item)">
                                                <i class="fas fa-pen mr-1"></i>
                                                Edit
                                            </button>
                                            <button v-if="item.status === 'scheduled' || item.status === 'draft'" class="btn btn-xs btn-primary" @click="publishNow(item)">Publish</button>
                                            <button class="btn btn-xs btn-danger" @click="removeItem(item)"><i class="fas fa-trash-alt mr-1"></i>Hapus</button>
                                        </div>
                                    </td>
                                </tr>
                                <tr v-if="!notifications.length">
                                    <td colspan="6" class="text-center text-muted py-4">Belum ada notifikasi.</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <BootstrapModal :show="showCreateModal" title="Tambah Notifikasi" size="lg" @close="closeCreateModal">
            <div class="crud-modal-body">
                <div v-if="createErrorMessages.length" class="alert alert-danger mb-0">
                    <div v-for="message in createErrorMessages" :key="`create-${message}`">{{ message }}</div>
                </div>
                <div class="form-group mb-0">
                    <label>Judul</label>
                    <input v-model="createForm.title" type="text" class="form-control" :class="{ 'is-invalid': createForm.errors.title }">
                    <div v-if="createForm.errors.title" class="invalid-feedback d-block">{{ createForm.errors.title }}</div>
                </div>
                <div class="form-group mb-0">
                    <label>Isi Notifikasi</label>
                    <textarea v-model="createForm.body" rows="6" class="form-control" :class="{ 'is-invalid': createForm.errors.body }"></textarea>
                    <div v-if="createForm.errors.body" class="invalid-feedback d-block">{{ createForm.errors.body }}</div>
                </div>
                <div class="form-group mb-0">
                    <label>Target</label>
                    <select v-model="createForm.target_role" class="form-control">
                        <option value="marketing">Marketing App</option>
                    </select>
                </div>
                <div class="form-group mb-0">
                    <label>Tipe Pengiriman</label>
                    <select v-model="createForm.delivery_type" class="form-control">
                        <option value="now">Kirim Sekarang</option>
                        <option value="scheduled">Jadwalkan</option>
                    </select>
                </div>
                <div v-if="createForm.delivery_type === 'scheduled'" class="form-group mb-0">
                    <label>Jadwal Kirim</label>
                    <input v-model="createForm.scheduled_at" type="datetime-local" class="form-control" :class="{ 'is-invalid': createForm.errors.scheduled_at }">
                    <div v-if="createForm.errors.scheduled_at" class="invalid-feedback d-block">{{ createForm.errors.scheduled_at }}</div>
                </div>
            </div>
            <template #footer>
                <button type="button" class="btn btn-secondary" @click="closeCreateModal">Batal</button>
                <button type="button" class="btn btn-primary" :disabled="createForm.processing" @click="submitCreate">Simpan Notifikasi</button>
            </template>
        </BootstrapModal>

        <BootstrapModal :show="showEditModal" title="Edit Notifikasi" size="lg" @close="closeEditModal">
            <div class="crud-modal-body">
                <div v-if="editErrorMessages.length" class="alert alert-danger mb-0">
                    <div v-for="message in editErrorMessages" :key="`edit-${message}`">{{ message }}</div>
                </div>
                <div class="form-group mb-0">
                    <label>Judul</label>
                    <input v-model="editForm.title" type="text" class="form-control" :class="{ 'is-invalid': editForm.errors.title }">
                    <div v-if="editForm.errors.title" class="invalid-feedback d-block">{{ editForm.errors.title }}</div>
                </div>
                <div class="form-group mb-0">
                    <label>Isi Notifikasi</label>
                    <textarea v-model="editForm.body" rows="6" class="form-control" :class="{ 'is-invalid': editForm.errors.body }"></textarea>
                    <div v-if="editForm.errors.body" class="invalid-feedback d-block">{{ editForm.errors.body }}</div>
                </div>
                <div class="form-group mb-0">
                    <label>Target</label>
                    <select v-model="editForm.target_role" class="form-control">
                        <option value="marketing">Marketing App</option>
                    </select>
                </div>
                <div class="form-group mb-0">
                    <label>Tipe Pengiriman</label>
                    <select v-model="editForm.delivery_type" class="form-control">
                        <option value="now">Kirim Sekarang</option>
                        <option value="scheduled">Jadwalkan</option>
                    </select>
                </div>
                <div v-if="editForm.delivery_type === 'scheduled'" class="form-group mb-0">
                    <label>Jadwal Kirim</label>
                    <input v-model="editForm.scheduled_at" type="datetime-local" class="form-control" :class="{ 'is-invalid': editForm.errors.scheduled_at }">
                    <div v-if="editForm.errors.scheduled_at" class="invalid-feedback d-block">{{ editForm.errors.scheduled_at }}</div>
                </div>
            </div>
            <template #footer>
                <button type="button" class="btn btn-secondary" @click="closeEditModal">Batal</button>
                <button type="button" class="btn btn-warning" :disabled="editForm.processing || !editForm.id" @click="submitEdit">Update</button>
            </template>
        </BootstrapModal>

        <BootstrapModal :show="showPreviewModal" title="Preview Notifikasi" size="lg" @close="closePreview">
            <div v-if="previewTarget">
                <h5 class="mb-3">{{ previewTarget.title }}</h5>
                <div class="text-muted small mb-3">Status: {{ statusLabel(previewTarget.status) }}</div>
                <div style="white-space: pre-wrap;">{{ previewTarget.body }}</div>
            </div>
        </BootstrapModal>

        <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDelete">
            Hapus notifikasi {{ deleteTarget?.title }}?
            <template #footer>
                <button type="button" class="btn btn-secondary" @click="closeDelete">Batal</button>
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

const props = defineProps({ notifications: Array });

const createForm = useForm({
    title: '',
    body: '',
    target_role: 'marketing',
    delivery_type: 'now',
    scheduled_at: '',
});
const editForm = useForm({
    id: null,
    title: '',
    body: '',
    target_role: 'marketing',
    delivery_type: 'now',
    scheduled_at: '',
});

const showCreateModal = ref(false);
const showEditModal = ref(false);
const showPreviewModal = ref(false);
const previewTarget = ref(null);
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const createErrorMessages = computed(() => Object.values(createForm.errors || {}));
const editErrorMessages = computed(() => Object.values(editForm.errors || {}));

const statusLabel = (status) => ({
    draft: 'Draft',
    scheduled: 'Terjadwal',
    published: 'Terkirim',
}[status] || status);

const openCreateModal = () => {
    createForm.reset();
    createForm.target_role = 'marketing';
    createForm.delivery_type = 'now';
    showCreateModal.value = true;
};

const closeCreateModal = () => {
    showCreateModal.value = false;
    createForm.reset('title', 'body', 'scheduled_at');
    createForm.target_role = 'marketing';
    createForm.delivery_type = 'now';
};

const submitCreate = () => createForm.post(adminUrl('/notifications'), {
    preserveScroll: true,
    onSuccess: () => closeCreateModal(),
});

const openEditModal = (item) => {
    editForm.id = item.id;
    editForm.title = item.title || '';
    editForm.body = item.body || '';
    editForm.target_role = item.target_role || 'marketing';
    editForm.delivery_type = item.status === 'scheduled' ? 'scheduled' : 'now';
    editForm.scheduled_at = item.scheduled_at || '';
    editForm.clearErrors();
    showEditModal.value = true;
};

const closeEditModal = () => {
    showEditModal.value = false;
    editForm.reset();
    editForm.id = null;
    editForm.target_role = 'marketing';
    editForm.delivery_type = 'now';
};

const submitEdit = () => editForm.put(adminUrl(`/notifications/${editForm.id}`), {
    preserveScroll: true,
    onSuccess: () => closeEditModal(),
});

const openPreview = (item) => {
    previewTarget.value = item;
    showPreviewModal.value = true;
};

const closePreview = () => {
    showPreviewModal.value = false;
    previewTarget.value = null;
};

const publishNow = (item) => router.post(adminUrl(`/notifications/${item.id}/publish`), {}, { preserveScroll: true });

const removeItem = (item) => {
    deleteTarget.value = item;
    showDeleteModal.value = true;
};

const closeDelete = () => {
    showDeleteModal.value = false;
    deleteTarget.value = null;
};

const confirmDelete = () => {
    if (!deleteTarget.value) return;
    const id = deleteTarget.value.id;
    closeDelete();
    router.delete(adminUrl(`/notifications/${id}`), { preserveScroll: true });
};
</script>

<style scoped>
.action-column {
    min-width: 300px;
}

.action-group {
    display: grid;
    gap: 0.45rem;
}

.action-group--three {
    grid-template-columns: repeat(3, minmax(0, 1fr));
}

.action-group--four {
    grid-template-columns: repeat(4, minmax(0, 1fr));
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

@media (max-width: 767.98px) {
    .action-group--four,
    .action-group--three {
        grid-template-columns: 1fr;
    }
}
</style>


