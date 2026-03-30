<template>
    <Head title="Penjualan Online" />

    <div class="row">
        <div class="col-md-12 col-lg-4">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Import Penjualan Online</h3></div>
                <div class="card-body">
                    <div class="form-group">
                        <label>File Order TikTok (.csv / .xlsx)</label>
                        <input type="file" class="form-control" accept=".csv,.xlsx,.txt" @change="handleFileChange('orders_file', $event)">
                        <small v-if="form.orders_file" class="text-muted d-block mt-1">{{ form.orders_file.name }}</small>
                    </div>
                    <div class="form-group">
                        <label>File Income TikTok (.csv / .xlsx)</label>
                        <input type="file" class="form-control" accept=".csv,.xlsx,.txt" @change="handleFileChange('income_file', $event)">
                        <small v-if="form.income_file" class="text-muted d-block mt-1">{{ form.income_file.name }}</small>
                    </div>
                    <p class="text-muted small mb-3">Dua file wajib diupload bersamaan. Data online sales lama akan dibersihkan lalu dibentuk ulang dari order selesai yang memiliki pasangan data income.</p>
                    <button class="btn btn-primary" :disabled="form.processing || !form.orders_file || !form.income_file" @click="submitImport">
                        {{ form.processing ? 'Mengimpor...' : 'Import Data' }}
                    </button>
                </div>
            </div>
        </div>

        <div class="col-md-12 col-lg-8">
            <div class="card card-outline card-success">
                <div class="card-header d-flex flex-wrap gap-2 align-items-center justify-content-between">
                    <h3 class="card-title mb-0">Datatable Penjualan Online</h3>
                    <div class="d-flex flex-wrap gap-2 align-items-center">
                        <input v-model="search" type="text" class="form-control form-control-sm" placeholder="Cari Order ID, product, provinsi, kota" style="width: 280px;">
                        <select v-model.number="pageSize" class="form-control form-control-sm" style="width: 110px;">
                            <option :value="10">10 data</option>
                            <option :value="25">25 data</option>
                            <option :value="50">50 data</option>
                        </select>
                    </div>
                </div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th @click="toggleSort('order_id')" class="sortable">Order ID</th>
                                <th @click="toggleSort('paid_time')" class="sortable">Paid Time</th>
                                <th>Produk</th>
                                <th @click="toggleSort('total_amount')" class="sortable">Total Settlement</th>
                                <th>Provinsi</th>
                                <th>Kota</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="sale in paginatedSales" :key="sale.id">
                                <td>{{ sale.order_id }}</td>
                                <td>{{ sale.paid_time || '-' }}</td>
                                <td>
                                    <div v-for="item in sale.items" :key="item.id" class="text-sm mb-1">
                                        <strong>{{ item.nama_product }}</strong>
                                        <span class="text-muted">x {{ item.quantity }} | {{ toCurrency(item.harga) }}</span>
                                    </div>
                                </td>
                                <td>{{ toCurrency(sale.total_amount) }}</td>
                                <td>{{ sale.province || '-' }}</td>
                                <td>{{ sale.regency_city || '-' }}</td>
                                <td>
                                    <div>{{ sale.order_status || '-' }}</div>
                                    <div class="small text-muted">{{ sale.order_substatus || '-' }}</div>
                                </td>
                            </tr>
                            <tr v-if="!paginatedSales.length">
                                <td colspan="7" class="text-center text-muted">Belum ada data penjualan online.</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <div class="card-footer d-flex justify-content-between align-items-center">
                    <div class="text-muted small">Menampilkan {{ paginatedSales.length }} dari {{ filteredSales.length }} data</div>
                    <div class="btn-group btn-group-sm">
                        <button class="btn btn-outline-secondary" :disabled="page === 1" @click="page -= 1">Prev</button>
                        <button class="btn btn-outline-secondary disabled">{{ page }} / {{ totalPages }}</button>
                        <button class="btn btn-outline-secondary" :disabled="page >= totalPages" @click="page += 1">Next</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showFeedbackModal" :title="feedbackTitle" :header-variant="feedbackType === 'error' ? 'danger' : feedbackType === 'warning' ? 'warning' : 'success'" size="mobile-full" @close="showFeedbackModal = false">
        <template v-if="feedbackLines.length > 1">
            <p class="mb-2">{{ feedbackLines[0] }}</p>
            <ul class="mb-0 ps-3">
                <li v-for="line in feedbackLines.slice(1)" :key="line">{{ cleanFeedbackLine(line) }}</li>
            </ul>
        </template>
        <template v-else>
            {{ feedbackMessage }}
        </template>
        <template #footer>
            <button type="button" class="btn" :class="feedbackButtonClass" @click="showFeedbackModal = false">Tutup</button>
        </template>
    </BootstrapModal>
</template>

<script setup>
import { computed, watch, ref } from 'vue';
import { Head, useForm, usePage } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';

defineOptions({ layout: AppLayout });

const pageProps = usePage();
const props = defineProps({
    sales: {
        type: Array,
        default: () => [],
    },
});

const form = useForm({ orders_file: null, income_file: null });
const search = ref('');
const page = ref(1);
const pageSize = ref(10);
const sortKey = ref('paid_time');
const sortDirection = ref('desc');
const showFeedbackModal = ref(false);

const errorMessage = computed(() => pageProps.props.errors.orders_file || pageProps.props.errors.income_file || '');
const warningMessage = computed(() => pageProps.props.flash?.warning || '');
const successMessage = computed(() => pageProps.props.flash?.success || '');
const feedbackType = computed(() => {
    if (errorMessage.value) {
        return errorMessage.value.toLowerCase().includes('stock') ? 'warning' : 'error';
    }

    if (warningMessage.value) {
        return 'warning';
    }

    if (successMessage.value) {
        return 'success';
    }

    return null;
});
const feedbackMessage = computed(() => errorMessage.value || warningMessage.value || successMessage.value || '');
const feedbackLines = computed(() => feedbackMessage.value.split('\n').map((line) => line.trim()).filter(Boolean));
const feedbackTitle = computed(() => {
    return feedbackType.value === 'success'
        ? 'Import Berhasil'
        : feedbackType.value === 'warning'
            ? 'Peringatan Import Online Sales'
            : 'Informasi Import Online Sales';
});
const feedbackButtonClass = computed(() => {
    return feedbackType.value === 'success'
        ? 'btn-success'
        : feedbackType.value === 'warning'
            ? 'btn-warning'
            : 'btn-danger';
});

const normalizedSearch = computed(() => search.value.trim().toLowerCase());
const sortRows = (left, right) => {
    const leftValue = left[sortKey.value] ?? '';
    const rightValue = right[sortKey.value] ?? '';
    if (sortDirection.value === 'asc') {
        return leftValue > rightValue ? 1 : -1;
    }
    return leftValue < rightValue ? 1 : -1;
};
const filteredSales = computed(() => {
    const rows = [...props.sales];

    if (normalizedSearch.value) {
        return rows.filter((sale) => {
            const haystack = [
                sale.order_id,
                sale.province,
                sale.regency_city,
                sale.order_status,
                sale.order_substatus,
                ...sale.items.map((item) => `${item.nama_product} ${item.raw_product_name}`),
            ].join(' ').toLowerCase();

            return haystack.includes(normalizedSearch.value);
        }).sort(sortRows);
    }

    return rows.sort(sortRows);
});
const totalPages = computed(() => Math.max(Math.ceil(filteredSales.value.length / pageSize.value), 1));
const paginatedSales = computed(() => {
    const start = (page.value - 1) * pageSize.value;
    return filteredSales.value.slice(start, start + pageSize.value);
});

watch([search, pageSize], () => {
    page.value = 1;
});

watch(totalPages, (value) => {
    if (page.value > value) {
        page.value = value;
    }
});

const toggleSort = (key) => {
    if (sortKey.value === key) {
        sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc';
        return;
    }

    sortKey.value = key;
    sortDirection.value = 'asc';
};

const handleFileChange = (field, event) => {
    const file = event.target.files?.[0] ?? null;
    form[field] = file;
};

const cleanFeedbackLine = (line) => line.replace(/^[-*]\s*/, '');

watch(feedbackMessage, (value) => {
    showFeedbackModal.value = Boolean(value);
}, { immediate: true });

const submitImport = () => form.post('/online-sales/import', {
    forceFormData: true,
    preserveScroll: true,
    onSuccess: () => form.reset(),
});
const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value || 0);
</script>

<style scoped>
.sortable {
    cursor: pointer;
}
</style>
