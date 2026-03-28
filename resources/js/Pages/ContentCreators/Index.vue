<template>
    <Head title="Content Creator" />

    <div v-if="hasErrors" class="alert alert-danger">
        <div v-for="(message, key) in page.props.errors" :key="key">{{ message }}</div>
    </div>

    <div class="row">
        <div class="col-lg-5">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Input Content Creator</h3></div>
                <div class="card-body">
                    <div class="form-group"><label>Nama</label><input v-model="createForm.nama" type="text" class="form-control"></div>
                    <div class="form-group">
                        <label>Bidang</label>
                        <div class="border rounded p-2 bg-light bidang-box">
                            <div v-for="option in bidangOptions" :key="`create-${option}`" class="custom-control custom-checkbox">
                                <input :id="`create-${slugify(option)}`" :checked="createForm.bidang.includes(option)" type="checkbox" class="custom-control-input" @change="toggleBidang(createForm, option)">
                                <label class="custom-control-label" :for="`create-${slugify(option)}`">{{ option }}</label>
                            </div>
                        </div>
                    </div>
                    <div class="form-group"><label>Username Instagram</label><input v-model="createForm.username_instagram" type="text" class="form-control"></div>
                    <div class="form-group"><label>Username TikTok</label><input v-model="createForm.username_tiktok" type="text" class="form-control"></div>
                    <div class="form-row">
                        <div class="form-group col-md-6"><label>Followers Instagram</label><input v-model="createForm.followers_instagram" type="number" min="0" class="form-control"></div>
                        <div class="form-group col-md-6"><label>Followers TikTok</label><input v-model="createForm.followers_tiktok" type="number" min="0" class="form-control"></div>
                    </div>
                    <div class="form-group"><label>Range Fee per Content</label><input v-model="createForm.range_fee_percontent" type="text" class="form-control"></div>
                    <div class="form-group"><label>Jenis Konten</label><input v-model="createForm.jenis_konten" type="text" class="form-control"></div>
                    <div class="form-group"><label>No Telp</label><input v-model="createForm.no_telp" type="text" class="form-control"></div>
                    <div class="form-group"><label>Wilayah</label><input v-model="createForm.wilayah" type="text" class="form-control"></div>
                    <button class="btn btn-primary" style="margin-top: 10px;" :disabled="createForm.processing" @click="submitCreate">Simpan Content Creator</button>
                </div>
            </div>

            <div v-if="editForm.id_contentcreator" class="card card-outline card-warning">
                <div class="card-header"><h3 class="card-title">Edit Content Creator</h3></div>
                <div class="card-body">
                    <div class="form-group"><label>Nama</label><input v-model="editForm.nama" type="text" class="form-control"></div>
                    <div class="form-group">
                        <label>Bidang</label>
                        <div class="border rounded p-2 bg-light bidang-box">
                            <div v-for="option in bidangOptions" :key="`edit-${option}`" class="custom-control custom-checkbox">
                                <input :id="`edit-${slugify(option)}`" :checked="editForm.bidang.includes(option)" type="checkbox" class="custom-control-input" @change="toggleBidang(editForm, option)">
                                <label class="custom-control-label" :for="`edit-${slugify(option)}`">{{ option }}</label>
                            </div>
                        </div>
                    </div>
                    <div class="form-group"><label>Username Instagram</label><input v-model="editForm.username_instagram" type="text" class="form-control"></div>
                    <div class="form-group"><label>Username TikTok</label><input v-model="editForm.username_tiktok" type="text" class="form-control"></div>
                    <div class="form-row">
                        <div class="form-group col-md-6"><label>Followers Instagram</label><input v-model="editForm.followers_instagram" type="number" min="0" class="form-control"></div>
                        <div class="form-group col-md-6"><label>Followers TikTok</label><input v-model="editForm.followers_tiktok" type="number" min="0" class="form-control"></div>
                    </div>
                    <div class="form-group"><label>Range Fee per Content</label><input v-model="editForm.range_fee_percontent" type="text" class="form-control"></div>
                    <div class="form-group"><label>Jenis Konten</label><input v-model="editForm.jenis_konten" type="text" class="form-control"></div>
                    <div class="form-group"><label>No Telp</label><input v-model="editForm.no_telp" type="text" class="form-control"></div>
                    <div class="form-group"><label>Wilayah</label><input v-model="editForm.wilayah" type="text" class="form-control"></div>
                    <button class="btn btn-warning mr-2" :disabled="editForm.processing" @click="submitEdit">Update</button>
                    <button class="btn btn-secondary" @click="resetEdit">Batal</button>
                </div>
            </div>
        </div>

        <div class="col-lg-7">
            <div class="card card-outline card-success">
                <div class="card-header"><h3 class="card-title">Daftar Content Creator</h3></div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Nama</th><th>Bidang</th><th>Instagram</th><th>TikTok</th><th>Followers</th><th>Fee</th><th>No Telp</th><th>Wilayah</th><th>Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="item in contentCreators" :key="item.id_contentcreator">
                                <td>{{ item.nama }}</td>
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
                                    <button class="btn btn-xs btn-warning mr-1" @click="pickEdit(item)">Edit</button>
                                    <button class="btn btn-xs btn-outline-danger" @click="removeCreator(item)">Hapus</button>
                                </td>
                            </tr>
                            <tr v-if="!contentCreators.length"><td colspan="9" class="text-center text-muted">Belum ada data content creator.</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue';
import { Head, router, useForm, usePage } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';

defineOptions({ layout: AppLayout });

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

const toggleBidang = (form, option) => {
    if (form.bidang.includes(option)) {
        form.bidang = form.bidang.filter((item) => item !== option);
        return;
    }

    form.bidang = [...form.bidang, option];
};

const pickEdit = (item) => Object.assign(editForm, {
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

const resetCreate = () => Object.assign(createForm, { ...createDefaults });
const resetEdit = () => Object.assign(editForm, { ...editDefaults });
const submitCreate = () => createForm.post('/content-creators', { preserveScroll: true, onSuccess: resetCreate });
const submitEdit = () => editForm.put(`/content-creators/${editForm.id_contentcreator}`, { preserveScroll: true, onSuccess: resetEdit });
const removeCreator = (item) => {
    if (window.confirm(`Hapus content creator ${item.nama}?`)) {
        router.delete(`/content-creators/${item.id_contentcreator}`, { preserveScroll: true });
    }
};

const formatNumber = (value) => new Intl.NumberFormat('id-ID').format(Number(value || 0));
const slugify = (value) => String(value).toLowerCase().replace(/\s+/g, '-');
</script>

<style scoped>
.bidang-box {
    max-height: 220px;
    overflow-y: auto;
}
</style>

