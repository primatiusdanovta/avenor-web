<template>
    <Head title="Marketing" />

    <div class="row">
        <div class="col-lg-4">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Tambah Marketing</h3></div>
                <div class="card-body">
                    <form @submit.prevent="submitCreate">
                        <div class="form-group"><label>Nama Marketing</label><input v-model="createForm.nama" type="text" class="form-control"></div>
                        <div class="form-group"><label>Status</label><Select2Input v-model="createForm.status" :options="statuses" placeholder="Pilih status" /></div>
                        <div class="form-group"><label>Password</label><input v-model="createForm.password" type="password" class="form-control"></div>
                        <div class="form-group"><label>Konfirmasi Password</label><input v-model="createForm.password_confirmation" type="password" class="form-control"></div>
                        <button type="submit" class="btn btn-primary" style="margin-top: 10px;" :disabled="createForm.processing">Tambah Marketing</button>
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
                <div v-else class="card-body text-muted">Pilih marketing pada tabel untuk lihat detail.</div>
            </div>
        </div>

        <div class="col-lg-8">
            <div class="card card-outline card-info">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h3 class="card-title">Daftar Marketing</h3>
                    <div class="d-flex align-items-center">
                        <input v-model="searchForm.search" type="text" class="form-control form-control-sm mr-2" placeholder="Cari marketing">
                        <button class="btn btn-sm btn-outline-primary" @click="submitSearch">Cari</button>
                    </div>
                </div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Nama</th><th>Status</th><th>Absensi</th><th>Barang Dibawa</th><th>Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in marketers" :key="item.id_user">
                                <td><Link :href="`/marketing?selected=${item.id_user}`" class="font-weight-bold text-primary">{{ item.nama }}</Link></td>
                                <td>{{ item.status }}</td>
                                <td>{{ item.today_status }}</td>
                                <td>
                                    <div v-if="item.carried_items.length">
                                        <div v-for="carry in item.carried_items" :key="`${item.id_user}-${carry.nama_product}-${carry.take_status}-${carry.return_status}`" class="text-sm">
                                            {{ carry.nama_product }} ({{ carry.quantity }}) - ambil: {{ carry.take_status }} - return: {{ carry.return_status }}
                                        </div>
                                    </div>
                                    <span v-else class="text-muted">-</span>
                                </td>
                                <td><button class="btn btn-xs btn-danger" @click="removeMarketing(item)">Hapus</button></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <div class="card card-outline card-success">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h3 class="card-title">Detail Marketing</h3>
                    <Link href="/approvals" class="btn btn-sm btn-outline-primary">Buka Halaman Approval</Link>
                </div>
                <div v-if="selectedMarketing" class="card-body">
                    <p><strong>Nama:</strong> {{ selectedMarketing.nama }}</p>
                    <p><strong>Status Akun:</strong> {{ selectedMarketing.status }}</p>
                    <template v-if="selectedMarketing.today_attendance">
                        <p><strong>Status Hari Ini:</strong> {{ selectedMarketing.today_attendance.status }}</p>
                        <p><strong>Check In:</strong> {{ selectedMarketing.today_attendance.check_in || '-' }}</p>
                        <p><strong>Check Out:</strong> {{ selectedMarketing.today_attendance.check_out || '-' }}</p>
                        <p><strong>Catatan:</strong> {{ selectedMarketing.today_attendance.notes || '-' }}</p>
                    </template>
                    <p v-else><strong>Status Hari Ini:</strong> belum absen</p>
                    <template v-if="selectedMarketing.latest_location">
                        <p><strong>Lokasi Terakhir:</strong> {{ selectedMarketing.latest_location.latitude }}, {{ selectedMarketing.latest_location.longitude }}</p>
                        <p><strong>Direkam:</strong> {{ selectedMarketing.latest_location.recorded_at }}</p>
                        <p><strong>Sumber:</strong> {{ selectedMarketing.latest_location.source }}</p>
                        <iframe :src="selectedMarketing.latest_location.map_url" width="100%" height="240" style="border:0" loading="lazy"></iframe>
                    </template>
                    <p v-else><strong>Lokasi Terakhir:</strong> belum ada data</p>

                    <hr>
                    <h5>Barang Yang Dibawa Hari Ini</h5>
                    <div class="table-responsive">
                        <table class="table table-sm table-bordered">
                            <thead><tr><th>Product</th><th>Dibawa</th><th>Take</th><th>Return</th><th>Sisa</th><th>Status Return</th><th>Approval</th></tr></thead>
                            <tbody>
                                <tr v-for="item in selectedMarketing.carried_items" :key="item.id_product_onhand">
                                    <td>{{ item.nama_product }}</td>
                                    <td>{{ item.quantity }}</td>
                                    <td>{{ item.take_status }}</td>
                                    <td>{{ item.quantity_dikembalikan }}</td>
                                    <td>{{ item.remaining_quantity }}</td>
                                    <td>{{ item.return_status }}</td>
                                    <td>
                                        <div v-if="item.return_status === 'pending'" class="btn-group btn-group-sm">
                                            <button class="btn btn-success" @click="approveReturn(item)"><i class="fas fa-check"></i></button>
                                            <button class="btn btn-danger" @click="rejectReturn(item)"><i class="fas fa-times"></i></button>
                                        </div>
                                        <span v-else class="text-muted">-</span>
                                    </td>
                                </tr>
                                <tr v-if="!selectedMarketing.carried_items.length"><td colspan="7" class="text-center text-muted">Belum ada barang yang dibawa hari ini.</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
                <div v-else class="card-body text-muted">Klik nama marketing pada tabel untuk melihat status hari ini, lokasi, dan barang yang dibawa.</div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { Link, Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import Select2Input from '../../Components/Select2Input.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({ filters: Object, marketers: Array, selectedMarketing: { type: Object, default: null }, statuses: Array });
const searchForm = useForm({ search: props.filters.search ?? '' });
const createForm = useForm({ nama: '', status: 'aktif', password: '', password_confirmation: '' });
const editForm = useForm({ id_user: props.selectedMarketing?.id_user ?? null, nama: props.selectedMarketing?.nama ?? '', status: props.selectedMarketing?.status ?? 'aktif', password: '', password_confirmation: '' });

const submitSearch = () => searchForm.get('/marketing', { preserveScroll: true, preserveState: true, replace: true });
const submitCreate = () => createForm.post('/marketing', { preserveScroll: true, onSuccess: () => createForm.reset() });
const submitEdit = () => editForm.put(`/marketing/${editForm.id_user}`, { preserveScroll: true });
const clearSelection = () => router.get('/marketing', { search: searchForm.search || undefined }, { preserveScroll: true, preserveState: true, replace: true });
const removeMarketing = (item) => { if (window.confirm(`Hapus akun marketing ${item.nama}?`)) router.delete(`/marketing/${item.id_user}`, { preserveScroll: true }); };
const approveReturn = (item) => router.post(`/products/onhand/${item.id_product_onhand}/approve`, {}, { preserveScroll: true });
const rejectReturn = (item) => router.post(`/products/onhand/${item.id_product_onhand}/reject`, {}, { preserveScroll: true });
</script>
