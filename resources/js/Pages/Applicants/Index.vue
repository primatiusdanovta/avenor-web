<template>
    <Head title="Applicant" />

    <div class="row">
        <div class="col-12">
            <div class="card card-outline card-primary">
                <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <div>
                        <h3 class="card-title mb-0">Daftar Applicant</h3>
                    </div>
                    <div class="d-flex align-items-center flex-wrap gap-2">
                        <input v-model="searchQuery" type="text" class="form-control form-control-sm applicant-search" placeholder="Cari nama, role, kontak, sosial, atau wilayah">
                        <select v-model.number="pageSize" class="form-control form-control-sm applicant-page-size">
                            <option :value="10">10</option>
                            <option :value="25">25</option>
                            <option :value="50">50</option>
                        </select>
                        <button class="btn btn-sm btn-dark" :disabled="!selectedIds.length || bulkProcessing" @click="connectSelected">
                            {{ bulkProcessing ? 'Memindahkan...' : `Pindahkan Terpilih (${selectedIds.length})` }}
                        </button>
                    </div>
                </div>

                <div class="card-body border-bottom bg-light">
                    <div class="d-flex align-items-center flex-wrap gap-3">
                        <label class="mb-0 d-inline-flex align-items-center gap-2">
                            <input type="checkbox" :checked="allVisibleSelected" :indeterminate.prop="someVisibleSelected && !allVisibleSelected" @change="toggleSelectAll">
                            <span>Pilih semua data pada halaman ini</span>
                        </label>
                        <span class="text-muted small">{{ paginationLabel }}</span>
                    </div>
                </div>

                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0 applicant-table">
                        <thead>
                            <tr>
                                <th style="width: 40px;"></th>
                                <th>Tanggal</th>
                                <th>Applicant</th>
                                <th>Posisi</th>
                                <th>Kontak</th>
                                <th>Status</th>
                                <th>Detail</th>
                                <th>Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="item in paginatedApplicants" :key="item.id">
                                <td>
                                    <input
                                        type="checkbox"
                                        :checked="selectedIds.includes(item.id)"
                                        :disabled="Boolean(item.content_creator_id)"
                                        @change="toggleSelection(item.id)"
                                    >
                                </td>
                                <td>{{ item.created_at || '-' }}</td>
                                <td>
                                    <div class="fw-semibold">{{ item.preview?.name || '-' }}</div>
                                    <div class="text-muted small">ID #{{ item.id }}</div>
                                </td>
                                <td>{{ item.job_title || '-' }}</td>
                                <td>
                                    <div>{{ item.preview?.phone || '-' }}</div>
                                    <div class="text-muted small">{{ item.preview?.instagram ? `IG: @${item.preview.instagram}` : 'IG: -' }}</div>
                                    <div class="text-muted small">{{ item.preview?.tiktok ? `TT: @${item.preview.tiktok}` : 'TT: -' }}</div>
                                    <div class="text-muted small">{{ item.preview?.wilayah || '-' }}</div>
                                </td>
                                <td>
                                    <span class="badge" :class="statusClass(item)">
                                        {{ statusLabel(item) }}
                                    </span>
                                    <div v-if="item.content_creator" class="text-muted small mt-1">
                                        Creator: {{ item.content_creator.nama }}
                                    </div>
                                </td>
                                <td class="applicant-detail-cell">
                                    <details>
                                        <summary class="text-primary">Lihat data</summary>
                                        <div class="mt-2">
                                            <div v-if="item.responses?.length" class="mb-2">
                                                <div v-for="field in item.responses" :key="`${item.id}-${field.key}`" class="small mb-1">
                                                    <strong>{{ field.label }}:</strong> {{ field.value || '-' }}
                                                </div>
                                            </div>
                                            <div v-if="item.uploaded_files?.length">
                                                <div class="small fw-semibold mb-1">Lampiran</div>
                                                <div v-for="file in item.uploaded_files" :key="`${item.id}-${file.key}`" class="small mb-1">
                                                    <a v-if="file.url" :href="file.url" target="_blank" rel="noopener">{{ file.label }} - {{ file.original_name }}</a>
                                                    <span v-else>{{ file.label }} - {{ file.original_name }}</span>
                                                </div>
                                            </div>
                                        </div>
                                    </details>
                                </td>
                                <td>
                                    <button
                                        class="btn btn-sm btn-outline-primary"
                                        :disabled="Boolean(item.content_creator_id) || singleProcessingId === item.id"
                                        @click="connectSingle(item.id)"
                                    >
                                        {{ singleProcessingId === item.id ? 'Memindahkan...' : (item.content_creator_id ? 'Terhubung' : 'Pindahkan') }}
                                    </button>
                                </td>
                            </tr>
                            <tr v-if="!paginatedApplicants.length">
                                <td colspan="8" class="text-center text-muted">Belum ada data applicant.</td>
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
</template>

<script setup>
import { computed, ref, watch } from 'vue';
import { Head, router } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import { adminUrl } from '../../utils/admin';

defineOptions({ layout: AppLayout });

const props = defineProps({
    applicants: { type: Array, default: () => [] },
});

const searchQuery = ref('');
const currentPage = ref(1);
const pageSize = ref(10);
const selectedIds = ref([]);
const bulkProcessing = ref(false);
const singleProcessingId = ref(null);

const normalize = (value) => String(value || '').toLowerCase();

const filteredApplicants = computed(() => {
    const keyword = normalize(searchQuery.value);
    if (!keyword) {
        return props.applicants;
    }

    return props.applicants.filter((item) => {
        const responseText = (item.responses || []).map((field) => `${field.label} ${field.value}`).join(' ');
        const uploadedText = (item.uploaded_files || []).map((file) => `${file.label} ${file.original_name}`).join(' ');

        return [
            item.id,
            item.job_title,
            item.status,
            item.preview?.name,
            item.preview?.phone,
            item.preview?.instagram,
            item.preview?.tiktok,
            item.preview?.wilayah,
            item.content_creator?.nama,
            responseText,
            uploadedText,
        ].some((field) => normalize(field).includes(keyword));
    });
});

const totalPages = computed(() => Math.max(Math.ceil(filteredApplicants.value.length / pageSize.value), 1));
const paginatedApplicants = computed(() => {
    const start = (currentPage.value - 1) * pageSize.value;
    return filteredApplicants.value.slice(start, start + pageSize.value);
});

const visibleSelectableIds = computed(() => paginatedApplicants.value.filter((item) => !item.content_creator_id).map((item) => item.id));
const allVisibleSelected = computed(() => visibleSelectableIds.value.length > 0 && visibleSelectableIds.value.every((id) => selectedIds.value.includes(id)));
const someVisibleSelected = computed(() => visibleSelectableIds.value.some((id) => selectedIds.value.includes(id)));
const paginationLabel = computed(() => {
    if (!filteredApplicants.value.length) {
        return '0 data';
    }

    const start = (currentPage.value - 1) * pageSize.value + 1;
    const end = Math.min(start + pageSize.value - 1, filteredApplicants.value.length);
    return `${start}-${end} dari ${filteredApplicants.value.length} data`;
});

watch([searchQuery, pageSize], () => {
    currentPage.value = 1;
});

watch(totalPages, (value) => {
    if (currentPage.value > value) {
        currentPage.value = value;
    }
});

watch(() => props.applicants, () => {
    selectedIds.value = selectedIds.value.filter((id) => props.applicants.some((item) => item.id === id && !item.content_creator_id));
});

const toggleSelection = (id) => {
    if (selectedIds.value.includes(id)) {
        selectedIds.value = selectedIds.value.filter((item) => item !== id);
        return;
    }

    selectedIds.value = [...selectedIds.value, id];
};

const toggleSelectAll = () => {
    if (allVisibleSelected.value) {
        selectedIds.value = selectedIds.value.filter((id) => !visibleSelectableIds.value.includes(id));
        return;
    }

    selectedIds.value = Array.from(new Set([...selectedIds.value, ...visibleSelectableIds.value]));
};

const submitConnect = (ids, options = {}) => {
    router.post(adminUrl('/applicants/connect-content-creators'), {
        application_ids: ids,
    }, {
        preserveScroll: true,
        onFinish: () => {
            bulkProcessing.value = false;
            singleProcessingId.value = null;
        },
        onSuccess: () => {
            selectedIds.value = selectedIds.value.filter((id) => !ids.includes(id));
            options.onSuccess?.();
        },
    });
};

const connectSelected = () => {
    if (!selectedIds.value.length) {
        return;
    }

    bulkProcessing.value = true;
    submitConnect(selectedIds.value);
};

const connectSingle = (id) => {
    singleProcessingId.value = id;
    submitConnect([id]);
};

const statusClass = (item) => {
    if (item.content_creator_id) {
        return 'badge-success';
    }

    return item.status === 'submitted' ? 'badge-warning' : 'badge-secondary';
};

const statusLabel = (item) => {
    if (item.content_creator_id) {
        return 'Terhubung ke Content Creator';
    }

    return item.status === 'submitted' ? 'Submitted' : item.status;
};
</script>

<style scoped>
.applicant-search {
    width: 320px;
}

.applicant-page-size {
    width: 88px;
}

.applicant-detail-cell {
    min-width: 260px;
}

.applicant-detail-cell summary {
    cursor: pointer;
    user-select: none;
}
</style>

