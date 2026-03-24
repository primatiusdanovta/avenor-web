<template>
    <Head title="Dashboard" />

    <div class="stack">
        <section class="hero-card">
            <div>
                <p class="hero-kicker">Ringkasan</p>
                <h3>Halo, {{ authUser?.nama }}</h3>
                <p class="hero-text">Dashboard utama menyesuaikan modul yang tersedia berdasarkan role login aktif.</p>
            </div>
            <div class="filter-actions">
                <Link v-for="action in quickActions" :key="action.href" :href="action.href" class="secondary-button">
                    {{ action.label }}
                </Link>
            </div>
        </section>

        <section class="stats-grid">
            <article class="stat-card">
                <span>Total User</span>
                <strong>{{ summary.totalUsers }}</strong>
            </article>
            <article class="stat-card">
                <span>User Aktif</span>
                <strong>{{ summary.activeUsers }}</strong>
            </article>
            <article class="stat-card">
                <span>User Nonaktif</span>
                <strong>{{ summary.inactiveUsers }}</strong>
            </article>
            <article class="stat-card">
                <span>Role Anda</span>
                <strong>{{ summary.currentRole }}</strong>
            </article>
        </section>

        <section class="panel-grid">
            <div class="panel-card">
                <div class="panel-head">
                    <h3>Role Focus</h3>
                    <p>Prioritas kerja sesuai jenis akun yang sedang login.</p>
                </div>
                <div class="role-list">
                    <div v-for="item in roleHighlights" :key="item.title" class="role-item role-item-block">
                        <div>
                            <strong>{{ item.title }}</strong>
                            <p class="inline-note">{{ item.description }}</p>
                        </div>
                    </div>
                </div>
            </div>

            <Deferred data="systemInfo">
                <template #fallback>
                    <div class="panel-card loading-card">Memuat info sistem...</div>
                </template>

                <div class="panel-card">
                    <div class="panel-head">
                        <h3>Deferred Props: System Info</h3>
                        <p>Konfigurasi inti dikirim terpisah dari payload awal.</p>
                    </div>
                    <ul class="meta-list">
                        <li><span>Database</span><strong>{{ systemInfo.database }}</strong></li>
                        <li><span>Session</span><strong>{{ systemInfo.sessionDriver }}</strong></li>
                        <li><span>Queue</span><strong>{{ systemInfo.queue }}</strong></li>
                        <li><span>Locale</span><strong>{{ systemInfo.locale }}</strong></li>
                    </ul>
                </div>
            </Deferred>
        </section>

        <section class="panel-grid">
            <Deferred data="roleStats">
                <template #fallback>
                    <div class="panel-card loading-card">Memuat statistik role...</div>
                </template>

                <div class="panel-card">
                    <div class="panel-head">
                        <h3>Deferred Props: Role Breakdown</h3>
                        <p>Data ini dimuat setelah render pertama.</p>
                    </div>
                    <div class="role-list">
                        <div v-for="item in roleStats" :key="item.role" class="role-item">
                            <span>{{ item.role }}</span>
                            <strong>{{ item.total }}</strong>
                        </div>
                    </div>
                </div>
            </Deferred>

            <div class="panel-card">
                <div class="panel-head">
                    <h3>Akses Saat Ini</h3>
                    <p>Halaman yang tersedia mengikuti role login aktif.</p>
                </div>
                <ul class="meta-list">
                    <li><span>User Management</span><strong>{{ canViewUsers ? 'Diizinkan' : 'Tidak diizinkan' }}</strong></li>
                    <li><span>Marketing KPI</span><strong>{{ canViewMarketingKpi ? 'Diizinkan' : 'Tidak diizinkan' }}</strong></li>
                    <li><span>Lazy Loading</span><strong>Aktif</strong></li>
                    <li><span>SPA Visit</span><strong>Aktif</strong></li>
                </ul>
            </div>
        </section>

        <Deferred v-if="marketingSnapshot" data="marketingSnapshot">
            <template #fallback>
                <div class="panel-card loading-card">Memuat snapshot marketing...</div>
            </template>

            <div class="panel-card">
                <div class="panel-head">
                    <h3>Marketing Snapshot</h3>
                    <p>Ringkasan cepat absensi untuk akun marketing.</p>
                </div>
                <ul class="meta-list">
                    <li><span>Total Absensi</span><strong>{{ marketingSnapshot.attendanceCount }}</strong></li>
                    <li><span>Total Terlambat</span><strong>{{ marketingSnapshot.lateCount }}</strong></li>
                </ul>
            </div>
        </Deferred>

        <WhenVisible data="recentUsers" :buffer="250">
            <template #fallback>
                <div class="panel-card loading-card">Scroll ke bawah memicu lazy loading recent users...</div>
            </template>

            <template #default="{ fetching }">
                <div class="panel-card">
                    <div class="panel-head">
                        <div>
                            <h3>WhenVisible: Recent Users</h3>
                            <p>Section ini diminta hanya saat area terlihat di viewport.</p>
                        </div>
                        <span v-if="fetching" class="badge">Refreshing...</span>
                    </div>

                    <div class="table-wrap">
                        <table>
                            <thead>
                                <tr>
                                    <th>Username</th>
                                    <th>Role</th>
                                    <th>Status</th>
                                    <th>Dibuat</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="user in recentUsers" :key="user.id_user">
                                    <td>{{ user.nama }}</td>
                                    <td>{{ user.role }}</td>
                                    <td>{{ user.status }}</td>
                                    <td>{{ user.created_at }}</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </template>
        </WhenVisible>
    </div>
</template>

<script setup>
import { computed } from 'vue';
import { Deferred, Head, Link, usePage, WhenVisible } from '@inertiajs/vue3';
import AppLayout from '../Layouts/AppLayout.vue';

defineOptions({ layout: AppLayout });

defineProps({
    summary: Object,
    quickActions: Array,
    roleHighlights: Array,
    canViewUsers: Boolean,
    canViewMarketingKpi: Boolean,
    roleStats: { type: Array, default: undefined },
    systemInfo: { type: Object, default: undefined },
    recentUsers: { type: Array, default: undefined },
    marketingSnapshot: { type: Object, default: undefined },
});

const page = usePage();
const authUser = computed(() => page.props.auth?.user ?? null);
</script>