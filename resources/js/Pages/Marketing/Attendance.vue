<template>
    <Head title="Absensi" />

    <div class="row">
        <div v-for="item in kpis" :key="item.label" class="col-md-6 col-lg-3 col-6">
            <div class="small-box bg-gradient-info">
                <div class="inner"><h3>{{ item.value }}</h3><p>{{ item.label }}</p></div>
                <div class="icon"><i class="fas fa-clipboard-check"></i></div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-md-12 col-lg-5">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Absensi Hari Ini</h3></div>
                <div class="card-body">
                    <div class="form-group">
                        <label>Status</label>
                        <Select2Input v-model="attendanceForm.status" :options="statuses" placeholder="Pilih status" />
                    </div>
                    <div class="form-group">
                        <label>Catatan</label>
                        <textarea v-model="attendanceForm.notes" class="form-control" rows="4" placeholder="Catatan absensi hari ini"></textarea>
                    </div>
                    <div v-if="locationError" class="alert alert-danger py-2">{{ locationError }}</div>
                    <div class="d-flex flex-wrap">
                        <button type="button" class="btn btn-success mr-2 mb-2" :disabled="attendanceForm.processing" @click="confirmAction('check-in')">Check In Sekarang</button>
                        <button type="button" class="btn btn-danger mb-2" :disabled="attendanceForm.processing" @click="confirmAction('check-out')">Check Out Sekarang</button>
                    </div>
                    <p class="text-muted text-sm mt-3 mb-0">Tanggal, jam, dan koordinat diambil otomatis saat tombol dijalankan.</p>
                </div>
            </div>
        </div>
        <div class="col-md-12 col-lg-7">
            <div class="card card-outline card-info">
                <div class="card-header"><h3 class="card-title">Status Hari Ini</h3></div>
                <div class="card-body">
                    <div v-if="todayAttendance">
                        <p><strong>Tanggal:</strong> {{ todayAttendance.date }}</p>
                        <p><strong>Status:</strong> {{ todayAttendance.status }}</p>
                        <p><strong>Check In:</strong> {{ todayAttendance.check_in || '-' }}</p>
                        <p><strong>Check Out:</strong> {{ todayAttendance.check_out || '-' }}</p>
                        <p><strong>Lokasi Check In:</strong> {{ todayAttendance.check_in_location }}</p>
                        <p class="mb-0"><strong>Lokasi Check Out:</strong> {{ todayAttendance.check_out_location }}</p>
                    </div>
                    <div v-else class="text-muted">Belum ada absensi hari ini.</div>
                    <Deferred data="latestLocation">
                        <template #fallback><div class="mt-3 text-muted">Memuat lokasi terakhir...</div></template>
                        <div class="mt-3" v-if="latestLocation">
                            <hr>
                            <p><strong>Lokasi Terakhir:</strong> {{ latestLocation.latitude }}, {{ latestLocation.longitude }}</p>
                            <p><strong>Waktu:</strong> {{ latestLocation.recorded_at }}</p>
                            <p><strong>Sumber:</strong> {{ latestLocation.source }}</p>
                            <iframe :src="latestLocation.map_url" width="100%" height="220" style="border:0" loading="lazy"></iframe>
                        </div>
                    </Deferred>
                </div>
            </div>
        </div>
    </div>

    <div v-if="!isSmoothiesSweetie" class="card card-outline card-warning">
        <div class="card-header"><h3 class="card-title">Barang Yang Dibawa Hari Ini</h3></div>
        <div class="card-body p-0 table-responsive">
            <table class="table table-striped mb-0">
                <thead><tr><th>Tanggal</th><th>Product</th><th>Dibawa</th><th>Terjual</th><th>Request Return</th><th>Sisa</th><th>Status Return</th></tr></thead>
                <tbody>
                    <tr v-for="item in carriedProducts" :key="item.id_product_onhand">
                        <td>{{ item.assignment_date }}</td>
                        <td>{{ item.nama_product }}</td>
                        <td>{{ item.quantity }}</td>
                        <td>{{ item.sold_quantity }}</td>
                        <td>{{ item.quantity_dikembalikan }}</td>
                        <td>{{ item.remaining_quantity }}</td>
                        <td>{{ item.status_label }}</td>
                    </tr>
                    <tr v-if="!carriedProducts.length"><td colspan="7" class="text-center text-muted">Belum ada barang yang dibawa hari ini.</td></tr>
                </tbody>
            </table>
        </div>
    </div>

    <div class="card card-outline card-secondary">
        <div class="card-header"><h3 class="card-title">Riwayat Absensi</h3></div>
        <div class="card-body p-0 table-responsive">
            <table class="table table-striped mb-0">
                <thead><tr><th>Tanggal</th><th>Status</th><th>Check In</th><th>Check Out</th><th>Lokasi Check In</th><th>Lokasi Check Out</th><th>Catatan</th></tr></thead>
                <tbody>
                    <tr v-for="item in recentAttendances" :key="item.id">
                        <td>{{ item.attendance_date }}</td>
                        <td>{{ item.status }}</td>
                        <td>{{ item.check_in || '-' }}</td>
                        <td>{{ item.check_out || '-' }}</td>
                        <td>{{ item.check_in_location }}</td>
                        <td>{{ item.check_out_location }}</td>
                        <td>{{ item.notes || '-' }}</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>

    <BootstrapModal :show="showConfirmModal" title="Konfirmasi" size="mobile-full" @close="showConfirmModal = false">
        {{ confirmMessage }}
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="showConfirmModal = false">Tidak</button>
            <button type="button" class="btn btn-primary" @click="runConfirmedAction">Ya</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showErrorModal" title="Peringatan" size="mobile-full" @close="showErrorModal = false">
        {{ errorMessage }}
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="showErrorModal = false">Tutup</button>
        </template>
    </BootstrapModal>
</template>

<script setup>
import { ref, watch } from 'vue';
import { Deferred, Head, useForm, usePage } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import { adminUrl } from '../../utils/admin';
import Select2Input from '../../Components/Select2Input.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    kpis: Array,
    todayAttendance: { type: Object, default: null },
    recentAttendances: Array,
    carriedProducts: Array,
    isSmoothiesSweetie: Boolean,
    latestLocation: { type: Object, default: undefined },
});

const page = usePage();
const statuses = ['hadir', 'terlambat', 'izin', 'sakit'];
const attendanceForm = useForm({ status: 'hadir', notes: '', latitude: null, longitude: null });
const locationError = ref('');
const confirmMessage = ref('');
const errorMessage = ref('');
const pendingAction = ref(null);
const showConfirmModal = ref(false);
const showErrorModal = ref(false);

const openErrorModal = (message) => {
    errorMessage.value = message;
    showErrorModal.value = true;
};

const resolveLocation = () => new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
        reject(new Error('Browser tidak mendukung lokasi.'));
        return;
    }

    navigator.geolocation.getCurrentPosition((position) => {
        resolve({ latitude: position.coords.latitude, longitude: position.coords.longitude });
    }, () => reject(new Error('Lokasi wajib dinyalakan sebelum absensi.')), { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 });
});

const confirmAction = (action) => {
    pendingAction.value = action;
    confirmMessage.value = action === 'check-in'
        ? 'Apakah anda ingin memulai pekerjaan'
        : 'Apakah anda ingin mengakhiri pekerjaan';
    showConfirmModal.value = true;
};

const runConfirmedAction = async () => {
    showConfirmModal.value = false;
    const action = pendingAction.value;
    if (!action) return;

    try {
        const coords = await resolveLocation();
        locationError.value = '';
        attendanceForm.latitude = coords.latitude;
        attendanceForm.longitude = coords.longitude;
        attendanceForm.post(adminUrl(`/marketing/attendance/${action}`), { preserveScroll: true });
    } catch (error) {
        locationError.value = error.message;
        openErrorModal(error.message);
    } finally {
        pendingAction.value = null;
    }
};

watch(() => page.props.errors?.checkout, (value) => {
    if (value) openErrorModal(value);
}, { immediate: true });

watch(() => page.props.errors?.checkin, (value) => {
    if (value) openErrorModal(value);
}, { immediate: true });
</script>



