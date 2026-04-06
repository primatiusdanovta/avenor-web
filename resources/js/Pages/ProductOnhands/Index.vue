<template>
    <AppLayout>
    <Head title="Barang Onhand" />

    <template #actions>
        <button type="button" class="btn btn-primary" @click="openCreateModal">
            <i class="fas fa-plus mr-1"></i>
            Tambah Onhand
        </button>
    </template>

    <div class="row">
        <div class="col-12">
            <div v-if="saveFeedback" class="alert alert-success">
                {{ saveFeedback }}
            </div>
            <div class="card card-outline card-secondary">
                <div class="card-header"><h3 class="card-title">Filter Barang Onhand</h3></div>
                <div class="card-body">
                    <form class="row align-items-end" @submit.prevent="submitFilters">
                        <div class="col-md-4 mb-3 mb-md-0">
                            <label class="mb-1">Cari</label>
                            <input v-model="filterForm.search" type="text" class="form-control" placeholder="Cari marketing atau product">
                        </div>
                        <div class="col-md-4 mb-3 mb-md-0">
                            <label class="mb-1">Marketing / Reseller</label>
                            <Select2Input v-model="filterForm.user_id" :options="users" value-key="id_user" label-key="option_label" placeholder="Semua user" />
                        </div>
                        <div class="col-md-3 mb-3 mb-md-0">
                            <label class="mb-1">Status Ambil</label>
                            <Select2Input v-model="filterForm.take_status" :options="takeStatuses" value-key="value" label-key="label" placeholder="Semua status" />
                        </div>
                        <div class="col-md-1">
                            <button class="btn btn-outline-primary w-100" type="submit">Terapkan</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-12">
            <div class="card card-outline card-info">
                <div class="card-header"><h3 class="card-title">Daftar Barang Onhand</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Tanggal</th>
                                <th>User</th>
                                <th>Product</th>
                                <th>Dibawa</th>
                                <th>Terjual</th>
                                <th>Sisa</th>
                                <th>Status Ambil</th>
                                <th>Status Return</th>
                                <th>Sales</th>
                                <th class="action-column">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="item in onhands" :key="item.id_product_onhand">
                                <td>{{ item.assignment_date }}</td>
                                <td>
                                    <div class="font-weight-bold">{{ item.user_name || '-' }}</div>
                                    <div class="small text-muted">{{ item.user_role || '-' }}</div>
                                </td>
                                <td>{{ item.nama_product }}</td>
                                <td>
                                    {{ displayQuantity(item) }}
                                    <div v-if="hasPendingQuantityChange(item)" class="small text-primary">
                                        Draft dari {{ item.quantity }}
                                    </div>
                                    <div v-if="quantityDelta(item) !== 0" class="small" :class="quantityDelta(item) > 0 ? 'text-success' : 'text-danger'">
                                        {{ formatDelta(quantityDelta(item)) }}
                                    </div>
                                </td>
                                <td>
                                    {{ displaySoldQuantity(item) }}
                                    <div v-if="item.actual_sold_quantity > 0" class="small text-muted">
                                        Penjualan asli {{ item.actual_sold_quantity }}
                                    </div>
                                    <div v-if="item.manual_sold_quantity > 0" class="small text-info">
                                        Koreksi {{ item.manual_sold_quantity }}
                                    </div>
                                    <div v-if="hasPendingSoldChange(item)" class="small text-primary">
                                        Draft dari {{ item.sold_quantity }}
                                    </div>
                                    <div v-if="soldDelta(item) !== 0" class="small" :class="soldDelta(item) > 0 ? 'text-success' : 'text-danger'">
                                        {{ formatDelta(soldDelta(item)) }}
                                    </div>
                                </td>
                                <td>{{ item.take_status === 'disetujui' ? displayRemaining(item) : '-' }}</td>
                                <td>
                                    <span class="badge status-badge" :class="takeStatusBadgeClass(item.take_status)">
                                        {{ item.take_status_label }}
                                    </span>
                                </td>
                                <td>
                                    <span class="badge status-badge" :class="returnStatusBadgeClass(item.return_status)">
                                        {{ item.return_status_label }}
                                    </span>
                                </td>
                                <td>{{ item.sales_count }}</td>
                                <td>
                                    <div class="action-group">
                                        <button type="button" class="btn btn-xs btn-outline-secondary" :disabled="displayQuantity(item) <= 1" @click="adjustQuantity(item, -1)">
                                            <i class="fas fa-minus mr-1"></i>
                                            Bawa -1
                                        </button>
                                        <button type="button" class="btn btn-xs btn-outline-primary" @click="adjustQuantity(item, 1)">
                                            <i class="fas fa-plus mr-1"></i>
                                            Bawa +1
                                        </button>
                                        <button type="button" class="btn btn-xs btn-outline-secondary" :disabled="!canDecreaseSold(item)" @click="adjustSoldQuantity(item, -1)">
                                            <i class="fas fa-minus mr-1"></i>
                                            Jual -1
                                        </button>
                                        <button type="button" class="btn btn-xs btn-outline-primary" :disabled="!canIncreaseSold(item)" @click="adjustSoldQuantity(item, 1)">
                                            <i class="fas fa-plus mr-1"></i>
                                            Jual +1
                                        </button>
                                        <button type="button" class="btn btn-xs btn-success" :disabled="!hasPendingQuantityChange(item)" @click="saveAdjustedQuantity(item)">
                                            <i class="fas fa-save mr-1"></i>
                                            Simpan Bawa
                                        </button>
                                        <button type="button" class="btn btn-xs btn-success" :disabled="!hasPendingSoldChange(item)" @click="saveAdjustedSoldQuantity(item)">
                                            <i class="fas fa-save mr-1"></i>
                                            Simpan Jual
                                        </button>
                                        <button type="button" class="btn btn-xs btn-outline-dark" :disabled="!hasPendingQuantityChange(item)" @click="resetAdjustedQuantity(item)">
                                            <i class="fas fa-undo mr-1"></i>
                                            Reset Bawa
                                        </button>
                                        <button type="button" class="btn btn-xs btn-outline-dark" :disabled="!hasPendingSoldChange(item)" @click="resetAdjustedSoldQuantity(item)">
                                            <i class="fas fa-undo mr-1"></i>
                                            Reset Jual
                                        </button>
                                        <button type="button" class="btn btn-xs btn-warning" @click="openEditModal(item)">
                                            <i class="fas fa-pen mr-1"></i>
                                            Edit
                                        </button>
                                        <button type="button" class="btn btn-xs btn-outline-danger" :disabled="!item.can_delete" @click="removeOnhand(item)">
                                            <i class="fas fa-trash-alt mr-1"></i>
                                            Hapus
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="!onhands.length">
                                <td colspan="10" class="text-center text-muted py-4">Belum ada barang onhand.</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showCreateModal" title="Tambah Barang Onhand" size="lg" @close="closeCreateModal">
        <div class="crud-modal-body">
            <div class="form-group mb-0">
                <label>User</label>
                <Select2Input v-model="createForm.user_id" :options="users" value-key="id_user" label-key="option_label" placeholder="Pilih marketing / reseller" />
            </div>
            <div class="form-group mb-0">
                <label>Product</label>
                <Select2Input v-model="createForm.id_product" :options="products" value-key="id_product" label-key="option_label" placeholder="Pilih product" />
            </div>
            <div class="form-group mb-0">
                <label>Quantity</label>
                <input v-model="createForm.quantity" type="number" min="1" class="form-control">
            </div>
            <div class="form-group mb-0">
                <label>Tanggal Onhand</label>
                <input v-model="createForm.assignment_date" type="date" class="form-control">
            </div>
            <div class="form-group mb-0">
                <label>Status Ambil</label>
                <Select2Input v-model="createForm.take_status" :options="takeStatuses" value-key="value" label-key="label" placeholder="Pilih status ambil" />
            </div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeCreateModal">Batal</button>
            <button type="button" class="btn btn-primary" :disabled="createForm.processing" @click="submitCreate">Simpan</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showEditModal" title="Edit Barang Onhand" size="lg" @close="closeEditModal">
        <div class="crud-modal-body">
            <div class="form-group mb-0">
                <label>User</label>
                <Select2Input v-model="editForm.user_id" :options="users" value-key="id_user" label-key="option_label" placeholder="Pilih marketing / reseller" />
            </div>
            <div class="form-group mb-0">
                <label>Product</label>
                <Select2Input v-model="editForm.id_product" :options="products" value-key="id_product" label-key="option_label" placeholder="Pilih product" />
            </div>
            <div class="form-group mb-0">
                <label>Quantity</label>
                <input v-model="editForm.quantity" type="number" min="1" class="form-control">
            </div>
            <div class="form-group mb-0">
                <label>Tanggal Onhand</label>
                <input v-model="editForm.assignment_date" type="date" class="form-control">
            </div>
            <div class="form-group mb-0">
                <label>Status Ambil</label>
                <Select2Input v-model="editForm.take_status" :options="takeStatuses" value-key="value" label-key="label" placeholder="Pilih status ambil" />
            </div>
            <div v-if="editingItem" class="alert alert-light mb-0">
                <div><strong>Terjual:</strong> {{ editingItem.sold_quantity }}</div>
                <div><strong>Penjualan asli:</strong> {{ editingItem.actual_sold_quantity }}</div>
                <div><strong>Koreksi manual:</strong> {{ editingItem.manual_sold_quantity }}</div>
                <div><strong>Return pending:</strong> {{ editingItem.quantity_dikembalikan }}</div>
                <div><strong>Return disetujui:</strong> {{ editingItem.approved_return_quantity }}</div>
                <div><strong>Jumlah penjualan terkait:</strong> {{ editingItem.sales_count }}</div>
            </div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeEditModal">Batal</button>
            <button type="button" class="btn btn-warning" :disabled="editForm.processing || !editForm.id_product_onhand" @click="submitEdit">Update</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        {{ deleteMessage }}
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeDeleteModal">Batal</button>
            <button type="button" class="btn btn-danger" @click="confirmDelete">Hapus</button>
        </template>
    </BootstrapModal>

    </AppLayout>
</template>

<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';
import Select2Input from '../../Components/Select2Input.vue';
import { adminUrl } from '../../utils/admin';

const props = defineProps({
    filters: Object,
    users: Array,
    products: Array,
    onhands: Array,
    takeStatuses: Array,
});

const today = new Date().toISOString().slice(0, 10);
const buildFilterParams = () => ({
    search: filterForm.search || undefined,
    user_id: filterForm.user_id || undefined,
    take_status: filterForm.take_status || undefined,
});

const filterForm = useForm({
    search: props.filters?.search ?? '',
    user_id: props.filters?.user_id ? String(props.filters.user_id) : '',
    take_status: props.filters?.take_status ?? '',
});

const createForm = useForm({
    user_id: props.filters?.user_id ? String(props.filters.user_id) : '',
    id_product: '',
    quantity: 1,
    assignment_date: today,
    take_status: 'disetujui',
    search: props.filters?.search ?? '',
    take_status_filter: props.filters?.take_status ?? '',
});

const editForm = useForm({
    id_product_onhand: null,
    user_id: '',
    id_product: '',
    quantity: 1,
    assignment_date: today,
    take_status: 'disetujui',
    search: props.filters?.search ?? '',
    take_status_filter: props.filters?.take_status ?? '',
});

const showCreateModal = ref(false);
const showEditModal = ref(false);
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const editingItem = ref(null);
const draftQuantities = reactive({});
const draftSoldQuantities = reactive({});
const saveFeedback = ref('');
let saveFeedbackTimeoutId = null;

watch(() => props.filters, (filters) => {
    filterForm.search = filters?.search ?? '';
    filterForm.user_id = filters?.user_id ? String(filters.user_id) : '';
    filterForm.take_status = filters?.take_status ?? '';
}, { deep: true });

const deleteMessage = computed(() => {
    if (!deleteTarget.value) return 'Hapus barang onhand ini?';
    return `Hapus barang onhand ${deleteTarget.value.nama_product} milik ${deleteTarget.value.user_name}?`;
});

const submitFilters = () => router.get(adminUrl('/product-onhands'), buildFilterParams(), {
    preserveScroll: true,
    preserveState: true,
    replace: true,
});

const openCreateModal = () => {
    createForm.reset();
    createForm.user_id = props.filters?.user_id ? String(props.filters.user_id) : '';
    createForm.id_product = '';
    createForm.quantity = 1;
    createForm.assignment_date = today;
    createForm.take_status = 'disetujui';
    createForm.search = filterForm.search || '';
    createForm.take_status_filter = filterForm.take_status || '';
    showCreateModal.value = true;
};

const closeCreateModal = () => {
    showCreateModal.value = false;
    createForm.reset();
};

const submitCreate = () => createForm.post(adminUrl('/product-onhands'), {
    preserveScroll: true,
    onSuccess: () => closeCreateModal(),
});

const openEditModal = (item) => {
    editingItem.value = item;
    editForm.id_product_onhand = item.id_product_onhand;
    editForm.user_id = String(item.user_id);
    editForm.id_product = String(item.id_product);
    editForm.quantity = item.quantity;
    editForm.assignment_date = item.assignment_date;
    editForm.take_status = item.take_status;
    editForm.search = filterForm.search || '';
    editForm.take_status_filter = filterForm.take_status || '';
    showEditModal.value = true;
};

const closeEditModal = () => {
    showEditModal.value = false;
    editingItem.value = null;
    editForm.reset();
    editForm.id_product_onhand = null;
};

const submitEdit = () => editForm.put(adminUrl(`/product-onhands/${editForm.id_product_onhand}`), {
    preserveScroll: true,
    onSuccess: () => closeEditModal(),
});

const clearSaveFeedback = () => {
    if (saveFeedbackTimeoutId) {
        clearTimeout(saveFeedbackTimeoutId);
        saveFeedbackTimeoutId = null;
    }

    saveFeedback.value = '';
};

const showSaveFeedback = (message) => {
    clearSaveFeedback();
    saveFeedback.value = message;
    saveFeedbackTimeoutId = setTimeout(() => {
        saveFeedback.value = '';
        saveFeedbackTimeoutId = null;
    }, 2500);
};

const adjustQuantity = (item, delta) => {
    clearSaveFeedback();
    const currentQuantity = Number(draftQuantities[item.id_product_onhand] ?? item.quantity ?? 0);
    const nextQuantity = currentQuantity + delta;
    if (nextQuantity < 1) return;

    draftQuantities[item.id_product_onhand] = nextQuantity;
};

const adjustSoldQuantity = (item, delta) => {
    clearSaveFeedback();
    const currentSoldQuantity = Number(draftSoldQuantities[item.id_product_onhand] ?? item.sold_quantity ?? 0);
    const nextSoldQuantity = currentSoldQuantity + delta;
    if (nextSoldQuantity < Number(item.minimum_sold_quantity ?? 0)) return;
    if (nextSoldQuantity > Number(item.maximum_sold_quantity ?? 0)) return;

    draftSoldQuantities[item.id_product_onhand] = nextSoldQuantity;
};

const hasPendingQuantityChange = (item) =>
    Number(draftQuantities[item.id_product_onhand] ?? item.quantity ?? 0) !== Number(item.quantity ?? 0);

const hasPendingSoldChange = (item) =>
    Number(draftSoldQuantities[item.id_product_onhand] ?? item.sold_quantity ?? 0) !== Number(item.sold_quantity ?? 0);

const displayQuantity = (item) =>
    Number(draftQuantities[item.id_product_onhand] ?? item.quantity ?? 0);

const displaySoldQuantity = (item) =>
    Number(draftSoldQuantities[item.id_product_onhand] ?? item.sold_quantity ?? 0);

const quantityDelta = (item) =>
    displayQuantity(item) - Number(item.quantity ?? 0);

const soldDelta = (item) =>
    displaySoldQuantity(item) - Number(item.sold_quantity ?? 0);

const formatDelta = (delta) => {
    if (delta === 0) return '';
    return `${delta > 0 ? '+' : ''}${delta}`;
};

const displayRemaining = (item) => {
    const nextQuantity = displayQuantity(item);
    const nextSoldQuantity = displaySoldQuantity(item);

    return Math.max(
        nextQuantity -
        nextSoldQuantity -
        Number(item.approved_return_quantity || 0) -
        Number(item.pending_return_quantity || item.quantity_dikembalikan || 0),
        0,
    );
};

const canDecreaseSold = (item) =>
    item.take_status === 'disetujui'
    && displaySoldQuantity(item) > Number(item.minimum_sold_quantity ?? 0);

const canIncreaseSold = (item) =>
    item.take_status === 'disetujui'
    && displaySoldQuantity(item) < Number(item.maximum_sold_quantity ?? 0);

const resetAdjustedQuantity = (item) => {
    clearSaveFeedback();
    delete draftQuantities[item.id_product_onhand];
};

const resetAdjustedSoldQuantity = (item) => {
    clearSaveFeedback();
    delete draftSoldQuantities[item.id_product_onhand];
};

const saveAdjustedQuantity = (item) => {
    const nextQuantity = displayQuantity(item);
    if (nextQuantity < 1 || !hasPendingQuantityChange(item)) return;

    router.put(adminUrl(`/product-onhands/${item.id_product_onhand}`), {
        user_id: item.user_id,
        id_product: item.id_product,
        quantity: nextQuantity,
        assignment_date: item.assignment_date,
        take_status: item.take_status,
        search: filterForm.search || '',
        take_status_filter: filterForm.take_status || '',
    }, {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => {
            const delta = nextQuantity - Number(item.quantity ?? 0);
            resetAdjustedQuantity(item);
            showSaveFeedback(`Quantity ${item.nama_product} berhasil diperbarui ${delta > 0 ? `(+${delta})` : `(${delta})`}.`);
        },
    });
};

const saveAdjustedSoldQuantity = (item) => {
    const nextSoldQuantity = displaySoldQuantity(item);
    if (!hasPendingSoldChange(item)) return;

    router.put(adminUrl(`/product-onhands/${item.id_product_onhand}/sold-quantity`), {
        sold_quantity: nextSoldQuantity,
        search: filterForm.search || '',
        user_id: filterForm.user_id || '',
        take_status_filter: filterForm.take_status || '',
    }, {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => {
            const delta = nextSoldQuantity - Number(item.sold_quantity ?? 0);
            resetAdjustedSoldQuantity(item);
            showSaveFeedback(`Barang terjual ${item.nama_product} berhasil diperbarui ${delta > 0 ? `(+${delta})` : `(${delta})`}.`);
        },
    });
};

const removeOnhand = (item) => {
    if (!item.can_delete) return;
    deleteTarget.value = item;
    showDeleteModal.value = true;
};

const closeDeleteModal = () => {
    showDeleteModal.value = false;
    deleteTarget.value = null;
};

const confirmDelete = () => {
    if (!deleteTarget.value) return;

    router.delete(adminUrl(`/product-onhands/${deleteTarget.value.id_product_onhand}`), {
        preserveScroll: true,
        data: buildFilterParams(),
        onSuccess: () => closeDeleteModal(),
    });
};

const takeStatusBadgeClass = (status) => ({
    pending: 'badge-warning-soft text-warning-emphasis',
    ditolak: 'badge-danger-soft text-danger-emphasis',
    disetujui: 'badge-success-soft text-success-emphasis',
}[status] || 'badge-secondary-soft text-secondary-emphasis');

const returnStatusBadgeClass = (status) => ({
    pending: 'badge-warning-soft text-warning-emphasis',
    disetujui: 'badge-success-soft text-success-emphasis',
    tidak_disetujui: 'badge-danger-soft text-danger-emphasis',
    belum: 'badge-secondary-soft text-secondary-emphasis',
}[status] || 'badge-secondary-soft text-secondary-emphasis');
</script>

<style scoped>
.crud-modal-body {
    display: grid;
    gap: 1rem;
}

.action-column {
    min-width: 280px;
}

.action-group {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 0.45rem;
}

.action-group .btn {
    width: 100%;
}

.status-badge {
    border-radius: 999px;
    padding: 0.45rem 0.7rem;
    font-weight: 600;
}

.badge-warning-soft { background: #fff3cd; }
.badge-success-soft { background: #d1e7dd; }
.badge-danger-soft { background: #f8d7da; }
.badge-secondary-soft { background: #e2e3e5; }

@media (max-width: 576px) {
    .action-group {
        grid-template-columns: 1fr;
    }
}
</style>
