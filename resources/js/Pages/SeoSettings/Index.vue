<template>
    <Head title="SEO Manager" />

    <div class="row">
        <div class="col-12">
            <div class="card card-outline card-dark">
                <div class="card-header">
                    <h3 class="card-title">SEO Landing Page</h3>
                </div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-lg-8">
                            <div class="form-group">
                                <label>SEO Title</label>
                                <input v-model="form.title" type="text" class="form-control">
                            </div>
                        </div>
                        <div class="col-lg-4">
                            <div class="form-group">
                                <label>Robots</label>
                                <input v-model="form.robots" type="text" class="form-control" placeholder="index,follow">
                            </div>
                        </div>
                    </div>

                    <div class="form-group">
                        <label>Meta Description</label>
                        <textarea v-model="form.meta_description" rows="4" class="form-control"></textarea>
                    </div>

                    <div class="form-group">
                        <label>Meta Keywords</label>
                        <textarea v-model="form.meta_keywords" rows="3" class="form-control"></textarea>
                    </div>

                    <div class="row">
                        <div class="col-lg-6">
                            <div class="form-group">
                                <label>Canonical URL</label>
                                <input v-model="form.canonical_url" type="text" class="form-control" placeholder="https://example.com/">
                            </div>
                        </div>
                        <div class="col-lg-6">
                            <div class="form-group">
                                <label>OG Image URL</label>
                                <input v-model="form.og_image" type="text" class="form-control" placeholder="https://example.com/og-image.jpg">
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-lg-6">
                            <div class="form-group">
                                <label>Open Graph Title</label>
                                <input v-model="form.og_title" type="text" class="form-control">
                            </div>
                        </div>
                        <div class="col-lg-6">
                            <div class="form-group">
                                <label>Open Graph Description</label>
                                <textarea v-model="form.og_description" rows="3" class="form-control"></textarea>
                            </div>
                        </div>
                    </div>

                    <div class="form-group">
                        <label>Schema JSON-LD</label>
                        <textarea v-model="form.schema_json" rows="12" class="form-control font-monospace"></textarea>
                        <small v-if="form.errors.schema_json" class="text-danger">{{ form.errors.schema_json }}</small>
                    </div>

                    <div class="form-group">
                        <label class="d-flex align-items-center gap-2 mb-0">
                            <input v-model="form.is_active" type="checkbox">
                            <span>SEO aktif untuk landing page</span>
                        </label>
                    </div>

                    <div class="d-flex gap-2">
                        <button type="button" class="btn btn-dark" :disabled="form.processing" @click="submit">
                            Simpan SEO
                        </button>
                        <a href="/" target="_blank" rel="noopener" class="btn btn-outline-secondary">
                            Preview Landing
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { Head, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import { adminUrl } from '../../utils/admin';

defineOptions({ layout: AppLayout });

const props = defineProps({
    seo: Object,
});

const form = useForm({
    title: props.seo?.title ?? '',
    meta_description: props.seo?.meta_description ?? '',
    meta_keywords: props.seo?.meta_keywords ?? '',
    canonical_url: props.seo?.canonical_url ?? '',
    og_title: props.seo?.og_title ?? '',
    og_description: props.seo?.og_description ?? '',
    og_image: props.seo?.og_image ?? '',
    robots: props.seo?.robots ?? 'index,follow',
    schema_json: props.seo?.schema_json ?? '',
    is_active: props.seo?.is_active ?? true,
});

const submit = () => {
    form.put(adminUrl('/seo-settings'), { preserveScroll: true });
};
</script>


