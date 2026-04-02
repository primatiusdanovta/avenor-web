<template>
    <Head title="Products" />

    <div class="row">
        <div class="col-md-12 col-lg-5">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Tambah Product</h3></div>
                <div class="card-body">
                    <div v-if="createErrorMessages.length" class="alert alert-danger">
                        <div v-for="message in createErrorMessages" :key="`create-error-${message}`">{{ message }}</div>
                    </div>
                    <form @submit.prevent="submitCreate">
                        <div class="form-group">
                            <label>Nama Product</label>
                            <input v-model="createForm.nama_product" type="text" class="form-control" :class="{ 'is-invalid': createForm.errors.nama_product }">
                            <div v-if="createForm.errors.nama_product" class="invalid-feedback d-block">{{ createForm.errors.nama_product }}</div>
                        </div>
                        <div class="form-row">
                            <div class="form-group col-md-6">
                                <label>Harga</label>
                                <input v-model="createForm.harga" type="number" min="0" class="form-control" :class="{ 'is-invalid': createForm.errors.harga }">
                                <div v-if="createForm.errors.harga" class="invalid-feedback d-block">{{ createForm.errors.harga }}</div>
                            </div>
                            <div class="form-group col-md-6"><label>Harga Modal</label><input :value="0" type="number" min="0" class="form-control" disabled></div>
                        </div>
                        <small class="text-muted d-block mb-3">Harga modal diisi otomatis dari halaman HPP.</small>
                        <div class="form-group">
                            <label>Stock Awal</label>
                            <input v-model="createForm.stock" type="number" min="0" class="form-control" :class="{ 'is-invalid': createForm.errors.stock }">
                            <div v-if="createForm.errors.stock" class="invalid-feedback d-block">{{ createForm.errors.stock }}</div>
                        </div>
                        <small class="text-muted d-block mb-3">Buat product baru dengan stock 0 terlebih dahulu. Setelah HPP dibuat, stock ditambah lewat form edit agar raw material ikut terpotong otomatis.</small>
                        <div class="form-group">
                            <label>Deskripsi</label>
                            <textarea v-model="createForm.deskripsi" rows="3" class="form-control" :class="{ 'is-invalid': createForm.errors.deskripsi }"></textarea>
                            <div v-if="createForm.errors.deskripsi" class="invalid-feedback d-block">{{ createForm.errors.deskripsi }}</div>
                        </div>
                        <div class="form-group">
                            <label>Fragrance Detail</label>
                            <div class="border rounded p-2 bg-light fragrance-box">
                                <div v-for="item in fragranceDetails" :key="`create-${item.id_fd}`" class="custom-control custom-checkbox">
                                    <input :id="`create-fragrance-${item.id_fd}`" v-model="createForm.fragrance_details" :value="String(item.id_fd)" type="checkbox" class="custom-control-input">
                                    <label class="custom-control-label" :for="`create-fragrance-${item.id_fd}`">{{ item.detail }}</label>
                                </div>
                            </div>
                            <small class="text-muted">Bisa memilih banyak detail fragrance sekaligus.</small>
                            <div v-if="createForm.errors.fragrance_details" class="text-danger small mt-1">{{ createForm.errors.fragrance_details }}</div>
                        </div>
                        <div class="form-group">
                            <label>Gambar</label>
                            <input type="file" class="form-control" accept="image/*" :class="{ 'is-invalid': createForm.errors.gambar }" @change="setImageFile(createForm, $event)">
                            <div v-if="createForm.errors.gambar" class="invalid-feedback d-block">{{ createForm.errors.gambar }}</div>
                        </div>
                        <button type="submit" class="btn btn-primary" style="margin-top: 10px;" :disabled="createForm.processing">Simpan Product</button>
                    </form>
                </div>
            </div>

            <div class="card card-outline card-warning">
                <div class="card-header"><h3 class="card-title">Edit Product</h3></div>
                <div v-if="editForm.id_product" class="card-body">
                    <div v-if="editErrorMessages.length" class="alert alert-danger">
                        <div v-for="message in editErrorMessages" :key="`edit-error-${message}`">{{ message }}</div>
                    </div>
                    <div class="form-group">
                        <label>Nama Product</label>
                        <input v-model="editForm.nama_product" type="text" class="form-control" :class="{ 'is-invalid': editForm.errors.nama_product }">
                        <div v-if="editForm.errors.nama_product" class="invalid-feedback d-block">{{ editForm.errors.nama_product }}</div>
                    </div>
                    <div class="form-row">
                        <div class="form-group col-md-6">
                            <label>Harga</label>
                            <input v-model="editForm.harga" type="number" min="0" class="form-control" :class="{ 'is-invalid': editForm.errors.harga }">
                            <div v-if="editForm.errors.harga" class="invalid-feedback d-block">{{ editForm.errors.harga }}</div>
                        </div>
                        <div class="form-group col-md-6"><label>Harga Modal</label><input :value="editForm.harga_modal" type="number" min="0" class="form-control" disabled></div>
                    </div>
                    <small class="text-muted d-block mb-3">Ubah harga modal melalui halaman HPP jika komposisi raw material berubah.</small>
                    <div class="form-group">
                        <label>Stock</label>
                        <input v-model="editForm.stock" type="number" min="0" class="form-control" :class="{ 'is-invalid': editForm.errors.stock }">
                        <div v-if="editForm.errors.stock" class="invalid-feedback d-block">{{ editForm.errors.stock }}</div>
                    </div>
                    <div class="form-group">
                        <label>Deskripsi</label>
                        <textarea v-model="editForm.deskripsi" rows="3" class="form-control" :class="{ 'is-invalid': editForm.errors.deskripsi }"></textarea>
                        <div v-if="editForm.errors.deskripsi" class="invalid-feedback d-block">{{ editForm.errors.deskripsi }}</div>
                    </div>
                    <div class="form-group">
                        <label>Fragrance Detail</label>
                        <div class="border rounded p-2 bg-light fragrance-box">
                            <div v-for="item in fragranceDetails" :key="`edit-${item.id_fd}`" class="custom-control custom-checkbox">
                                <input :id="`edit-fragrance-${item.id_fd}`" v-model="editForm.fragrance_details" :value="String(item.id_fd)" type="checkbox" class="custom-control-input">
                                <label class="custom-control-label" :for="`edit-fragrance-${item.id_fd}`">{{ item.detail }}</label>
                            </div>
                        </div>
                        <div v-if="editForm.errors.fragrance_details" class="text-danger small mt-1">{{ editForm.errors.fragrance_details }}</div>
                    </div>
                    <div v-if="editForm.gambar_lama" class="form-group">
                        <label>Gambar Saat Ini</label>
                        <div>
                            <img :src="editForm.gambar_lama" alt="current product" class="product-preview-image">
                        </div>
                        <small class="text-muted">Upload gambar baru hanya jika ingin mengganti gambar product.</small>
                    </div>
                    <div class="form-group">
                        <label>Gambar Baru</label>
                        <input type="file" class="form-control" accept="image/*" :class="{ 'is-invalid': editForm.errors.gambar }" @change="setImageFile(editForm, $event)">
                        <div v-if="editForm.errors.gambar" class="invalid-feedback d-block">{{ editForm.errors.gambar }}</div>
                    </div>
                    <div class="d-flex flex-wrap">
                        <button class="btn btn-warning mr-2 mb-2" @click="submitEdit" :disabled="editForm.processing">Update</button>
                        <button class="btn btn-secondary mb-2" @click="resetEdit">Batal</button>
                    </div>
                </div>
                <div v-else class="card-body text-muted">Pilih product dari tabel untuk edit data.</div>
            </div>
        </div>

        <div class="col-md-12 col-lg-7">
            <div class="card card-outline card-success">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h3 class="card-title">Daftar Product</h3>
                    <input v-model="keyword" type="text" class="form-control form-control-sm w-auto" placeholder="Cari product">
                </div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Gambar</th><th>Nama</th><th>Fragrance Detail</th><th>Harga</th><th>Harga Modal</th><th>Stock</th><th>Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in filteredProducts" :key="item.id_product">
                                <td><img v-if="item.gambar" :src="item.gambar" alt="product" style="width:48px;height:48px;object-fit:cover"></td>
                                <td>
                                    <div>{{ item.nama_product }}</div>
                                    <div class="text-muted small">{{ truncateWords(item.deskripsi, 10) }}</div>
                                </td>
                                <td>
                                    <div v-if="item.fragrance_details.length" class="small">
                                        <span v-for="detail in item.fragrance_details" :key="`${item.id_product}-${detail.id_fd}`" class="fragrance-badge mr-1 mb-1">{{ detail.detail }}</span>
                                    </div>
                                    <span v-else class="text-muted">-</span>
                                </td>
                                <td>{{ toCurrency(item.harga) }}</td>
                                <td>{{ toCurrency(item.harga_modal) }}</td>
                                <td>{{ item.stock }}</td>
                                <td>
                                    <button class="btn btn-xs btn-warning mr-1" @click="pickEdit(item)">Edit</button>
                                    <button class="btn btn-xs btn-danger" @click="removeProduct(item)">Hapus</button>
                                </td>
                            </tr>
                            <tr v-if="!filteredProducts.length"><td colspan="7" class="text-center text-muted">Belum ada product.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        Hapus product {{ deleteTarget?.nama_product }}?
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeDeleteModal">Batal</button>
            <button type="button" class="btn btn-danger" @click="confirmDelete">Hapus</button>
        </template>
    </BootstrapModal>
</template>

<script setup>
import { computed, ref } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({ products: Array, fragranceDetails: Array });
const keyword = ref('');
const createForm = useForm({ nama_product: '', harga: '', stock: 0, deskripsi: '', fragrance_details: [], gambar: null });
const editForm = useForm({ id_product: null, nama_product: '', harga: '', harga_modal: 0, stock: 0, deskripsi: '', fragrance_details: [], gambar: null, gambar_lama: null });
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const filteredProducts = computed(() => props.products.filter((item) => item.nama_product.toLowerCase().includes(keyword.value.toLowerCase())));
const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value || 0);
const createErrorMessages = computed(() => Object.values(createForm.errors || {}));
const editErrorMessages = computed(() => Object.values(editForm.errors || {}));

const truncateWords = (value, limit = 10) => {
    const words = String(value || '').trim().split(/\s+/).filter(Boolean);
    if (!words.length) return '-';
    return words.length <= limit ? words.join(' ') : `${words.slice(0, limit).join(' ')}...`;
};
const setImageFile = (form, event) => {
    form.gambar = event.target.files?.[0] ?? null;
};

const submitCreate = () => createForm.post('/products', {
    forceFormData: true,
    preserveScroll: true,
    onSuccess: () => createForm.reset(),
});
const pickEdit = (item) => Object.assign(editForm, {
    id_product: item.id_product,
    nama_product: item.nama_product,
    harga: item.harga,
    harga_modal: item.harga_modal,
    stock: item.stock,
    deskripsi: item.deskripsi || '',
    fragrance_details: item.fragrance_details.map((detail) => String(detail.id_fd)),
    gambar: null,
    gambar_lama: item.gambar || null,
});
const submitEdit = () => {
    editForm.transform((data) => ({ id_product: data.id_product, nama_product: data.nama_product, harga: data.harga, stock: data.stock, deskripsi: data.deskripsi, fragrance_details: data.fragrance_details, gambar: data.gambar, _method: 'put' })).post(`/products/${editForm.id_product}`, {
        forceFormData: true,
        preserveScroll: true,
        onSuccess: () => editForm.reset(),
    });
};
const resetEdit = () => editForm.reset();
const removeProduct = (item) => {
    deleteTarget.value = item;
    showDeleteModal.value = true;
};
const closeDeleteModal = () => {
    showDeleteModal.value = false;
    deleteTarget.value = null;
};
const confirmDelete = () => {
    if (!deleteTarget.value) return;
    const id = deleteTarget.value.id_product;
    closeDeleteModal();
    router.delete(`/products/${id}`, { preserveScroll: true });
};
</script>

<style scoped>
.fragrance-box {
    max-height: 220px;
    overflow-y: auto;
}

.product-preview-image {
    width: 96px;
    height: 96px;
    object-fit: cover;
    border-radius: 0.5rem;
    border: 1px solid #dee2e6;
}

.fragrance-badge {
    display: inline-block;
    padding: 0.35rem 0.55rem;
    border-radius: 999px;
    background: #eef2ff;
    border: 1px solid #c7d2fe;
    color: #3730a3;
    font-weight: 600;
}
</style>

