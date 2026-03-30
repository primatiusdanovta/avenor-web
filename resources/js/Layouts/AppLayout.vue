<template>
    <div class="app-wrapper">
        <nav class="app-header navbar navbar-expand bg-body border-bottom shadow-sm">
            <div class="container-fluid">
                <ul class="navbar-nav">
                    <li class="nav-item">
                        <a href="#" class="nav-link" data-widget="pushmenu" @click.prevent>
                            <i class="fas fa-bars"></i>
                        </a>
                    </li>
                </ul>

                <ul class="navbar-nav ms-auto align-items-center gap-2">
                    <li class="nav-item d-none d-md-block text-muted small">
                        {{ user?.nama }} | {{ user?.role }}
                    </li>
                    <li class="nav-item">
                        <Link href="/logout" method="post" as="button" class="btn btn-outline-danger btn-sm">Logout</Link>
                    </li>
                </ul>
            </div>
        </nav>

        <aside class="app-sidebar bg-body-secondary shadow" data-bs-theme="dark">
            <div class="sidebar-brand">
                <Link href="/dashboard" class="brand-link text-decoration-none">
                    <img :src="logoUrl" alt="Primatama" class="brand-image opacity-75 shadow-sm bg-white p-1 rounded-circle">
                    <span class="brand-text fw-light">Avenor Perfume</span>
                </Link>
            </div>

            <div class="sidebar-wrapper">
                <nav class="mt-2">
                    <ul
                        class="nav sidebar-menu flex-column"
                        data-widget="treeview"
                        role="navigation"
                        aria-label="Main navigation"
                        data-accordion="false"
                    >
                        <li v-for="item in navigation" :key="item.href" class="nav-item">
                            <Link :href="item.href" class="nav-link" :class="{ active: isActive(item.href) }">
                                <i class="nav-icon" :class="item.icon"></i>
                                <p>{{ item.label }}</p>
                            </Link>
                        </li>
                    </ul>
                </nav>
            </div>
        </aside>

        <main class="app-main">
            <div class="app-content-header">
                <div class="container-fluid">
                    <div class="row mb-2 align-items-center">
                        <div class="col-sm-6">
                            <h1 class="mb-0">{{ headerTitle }}</h1>
                        </div>
                        <div class="col-sm-6 text-end">
                            <slot name="actions" />
                        </div>
                    </div>
                </div>
            </div>

            <div class="app-content pb-4">
                <div class="container-fluid">
                    <div v-if="showFlashSuccess && flashSuccess" class="alert alert-success alert-dismissible fade show" role="alert">
                        {{ flashSuccess }}
                        <button type="button" class="btn-close" aria-label="Close" @click="showFlashSuccess = false"></button>
                    </div>

                    <div v-if="showFlashWarning && flashWarning" class="alert alert-warning alert-dismissible fade show" role="alert">
                        {{ flashWarning }}
                        <button type="button" class="btn-close" aria-label="Close" @click="showFlashWarning = false"></button>
                    </div>

                    <div v-if="showFlashError && flashError" class="alert alert-danger alert-dismissible fade show" role="alert">
                        {{ flashError }}
                        <button type="button" class="btn-close" aria-label="Close" @click="showFlashError = false"></button>
                    </div>

                    <slot />
                </div>
            </div>
        </main>
    </div>

    <BootstrapModal
        :show="showLocationWarning"
        title="Peringatan Sinkronisasi Lokasi"
        header-variant="warning"
        size="mobile-full"
        @close="showLocationWarning = false"
    >
        {{ locationWarning }}
        <template #footer>
            <button type="button" class="btn btn-warning" @click="showLocationWarning = false">Tutup</button>
        </template>
    </BootstrapModal>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import { Link, usePage } from '@inertiajs/vue3';
import BootstrapModal from '../Components/BootstrapModal.vue';

const props = defineProps({
    title: { type: String, default: '' },
});

const page = usePage();
const logoUrl = '/img/logo.png';
const user = computed(() => page.props.auth?.user ?? null);
const navigation = computed(() => page.props.navigation ?? []);
const currentUrl = computed(() => page.url ?? '');
const flashSuccess = computed(() => page.props.flash?.success ?? null);
const flashWarning = computed(() => page.props.flash?.warning ?? null);
const flashError = computed(() => page.props.flash?.error ?? null);
const pageComponent = computed(() => page.component ?? '');

const pageTitleMap = {
    Dashboard: 'Dashboard',
    'Users/Manage': 'Kelola User',
    'ContentCreators/Index': 'Content Creator',
    'SalesTargets/Index': 'Target Penjualan',
    'Hpp/Index': 'HPP Product',
    'Products/Onhand': 'Product On Hand',
    'Products/Manage': 'Kelola Product',
    'Products/Knowledge': 'Product Knowledge',
    'RawMaterials/Index': 'Raw Material',
    'Sales/Index': 'Penjualan Offline',
    'OnlineSales/Index': 'Penjualan Online',
    'Customers/Index': 'Pelanggan',
    'Reports/Index': 'Report',
    'Promos/Index': 'Promo',
    'Marketing/Index': 'Monitoring Marketing',
    'Marketing/Attendance': 'Absensi Marketing',
    'Approvals/Index': 'Approval',
};

const fallbackTitleFromComponent = (component) => {
    if (!component) {
        return 'Dashboard';
    }

    const raw = component.split('/').pop() ?? component;
    return raw.replace(/([a-z])([A-Z])/g, '$1 $2');
};

const headerTitle = computed(() => {
    const explicitTitle = props.title?.trim();
    if (explicitTitle) {
        return explicitTitle;
    }

    return pageTitleMap[pageComponent.value] ?? fallbackTitleFromComponent(pageComponent.value);
});

const showFlashSuccess = ref(true);
const showFlashWarning = ref(true);
const showFlashError = ref(true);
const locationWarning = ref('');
const showLocationWarning = ref(false);
const lastLocationWarning = ref('');
let locationInterval = null;
let sidebarToggleButton = null;
let sidebarToggleHandler = null;

watch(() => page.url, () => {
    showFlashSuccess.value = true;
    showFlashWarning.value = true;
    showFlashError.value = true;
});

const isActive = (path) => currentUrl.value.startsWith(path);

const openLocationWarning = (message) => {
    if (!message || lastLocationWarning.value === message) {
        return;
    }

    locationWarning.value = message;
    showLocationWarning.value = true;
    lastLocationWarning.value = message;
};

const sendMarketingLocation = (source = 'heartbeat') => {
    if (user.value?.role !== 'marketing' || !navigator.geolocation) return;

    navigator.geolocation.getCurrentPosition((position) => {
        window.axios.post('/marketing/location', {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            source,
        }).catch(() => {
            openLocationWarning('Lokasi gagal disinkronkan ke server. Pastikan koneksi stabil lalu muat ulang halaman.');
        });
    }, () => {
        openLocationWarning('Sinkronisasi lokasi membutuhkan izin GPS aktif. Aktifkan izin lokasi lalu coba lagi.');
    }, { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 });
};

onMounted(() => {
    setTimeout(() => {
        if (window.adminlte) {
            const sidebar = document.querySelector('.app-sidebar');
            const toggleButton = document.querySelector('[data-widget="pushmenu"]');

            if (sidebar && window.adminlte.PushMenu) {
                const pushMenu = new window.adminlte.PushMenu(sidebar);

                if (toggleButton && typeof pushMenu.toggle === 'function') {
                    sidebarToggleButton = toggleButton;
                    sidebarToggleHandler = (event) => {
                        event.preventDefault();
                        pushMenu.toggle();
                    };

                    toggleButton.addEventListener('click', sidebarToggleHandler);
                }
            }

            const treeviews = document.querySelectorAll('[data-widget="treeview"]');
            if (window.adminlte.Treeview && treeviews.length > 0) {
                treeviews.forEach((element) => {
                    try {
                        new window.adminlte.Treeview(element);
                    } catch (error) {
                        console.warn('Treeview error:', error.message);
                    }
                });
            }
        } else {
            console.error('AppLayout: window.adminlte not available.');
        }
    }, 50);

    if (user.value?.role === 'marketing') {
        sendMarketingLocation();
        locationInterval = window.setInterval(() => sendMarketingLocation(), 3600000);
    }
});

onBeforeUnmount(() => {
    if (locationInterval) window.clearInterval(locationInterval);

    if (sidebarToggleButton && sidebarToggleHandler) {
        sidebarToggleButton.removeEventListener('click', sidebarToggleHandler);
    }
});
</script>
