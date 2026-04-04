<template>
    <div class="app-wrapper">
        <nav class="app-header navbar navbar-expand bg-body border-bottom shadow-sm">
            <div class="container-fluid">
                <ul class="navbar-nav">
                    <li class="nav-item">
                        <a href="#" class="nav-link" role="button" @click.prevent="handleSidebarToggle">
                            <i class="fas fa-bars"></i>
                        </a>
                    </li>
                </ul>

                <ul class="navbar-nav ms-auto align-items-center gap-2">
                    <li class="nav-item d-none d-md-block text-muted small">
                        {{ user?.nama }} | {{ user?.role }}
                    </li>
                    <li class="nav-item">
                        <Link :href="adminUrl('/logout')" method="post" as="button" class="btn btn-outline-danger btn-sm">Logout</Link>
                    </li>
                </ul>
            </div>
        </nav>

        <aside class="app-sidebar bg-body-secondary shadow" data-bs-theme="dark">
            <div class="sidebar-brand">
                <Link :href="adminUrl('/dashboard')" class="brand-link text-decoration-none">
                    <img :src="logoUrl" alt="Primatama" class="brand-image opacity-75 shadow-sm bg-white p-1 rounded-circle">
                    <span class="brand-text fw-light">Avenor Perfume</span>
                </Link>
            </div>

            <div class="sidebar-wrapper">
                <nav class="mt-2">
                    <ul class="nav sidebar-menu flex-column" role="navigation" aria-label="Main navigation">
                        <li v-for="item in navigation" :key="item.label + (item.href || '')" class="nav-item" :class="{ 'menu-open': isMenuOpen(item.label) }">
                            <template v-if="item.children?.length">
                                <a href="#" class="nav-link" :class="{ active: isMenuOpen(item.label) }" @click.prevent="toggleMenu(item.label)">
                                    <i class="nav-icon" :class="item.icon"></i>
                                    <p>
                                        {{ item.label }}
                                        <i class="nav-arrow fas fa-angle-right"></i>
                                    </p>
                                </a>
                                <ul class="nav nav-treeview">
                                    <li v-for="child in item.children" :key="child.label + child.href" class="nav-item">
                                        <Link :href="child.href" class="nav-link" :class="{ active: isActive(child.href) }" @click="closeMobileSidebar">
                                            <i :class="child.icon"></i>
                                            <p>{{ child.label }}</p>
                                        </Link>
                                    </li>
                                </ul>
                            </template>
                            <Link v-else :href="item.href" class="nav-link" :class="{ active: isActive(item.href) }" @click="closeMobileSidebar">
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
                            <h1 class="mb-0">{{ pageHeading }}</h1>
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

                    <div v-if="flashWarning" class="alert alert-warning" role="alert">
                        {{ flashWarning }}
                    </div>

                    <div v-if="flashError" class="alert alert-danger" role="alert">
                        {{ flashError }}
                    </div>

                    <div v-if="validationErrors.length" class="alert alert-danger" role="alert">
                        <div class="fw-semibold mb-1">Mohon periksa kembali input Anda.</div>
                        <div v-for="message in validationErrors" :key="message">{{ message }}</div>
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
import { adminUrl } from '../utils/admin';

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
const validationErrors = computed(() => Object.values(page.props.errors ?? {}).filter(Boolean));
const pageHeading = ref(props.title || 'Dashboard');

const showFlashSuccess = ref(true);
const openMenus = ref({});
let locationInterval = null;

const isDesktop = () => window.innerWidth >= 992;
const normalizePath = (value) => {
    if (!value) return '';

    try {
        if (typeof window !== 'undefined') {
            const url = new URL(value, window.location.origin);
            return url.pathname.replace(/\/+$/, '') || '/';
        }
    } catch (_) {
        // Ignore URL parsing errors and fall back to string cleanup.
    }

    const normalized = String(value).split('?')[0].split('#')[0].trim();
    if (!normalized) return '';

    return normalized.replace(/\/+$/, '') || '/';
};

const isActive = (path) => {
    const currentPath = normalizePath(currentUrl.value);
    const targetPath = normalizePath(path);

    if (!currentPath || !targetPath) return false;
    if (currentPath === targetPath) return true;
    if (targetPath === '/') return currentPath === '/';

    return currentPath.startsWith(`${targetPath}/`);
};
const hasActiveChild = (item) => Array.isArray(item?.children) && item.children.some((child) => isActive(child.href));
const isMenuOpen = (label) => Boolean(openMenus.value[label]);

const findActiveNavigationLabel = (items) => {
    for (const item of items ?? []) {
        if (item?.children?.length) {
            const activeChild = item.children.find((child) => isActive(child.href));
            if (activeChild) {
                return activeChild.label;
            }
        }

        if (item?.href && isActive(item.href)) {
            return item.label;
        }
    }

    return '';
};

const syncOpenMenusWithRoute = () => {
    const nextState = {};
    for (const item of navigation.value) {
        if (item?.children?.length) {
            nextState[item.label] = hasActiveChild(item);
        }
    }
    openMenus.value = { ...openMenus.value, ...nextState };
};

const toggleMenu = (label) => {
    openMenus.value = {
        ...openMenus.value,
        [label]: !openMenus.value[label],
    };
};

const syncPageHeading = () => {
    if (props.title) {
        pageHeading.value = props.title;
        return;
    }

    const activeLabel = findActiveNavigationLabel(navigation.value);
    if (activeLabel) {
        pageHeading.value = activeLabel;
        return;
    }

    if (typeof document !== 'undefined') {
        const rawTitle = document.title.split('|')[0].trim();
        pageHeading.value = rawTitle || 'Dashboard';
        return;
    }

    pageHeading.value = 'Dashboard';
};

const closeMobileSidebar = () => {
    if (typeof document === 'undefined') return;
    document.body.classList.remove('sidebar-open');
};

const handleSidebarToggle = () => {
    if (typeof document === 'undefined') return;

    if (isDesktop()) {
        document.body.classList.toggle('sidebar-collapse');
        return;
    }

    document.body.classList.toggle('sidebar-open');
};

watch(() => page.url, () => {
    showFlashSuccess.value = true;
    closeMobileSidebar();
    syncOpenMenusWithRoute();
    syncPageHeading();
});

const sendMarketingLocation = (source = 'heartbeat') => {
    if (user.value?.role !== 'marketing' || !navigator.geolocation) return;

    navigator.geolocation.getCurrentPosition((position) => {
        window.axios.post(adminUrl('/marketing/location'), {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            source,
        }).catch(() => {});
    }, () => {}, { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 });
};

onMounted(() => {
    if (typeof document !== 'undefined') {
        document.body.classList.remove('sidebar-open');
    }
    syncOpenMenusWithRoute();
    syncPageHeading();

    if (user.value?.role === 'marketing') {
        sendMarketingLocation();
        locationInterval = window.setInterval(() => sendMarketingLocation(), 3600000);
    }
});

onBeforeUnmount(() => {
    if (locationInterval) window.clearInterval(locationInterval);
    closeMobileSidebar();
});
</script>






