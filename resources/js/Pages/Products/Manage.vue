<template>
    <AppLayout>
    <Head title="Products" />

    <template #actions>
        <button type="button" class="btn btn-primary" @click="openCreateModal">
            <i class="fas fa-plus mr-1"></i>
            Tambah Product
        </button>
    </template>

    <div class="row">
        <div class="col-lg-12">
            <div class="card card-outline card-success">
                <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <h3 class="card-title mb-0">Daftar Product</h3>
                    <input v-model="keyword" type="text" class="form-control form-control-sm product-search" placeholder="Cari product">
                </div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Gambar</th><th>Nama</th><th v-if="!isSmoothiesSweetie">Fragrance Detail</th><th>Varian</th><th>Harga</th><th>Harga Modal</th><th>Stock</th><th class="action-column">Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in filteredProducts" :key="item.id_product">
                                <td><img v-if="item.gambar" :src="item.gambar" alt="product" style="width:48px;height:48px;object-fit:cover"></td>
                                <td>
                                    <button type="button" class="btn btn-link p-0 font-weight-bold text-left" @click="openEditModal(item)">{{ item.nama_product }}</button>
                                    <div class="text-muted small">{{ truncateWords(item.deskripsi, 10) }}</div>
                                </td>
                                <td v-if="!isSmoothiesSweetie">
                                    <div v-if="item.fragrance_details.length" class="small">
                                        <span v-for="detail in item.fragrance_details" :key="`${item.id_product}-${detail.id_fd}`" class="fragrance-badge mr-1 mb-1">{{ detail.detail }}</span>
                                    </div>
                                    <span v-else class="text-muted">-</span>
                                </td>
                                <td>
                                    <div v-if="item.variants?.length" class="small">
                                        <div v-for="variant in item.variants" :key="`${item.id_product}-${variant.id}`">
                                            {{ variant.name }} | {{ toCurrency(variant.price) }}<span v-if="variant.total_satuan_ml"> | {{ formatNumber(variant.total_satuan_ml) }} ml</span>
                                        </div>
                                    </div>
                                    <span v-else class="text-muted">-</span>
                                </td>
                                <td>{{ toCurrency(item.harga) }}</td>
                                <td>{{ toCurrency(item.harga_modal) }}</td>
                                <td>{{ item.stock }}</td>
                                <td>
                                    <div class="action-group">
                                        <button class="btn btn-xs btn-warning" @click="openEditModal(item)"><i class="fas fa-pen mr-1"></i>Edit</button>
                                        <button class="btn btn-xs btn-danger" @click="removeProduct(item)"><i class="fas fa-trash-alt mr-1"></i>Hapus</button>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="!filteredProducts.length"><td :colspan="isSmoothiesSweetie ? 8 : 9" class="text-center text-muted">Belum ada product.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showCreateModal" title="Tambah Product" size="xl" @close="closeCreateModal">
        <div class="crud-modal-body">
            <div v-if="createErrorMessages.length" class="alert alert-danger mb-0">
                <div v-for="message in createErrorMessages" :key="`create-error-${message}`">{{ message }}</div>
            </div>
            <div class="form-group mb-0">
                <label>Nama Product</label>
                <input v-model="createForm.nama_product" type="text" class="form-control" :class="{ 'is-invalid': createForm.errors.nama_product }">
                <div v-if="createForm.errors.nama_product" class="invalid-feedback d-block">{{ createForm.errors.nama_product }}</div>
            </div>
            <div class="form-row">
                <div class="form-group col-md-6 mb-0">
                    <label>Harga</label>
                    <input v-model="createForm.harga" type="number" min="0" class="form-control" :class="{ 'is-invalid': createForm.errors.harga }">
                    <div v-if="createForm.errors.harga" class="invalid-feedback d-block">{{ createForm.errors.harga }}</div>
                </div>
                <div class="form-group col-md-6 mb-0"><label>Harga Modal</label><input :value="0" type="number" min="0" class="form-control" disabled></div>
            </div>
            <small class="text-muted d-block">Harga modal diisi otomatis dari halaman HPP.</small>
            <div v-if="!isSmoothiesSweetie" class="form-group mb-0">
                <label>Stock Awal</label>
                <input v-model="createForm.stock" type="number" min="0" class="form-control" :class="{ 'is-invalid': createForm.errors.stock }">
                <div v-if="createForm.errors.stock" class="invalid-feedback d-block">{{ createForm.errors.stock }}</div>
            </div>
            <small class="text-muted d-block">
                {{ isSmoothiesSweetie ? 'Stock awal disembunyikan untuk store Smoothies Sweetie. Tambah stock dilakukan setelah product selesai dibuat.' : 'Buat product baru dengan stock 0 terlebih dahulu. Setelah HPP dibuat, stock ditambah lewat form edit agar raw material ikut terpotong otomatis.' }}
            </small>
            <div class="form-group mb-0">
                <label>Deskripsi</label>
                <RichTextEditor v-model="createForm.deskripsi" />
                <div v-if="createForm.errors.deskripsi" class="invalid-feedback d-block">{{ createForm.errors.deskripsi }}</div>
            </div>
            <div class="form-group mb-0">
                <label>Varian Product</label>
                <div class="variant-box">
                    <div v-for="(variant, index) in createForm.variants" :key="variant.key" class="border rounded p-2 mb-2 bg-light">
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <strong>Varian {{ index + 1 }}</strong>
                            <button v-if="createForm.variants.length > 1" type="button" class="btn btn-xs btn-outline-danger" @click="removeVariant(createForm, index)">Hapus</button>
                        </div>
                        <div class="row">
                            <div class="col-md-4 mb-2">
                                <label class="small">Nama Varian</label>
                                <input v-model="variant.name" type="text" class="form-control" placeholder="Reguler / Large">
                            </div>
                            <div class="col-md-4 mb-2">
                                <label class="small">Harga</label>
                                <input v-model="variant.price" type="number" min="0" class="form-control">
                            </div>
                            <div class="col-md-3 mb-2">
                                <label class="small">Total Satuan ML</label>
                                <input v-model="variant.total_satuan_ml" type="number" min="0" step="0.01" class="form-control">
                            </div>
                            <div class="col-md-1 mb-2 d-flex align-items-end">
                                <div class="form-check">
                                    <input :id="`create-default-${index}`" v-model="variant.is_default" type="radio" class="form-check-input" :name="'create-default-variant'" @change="markDefaultVariant(createForm, index)">
                                    <label class="form-check-label small" :for="`create-default-${index}`">Default</label>
                                </div>
                            </div>
                        </div>
                    </div>
                    <button type="button" class="btn btn-sm btn-outline-secondary" @click="addVariant(createForm)">Tambah Varian</button>
                </div>
            </div>
            <div v-if="!isSmoothiesSweetie" class="form-group mb-0">
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
            <div class="form-group mb-0">
                <label>Gambar</label>
                <input type="file" class="form-control" accept="image/*" :class="{ 'is-invalid': createForm.errors.gambar }" @change="setImageFile(createForm, $event)">
                <div v-if="createForm.errors.gambar" class="invalid-feedback d-block">{{ createForm.errors.gambar }}</div>
            </div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeCreateModal">Batal</button>
            <button type="button" class="btn btn-primary" :disabled="createForm.processing" @click="submitCreate">Simpan Product</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showEditModal" title="Edit Product" size="xl" @close="closeEditModal">
        <div class="crud-modal-body">
            <div v-if="editErrorMessages.length" class="alert alert-danger mb-0">
                <div v-for="message in editErrorMessages" :key="`edit-error-${message}`">{{ message }}</div>
            </div>
            <div class="form-group mb-0">
                <label>Nama Product</label>
                <input v-model="editForm.nama_product" type="text" class="form-control" :class="{ 'is-invalid': editForm.errors.nama_product }">
                <div v-if="editForm.errors.nama_product" class="invalid-feedback d-block">{{ editForm.errors.nama_product }}</div>
            </div>
            <div class="form-row">
                <div class="form-group col-md-6 mb-0">
                    <label>Harga</label>
                    <input v-model="editForm.harga" type="number" min="0" class="form-control" :class="{ 'is-invalid': editForm.errors.harga }">
                    <div v-if="editForm.errors.harga" class="invalid-feedback d-block">{{ editForm.errors.harga }}</div>
                </div>
                <div class="form-group col-md-6 mb-0"><label>Harga Modal</label><input :value="editForm.harga_modal" type="number" min="0" class="form-control" disabled></div>
            </div>
            <small class="text-muted d-block">Ubah harga modal melalui halaman HPP jika komposisi raw material berubah.</small>
            <div class="form-group mb-0">
                <label>Stock</label>
                <input v-model="editForm.stock" type="number" min="0" class="form-control" :class="{ 'is-invalid': editForm.errors.stock }">
                <div v-if="editForm.errors.stock" class="invalid-feedback d-block">{{ editForm.errors.stock }}</div>
            </div>
            <div class="form-group mb-0">
                <label>Deskripsi</label>
                <RichTextEditor v-model="editForm.deskripsi" />
                <div v-if="editForm.errors.deskripsi" class="invalid-feedback d-block">{{ editForm.errors.deskripsi }}</div>
            </div>
            <div class="form-group mb-0">
                <label>Varian Product</label>
                <div class="variant-box">
                    <div v-for="(variant, index) in editForm.variants" :key="variant.key" class="border rounded p-2 mb-2 bg-light">
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <strong>Varian {{ index + 1 }}</strong>
                            <button v-if="editForm.variants.length > 1" type="button" class="btn btn-xs btn-outline-danger" @click="removeVariant(editForm, index)">Hapus</button>
                        </div>
                        <div class="row">
                            <div class="col-md-4 mb-2">
                                <label class="small">Nama Varian</label>
                                <input v-model="variant.name" type="text" class="form-control" placeholder="Reguler / Large">
                            </div>
                            <div class="col-md-4 mb-2">
                                <label class="small">Harga</label>
                                <input v-model="variant.price" type="number" min="0" class="form-control">
                            </div>
                            <div class="col-md-3 mb-2">
                                <label class="small">Total Satuan ML</label>
                                <input v-model="variant.total_satuan_ml" type="number" min="0" step="0.01" class="form-control">
                            </div>
                            <div class="col-md-1 mb-2 d-flex align-items-end">
                                <div class="form-check">
                                    <input :id="`edit-default-${index}`" v-model="variant.is_default" type="radio" class="form-check-input" :name="'edit-default-variant'" @change="markDefaultVariant(editForm, index)">
                                    <label class="form-check-label small" :for="`edit-default-${index}`">Default</label>
                                </div>
                            </div>
                        </div>
                    </div>
                    <button type="button" class="btn btn-sm btn-outline-secondary" @click="addVariant(editForm)">Tambah Varian</button>
                </div>
            </div>
            <div v-if="!isSmoothiesSweetie" class="form-group mb-0">
                <label>Fragrance Detail</label>
                <div class="border rounded p-2 bg-light fragrance-box">
                    <div v-for="item in fragranceDetails" :key="`edit-${item.id_fd}`" class="custom-control custom-checkbox">
                        <input :id="`edit-fragrance-${item.id_fd}`" v-model="editForm.fragrance_details" :value="String(item.id_fd)" type="checkbox" class="custom-control-input">
                        <label class="custom-control-label" :for="`edit-fragrance-${item.id_fd}`">{{ item.detail }}</label>
                    </div>
                </div>
                <div v-if="editForm.errors.fragrance_details" class="text-danger small mt-1">{{ editForm.errors.fragrance_details }}</div>
            </div>
            <div v-if="editForm.gambar_lama" class="form-group mb-0">
                <label>Gambar Saat Ini</label>
                <div>
                    <img :src="editForm.gambar_lama" alt="current product" class="product-preview-image">
                </div>
                <small class="text-muted">Upload gambar baru hanya jika ingin mengganti gambar product.</small>
            </div>
            <div class="form-group mb-0">
                <label>Gambar Baru</label>
                <input type="file" class="form-control" accept="image/*" :class="{ 'is-invalid': editForm.errors.gambar }" @change="setImageFile(editForm, $event)">
                <div v-if="editForm.errors.gambar" class="invalid-feedback d-block">{{ editForm.errors.gambar }}</div>
            </div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeEditModal">Batal</button>
            <button type="button" class="btn btn-warning" :disabled="editForm.processing || !editForm.id_product" @click="submitEdit">Update</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        Hapus product {{ deleteTarget?.nama_product }}?
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeDeleteModal">Batal</button>
            <button type="button" class="btn btn-danger" @click="confirmDelete">Hapus</button>
        </template>
    </BootstrapModal>

    </AppLayout>
</template>

<script setup>
import { computed, ref } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';
import RichTextEditor from '../../Components/RichTextEditor.vue';
import { adminUrl } from '../../utils/admin';

const props = defineProps({ products: Array, fragranceDetails: Array, isSmoothiesSweetie: Boolean });
const keyword = ref('');
const emptyVariant = () => ({ key: `${Date.now()}-${Math.random()}`, id: null, name: '', price: 0, total_satuan_ml: 0, is_default: false });
const createForm = useForm({ nama_product: '', harga: '', stock: 0, deskripsi: '', fragrance_details: [], variants: [emptyVariant()], gambar: null });
const editForm = useForm({ id_product: null, nama_product: '', harga: '', harga_modal: 0, stock: 0, deskripsi: '', fragrance_details: [], variants: [emptyVariant()], gambar: null, gambar_lama: null });
const showCreateModal = ref(false);
const showEditModal = ref(false);
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const filteredProducts = computed(() => props.products.filter((item) => item.nama_product.toLowerCase().includes(keyword.value.toLowerCase())));
const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value || 0);
const createErrorMessages = computed(() => Object.values(createForm.errors || {}));
const editErrorMessages = computed(() => Object.values(editForm.errors || {}));
const formatNumber = (value) => new Intl.NumberFormat('id-ID', { maximumFractionDigits: 2 }).format(Number(value || 0));
const plainText = (value) => String(value || '')
    .replace(/<[^>]*>/g, ' ')
    .replace(/&nbsp;/gi, ' ')
    .replace(/\s+/g, ' ')
    .trim();

const truncateWords = (value, limit = 10) => {
    const words = plainText(value).split(/\s+/).filter(Boolean);
    if (!words.length) return '-';
    return words.length <= limit ? words.join(' ') : `${words.slice(0, limit).join(' ')}...`;
};
const setImageFile = (form, event) => {
    form.gambar = event.target.files?.[0] ?? null;
};
const addVariant = (form) => {
    form.variants.push(emptyVariant());
};
const removeVariant = (form, index) => {
    form.variants.splice(index, 1);
    if (!form.variants.length) {
        form.variants = [emptyVariant()];
    }
    if (!form.variants.some((variant) => variant.is_default)) {
        form.variants[0].is_default = true;
    }
};
const markDefaultVariant = (form, index) => {
    form.variants = form.variants.map((variant, currentIndex) => ({
        ...variant,
        is_default: currentIndex === index,
    }));
};
const openCreateModal = () => {
    createForm.reset();
    createForm.fragrance_details = [];
    createForm.variants = [Object.assign(emptyVariant(), { name: 'Reguler', price: 0, is_default: true })];
    createForm.gambar = null;
    showCreateModal.value = true;
};
const closeCreateModal = () => {
    showCreateModal.value = false;
    createForm.reset();
    createForm.fragrance_details = [];
    createForm.variants = [emptyVariant()];
    createForm.gambar = null;
};
const submitCreate = () => createForm.transform((data) => ({
    ...data,
    variants: data.variants.map(({ id, name, price, total_satuan_ml, is_default }) => ({ id, name, price, total_satuan_ml, is_default })),
})).post(adminUrl('/products'), {
    forceFormData: true,
    preserveScroll: true,
    onSuccess: () => closeCreateModal(),
});
const openEditModal = (item) => {
    Object.assign(editForm, {
        id_product: item.id_product,
        nama_product: item.nama_product,
        harga: item.harga,
        harga_modal: item.harga_modal,
        stock: item.stock,
        deskripsi: item.deskripsi || '',
        fragrance_details: item.fragrance_details.map((detail) => String(detail.id_fd)),
        variants: item.variants?.length
            ? item.variants.map((variant) => ({ key: `${variant.id}-${Math.random()}`, id: variant.id, name: variant.name, price: variant.price, total_satuan_ml: variant.total_satuan_ml, is_default: variant.is_default }))
            : [Object.assign(emptyVariant(), { name: 'Reguler', price: item.harga, is_default: true })],
        gambar: null,
        gambar_lama: item.gambar || null,
    });
    showEditModal.value = true;
};
const closeEditModal = () => {
    showEditModal.value = false;
    editForm.reset();
    editForm.id_product = null;
    editForm.fragrance_details = [];
    editForm.variants = [emptyVariant()];
    editForm.gambar = null;
    editForm.gambar_lama = null;
};
const submitEdit = () => {
    editForm.transform((data) => ({ id_product: data.id_product, nama_product: data.nama_product, harga: data.harga, stock: data.stock, deskripsi: data.deskripsi, fragrance_details: data.fragrance_details, variants: data.variants.map(({ id, name, price, total_satuan_ml, is_default }) => ({ id, name, price, total_satuan_ml, is_default })), gambar: data.gambar, _method: 'put' })).post(adminUrl(`/products/${editForm.id_product}`), {
        forceFormData: true,
        preserveScroll: true,
        onSuccess: () => closeEditModal(),
    });
};
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
    router.delete(adminUrl(`/products/${id}`), { preserveScroll: true });
};
</script>

<style scoped>
.product-search {
    width: 220px;
}

.fragrance-box {
    max-height: 220px;
    overflow-y: auto;
}

.variant-box {
    max-height: 340px;
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

.action-column {
    min-width: 170px;
}

.action-group {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 0.45rem;
}

.action-group .btn {
    width: 100%;
    min-width: 0;
    white-space: nowrap;
}

.crud-modal-body {
    display: grid;
    gap: 1rem;
}

@media (max-width: 575.98px) {
    .product-search {
        width: 100%;
    }

    .action-group {
        grid-template-columns: 1fr;
    }
}
</style>



