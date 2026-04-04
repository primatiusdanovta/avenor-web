<template>
    <AppLayout>
    <Head title="Content Creator" />

    <template #actions>
        <button type="button" class="btn btn-primary" @click="openCreateModal">
            <i class="fas fa-plus mr-1"></i>
            Tambah Content Creator
        </button>
    </template>

    <div v-if="hasErrors" class="alert alert-danger">
        <div v-for="(message, key) in page.props.errors" :key="key">{{ message }}</div>
    </div>

    <div class="row">
        <div class="col-lg-12">
            <div class="card card-outline card-success">
                <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <h3 class="card-title mb-0">Daftar Content Creator</h3>
                    <div class="d-flex align-items-center flex-wrap gap-2">
                        <input v-model="searchQuery" type="text" class="form-control form-control-sm creator-search" placeholder="Cari creator, wilayah, atau akun">
                        <select v-model.number="pageSize" class="form-control form-control-sm creator-page-size">
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
                                <th role="button" @click="setSort('created_at')">Tanggal</th>
                                <th role="button" @click="setSort('nama')">Nama</th>
                                <th>Bidang</th>
                                <th>Instagram</th>
                                <th>TikTok</th>
                                <th role="button" @click="setSort('followers_total')">Followers</th>
                                <th>Fee</th>
                                <th>No Telp</th>
                                <th>Wilayah</th>
                                <th class="action-column">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="item in paginatedCreators" :key="item.id_contentcreator">
                                <td>{{ item.created_at || '-' }}</td>
                                <td><button type="button" class="btn btn-link p-0 font-weight-bold text-left" @click="openEditModal(item)">{{ item.nama }}</button></td>
                                <td>{{ (item.bidang || []).join(', ') || '-' }}</td>
                                <td>{{ item.username_instagram || '-' }}</td>
                                <td>{{ item.username_tiktok || '-' }}</td>
                                <td>
                                    IG: {{ formatNumber(item.followers_instagram) }}<br>
                                    TT: {{ formatNumber(item.followers_tiktok) }}
                                </td>
                                <td>
                                    {{ item.range_fee_percontent || '-' }}<br>
                                    <span class="text-muted text-sm">{{ item.jenis_konten || '-' }}</span>
                                </td>
                                <td>{{ item.no_telp || '-' }}</td>
                                <td>{{ item.wilayah || '-' }}</td>
                                <td>
                                    <div class="action-group">
                                        <button class="btn btn-xs btn-warning" @click="openEditModal(item)"><i class="fas fa-pen mr-1"></i>Edit</button>
                                        <button class="btn btn-xs btn-outline-danger" @click="removeCreator(item)"><i class="fas fa-trash-alt mr-1"></i>Hapus</button>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="!paginatedCreators.length"><td colspan="10" class="text-center text-muted">Belum ada data content creator.</td></tr>
                        </tbody>
                    </table>
                </div>
                <div class="card-footer d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <div class="text-muted small">Menampilkan {{ paginationLabel }}</div>
                    <div class="btn-group btn-group-sm">
                        <button class="btn btn-outline-secondary" :disabled="currentPage === 1" @click="currentPage -= 1">Prev</button>
                        <button class="btn btn-outline-secondary disabled">Hal {{ currentPage }} / {{ totalPages }}</button>
                        <button class="btn btn-outline-secondary" :disabled="currentPage === totalPages" @click="currentPage += 1">Next</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <BootstrapModal :show="showCreateModal" title="Tambah Content Creator" size="xl" @close="closeCreateModal">
        <div class="crud-modal-body">
            <div class="form-group mb-0"><label>Nama</label><input v-model="createForm.nama" type="text" class="form-control"></div>
            <div class="form-group mb-0">
                <label>Bidang</label>
                <div class="border rounded p-2 bg-light bidang-box">
                    <div v-for="option in bidangOptions" :key="`create-${option}`" class="custom-control custom-checkbox">
                        <input :id="`create-${slugify(option)}`" :checked="createForm.bidang.includes(option)" type="checkbox" class="custom-control-input" @change="toggleBidang(createForm, option)">
                        <label class="custom-control-label" :for="`create-${slugify(option)}`">{{ option }}</label>
                    </div>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group col-md-6 mb-0"><label>Username Instagram</label><input v-model="createForm.username_instagram" type="text" class="form-control"></div>
                <div class="form-group col-md-6 mb-0"><label>Username TikTok</label><input v-model="createForm.username_tiktok" type="text" class="form-control"></div>
            </div>
            <div class="form-row">
                <div class="form-group col-md-6 mb-0"><label>Followers Instagram</label><input v-model="createForm.followers_instagram" type="number" min="0" class="form-control"></div>
                <div class="form-group col-md-6 mb-0"><label>Followers TikTok</label><input v-model="createForm.followers_tiktok" type="number" min="0" class="form-control"></div>
            </div>
            <div class="form-row">
                <div class="form-group col-md-6 mb-0"><label>Range Fee per Content</label><input v-model="createForm.range_fee_percontent" type="text" class="form-control"></div>
                <div class="form-group col-md-6 mb-0"><label>Jenis Konten</label><input v-model="createForm.jenis_konten" type="text" class="form-control"></div>
            </div>
            <div class="form-row">
                <div class="form-group col-md-6 mb-0"><label>No Telp</label><input v-model="createForm.no_telp" type="text" class="form-control"></div>
                <div class="form-group col-md-6 mb-0"><label>Wilayah</label><input v-model="createForm.wilayah" type="text" class="form-control"></div>
            </div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeCreateModal">Batal</button>
            <button type="button" class="btn btn-primary" :disabled="createForm.processing" @click="submitCreate">Simpan Content Creator</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showEditModal" title="Edit Content Creator" size="xl" @close="closeEditModal">
        <div class="crud-modal-body">
            <div class="form-group mb-0"><label>Nama</label><input v-model="editForm.nama" type="text" class="form-control"></div>
            <div class="form-group mb-0">
                <label>Bidang</label>
                <div class="border rounded p-2 bg-light bidang-box">
                    <div v-for="option in bidangOptions" :key="`edit-${option}`" class="custom-control custom-checkbox">
                        <input :id="`edit-${slugify(option)}`" :checked="editForm.bidang.includes(option)" type="checkbox" class="custom-control-input" @change="toggleBidang(editForm, option)">
                        <label class="custom-control-label" :for="`edit-${slugify(option)}`">{{ option }}</label>
                    </div>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group col-md-6 mb-0"><label>Username Instagram</label><input v-model="editForm.username_instagram" type="text" class="form-control"></div>
                <div class="form-group col-md-6 mb-0"><label>Username TikTok</label><input v-model="editForm.username_tiktok" type="text" class="form-control"></div>
            </div>
            <div class="form-row">
                <div class="form-group col-md-6 mb-0"><label>Followers Instagram</label><input v-model="editForm.followers_instagram" type="number" min="0" class="form-control"></div>
                <div class="form-group col-md-6 mb-0"><label>Followers TikTok</label><input v-model="editForm.followers_tiktok" type="number" min="0" class="form-control"></div>
            </div>
            <div class="form-row">
                <div class="form-group col-md-6 mb-0"><label>Range Fee per Content</label><input v-model="editForm.range_fee_percontent" type="text" class="form-control"></div>
                <div class="form-group col-md-6 mb-0"><label>Jenis Konten</label><input v-model="editForm.jenis_konten" type="text" class="form-control"></div>
            </div>
            <div class="form-row">
                <div class="form-group col-md-6 mb-0"><label>No Telp</label><input v-model="editForm.no_telp" type="text" class="form-control"></div>
                <div class="form-group col-md-6 mb-0"><label>Wilayah</label><input v-model="editForm.wilayah" type="text" class="form-control"></div>
            </div>
        </div>
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeEditModal">Batal</button>
            <button type="button" class="btn btn-warning" :disabled="editForm.processing || !editForm.id_contentcreator" @click="submitEdit">Update</button>
        </template>
    </BootstrapModal>

    <BootstrapModal :show="showDeleteModal" title="Konfirmasi Hapus" size="mobile-full" @close="closeDeleteModal">
        Hapus content creator {{ deleteTarget?.nama }}?
        <template #footer>
            <button type="button" class="btn btn-secondary" @click="closeDeleteModal">Batal</button>
            <button type="button" class="btn btn-danger" @click="confirmDelete">Hapus</button>
        </template>
    </BootstrapModal>

    </AppLayout>
</template>

<script setup>
import { computed, ref, watch } from 'vue';
import { Head, router, useForm, usePage } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';
import { adminUrl } from '../../utils/admin';

const props = defineProps({ contentCreators: Array, bidangOptions: Array });
const page = usePage();

const createDefaults = {
    nama: '',
    bidang: [],
    username_instagram: '',
    username_tiktok: '',
    followers_instagram: 0,
    followers_tiktok: 0,
    range_fee_percontent: '',
    jenis_konten: '',
    no_telp: '',
    wilayah: '',
};

const editDefaults = {
    id_contentcreator: null,
    ...createDefaults,
};

const createForm = useForm({ ...createDefaults });
const editForm = useForm({ ...editDefaults });
const hasErrors = computed(() => Object.keys(page.props.errors || {}).length > 0);
const searchQuery = ref('');
const sortBy = ref('created_at');
const sortDirection = ref('desc');
const currentPage = ref(1);
const pageSize = ref(10);
const showCreateModal = ref(false);
const showEditModal = ref(false);
const showDeleteModal = ref(false);
const deleteTarget = ref(null);

const normalize = (value) => String(value || '').toLowerCase();
const creatorRows = computed(() => props.contentCreators.map((item) => ({
    ...item,
    followers_total: Number(item.followers_instagram || 0) + Number(item.followers_tiktok || 0),
})));

const filteredCreators = computed(() => {
    const keyword = normalize(searchQuery.value);
    if (!keyword) {
        return creatorRows.value;
    }

    return creatorRows.value.filter((item) => [
        item.nama,
        item.username_instagram,
        item.username_tiktok,
        item.wilayah,
        (item.bidang || []).join(' '),
    ].some((field) => normalize(field).includes(keyword)));
});

const sortedCreators = computed(() => {
    const rows = [...filteredCreators.value];

    rows.sort((left, right) => {
        let leftValue = left[sortBy.value];
        let rightValue = right[sortBy.value];

        if (sortBy.value === 'created_at') {
            leftValue = new Date(left.created_at || 0).getTime();
            rightValue = new Date(right.created_at || 0).getTime();
        }

        if (typeof leftValue === 'string') {
            leftValue = leftValue.toLowerCase();
        }

        if (typeof rightValue === 'string') {
            rightValue = rightValue.toLowerCase();
        }

        if (leftValue === rightValue) {
            return 0;
        }

        const result = leftValue > rightValue ? 1 : -1;
        return sortDirection.value === 'asc' ? result : -result;
    });

    return rows;
});

const totalPages = computed(() => Math.max(Math.ceil(sortedCreators.value.length / pageSize.value), 1));
const paginatedCreators = computed(() => {
    const start = (currentPage.value - 1) * pageSize.value;
    return sortedCreators.value.slice(start, start + pageSize.value);
});
const paginationLabel = computed(() => {
    if (!sortedCreators.value.length) {
        return '0 data';
    }

    const start = (currentPage.value - 1) * pageSize.value + 1;
    const end = Math.min(start + pageSize.value - 1, sortedCreators.value.length);
    return `${start}-${end} dari ${sortedCreators.value.length} data`;
});

watch([searchQuery, pageSize], () => {
    currentPage.value = 1;
});

watch(totalPages, (value) => {
    if (currentPage.value > value) {
        currentPage.value = value;
    }
});

const setSort = (field) => {
    if (sortBy.value === field) {
        sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc';
        return;
    }

    sortBy.value = field;
    sortDirection.value = field === 'created_at' ? 'desc' : 'asc';
};

const toggleBidang = (form, option) => {
    if (form.bidang.includes(option)) {
        form.bidang = form.bidang.filter((item) => item !== option);
        return;
    }

    form.bidang = [...form.bidang, option];
};

const openCreateModal = () => {
    Object.assign(createForm, { ...createDefaults });
    showCreateModal.value = true;
};
const closeCreateModal = () => {
    showCreateModal.value = false;
    Object.assign(createForm, { ...createDefaults });
};
const openEditModal = (item) => {
    Object.assign(editForm, {
        id_contentcreator: item.id_contentcreator,
        nama: item.nama,
        bidang: [...(item.bidang || [])],
        username_instagram: item.username_instagram || '',
        username_tiktok: item.username_tiktok || '',
        followers_instagram: item.followers_instagram || 0,
        followers_tiktok: item.followers_tiktok || 0,
        range_fee_percontent: item.range_fee_percontent || '',
        jenis_konten: item.jenis_konten || '',
        no_telp: item.no_telp || '',
        wilayah: item.wilayah || '',
    });
    showEditModal.value = true;
};
const closeEditModal = () => {
    showEditModal.value = false;
    Object.assign(editForm, { ...editDefaults });
};
const submitCreate = () => createForm.post(adminUrl('/content-creators'), { preserveScroll: true, onSuccess: closeCreateModal });
const submitEdit = () => editForm.put(adminUrl(`/content-creators/${editForm.id_contentcreator}`), { preserveScroll: true, onSuccess: closeEditModal });
const removeCreator = (item) => {
    deleteTarget.value = item;
    showDeleteModal.value = true;
};
const closeDeleteModal = () => {
    showDeleteModal.value = false;
    deleteTarget.value = null;
};
const confirmDelete = () => {
    if (!deleteTarget.value) return;
    const id = deleteTarget.value.id_contentcreator;
    closeDeleteModal();
    router.delete(adminUrl(`/content-creators/${id}`), { preserveScroll: true });
};

const formatNumber = (value) => new Intl.NumberFormat('id-ID').format(Number(value || 0));
const slugify = (value) => String(value).toLowerCase().replace(/\s+/g, '-');
</script>

<style scoped>
.bidang-box {
    max-height: 220px;
    overflow-y: auto;
}

.creator-search {
    width: 240px;
}

.creator-page-size {
    width: 80px;
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
    .creator-search,
    .creator-page-size {
        width: 100%;
    }

    .action-group {
        grid-template-columns: 1fr;
    }
}
</style>



