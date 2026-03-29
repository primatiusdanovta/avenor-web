<template>
    <Head title="Promos" />

    <div class="row">
        <div class="col-md-12 col-lg-5">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Tambah Promo</h3></div>
                <div class="card-body">
                    <form @submit.prevent="submitCreate">
                        <div class="form-group"><label>Nama Promo</label><input v-model="createForm.nama_promo" type="text" class="form-control"></div>
                        <div class="form-group"><label>Potongan</label><input v-model="createForm.potongan" type="number" min="0" class="form-control"></div>
                        <div class="form-group"><label>Masa Aktif</label><input v-model="createForm.masa_aktif" type="date" class="form-control"></div>
                        <div class="form-group"><label>Minimal Quantity</label><input v-model="createForm.minimal_quantity" type="number" min="1" class="form-control"></div>
                        <div class="form-group"><label>Minimal Belanja</label><input v-model="createForm.minimal_belanja" type="number" min="0" class="form-control"></div>
                        <button class="btn btn-primary" style="margin-top: 10px;" :disabled="createForm.processing">Simpan Promo</button>
                    </form>
                </div>
            </div>

            <div class="card card-outline card-warning">
                <div class="card-header"><h3 class="card-title">Edit Promo</h3></div>
                <div v-if="editForm.id" class="card-body">
                    <div class="form-group"><label>Nama Promo</label><input v-model="editForm.nama_promo" type="text" class="form-control"></div>
                    <div class="form-group"><label>Potongan</label><input v-model="editForm.potongan" type="number" min="0" class="form-control"></div>
                    <div class="form-group"><label>Masa Aktif</label><input v-model="editForm.masa_aktif" type="date" class="form-control"></div>
                    <div class="form-group"><label>Minimal Quantity</label><input v-model="editForm.minimal_quantity" type="number" min="1" class="form-control"></div>
                    <div class="form-group"><label>Minimal Belanja</label><input v-model="editForm.minimal_belanja" type="number" min="0" class="form-control"></div>
                    <button class="btn btn-warning mr-2" @click="submitEdit">Update</button>
                    <button class="btn btn-secondary" @click="editForm.reset()">Batal</button>
                </div>
                <div v-else class="card-body text-muted">Pilih promo dari tabel untuk edit.</div>
            </div>
        </div>

        <div class="col-md-12 col-lg-7">
            <div class="card card-outline card-success">
                <div class="card-header"><h3 class="card-title">Daftar Promo</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Kode</th><th>Nama</th><th>Potongan</th><th>Masa Aktif</th><th>Min Qty</th><th>Min Belanja</th><th>Status</th><th>Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in promos" :key="item.id">
                                <td>{{ item.kode_promo }}</td>
                                <td>{{ item.nama_promo }}</td>
                                <td>{{ toCurrency(item.potongan) }}</td>
                                <td>{{ item.masa_aktif }}</td>
                                <td>{{ item.minimal_quantity }}</td>
                                <td>{{ toCurrency(item.minimal_belanja) }}</td>
                                <td>{{ item.is_active ? 'aktif' : 'expired' }}</td>
                                <td>
                                    <button class="btn btn-xs btn-warning mr-1" @click="pickEdit(item)">Edit</button>
                                    <button class="btn btn-xs btn-danger" @click="removePromo(item)">Hapus</button>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';

defineOptions({ layout: AppLayout });

defineProps({ promos: Array });
const createForm = useForm({ nama_promo: '', potongan: '', masa_aktif: '', minimal_quantity: 1, minimal_belanja: 0 });
const editForm = useForm({ id: null, nama_promo: '', potongan: '', masa_aktif: '', minimal_quantity: 1, minimal_belanja: 0 });
const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value || 0);
const submitCreate = () => createForm.post('/promos', { preserveScroll: true, onSuccess: () => createForm.reset() });
const pickEdit = (item) => Object.assign(editForm, item);
const submitEdit = () => editForm.put(`/promos/${editForm.id}`, { preserveScroll: true });
const removePromo = (item) => { if (window.confirm(`Hapus promo ${item.nama_promo}?`)) router.delete(`/promos/${item.id}`, { preserveScroll: true }); };
</script>

