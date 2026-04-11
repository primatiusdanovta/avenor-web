<template>
    <AppLayout title="SOP">
        <Head title="SOP" />

        <template #actions>
            <button v-if="canManage" type="button" class="btn btn-primary" @click="openCreate">Tambah SOP</button>
        </template>

        <div v-if="canManage" class="card card-outline card-warning mb-3">
            <div class="card-header">
                <h3 class="card-title mb-0">Template SOP Operasional</h3>
            </div>
            <div class="card-body">
                <p class="text-muted small mb-3">Gunakan template cepat untuk membuat SOP yang langsung actionable di flow Smoothies Sweetie.</p>
                <div class="d-flex flex-wrap gap-2">
                    <button type="button" class="btn btn-outline-dark btn-sm" @click="applyTemplate('pre_blend')">Pre-Blend</button>
                    <button type="button" class="btn btn-outline-dark btn-sm" @click="applyTemplate('final_check')">Final Check Topping</button>
                    <button type="button" class="btn btn-outline-dark btn-sm" @click="applyTemplate('handover')">Serah-Terima Customer</button>
                    <button type="button" class="btn btn-outline-dark btn-sm" @click="applyTemplate('close_shift')">Close Shift Kasir</button>
                </div>
            </div>
        </div>

        <div class="row">
            <div v-for="item in items" :key="item.id_sop" class="col-md-6 mb-3">
                <div class="card card-outline card-success h-100">
                    <div class="card-header d-flex justify-content-between align-items-center gap-2">
                        <h3 class="card-title mb-0">{{ item.title }}</h3>
                        <div v-if="canManage" class="d-flex gap-2">
                            <button type="button" class="btn btn-sm btn-warning" @click="openEdit(item)">Edit</button>
                            <button type="button" class="btn btn-sm btn-danger" @click="removeItem(item)">Hapus</button>
                        </div>
                    </div>
                    <div class="card-body sop-detail-content" v-html="renderRichText(item.detail)"></div>
                </div>
            </div>
            <div v-if="!items.length" class="col-12">
                <div class="alert alert-light border text-muted mb-0">Belum ada SOP.</div>
            </div>
        </div>

        <BootstrapModal :show="showModal" :title="form.id_sop ? 'Edit SOP' : 'Tambah SOP'" size="xl" @close="closeModal">
            <div class="crud-modal-body">
                <div class="form-group mb-0"><label>Judul</label><input v-model="form.title" type="text" class="form-control"></div>
                <div class="form-group mb-0">
                    <label>Detail</label>
                    <RichTextEditor v-model="form.detail" />
                </div>
            </div>
            <template #footer>
                <button type="button" class="btn btn-secondary" @click="closeModal">Batal</button>
                <button type="button" class="btn btn-primary" @click="submitForm">Simpan</button>
            </template>
        </BootstrapModal>
    </AppLayout>
</template>

<script setup>
import { Head, router, useForm } from '@inertiajs/vue3';
import { ref } from 'vue';
import AppLayout from '../../Layouts/AppLayout.vue';
import BootstrapModal from '../../Components/BootstrapModal.vue';
import RichTextEditor from '../../Components/RichTextEditor.vue';
import { adminUrl } from '../../utils/admin';

const props = defineProps({ items: Array, canManage: Boolean });
const showModal = ref(false);
const form = useForm({ id_sop: null, title: '', detail: '' });
const escapeHtml = (value) => String(value || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
const renderRichText = (value) => {
    if (!value) {
        return '<p class="text-muted mb-0">Belum ada detail SOP.</p>';
    }

    return /<\/?[a-z][\s\S]*>/i.test(value)
        ? value
        : escapeHtml(value).replace(/\n/g, '<br>');
};
const sopTemplates = {
    pre_blend: {
        title: 'Pre-Blend Station',
        detail: '1. Pastikan blender, gelas, dan area kerja bersih.\n2. Cek stok buah, susu, dan es untuk pesanan berikutnya.\n3. Cocokkan ukuran gelas dengan size yang dipilih customer.\n4. Mulai blending hanya setelah bahan dasar lengkap.',
    },
    final_check: {
        title: 'Final Check Topping',
        detail: '1. Cek kembali topping yang dipilih di pesanan.\n2. Pastikan urutan topping sesuai standar outlet.\n3. Lap sisi gelas sebelum minuman diberikan.\n4. Konfirmasi nama menu dan topping ke customer.',
    },
    handover: {
        title: 'Serah-Terima Customer',
        detail: '1. Sebutkan nama menu dan size saat memanggil customer.\n2. Konfirmasi metode pembayaran sudah selesai.\n3. Serahkan minuman dengan sedotan dan napkin.\n4. Ucapkan penutup pelayanan singkat sebelum transaksi dianggap selesai.',
    },
    close_shift: {
        title: 'Close Shift Kasir',
        detail: '1. Pastikan semua nomor antrian hari ini sudah berstatus closed.\n2. Cocokkan transaksi cash dan QRIS dengan rekap penjualan.\n3. Bersihkan station dan catat stok topping yang perlu refill.\n4. Dokumentasikan kendala operasional untuk shift berikutnya.',
    },
};

const openCreate = () => {
    form.reset();
    form.id_sop = null;
    showModal.value = true;
};
const applyTemplate = (key) => {
    const template = sopTemplates[key];
    if (!template) return;
    form.reset();
    form.id_sop = null;
    form.title = template.title;
    form.detail = template.detail;
    showModal.value = true;
};
const openEdit = (item) => {
    form.id_sop = item.id_sop;
    form.title = item.title;
    form.detail = item.detail;
    showModal.value = true;
};
const closeModal = () => {
    showModal.value = false;
    form.reset();
    form.id_sop = null;
};
const submitForm = () => {
    if (form.id_sop) {
        form.put(adminUrl(`/sops/${form.id_sop}`), { preserveScroll: true, onSuccess: closeModal });
        return;
    }

    form.post(adminUrl('/sops'), { preserveScroll: true, onSuccess: closeModal });
};
const removeItem = (item) => router.delete(adminUrl(`/sops/${item.id_sop}`), { preserveScroll: true });
</script>

<style scoped>
.crud-modal-body {
    display: grid;
    gap: 1rem;
}

.sop-detail-content :deep(p:last-child),
.sop-detail-content :deep(ul:last-child),
.sop-detail-content :deep(ol:last-child) {
    margin-bottom: 0;
}
</style>
