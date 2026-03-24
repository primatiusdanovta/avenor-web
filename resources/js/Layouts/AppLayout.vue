<template>
    <div class="wrapper">
        <nav class="main-header navbar navbar-expand navbar-white navbar-light">
            <ul class="navbar-nav">
                <li class="nav-item">
                    <a class="nav-link" data-widget="pushmenu" href="#" role="button"><i class="fas fa-bars"></i></a>
                </li>
            </ul>
            <ul class="navbar-nav ml-auto align-items-center">
                <li class="nav-item mr-3 text-sm text-muted">
                    {{ user?.nama }} | {{ user?.role }}
                </li>
                <li class="nav-item">
                    <Link href="/logout" method="post" as="button" class="btn btn-outline-danger btn-sm">Logout</Link>
                </li>
            </ul>
        </nav>

        <aside class="main-sidebar sidebar-dark-primary elevation-4">
            <Link href="/dashboard" class="brand-link d-flex align-items-center">
                <img :src="logoUrl" alt="Primatama" class="brand-image img-circle elevation-2 bg-white p-1">
                <span class="brand-text font-weight-light">Avenor Web</span>
            </Link>

            <div class="sidebar">
                <div class="user-panel mt-3 pb-3 mb-3 d-flex">
                    <div class="image">
                        <div class="adminlte-avatar">{{ initials }}</div>
                    </div>
                    <div class="info">
                        <a href="#" class="d-block">{{ user?.nama }}</a>
                        <small class="text-muted text-capitalize">{{ user?.role }} | {{ user?.status }}</small>
                    </div>
                </div>

                <nav class="mt-2">
                    <ul class="nav nav-pills nav-sidebar flex-column" role="menu">
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

        <div class="content-wrapper">
            <div class="content-header">
                <div class="container-fluid">
                    <div class="row mb-2">
                        <div class="col-sm-6"><h1 class="m-0">{{ title }}</h1></div>
                        <div class="col-sm-6 text-right"><slot name="actions" /></div>
                    </div>
                </div>
            </div>

            <div class="content">
                <div class="container-fluid">
                    <div v-if="flashSuccess" class="alert alert-success alert-dismissible fade show" role="alert">
                        {{ flashSuccess }}
                        <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                    </div>
                    <slot />
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted } from 'vue';
import { Link, usePage } from '@inertiajs/vue3';

defineProps({
    title: { type: String, default: 'Dashboard' },
});

const page = usePage();
const logoUrl = '/img/primatama.png';
const user = computed(() => page.props.auth?.user ?? null);
const navigation = computed(() => page.props.navigation ?? []);
const currentUrl = computed(() => page.url ?? '');
const flashSuccess = computed(() => page.props.flash?.success ?? null);
const initials = computed(() => user.value?.nama?.slice(0, 2).toUpperCase() ?? 'AW');
let locationInterval = null;

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
    if (user.value?.role === 'marketing') {
        sendMarketingLocation();
        locationInterval = window.setInterval(() => sendMarketingLocation(), 3600000);
    }
});

onBeforeUnmount(() => {
    if (locationInterval) window.clearInterval(locationInterval);
});
</script>