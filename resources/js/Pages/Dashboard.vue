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

        <div v-if="isMarketing && salesAppDownload?.url" class="row">
            <div class="col-12">
                <div class="card card-outline card-success">
                    <div class="card-body d-flex flex-column flex-lg-row align-items-lg-center justify-content-between gap-3">
                        <div>
                            <div class="text-muted small text-uppercase mb-2">Sales App</div>
                            <div class="h5 mb-1">Download aplikasi sales Android terbaru</div>
                            <div class="text-muted small">{{ salesAppDownload.name || 'APK siap diunduh untuk tim marketing.' }}</div>
                        </div>
                        <a :href="salesAppDownload.url" class="btn btn-success btn-lg download-app-button">
                            <i class="fab fa-android mr-2"></i>
                            Download App Sales
                        </a>
                    </div>
                </div>
            </div>
        </div>

        <div v-if="dashboardFilters && isSuperadmin" class="row">
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

        <template v-if="dashboardData?.mode === 'manager' && isSuperadmin">
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

        <div v-if="!(dashboardData?.mode === 'manager' && isSuperadmin)" class="row">
            <div v-if="inventorySummary" class="col-md-12 col-lg-6">
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
            <div :class="inventorySummary ? 'col-lg-6' : 'col-12'" v-if="dashboardData?.mode === 'manager'">
                <div class="card card-outline card-dark h-100">
                    <div class="card-header"><h3 class="card-title">Tim Saat Ini</h3></div>
                    <div class="card-body">
                        <p class="mb-1"><strong>Periode:</strong> {{ dashboardData.period_label }}</p>
                        <p class="mb-1"><strong>Total Marketing:</strong> {{ dashboardData.kpis.marketing_count }}</p>
                        <p class="mb-1"><strong>Total Seller:</strong> {{ dashboardData.kpis.seller_count }}</p>
                        <p class="mb-1"><strong>Marketing On Duty:</strong> {{ dashboardData.kpis.on_duty_marketing }}</p>
                        <p class="mb-1"><strong>Net Profit Offline Selling:</strong> {{ toCurrency(dashboardData.kpis.net_profit_offline_total) }}</p>
                        <p class="mb-0"><strong>Net Profit Online Selling:</strong> {{ toCurrency(dashboardData.kpis.net_profit_online_total) }}</p>
                    </div>
                </div>
            </div>
            <div :class="inventorySummary ? 'col-lg-6' : 'col-12'" v-else>
                <div class="card card-outline card-dark h-100">
                    <div class="card-header"><h3 class="card-title">Ringkasan Bulan Ini</h3></div>
                    <div class="card-body">
                        <p class="mb-1"><strong>Periode:</strong> {{ dashboardData.period_label }}</p>
                        <p class="mb-1"><strong>Hari Hadir:</strong> {{ dashboardData.kpis.attendance_days }}</p>
                        <p class="mb-1"><strong>Total Revenue:</strong> {{ toCurrency(dashboardData.kpis.monthly_revenue) }}</p>
                        <p class="mb-1"><strong>Total Jam Kerja:</strong> {{ dashboardData.kpis.monthly_hours }} jam</p>
                        <p v-if="isMarketing && dashboardData.kpis.total_kpi !== null" class="mb-1"><strong>Total KPI:</strong> {{ dashboardData.kpis.total_kpi.toFixed(2) }}</p>
                        <p class="mb-0"><strong>Total Transaksi:</strong> {{ dashboardData.kpis.monthly_transactions }}</p>
                    </div>
                </div>
            </div>
        </div>

        <template v-if="dashboardData?.mode === 'manager'">
            <div v-if="showOfflineManagerContent" class="row">
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-success h-100">
                        <div class="card-header"><h3 class="card-title">Gross Profit Offline Selling</h3></div>
                        <div class="card-body">
                            <SimpleBarChart :labels="dashboardData.gross_profit_offline_chart.labels" :values="dashboardData.gross_profit_offline_chart.values" color="#198754" empty-message="Belum ada gross profit offline di bulan ini." />
                            <div class="text-right font-weight-bold mt-3">{{ toCurrency(dashboardData.gross_profit_offline_chart.total) }}</div>
                        </div>
                    </div>
                </div>
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-info h-100">
                        <div class="card-header"><h3 class="card-title">Net Profit Offline Selling</h3></div>
                        <div class="card-body">
                            <SimpleBarChart :labels="dashboardData.net_profit_offline_chart.labels" :values="dashboardData.net_profit_offline_chart.values" color="#0d6efd" empty-message="Belum ada net profit offline di bulan ini." />
                            <div class="text-right font-weight-bold mt-3">{{ toCurrency(dashboardData.net_profit_offline_chart.total) }}</div>
                        </div>
                    </div>
                </div>
            </div>

            <div v-if="showOnlineManagerContent" class="row">
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-warning h-100">
                        <div class="card-header"><h3 class="card-title">Gross Profit Online Selling</h3></div>
                        <div class="card-body">
                            <SimpleBarChart :labels="dashboardData.gross_profit_online_chart.labels" :values="dashboardData.gross_profit_online_chart.values" color="#fd7e14" empty-message="Belum ada gross profit online di bulan ini." />
                            <div class="text-right font-weight-bold mt-3">{{ toCurrency(dashboardData.gross_profit_online_chart.total) }}</div>
                        </div>
                    </div>
                </div>
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-primary h-100">
                        <div class="card-header"><h3 class="card-title">Net Profit Online Selling</h3></div>
                        <div class="card-body">
                            <SimpleBarChart :labels="dashboardData.net_profit_online_chart.labels" :values="dashboardData.net_profit_online_chart.values" color="#6610f2" empty-message="Belum ada net profit online di bulan ini." />
                            <div class="text-right font-weight-bold mt-3">{{ toCurrency(dashboardData.net_profit_online_chart.total) }}</div>
                        </div>
                    </div>
                </div>
            </div>

            <div v-if="showOfflineManagerContent" class="row">
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-primary h-100">
                        <div class="card-header"><h3 class="card-title">5 Product Terlaris Offline Sales</h3></div>
                        <div class="card-body"><SimplePieChart :labels="dashboardData.top_products_offline_chart.labels" :values="dashboardData.top_products_offline_chart.values" /></div>
                    </div>
                </div>
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-secondary h-100">
                        <div class="card-header"><h3 class="card-title">Top 5 Product Offline Sales</h3></div>
                        <div class="card-body p-0 table-responsive">
                            <table class="table table-hover mb-0">
                                <thead><tr><th>Produk</th><th>Qty</th><th>Revenue</th></tr></thead>
                                <tbody>
                                    <tr v-for="item in dashboardData.top_products_offline_table" :key="item.label"><td>{{ item.label }}</td><td>{{ item.quantity }}</td><td>{{ toCurrency(item.revenue) }}</td></tr>
                                    <tr v-if="!dashboardData.top_products_offline_table.length"><td colspan="3" class="text-center text-muted">Belum ada data produk offline terjual.</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <div v-if="showOnlineManagerContent" class="row">
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-warning h-100">
                        <div class="card-header"><h3 class="card-title">5 Product Terlaris Online Selling</h3></div>
                        <div class="card-body"><SimplePieChart :labels="dashboardData.top_products_online_chart.labels" :values="dashboardData.top_products_online_chart.values" /></div>
                    </div>
                </div>
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-dark h-100">
                        <div class="card-header"><h3 class="card-title">Top 5 Product Online Selling</h3></div>
                        <div class="card-body p-0 table-responsive">
                            <table class="table table-hover mb-0">
                                <thead><tr><th>Produk</th><th>Qty</th><th>Revenue</th></tr></thead>
                                <tbody>
                                    <tr v-for="item in dashboardData.top_products_online_table" :key="item.label"><td>{{ item.label }}</td><td>{{ item.quantity }}</td><td>{{ toCurrency(item.revenue) }}</td></tr>
                                    <tr v-if="!dashboardData.top_products_online_table.length"><td colspan="3" class="text-center text-muted">Belum ada data produk online terjual.</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <div v-if="showOfflineManagerContent || showOnlineManagerContent" class="row">
                <div v-if="showOfflineManagerContent" class="col-md-12 col-lg-6">
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
                <div v-if="showOnlineManagerContent" class="col-md-12 col-lg-6">
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
            <div v-if="isMarketing && dashboardData.marketing_kpi" class="row">
                <div class="col-md-4">
                    <div class="card card-outline card-primary h-100"><div class="card-body"><div class="text-muted small">KPI Penjualan</div><div class="h4 mb-0">{{ dashboardData.marketing_kpi.sales_score.toFixed(2) }} / 70</div><div class="small text-muted mt-2">{{ dashboardData.marketing_kpi.quantity_sold }}/{{ dashboardData.marketing_kpi.sales_target }} pcs</div></div></div>
                </div>
                <div class="col-md-4">
                    <div class="card card-outline card-warning h-100"><div class="card-body"><div class="text-muted small">KPI Kehadiran</div><div class="h4 mb-0">{{ dashboardData.marketing_kpi.attendance_score.toFixed(2) }} / 20</div><div class="small text-muted mt-2">{{ dashboardData.marketing_kpi.attendance_days }}/{{ dashboardData.marketing_kpi.attendance_target }} hari</div></div></div>
                </div>
                <div class="col-md-4">
                    <div class="card card-outline card-info h-100"><div class="card-body"><div class="text-muted small">KPI Jam Kerja</div><div class="h4 mb-0">{{ dashboardData.marketing_kpi.hours_score.toFixed(2) }} / 10</div><div class="small text-muted mt-2">{{ dashboardData.marketing_kpi.average_hours_per_day.toFixed(2) }}/{{ dashboardData.marketing_kpi.hours_target }} jam per hari</div></div></div>
                </div>
            </div>

            <div class="row">
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-primary h-100">
                        <div class="card-header"><h3 class="card-title">Target Penjualan {{ dashboardData.target_summary.period_label }}</h3></div>
                        <div class="card-body">
                            <p class="mb-1"><strong>Bulan Saat Ini:</strong> {{ dashboardData.target_summary.period_label }}</p>
                            <p class="mb-1"><strong>Target Harian Terpenuhi:</strong> {{ dashboardData.target_summary.daily.achieved_count }} / {{ dashboardData.target_summary.daily.total_periods }} hari</p>
                            <p class="mb-1 text-muted">Qty target harian {{ dashboardData.target_summary.daily.target_qty }} | Bonus tercapai {{ toCurrency(dashboardData.target_summary.daily.bonus) }}</p>
                            <p class="mb-1"><strong>Target Mingguan Terpenuhi:</strong> {{ dashboardData.target_summary.weekly.achieved_count }} / {{ dashboardData.target_summary.weekly.total_periods }} minggu</p>
                            <p class="mb-1 text-muted">Qty target mingguan {{ dashboardData.target_summary.weekly.target_qty }} | Bonus tercapai {{ toCurrency(dashboardData.target_summary.weekly.bonus) }}</p>
                            <p class="mb-1"><strong>Target Bulanan:</strong> {{ dashboardData.target_summary.monthly.met ? 'Terpenuhi' : 'Belum Terpenuhi' }} ({{ dashboardData.target_summary.monthly.total_quantity }}/{{ dashboardData.target_summary.monthly.target_qty }})</p>
                            <p class="mb-1 text-muted">Bonus bulanan tercapai {{ toCurrency(dashboardData.target_summary.monthly.bonus) }}</p>
                            <p class="mb-0"><strong>Bonus anda saat ini:</strong> {{ toCurrency(dashboardData.target_summary.bonus_total) }}</p>
                            <div v-if="dashboardData.target_summary.reminder" class="alert alert-warning mt-3 mb-0">{{ dashboardData.target_summary.reminder }}</div>
                        </div>
                    </div>
                </div>
                <div class="col-md-12 col-lg-6">
                    <div class="card card-outline card-secondary h-100">
                        <div class="card-header"><h3 class="card-title">History Penjualan {{ dashboardData.previous_target_summary.period_label }}</h3></div>
                        <div class="card-body">
                            <p class="mb-1"><strong>Target Harian Terpenuhi:</strong> {{ dashboardData.previous_target_summary.daily.achieved_count }} / {{ dashboardData.previous_target_summary.daily.total_periods }} hari</p>
                            <p class="mb-1 text-muted">Qty target harian {{ dashboardData.previous_target_summary.daily.target_qty }} | Bonus tercapai {{ toCurrency(dashboardData.previous_target_summary.daily.bonus) }}</p>
                            <p class="mb-1"><strong>Target Mingguan Terpenuhi:</strong> {{ dashboardData.previous_target_summary.weekly.achieved_count }} / {{ dashboardData.previous_target_summary.weekly.total_periods }} minggu</p>
                            <p class="mb-1 text-muted">Qty target mingguan {{ dashboardData.previous_target_summary.weekly.target_qty }} | Bonus tercapai {{ toCurrency(dashboardData.previous_target_summary.weekly.bonus) }}</p>
                            <p class="mb-1"><strong>Target Bulanan:</strong> {{ dashboardData.previous_target_summary.monthly.met ? 'Terpenuhi' : 'Belum Terpenuhi' }} ({{ dashboardData.previous_target_summary.monthly.total_quantity }}/{{ dashboardData.previous_target_summary.monthly.target_qty }})</p>
                            <p class="mb-1 text-muted">Bonus bulanan tercapai {{ toCurrency(dashboardData.previous_target_summary.monthly.bonus) }}</p>
                            <p class="mb-0"><strong>Bonus bulan lalu:</strong> {{ toCurrency(dashboardData.previous_target_summary.bonus_total) }}</p>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row">
                <div v-if="dashboardData.attendance_chart.values.length" class="col-md-12 col-lg-6 col-xl-4 mb-3"><div class="card card-outline card-primary h-100"><div class="card-header"><h3 class="card-title">Grafik Absensi</h3></div><div class="card-body"><SimpleBarChart :labels="dashboardData.attendance_chart.labels" :values="dashboardData.attendance_chart.values" color="#fd7e14" empty-message="Belum ada data absensi." /></div></div></div>
                <div v-if="dashboardData.sales_chart.values.length" class="col-md-12 col-lg-6 col-xl-4 mb-3"><div class="card card-outline card-success h-100"><div class="card-header"><h3 class="card-title">Grafik Penjualan</h3></div><div class="card-body"><SimpleBarChart :labels="dashboardData.sales_chart.labels" :values="dashboardData.sales_chart.values" color="#198754" empty-message="Belum ada data penjualan." /></div></div></div>
                <div v-if="dashboardData.hours_chart.values.length" class="col-md-12 col-lg-6 col-xl-4 mb-3"><div class="card card-outline card-info h-100"><div class="card-header"><h3 class="card-title">Jam Kerja per Hari</h3></div><div class="card-body"><SimpleBarChart :labels="dashboardData.hours_chart.labels" :values="dashboardData.hours_chart.values" color="#0dcaf0" empty-message="Belum ada data jam kerja." /></div></div></div>
            </div>

            <div class="row">
                <div class="col-md-12 col-lg-6"><div class="card card-outline card-primary h-100"><div class="card-header"><h3 class="card-title">5 Produk Terlaris</h3></div><div class="card-body"><SimplePieChart :labels="dashboardData.top_products_chart.labels" :values="dashboardData.top_products_chart.values" /></div></div></div>
                <div class="col-md-12 col-lg-6"><div class="card card-outline card-secondary h-100"><div class="card-header"><h3 class="card-title">Top 5 Produk Anda</h3></div><div class="card-body p-0 table-responsive"><table class="table table-hover mb-0"><thead><tr><th>Produk</th><th>Qty</th><th>Revenue</th></tr></thead><tbody><tr v-for="item in dashboardData.top_products_table" :key="item.label"><td>{{ item.label }}</td><td>{{ item.quantity }}</td><td>{{ toCurrency(item.revenue) }}</td></tr><tr v-if="!dashboardData.top_products_table.length"><td colspan="3" class="text-center text-muted">Belum ada data produk terjual.</td></tr></tbody></table></div></div></div>
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












