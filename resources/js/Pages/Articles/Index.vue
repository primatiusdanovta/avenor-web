<template>
    <Head title="Article" />

    <div class="row g-4">
        <div class="col-lg-5">
            <div class="card card-outline card-primary">
                <div class="card-header">
                    <h3 class="card-title mb-0">{{ editForm.id ? 'Edit Article' : 'Tambah Article' }}</h3>
                </div>
                <div class="card-body">
                    <div class="form-group">
                        <label>Judul</label>
                        <input v-model="activeForm.title" type="text" class="form-control" placeholder="Masukkan judul article">
                    </div>
                    <div class="form-group">
                        <label>Slug</label>
                        <input v-model="activeForm.slug" type="text" class="form-control" placeholder="Kosongkan agar dibuat otomatis">
                        <small class="text-muted">Publik akan dibuka di `/article/{slug}`.</small>
                    </div>
                    <div class="form-row">
                        <div class="form-group col-md-6">
                            <label>Author</label>
                            <input v-model="activeForm.author" type="text" class="form-control" placeholder="Nama penulis">
                        </div>
                        <div class="form-group col-md-6">
                            <label>Tanggal</label>
                            <input v-model="activeForm.published_at" type="date" class="form-control">
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Deskripsi Singkat</label>
                        <textarea v-model="activeForm.excerpt" rows="3" class="form-control" maxlength="500" placeholder="Ringkasan singkat untuk card article"></textarea>
                    </div>
                    <div class="form-group">
                        <label>Isi Article</label>
                        <textarea v-model="activeForm.body" rows="10" class="form-control" placeholder="Tulis isi article. Pisahkan paragraf dengan baris kosong."></textarea>
                    </div>
                    <div class="form-group">
                        <label>Gambar</label>
                        <input type="file" class="form-control" accept="image/*" @change="setImage(activeForm, $event)">
                    </div>
                    <div v-if="imagePreviewUrl" class="article-preview mb-3">
                        <img :src="imagePreviewUrl" alt="Preview article" class="article-preview__image">
                    </div>
                    <div v-if="editForm.id && editForm.image_url" class="mb-3">
                        <button type="button" class="btn btn-sm" :class="activeForm.remove_image ? 'btn-outline-success' : 'btn-outline-danger'" @click="activeForm.remove_image = !activeForm.remove_image">
                            {{ activeForm.remove_image ? 'Batal hapus gambar' : 'Hapus gambar lama' }}
                        </button>
                    </div>
                    <div class="form-group">
                        <label class="mb-0 d-inline-flex align-items-center gap-2">
                            <input v-model="activeForm.is_published" type="checkbox">
                            <span>Publish article</span>
                        </label>
                    </div>
                    <div class="d-flex gap-2 flex-wrap">
                        <button class="btn btn-primary" :disabled="activeForm.processing" @click="submitForm">
                            {{ activeForm.processing ? 'Menyimpan...' : (editForm.id ? 'Update Article' : 'Simpan Article') }}
                        </button>
                        <button v-if="editForm.id" class="btn btn-secondary" type="button" @click="resetEdit">Batal</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-lg-7">
            <div class="card card-outline card-success">
                <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <h3 class="card-title mb-0">Daftar Article</h3>
                    <div class="d-flex align-items-center flex-wrap gap-2">
                        <input v-model="searchQuery" type="text" class="form-control form-control-sm article-search" placeholder="Cari judul, author, slug, atau deskripsi">
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
                                <th>Tanggal</th>
                                <th>Status</th>
                                <th>Preview</th>
                                <th>Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="item in paginatedArticles" :key="item.id">
                                <td class="article-cell">
                                    <div class="fw-semibold">{{ item.title }}</div>
                                    <div class="text-muted small">{{ item.slug }}</div>
                                    <div class="text-muted small mt-1">{{ item.excerpt }}</div>
                                </td>
                                <td>{{ item.author }}</td>
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
                                    <button class="btn btn-xs btn-warning mr-1" @click="pickEdit(item)">Edit</button>
                                    <button class="btn btn-xs btn-outline-danger" @click="removeArticle(item)">Hapus</button>
                                </td>
                            </tr>
                            <tr v-if="!paginatedArticles.length">
                                <td colspan="6" class="text-center text-muted">Belum ada article.</td>
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

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        Hapus article {{ deleteTarget?.title }}?
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeDeleteModal">Batal</button>
            <button type="button" class="btn btn-danger" @click="confirmDelete">Hapus</button>
        </template>
    </BootstrapModal>
</template>

<script setup>
import { computed, ref, watch } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import BootstrapModal from '../../Components/BootstrapModal.vue';
import AppLayout from '../../Layouts/AppLayout.vue';
import { adminUrl } from '../../utils/admin';

defineOptions({ layout: AppLayout });

const props = defineProps({
    articles: { type: Array, default: () => [] },
});

const defaults = () => ({
    id: null,
    title: '',
    slug: '',
    author: 'Avenor Team',
    published_at: new Date().toISOString().slice(0, 10),
    excerpt: '',
    body: '',
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
const showDeleteModal = ref(false);
const deleteTarget = ref(null);
const previewObjectUrl = ref('');

const activeForm = computed(() => (editForm.id ? editForm : createForm));
const imagePreviewUrl = computed(() => previewObjectUrl.value || activeForm.value.image_url || '');

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
        item.excerpt,
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

const pickEdit = (item) => {
    revokePreview();
    Object.assign(editForm, {
        id: item.id,
        title: item.title,
        slug: item.slug,
        author: item.author || 'Avenor Team',
        published_at: item.published_at || new Date().toISOString().slice(0, 10),
        excerpt: item.excerpt || '',
        body: item.body || '',
        is_published: Boolean(item.is_published),
        image: null,
        image_url: item.image_url || '',
        remove_image: false,
    });
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
</style>
