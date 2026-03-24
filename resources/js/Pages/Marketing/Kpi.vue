<template>
    <Head title="Marketing KPI" />

    <div class="stack">
        <section class="stats-grid">
            <article v-for="item in kpis" :key="item.label" class="stat-card">
                <span>{{ item.label }}</span>
                <strong>{{ item.value }}</strong>
            </article>
        </section>

        <section class="panel-grid users-admin-grid">
            <div class="panel-card">
                <div class="panel-head">
                    <div>
                        <h3>Form Absensi Marketing</h3>
                        <p>Absensi dicatat berdasarkan area yang dikunjungi.</p>
                    </div>
                </div>

                <form class="stack" @submit.prevent="submitAttendance">
                    <label class="field">
                        <span>Area</span>
                        <select v-model="attendanceForm.area_id">
                            <option value="">Pilih area</option>
                            <option v-for="area in areas" :key="area.id" :value="area.id">{{ area.name }} - {{ area.region }}</option>
                        </select>
                        <small v-if="attendanceForm.errors.area_id" class="field-error">{{ attendanceForm.errors.area_id }}</small>
                    </label>

                    <label class="field">
                        <span>Tanggal Absensi</span>
                        <input v-model="attendanceForm.attendance_date" type="date">
                    </label>

                    <div class="dual-grid">
                        <label class="field">
                            <span>Check In</span>
                            <input v-model="attendanceForm.check_in" type="time">
                        </label>
                        <label class="field">
                            <span>Check Out</span>
                            <input v-model="attendanceForm.check_out" type="time">
                        </label>
                    </div>

                    <label class="field">
                        <span>Status</span>
                        <select v-model="attendanceForm.status">
                            <option value="hadir">hadir</option>
                            <option value="terlambat">terlambat</option>
                            <option value="izin">izin</option>
                        </select>
                    </label>

                    <label class="field">
                        <span>Catatan</span>
                        <textarea v-model="attendanceForm.notes" rows="4" placeholder="Catatan aktivitas area"></textarea>
                    </label>

                    <button type="submit" class="primary-button" :disabled="attendanceForm.processing">
                        {{ attendanceForm.processing ? 'Menyimpan...' : 'Simpan Absensi' }}
                    </button>
                </form>
            </div>

            <Deferred data="areaPerformance">
                <template #fallback>
                    <div class="panel-card loading-card">Memuat performa area...</div>
                </template>

                <div class="panel-card">
                    <div class="panel-head">
                        <div>
                            <h3>KPI Area Marketing</h3>
                            <p>Performa kunjungan area pada bulan berjalan.</p>
                        </div>
                    </div>

                    <div class="role-list">
                        <div v-for="item in areaPerformance" :key="`${item.name}-${item.region}`" class="role-item role-item-block">
                            <div>
                                <strong>{{ item.name }}</strong>
                                <p class="inline-note">{{ item.region }}</p>
                            </div>
                            <strong>{{ item.total_visits }} kunjungan</strong>
                        </div>
                    </div>
                </div>
            </Deferred>
        </section>

        <section class="panel-card">
            <div class="panel-head">
                <div>
                    <h3>Riwayat Absensi Terbaru</h3>
                    <p>{{ summary.coveredAreas }} area tercakup dari {{ summary.activeAreas }} area aktif. Izin bulan ini: {{ summary.izinCount }}.</p>
                </div>
            </div>

            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>Tanggal</th>
                            <th>Area</th>
                            <th>Status</th>
                            <th>Check In</th>
                            <th>Check Out</th>
                            <th>Catatan</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="item in recentAttendances" :key="item.id">
                            <td>{{ item.attendance_date }}</td>
                            <td>{{ item.area.name }} / {{ item.area.region }}</td>
                            <td>{{ item.status }}</td>
                            <td>{{ item.check_in }}</td>
                            <td>{{ item.check_out || '-' }}</td>
                            <td>{{ item.notes || '-' }}</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </section>
    </div>
</template>

<script setup>
import { Deferred, Head, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    kpis: Array,
    summary: Object,
    areas: Array,
    recentAttendances: Array,
    areaPerformance: {
        type: Array,
        default: undefined,
    },
});

const today = new Date().toISOString().slice(0, 10);

const attendanceForm = useForm({
    area_id: '',
    attendance_date: today,
    check_in: '08:00',
    check_out: '17:00',
    status: 'hadir',
    notes: '',
});

const submitAttendance = () => {
    attendanceForm.post('/marketing/attendance', {
        preserveScroll: true,
        onSuccess: () => {
            attendanceForm.area_id = '';
            attendanceForm.notes = '';
        },
    });
};
</script>