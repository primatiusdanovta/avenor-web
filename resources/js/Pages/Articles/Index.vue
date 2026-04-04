<template>
    <AppLayout>
    <Head title="Article" />

    <template #actions>
        <button type="button" class="btn btn-primary" @click="openCreateModal">
            <i class="fas fa-plus mr-1"></i>
            Tambah Article
        </button>
    </template>

    <div class="row">
        <div class="col-lg-12">
            <div class="card card-outline card-success">
                <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <h3 class="card-title mb-0">Daftar Article</h3>
                    <div class="d-flex align-items-center flex-wrap gap-2">
                        <input v-model="searchQuery" type="text" class="form-control form-control-sm article-search" placeholder="Cari judul, author, slug, kategori, atau deskripsi">
                        <select v-model.number="pageSize" class="form-control form-control-sm article-page-size">
                            <option :value="5">5</option>
                            <option :value="10">10</option>
                            <option :value="25">25</option>
                        </select>
                    </div>
                </div>

                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Article</th>
                                <th>Author</th>
                                <th>Kategori</th>
                                <th>Tanggal</th>
                                <th>Status</th>
                                <th>Preview</th>
                                <th class="action-column">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="item in paginatedArticles" :key="item.id">
                                <td class="article-cell">
                                    <button type="button" class="btn btn-link p-0 font-weight-bold text-left" @click="openEditModal(item)">{{ item.title }}</button>
                                    <div class="text-muted small">{{ item.slug }}</div>
                                    <div class="text-muted small mt-1">{{ item.excerpt }}</div>
                                    <div v-if="item.seo_title || item.seo_description" class="text-muted small mt-2">
                                        SEO custom aktif
                                    </div>
                                </td>
                                <td>{{ item.author }}</td>
                                <td>
                                    <span class="badge badge-light border">{{ item.category || 'Journal' }}</span>
                                </td>
                                <td>{{ item.published_at || '-' }}</td>
                                <td>
                                    <span class="badge" :class="item.is_published ? 'badge-success' : 'badge-secondary'">
                                        {{ item.is_published ? 'Published' : 'Draft' }}
                                    </span>
                                </td>
                                <td>
                                    <a :href="item.public_url" target="_blank" rel="noopener" class="btn btn-xs btn-outline-dark">Buka</a>
                                </td>
                                <td>
                                    <div class="action-group">
                                        <button class="btn btn-xs btn-warning" @click="openEditModal(item)"><i class="fas fa-pen mr-1"></i>Edit</button>
                                        <button class="btn btn-xs btn-outline-danger" @click="removeArticle(item)"><i class="fas fa-trash-alt mr-1"></i>Hapus</button>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="!paginatedArticles.length">
                                <td colspan="7" class="text-center text-muted">Belum ada article.</td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <div class="card-footer d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <div class="text-muted small">{{ paginationLabel }}</div>
                    <div class="btn-group btn-group-sm">
                        <button class="btn btn-outline-secondary" :disabled="currentPage === 1" @click="currentPage -= 1">Prev</button>
                        <button class="btn btn-outline-secondary disabled">Hal {{ currentPage }} / {{ totalPages }}</button>
                        <button class="btn btn-outline-secondary" :disabled="currentPage === totalPages" @click="currentPage += 1">Next</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showFormModal" :title="formModalTitle" size="xl" @close="closeFormModal">
        <div class="crud-modal-body">
            <div class="form-group mb-0">
                <label>Judul</label>
                <input v-model="activeForm.title" type="text" class="form-control" placeholder="Masukkan judul article">
            </div>
            <div class="form-row">
                <div class="form-group col-md-6 mb-0">
                    <label>Slug</label>
                    <input v-model="activeForm.slug" type="text" class="form-control" placeholder="Kosongkan agar dibuat otomatis">
                    <small class="text-muted">Publik akan dibuka di `/article/{slug}`.</small>
                </div>
                <div class="form-group col-md-6 mb-0">
                    <label>Kategori</label>
                    <input v-model="activeForm.category" list="article-category-options" type="text" class="form-control" placeholder="Pilih atau ketik kategori">
                    <datalist id="article-category-options">
                        <option v-for="category in categories" :key="category" :value="category"></option>
                    </datalist>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group col-md-6 mb-0">
                    <label>Author</label>
                    <input v-model="activeForm.author" type="text" class="form-control" placeholder="Nama penulis">
                </div>
                <div class="form-group col-md-6 mb-0">
                    <label>Tanggal</label>
                    <input v-model="activeForm.published_at" type="date" class="form-control">
                </div>
            </div>
            <div class="form-group mb-0">
                <label>Deskripsi Singkat</label>
                <textarea v-model="activeForm.excerpt" rows="3" class="form-control" maxlength="500" placeholder="Ringkasan singkat untuk card article"></textarea>
            </div>
            <div class="form-group mb-0">
                <label>Isi Article</label>
                <RichTextEditor v-model="activeForm.body" />
            </div>
            <div class="form-group mb-0">
                <label>Gambar</label>
                <input type="file" class="form-control" accept="image/*" @change="setImage(activeForm, $event)">
            </div>
            <div v-if="imagePreviewUrl" class="article-preview">
                <img :src="imagePreviewUrl" alt="Preview article" class="article-preview__image">
            </div>

            <div class="seo-panel">
                <div class="seo-panel__title">SEO Manage</div>
                <div class="text-muted small">Field ini akan dipakai khusus untuk halaman article ini. Jika dikosongkan, sistem akan fallback ke judul, excerpt, gambar, dan kategori article.</div>
                <div class="form-group mb-0">
                    <label>SEO Title</label>
                    <input v-model="activeForm.seo_title" type="text" class="form-control" maxlength="255" placeholder="Kosongkan untuk pakai judul article">
                </div>
                <div class="form-group mb-0">
                    <label>SEO Description</label>
                    <textarea v-model="activeForm.seo_description" rows="3" class="form-control" maxlength="500" placeholder="Kosongkan untuk pakai deskripsi singkat"></textarea>
                </div>
                <div class="form-group mb-0">
                    <label>SEO Keywords</label>
                    <input v-model="activeForm.seo_keywords" type="text" class="form-control" maxlength="1000" placeholder="keyword1, keyword2, keyword3">
                </div>
                <div class="form-row">
                    <div class="form-group col-md-6 mb-0">
                        <label>Canonical URL</label>
                        <input v-model="activeForm.seo_canonical_url" type="text" class="form-control" maxlength="2048" placeholder="https://domain.com/article/...">
                    </div>
                    <div class="form-group col-md-6 mb-0">
                        <label>Robots</label>
                        <input v-model="activeForm.seo_robots" type="text" class="form-control" maxlength="255" placeholder="index,follow">
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group col-md-6 mb-0">
                        <label>OG Title</label>
                        <input v-model="activeForm.og_title" type="text" class="form-control" maxlength="255" placeholder="Kosongkan untuk ikut SEO title">
                    </div>
                    <div class="form-group col-md-6 mb-0">
                        <label>OG Image URL</label>
                        <input v-model="activeForm.og_image_url" type="text" class="form-control" maxlength="2048" placeholder="Kosongkan untuk pakai gambar article">
                    </div>
                </div>
                <div class="form-group mb-0">
                    <label>OG Description</label>
                    <textarea v-model="activeForm.og_description" rows="3" class="form-control" maxlength="500" placeholder="Kosongkan untuk ikut SEO description"></textarea>
                </div>
                <div class="form-group mb-0">
                    <label>OG Image Alt</label>
                    <input v-model="activeForm.og_image_alt" type="text" class="form-control" maxlength="255" placeholder="Kosongkan untuk pakai judul article">
                </div>
            </div>

            <div v-if="editForm.id && editForm.image_url" class="mb-0">
                <button type="button" class="btn btn-sm" :class="activeForm.remove_image ? 'btn-outline-success' : 'btn-outline-danger'" @click="activeForm.remove_image = !activeForm.remove_image">
                    {{ activeForm.remove_image ? 'Batal hapus gambar' : 'Hapus gambar lama' }}
                </button>
            </div>
            <div class="form-group mb-0">
                <label class="mb-0 d-inline-flex align-items-center gap-2">
                    <input v-model="activeForm.is_published" type="checkbox">
                    <span>Publish article</span>
                </label>
            </div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeFormModal">Batal</button>
            <button class="btn btn-primary" :disabled="activeForm.processing" @click="submitForm">
                {{ activeForm.processing ? 'Menyimpan...' : (editForm.id ? 'Update Article' : 'Simpan Article') }}
            </button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        Hapus article {{ deleteTarget?.title }}?
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeDeleteModal">Batal</button>
            <button type="button" class="btn btn-danger" @click="confirmDelete">Hapus</button>
        </template>
    </BootstrapModal>

    </AppLayout>
</template>

<script setup>
import { computed, ref, watch } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import BootstrapModal from '../../Components/BootstrapModal.vue';
import RichTextEditor from '../../Components/RichTextEditor.vue';
import AppLayout from '../../Layouts/AppLayout.vue';
import { adminUrl } from '../../utils/admin';

const props = defineProps({
    articles: { type: Array, default: () => [] },
    categories: { type: Array, default: () => [] },
});

const defaults = () => ({
    id: null,
    title: '',
    slug: '',
    author: 'Avenor Team',
    category: props.categories[0] || 'Fragrance Guide',
    published_at: new Date().toISOString().slice(0, 10),
    excerpt: '',
    body: '',
    seo_title: '',
    seo_description: '',
    seo_keywords: '',
    seo_canonical_url: '',
    seo_robots: 'index,follow',
    og_title: '',
    og_description: '',
    og_image_url: '',
    og_image_alt: '',
    is_published: true,
    image: null,
    image_url: '',
    remove_image: false,
});

const createForm = useForm(defaults());
const editForm = useForm(defaults());
const searchQuery = ref('');
const currentPage = ref(1);
const pageSize = ref(5);
const showFormModal = ref(false);
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const previewObjectUrl = ref('');

const activeForm = computed(() => (editForm.id ? editForm : createForm));
const imagePreviewUrl = computed(() => previewObjectUrl.value || activeForm.value.image_url || '');
const formModalTitle = computed(() => editForm.id ? 'Edit Article' : 'Tambah Article');

const normalize = (value) => String(value || '').toLowerCase();

const filteredArticles = computed(() => {
    const keyword = normalize(searchQuery.value);
    if (!keyword) {
        return props.articles;
    }

    return props.articles.filter((item) => [
        item.title,
        item.slug,
        item.author,
        item.category,
        item.excerpt,
        item.seo_title,
        item.seo_description,
    ].some((field) => normalize(field).includes(keyword)));
});

const totalPages = computed(() => Math.max(Math.ceil(filteredArticles.value.length / pageSize.value), 1));
const paginatedArticles = computed(() => {
    const start = (currentPage.value - 1) * pageSize.value;
    return filteredArticles.value.slice(start, start + pageSize.value);
});
const paginationLabel = computed(() => {
    if (!filteredArticles.value.length) {
        return '0 data';
    }

    const start = (currentPage.value - 1) * pageSize.value + 1;
    const end = Math.min(start + pageSize.value - 1, filteredArticles.value.length);
    return `${start}-${end} dari ${filteredArticles.value.length} data`;
});

watch([searchQuery, pageSize], () => {
    currentPage.value = 1;
});

watch(totalPages, (value) => {
    if (currentPage.value > value) {
        currentPage.value = value;
    }
});

const revokePreview = () => {
    if (!previewObjectUrl.value) {
        return;
    }

    URL.revokeObjectURL(previewObjectUrl.value);
    previewObjectUrl.value = '';
};

const setImage = (form, event) => {
    const file = event.target.files?.[0] ?? null;
    form.image = file;
    form.remove_image = false;
    revokePreview();

    if (file) {
        previewObjectUrl.value = URL.createObjectURL(file);
    }
};

const resetCreate = () => {
    revokePreview();
    Object.assign(createForm, defaults());
};

const resetEdit = () => {
    revokePreview();
    Object.assign(editForm, defaults());
};

const openCreateModal = () => {
    resetEdit();
    resetCreate();
    showFormModal.value = true;
};

const openEditModal = (item) => {
    revokePreview();
    Object.assign(editForm, {
        id: item.id,
        title: item.title,
        slug: item.slug,
        author: item.author || 'Avenor Team',
        category: item.category || props.categories[0] || 'Fragrance Guide',
        published_at: item.published_at || new Date().toISOString().slice(0, 10),
        excerpt: item.excerpt || '',
        body: item.body || '',
        seo_title: item.seo_title || '',
        seo_description: item.seo_description || '',
        seo_keywords: item.seo_keywords || '',
        seo_canonical_url: item.seo_canonical_url || '',
        seo_robots: item.seo_robots || 'index,follow',
        og_title: item.og_title || '',
        og_description: item.og_description || '',
        og_image_url: item.og_image_url || '',
        og_image_alt: item.og_image_alt || '',
        is_published: Boolean(item.is_published),
        image: null,
        image_url: item.image_url || '',
        remove_image: false,
    });
    showFormModal.value = true;
};

const closeFormModal = () => {
    showFormModal.value = false;
    resetEdit();
    resetCreate();
};

const submitForm = () => {
    const form = activeForm.value;
    const options = {
        preserveScroll: true,
        forceFormData: true,
        onSuccess: () => {
            if (editForm.id) {
                resetEdit();
            } else {
                resetCreate();
            }
            showFormModal.value = false;
        },
    };

    if (editForm.id) {
        form.put(adminUrl(`/articles/${editForm.id}`), options);
        return;
    }

    form.post(adminUrl('/articles'), options);
};

const removeArticle = (item) => {
    deleteTarget.value = item;
    showDeleteModal.value = true;
};

const closeDeleteModal = () => {
    showDeleteModal.value = false;
    deleteTarget.value = null;
};

const confirmDelete = () => {
    if (!deleteTarget.value) {
        return;
    }

    const id = deleteTarget.value.id;
    closeDeleteModal();
    router.delete(adminUrl(`/articles/${id}`), { preserveScroll: true });
};
</script>

<style scoped>
.article-search {
    width: 260px;
}

.article-page-size {
    width: 84px;
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

.article-cell {
    min-width: 280px;
}

.article-preview {
    overflow: hidden;
    border-radius: 1rem;
    border: 1px solid rgba(0, 0, 0, 0.08);
}

.article-preview__image {
    display: block;
    width: 100%;
    max-height: 240px;
    object-fit: cover;
}

.seo-panel {
    display: grid;
    gap: 1rem;
    padding: 1rem;
    border: 1px solid rgba(0, 0, 0, 0.08);
    border-radius: 1rem;
    background: rgba(248, 249, 250, 0.75);
}

.seo-panel__title {
    font-weight: 700;
    color: #212529;
}

.crud-modal-body {
    display: grid;
    gap: 1rem;
}

@media (max-width: 575.98px) {
    .action-group {
        grid-template-columns: 1fr;
    }

    .article-search,
    .article-page-size {
        width: 100%;
    }
}
</style>
