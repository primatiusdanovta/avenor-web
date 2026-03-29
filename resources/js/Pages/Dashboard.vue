<template>
    <Head title="Dashboard" />

    <div class="dashboard-page">
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

        <div class="row">
            <div class="col-md-12 col-lg-6">
                <div class="card card-outline card-warning h-100">
                    <div class="card-header"><h3 class="card-title">Ringkasan Inventory</h3></div>
                    <div class="card-body">
                        <p class="mb-1"><strong>Total Product:</strong> {{ inventorySummary.products }}</p>
                        <p class="mb-1"><strong>Raw Material:</strong> {{ inventorySummary.rawMaterials ?? 0 }}</p>
                        <p class="mb-1"><strong>Promo Aktif:</strong> {{ inventorySummary.promos }}</p>
                        <p class="mb-1"><strong>Pending Return:</strong> {{ inventorySummary.pendingReturns }}</p>
                        <p class="mb-0"><strong>Pending Sales:</strong> {{ inventorySummary.pendingSales }}</p>
                    </div>
                </div>
            </div>
            <div class="col-lg-6" v-if="dashboardData?.mode === 'manager'">
                <div class="card card-outline card-dark h-100">
                    <div class="card-header"><h3 class="card-title">Tim Saat Ini</h3></div>
                    <div class="card-body">
                        <p class="mb-1"><strong>Total Marketing:</strong> {{ dashboardData.kpis.marketing_count }}</p>
                        <p class="mb-1"><strong>Total Seller:</strong> {{ dashboardData.kpis.seller_count }}</p>
                        <p class="mb-1"><strong>Marketing On Duty:</strong> {{ dashboardData.kpis.on_duty_marketing }}</p>
                        <p class="mb-0"><strong>Net Profit Bulan Ini:</strong> {{ toCurrency(dashboardData.kpis.net_profit_total) }}</p>
                    </div>
                </div>
            </div>
            <div class="col-lg-6" v-else>
                <div class="card card-outline card-dark h-100">
                    <div class="card-header"><h3 class="card-title">Ringkasan Bulan Ini</h3></div>
                    <div class="card-body">
                        <p class="mb-1"><strong>Hari Hadir:</strong> {{ dashboardData.kpis.attendance_days }}</p>
                        <p class="mb-1"><strong>Total Revenue:</strong> {{ toCurrency(dashboardData.kpis.monthly_revenue) }}</p>
                        <p class="mb-1"><strong>Total Jam Kerja:</strong> {{ dashboardData.kpis.monthly_hours }} jam</p>
                        <p class="mb-0"><strong>Total Transaksi:</strong> {{ dashboardData.kpis.monthly_transactions }}</p>
                    </div>
                </div>
            </div>
        </div>

        <template v-if="dashboardData?.mode === 'manager'">
            <div class="row">
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-success">
                        <div class="card-header"><h3 class="card-title">Gross Profit</h3></div>
                        <div class="card-body">
                            <SimpleBarChart :labels="dashboardData.gross_profit_chart.labels" :values="dashboardData.gross_profit_chart.values" color="#198754" empty-message="Belum ada gross profit di bulan ini." />
                            <div class="text-right font-weight-bold mt-3">{{ toCurrency(dashboardData.gross_profit_chart.total) }}</div>
                        </div>
                    </div>
                </div>
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-info">
                        <div class="card-header"><h3 class="card-title">Net Profit</h3></div>
                        <div class="card-body">
                            <SimpleBarChart :labels="dashboardData.net_profit_chart.labels" :values="dashboardData.net_profit_chart.values" color="#0d6efd" empty-message="Belum ada net profit di bulan ini." />
                            <div class="text-right font-weight-bold mt-3">{{ toCurrency(dashboardData.net_profit_chart.total) }}</div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row">
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-primary h-100">
                        <div class="card-header"><h3 class="card-title">5 Produk Terlaris</h3></div>
                        <div class="card-body">
                            <SimplePieChart :labels="dashboardData.top_products_chart.labels" :values="dashboardData.top_products_chart.values" />
                        </div>
                    </div>
                </div>
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-secondary h-100">
                        <div class="card-header"><h3 class="card-title">Top 5 Produk</h3></div>
                        <div class="card-body p-0 table-responsive">
                            <table class="table table-hover mb-0">
                                <thead><tr><th>Produk</th><th>Qty</th><th>Revenue</th></tr></thead>
                                <tbody>
                                    <tr v-for="item in dashboardData.top_products_table" :key="item.label"><td>{{ item.label }}</td><td>{{ item.quantity }}</td><td>{{ toCurrency(item.revenue) }}</td></tr>
                                    <tr v-if="!dashboardData.top_products_table.length"><td colspan="3" class="text-center text-muted">Belum ada data produk terjual.</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row">
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-primary">
                        <div class="card-header"><h3 class="card-title">Top 10 Marketing</h3></div>
                        <div class="card-body p-0 table-responsive">
                            <table class="table table-striped mb-0">
                                <thead><tr><th>Nama</th><th>Qty</th><th>Revenue</th></tr></thead>
                                <tbody>
                                    <tr v-for="item in dashboardData.top_marketing" :key="item.name"><td>{{ item.name }}</td><td>{{ item.quantity }}</td><td>{{ toCurrency(item.revenue) }}</td></tr>
                                    <tr v-if="!dashboardData.top_marketing.length"><td colspan="3" class="text-center text-muted">Belum ada data marketing.</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-warning">
                        <div class="card-header"><h3 class="card-title">Top 10 Seller</h3></div>
                        <div class="card-body p-0 table-responsive">
                            <table class="table table-striped mb-0">
                                <thead><tr><th>Nama</th><th>Qty</th><th>Revenue</th></tr></thead>
                                <tbody>
                                    <tr v-for="item in dashboardData.top_resellers" :key="item.name"><td>{{ item.name }}</td><td>{{ item.quantity }}</td><td>{{ toCurrency(item.revenue) }}</td></tr>
                                    <tr v-if="!dashboardData.top_resellers.length"><td colspan="3" class="text-center text-muted">Belum ada data seller.</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </template>

        <template v-else>
            <div class="row">
                <div class="col-md-12 col-lg-4">
                    <div class="card card-outline card-primary">
                        <div class="card-header"><h3 class="card-title">Grafik Absensi</h3></div>
                        <div class="card-body"><SimpleBarChart :labels="dashboardData.attendance_chart.labels" :values="dashboardData.attendance_chart.values" color="#fd7e14" empty-message="Belum ada data absensi." /></div>
                    </div>
                </div>
                <div class="col-md-12 col-lg-4">
                    <div class="card card-outline card-success">
                        <div class="card-header"><h3 class="card-title">Grafik Penjualan</h3></div>
                        <div class="card-body"><SimpleBarChart :labels="dashboardData.sales_chart.labels" :values="dashboardData.sales_chart.values" color="#198754" empty-message="Belum ada data penjualan." /></div>
                    </div>
                </div>
                <div class="col-md-12 col-lg-4">
                    <div class="card card-outline card-info">
                        <div class="card-header"><h3 class="card-title">Jam Kerja per Hari</h3></div>
                        <div class="card-body"><SimpleBarChart :labels="dashboardData.hours_chart.labels" :values="dashboardData.hours_chart.values" color="#0dcaf0" empty-message="Belum ada data jam kerja." /></div>
                    </div>
                </div>
            </div>

            <div class="row">
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-primary h-100">
                        <div class="card-header"><h3 class="card-title">5 Produk Terlaris</h3></div>
                        <div class="card-body"><SimplePieChart :labels="dashboardData.top_products_chart.labels" :values="dashboardData.top_products_chart.values" /></div>
                    </div>
                </div>
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-secondary h-100">
                        <div class="card-header"><h3 class="card-title">Top 5 Produk Anda</h3></div>
                        <div class="card-body p-0 table-responsive">
                            <table class="table table-hover mb-0">
                                <thead><tr><th>Produk</th><th>Qty</th><th>Revenue</th></tr></thead>
                                <tbody>
                                    <tr v-for="item in dashboardData.top_products_table" :key="item.label"><td>{{ item.label }}</td><td>{{ item.quantity }}</td><td>{{ toCurrency(item.revenue) }}</td></tr>
                                    <tr v-if="!dashboardData.top_products_table.length"><td colspan="3" class="text-center text-muted">Belum ada data produk terjual.</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </template>
    </div>
</template>

<script setup>
import { defineComponent, h, ref, watch } from 'vue';
import { Head, usePage } from '@inertiajs/vue3';
import AppLayout from '../Layouts/AppLayout.vue';

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
            return h('div', { class: 'simple-bar-chart' }, [
                h('div', { class: 'd-flex align-items-end', style: 'height:220px; gap:6px;' },
                    props.values.map((value, index) => h('div', { class: 'flex-fill text-center' }, [
                        h('div', { class: 'small text-muted mb-1' }, formatCompact(value)),
                        h('div', { class: 'mx-auto rounded-top', style: `width:100%; max-width:28px; min-height:8px; height:${Math.max((Math.abs(Number(value) || 0) / max) * 150, 8)}px; background:${props.color || '#0d6efd'};` }),
                        h('div', { class: 'small text-muted mt-2' }, props.labels?.[index] || ''),
                    ]))
                ),
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
                h('div', { class: 'w-100 mt-3' },
                    (props.labels || []).map((label, index) => h('div', { class: 'd-flex align-items-center mb-2' }, [
                        h('span', { style: `display:inline-block; width:12px; height:12px; border-radius:50%; margin-right:8px; background:${palette[index % palette.length]};` }),
                        h('span', { class: 'mr-2' }, label),
                        h('span', { class: 'text-muted small ml-auto' }, `${props.values?.[index] || 0}`),
                    ]))
                ),
            ]);
        };
    },
});

defineProps({
    inventorySummary: Object,
    dashboardData: Object,
});

const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value || 0);
const formatCompact = (value) => new Intl.NumberFormat('id-ID', { notation: 'compact', maximumFractionDigits: 1 }).format(Number(value || 0));
const formatStock = (value) => new Intl.NumberFormat('id-ID', { maximumFractionDigits: 2 }).format(Number(value || 0));
</script>

<style scoped>
.dashboard-page .row {
    margin-bottom: 10px;
}
</style>

