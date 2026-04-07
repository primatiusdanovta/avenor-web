<template>
    <AppLayout>
    <Head title="Consign" />

    <div class="row">
        <div class="col-12">
            <div class="card card-outline card-secondary">
                <div class="card-header"><h3 class="card-title">Filter Consign</h3></div>
                <div class="card-body">
                    <form class="row align-items-end" @submit.prevent="submitSearch">
                        <div class="col-md-4 mb-3 mb-md-0">
                            <label class="mb-1">Sales Field Executive</label>
                            <Select2Input v-model="filterForm.user_id" :options="users" value-key="id_user" label-key="option_label" placeholder="Semua sales field executive" />
                        </div>
                        <div class="col-md-5 mb-3 mb-md-0">
                            <label class="mb-1">Cari tempat / product</label>
                            <input v-model="filterForm.search" type="text" class="form-control" placeholder="Cari nama tempat, alamat, atau product">
                        </div>
                        <div class="col-md-3">
                            <button class="btn btn-outline-primary w-100" type="submit">Terapkan</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-12">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Daftar Titip Barang</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Sales Field Executive</th>
                                <th>Nama Tempat</th>
                                <th>Alamat</th>
                                <th>Tanggal</th>
                                <th>Submitted</th>
                                <th>Bukti</th>
                                <th>Items</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="consignment in consignments" :key="consignment.id">
                                <td>{{ consignment.user_name }}</td>
                                <td class="font-weight-bold">{{ consignment.place_name }}</td>
                                <td>{{ consignment.address }}</td>
                                <td>{{ consignment.consignment_date }}</td>
                                <td>{{ consignment.submitted_at }}</td>
                                <td>
                                    <a
                                        v-if="consignment.handover_proof_photo_url"
                                        :href="consignment.handover_proof_photo_url"
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        class="btn btn-sm btn-outline-secondary"
                                    >
                                        Lihat Foto
                                    </a>
                                    <span v-else class="text-muted">-</span>
                                </td>
                                <td>
                                    <div class="item-stack">
                                        <div v-for="item in consignment.items" :key="item.id" class="item-card">
                                            <div class="font-weight-bold">{{ item.product_name }}</div>
                                            <div class="small text-muted mb-2">Batch {{ item.pickup_batch_code || '-' }} | Qty {{ item.quantity }}</div>
                                            <div class="small mb-2">Terjual {{ item.sold_quantity }} | Dikembalikan {{ item.returned_quantity }} | Status {{ item.status }}</div>
                                            <form class="row align-items-end" @submit.prevent="submitItem(item)">
                                                <div class="col-md-3 mb-2">
                                                    <label class="mb-1">Terjual</label>
                                                    <input v-model="itemForms[item.id].sold_quantity" type="number" min="0" class="form-control form-control-sm">
                                                </div>
                                                <div class="col-md-3 mb-2">
                                                    <label class="mb-1">Dikembalikan</label>
                                                    <input v-model="itemForms[item.id].returned_quantity" type="number" min="0" class="form-control form-control-sm">
                                                </div>
                                                <div class="col-md-4 mb-2">
                                                    <label class="mb-1">Catatan</label>
                                                    <input v-model="itemForms[item.id].status_notes" type="text" class="form-control form-control-sm" placeholder="opsional">
                                                </div>
                                                <div class="col-md-2 mb-2">
                                                    <button class="btn btn-sm btn-primary w-100" :disabled="itemForms[item.id].processing">Simpan</button>
                                                </div>
                                            </form>
                                        </div>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="!consignments.length">
                                <td colspan="7" class="text-center text-muted py-4">Belum ada data consign.</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
    </AppLayout>
</template>

<script setup>
import { Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import Select2Input from '../../Components/Select2Input.vue';
import { adminUrl } from '../../utils/admin';

const props = defineProps({
    filters: Object,
    users: Array,
    consignments: Array,
});

const filterForm = useForm({
    user_id: props.filters.user_id ?? null,
    search: props.filters.search ?? '',
});

const itemForms = Object.fromEntries(
    props.consignments.flatMap((consignment) => consignment.items.map((item) => [
        item.id,
        useForm({
            sold_quantity: item.sold_quantity,
            returned_quantity: item.returned_quantity,
            status_notes: item.status_notes ?? '',
        }),
    ])),
);

const submitSearch = () => filterForm.get(adminUrl('/consignments'), { preserveScroll: true, preserveState: true, replace: true });
const submitItem = (item) => itemForms[item.id].put(adminUrl(`/consignment-items/${item.id}`), { preserveScroll: true });
</script>

<style scoped>
.item-stack {
    display: grid;
    gap: 0.75rem;
    min-width: 480px;
}

.item-card {
    border: 1px solid #e5e7eb;
    border-radius: 12px;
    padding: 0.85rem;
    background: #fff;
}
</style>
