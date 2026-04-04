<template>
    <Head title="Approvals" />

    <div class="row approvals-row">
        <div class="col-lg-12">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Approval Pengambilan Barang</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Nama</th><th>Role</th><th>Product</th><th>Qty</th><th>Tanggal</th><th>Request</th><th>Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in takeRequests" :key="`take-${item.id_product_onhand}`">
                                <td><Link :href="adminUrl(`/marketing?selected=${item.id_user}`)" class="text-primary font-weight-bold">{{ item.nama }}</Link></td>
                                <td>{{ item.role }}</td>
                                <td>{{ item.nama_product }}</td>
                                <td>{{ item.quantity }}</td>
                                <td>{{ item.assignment_date }}</td>
                                <td>{{ item.requested_at || '-' }}</td>
                                <td>
                                    <div class="btn-group btn-group-sm">
                                        <button class="btn btn-success" @click="approveTake(item)"><i class="fas fa-check"></i></button>
                                        <button class="btn btn-danger" @click="rejectTake(item)"><i class="fas fa-times"></i></button>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="!takeRequests.length"><td colspan="7" class="text-center text-muted">Belum ada request pengambilan barang.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <div class="row approvals-row">
        <div class="col-lg-12">
            <div class="card card-outline card-warning">
                <div class="card-header"><h3 class="card-title">Approval Pengembalian Barang</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Nama</th><th>Role</th><th>Product</th><th>Dibawa</th><th>Dikembalikan</th><th>Tanggal</th><th>Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in returnRequests" :key="`return-${item.id_product_onhand}`">
                                <td><Link :href="adminUrl(`/marketing?selected=${item.id_user}`)" class="text-primary font-weight-bold">{{ item.nama }}</Link></td>
                                <td>{{ item.role }}</td>
                                <td>{{ item.nama_product }}</td>
                                <td>{{ item.quantity }}</td>
                                <td>{{ item.quantity_dikembalikan }}</td>
                                <td>{{ item.assignment_date }}</td>
                                <td>
                                    <div class="btn-group btn-group-sm">
                                        <button class="btn btn-success" @click="approveReturn(item)"><i class="fas fa-check"></i></button>
                                        <button class="btn btn-danger" @click="rejectReturn(item)"><i class="fas fa-times"></i></button>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="!returnRequests.length"><td colspan="7" class="text-center text-muted">Belum ada request pengembalian barang.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { Head, Link, router } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import { adminUrl } from '../../utils/admin';

defineOptions({ layout: AppLayout });

defineProps({
    takeRequests: Array,
    returnRequests: Array,
    selectedMarketing: { type: Object, default: null },
});

const approveTake = (item) => router.post(adminUrl(`/products/onhand/${item.id_product_onhand}/take-approve`), {}, { preserveScroll: true });
const rejectTake = (item) => router.post(adminUrl(`/products/onhand/${item.id_product_onhand}/take-reject`), {}, { preserveScroll: true });
const approveReturn = (item) => router.post(adminUrl(`/products/onhand/${item.id_product_onhand}/approve`), {}, { preserveScroll: true });
const rejectReturn = (item) => router.post(adminUrl(`/products/onhand/${item.id_product_onhand}/reject`), {}, { preserveScroll: true });
</script>

<style scoped>
.approvals-row {
    margin-bottom: 10px;
}
</style>

