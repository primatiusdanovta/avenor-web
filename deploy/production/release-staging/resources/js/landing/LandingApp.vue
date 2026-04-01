<template>
    <div class="landing-root" :style="themeVars">
        <div class="landing-noise"></div>
        <Navbar page-type="product" :social-hub="content.social_hub || {}" :ui-labels="uiLabels.navigation" />
        <HeroSection
            :hero="content.hero"
            :product="content.product"
            :is-mobile="isMobile"
            :social-hub="content.social_hub || {}"
            @click-wa="handleWhatsApp"
            @share="handleShare"
            @open-buy-options="showMarketplaceSheet = true"
        />
        <NotesJourney :story="content.story" :notes="content.notes" :product-name="content.product?.name" />
        <IngredientBento :intro="content.ingredients_intro" :ingredients="content.ingredients" />
        <EducationBlock :education="content.education" />
        <FaqAccordion :items="content.faq || []" :faq-content="uiLabels.faq" />
        <MainFooter :social-hub="content.social_hub || {}" />

        <button v-if="hasMarketplaceLinks" type="button" class="sticky-buy-button" @click="showMarketplaceSheet = true">{{ uiLabels.sticky_cta?.label }}</button>
        <MarketplaceSheet
            :show="showMarketplaceSheet"
            :links="content.social_hub || {}"
            :labels="uiLabels.marketplace"
            @close="showMarketplaceSheet = false"
            @select="handleMarketplaceSelect"
        />

        <div v-if="loading" class="landing-loading">{{ uiLabels.system_messages?.loading }}</div>
        <div v-if="error" class="landing-error">{{ error }}</div>
    </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import axios from 'axios';
import EducationBlock from './EducationBlock.vue';
import FaqAccordion from './FaqAccordion.vue';
import HeroSection from './HeroSection.vue';
import IngredientBento from './IngredientBento.vue';
import MainFooter from './MainFooter.vue';
import MarketplaceSheet from './MarketplaceSheet.vue';
import Navbar from './Navbar.vue';
import NotesJourney from './NotesJourney.vue';

const fallbackLabels = {
    navigation: {
        home_label: '',
        brand_label: '',
        collection_label: '',
        discovery_label: '',
        contact_label: '',
    },
    faq: {
        kicker: '',
        title: '',
        description: '',
    },
    marketplace: {
        title: '',
        tokopedia_label: '',
        tiktok_shop_label: '',
        empty_state: '',
    },
    sticky_cta: {
        label: '',
    },
    system_messages: {
        loading: '',
        error: '',
    },
    share_text_prefix: '',
};

const fallbackContent = {
    product: null,
    hero: null,
    story: null,
    notes: [],
    ingredients_intro: null,
    ingredients: [],
    education: null,
    faq: [],
    theme: {
        background: '',
        accent: '',
        accentSoft: '',
        accentDeep: '',
        halo: '',
    },
    social_hub: {},
    ui_labels: fallbackLabels,
};

const loading = ref(true);
const error = ref('');
const viewportWidth = ref(typeof window === 'undefined' ? 1440 : window.innerWidth);
const productSlug = ref(typeof window !== 'undefined' ? (window.AVENOR_PRODUCT_SLUG || '') : '');
const content = ref(typeof window !== 'undefined' && window.AVENOR_LANDING_INITIAL_STATE ? window.AVENOR_LANDING_INITIAL_STATE : fallbackContent);
const showMarketplaceSheet = ref(false);
const isMobile = computed(() => viewportWidth.value < 769);
const hasMarketplaceLinks = computed(() => Boolean(content.value?.social_hub?.tokopedia_url || content.value?.social_hub?.tiktok_shop_url));
const uiLabels = computed(() => ({
    ...fallbackLabels,
    ...(content.value?.ui_labels || {}),
    navigation: {
        ...fallbackLabels.navigation,
        ...(content.value?.ui_labels?.navigation || {}),
    },
    faq: {
        ...fallbackLabels.faq,
        ...(content.value?.ui_labels?.faq || {}),
    },
    marketplace: {
        ...fallbackLabels.marketplace,
        ...(content.value?.ui_labels?.marketplace || {}),
    },
    sticky_cta: {
        ...fallbackLabels.sticky_cta,
        ...(content.value?.ui_labels?.sticky_cta || {}),
    },
    system_messages: {
        ...fallbackLabels.system_messages,
        ...(content.value?.ui_labels?.system_messages || {}),
    },
}));
const themeVars = computed(() => ({
    '--landing-background': content.value?.theme?.background || '',
    '--landing-accent': content.value?.theme?.accent || '',
    '--landing-accent-soft': content.value?.theme?.accentSoft || '',
    '--landing-accent-deep': content.value?.theme?.accentDeep || '',
    '--landing-halo': content.value?.theme?.halo || '',
}));
let hasTrackedView = false;

const trackEvent = (eventName, params = {}) => {
    if (typeof window !== 'undefined' && typeof window.gtag === 'function') {
        window.gtag('event', eventName, params);
    }

    if (typeof window !== 'undefined' && typeof window.fbq === 'function') {
        window.fbq('trackCustom', eventName, params);
    }
};

const trackViewContent = () => {
    if (hasTrackedView || !content.value?.product) return;

    hasTrackedView = true;
    trackEvent('ViewContent', {
        content_name: content.value.product.name,
        content_ids: [content.value.product.id_product],
        value: content.value.product.price,
        currency: 'IDR',
    });

    if (typeof window !== 'undefined' && typeof window.fbq === 'function') {
        window.fbq('track', 'ViewContent', {
            content_name: content.value.product.name,
            content_ids: [content.value.product.id_product],
            value: content.value.product.price,
            currency: 'IDR',
        });
    }
};

const loadContent = async () => {
    if (!productSlug.value) {
        loading.value = false;
        return;
    }

    loading.value = true;
    error.value = '';

    try {
        const response = await axios.get(`/api/landing-content/${productSlug.value}`);
        content.value = response.data ?? content.value;
        trackViewContent();
    } catch (err) {
        error.value = uiLabels.value.system_messages?.error || '';
    } finally {
        loading.value = false;
    }
};

const handleResize = () => {
    viewportWidth.value = window.innerWidth;
};

const handleWhatsApp = () => {
    if (!content.value?.product?.whatsapp_url) return;
    trackEvent('ClickToWA', {
        product_name: content.value.product.name,
        destination: 'whatsapp',
    });
    window.open(content.value.product.whatsapp_url, '_blank', 'noopener');
};

const handleMarketplaceSelect = (platform) => {
    showMarketplaceSheet.value = false;
    trackEvent('MarketplaceClick', {
        product_name: content.value?.product?.name,
        destination: platform,
    });
};

const handleShare = async (platform) => {
    const url = window.location.href;
    const title = content.value?.product?.name || content.value?.seo?.title || '';
    const prefix = (uiLabels.value.share_text_prefix || '').trim();
    const text = [prefix, title].filter(Boolean).join(' ');

    trackEvent('ShareLanding', { platform, product_name: title });

    if ((platform === 'instagram' || platform === 'tiktok') && navigator.share) {
        await navigator.share({ title, text, url }).catch(() => {});
        return;
    }

    if (platform === 'facebook') {
        window.open(`https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(url)}`, '_blank', 'noopener');
        return;
    }

    if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(url).catch(() => {});
    }
};

watch(() => content.value?.product?.id_product, () => {
    trackViewContent();
});

onMounted(() => {
    document.body.className = 'landing-body';
    document.documentElement.style.scrollBehavior = 'smooth';
    window.addEventListener('resize', handleResize, { passive: true });

    if (window.AVENOR_LANDING_INITIAL_STATE) {
        loading.value = false;
        trackViewContent();
        return;
    }

    loadContent();
});

onBeforeUnmount(() => {
    window.removeEventListener('resize', handleResize);
});
</script>
