<template>
    <AppLayout>
    <Head title="Pengeluaran" />

    <template #actions>
        <div class="d-flex flex-wrap justify-content-end gap-2">
            <button type="button" class="btn btn-warning" @click="showOperasionalModal = true">
                <i class="fas fa-plus mr-1"></i>
                Tambah Operasional
            </button>
            <button type="button" class="btn btn-primary" @click="showBahanBakuModal = true">
                <i class="fas fa-plus mr-1"></i>
                Tambah Bahan Baku
            </button>
        </div>
    </template>

    <div class="row">
        <div class="col-md-12 col-xl-4 mb-3">
            <div class="card card-outline card-primary h-100">
                <div class="card-body">
                    <div class="text-muted small mb-2">Total Bahan Baku</div>
                    <div class="h4 mb-0">{{ toCurrency(summary.bahan_baku) }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-12 col-xl-4 mb-3">
            <div class="card card-outline card-warning h-100">
                <div class="card-body">
                    <div class="text-muted small mb-2">Total Operasional</div>
                    <div class="h4 mb-0">{{ toCurrency(summary.operasional) }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-12 col-xl-4 mb-3">
            <div class="card card-outline card-success h-100">
                <div class="card-body">
                    <div class="text-muted small mb-2">Total Semua Pengeluaran</div>
                    <div class="h4 mb-0">{{ toCurrency(summary.total) }}</div>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-lg-12">
            <div class="card card-outline card-secondary">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h3 class="card-title">Riwayat Pengeluaran</h3>
                    <input v-model="keyword" type="text" class="form-control form-control-sm w-auto" placeholder="Cari pengeluaran">
                </div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Tanggal</th>
                                <th>Kategori</th>
                                <th>Judul</th>
                                <th>Keterangan</th>
                                <th>Jumlah</th>
                                <th>Input Oleh</th>
                                <th>Dibuat</th>
                                <th class="action-column">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="item in filteredExpenses" :key="item.id">
                                <td>{{ item.expense_date }}</td>
                                <td><span class="badge" :class="badgeClass(item.category)">{{ item.category_label }}</span></td>
                                <td><button type="button" class="btn btn-link p-0 font-weight-bold text-left" @click="pickEdit(item)">{{ item.title }}</button></td>
                                <td class="text-muted">{{ item.notes || '-' }}</td>
                                <td>{{ toCurrency(item.amount) }}</td>
                                <td>{{ item.created_by_name }}</td>
                                <td>{{ item.created_at }}</td>
                                <td>
                                    <div class="action-group">
                                        <button type="button" class="btn btn-xs btn-warning" @click="pickEdit(item)"><i class="fas fa-pen mr-1"></i>Edit</button>
                                        <button type="button" class="btn btn-xs btn-danger" @click="askDelete(item)"><i class="fas fa-trash-alt mr-1"></i>Hapus</button>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="!filteredExpenses.length">
                                <td colspan="8" class="text-center text-muted">Belum ada data pengeluaran.</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showBahanBakuModal" title="Input Pengeluaran Bahan Baku" header-variant="primary" @close="closeBahanBakuModal">
        <form @submit.prevent="submitBahanBaku">
            <div class="form-group">
                <label>Judul Pengeluaran</label>
                <input v-model="bahanBakuForm.title" type="text" class="form-control" placeholder="Contoh: Beli bibit parfum">
            </div>
            <div class="form-group">
                <label>Jumlah</label>
                <input v-model="bahanBakuForm.amount" type="number" min="0" step="0.01" class="form-control" placeholder="0">
            </div>
            <div class="form-group">
                <label>Tanggal Pengeluaran</label>
                <input v-model="bahanBakuForm.expense_date" type="date" class="form-control">
            </div>
            <div class="form-group mb-0">
                <label>Keterangan</label>
                <textarea v-model="bahanBakuForm.notes" rows="3" class="form-control" placeholder="Opsional"></textarea>
            </div>
        </form>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeBahanBakuModal">Batal</button>
            <button type="button" class="btn btn-primary" :disabled="bahanBakuForm.processing" @click="submitBahanBaku">Simpan</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showOperasionalModal" title="Input Pengeluaran Operasional" header-variant="warning" @close="closeOperasionalModal">
        <form @submit.prevent="submitOperasional">
            <div class="form-group">
                <label>Judul Pengeluaran</label>
                <input v-model="operasionalForm.title" type="text" class="form-control" placeholder="Contoh: Biaya transport">
            </div>
            <div class="form-group">
                <label>Jumlah</label>
                <input v-model="operasionalForm.amount" type="number" min="0" step="0.01" class="form-control" placeholder="0">
            </div>
            <div class="form-group">
                <label>Tanggal Pengeluaran</label>
                <input v-model="operasionalForm.expense_date" type="date" class="form-control">
            </div>
            <div class="form-group mb-0">
                <label>Keterangan</label>
                <textarea v-model="operasionalForm.notes" rows="3" class="form-control" placeholder="Opsional"></textarea>
            </div>
        </form>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeOperasionalModal">Batal</button>
            <button type="button" class="btn btn-warning" :disabled="operasionalForm.processing" @click="submitOperasional">Simpan</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showEditModal" :title="editForm.category === 'bahan_baku' ? 'Edit Pengeluaran Bahan Baku' : 'Edit Pengeluaran Operasional'" :header-variant="editForm.category === 'bahan_baku' ? 'primary' : 'warning'" @close="closeEditModal">
        <form @submit.prevent="submitEdit">
            <div class="form-group">
                <label>Kategori</label>
                <select v-model="editForm.category" class="form-control">
                    <option value="bahan_baku">Bahan Baku</option>
                    <option value="operasional">Operasional</option>
                </select>
            </div>
            <div class="form-group">
                <label>Judul Pengeluaran</label>
                <input v-model="editForm.title" type="text" class="form-control">
            </div>
            <div class="form-group">
                <label>Jumlah</label>
                <input v-model="editForm.amount" type="number" min="0" step="0.01" class="form-control">
            </div>
            <div class="form-group">
                <label>Tanggal Pengeluaran</label>
                <input v-model="editForm.expense_date" type="date" class="form-control">
            </div>
            <div class="form-group mb-0">
                <label>Keterangan</label>
                <textarea v-model="editForm.notes" rows="3" class="form-control" placeholder="Opsional"></textarea>
            </div>
        </form>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeEditModal">Batal</button>
            <button type="button" class="btn" :class="editForm.category === 'bahan_baku' ? 'btn-primary' : 'btn-warning'" :disabled="editForm.processing" @click="submitEdit">Update</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        Hapus pengeluaran {{ deleteTarget?.title }}?
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeDeleteModal">Batal</button>
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

const props = defineProps({
    expenses: Array,
    summary: Object,
});

const keyword = ref('');
const showBahanBakuModal = ref(false);
const showOperasionalModal = ref(false);
const showEditModal = ref(false);
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const today = new Date().toISOString().slice(0, 10);
const makeForm = (category) => useForm({
    category,
    title: '',
    amount: '',
    expense_date: today,
    notes: '',
});

const bahanBakuForm = makeForm('bahan_baku');
const operasionalForm = makeForm('operasional');
const editForm = useForm({
    id: null,
    category: 'bahan_baku',
    title: '',
    amount: '',
    expense_date: today,
    notes: '',
});

const filteredExpenses = computed(() => props.expenses.filter((item) => {
    const haystack = [item.category_label, item.title, item.notes || '', item.created_by_name || ''].join(' ').toLowerCase();
    return haystack.includes(keyword.value.toLowerCase());
}));

const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 2 }).format(value || 0);
const badgeClass = (category) => category === 'bahan_baku' ? 'badge-primary' : 'badge-warning';

const resetCreateForm = (form) => {
    form.reset();
    form.expense_date = today;
    form.clearErrors();
};

const closeBahanBakuModal = () => {
    showBahanBakuModal.value = false;
    resetCreateForm(bahanBakuForm);
};

const closeOperasionalModal = () => {
    showOperasionalModal.value = false;
    resetCreateForm(operasionalForm);
};

const pickEdit = (item) => {
    editForm.id = item.id;
    editForm.category = item.category;
    editForm.title = item.title;
    editForm.amount = item.amount;
    editForm.expense_date = item.expense_date;
    editForm.notes = item.notes || '';
    editForm.clearErrors();
    showEditModal.value = true;
};

const closeEditModal = () => {
    showEditModal.value = false;
    editForm.reset();
    editForm.id = null;
    editForm.category = 'bahan_baku';
    editForm.expense_date = today;
    editForm.clearErrors();
};

const askDelete = (item) => {
    deleteTarget.value = item;
    showDeleteModal.value = true;
};

const closeDeleteModal = () => {
    showDeleteModal.value = false;
    deleteTarget.value = null;
};

const submitBahanBaku = () => bahanBakuForm.post(adminUrl('/expenses'), {
    preserveScroll: true,
    onSuccess: closeBahanBakuModal,
});

const submitOperasional = () => operasionalForm.post(adminUrl('/expenses'), {
    preserveScroll: true,
    onSuccess: closeOperasionalModal,
});

const submitEdit = () => editForm.put(adminUrl(`/expenses/${editForm.id}`), {
    preserveScroll: true,
    onSuccess: closeEditModal,
});

const confirmDelete = () => {
    if (!deleteTarget.value) return;
    const id = deleteTarget.value.id;
    closeDeleteModal();
    router.delete(adminUrl(`/expenses/${id}`), { preserveScroll: true });
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

@media (max-width: 575.98px) {
    .action-group {
        grid-template-columns: 1fr;
    }
}
</style>



