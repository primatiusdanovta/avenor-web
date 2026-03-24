<template>
    <Head title="Raw Material" />

    <div class="row">
        <div class="col-lg-5">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Input Raw Material</h3></div>
                <div class="card-body">
                    <form @submit.prevent="submitCreate">
                        <div class="form-group">
                            <label>Nama</label>
                            <input v-model="createForm.nama_rm" type="text" class="form-control" placeholder="Nama raw material">
                        </div>
                        <div class="form-group">
                            <label>Harga</label>
                            <input v-model="createForm.harga" type="number" min="0" class="form-control" placeholder="0">
                        </div>
                        <div class="form-group">
                            <label>Quantity</label>
                            <input v-model="createForm.quantity" type="number" min="1" class="form-control" placeholder="0">
                        </div>
                        <div class="form-group">
                            <label>Satuan</label>
                            <Select2Input v-model="createForm.satuan" :options="satuanOptions" placeholder="Pilih satuan" />
                        </div>
                        <div class="form-group">
                            <label>Stock</label>
                            <input v-model="createForm.stock" type="number" min="0" class="form-control" placeholder="0">
                        </div>

                        <div class="alert alert-info mb-0">
                            <div><strong>Harga:</strong> {{ toCurrency(createPreview.harga) }}</div>
                            <div><strong>Harga Total:</strong> {{ toCurrency(createPreview.hargaTotal) }}</div>
                            <div><strong>Harga Satuan:</strong> {{ toCurrency(createPreview.hargaSatuan) }}</div>
                            <div><strong>Stock:</strong> {{ createForm.stock || 0 }}</div>
                            <div><strong>Total Quantity:</strong> {{ createPreview.totalQuantity }} {{ createPreview.satuan }}</div>
                        </div>

                        <button type="submit" class="btn btn-primary mt-3" :disabled="createForm.processing">Simpan Raw Material</button>
                    </form>
                </div>
            </div>

            <div class="card card-outline card-warning mt-4">
                <div class="card-header"><h3 class="card-title">Edit Raw Material</h3></div>
                <div v-if="editForm.id_rm" class="card-body">
                    <div class="form-group">
                        <label>Nama</label>
                        <input v-model="editForm.nama_rm" type="text" class="form-control" placeholder="Nama raw material">
                    </div>
                    <div class="form-group">
                        <label>Harga</label>
                        <input v-model="editForm.harga" type="number" min="0" class="form-control" placeholder="0">
                    </div>
                    <div class="form-group">
                        <label>Quantity</label>
                        <input v-model="editForm.quantity" type="number" min="1" class="form-control" placeholder="0">
                    </div>
                    <div class="form-group">
                        <label>Satuan</label>
                        <Select2Input v-model="editForm.satuan" :options="satuanOptions" placeholder="Pilih satuan" />
                    </div>
                    <div class="form-group">
                        <label>Stock</label>
                        <input v-model="editForm.stock" type="number" min="0" class="form-control" placeholder="0">
                    </div>

                    <div class="alert alert-warning mb-0">
                        <div><strong>Harga:</strong> {{ toCurrency(editPreview.harga) }}</div>
                        <div><strong>Harga Total:</strong> {{ toCurrency(editPreview.hargaTotal) }}</div>
                        <div><strong>Harga Satuan:</strong> {{ toCurrency(editPreview.hargaSatuan) }}</div>
                        <div><strong>Stock:</strong> {{ editForm.stock || 0 }}</div>
                        <div><strong>Total Quantity:</strong> {{ editPreview.totalQuantity }} {{ editPreview.satuan }}</div>
                    </div>

                    <div class="mt-3 d-flex flex-wrap">
                        <button class="btn btn-warning mr-2 mb-2" :disabled="editForm.processing" @click="submitEdit">Update Raw Material</button>
                        <button class="btn btn-secondary mb-2" @click="resetEdit">Batal</button>
                    </div>
                </div>
                <div v-else class="card-body text-muted">Pilih raw material dari tabel untuk edit data.</div>
            </div>
        </div>

        <div class="col-lg-7">
            <div class="card card-outline card-success">
                <div class="card-header"><h3 class="card-title">Daftar Raw Material</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Nama</th><th>Satuan</th><th>Harga</th><th>Harga Total</th><th>Quantity</th><th>Harga Satuan</th><th>Stock</th><th>Total Quantity</th><th>Dibuat</th><th>Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in materials" :key="item.id_rm">
                                <td>{{ item.nama_rm }}</td>
                                <td>{{ item.satuan }}</td>
                                <td>{{ toCurrency(item.harga) }}</td>
                                <td>{{ toCurrency(item.harga_total) }}</td>
                                <td>{{ item.quantity }}</td>
                                <td>{{ toCurrency(item.harga_satuan) }} / {{ item.satuan }}</td>
                                <td>{{ item.stock }}</td>
                                <td>{{ item.total_quantity }} / {{ item.satuan }}</td>
                                <td>{{ item.created_at }}</td>
                                <td>
                                    <button class="btn btn-xs btn-warning mr-1" @click="pickEdit(item)">Edit</button>
                                    <button class="btn btn-xs btn-danger" @click="removeMaterial(item)">Hapus</button>
                                </td>
                            </tr>
                            <tr v-if="!materials.length"><td colspan="10" class="text-center text-muted">Belum ada raw material.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import Select2Input from '../../Components/Select2Input.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({ materials: Array });
const satuanOptions = ['pcs', 'ML'];
const createForm = useForm({ nama_rm: '', harga: '', quantity: 1, satuan: '', stock: 0 });
const editForm = useForm({ id_rm: null, nama_rm: '', harga: '', quantity: 1, satuan: '', stock: 0 });

const previewFor = (form) => computed(() => {
    const harga = Number(form.harga || 0);
    const quantity = Number(form.quantity || 0);
    const stock = Number(form.stock || 0);

    return {
        harga,
        hargaSatuan: quantity > 0 ? harga / quantity : 0,
        hargaTotal: stock * harga,
        totalQuantity: stock * quantity,
        satuan: form.satuan || '-',
    };
});

const createPreview = previewFor(createForm);
const editPreview = previewFor(editForm);

const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 2 }).format(value || 0);
const submitCreate = () => createForm.post('/raw-materials', { preserveScroll: true, onSuccess: () => createForm.reset() });
const pickEdit = (item) => Object.assign(editForm, {
    id_rm: item.id_rm,
    nama_rm: item.nama_rm,
    harga: item.harga,
    quantity: item.quantity,
    satuan: item.satuan,
    stock: item.stock,
});
const submitEdit = () => editForm.put(`/raw-materials/${editForm.id_rm}`, { preserveScroll: true, onSuccess: () => editForm.reset() });
const resetEdit = () => editForm.reset();
const removeMaterial = (item) => {
    if (window.confirm(`Hapus raw material ${item.nama_rm}?`)) {
        router.delete(`/raw-materials/${item.id_rm}`, { preserveScroll: true });
    }
};
</script>
