<template>
    <Head title="Marketing" />

    <div class="row">
        <div class="col-12">
            <div class="card card-outline card-secondary">
                <div class="card-header"><h3 class="card-title">Filter KPI Marketing</h3></div>
                <div class="card-body">
                    <form class="row align-items-end" @submit.prevent="submitSearch">
                        <div class="col-md-4 mb-3 mb-md-0">
                            <label class="mb-1">Bulan</label>
                            <select v-model="searchForm.month" class="form-control">
                                <option v-for="month in periodFilters.months" :key="month.value" :value="month.value">{{ month.label }}</option>
                            </select>
                        </div>
                        <div class="col-md-4 mb-3 mb-md-0">
                            <label class="mb-1">Tahun</label>
                            <select v-model="searchForm.year" class="form-control">
                                <option v-for="year in periodFilters.years" :key="year.value" :value="year.value">{{ year.label }}</option>
                            </select>
                        </div>
                        <div class="col-md-4">
                            <label class="mb-1">Cari Marketing</label>
                            <div class="d-flex">
                                <input v-model="searchForm.search" type="text" class="form-control mr-2" placeholder="Cari marketing">
                                <button class="btn btn-outline-primary" type="submit">Terapkan</button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-md-12 col-lg-4">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Tambah Marketing</h3></div>
                <div class="card-body">
                    <form @submit.prevent="submitCreate">
                        <div class="form-group"><label>Nama Marketing</label><input v-model="createForm.nama" type="text" class="form-control"></div>
                        <div class="form-group"><label>Status</label><Select2Input v-model="createForm.status" :options="statuses" placeholder="Pilih status" /></div>
                        <div class="form-group"><label>Password</label><input v-model="createForm.password" type="password" class="form-control"></div>
                        <div class="form-group"><label>Konfirmasi Password</label><input v-model="createForm.password_confirmation" type="password" class="form-control"></div>
                        <button type="submit" class="btn btn-primary mt-2" :disabled="createForm.processing">Tambah Marketing</button>
                    </form>
                </div>
            </div>

            <div class="card card-outline card-warning">
                <div class="card-header"><h3 class="card-title">Edit Marketing</h3></div>
                <div v-if="selectedMarketing" class="card-body">
                    <div class="form-group"><label>Nama Marketing</label><input v-model="editForm.nama" type="text" class="form-control"></div>
                    <div class="form-group"><label>Status</label><Select2Input v-model="editForm.status" :options="statuses" placeholder="Pilih status" /></div>
                    <div class="form-group"><label>Password Baru</label><input v-model="editForm.password" type="password" class="form-control"></div>
                    <div class="form-group"><label>Konfirmasi Password Baru</label><input v-model="editForm.password_confirmation" type="password" class="form-control"></div>
                    <button class="btn btn-warning mr-2" @click="submitEdit">Simpan</button>
                    <button class="btn btn-secondary" @click="clearSelection">Batal</button>
                </div>
                <div v-else class="card-body text-muted">Klik tombol detail pada tabel untuk melihat dan mengedit marketing.</div>
            </div>
        </div>

        <div class="col-md-12 col-lg-8">
            <div class="card card-outline card-info">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h3 class="card-title">Daftar Marketing</h3>
                </div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Nama</th><th>Status</th><th>Absensi</th><th>Total KPI</th><th>Penjualan</th><th>Kehadiran</th><th>Jam Kerja/Hari</th><th>Barang Dibawa</th><th style="min-width: 220px;">Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in marketers" :key="item.id_user">
                                <td><button type="button" class="btn btn-link p-0 font-weight-bold text-primary text-decoration-none" @click="openDetail(item.id_user)">{{ item.nama }}</button></td>
                                <td>{{ item.status }}</td>
                                <td>{{ item.today_status }}</td>
                                <td><span class="badge kpi-badge">{{ item.kpi.total_score.toFixed(2) }}</span></td>
                                <td>{{ item.kpi.quantity_sold }}/{{ item.kpi.sales_target }} pcs</td>
                                <td>{{ item.kpi.attendance_days }}/{{ item.kpi.attendance_target }} hari</td>
                                <td>{{ item.kpi.average_hours_per_day.toFixed(2) }}/{{ item.kpi.hours_target }} jam</td>
                                <td>
                                    <div v-if="item.carried_items.length">
                                        <div v-for="carry in item.carried_items" :key="`${item.id_user}-${carry.nama_product}-${carry.take_status}-${carry.return_status}`" class="text-sm">
                                            {{ carry.nama_product }} ({{ carry.quantity }}) - ambil: {{ carry.take_status_label }} - status: {{ carry.status_label }}
                                        </div>
                                    </div>
                                    <span v-else class="text-muted">-</span>
                                </td>
                                <td>
                                    <div class="d-flex flex-wrap gap-2 action-group">
                                        <button type="button" class="btn btn-xs btn-outline-primary" @click="openDetail(item.id_user)">Detail Marketing</button>
                                        <button v-if="isSuperadmin" type="button" class="btn btn-xs btn-outline-dark" @click="openMonitoring(item)">Monitoring Marketing</button>
                                        <button type="button" class="btn btn-xs btn-danger" @click="removeMarketing(item)">Hapus</button>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="!marketers.length"><td colspan="9" class="text-center text-muted py-4">Belum ada data marketing.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showDetailModal" title="Detail Marketing" size="xl" @close="closeDetailModal">
        <div v-if="detailLoading" class="text-center py-4 text-muted">Memuat detail marketing...</div>
        <div v-else-if="selectedMarketing">
            <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-center mb-3">
                <div>
                    <h4 class="mb-1">{{ selectedMarketing.nama }}</h4>
                    <div class="text-muted">Status akun: {{ selectedMarketing.status }}</div>
                </div>
                <div class="d-flex flex-wrap gap-2 mt-3 mt-lg-0">
                    <span class="badge badge-primary px-3 py-2">KPI {{ selectedMarketing.current_kpi.total_score.toFixed(2) }}</span>
                    <span class="badge policy-badge" :class="returnPolicyBadgeClass(selectedMarketing.require_return_before_checkout)">
                        {{ selectedMarketing.require_return_before_checkout ? 'Wajib Pengembalian' : 'Checkout Tanpa Pengembalian' }}
                    </span>
                </div>
            </div>

            <div class="row detail-grid mb-3">
                <div class="col-md-6 col-xl-3 mb-3">
                    <div class="detail-card">
                        <div class="detail-label">Product Terjual</div>
                        <div class="detail-value">{{ selectedMarketing.current_kpi.quantity_sold }}/{{ selectedMarketing.current_kpi.sales_target }} pcs</div>
                    </div>
                </div>
                <div class="col-md-6 col-xl-3 mb-3">
                    <div class="detail-card">
                        <div class="detail-label">Kehadiran</div>
                        <div class="detail-value">{{ selectedMarketing.current_kpi.attendance_days }}/{{ selectedMarketing.current_kpi.attendance_target }} hari</div>
                    </div>
                </div>
                <div class="col-md-6 col-xl-3 mb-3">
                    <div class="detail-card">
                        <div class="detail-label">Jam Kerja / Hari</div>
                        <div class="detail-value">{{ selectedMarketing.current_kpi.average_hours_per_day.toFixed(2) }}/{{ selectedMarketing.current_kpi.hours_target }} jam</div>
                    </div>
                </div>
                <div class="col-md-6 col-xl-3 mb-3">
                    <div class="detail-card">
                        <div class="detail-label">Status Hari Ini</div>
                        <div class="detail-value">{{ selectedMarketing.today_attendance?.status || 'belum absen' }}</div>
                    </div>
                </div>
            </div>

            <div class="card bg-light border-0 mb-3">
                <div class="card-body py-3">
                    <div class="row">
                        <div class="col-md-4 mb-3 mb-md-0">
                            <div class="small text-muted">Check In</div>
                            <div class="font-weight-bold">{{ selectedMarketing.today_attendance?.check_in || '-' }}</div>
                        </div>
                        <div class="col-md-4 mb-3 mb-md-0">
                            <div class="small text-muted">Check Out</div>
                            <div class="font-weight-bold">{{ selectedMarketing.today_attendance?.check_out || '-' }}</div>
                        </div>
                        <div class="col-md-4">
                            <div class="small text-muted">Catatan</div>
                            <div class="font-weight-bold">{{ selectedMarketing.today_attendance?.notes || '-' }}</div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row">
                <div class="col-lg-7 mb-3 mb-lg-0">
                    <div class="section-panel h-100">
                        <div class="section-title">Ringkasan KPI</div>
                        <div class="summary-line"><span>Skor Penjualan</span><strong>{{ selectedMarketing.current_kpi.sales_score.toFixed(2) }} / 70</strong></div>
                        <div class="summary-line"><span>Skor Kehadiran</span><strong>{{ selectedMarketing.current_kpi.attendance_score.toFixed(2) }} / 20</strong></div>
                        <div class="summary-line"><span>Skor Jam Kerja</span><strong>{{ selectedMarketing.current_kpi.hours_score.toFixed(2) }} / 10</strong></div>
                        <div class="section-subtitle mt-4">Riwayat KPI 6 Bulan</div>
                        <div v-if="selectedMarketing.kpi_history?.length" class="history-stack">
                            <div v-for="history in selectedMarketing.kpi_history" :key="history.period_label" class="history-item">
                                <div>
                                    <div class="font-weight-bold">{{ history.period_label }}</div>
                                    <div class="small text-muted">{{ history.quantity_sold }} pcs | {{ history.attendance_days }} hari | {{ history.average_hours_per_day.toFixed(2) }} jam</div>
                                </div>
                                <span class="badge badge-dark">{{ history.total_score.toFixed(2) }}</span>
                            </div>
                        </div>
                        <div v-else class="text-muted">Belum ada riwayat KPI.</div>
                    </div>
                </div>
                <div class="col-lg-5">
                    <div class="section-panel mb-3">
                        <div class="section-title">Lokasi Terakhir</div>
                        <template v-if="selectedMarketing.latest_location">
                            <div class="small text-muted mb-2">
                                {{ selectedMarketing.latest_location.latitude }}, {{ selectedMarketing.latest_location.longitude }}
                            </div>
                            <div class="small text-muted mb-2">Direkam: {{ selectedMarketing.latest_location.recorded_at }}</div>
                            <div class="small text-muted mb-3">Sumber: {{ selectedMarketing.latest_location.source }}</div>
                            <iframe :src="selectedMarketing.latest_location.map_url" width="100%" height="220" style="border:0; border-radius: 12px;" loading="lazy"></iframe>
                        </template>
                        <div v-else class="text-muted">Belum ada data lokasi terbaru.</div>
                    </div>
                    <div class="section-panel">
                        <div class="section-title">Barang Yang Dibawa Hari Ini</div>
                        <div v-if="selectedMarketing.carried_items?.length" class="carried-stack">
                            <div v-for="item in selectedMarketing.carried_items" :key="item.id_product_onhand" class="carried-item">
                                <div class="font-weight-bold">{{ item.nama_product }}</div>
                                <div class="small text-muted mb-2">Dibawa {{ item.quantity }} | Return {{ item.quantity_dikembalikan }} | Sisa {{ item.remaining_quantity }}</div>
                                <div class="d-flex flex-wrap gap-2 align-items-center">
                                    <span class="badge status-badge" :class="takeStatusBadgeClass(item.take_status)">{{ item.take_status_label }}</span>
                                    <span class="badge status-badge" :class="returnStatusBadgeClass(item.return_status)">{{ item.status_label }}</span>
                                    <div v-if="item.return_status === 'pending'" class="btn-group btn-group-sm ml-auto">
                                        <button class="btn btn-success" @click="approveReturn(item)"><i class="fas fa-check"></i></button>
                                        <button class="btn btn-danger" @click="rejectReturn(item)"><i class="fas fa-times"></i></button>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div v-else class="text-muted">Belum ada barang yang dibawa hari ini.</div>
                    </div>
                </div>
            </div>
        </div>
        <div v-else class="text-muted">Data marketing belum tersedia.</div>
        <template #footer>
            <Link href="/approvals" class="btn btn-outline-primary">Buka Halaman Approval</Link>
            <button type="button" class="btn btn-secondary" @click="closeDetailModal">Tutup</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showMonitoringModal" title="Monitoring Marketing" size="lg" @close="closeMonitoringModal">
        <div v-if="monitoringTarget">
            <h5 class="mb-2">{{ monitoringTarget.nama }}</h5>
            <p class="text-muted mb-3">Superadmin dapat mengatur apakah marketing perlu mengembalikan barang. Jika perlu, marketing harus mengembalikan barang sebelum checkout. Jika tidak, marketing bisa checkout tanpa mengembalikan barang.</p>
            <div class="form-group mb-0">
                <label class="mb-1">Pengembalian Barang</label>
                <select v-model="monitoringForm.require_return_before_checkout" class="form-control">
                    <option :value="true">Wajib mengembalikan barang sebelum checkout</option>
                    <option :value="false">Tidak wajib, boleh checkout tanpa pengembalian</option>
                </select>
            </div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeMonitoringModal">Batal</button>
            <button type="button" class="btn btn-primary" :disabled="monitoringForm.processing || !monitoringTarget" @click="submitMonitoring">Pengembalian Barang</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        Hapus akun marketing {{ deleteTarget?.nama }}?
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeDeleteModal">Batal</button>
            <button type="button" class="btn btn-danger" @click="confirmDelete">Hapus</button>
        </template>
    </BootstrapModal>
</template>

<script setup>
import { computed, ref, watch } from 'vue';
import { Link, Head, router, useForm, usePage } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import Select2Input from '../../Components/Select2Input.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    filters: Object,
    marketers: Array,
    selectedMarketing: { type: Object, default: null },
    statuses: Array,
    periodFilters: Object,
});

const page = usePage();
const isSuperadmin = computed(() => page.props.auth?.user?.role === 'superadmin');
const selectedMarketing = ref(props.selectedMarketing ?? null);
const showDetailModal = ref(Boolean(props.selectedMarketing));
const detailLoading = ref(false);
const searchForm = useForm({
    search: props.filters.search ?? '',
    selected: props.filters.selected ?? undefined,
    month: props.filters.month ?? props.periodFilters.month,
    year: props.filters.year ?? props.periodFilters.year,
});
const createForm = useForm({ nama: '', status: 'aktif', password: '', password_confirmation: '' });
const editForm = useForm({ id_user: props.selectedMarketing?.id_user ?? null, nama: props.selectedMarketing?.nama ?? '', status: props.selectedMarketing?.status ?? 'aktif', password: '', password_confirmation: '' });
const monitoringForm = useForm({ require_return_before_checkout: true });
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const showMonitoringModal = ref(false);
const monitoringTarget = ref(null);

watch(() => props.filters, (filters) => {
    searchForm.search = filters.search ?? '';
    searchForm.selected = filters.selected ?? undefined;
    searchForm.month = filters.month ?? props.periodFilters.month;
    searchForm.year = filters.year ?? props.periodFilters.year;
}, { deep: true });

watch(() => props.selectedMarketing, (marketing) => {
    if (!selectedMarketing.value) {
        selectedMarketing.value = marketing ?? null;
    }

    editForm.id_user = marketing?.id_user ?? editForm.id_user;
    editForm.nama = marketing?.nama ?? '';
    editForm.status = marketing?.status ?? 'aktif';
    editForm.password = '';
    editForm.password_confirmation = '';
}, { immediate: true });

const buildFilterParams = (overrides = {}) => ({
    search: searchForm.search || undefined,
    selected: searchForm.selected || undefined,
    month: searchForm.month,
    year: searchForm.year,
    ...overrides,
});

const submitSearch = () => router.get('/marketing', buildFilterParams({ selected: undefined }), { preserveScroll: true, preserveState: true, replace: true });
const submitCreate = () => createForm.post('/marketing', { preserveScroll: true, onSuccess: () => createForm.reset() });
const submitEdit = () => editForm.put(`/marketing/${editForm.id_user}`, { preserveScroll: true });
const clearSelection = () => {
    selectedMarketing.value = null;
    showDetailModal.value = false;
    editForm.reset();
    editForm.id_user = null;
};
const openDetail = async (id) => {
    detailLoading.value = true;
    showDetailModal.value = true;

    try {
        const query = new URLSearchParams({
            month: String(searchForm.month),
            year: String(searchForm.year),
        });
        const { data } = await window.axios.get(`/marketing/${id}/detail?${query.toString()}`);
        selectedMarketing.value = data;
        editForm.id_user = data.id_user;
        editForm.nama = data.nama;
        editForm.status = data.status;
        editForm.password = '';
        editForm.password_confirmation = '';
    } finally {
        detailLoading.value = false;
    }
};
const closeDetailModal = () => {
    showDetailModal.value = false;
};
const openMonitoring = (item) => {
    monitoringTarget.value = item;
    monitoringForm.require_return_before_checkout = Boolean(item.require_return_before_checkout);
    showMonitoringModal.value = true;
};
const closeMonitoringModal = () => {
    showMonitoringModal.value = false;
    monitoringTarget.value = null;
    monitoringForm.reset();
    monitoringForm.require_return_before_checkout = true;
};
const submitMonitoring = () => {
    if (!monitoringTarget.value) return;
    monitoringForm.put(`/marketing/${monitoringTarget.value.id_user}/return-policy`, {
        preserveScroll: true,
        onSuccess: () => closeMonitoringModal(),
    });
};
const removeMarketing = (item) => {
    deleteTarget.value = item;
    showDeleteModal.value = true;
};
const closeDeleteModal = () => {
    showDeleteModal.value = false;
    deleteTarget.value = null;
};
const confirmDelete = () => {
    if (!deleteTarget.value) return;
    const id = deleteTarget.value.id_user;
    closeDeleteModal();
    router.delete(`/marketing/${id}`, { preserveScroll: true });
};
const approveReturn = (item) => router.post(`/products/onhand/${item.id_product_onhand}/approve`, {}, { preserveScroll: true });
const rejectReturn = (item) => router.post(`/products/onhand/${item.id_product_onhand}/reject`, {}, { preserveScroll: true });
const returnPolicyBadgeClass = (requiresReturn) => requiresReturn ? 'badge-warning-soft text-warning-emphasis' : 'badge-success-soft text-success-emphasis';
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
.action-group {
    gap: 0.35rem;
}

.action-group .btn {
    min-width: 132px;
}

.kpi-badge {
    background: #1f2937;
    color: #ffffff;
    border-radius: 999px;
    padding: 0.45rem 0.7rem;
    font-weight: 700;
}

.policy-badge,
.status-badge {
    border-radius: 999px;
    padding: 0.45rem 0.7rem;
    font-weight: 600;
}

.badge-warning-soft {
    background: #fff3cd;
}

.badge-success-soft {
    background: #d1e7dd;
}

.badge-danger-soft {
    background: #f8d7da;
}

.badge-secondary-soft {
    background: #e2e3e5;
}

.detail-card,
.section-panel {
    border: 1px solid #e5e7eb;
    border-radius: 14px;
    background: #fff;
}

.detail-card {
    height: 100%;
    padding: 1rem;
}

.detail-label,
.section-subtitle {
    font-size: 0.8rem;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    color: #6c757d;
}

.detail-value {
    font-size: 1rem;
    font-weight: 700;
    color: #1f2937;
    margin-top: 0.35rem;
}

.section-panel {
    padding: 1rem;
}

.section-title {
    font-size: 1rem;
    font-weight: 700;
    margin-bottom: 0.9rem;
}

.summary-line,
.history-item,
.carried-item {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 0.75rem;
}

.summary-line {
    padding: 0.5rem 0;
    border-bottom: 1px solid #edf2f7;
}

.summary-line:last-of-type {
    border-bottom: 0;
}

.history-stack,
.carried-stack {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
}

.history-item,
.carried-item {
    padding: 0.85rem 0.9rem;
    border-radius: 12px;
    background: #f8fafc;
}

@media (max-width: 991.98px) {
    .summary-line,
    .history-item,
    .carried-item {
        flex-direction: column;
    }

    .action-group .btn {
        min-width: auto;
        width: 100%;
    }
}

@media (max-width: 576px) {
    .detail-card {
        padding: 0.85rem;
    }

    .detail-label,
    .section-subtitle {
        font-size: 0.72rem;
    }

    .detail-value,
    .section-title {
        font-size: 0.95rem;
    }

    .section-panel {
        padding: 0.85rem;
    }

    .history-item,
    .carried-item {
        padding: 0.75rem;
    }
}
</style>
