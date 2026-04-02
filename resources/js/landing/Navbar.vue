<template>
    <header class="landing-navbar" :class="{ 'landing-navbar--scrolled': isScrolled }">
        <div class="container">
            <div class="landing-navbar__inner">
                <nav class="landing-navbar__menu landing-navbar__menu--left" aria-label="Primary">
                    <a :href="homeHref" @click="handleNavClick($event, homeHref)">{{ resolvedLabels.home_label }}</a>
                    <a :href="collectionHref" @click="handleNavClick($event, collectionHref)">{{ resolvedLabels.collection_label }}</a>
                </nav>

                <a :href="homeHref" class="landing-navbar__brand" :aria-label="brandLabel ? brandLabel + ' home' : ''" @click="handleNavClick($event, homeHref)">
                    <img :src="brandLogo" :alt="brandLabel" class="landing-navbar__logo">
                </a>

                <nav class="landing-navbar__menu landing-navbar__menu--right" aria-label="Secondary">
                    <a :href="discoveryHref" @click="handleNavClick($event, discoveryHref)">{{ resolvedLabels.discovery_label }}</a>
                    <a :href="contactHref" @click="handleNavClick($event, contactHref)">{{ resolvedLabels.contact_label }}</a>
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
const collectionHref = computed(() => (props.pageType === 'master' ? '#collection' : '/#collection'));
const discoveryHref = computed(() => (props.pageType === 'master' ? '#discovery' : '/#discovery'));
const contactHref = computed(() => (props.pageType === 'master' ? '#main-footer' : '/#main-footer'));
const resolvedLabels = computed(() => ({
    home_label: props.uiLabels?.home_label || 'Home',
    brand_label: props.uiLabels?.brand_label || 'Avenor Perfume',
    collection_label: props.uiLabels?.collection_label || 'Collection',
    discovery_label: props.uiLabels?.discovery_label || 'Discovery',
    contact_label: props.uiLabels?.contact_label || 'Contact',
}));

const brandLabel = computed(() => resolvedLabels.value.brand_label || resolvedLabels.value.home_label || '');

const updateScrollState = () => {
    isScrolled.value = window.scrollY > 24;
};

const handleNavClick = (event, href) => {
    if (!href || href.startsWith('/#') || !href.startsWith('#')) {
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

