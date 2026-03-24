<template>
    <div class="shell">
        <aside class="sidebar">
            <div>
                <div class="brand">
                    <img :src="logoUrl" alt="Primatama" class="brand-logo">
                    <div>
                        <p class="brand-eyebrow">Avenor Web</p>
                        <h1>Control Panel</h1>
                    </div>
                </div>

                <nav class="nav-group">
                    <Link
                        v-for="item in navigation"
                        :key="item.href"
                        :href="item.href"
                        class="nav-link"
                        :class="{ active: isActive(item.href) }"
                    >
                        {{ item.label }}
                    </Link>
                </nav>
            </div>

            <div class="sidebar-footer">
                <div class="profile-card">
                    <p class="profile-name">{{ user?.nama }}</p>
                    <p class="profile-meta">{{ user?.role }} · {{ user?.status }}</p>
                </div>

                <Link href="/logout" method="post" as="button" class="logout-button">
                    Logout
                </Link>
            </div>
        </aside>

        <main class="content">
            <header class="page-header">
                <div>
                    <p class="page-kicker">Single Page App</p>
                    <h2>{{ title }}</h2>
                </div>
                <slot name="actions" />
            </header>

            <slot />
        </main>
    </div>
</template>

<script setup>
import { computed } from 'vue';
import { Link, usePage } from '@inertiajs/vue3';

defineProps({
    title: {
        type: String,
        default: 'Dashboard',
    },
});

const logoUrl = '/img/primatama.png';
const page = usePage();
const user = computed(() => page.props.auth?.user ?? null);
const navigation = computed(() => page.props.navigation ?? []);
const currentUrl = computed(() => page.url ?? '');

const isActive = (path) => currentUrl.value.startsWith(path);
</script>