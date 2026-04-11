<template>
    <AppLayout title="Extra Topping">
        <Head title="Extra Topping" />

        <template #actions>
            <button v-if="canManage" type="button" class="btn btn-primary" @click="openCreate">Tambah Extra Topping</button>
        </template>

        <div class="card card-outline card-success">
            <div class="card-header"><h3 class="card-title mb-0">Daftar Extra Topping</h3></div>
            <div class="card-body p-0 table-responsive">
                <table class="table table-hover mb-0">
                    <thead><tr><th>Nama</th><th>Harga</th><th>Status</th><th v-if="canManage">Aksi</th></tr></thead>
                    <tbody>
                        <tr v-for="item in items" :key="item.id">
                            <td>{{ item.name }}</td>
                            <td>{{ toCurrency(item.price) }}</td>
                            <td>{{ item.is_active ? 'Aktif' : 'Nonaktif' }}</td>
                            <td v-if="canManage">
                                <div class="d-flex gap-2">
                                    <button type="button" class="btn btn-sm btn-warning" @click="openEdit(item)">Edit</button>
                                    <button type="button" class="btn btn-sm btn-danger" @click="removeItem(item)">Hapus</button>
                                </div>
                            </td>
                        </tr>
                        <tr v-if="!items.length"><td :colspan="canManage ? 4 : 3" class="text-center text-muted">Belum ada extra topping.</td></tr>
                    </tbody>
                </table>
            </div>
        </div>

        <BootstrapModal :show="showModal" :title="form.id ? 'Edit Extra Topping' : 'Tambah Extra Topping'" @close="closeModal">
            <div class="crud-modal-body">
                <div class="form-group mb-0"><label>Nama</label><input v-model="form.name" type="text" class="form-control"></div>
                <div class="form-group mb-0"><label>Harga</label><input v-model="form.price" type="number" min="0" class="form-control"></div>
                <div class="form-group mb-0">
                    <label>Status</label>
                    <select v-model="form.is_active" class="form-control">
                        <option :value="true">Aktif</option>
                        <option :value="false">Nonaktif</option>
                    </select>
                </div>
            </div>
            <template #footer>
                <button type="button" class="btn btn-secondary" @click="closeModal">Batal</button>
                <button type="button" class="btn btn-primary" @click="submitForm">Simpan</button>
            </template>
        </BootstrapModal>
    </AppLayout>
</template>

<script setup>
import { Head, router, useForm } from '@inertiajs/vue3';
import { ref } from 'vue';
import AppLayout from '../../Layouts/AppLayout.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';
import { adminUrl } from '../../utils/admin';

const props = defineProps({ items: Array, canManage: Boolean });
const showModal = ref(false);
const form = useForm({ id: null, name: '', price: 0, is_active: true });
const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value || 0);

const openCreate = () => {
    form.reset();
    form.id = null;
    form.is_active = true;
    showModal.value = true;
};
const openEdit = (item) => {
    form.id = item.id;
    form.name = item.name;
    form.price = item.price;
    form.is_active = item.is_active;
    showModal.value = true;
};
const closeModal = () => {
    showModal.value = false;
    form.reset();
    form.id = null;
};
const submitForm = () => {
    if (form.id) {
        form.put(adminUrl(`/extra-toppings/${form.id}`), { preserveScroll: true, onSuccess: closeModal });
        return;
    }

    form.post(adminUrl('/extra-toppings'), { preserveScroll: true, onSuccess: closeModal });
};
const removeItem = (item) => router.delete(adminUrl(`/extra-toppings/${item.id}`), { preserveScroll: true });
</script>

<style scoped>
.crud-modal-body {
    display: grid;
    gap: 1rem;
}
</style>
