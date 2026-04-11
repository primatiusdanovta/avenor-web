<template>
    <AppLayout title="Antrian">
        <Head title="Antrian" />

        <div class="d-flex justify-content-between align-items-center mb-3">
            <div class="text-muted small">Refresh otomatis tiap 10 detik. Status: {{ autoRefreshLabel }}</div>
            <button type="button" class="btn btn-outline-primary btn-sm" @click="refreshBoard">Refresh</button>
        </div>

        <div v-if="lastClosedSale" class="alert alert-info border">
            <div class="fw-semibold">Transaksi terakhir yang selesai</div>
            <div class="small text-muted">{{ lastClosedSale.sale_number || '-' }} | {{ lastClosedSale.transaction_code || '-' }}</div>
            <div class="small text-muted">Closed pada {{ lastClosedSale.closed_at || '-' }}</div>
        </div>

        <div class="queue-board">
            <div v-for="item in sortedItems" :key="item.sale_number" class="queue-card card card-outline card-success">
                <div class="card-body text-center">
                    <div class="text-muted small">No Urut</div>
                    <div class="queue-number">{{ item.queue_number }}</div>
                    <div class="small font-weight-bold">{{ item.sale_number }}</div>
                    <div class="small text-muted">{{ item.transaction_code || '-' }}</div>
                    <div class="small text-muted mt-2">{{ item.created_at }}</div>
                    <div class="small mt-2">Status: {{ item.payment_status }}</div>
                    <div v-if="item.details?.length" class="queue-details text-left mt-3">
                        <div v-for="(detail, index) in item.details" :key="`${item.sale_number}-${index}`" class="queue-detail-line">
                            {{ detail.nama_product }} - {{ detail.quantity }}
                            <span v-if="detail.extra_toppings?.length"> - {{ detail.extra_toppings.join(', ') }}</span>
                        </div>
                    </div>
                    <button
                        v-if="canClose"
                        type="button"
                        class="btn btn-sm btn-danger mt-3"
                        :disabled="closingSaleNumber === item.sale_number"
                        @click="closeItem(item)"
                    >
                        {{ closingSaleNumber === item.sale_number ? 'Closing...' : 'Close' }}
                    </button>
                </div>
            </div>
            <div v-if="!sortedItems.length" class="alert alert-light border text-muted mb-0">Belum ada antrian aktif.</div>
        </div>
    </AppLayout>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { Head, router } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import { adminUrl } from '../../utils/admin';
const props = defineProps({ items: Array, canClose: Boolean, lastClosedSale: Object });
const sortedItems = computed(() => [...(props.items || [])].sort((a, b) => Number(a.queue_number || 0) - Number(b.queue_number || 0)));
const closingSaleNumber = ref('');
const autoRefreshLabel = ref('aktif');
let refreshTimer = null;

const stopRefreshTimer = () => {
    if (refreshTimer) {
        window.clearInterval(refreshTimer);
        refreshTimer = null;
    }
};

const startRefreshTimer = () => {
    stopRefreshTimer();
    refreshTimer = window.setInterval(() => refreshBoard(), 10000);
};

const shouldPauseRefresh = () => document.visibilityState !== 'visible' || Boolean(closingSaleNumber.value);
const syncRefreshLabel = () => {
    autoRefreshLabel.value = shouldPauseRefresh() ? 'jeda' : 'aktif';
};

const refreshBoard = () => {
    if (shouldPauseRefresh()) {
        syncRefreshLabel();
        return;
    }

    syncRefreshLabel();
    router.get(adminUrl('/queue-board'), {}, { preserveScroll: true, preserveState: true, replace: true });
};

const closeItem = (item) => {
    if (!item?.sale_number || closingSaleNumber.value) {
        return;
    }

    closingSaleNumber.value = item.sale_number;
    syncRefreshLabel();
    stopRefreshTimer();
    router.post(adminUrl('/queue-board/close'), { sale_number: item.sale_number }, {
        preserveScroll: true,
        preserveState: false,
        replace: true,
        onFinish: () => {
            closingSaleNumber.value = '';
            syncRefreshLabel();
            startRefreshTimer();
        },
    });
};

onMounted(() => {
    syncRefreshLabel();
    startRefreshTimer();
    document.addEventListener('visibilitychange', syncRefreshLabel);
});

onBeforeUnmount(() => {
    stopRefreshTimer();
    document.removeEventListener('visibilitychange', syncRefreshLabel);
});
</script>

<style scoped>
.queue-board {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 1rem;
}

.queue-card {
    min-height: 240px;
}

.queue-number {
    font-size: 4rem;
    font-weight: 800;
    line-height: 1;
    margin: 0.75rem 0;
}

.queue-details {
    border-top: 1px dashed #d9e3de;
    padding-top: 0.75rem;
    font-size: 0.82rem;
}

.queue-detail-line + .queue-detail-line {
    margin-top: 0.35rem;
}
</style>
