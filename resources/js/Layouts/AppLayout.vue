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
                            <h1 class="mb-0">{{ title }}</h1>
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

                    <slot />
                </div>
            </div>
        </main>
    </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import { Link, usePage } from '@inertiajs/vue3';

defineProps({
    title: { type: String, default: 'Dashboard' },
});

const page = usePage();
const logoUrl = '/img/logo.png';
const user = computed(() => page.props.auth?.user ?? null);
const navigation = computed(() => page.props.navigation ?? []);
const currentUrl = computed(() => page.url ?? '');
const flashSuccess = computed(() => page.props.flash?.success ?? null);

const showFlashSuccess = ref(true);
let locationInterval = null;

watch(() => page.url, () => {
    showFlashSuccess.value = true;
});

const isActive = (path) => currentUrl.value.startsWith(path);

const sendMarketingLocation = (source = 'heartbeat') => {
    if (user.value?.role !== 'marketing' || !navigator.geolocation) return;

    navigator.geolocation.getCurrentPosition((position) => {
        window.axios.post('/marketing/location', {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            source,
        }).catch(() => {});
    }, () => {}, { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 });
};

onMounted(() => {
    // Ensure AdminLTE is properly initialized for this layout
    // This will be called AFTER Vue renders the sidebar
    setTimeout(() => {
        if (window.adminlte) {
            
            // Get sidebar and toggle button
            const sidebar = document.querySelector('.app-sidebar');
            const toggleButton = document.querySelector('[data-widget="pushmenu"]');
            
            if (sidebar && window.adminlte.PushMenu) {
                // Create PushMenu instance
                const pushMenu = new window.adminlte.PushMenu(sidebar);
                
                // If button exists and PushMenu has a toggle method, ensure event listeners work
                if (toggleButton && typeof pushMenu.toggle === 'function') {
                    // Add explicit click handler as fallback for Vue-rendered elements
                    toggleButton.addEventListener('click', (e) => {
                        e.preventDefault();
                        pushMenu.toggle();
                               });
                        }
            }
            
            // Initialize treeviews
            const treeviews = document.querySelectorAll('[data-widget="treeview"]');
            if (window.adminlte.Treeview && treeviews.length > 0) {
                treeviews.forEach(el => {
                    try {
                        new window.adminlte.Treeview(el);
                    } catch (e) {
                        console.warn('⚠️ Treeview error:', e.message);
                    }
                });
                        }
        } else {
            console.error('❌ AppLayout: window.adminlte not available!');
        }
    }, 50);
    
    if (user.value?.role === 'marketing') {
        sendMarketingLocation();
        locationInterval = window.setInterval(() => sendMarketingLocation(), 3600000);
    }
});

onBeforeUnmount(() => {
    if (locationInterval) window.clearInterval(locationInterval);
});
</script>
