<template>
    <Head title="Report" />

    <div class="row mb-3">
        <div class="col-12">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Filter Report</h3></div>
                <div class="card-body">
                    <form class="row g-3 align-items-end" @submit.prevent="applyFilter">
                        <div class="col-md-4">
                            <label class="form-label">Jenis Report</label>
                            <select v-model="filterForm.type" class="form-control">
                                <option v-for="option in reportOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Tanggal Dari</label>
                            <input v-model="filterForm.date_from" type="date" class="form-control">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Tanggal Sampai</label>
                            <input v-model="filterForm.date_to" type="date" class="form-control">
                        </div>
                        <div class="col-md-2 d-grid gap-2">
                            <button type="submit" class="btn btn-primary">Tampilkan</button>
                            <button type="button" class="btn btn-outline-danger" @click="exportPdf">Export PDF</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <div v-if="filterForm.type === 'offline'" class="row">
        <div class="col-md-4" v-for="card in offlineCards" :key="card.label">
            <div class="card card-outline card-primary h-100">
                <div class="card-body">
                    <div class="text-muted small mb-2">{{ card.label }}</div>
                    <div class="h4 mb-0">{{ card.value }}</div>
                </div>
            </div>
        </div>
    </div>

    <div v-else-if="filterForm.type === 'online'" class="row">
        <div class="col-md-4" v-for="card in onlineCards" :key="card.label">
            <div class="card card-outline card-warning h-100">
                <div class="card-body">
                    <div class="text-muted small mb-2">{{ card.label }}</div>
                    <div class="h4 mb-0">{{ card.value }}</div>
                </div>
            </div>
        </div>
    </div>

    <div v-else class="row">
        <div class="col-md-4" v-for="card in summaryCards" :key="card.label">
            <div class="card card-outline card-dark h-100">
                <div class="card-body">
                    <div class="text-muted small mb-2">{{ card.label }}</div>
                    <div class="h4 mb-0">{{ card.value }}</div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import { adminUrl } from '../../utils/admin';

defineOptions({ layout: AppLayout });

const props = defineProps({
    filters: Object,
    reportOptions: Array,
    reportData: Object,
});

const filterForm = useForm({
    type: props.filters.type,
    date_from: props.filters.date_from,
    date_to: props.filters.date_to,
});

const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value || 0);
const toPercent = (value) => `${Number(value || 0).toFixed(2)}%`;

const offlineCards = computed(() => [
    { label: 'Total Quantity Offline', value: props.reportData.offline.total_quantity },
    { label: 'Gross Profit Offline', value: toCurrency(props.reportData.offline.gross_profit) },
    { label: 'Net Profit Offline', value: toCurrency(props.reportData.offline.net_profit) },
]);

const onlineCards = computed(() => [
    { label: 'Total Quantity Online', value: props.reportData.online.total_quantity },
    { label: 'Gross Profit Online', value: toCurrency(props.reportData.online.gross_profit) },
    { label: 'Net Profit Online', value: toCurrency(props.reportData.online.net_profit) },
]);

const summaryCards = computed(() => [
    { label: 'Revenue', value: toCurrency(props.reportData.summary.revenue) },
    { label: 'Net Profit', value: toCurrency(props.reportData.summary.net_profit) },
    { label: 'NPM Base', value: toCurrency(props.reportData.summary.npm_base) },
    { label: 'NPM Percent', value: toPercent(props.reportData.summary.npm_percent) },
    { label: 'Gross Profit Offline', value: toCurrency(props.reportData.offline.gross_profit) },
    { label: 'Gross Profit Online', value: toCurrency(props.reportData.online.gross_profit) },
    { label: 'Net Profit Offline', value: toCurrency(props.reportData.offline.net_profit) },
    { label: 'Net Profit Online', value: toCurrency(props.reportData.online.net_profit) },
]);

const applyFilter = () => {
    router.get(adminUrl('/reports'), filterForm.data(), { preserveState: true, preserveScroll: true });
};

const exportPdf = () => {
    const params = new URLSearchParams(filterForm.data()).toString();
    window.open(`${adminUrl('/reports/export-pdf')}?${params}`, '_blank', 'noopener,noreferrer');
};
</script>





