<template>
    <Head title="Product Knowledge" />

    <div class="knowledge-page">
        <div class="card card-outline card-primary mb-3">
            <div class="card-header"><h3 class="card-title">Filter Product Knowledge</h3></div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-12">
                        <label>Filter Detail</label>
                        <div class="border rounded p-2 bg-light filter-checkbox-box">
                            <div v-for="detail in detailOptions" :key="`${detail.jenis}-${detail.detail}`" class="custom-control custom-checkbox">
                                <input
                                    :id="`detail-${slugify(detail.jenis)}-${slugify(detail.detail)}`"
                                    :checked="selectedDetail.includes(detail.detail)"
                                    type="checkbox"
                                    class="custom-control-input"
                                    @change="toggleDetail(detail.detail)"
                                >
                                <label class="custom-control-label" :for="`detail-${slugify(detail.jenis)}-${slugify(detail.detail)}`">
                                    {{ detail.detail }}
                                    <span class="text-muted">({{ detail.jenis }})</span>
                                </label>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="mt-3 d-flex flex-wrap align-items-center gap-2">
                    <span class="text-muted small">Filter aktif akan langsung mengeliminasi product tanpa reload halaman.</span>
                    <button type="button" class="btn btn-sm btn-outline-secondary ml-auto" @click="resetFilters">Reset Filter</button>
                </div>
            </div>
        </div>

        <TransitionGroup name="knowledge-list" tag="div" class="row">
            <div v-for="product in filteredProducts" :key="product.id_product" class="col-md-6 col-xl-4 mb-3">
                <div class="card knowledge-card h-100 shadow-sm">
                    <div class="knowledge-media">
                        <button v-if="product.gambar" type="button" class="knowledge-image-button" @click="openPreview(product)">
                            <img :src="product.gambar" :alt="product.nama_product" class="knowledge-image">
                        </button>
                        <button v-else type="button" class="knowledge-image placeholder d-flex align-items-center justify-content-center text-muted border-0 w-100" @click="openPreview(product)">No Image</button>
                    </div>
                    <div class="card-body text-center d-flex flex-column justify-content-center">
                        <h5 class="card-title mb-3">{{ product.nama_product }}</h5>
                        <div class="d-flex flex-wrap justify-content-center">
                            <span v-for="detail in product.fragrance_details" :key="`${product.id_product}-${detail.id_fd}`" class="badge border mr-1 mb-1 knowledge-badge">
                                {{ detail.detail }}
                            </span>
                            <span v-if="!product.fragrance_details.length" class="text-muted small">Belum ada data fragrance detail.</span>
                        </div>
                    </div>
                </div>
            </div>
        </TransitionGroup>

        <div v-if="!filteredProducts.length" class="alert alert-light border text-muted">Tidak ada product yang cocok dengan kombinasi filter saat ini.</div>
    </div>

    <BootstrapModal :show="Boolean(activeProduct)" :title="activeProduct?.nama_product || 'Detail Product'" size="lg" @close="activeProduct = null">
        <div v-if="activeProduct" class="text-center">
            <img v-if="activeProduct.gambar" :src="activeProduct.gambar" :alt="activeProduct.nama_product" class="img-fluid rounded border knowledge-preview-image mb-3">
            <div v-else class="knowledge-preview-empty rounded border mb-3 d-flex align-items-center justify-content-center text-muted">No Image</div>
            <p class="text-left mb-0">{{ activeProduct.deskripsi || 'Belum ada deskripsi product.' }}</p>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="activeProduct = null">Tutup</button>
        </template>
    </BootstrapModal>
</template>

<script setup>
import { computed, ref } from 'vue';
import { Head } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({ products: Array, fragranceFilters: Array });
const selectedDetail = ref([]);
const activeProduct = ref(null);

const detailOptions = computed(() => props.fragranceFilters.flatMap((group) => group.details.map((detail) => ({ jenis: group.jenis, detail: detail.detail }))));
const filteredProducts = computed(() => props.products.filter((product) => {
    const details = product.fragrance_details || [];
    return !selectedDetail.value.length || details.some((item) => selectedDetail.value.includes(item.detail));
}));

const resetFilters = () => {
    selectedDetail.value = [];
};

const toggleDetail = (detail) => {
    if (selectedDetail.value.includes(detail)) {
        selectedDetail.value = selectedDetail.value.filter((item) => item !== detail);
        return;
    }

    selectedDetail.value = [...selectedDetail.value, detail];
};

const openPreview = (product) => {
    activeProduct.value = product;
};

const slugify = (value) => String(value).toLowerCase().replace(/\s+/g, '-');
</script>

<style scoped>
.knowledge-page {
    min-height: 100%;
}

.filter-checkbox-box {
    max-height: 220px;
    overflow-y: auto;
}

.knowledge-card {
    border-radius: 20px;
    overflow: hidden;
    border: 1px solid #e8decf;
}

.knowledge-media {
    background: linear-gradient(135deg, #f8f3ec, #efe4d2);
    padding: 16px;
}

.knowledge-image-button {
    display: block;
    width: 100%;
    border: 0;
    background: transparent;
    padding: 0;
}

.knowledge-image {
    width: 100%;
    height: 240px;
    object-fit: cover;
    border-radius: 16px;
}

.placeholder {
    background: rgba(255, 255, 255, 0.65);
}

.knowledge-badge {
    color: #4b2e1f;
    background-color: #f8f1e7;
    border-color: #d8b98f !important;
}

.knowledge-preview-image,
.knowledge-preview-empty {
    width: 100%;
    max-height: 70vh;
    object-fit: contain;
    min-height: 240px;
}

.knowledge-list-enter-active,
.knowledge-list-leave-active {
    transition: all 0.25s ease;
}

.knowledge-list-enter-from,
.knowledge-list-leave-to {
    opacity: 0;
    transform: translateY(10px);
}
</style>
