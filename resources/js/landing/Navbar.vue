<template>
    <header class="landing-navbar" :class="{ 'landing-navbar--scrolled': isScrolled }">
        <div class="container">
            <div class="landing-navbar__inner">
                <nav class="landing-navbar__menu landing-navbar__menu--left" aria-label="Primary">
                    <a v-for="item in leftItems" :key="`${item.label}-${item.href}`" :href="resolveHref(item.href)" @click="handleNavClick($event, resolveHref(item.href))">{{ item.label }}</a>
                </nav>

                <a :href="homeHref" class="landing-navbar__brand" :aria-label="brandLabel ? brandLabel + ' home' : ''" @click="handleNavClick($event, homeHref)">
                    <img :src="brandLogo" :alt="brandLabel" class="landing-navbar__logo">
                </a>

                <nav class="landing-navbar__menu landing-navbar__menu--right" aria-label="Secondary">
                    <a v-for="item in rightItems" :key="`${item.label}-${item.href}`" :href="resolveHref(item.href)" @click="handleNavClick($event, resolveHref(item.href))">{{ item.label }}</a>
                </nav>
            </div>
        </div>
    </header>

</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import brandLogo from '../../img/avenor_putih.png';

const props = defineProps({
    pageType: { type: String, default: 'master' },
    socialHub: { type: Object, default: () => ({}) },
    uiLabels: { type: Object, default: () => ({}) },
});

const isScrolled = ref(false);

const homeHref = computed(() => (props.pageType === 'master' ? '#top' : '/'));
const defaultItems = [
    { label: 'Home', href: '#top', side: 'left' },
    { label: 'Social Hub', href: '#social-hub', side: 'left' },
    { label: 'The Collection', href: '#collection', side: 'left' },
    { label: 'Discovery', href: '#discovery', side: 'right' },
    { label: 'Contact', href: '#main-footer', side: 'right' },
    { label: 'Carrers', href: '/carrers', side: 'right' },
];
const navItems = computed(() => {
    const configured = props.socialHub?.master_page?.navigation?.items;
    if (Array.isArray(configured) && configured.length) {
        return configured.filter((item) => item?.label && item?.href);
    }

    return defaultItems;
});
const leftItems = computed(() => navItems.value.filter((item) => (item.side || 'left') === 'left'));
const rightItems = computed(() => navItems.value.filter((item) => (item.side || 'right') === 'right'));
const brandLabel = computed(() => props.uiLabels?.brand_label || 'Avenor Perfume');

const resolveHref = (href) => {
    if (!href) {
        return homeHref.value;
    }

    if (href === '#top') {
        return props.pageType === 'master' ? '#top' : '/';
    }

    if (href.startsWith('#')) {
        return props.pageType === 'master' ? href : `/${href}`;
    }

    return href;
};

const updateScrollState = () => {
    isScrolled.value = window.scrollY > 24;
};

const handleNavClick = (event, href) => {
    if (!href || href.startsWith('/#') || href === '/' || !href.startsWith('#')) {
        return;
    }

    event.preventDefault();

    if (href === '#top') {
        window.scrollTo({ top: 0, behavior: 'smooth' });
        return;
    }

    const target = document.querySelector(href);
    if (!target) {
        return;
    }

    const navbar = document.querySelector('.landing-navbar');
    const offset = navbar ? navbar.getBoundingClientRect().height + 16 : 92;
    const top = target.getBoundingClientRect().top + window.scrollY - offset;

    window.scrollTo({ top, behavior: 'smooth' });
};

onMounted(() => {
    updateScrollState();
    window.addEventListener('scroll', updateScrollState, { passive: true });
});

onBeforeUnmount(() => {
    window.removeEventListener('scroll', updateScrollState);
});
</script>
