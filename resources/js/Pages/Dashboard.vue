<template>
    <Head title="Dashboard" />

    <div class="row">
        <div v-for="item in summaryCards" :key="item.label" class="col-lg-3 col-6">
            <div class="small-box" :class="item.color">
                <div class="inner"><h3>{{ item.value }}</h3><p>{{ item.label }}</p></div>
                <div class="icon"><i :class="item.icon"></i></div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-lg-7">
            <div class="card card-outline card-primary">
                <div class="card-header"><h3 class="card-title">Fokus Role</h3></div>
                <div class="card-body">
                    <div v-for="item in roleHighlights" :key="item.title" class="mb-3">
                        <h5 class="mb-1">{{ item.title }}</h5>
                        <p class="text-muted mb-0">{{ item.description }}</p>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-lg-5">
            <div class="card card-outline card-success">
                <div class="card-header"><h3 class="card-title">Aksi Cepat</h3></div>
                <div class="card-body d-flex flex-wrap gap-2">
                    <Link v-for="action in quickActions" :key="action.href" :href="action.href" class="btn btn-outline-primary mr-2 mb-2">{{ action.label }}</Link>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-lg-6">
            <Deferred data="roleStats">
                <template #fallback><div class="card"><div class="card-body">Memuat statistik role...</div></div></template>
                <div class="card card-outline card-info">
                    <div class="card-header"><h3 class="card-title">Statistik Role</h3></div>
                    <div class="card-body p-0">
                        <table class="table table-striped mb-0">
                            <thead><tr><th>Role</th><th>Total</th></tr></thead>
                            <tbody><tr v-for="item in roleStats" :key="item.role"><td>{{ item.role }}</td><td>{{ item.total }}</td></tr></tbody>
                        </table>
                    </div>
                </div>
            </Deferred>
        </div>
        <div class="col-lg-6">
            <Deferred data="inventorySummary">
                <template #fallback><div class="card"><div class="card-body">Memuat inventory...</div></div></template>
                <div class="card card-outline card-warning">
                    <div class="card-header"><h3 class="card-title">Ringkasan Inventory</h3></div>
                    <div class="card-body">
                        <p class="mb-1"><strong>Total Product:</strong> {{ inventorySummary.products }}</p>
                        <p class="mb-1"><strong>Raw Material:</strong> {{ inventorySummary.rawMaterials ?? 0 }}</p>
                        <p class="mb-1"><strong>Promo Aktif:</strong> {{ inventorySummary.promos }}</p>
                        <p class="mb-1"><strong>Pending Return:</strong> {{ inventorySummary.pendingReturns }}</p>
                        <p class="mb-0"><strong>Pending Sales:</strong> {{ inventorySummary.pendingSales }}</p>
                    </div>
                </div>
            </Deferred>
        </div>
    </div>

    <WhenVisible data="recentUsers" :buffer="250">
        <template #fallback><div class="card"><div class="card-body">Memuat user terbaru...</div></div></template>
        <template #default="{ fetching }">
            <div class="card card-outline card-secondary">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h3 class="card-title">User Terbaru</h3>
                    <span v-if="fetching" class="badge badge-info">Refreshing</span>
                </div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0">
                        <thead><tr><th>Nama</th><th>Role</th><th>Status</th><th>Dibuat</th></tr></thead>
                        <tbody><tr v-for="item in recentUsers" :key="item.id_user"><td>{{ item.nama }}</td><td>{{ item.role }}</td><td>{{ item.status }}</td><td>{{ item.created_at }}</td></tr></tbody>
                    </table>
                </div>
            </div>
        </template>
    </WhenVisible>
</template>

<script setup>
import { computed } from 'vue';
import { Deferred, Head, Link, WhenVisible } from '@inertiajs/vue3';
import AppLayout from '../Layouts/AppLayout.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    summary: Object,
    quickActions: Array,
    roleHighlights: Array,
    roleStats: { type: Array, default: undefined },
    recentUsers: { type: Array, default: undefined },
    inventorySummary: { type: Object, default: undefined },
});

const summaryCards = computed(() => [
    { label: 'Total User', value: props.summary.totalUsers, color: 'bg-info', icon: 'fas fa-users' },
    { label: 'User Aktif', value: props.summary.activeUsers, color: 'bg-success', icon: 'fas fa-user-check' },
    { label: 'User Nonaktif', value: props.summary.inactiveUsers, color: 'bg-warning', icon: 'fas fa-user-times' },
    { label: 'Role Anda', value: props.summary.currentRole, color: 'bg-primary', icon: 'fas fa-id-badge' },
]);
</script>
