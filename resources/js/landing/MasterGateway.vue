<template>
    <div class="landing-root master-root">
        <div class="landing-noise"></div>
        <Navbar page-type="master" :social-hub="content.social_hub || {}" />

        <section class="master-hero section-shell">
            <div class="master-hero__video">
                <video v-if="content.hero?.video_url" class="master-hero__video-el" :src="content.hero.video_url" autoplay muted loop playsinline preload="metadata"></video>
            </div>
            <div class="container position-relative">
                <div class="row justify-content-center text-center">
                    <div class="col-lg-9">
                        <div class="hero-kicker">{{ content.hero?.eyebrow || 'Avenor Perfume' }}</div>
                        <h1 ref="titleRef" class="master-title">{{ content.hero?.title }}</h1>
                        <p class="hero-description mx-auto master-description">{{ content.hero?.description }}</p>
                    </div>
                </div>
            </div>
        </section>

        <section id="social-hub" class="section-shell">
            <div class="container">
                <div class="section-heading text-center mx-auto">
                    <div class="section-kicker">{{ masterPage.social_hub_section.eyebrow }}</div>
                    <h2 class="section-title">{{ masterPage.social_hub_section.title }}</h2>
                    <p class="section-description">{{ masterPage.social_hub_section.description }}</p>
                </div>
                <div class="row g-3 g-lg-4">
                    <div class="col-12 col-lg-4">
                        <component :is="content.social_hub?.tiktok_url ? 'a' : 'div'" class="master-card" :href="content.social_hub?.tiktok_url || null" target="_blank" rel="noopener" :class="{ 'master-card--disabled': !content.social_hub?.tiktok_url }">
                            <div class="master-card__eyebrow">{{ socialCards.tiktok.eyebrow }}</div>
                            <h3>{{ socialCards.tiktok.title }}</h3>
                            <p>{{ socialCards.tiktok.description }}</p>
                        </component>
                    </div>
                    <div class="col-12 col-lg-4">
                        <component :is="content.social_hub?.instagram_url ? 'a' : 'div'" class="master-card" :href="content.social_hub?.instagram_url || null" target="_blank" rel="noopener" :class="{ 'master-card--disabled': !content.social_hub?.instagram_url }">
                            <div class="master-card__eyebrow">{{ socialCards.instagram.eyebrow }}</div>
                            <h3>{{ socialCards.instagram.title }}</h3>
                            <p>{{ socialCards.instagram.description }}</p>
                        </component>
                    </div>
                    <div class="col-12 col-lg-4">
                        <component :is="content.social_hub?.whatsapp_url ? 'a' : 'div'" class="master-card" :href="content.social_hub?.whatsapp_url || null" target="_blank" rel="noopener" :class="{ 'master-card--disabled': !content.social_hub?.whatsapp_url }">
                            <div class="master-card__eyebrow">{{ socialCards.whatsapp.eyebrow }}</div>
                            <h3>{{ socialCards.whatsapp.title }}</h3>
                            <p>{{ socialCards.whatsapp.description }}</p>
                        </component>
                    </div>
                </div>
            </div>
        </section>

        <section id="collection" class="section-shell">
            <div class="container-fluid px-0">
                <div class="container">
                    <div class="section-heading d-flex flex-column flex-lg-row justify-content-between align-items-lg-end gap-3">
                        <div>
                            <div class="section-kicker">{{ masterPage.collection_section.eyebrow }}</div>
                            <h2 class="section-title mb-0">{{ masterPage.collection_section.title }}</h2>
                        </div>
                        <p class="section-description mb-0">{{ masterPage.collection_section.description }}</p>
                    </div>
                </div>
                <div class="master-collection-grid" :class="collectionGridClass">
                    <a v-for="product in content.products" :key="product.id_product" class="collection-card" :class="{ 'collection-card--disabled': !product.url }" :href="product.url || null">
                        <div class="collection-card__media">
                            <img v-if="product.image_url" :src="product.image_url" :alt="product.name" loading="lazy">
                            <div v-else class="collection-card__placeholder">{{ product.name }}</div>
                        </div>
                        <div class="collection-card__body">
                            <div class="collection-card__eyebrow">{{ product.is_active ? masterPage.collection_section.card_active_status : masterPage.collection_section.card_inactive_status }}</div>
                            <h3>{{ product.name }}</h3>
                            <div class="collection-card__meta">
                                <span v-for="tag in product.scent_tags || []" :key="product.id_product + '-' + tag" class="collection-card__tag">{{ tag }}</span>
                            </div>
                            <span class="collection-card__cta">{{ product.url ? masterPage.collection_section.card_active_cta : masterPage.collection_section.card_inactive_cta }}</span>
                        </div>
                    </a>
                </div>
            </div>
        </section>

        <section class="section-shell">
            <div class="container">
                <div class="manifesto-card">
                    <div class="section-kicker">{{ masterPage.manifesto.eyebrow }}</div>
                    <h2 class="manifesto-card__title">{{ masterPage.manifesto.title }}</h2>
                    <p class="section-description mb-0">{{ masterPage.manifesto.description }}</p>
                </div>
            </div>
        </section>

        <section id="discovery" class="section-shell">
            <div class="container">
                <div class="section-heading text-center mx-auto">
                    <div class="section-kicker">{{ masterPage.discovery.eyebrow }}</div>
                    <h2 class="section-title">{{ masterPage.discovery.title }}</h2>
                    <p class="section-description">{{ masterPage.discovery.description }}</p>
                </div>

                <div v-if="discoveryCards.length && !isDiscoverySlider" class="row g-3 g-lg-4">
                    <div v-for="preview in discoveryCards" :key="preview.id" class="col-12 col-lg-6">
                        <div class="education-card education-card--preview h-100">
                            <div class="education-card__eyebrow">{{ masterPage.discovery.preview_eyebrow }}</div>
                            <h3 class="collection-card__title">{{ preview.title }}</h3>
                            <p class="mb-0">{{ preview.description }}</p>
                        </div>
                    </div>
                </div>

                <div v-else-if="discoveryCards.length" class="discovery-slider-wrap">
                    <div class="discovery-slider-toolbar">
                        <button type="button" class="discovery-slider__nav" :disabled="discoveryIndex === 0" @click="scrollDiscovery(-1)">Prev</button>
                        <div class="discovery-slider__dots">
                            <button
                                v-for="(preview, index) in discoveryCards"
                                :key="preview.id + '-dot'"
                                type="button"
                                class="discovery-slider__dot"
                                :class="{ 'is-active': index === discoveryIndex }"
                                :aria-label="'Go to discovery card ' + (index + 1)"
                                @click="scrollDiscoveryTo(index)"
                            ></button>
                        </div>
                        <button type="button" class="discovery-slider__nav" :disabled="discoveryIndex >= discoveryCards.length - 1" @click="scrollDiscovery(1)">Next</button>
                    </div>
                    <div ref="discoveryScroller" class="discovery-slider" @scroll.passive="syncDiscoveryIndex">
                        <article v-for="(preview, index) in discoveryCards" :key="preview.id" class="discovery-slide" :class="{ 'is-active': index === discoveryIndex }" tabindex="0">
                            <div class="education-card education-card--preview h-100">
                                <div class="education-card__eyebrow">{{ masterPage.discovery.preview_eyebrow }}</div>
                                <h3 class="collection-card__title">{{ preview.title }}</h3>
                                <p class="mb-0">{{ preview.description }}</p>
                            </div>
                        </article>
                    </div>
                </div>
            </div>
        </section>

        <MainFooter :social-hub="content.social_hub || {}" />

        <div v-if="loading" class="landing-loading">{{ masterPage.system_messages.loading }}</div>
        <div v-if="error" class="landing-error">{{ error }}</div>
    </div>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue';
import axios from 'axios';
import MainFooter from './MainFooter.vue';
import Navbar from './Navbar.vue';

const fallbackContent = {
    page_type: 'master',
    hero: { title: 'Discover Your Signature', description: '' },
    products: [],
    social_hub: {},
};

const defaultSocialCards = {
    tiktok: {
        eyebrow: 'TikTok',
        title: 'Review Highlights',
        description: 'Short-form fragrance impressions, reactions, and launch moments.',
    },
    instagram: {
        eyebrow: 'Instagram',
        title: 'Aesthetic Grid',
        description: 'Editorial visuals, rituals, and product stories in a curated gallery.',
    },
    whatsapp: {
        eyebrow: 'WhatsApp',
        title: 'Consult with Our Scent Expert',
        description: 'Start a direct conversation and get guided toward the right scent.',
    },
};

const content = ref(typeof window !== 'undefined' && window.AVENOR_LANDING_INITIAL_STATE ? window.AVENOR_LANDING_INITIAL_STATE : fallbackContent);
const loading = ref(true);
const error = ref('');
const titleRef = ref(null);
const discoveryScroller = ref(null);
const discoveryIndex = ref(0);

const socialCards = computed(() => ({
    tiktok: { ...defaultSocialCards.tiktok, ...(content.value?.social_hub?.cards?.tiktok || {}) },
    instagram: { ...defaultSocialCards.instagram, ...(content.value?.social_hub?.cards?.instagram || {}) },
    whatsapp: { ...defaultSocialCards.whatsapp, ...(content.value?.social_hub?.cards?.whatsapp || {}) },
}));

const masterPage = computed(() => ({
    social_hub_section: {
        eyebrow: content.value?.social_hub?.master_page?.social_hub_section?.eyebrow || 'Social Hub',
        title: content.value?.social_hub?.master_page?.social_hub_section?.title || 'Follow the brand atmosphere across channels',
        description: content.value?.social_hub?.master_page?.social_hub_section?.description || 'Connect with the brand through short-form reviews, editorial visuals, and direct WhatsApp consultation.',
    },
    collection_section: {
        eyebrow: content.value?.social_hub?.master_page?.collection_section?.eyebrow || 'The Collection',
        title: content.value?.social_hub?.master_page?.collection_section?.title || 'Explore the full collection',
        description: content.value?.social_hub?.master_page?.collection_section?.description || 'Each discovery card opens a dedicated scent narrative.',
        card_active_status: content.value?.social_hub?.master_page?.collection_section?.card_active_status || 'Discovery Ready',
        card_inactive_status: content.value?.social_hub?.master_page?.collection_section?.card_inactive_status || 'Coming Soon',
        card_active_cta: content.value?.social_hub?.master_page?.collection_section?.card_active_cta || 'Explore the Scent',
        card_inactive_cta: content.value?.social_hub?.master_page?.collection_section?.card_inactive_cta || 'Awaiting Discovery',
    },
    manifesto: {
        eyebrow: content.value?.social_hub?.master_page?.manifesto?.eyebrow || 'Brand Manifesto',
        title: content.value?.social_hub?.master_page?.manifesto?.title || 'Crafted in small batches for unique souls.',
        description: content.value?.social_hub?.master_page?.manifesto?.description || 'Avenor builds perfume as atmosphere first. Every bottle is composed to feel intimate, memorable, and quietly bold from first spray to dry down.',
    },
    discovery: {
        eyebrow: content.value?.social_hub?.master_page?.discovery?.eyebrow || 'Journal / Discovery',
        title: content.value?.social_hub?.master_page?.discovery?.title || 'Learn how each scent performs before you choose',
        description: content.value?.social_hub?.master_page?.discovery?.description || 'A quick preview from our fragrance education blocks before you move into a full product story.',
        preview_eyebrow: content.value?.social_hub?.master_page?.discovery?.preview_eyebrow || 'Educational Preview',
    },
    system_messages: {
        loading: content.value?.social_hub?.master_page?.system_messages?.loading || 'Curating the gateway...',
        error: content.value?.social_hub?.master_page?.system_messages?.error || 'The master gateway could not be loaded right now.',
    },
}));

const discoveryCards = computed(() => {
    const configuredPreviews = (content.value?.social_hub?.master_page?.discovery?.preview_cards || [])
        .filter((item) => item?.title || item?.description)
        .map((item, index) => ({
            id: 'configured-' + index,
            title: item.title || 'Discovery Notes',
            description: item.description || 'Understand the profile, texture, and character of each scent before entering a full product narrative.',
        }));

    if (configuredPreviews.length) {
        return configuredPreviews;
    }

    return (content.value?.products || [])
        .filter((product) => product.is_active)
        .slice(0, 6)
        .map((product) => ({
            id: 'product-' + product.id_product,
            title: product.name + ' Discovery',
            description: product.description || 'Discover the profile, character, and wearing ritual of this scent before opening the full story.',
        }));
});

const isDiscoverySlider = computed(() => discoveryCards.value.length > 2);

const collectionGridClass = computed(() => ({
    'master-collection-grid--eleven': (content.value?.products || []).length >= 11,
}));

const getDiscoverySlides = () => Array.from(discoveryScroller.value?.querySelectorAll('.discovery-slide') || []);

const syncDiscoveryIndex = () => {
    if (!discoveryScroller.value) return;

    const slides = getDiscoverySlides();
    if (!slides.length) return;

    const currentLeft = discoveryScroller.value.scrollLeft;
    let closestIndex = 0;
    let closestDistance = Number.POSITIVE_INFINITY;

    slides.forEach((slide, index) => {
        const distance = Math.abs(slide.offsetLeft - currentLeft);
        if (distance < closestDistance) {
            closestDistance = distance;
            closestIndex = index;
        }
    });

    discoveryIndex.value = closestIndex;
};

const scrollDiscoveryTo = (index) => {
    if (!discoveryScroller.value) return;

    const slides = getDiscoverySlides();
    const target = slides[index];
    if (!target) return;

    discoveryScroller.value.scrollTo({
        left: target.offsetLeft,
        behavior: 'smooth',
    });
    discoveryIndex.value = index;
};

const scrollDiscovery = (direction) => {
    const nextIndex = Math.min(Math.max(discoveryIndex.value + direction, 0), discoveryCards.value.length - 1);
    scrollDiscoveryTo(nextIndex);
};

const handleDiscoveryResize = () => {
    if (!isDiscoverySlider.value) return;
    scrollDiscoveryTo(discoveryIndex.value);
};

const loadContent = async () => {
    loading.value = true;
    error.value = '';

    try {
        const response = await axios.get('/api/master-gateway');
        content.value = response.data ?? content.value;
        discoveryIndex.value = 0;
        animateTitle();
    } catch (err) {
        error.value = content.value?.social_hub?.master_page?.system_messages?.error || 'The master gateway could not be loaded right now.';
    } finally {
        loading.value = false;
    }
};

const animateTitle = async () => {
    await nextTick();

    if (!window.gsap || !titleRef.value) return;

    const text = titleRef.value.textContent || '';
    titleRef.value.innerHTML = text.split('').map((char) => `<span class="master-title__char">${char === ' ' ? '&nbsp;' : char}</span>`).join('');
    const chars = titleRef.value.querySelectorAll('.master-title__char');

    window.gsap.fromTo(chars, { autoAlpha: 0, y: 24 }, { autoAlpha: 1, y: 0, stagger: 0.04, duration: 0.55, ease: 'power2.out' });
};

onMounted(() => {
    document.body.className = 'landing-body';
    document.documentElement.style.scrollBehavior = 'smooth';
    window.addEventListener('resize', handleDiscoveryResize, { passive: true });

    if (window.AVENOR_LANDING_INITIAL_STATE) {
        loading.value = false;
        animateTitle();
        return;
    }

    loadContent();
});

onBeforeUnmount(() => {
    window.removeEventListener('resize', handleDiscoveryResize);
});
</script>

<style scoped>
.discovery-slider-wrap {
    display: grid;
    gap: 1rem;
}

.discovery-slider-toolbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
}

.discovery-slider {
    display: grid;
    grid-auto-flow: column;
    grid-auto-columns: minmax(0, 84%);
    gap: 1rem;
    overflow-x: auto;
    padding: 0.25rem 0 0.75rem;
    scroll-snap-type: x mandatory;
    scrollbar-width: none;
    cursor: grab;
}

.discovery-slider::-webkit-scrollbar {
    display: none;
}

.discovery-slide {
    scroll-snap-align: start;
    transition: transform 220ms ease, opacity 220ms ease;
    opacity: 0.72;
}

.discovery-slide.is-active {
    opacity: 1;
    transform: translateY(-4px);
}

.discovery-slider__nav {
    border: 1px solid rgba(212, 175, 55, 0.35);
    background: rgba(255, 255, 255, 0.04);
    color: #f8f1dc;
    border-radius: 999px;
    padding: 0.65rem 1rem;
    font-size: 0.85rem;
    letter-spacing: 0.12em;
    text-transform: uppercase;
}

.discovery-slider__nav:disabled {
    opacity: 0.45;
    cursor: not-allowed;
}

.discovery-slider__dots {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    flex: 1;
}

.discovery-slider__dot {
    width: 0.7rem;
    height: 0.7rem;
    border-radius: 999px;
    border: 0;
    background: rgba(255, 255, 255, 0.2);
}

.discovery-slider__dot.is-active {
    background: var(--landing-accent, #d4af37);
}

@media (min-width: 992px) {
    .discovery-slider {
        grid-auto-columns: minmax(0, 42%);
    }
}
</style>
