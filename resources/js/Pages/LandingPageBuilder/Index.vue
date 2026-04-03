<template>
    <Head title="Landing Page Builder" />

    <div class="row g-3">
        <div class="col-lg-4">
            <div class="card card-outline card-dark h-100">
                <div class="card-header">
                    <h3 class="card-title">Variant Products</h3>
                </div>
                <div class="card-body p-0">
                    <div class="list-group list-group-flush">
                        <button
                            v-for="product in products"
                            :key="product.id_product"
                            type="button"
                            class="list-group-item list-group-item-action text-start"
                            :class="{ active: selectedId === product.id_product }"
                            @click="selectProduct(product.id_product)"
                        >
                            <div class="d-flex justify-content-between align-items-center gap-2">
                                <strong>{{ product.nama_product }}</strong>
                                <span class="badge" :class="product.landing_page_active ? 'bg-success' : 'bg-secondary'">
                                    {{ product.landing_page_active ? 'Active' : 'Inactive' }}
                                </span>
                            </div>
                            <div class="small text-muted mt-1">/product/{{ product.landing_slug }}</div>
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-lg-8">
            <div v-if="selectedProduct" class="card card-outline card-warning">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h3 class="card-title">{{ selectedProduct.nama_product }}</h3>
                    <a :href="selectedProduct.preview_url" target="_blank" rel="noopener" class="btn btn-sm btn-dark">Preview Landing</a>
                </div>
                <div class="card-body">
                    <div class="form-group mb-3">
                        <label class="d-flex align-items-center gap-2 mb-0">
                            <input v-model="form.landing_page_active" type="checkbox">
                            <span>Landing page aktif untuk variant ini</span>
                        </label>
                    </div>

                    <div class="card bg-light mb-4">
                        <div class="card-header"><strong>Theme & SEO Preset</strong></div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-6 form-group">
                                    <label>Theme Preset</label>
                                    <select v-model="form.landing_theme_key" class="form-control">
                                        <option value="">Gunakan default global</option>
                                        <option v-for="option in themeOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                                    </select>
                                    <small class="form-text text-muted">Menentukan eyebrow hero dan palette theme untuk halaman product ini.</small>
                                </div>
                                <div class="col-md-6 form-group">
                                    <label>SEO Fallback Preset</label>
                                    <select v-model="form.landing_seo_fallback_key" class="form-control">
                                        <option value="">Gunakan default global</option>
                                        <option v-for="option in seoFallbackOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                                    </select>
                                    <small class="form-text text-muted">Dipakai saat SEO title atau description custom pada product dikosongkan.</small>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6 form-group">
                            <label>SEO Title</label>
                            <input v-model="form.seo_title" type="text" class="form-control">
                        </div>
                        <div class="col-md-6 form-group">
                            <label>Canonical URL</label>
                            <input v-model="form.canonical_url" type="text" class="form-control" placeholder="https://example.com/product/slug">
                        </div>
                    </div>

                    <div class="form-group">
                        <label>SEO Description</label>
                        <textarea v-model="form.seo_description" rows="4" class="form-control"></textarea>
                    </div>

                    <div class="row mt-3">
                        <div class="col-md-4 form-group">
                            <label>Top Notes</label>
                            <textarea v-model="form.top_notes_text" rows="5" class="form-control"></textarea>
                        </div>
                        <div class="col-md-4 form-group">
                            <label>Heart Notes</label>
                            <textarea v-model="form.heart_notes_text" rows="5" class="form-control"></textarea>
                        </div>
                        <div class="col-md-4 form-group">
                            <label>Base Notes</label>
                            <textarea v-model="form.base_notes_text" rows="5" class="form-control"></textarea>
                        </div>
                    </div>

                    <div class="card bg-light mt-4">
                        <div class="card-header"><strong>Educational Section</strong></div>
                        <div class="card-body">
                            <div class="form-group">
                                <label>Education Title</label>
                                <input v-model="form.education_content.title" type="text" class="form-control">
                            </div>
                            <div class="form-group">
                                <label>Education Body</label>
                                <textarea v-model="form.education_content.body" rows="5" class="form-control"></textarea>
                            </div>
                            <div class="form-group mb-0">
                                <label>Education Tips</label>
                                <textarea v-model="educationTips" rows="5" class="form-control" placeholder="Satu tips per baris"></textarea>
                            </div>
                        </div>
                    </div>

                    <div class="card bg-light mt-4">
                        <div class="card-header"><strong>Narrative Scroll</strong></div>
                        <div class="card-body">
                            <div class="form-group">
                                <label>Kicker</label>
                                <input v-model="form.narrative_scroll.kicker" type="text" class="form-control">
                            </div>
                            <div class="form-group">
                                <label>Title</label>
                                <input v-model="form.narrative_scroll.title" type="text" class="form-control">
                            </div>
                            <div class="form-group mb-0">
                                <label>Description</label>
                                <textarea v-model="form.narrative_scroll.description" rows="4" class="form-control"></textarea>
                            </div>

                            <div class="d-flex justify-content-between align-items-center mt-4 mb-3">
                                <strong>Stages</strong>
                                <button type="button" class="btn btn-sm btn-outline-dark" @click="addNarrativeStage">Tambah Stage</button>
                            </div>
                            <div v-for="(stage, index) in form.narrative_scroll.stages" :key="`stage-${index}`" class="border rounded p-3 mb-3">
                                <div class="form-group">
                                    <label>Section Key</label>
                                    <input v-model="stage.section_name" type="text" class="form-control" placeholder="stage_1">
                                </div>
                                <div class="form-group">
                                    <label>Stage Title</label>
                                    <input v-model="stage.title" type="text" class="form-control">
                                </div>
                                <div class="form-group mb-2">
                                    <label>Stage Description</label>
                                    <textarea v-model="stage.description" rows="4" class="form-control"></textarea>
                                </div>
                                <div class="d-flex flex-wrap gap-2">
                                    <button type="button" class="btn btn-sm btn-outline-secondary" :disabled="index === 0" @click="moveNarrativeStage(index, -1)">Naik</button>
                                    <button type="button" class="btn btn-sm btn-outline-secondary" :disabled="index === form.narrative_scroll.stages.length - 1" @click="moveNarrativeStage(index, 1)">Turun</button>
                                    <button type="button" class="btn btn-sm btn-outline-danger" @click="removeNarrativeStage(index)">Hapus</button>
                                </div>
                            </div>
                            <div v-if="!form.narrative_scroll.stages.length" class="text-muted">Belum ada stage custom. Jika kosong, halaman akan memakai top, heart, dan base notes default.</div>
                        </div>
                    </div>

                    <div class="card bg-light mt-4">
                        <div class="card-header"><strong>Bottle Image</strong></div>
                        <div class="card-body">
                            <div class="form-group">
                                <label>Upload Bottle Image</label>
                                <input type="file" class="form-control" accept="image/*" @change="setBottleImage">
                                <small class="form-text text-muted">Gunakan PNG/WebP background transparan agar efek glow, tilt, dan floating tetap terasa natural pada halaman product.</small>
                            </div>

                            <div v-if="bottleImagePreviewUrl" class="bottle-preview">
                                <img :src="bottleImagePreviewUrl" alt="Bottle preview" class="bottle-preview__image">
                                <div class="d-flex flex-wrap gap-2 mt-3">
                                    <button
                                        type="button"
                                        class="btn btn-sm"
                                        :class="form.remove_bottle_image ? 'btn-outline-success' : 'btn-outline-danger'"
                                        @click="toggleRemoveBottleImage"
                                    >
                                        {{ form.remove_bottle_image ? 'Batal Hapus Bottle Image' : 'Hapus Bottle Image' }}
                                    </button>
                                </div>
                            </div>
                            <div v-else class="text-muted">Belum ada bottle image. Jika kosong, halaman akan memakai botol luxury placeholder atau gallery sesuai konfigurasi.</div>
                        </div>
                    </div>

                    <div class="card bg-light mt-4">
                        <div class="card-header"><strong>Product Gallery</strong></div>
                        <div class="card-body">
                            <div class="form-group">
                                <label>Tambah Gambar Product</label>
                                <input type="file" class="form-control" accept="image/*" multiple @change="setGalleryFiles">
                                <small class="form-text text-muted">Upload bisa lebih dari satu gambar. Urutan paling atas akan tampil lebih dulu pada slider product.</small>
                            </div>

                            <div v-if="galleryPreviewImages.length" class="gallery-list">
                                <div v-for="(image, index) in galleryPreviewImages" :key="image.key" class="gallery-item" :class="{ 'gallery-item--removed': image.markedForRemoval }">
                                    <img :src="image.image_url" alt="gallery preview" class="gallery-item__image">
                                    <div class="gallery-item__body">
                                        <div class="font-weight-bold">
                                            {{ image.isNew ? `Gambar baru ${index + 1}` : `Gambar ${index + 1}` }}
                                        </div>
                                        <div class="small text-muted">{{ image.isNew ? 'Belum disimpan' : `Urutan tampil: ${index + 1}` }}</div>
                                        <div class="d-flex flex-wrap gap-2 mt-2">
                                            <button type="button" class="btn btn-sm btn-outline-secondary" :disabled="index === 0 || image.markedForRemoval" @click="moveGalleryImage(index, -1)">Naik</button>
                                            <button type="button" class="btn btn-sm btn-outline-secondary" :disabled="index === galleryPreviewImages.length - 1 || image.markedForRemoval" @click="moveGalleryImage(index, 1)">Turun</button>
                                            <button
                                                v-if="!image.isNew"
                                                type="button"
                                                class="btn btn-sm"
                                                :class="image.markedForRemoval ? 'btn-outline-success' : 'btn-outline-danger'"
                                                @click="toggleRemoveGalleryImage(image.id)"
                                            >
                                                {{ image.markedForRemoval ? 'Batal Hapus' : 'Hapus' }}
                                            </button>
                                            <button
                                                v-else
                                                type="button"
                                                class="btn btn-sm btn-outline-danger"
                                                @click="removeNewGalleryImage(image.key)"
                                            >
                                                Hapus
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div v-else class="text-muted">Belum ada gambar gallery. Jika kosong, sistem masih akan fallback ke gambar utama product lama bila tersedia.</div>
                        </div>
                    </div>

                    <div class="card bg-light mt-4">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <strong>FAQ Accordion</strong>
                            <button type="button" class="btn btn-sm btn-outline-dark" @click="addFaq">Tambah FAQ</button>
                        </div>
                        <div class="card-body">
                            <div v-for="(faq, index) in form.faq_data" :key="index" class="border rounded p-3 mb-3">
                                <div class="form-group">
                                    <label>Pertanyaan</label>
                                    <input v-model="faq.question" type="text" class="form-control">
                                </div>
                                <div class="form-group mb-2">
                                    <label>Jawaban</label>
                                    <textarea v-model="faq.answer" rows="4" class="form-control"></textarea>
                                </div>
                                <button type="button" class="btn btn-sm btn-outline-danger" @click="removeFaq(index)">Hapus FAQ</button>
                            </div>
                            <div v-if="!form.faq_data.length" class="text-muted">Belum ada FAQ untuk product ini.</div>
                        </div>
                    </div>

                    <div class="card bg-light mt-4">
                        <div class="card-header"><strong>Fragrance Details</strong></div>
                        <div class="card-body">
                            <div v-if="selectedProduct.fragrance_details?.length" class="d-flex flex-wrap gap-2">
                                <span v-for="detail in selectedProduct.fragrance_details" :key="detail.id_fd" class="badge border text-dark">{{ detail.jenis }}: {{ detail.detail }}</span>
                            </div>
                            <div v-else class="text-muted">Belum ada fragrance details pada produk ini.</div>
                        </div>
                    </div>

                    <div class="mt-4 d-flex gap-2">
                        <button type="button" class="btn btn-warning" :disabled="form.processing" @click="submit">Simpan Builder</button>
                        <button type="button" class="btn btn-secondary" :disabled="form.processing" @click="resetCurrent">Reset</button>
                    </div>
                </div>
            </div>
            <div v-else class="card card-outline card-secondary">
                <div class="card-body text-muted">Pilih product untuk mengatur landing page variant.</div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue';
import { Head, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    products: { type: Array, default: () => [] },
    themeOptions: { type: Array, default: () => [] },
    seoFallbackOptions: { type: Array, default: () => [] },
});

const selectedId = ref(props.products?.[0]?.id_product ?? null);
const selectedProduct = computed(() => props.products.find((item) => item.id_product === selectedId.value) ?? null);

const form = useForm({
    landing_page_active: false,
    landing_theme_key: '',
    landing_seo_fallback_key: '',
    seo_title: '',
    seo_description: '',
    canonical_url: '',
    top_notes_text: '',
    heart_notes_text: '',
    base_notes_text: '',
    education_content: {
        title: '',
        body: '',
        tips: [],
    },
    faq_data: [],
    narrative_scroll: {
        kicker: '',
        title: '',
        description: '',
        stages: [],
    },
    remove_bottle_image: false,
    bottle_image: null,
    gallery_sequence: [],
    gallery_image_order: [],
    remove_gallery_image_ids: [],
    gallery_new_image_keys: [],
    gallery_images: [],
});

const educationTips = ref('');
const galleryExisting = ref([]);
const galleryNewFiles = ref([]);
const bottleImagePreviewUrl = ref('');
const bottleImageObjectUrl = ref('');

const revokeNewGalleryPreviews = () => {
    galleryNewFiles.value.forEach((item) => {
        if (item.image_url) {
            URL.revokeObjectURL(item.image_url);
        }
    });
};

const revokeBottlePreview = () => {
    if (bottleImageObjectUrl.value) {
        URL.revokeObjectURL(bottleImageObjectUrl.value);
        bottleImageObjectUrl.value = '';
    }
};

const hydrateForm = (product) => {
    if (!product) return;

    revokeNewGalleryPreviews();
    revokeBottlePreview();

    form.defaults({
        landing_page_active: product.landing_page_active ?? false,
        landing_theme_key: product.landing_theme_key ?? '',
        landing_seo_fallback_key: product.landing_seo_fallback_key ?? '',
        seo_title: product.seo_title ?? '',
        seo_description: product.seo_description ?? '',
        canonical_url: product.canonical_url ?? '',
        top_notes_text: product.top_notes_text ?? '',
        heart_notes_text: product.heart_notes_text ?? '',
        base_notes_text: product.base_notes_text ?? '',
        education_content: {
            title: product.education_content?.title ?? 'Customer Education',
            body: product.education_content?.body ?? '',
            tips: product.education_content?.tips ?? [],
        },
        faq_data: (product.faq_data ?? []).map((faq) => ({ question: faq.question ?? '', answer: faq.answer ?? '' })),
        narrative_scroll: {
            kicker: product.narrative_scroll?.kicker ?? '',
            title: product.narrative_scroll?.title ?? '',
            description: product.narrative_scroll?.description ?? '',
            stages: (product.narrative_scroll?.stages ?? []).map((stage, index) => ({
                section_name: stage.section_name ?? `stage_${index + 1}`,
                title: stage.title ?? '',
                description: stage.description ?? '',
            })),
        },
        remove_bottle_image: false,
        bottle_image: null,
        gallery_sequence: (product.gallery_images ?? []).map((image) => `existing:${image.id}`),
        gallery_image_order: (product.gallery_images ?? []).map((image) => image.id),
        remove_gallery_image_ids: [],
        gallery_new_image_keys: [],
        gallery_images: [],
    });

    form.reset();
    educationTips.value = (product.education_content?.tips ?? []).join('\n');
    bottleImagePreviewUrl.value = product.bottle_image_url ?? '';
    galleryExisting.value = (product.gallery_images ?? []).map((image) => ({
        id: image.id,
        image_url: image.image_url,
        markedForRemoval: false,
    }));
    galleryNewFiles.value = [];
};

const setBottleImage = (event) => {
    const file = event.target.files?.[0] ?? null;
    revokeBottlePreview();
    form.bottle_image = file;
    form.remove_bottle_image = false;

    if (file) {
        bottleImageObjectUrl.value = URL.createObjectURL(file);
        bottleImagePreviewUrl.value = bottleImageObjectUrl.value;
    } else {
        bottleImagePreviewUrl.value = selectedProduct.value?.bottle_image_url ?? '';
    }

    event.target.value = '';
};

const toggleRemoveBottleImage = () => {
    const nextState = !form.remove_bottle_image;
    form.remove_bottle_image = nextState;

    if (nextState) {
        revokeBottlePreview();
        form.bottle_image = null;
        bottleImagePreviewUrl.value = '';
        return;
    }

    bottleImagePreviewUrl.value = bottleImageObjectUrl.value || selectedProduct.value?.bottle_image_url || '';
};

watch(selectedProduct, (product) => {
    hydrateForm(product);
}, { immediate: true });

watch(educationTips, (value) => {
    form.education_content.tips = String(value)
        .split(/\r?\n/)
        .map((item) => item.trim())
        .filter(Boolean);
});

const addFaq = () => {
    form.faq_data.push({ question: '', answer: '' });
};

const removeFaq = (index) => {
    form.faq_data.splice(index, 1);
};

const addNarrativeStage = () => {
    form.narrative_scroll.stages.push({
        section_name: `stage_${form.narrative_scroll.stages.length + 1}`,
        title: '',
        description: '',
    });
};

const removeNarrativeStage = (index) => {
    form.narrative_scroll.stages.splice(index, 1);
};

const moveNarrativeStage = (index, direction) => {
    const targetIndex = index + direction;
    if (targetIndex < 0 || targetIndex >= form.narrative_scroll.stages.length) return;
    const copy = [...form.narrative_scroll.stages];
    const [item] = copy.splice(index, 1);
    copy.splice(targetIndex, 0, item);
    form.narrative_scroll.stages = copy;
};

const syncGalleryPayload = () => {
    form.gallery_sequence = galleryPreviewImages.value
        .filter((image) => !image.markedForRemoval)
        .map((image) => image.isNew ? `new:${image.key}` : `existing:${image.id}`);
    form.gallery_image_order = galleryExisting.value
        .filter((image) => !image.markedForRemoval)
        .map((image) => image.id);
    form.remove_gallery_image_ids = galleryExisting.value
        .filter((image) => image.markedForRemoval)
        .map((image) => image.id);
    form.gallery_new_image_keys = galleryNewFiles.value.map((item) => item.key);
    form.gallery_images = galleryNewFiles.value.map((item) => item.file);
};

const setGalleryFiles = (event) => {
    const files = Array.from(event.target.files ?? []);
    if (!files.length) return;
    galleryNewFiles.value.push(...files.map((file, index) => ({
        key: `new-${Date.now()}-${index}-${file.name}`,
        file,
        image_url: URL.createObjectURL(file),
    })));
    syncGalleryPayload();
    event.target.value = '';
};

const toggleRemoveGalleryImage = (id) => {
    galleryExisting.value = galleryExisting.value.map((image) => image.id === id ? { ...image, markedForRemoval: !image.markedForRemoval } : image);
    syncGalleryPayload();
};

const moveGalleryImage = (index, direction) => {
    const items = [...galleryPreviewImages.value];
    const targetIndex = index + direction;
    if (targetIndex < 0 || targetIndex >= items.length) return;
    const [item] = items.splice(index, 1);
    items.splice(targetIndex, 0, item);

    galleryExisting.value = items.filter((item) => !item.isNew).map(({ isNew, key, ...rest }) => rest);
    galleryNewFiles.value = items.filter((item) => item.isNew).map(({ id, isNew, markedForRemoval, ...rest }) => rest);
    syncGalleryPayload();
};

const removeNewGalleryImage = (key) => {
    const target = galleryNewFiles.value.find((item) => item.key === key);
    if (!target) return;
    URL.revokeObjectURL(target.image_url);
    galleryNewFiles.value = galleryNewFiles.value.filter((item) => item.key !== target.key);
    syncGalleryPayload();
};

const galleryPreviewImages = computed(() => ([
    ...galleryExisting.value.map((image) => ({
        ...image,
        key: `existing-${image.id}`,
        isNew: false,
    })),
    ...galleryNewFiles.value.map((image) => ({
        ...image,
        id: null,
        markedForRemoval: false,
        isNew: true,
    })),
]));

const selectProduct = (id) => {
    selectedId.value = id;
};

const resetCurrent = () => {
    hydrateForm(selectedProduct.value);
};

const submit = () => {
    if (!selectedProduct.value) return;
    syncGalleryPayload();
    form.transform((data) => ({
        ...data,
        _method: 'put',
    })).post(`/landing-page-builder/${selectedProduct.value.id_product}`, {
        forceFormData: true,
        preserveScroll: true,
    });
};
</script>

<style scoped>
.bottle-preview {
    padding: 1rem;
    border: 1px solid #d9dee4;
    border-radius: 0.9rem;
    background: #fff;
}

.bottle-preview__image {
    display: block;
    width: min(220px, 100%);
    max-height: 320px;
    object-fit: contain;
}

.gallery-list {
    display: grid;
    gap: 1rem;
}

.gallery-item {
    display: flex;
    gap: 1rem;
    align-items: center;
    padding: 0.9rem;
    border: 1px solid #d9dee4;
    border-radius: 0.9rem;
    background: #fff;
}

.gallery-item--removed {
    opacity: 0.55;
    border-style: dashed;
}

.gallery-item__image {
    width: 88px;
    height: 88px;
    object-fit: cover;
    border-radius: 0.75rem;
    border: 1px solid #d9dee4;
}

.gallery-item__body {
    flex: 1;
}
</style>
