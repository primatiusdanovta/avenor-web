<template>
    <AppLayout>
        <Head title="Consign" />

        <template #actions>
            <button
                v-if="canManageConsignments"
                type="button"
                class="btn btn-primary"
                @click="openCreateModal"
            >
                <i class="fas fa-plus mr-1"></i>
                Tambah Consign
            </button>
        </template>

        <div class="row">
            <div class="col-12">
                <div class="card card-outline card-secondary">
                    <div class="card-header"><h3 class="card-title">Filter Consign</h3></div>
                    <div class="card-body">
                        <form class="row align-items-end" @submit.prevent="submitSearch">
                            <div class="col-md-4 mb-3 mb-md-0">
                                <label class="mb-1">Sales Field Executive</label>
                                <Select2Input v-model="filterForm.user_id" :options="users" value-key="id_user" label-key="option_label" placeholder="Semua sales field executive" />
                            </div>
                            <div class="col-md-5 mb-3 mb-md-0">
                                <label class="mb-1">Cari tempat / product</label>
                                <input v-model="filterForm.search" type="text" class="form-control" placeholder="Cari nama tempat, alamat, atau product">
                            </div>
                            <div class="col-md-3">
                                <button class="btn btn-outline-primary w-100" type="submit">Terapkan</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-12">
                <div class="card card-outline card-primary">
                    <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                        <h3 class="card-title">Daftar Titip Barang</h3>
                        <div class="small text-muted">
                            Superadmin bisa menambahkan consign baru ke user terpilih, edit data consign, dan update status item consign.
                        </div>
                    </div>
                    <div class="card-body">
                        <div v-if="consignments.length" class="consignment-grid">
                            <div v-for="consignment in consignments" :key="consignment.id" class="consignment-card">
                                <div class="consignment-card__header">
                                    <div>
                                        <div class="consignment-card__title">{{ consignment.place_name }}</div>
                                        <div class="small text-muted">{{ consignment.user_name }} | {{ consignment.address }}</div>
                                    </div>
                                    <div class="d-flex flex-wrap gap-2 justify-content-end">
                                        <span class="badge badge-light">{{ consignment.consignment_date }}</span>
                                        <span class="badge badge-light">{{ consignment.items.length }} item</span>
                                    </div>
                                </div>

                                <div class="consignment-card__meta">
                                    <div><strong>Submitted:</strong> {{ consignment.submitted_at || '-' }}</div>
                                    <div v-if="consignment.notes"><strong>Catatan:</strong> {{ consignment.notes }}</div>
                                    <div v-if="consignment.handover_proof_photo_url">
                                        <a :href="consignment.handover_proof_photo_url" target="_blank" rel="noopener noreferrer" class="btn btn-sm btn-outline-secondary mt-2">
                                            Lihat Foto Bukti
                                        </a>
                                    </div>
                                </div>

                                <div class="item-stack mt-3">
                                    <div v-for="item in consignment.items" :key="item.id" class="item-card">
                                        <div class="d-flex justify-content-between gap-3 flex-wrap">
                                            <div>
                                                <div class="font-weight-bold">{{ item.product_name }}</div>
                                                <div class="small text-muted">Batch {{ item.pickup_batch_code || '-' }} | Qty {{ item.quantity }}</div>
                                            </div>
                                            <span class="badge status-badge" :class="itemStatusClass(item.status)">{{ item.status }}</span>
                                        </div>
                                        <div class="small mt-2 mb-2">Terjual {{ item.sold_quantity }} | Dikembalikan {{ item.returned_quantity }}</div>
                                        <form class="row align-items-end" @submit.prevent="submitItem(item)">
                                            <div class="col-md-3 mb-2">
                                                <label class="mb-1">Terjual</label>
                                                <input v-model="itemForms[item.id].sold_quantity" type="number" min="0" class="form-control form-control-sm">
                                            </div>
                                            <div class="col-md-3 mb-2">
                                                <label class="mb-1">Dikembalikan</label>
                                                <input v-model="itemForms[item.id].returned_quantity" type="number" min="0" class="form-control form-control-sm">
                                            </div>
                                            <div class="col-md-4 mb-2">
                                                <label class="mb-1">Catatan</label>
                                                <input v-model="itemForms[item.id].status_notes" type="text" class="form-control form-control-sm" placeholder="opsional">
                                            </div>
                                            <div class="col-md-2 mb-2">
                                                <button class="btn btn-sm btn-primary w-100" :disabled="itemForms[item.id].processing">Simpan</button>
                                            </div>
                                        </form>
                                    </div>
                                </div>

                                <div v-if="canManageConsignments" class="consignment-card__actions">
                                    <button type="button" class="btn btn-sm btn-warning" @click="openEditModal(consignment)">
                                        <i class="fas fa-pen mr-1"></i>
                                        Edit
                                    </button>
                                    <button type="button" class="btn btn-sm btn-outline-danger" @click="promptDelete(consignment)">
                                        <i class="fas fa-trash-alt mr-1"></i>
                                        Hapus
                                    </button>
                                </div>
                            </div>
                        </div>
                        <div v-else class="text-center text-muted py-4">Belum ada data consign.</div>
                    </div>
                </div>
            </div>
        </div>

        <BootstrapModal :show="showConsignmentModal" :title="modalTitle" size="xl" @close="closeConsignmentModal">
            <div class="consignment-form-grid">
                <div class="form-group mb-0">
                    <label>User Tujuan</label>
                    <Select2Input v-model="consignmentForm.user_id" :options="users" value-key="id_user" label-key="option_label" placeholder="Pilih sales field executive" />
                </div>
                <div class="form-group mb-0">
                    <label>Tanggal Consign</label>
                    <input v-model="consignmentForm.consignment_date" type="date" class="form-control">
                </div>
                <div class="form-group mb-0">
                    <label>Nama Tempat</label>
                    <input v-model="consignmentForm.place_name" type="text" class="form-control" placeholder="Nama toko / booth / partner">
                </div>
                <div class="form-group mb-0">
                    <label>Alamat</label>
                    <textarea v-model="consignmentForm.address" rows="3" class="form-control" placeholder="Alamat consign"></textarea>
                </div>
                <div class="form-group mb-0 form-group--full">
                    <label>Catatan</label>
                    <textarea v-model="consignmentForm.notes" rows="2" class="form-control" placeholder="Catatan internal consign"></textarea>
                </div>
                <div class="form-group mb-0 form-group--full">
                    <label>Foto Bukti</label>
                    <input type="file" class="form-control" accept="image/*" @change="handleProofChange">
                    <div v-if="editingProofUrl" class="mt-2 d-flex flex-wrap align-items-center gap-3">
                        <a :href="editingProofUrl" target="_blank" rel="noopener noreferrer" class="btn btn-sm btn-outline-secondary">Lihat Bukti Saat Ini</a>
                        <div class="form-check">
                            <input id="remove-proof" v-model="consignmentForm.remove_handover_proof_photo" class="form-check-input" type="checkbox">
                            <label for="remove-proof" class="form-check-label">Hapus bukti lama</label>
                        </div>
                    </div>
                </div>
            </div>

            <div class="consignment-items-panel mt-4">
                <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
                    <div>
                        <div class="font-weight-bold">Item Consign</div>
                        <div class="small text-muted">Pilih batch onhand milik user terpilih. Batch dengan sisa stock 0 tetap muncul saat sedang diedit jika sudah dipakai di consign ini.</div>
                    </div>
                    <button type="button" class="btn btn-sm btn-outline-primary" @click="addItemRow">
                        <i class="fas fa-plus mr-1"></i>
                        Tambah Item
                    </button>
                </div>

                <div v-if="consignmentForm.items.length" class="item-editor-list">
                    <div v-for="(item, index) in consignmentForm.items" :key="`draft-${index}-${item.id || 'new'}`" class="item-editor-card">
                        <div class="row">
                            <div class="col-md-7 mb-3 mb-md-0">
                                <label class="mb-1">Batch Onhand</label>
                                <select v-model="item.product_onhand_id" class="form-control">
                                    <option value="">Pilih batch onhand</option>
                                    <option v-for="option in optionsForItem(index)" :key="option.id_product_onhand" :value="String(option.id_product_onhand)">
                                        {{ option.option_label }}
                                    </option>
                                </select>
                                <div v-if="selectedOnhand(item.product_onhand_id)" class="small text-muted mt-2">
                                    Qty onhand {{ selectedOnhand(item.product_onhand_id).quantity }} | Sisa bisa consign {{ selectedOnhand(item.product_onhand_id).available_quantity }} | Batch {{ selectedOnhand(item.product_onhand_id).pickup_batch_code || '-' }}
                                </div>
                            </div>
                            <div class="col-md-3 mb-3 mb-md-0">
                                <label class="mb-1">Quantity</label>
                                <input v-model="item.quantity" type="number" min="1" class="form-control">
                            </div>
                            <div class="col-md-2 d-flex align-items-end">
                                <button type="button" class="btn btn-outline-danger w-100" :disabled="consignmentForm.items.length === 1" @click="removeItemRow(index)">
                                    Hapus
                                </button>
                            </div>
                        </div>
                        <div v-if="item.id" class="small text-muted mt-2">
                            Item existing | Terjual {{ item.sold_quantity || 0 }} | Dikembalikan {{ item.returned_quantity || 0 }}
                        </div>
                    </div>
                </div>
                <div v-else class="text-muted">Belum ada item consign.</div>
            </div>

            <template #footer>
                <button type="button" class="btn btn-secondary" @click="closeConsignmentModal">Batal</button>
                <button type="button" class="btn btn-primary" :disabled="consignmentForm.processing" @click="submitConsignment">
                    {{ consignmentForm.processing ? 'Menyimpan...' : 'Simpan Consign' }}
                </button>
            </template>
        </BootstrapModal>

        <BootstrapModal :show="showDeleteModal" title="Hapus Consign" size="mobile-full" @close="closeDeleteModal">
            <div v-if="deleteTarget">
                Hapus consign <strong>{{ deleteTarget.place_name }}</strong> milik <strong>{{ deleteTarget.user_name }}</strong>?
                <div class="small text-muted mt-2">Consign yang sudah memiliki progres penjualan atau pengembalian tidak bisa dihapus.</div>
            </div>
            <template #footer>
                <button type="button" class="btn btn-secondary" @click="closeDeleteModal">Batal</button>
                <button type="button" class="btn btn-danger" @click="confirmDelete">Hapus</button>
            </template>
        </BootstrapModal>
    </AppLayout>
</template>

<script setup>
import { computed, ref, watch } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';
import Select2Input from '../../Components/Select2Input.vue';
import { adminUrl } from '../../utils/admin';

const props = defineProps({
    filters: Object,
    users: Array,
    consignments: Array,
    availableOnhands: Array,
    canManageConsignments: Boolean,
});

const today = new Date().toISOString().slice(0, 10);
const filterForm = useForm({
    user_id: props.filters.user_id ? String(props.filters.user_id) : '',
    search: props.filters.search ?? '',
});

const itemForms = Object.fromEntries(
    props.consignments.flatMap((consignment) => consignment.items.map((item) => [
        item.id,
        useForm({
            sold_quantity: item.sold_quantity,
            returned_quantity: item.returned_quantity,
            status_notes: item.status_notes ?? '',
        }),
    ])),
);

const createEmptyItem = () => ({
    id: null,
    product_onhand_id: '',
    quantity: 1,
    sold_quantity: 0,
    returned_quantity: 0,
});

const consignmentForm = useForm({
    id: null,
    user_id: props.filters.user_id ? String(props.filters.user_id) : '',
    place_name: '',
    address: '',
    consignment_date: today,
    notes: '',
    handover_proof_photo: null,
    remove_handover_proof_photo: false,
    items: [createEmptyItem()],
});

const showConsignmentModal = ref(false);
const showDeleteModal = ref(false);
const modalMode = ref('create');
const deleteTarget = ref(null);
const editingProofUrl = ref(null);

const modalTitle = computed(() => modalMode.value === 'create' ? 'Tambah Consign Baru' : 'Edit Consign');

const normalizeUserId = (value) => value ? String(value) : '';
const normalizeOnhandId = (value) => value ? String(value) : '';

const resetConsignmentForm = () => {
    consignmentForm.reset();
    consignmentForm.id = null;
    consignmentForm.user_id = props.filters.user_id ? String(props.filters.user_id) : '';
    consignmentForm.place_name = '';
    consignmentForm.address = '';
    consignmentForm.consignment_date = today;
    consignmentForm.notes = '';
    consignmentForm.handover_proof_photo = null;
    consignmentForm.remove_handover_proof_photo = false;
    consignmentForm.items = [createEmptyItem()];
    editingProofUrl.value = null;
};

const selectedItemIds = computed(() => new Set(
    consignmentForm.items
        .map((item) => normalizeOnhandId(item.product_onhand_id))
        .filter(Boolean),
));

const onhandsForSelectedUser = computed(() => props.availableOnhands.filter((item) => {
    if (!normalizeUserId(consignmentForm.user_id)) return false;

    return normalizeUserId(item.user_id) === normalizeUserId(consignmentForm.user_id)
        && (Number(item.available_quantity) > 0 || selectedItemIds.value.has(normalizeOnhandId(item.id_product_onhand)));
}));

const optionsForItem = (index) => {
    const currentId = normalizeOnhandId(consignmentForm.items[index]?.product_onhand_id);

    return onhandsForSelectedUser.value.filter((option) => {
        const optionId = normalizeOnhandId(option.id_product_onhand);
        if (optionId === currentId) return true;

        return !consignmentForm.items.some((item, itemIndex) => itemIndex !== index && normalizeOnhandId(item.product_onhand_id) === optionId);
    });
};

const selectedOnhand = (productOnhandId) => props.availableOnhands.find(
    (item) => normalizeOnhandId(item.id_product_onhand) === normalizeOnhandId(productOnhandId),
);

watch(() => consignmentForm.user_id, (nextValue, previousValue) => {
    if (!showConsignmentModal.value || nextValue === previousValue) return;

    consignmentForm.items = [createEmptyItem()];
});

const openCreateModal = () => {
    modalMode.value = 'create';
    resetConsignmentForm();
    showConsignmentModal.value = true;
};

const openEditModal = (consignment) => {
    modalMode.value = 'edit';
    consignmentForm.clearErrors();
    consignmentForm.id = consignment.id;
    consignmentForm.user_id = String(consignment.user_id);
    consignmentForm.place_name = consignment.place_name ?? '';
    consignmentForm.address = consignment.address ?? '';
    consignmentForm.consignment_date = consignment.consignment_date ?? today;
    consignmentForm.notes = consignment.notes ?? '';
    consignmentForm.handover_proof_photo = null;
    consignmentForm.remove_handover_proof_photo = false;
    consignmentForm.items = consignment.items.length
        ? consignment.items.map((item) => ({
            id: item.id,
            product_onhand_id: String(item.product_onhand_id),
            quantity: item.quantity,
            sold_quantity: item.sold_quantity,
            returned_quantity: item.returned_quantity,
        }))
        : [createEmptyItem()];
    editingProofUrl.value = consignment.handover_proof_photo_url ?? null;
    showConsignmentModal.value = true;
};

const closeConsignmentModal = () => {
    showConsignmentModal.value = false;
    resetConsignmentForm();
};

const addItemRow = () => {
    consignmentForm.items = [...consignmentForm.items, createEmptyItem()];
};

const removeItemRow = (index) => {
    if (consignmentForm.items.length === 1) return;
    consignmentForm.items.splice(index, 1);
};

const handleProofChange = (event) => {
    const file = event.target.files?.[0] ?? null;
    consignmentForm.handover_proof_photo = file;
};

const buildConsignmentPayload = (data) => ({
    user_id: Number(data.user_id),
    place_name: data.place_name,
    address: data.address,
    consignment_date: data.consignment_date,
    notes: data.notes || null,
    handover_proof_photo: data.handover_proof_photo,
    remove_handover_proof_photo: data.remove_handover_proof_photo ? 1 : 0,
    items: data.items.map((item) => ({
        ...(item.id ? { id: Number(item.id) } : {}),
        product_onhand_id: Number(item.product_onhand_id),
        quantity: Number(item.quantity),
    })),
});

const submitConsignment = () => {
    consignmentForm.transform((data) => ({
        ...buildConsignmentPayload(data),
        ...(modalMode.value === 'edit' ? { _method: 'put' } : {}),
    }));

    const options = {
        preserveScroll: true,
        forceFormData: true,
        onSuccess: () => closeConsignmentModal(),
    };

    if (modalMode.value === 'create') {
        consignmentForm.post(adminUrl('/consignments'), options);
        return;
    }

    consignmentForm.post(adminUrl(`/consignments/${consignmentForm.id}`), options);
};

const promptDelete = (consignment) => {
    deleteTarget.value = consignment;
    showDeleteModal.value = true;
};

const closeDeleteModal = () => {
    showDeleteModal.value = false;
    deleteTarget.value = null;
};

const confirmDelete = () => {
    if (!deleteTarget.value) return;

    router.delete(adminUrl(`/consignments/${deleteTarget.value.id}`), {
        preserveScroll: true,
        data: {
            user_id: filterForm.user_id || '',
            search: filterForm.search || '',
        },
        onSuccess: () => closeDeleteModal(),
    });
};

const submitSearch = () => filterForm.get(adminUrl('/consignments'), {
    preserveScroll: true,
    preserveState: true,
    replace: true,
});

const submitItem = (item) => itemForms[item.id].put(adminUrl(`/consignment-items/${item.id}`), {
    preserveScroll: true,
    data: {
        sold_quantity: itemForms[item.id].sold_quantity,
        returned_quantity: itemForms[item.id].returned_quantity,
        status_notes: itemForms[item.id].status_notes,
        user_id: filterForm.user_id || '',
        search: filterForm.search || '',
    },
});

const itemStatusClass = (status) => ({
    dititipkan: 'badge-warning-soft text-warning-emphasis',
    terjual: 'badge-success-soft text-success-emphasis',
    dikembalikan: 'badge-info-soft text-info-emphasis',
}[status] || 'badge-secondary-soft text-secondary-emphasis');
</script>

<style scoped>
.consignment-grid,
.consignment-form-grid,
.item-stack,
.item-editor-list {
    display: grid;
    gap: 1rem;
}

.consignment-grid {
    grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
}

.consignment-card,
.item-card,
.item-editor-card,
.consignment-items-panel {
    border: 1px solid #e5e7eb;
    border-radius: 16px;
    background: #fff;
}

.consignment-card {
    padding: 1rem;
}

.consignment-card__header,
.consignment-card__actions {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 1rem;
}

.consignment-card__title {
    font-size: 1.05rem;
    font-weight: 700;
    color: #111827;
}

.consignment-card__meta {
    margin-top: 0.85rem;
    color: #4b5563;
    font-size: 0.92rem;
}

.consignment-card__actions {
    margin-top: 1rem;
}

.item-card,
.item-editor-card {
    padding: 0.9rem;
}

.consignment-form-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
}

.form-group--full {
    grid-column: 1 / -1;
}

.consignment-items-panel {
    padding: 1rem;
    background: #f9fafb;
}

.status-badge {
    border-radius: 999px;
    padding: 0.45rem 0.7rem;
    font-weight: 600;
}

.badge-warning-soft { background: #fff3cd; }
.badge-success-soft { background: #d1e7dd; }
.badge-info-soft { background: #cff4fc; }
.badge-secondary-soft { background: #e2e3e5; }

@media (max-width: 767.98px) {
    .consignment-form-grid {
        grid-template-columns: 1fr;
    }

    .consignment-card__header,
    .consignment-card__actions {
        flex-direction: column;
    }
}
</style>

