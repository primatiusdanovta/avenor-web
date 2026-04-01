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
});

const educationTips = ref('');

const hydrateForm = (product) => {
    if (!product) return;

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
    });

    form.reset();
    educationTips.value = (product.education_content?.tips ?? []).join('\n');
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

const selectProduct = (id) => {
    selectedId.value = id;
};

const resetCurrent = () => {
    hydrateForm(selectedProduct.value);
};

const submit = () => {
    if (!selectedProduct.value) return;
    form.put(`/landing-page-builder/${selectedProduct.value.id_product}`, { preserveScroll: true });
};
</script>
