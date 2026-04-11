<template>
    <Head title="Dashboard" />

    <div class="dashboard-page">
        <!-- Inventory Alert -->
        <div v-if="showInventoryAlert && hasInventoryAlerts" class="alert alert-warning alert-dismissible fade show" role="alert">
            <button type="button" class="btn-close" aria-label="Close" @click="showInventoryAlert = false"></button>
            <div class="fw-bold mb-2">Peringatan stock minimum</div>
            <div v-if="inventoryAlerts.products?.length" class="mb-2">
                <strong>Product stock &lt; 20:</strong>
                {{ inventoryAlerts.products.map((item) => `${item.name} (${item.value} ${item.unit})`).join(', ') }}
            </div>
            <div v-if="inventoryAlerts.rawMaterials?.length">
                <strong>Raw material total quantity &lt; 200:</strong>
                {{ inventoryAlerts.rawMaterials.map((item) => `${item.name} (${formatStock(item.value)} ${item.unit})`).join(', ') }}
            </div>
        </div>

        <!-- Sales App Download -->
        <div v-if="isMarketing && salesAppDownload" class="row">
            <div class="col-12">
                <div class="card card-outline card-success">
                    <div class="card-body d-flex flex-column flex-lg-row align-items-lg-center justify-content-between gap-3">
                        <div>
                            <div class="text-muted small text-uppercase mb-2">Sales App</div>
                            <div class="h5 mb-1">Download aplikasi sales lapangan Android terbaru</div>
                            <div class="text-muted small">{{ salesAppDownload.name || 'File APK belum diunggah oleh superadmin.' }}</div>
                        </div>
                        <component
                            :is="salesAppDownload.url ? 'a' : 'button'"
                            :href="salesAppDownload.url || null"
                            type="button"
                            class="btn btn-lg download-app-button"
                            :class="salesAppDownload.url ? 'btn-success' : 'btn-outline-secondary disabled'"
                            :disabled="!salesAppDownload.url"
                            target="_blank"
                            rel="noopener"
                            :aria-disabled="!salesAppDownload.url"
                        >
                            <i class="fab fa-android mr-2"></i>
                            Download App Sales
                        </component>
                    </div>
                </div>
            </div>
        </div>

        <!-- Dashboard Filter -->
        <div v-if="dashboardFilters && (isSuperadmin || isOwner)" class="row">
            <div class="col-12">
                <div class="card card-outline card-secondary">
                    <div class="card-header"><h3 class="card-title">Filter Dashboard</h3></div>
                    <div class="card-body">
                        <form class="row align-items-end" @submit.prevent="applyDashboardFilter">
                            <div class="col-md-3 mb-3 mb-md-0">
                                <label class="mb-1">Jenis Penjualan</label>
                                <select v-model="filterForm.type" class="form-control">
                                    <option v-for="type in dashboardFilters.types" :key="type.value" :value="type.value">{{ type.label }}</option>
                                </select>
                            </div>
                            <div class="col-md-3 mb-3 mb-md-0">
                                <label class="mb-1">Bulan</label>
                                <select v-model="filterForm.month" class="form-control">
                                    <option v-for="month in dashboardFilters.months" :key="month.value" :value="month.value">{{ month.label }}</option>
                                </select>
                            </div>
                            <div class="col-md-3 mb-3 mb-md-0">
                                <label class="mb-1">Tahun</label>
                                <select v-model="filterForm.year" class="form-control">
                                    <option v-for="year in dashboardFilters.years" :key="year.value" :value="year.value">{{ year.label }}</option>
                                </select>
                            </div>
                            <div class="col-md-3">
                                <button type="submit" class="btn btn-outline-primary w-100">Tampilkan {{ selectedDashboardPeriodLabel }}</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>

        <!-- Manager Content -->
        <template v-if="dashboardData?.mode === 'manager' && (isSuperadmin || isOwner)">
            <div class="row">
                <div class="col-xl-6 col-md-6 mb-3">
                    <div class="card card-outline card-primary h-100">
                        <div class="card-body">
                            <div class="text-muted small text-uppercase mb-2">Penjualan Offline</div>
                            <div class="h4 mb-1">{{ toCurrency(dashboardData.kpis.gross_profit_offline_total) }}</div>
                            <div class="text-muted">Total product terjual: {{ formatCompact(dashboardData.kpis.product_sold_offline) }}</div>
                        </div>
                    </div>
                </div>
                <div class="col-xl-6 col-md-6 mb-3">
                    <div class="card card-outline card-warning h-100">
                        <div class="card-body">
                            <div class="text-muted small text-uppercase mb-2">Penjualan Online</div>
                            <div class="h4 mb-1">{{ toCurrency(dashboardData.kpis.gross_profit_online_total) }}</div>
                            <div class="text-muted">Total product terjual: {{ formatCompact(dashboardData.kpis.product_sold_online) }}</div>
                        </div>
                    </div>
                </div>
                <div class="col-xl-4 col-md-4 mb-3">
                    <div class="card card-outline card-secondary h-100">
                        <div class="card-body">
                            <div class="text-muted small text-uppercase mb-2">Revenue</div>
                            <div class="h4 mb-1">{{ toCurrency(dashboardData.kpis.revenue_total) }}</div>
                        </div>
                    </div>
                </div>
                <div class="col-xl-4 col-md-4 mb-3">
                    <div class="card card-outline card-success h-100">
                        <div class="card-body">
                            <div class="text-muted small text-uppercase mb-2">Gross Profit</div>
                            <div class="h4 mb-1">{{ toCurrency(dashboardData.kpis.gross_profit_total) }}</div>
                        </div>
                    </div>
                </div>
                <div class="col-xl-4 col-md-4 mb-3">
                    <div class="card card-outline card-dark h-100">
                        <div class="card-body">
                            <div class="text-muted small text-uppercase mb-2">Net Profit</div>
                            <div class="h4 mb-1">{{ toCurrency(dashboardData.kpis.net_profit_total) }}</div>
                        </div>
                    </div>
                </div>
            </div>
        </template>

        <!-- Marketing/Other Content -->
        <template v-else>
            <div v-if="isMarketing && dashboardData?.marketing_kpi" class="row">
                <div class="col-12">
                    <div class="card card-outline card-warning h-100">
                        <div class="card-header"><h3 class="card-title">Ringkasan Inventory</h3></div>
                        <div class="card-body">
                            <p class="mb-1"><strong>Total Product:</strong> {{ inventorySummary.products }}</p>
                            <p class="mb-1"><strong>Raw Material:</strong> {{ inventorySummary.rawMaterials ?? 0 }}</p>
                            <p class="mb-1"><strong>Promo Aktif:</strong> {{ inventorySummary.promos }}</p>
                        </div>
                    </div>
                </div>
            </div>
        </template>
    </div>
</template>


<script setup>
import { computed, defineComponent, h, ref, watch } from 'vue';
import { Head, router, useForm, usePage } from '@inertiajs/vue3';
import AppLayout from '../Layouts/AppLayout.vue';
import { adminUrl } from '../utils/admin';

defineOptions({ layout: AppLayout });

const page = usePage();
const inventoryAlerts = page.props.inventoryAlerts ?? null;
const hasInventoryAlerts = Boolean(inventoryAlerts?.products?.length || inventoryAlerts?.rawMaterials?.length);
const showInventoryAlert = ref(true);

watch(() => page.url, () => {
    showInventoryAlert.value = true;
});

const SimpleBarChart = defineComponent({
    props: { labels: Array, values: Array, color: String, emptyMessage: String },
    setup(props) {
        return () => {
            if (!props.values?.length) {
                return h('div', { class: 'text-center text-muted py-5' }, props.emptyMessage || 'Belum ada data.');
            }

            const max = Math.max(...props.values.map((value) => Math.abs(Number(value) || 0)), 1);
            const barWidth = 46;
            const gap = 12;
            const minChartWidth = Math.max(((props.values.length || 0) * (barWidth + gap)) + gap, 280);

            return h('div', { class: 'simple-bar-chart overflow-auto pb-2' }, [
                h('div', { class: 'd-flex align-items-end', style: `height:240px; gap:${gap}px; min-width:${minChartWidth}px;` }, props.values.map((value, index) => h('div', { class: 'text-center d-flex flex-column justify-content-end align-items-center', style: `width:${barWidth}px; flex:0 0 ${barWidth}px;` }, [
                    h('div', { class: 'small text-muted mb-2', style: 'line-height:1.1; white-space:normal; word-break:break-word;' }, formatCompact(value)),
                    h('div', { class: 'w-100 d-flex align-items-end', style: 'height:150px;' }, [
                        h('div', { class: 'w-100 rounded-top', style: `min-height:8px; height:${Math.max((Math.abs(Number(value) || 0) / max) * 150, 8)}px; background:${props.color || '#0d6efd'};` }),
                    ]),
                    h('div', { class: 'small text-muted mt-2', style: 'line-height:1.1;' }, props.labels?.[index] || ''),
                ]))),
            ]);
        };
    },
});

const SimplePieChart = defineComponent({
    props: { labels: Array, values: Array },
    setup(props) {
        const palette = ['#0d6efd', '#198754', '#ffc107', '#dc3545', '#6f42c1'];

        return () => {
            const total = (props.values || []).reduce((sum, value) => sum + Number(value || 0), 0);
            if (!total) {
                return h('div', { class: 'text-center text-muted py-5' }, 'Belum ada data produk terlaris.');
            }

            let cursor = 0;
            const gradient = (props.values || []).map((value, index) => {
                const slice = (Number(value || 0) / total) * 100;
                const start = cursor;
                cursor += slice;
                return `${palette[index % palette.length]} ${start}% ${cursor}%`;
            }).join(', ');

            return h('div', { class: 'd-flex flex-column align-items-center' }, [
                h('div', { style: `width:220px; height:220px; border-radius:50%; background:conic-gradient(${gradient});` }),
                h('div', { class: 'w-100 mt-3' }, (props.labels || []).map((label, index) => h('div', { class: 'd-flex align-items-center mb-2' }, [
                    h('span', { style: `display:inline-block; width:12px; height:12px; border-radius:50%; margin-right:8px; background:${palette[index % palette.length]};` }),
                    h('span', { class: 'mr-2' }, label),
                    h('span', { class: 'text-muted small ml-auto' }, `${props.values?.[index] || 0}`),
                ]))),
            ]);
        };
    },
});

const props = defineProps({ summary: Object, inventorySummary: Object, dashboardData: Object, dashboardFilters: Object, salesAppDownload: Object });
const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value || 0);
const formatCompact = (value) => new Intl.NumberFormat('id-ID', { notation: 'compact', maximumFractionDigits: 1 }).format(Number(value || 0));
const formatStock = (value) => new Intl.NumberFormat('id-ID', { maximumFractionDigits: 2 }).format(Number(value || 0));
const toPercent = (value) => `${Number(value || 0).toFixed(2)}%`;
const isSuperadmin = computed(() => props.summary?.currentRole === 'superadmin');
const isOwner = computed(() => props.summary?.currentRole === 'owner');
const isMarketing = computed(() => props.summary?.currentRole === 'marketing');
const filterForm = useForm({ type: props.dashboardFilters?.type ?? 'all', month: props.dashboardFilters?.month ?? new Date().getMonth() + 1, year: props.dashboardFilters?.year ?? new Date().getFullYear() });
const selectedDashboardPeriodLabel = computed(() => {
    const selectedMonth = props.dashboardFilters?.months?.find((month) => Number(month.value) === Number(filterForm.month));
    const selectedType = props.dashboardFilters?.types?.find((type) => String(type.value) === String(filterForm.type));
    const monthLabel = selectedMonth?.label ?? 'Bulan';
    const typeLabel = selectedType?.label ?? 'All Selling';
    return `${typeLabel} | ${monthLabel} ${filterForm.year}`.trim();
});

const applyDashboardFilter = () => {
    router.get(adminUrl('/dashboard'), filterForm.data(), { preserveScroll: true, preserveState: true, replace: true });
};

const showOfflineManagerContent = computed(() => ['all', 'offline'].includes(props.dashboardData?.active_filter_type || 'all'));
const showOnlineManagerContent = computed(() => ['all', 'online'].includes(props.dashboardData?.active_filter_type || 'all'));
</script>

<style scoped>
.dashboard-page .row {
    margin-bottom: 10px;
}

.download-app-button {
    min-width: 240px;
}
</style>















