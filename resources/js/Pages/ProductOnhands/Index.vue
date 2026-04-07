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
                <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <h3 class="card-title">Daftar Barang Onhand Per User</h3>
                    <div class="small text-muted">List utama diringkas per user. Detail dan aksi onhand dibuka lewat modal.</div>
                </div>
                <div class="card-body">
                    <div v-if="groupedOnhands.length" class="grouped-onhand-list">
                        <div v-for="group in groupedOnhands" :key="group.user_id" class="onhand-user-card">
                            <div class="onhand-user-card__top">
                                <div>
                                    <div class="onhand-user-card__name">{{ group.user_name }}</div>
                                    <div class="small text-muted">{{ group.user_role }}</div>
                                </div>
                                <div class="onhand-user-card__stats">
                                    <div class="user-stat-pill">
                                        <span>Batch</span>
                                        <strong>{{ group.items.length }}</strong>
                                    </div>
                                    <div class="user-stat-pill">
                                        <span>Dibawa</span>
                                        <strong>{{ group.total_quantity }}</strong>
                                    </div>
                                    <div class="user-stat-pill">
                                        <span>Terjual</span>
                                        <strong>{{ group.total_sold }}</strong>
                                    </div>
                                    <div class="user-stat-pill">
                                        <span>Sisa</span>
                                        <strong>{{ group.total_remaining }}</strong>
                                    </div>
                                </div>
                            </div>
                            <div class="onhand-user-card__bottom">
                                <div class="small text-muted">
                                    Batch terbaru {{ group.latest_assignment_date || '-' }}. Pending approval {{ group.pending_count }}. Return pending {{ group.pending_return_count }}.
                                </div>
                                <button type="button" class="btn btn-outline-primary" @click="openManageModal(group)">
                                    <i class="fas fa-layer-group mr-1"></i>
                                    Kelola Onhand
                                </button>
                            </div>
                        </div>
                    </div>
                    <div v-else class="text-center text-muted py-4">Belum ada barang onhand.</div>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showCreateModal" title="Tambah Barang Onhand" size="lg" @close="closeCreateModal">
        <div class="crud-modal-body">
            <div class="form-group mb-0">
                <label>User</label>
                <Select2Input v-model="createForm.user_id" :options="users" value-key="id_user" label-key="option_label" placeholder="Pilih marketing / sales field executive" />
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
                <Select2Input v-model="editForm.user_id" :options="users" value-key="id_user" label-key="option_label" placeholder="Pilih marketing / sales field executive" />
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

    <BootstrapModal :show="showManageModal" :title="manageModalTitle" size="xl" @close="closeManageModal">
        <div v-if="activeUserGroup" class="manage-onhand-modal">
            <div class="manage-onhand-summary">
                <div class="summary-card"><div class="summary-label">Total Batch</div><div class="summary-value">{{ activeUserGroup.items.length }}</div></div>
                <div class="summary-card"><div class="summary-label">Total Dibawa</div><div class="summary-value">{{ activeUserGroup.total_quantity }}</div></div>
                <div class="summary-card"><div class="summary-label">Total Terjual</div><div class="summary-value">{{ activeUserGroup.total_sold }}</div></div>
                <div class="summary-card"><div class="summary-label">Total Sisa</div><div class="summary-value">{{ activeUserGroup.total_remaining }}</div></div>
            </div>

            <div class="manage-onhand-list">
                <div v-for="item in activeUserGroup.items" :key="item.id_product_onhand" class="manage-onhand-item">
                    <div class="manage-onhand-item__header">
                        <div>
                            <div class="font-weight-bold">{{ item.nama_product }}</div>
                            <div class="small text-muted">Tanggal {{ item.assignment_date }} | Batch {{ item.pickup_batch_code || '-' }}</div>
                        </div>
                        <div class="manage-onhand-item__badges">
                            <span class="badge status-badge" :class="takeStatusBadgeClass(item.take_status)">{{ item.take_status_label }}</span>
                            <span class="badge status-badge" :class="returnStatusBadgeClass(item.return_status)">{{ item.return_status_label }}</span>
                        </div>
                    </div>

                    <div class="manage-onhand-item__grid">
                        <div class="metric-tile">
                            <span>Dibawa</span>
                            <strong>{{ displayQuantity(item) }}</strong>
                            <small v-if="hasPendingQuantityChange(item)" class="text-primary">Draft dari {{ item.quantity }}</small>
                            <small v-else-if="quantityDelta(item) !== 0" :class="quantityDelta(item) > 0 ? 'text-success' : 'text-danger'">{{ formatDelta(quantityDelta(item)) }}</small>
                        </div>
                        <div class="metric-tile">
                            <span>Terjual</span>
                            <strong>{{ displaySoldQuantity(item) }}</strong>
                            <small v-if="hasPendingSoldChange(item)" class="text-primary">Draft dari {{ item.sold_quantity }}</small>
                            <small v-else-if="item.actual_sold_quantity > 0" class="text-muted">Penjualan asli {{ item.actual_sold_quantity }}</small>
                            <small v-else-if="item.manual_sold_quantity > 0" class="text-info">Koreksi {{ item.manual_sold_quantity }}</small>
                        </div>
                        <div class="metric-tile">
                            <span>Sisa</span>
                            <strong>{{ item.take_status === 'disetujui' ? displayRemaining(item) : '-' }}</strong>
                            <small class="text-muted">Sales {{ item.sales_count }}</small>
                        </div>
                        <div class="metric-tile">
                            <span>Retur</span>
                            <strong>{{ Number(item.pending_return_quantity || 0) + Number(item.approved_return_quantity || 0) }}</strong>
                            <small class="text-muted">Pending {{ item.pending_return_quantity }} | Approved {{ item.approved_return_quantity }}</small>
                        </div>
                    </div>

                    <div class="action-group">
                        <button type="button" class="btn btn-xs btn-outline-secondary" :disabled="displayQuantity(item) <= 1" @click="adjustQuantity(item, -1)"><i class="fas fa-minus mr-1"></i>Bawa -1</button>
                        <button type="button" class="btn btn-xs btn-outline-primary" @click="adjustQuantity(item, 1)"><i class="fas fa-plus mr-1"></i>Bawa +1</button>
                        <button type="button" class="btn btn-xs btn-outline-secondary" :disabled="!canDecreaseSold(item)" @click="adjustSoldQuantity(item, -1)"><i class="fas fa-minus mr-1"></i>Jual -1</button>
                        <button type="button" class="btn btn-xs btn-outline-primary" :disabled="!canIncreaseSold(item)" @click="adjustSoldQuantity(item, 1)"><i class="fas fa-plus mr-1"></i>Jual +1</button>
                        <button type="button" class="btn btn-xs btn-success" :disabled="!hasPendingQuantityChange(item)" @click="saveAdjustedQuantity(item)"><i class="fas fa-save mr-1"></i>Simpan Bawa</button>
                        <button type="button" class="btn btn-xs btn-success" :disabled="!hasPendingSoldChange(item)" @click="saveAdjustedSoldQuantity(item)"><i class="fas fa-save mr-1"></i>Simpan Jual</button>
                        <button type="button" class="btn btn-xs btn-outline-dark" :disabled="!hasPendingQuantityChange(item)" @click="resetAdjustedQuantity(item)"><i class="fas fa-undo mr-1"></i>Reset Bawa</button>
                        <button type="button" class="btn btn-xs btn-outline-dark" :disabled="!hasPendingSoldChange(item)" @click="resetAdjustedSoldQuantity(item)"><i class="fas fa-undo mr-1"></i>Reset Jual</button>
                        <button type="button" class="btn btn-xs btn-warning" @click="openEditModal(item)"><i class="fas fa-pen mr-1"></i>Edit</button>
                        <button type="button" class="btn btn-xs btn-outline-danger" :disabled="!item.can_delete" @click="removeOnhand(item)"><i class="fas fa-trash-alt mr-1"></i>Hapus</button>
                    </div>
                </div>
            </div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeManageModal">Tutup</button>
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
const showManageModal = ref(false);
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const editingItem = ref(null);
const activeUserGroup = ref(null);
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

const displayQuantity = (item) => Number(draftQuantities[item.id_product_onhand] ?? item.quantity ?? 0);
const displaySoldQuantity = (item) => Number(draftSoldQuantities[item.id_product_onhand] ?? item.sold_quantity ?? 0);
const displayRemaining = (item) => {
    const nextQuantity = displayQuantity(item);
    const nextSoldQuantity = displaySoldQuantity(item);

    return Math.max(
        nextQuantity - nextSoldQuantity - Number(item.approved_return_quantity || 0) - Number(item.pending_return_quantity || item.quantity_dikembalikan || 0),
        0,
    );
};

const groupedOnhands = computed(() => {
    const groups = new Map();

    props.onhands.forEach((item) => {
        const key = String(item.user_id ?? 'unknown');
        if (!groups.has(key)) {
            groups.set(key, {
                user_id: item.user_id,
                user_name: item.user_name || '-',
                user_role: item.user_role || '-',
                latest_assignment_date: item.assignment_date || null,
                total_quantity: 0,
                total_sold: 0,
                total_remaining: 0,
                pending_count: 0,
                pending_return_count: 0,
                items: [],
            });
        }

        const group = groups.get(key);
        group.items.push(item);
        group.total_quantity += Number(item.quantity ?? 0);
        group.total_sold += Number(item.sold_quantity ?? 0);
        group.total_remaining += item.take_status === 'disetujui' ? displayRemaining(item) : 0;
        group.pending_count += item.take_status === 'pending' ? 1 : 0;
        group.pending_return_count += item.return_status === 'pending' ? 1 : 0;

        if ((item.assignment_date || '') > (group.latest_assignment_date || '')) {
            group.latest_assignment_date = item.assignment_date;
        }
    });

    return Array.from(groups.values());
});

const manageModalTitle = computed(() => activeUserGroup.value ? `Kelola Onhand ${activeUserGroup.value.user_name}` : 'Kelola Onhand');

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

const openManageModal = (group) => {
    activeUserGroup.value = group;
    showManageModal.value = true;
};

const closeManageModal = () => {
    showManageModal.value = false;
    activeUserGroup.value = null;
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

const hasPendingQuantityChange = (item) => Number(draftQuantities[item.id_product_onhand] ?? item.quantity ?? 0) !== Number(item.quantity ?? 0);
const hasPendingSoldChange = (item) => Number(draftSoldQuantities[item.id_product_onhand] ?? item.sold_quantity ?? 0) !== Number(item.sold_quantity ?? 0);
const quantityDelta = (item) => displayQuantity(item) - Number(item.quantity ?? 0);
const soldDelta = (item) => displaySoldQuantity(item) - Number(item.sold_quantity ?? 0);
const formatDelta = (delta) => delta === 0 ? '' : `${delta > 0 ? '+' : ''}${delta}`;
const canDecreaseSold = (item) => item.take_status === 'disetujui' && displaySoldQuantity(item) > Number(item.minimum_sold_quantity ?? 0);
const canIncreaseSold = (item) => item.take_status === 'disetujui' && displaySoldQuantity(item) < Number(item.maximum_sold_quantity ?? 0);

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
.crud-modal-body,
.manage-onhand-list,
.grouped-onhand-list {
    display: grid;
    gap: 1rem;
}

.manage-onhand-summary {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 0.75rem;
    margin-bottom: 1rem;
}

.summary-card,
.metric-tile,
.onhand-user-card,
.manage-onhand-item {
    border: 1px solid #e5e7eb;
    border-radius: 16px;
    background: #fff;
}

.summary-card,
.metric-tile {
    padding: 0.9rem 1rem;
}

.summary-label,
.metric-tile span,
.user-stat-pill span {
    display: block;
    font-size: 0.78rem;
    color: #6b7280;
    text-transform: uppercase;
    letter-spacing: 0.04em;
}

.summary-value,
.metric-tile strong,
.user-stat-pill strong {
    display: block;
    margin-top: 0.3rem;
    font-size: 1.2rem;
    font-weight: 700;
    color: #111827;
}

.metric-tile small {
    display: block;
    margin-top: 0.35rem;
}

.onhand-user-card {
    padding: 1rem 1.1rem;
    background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
}

.onhand-user-card__top,
.onhand-user-card__bottom,
.manage-onhand-item__header {
    display: flex;
    justify-content: space-between;
    gap: 1rem;
}

.onhand-user-card__bottom {
    margin-top: 1rem;
    align-items: center;
}

.onhand-user-card__name {
    font-size: 1.05rem;
    font-weight: 700;
    color: #111827;
}

.onhand-user-card__stats,
.manage-onhand-item__badges {
    display: flex;
    flex-wrap: wrap;
    gap: 0.6rem;
}

.user-stat-pill {
    min-width: 88px;
    padding: 0.75rem 0.9rem;
    border-radius: 14px;
    background: #eef6ff;
}

.manage-onhand-item {
    padding: 1rem;
}

.manage-onhand-item__grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 0.75rem;
    margin: 1rem 0;
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

@media (max-width: 991.98px) {
    .manage-onhand-summary,
    .manage-onhand-item__grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .onhand-user-card__top,
    .onhand-user-card__bottom,
    .manage-onhand-item__header {
        flex-direction: column;
    }
}

@media (max-width: 576px) {
    .manage-onhand-summary,
    .manage-onhand-item__grid,
    .action-group {
        grid-template-columns: 1fr;
    }
}
</style>

