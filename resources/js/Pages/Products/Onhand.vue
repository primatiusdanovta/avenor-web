<template>
    <Head title="Products" />

    <div v-if="$page.props.errors.quantity_dikembalikan" class="alert alert-danger">{{ $page.props.errors.quantity_dikembalikan }}</div>
    <div v-if="$page.props.errors.id_product" class="alert alert-danger">{{ $page.props.errors.id_product }}</div>
    <div v-if="$page.props.errors.quantity" class="alert alert-danger">{{ $page.props.errors.quantity }}</div>

    <div class="row">
        <div class="col-lg-5">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Request Ambil Barang</h3></div>
                <div class="card-body">
                    <div v-if="!attendanceReady" class="alert alert-warning">Marketing wajib check in terlebih dahulu sebelum mengambil barang.</div>
                    <div class="form-group">
                        <label>Product</label>
                        <Select2Input v-model="takeForm.id_product" :options="products" value-key="id_product" label-key="option_label" placeholder="Cari lalu pilih product" :disabled="!attendanceReady" />
                    </div>
                    <div class="form-group">
                        <label>Quantity</label>
                        <input v-model="takeForm.quantity" type="number" min="1" class="form-control" :disabled="!attendanceReady">
                    </div>
                    <button class="btn btn-primary" :disabled="takeForm.processing || !attendanceReady || !takeForm.id_product" @click="submitTake">Kirim Request</button>
                    <p class="text-muted text-sm mt-3 mb-0">Barang baru bisa dipakai setelah disetujui admin atau superadmin.</p>
                </div>
            </div>

            <div class="card card-outline card-info">
                <div class="card-header"><h3 class="card-title">Status Hari Ini</h3></div>
                <div class="card-body">
                    <div v-if="todayAttendance">
                        <p><strong>Status:</strong> {{ todayAttendance.status }}</p>
                        <p><strong>Check In:</strong> {{ todayAttendance.check_in || '-' }}</p>
                        <p class="mb-0"><strong>Check Out:</strong> {{ todayAttendance.check_out || '-' }}</p>
                    </div>
                    <div v-else class="text-muted">Belum ada absensi hari ini.</div>
                </div>
            </div>
        </div>

        <div class="col-lg-7">
            <div class="card card-outline card-success">
                <div class="card-header"><h3 class="card-title">Barang Yang Dibawa</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Tanggal</th><th>Product</th><th>Dibawa</th><th>Terjual</th><th>Sisa</th><th>Status</th></tr></thead>
                        <tbody>
                            <tr v-for="item in onhands" :key="item.id_product_onhand">
                                <td>{{ item.assignment_date }}</td>
                                <td>{{ item.nama_product }}</td>
                                <td>{{ item.quantity }}</td>
                                <td>{{ item.sold_quantity }}</td>
                                <td>{{ item.take_status === 'disetujui' ? item.remaining_quantity : '-' }}</td>
                                <td>
                                    <span v-if="item.take_status !== 'disetujui'">{{ item.take_status_label }}</span>
                                    <span v-else>{{ item.status_label }}</span>
                                </td>
                            </tr>
                            <tr v-if="!onhands.length"><td colspan="6" class="text-center text-muted">Belum ada barang yang dibawa.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <div class="card card-outline card-warning">
                <div class="card-header"><h3 class="card-title">Pengembalian Barang Yang Dibawa Hari Ini</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Product</th><th>Status Ambil</th><th>Dibawa</th><th>Terjual</th><th>Max Return</th><th>Request Return</th><th>Status</th><th>Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in todayReturnItems" :key="`return-${item.id_product_onhand}`">
                                <td>{{ item.nama_product }}</td>
                                <td>{{ item.take_status_label }}</td>
                                <td>{{ item.quantity }}</td>
                                <td>{{ item.sold_quantity }}</td>
                                <td>{{ item.take_status === 'disetujui' ? item.max_return : '-' }}</td>
                                <td>{{ item.quantity_dikembalikan }}</td>
                                <td>{{ item.status_label }}</td>
                                <td>
                                    <div v-if="item.take_status !== 'disetujui'" class="text-muted text-sm">Menunggu approval barang</div>
                                    <div v-else-if="item.sold_out" class="text-success text-sm">Tidak wajib return</div>
                                    <div v-else-if="item.has_pending_request" class="text-warning text-sm">Masih ada antrian yang belum disetujui</div>
                                    <div v-else class="input-group input-group-sm">
                                        <input :value="returnInputs[item.id_product_onhand] ?? item.max_return" type="number" min="1" :max="item.max_return" class="form-control" @input="returnInputs[item.id_product_onhand] = Number($event.target.value)">
                                        <div class="input-group-append">
                                            <button class="btn btn-outline-primary" @click="submitReturn(item)">Request</button>
                                        </div>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="!todayReturnItems.length"><td colspan="8" class="text-center text-muted">Belum ada barang yang perlu diproses hari ini.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { reactive } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import Select2Input from '../../Components/Select2Input.vue';

defineOptions({ layout: AppLayout });

defineProps({ products: Array, attendanceReady: Boolean, todayAttendance: { type: Object, default: null }, onhands: Array, todayReturnItems: Array });
const returnInputs = reactive({});
const takeForm = useForm({ id_product: '', quantity: 1 });

const submitTake = () => takeForm.post('/products/take', { preserveScroll: true, onSuccess: () => takeForm.reset('id_product', 'quantity') });
const submitReturn = (item) => router.put(`/products/onhand/${item.id_product_onhand}/return`, { quantity_dikembalikan: Number(returnInputs[item.id_product_onhand] ?? item.max_return ?? 0) }, { preserveScroll: true });
</script>

