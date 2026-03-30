<template>
    <div class="app-wrapper">
        <nav class="app-header navbar navbar-expand bg-body border-bottom shadow-sm">
            <div class="container-fluid">
                <ul class="navbar-nav">
                    <li class="nav-item">
                        <a
                            ref="sidebarToggleElement"
                            href="#"
                            class="nav-link"
                            data-lte-toggle="sidebar"
                            role="button"
                        >
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

        <aside ref="sidebarElement" class="app-sidebar bg-body-secondary shadow" data-bs-theme="dark">
            <div class="sidebar-brand">
                <Link href="/dashboard" class="brand-link text-decoration-none">
                    <img :src="logoUrl" alt="Primatama" class="brand-image opacity-75 shadow-sm bg-white p-1 rounded-circle">
                    <span class="brand-text fw-light">Avenor Perfume</span>
                </Link>
            </div>

            <div class="sidebar-wrapper">
                <nav class="mt-2">
                    <ul
                        ref="treeviewElement"
                        class="nav sidebar-menu flex-column"
                        data-lte-toggle="treeview"
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
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue';
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
const sidebarElement = ref(null);
const sidebarToggleElement = ref(null);
const treeviewElement = ref(null);
let locationInterval = null;
let pushMenuInstance = null;
let toggleHandler = null;
let treeviewHandler = null;
let navLinkHandler = null;

const closeMobileSidebar = () => {
    if (window.innerWidth < 992) {
        document.body.classList.remove('sidebar-open');
    }
};

watch(() => page.url, () => {
    showFlashSuccess.value = true;
    closeMobileSidebar();

    nextTick(() => {
        initAdminLteWidgets();
    });
});

const isActive = (path) => currentUrl.value.startsWith(path);

const destroyAdminLteWidgets = () => {
    if (sidebarToggleElement.value && toggleHandler) {
        sidebarToggleElement.value.removeEventListener('click', toggleHandler);
    }

    if (treeviewElement.value && treeviewHandler) {
        treeviewElement.value.removeEventListener('click', treeviewHandler);
    }

    if (sidebarElement.value && navLinkHandler) {
        sidebarElement.value.removeEventListener('click', navLinkHandler);
    }

    toggleHandler = null;
    treeviewHandler = null;
    navLinkHandler = null;
    pushMenuInstance = null;
};

const initAdminLteWidgets = () => {
    destroyAdminLteWidgets();

    if (!window.adminlte || !sidebarElement.value) {
        return;
    }

    if (window.adminlte.PushMenu) {
        pushMenuInstance = new window.adminlte.PushMenu(sidebarElement.value);
        if (typeof pushMenuInstance.init === 'function') {
            pushMenuInstance.init();
        }
    }

    if (sidebarToggleElement.value && pushMenuInstance && typeof pushMenuInstance.toggle === 'function') {
        toggleHandler = (event) => {
            event.preventDefault();
            pushMenuInstance.toggle();
        };

        sidebarToggleElement.value.addEventListener('click', toggleHandler);
    }

    if (treeviewElement.value && window.adminlte.Treeview) {
        treeviewHandler = (event) => {
            const toggleTarget = event.target.closest('.nav-link');
            const targetItem = toggleTarget?.closest('.nav-item');
            const targetTreeviewMenu = targetItem?.querySelector('.nav-treeview');

            if (!targetItem || !targetTreeviewMenu) {
                return;
            }

            if (toggleTarget.getAttribute('href') === '#') {
                event.preventDefault();
            }

            new window.adminlte.Treeview(targetItem, {
                accordion: treeviewElement.value?.dataset.accordion !== 'false',
            }).toggle();
        };

        treeviewElement.value.addEventListener('click', treeviewHandler);
    }

    if (sidebarElement.value) {
        navLinkHandler = (event) => {
            const link = event.target.closest('.nav-link');
            const targetItem = link?.closest('.nav-item');
            const hasTreeviewMenu = targetItem?.querySelector('.nav-treeview');

            if (!link || hasTreeviewMenu) {
                return;
            }

            closeMobileSidebar();
        };

        sidebarElement.value.addEventListener('click', navLinkHandler);
    }
};

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
    closeMobileSidebar();

    nextTick(() => {
        initAdminLteWidgets();
    });

    if (user.value?.role === 'marketing') {
        sendMarketingLocation();
        locationInterval = window.setInterval(() => sendMarketingLocation(), 3600000);
    }
});

onBeforeUnmount(() => {
    if (locationInterval) window.clearInterval(locationInterval);
    destroyAdminLteWidgets();
});
</script>
