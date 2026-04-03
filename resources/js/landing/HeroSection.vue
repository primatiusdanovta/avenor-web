<template>
    <section v-if="hero?.is_active" class="landing-hero section-shell">
        <div class="container">
            <div class="row align-items-center g-4 g-lg-5">
                <div class="col-lg-6 order-2 order-lg-1">
                    <div class="hero-copy">
                        <div class="hero-kicker">{{ hero.meta_data?.eyebrow }}</div>
                        <div class="hero-badge">{{ hero.meta_data?.badge }}</div>
                        <h1 class="hero-title">{{ hero.title }}</h1>
                        <p class="hero-description">{{ hero.description }}</p>

                        <div v-if="product" class="hero-product-meta">
                            <div class="hero-meta-card">
                                <span class="hero-meta-label">{{ hero.meta_data?.price_label }}</span>
                                <strong>{{ formatCurrency(product.price) }}</strong>
                            </div>
                            <div class="hero-meta-card">
                                <span class="hero-meta-label">{{ hero.meta_data?.stock_label }}</span>
                                <strong>{{ stockText }}</strong>
                            </div>
                        </div>

                        <div class="hero-actions">
                            <a :href="hero.meta_data?.cta_href" class="btn btn-luxury-primary btn-lg">{{ hero.meta_data?.cta_label }}</a>
                            <a :href="hero.meta_data?.secondary_href" class="btn btn-luxury-secondary btn-lg">{{ hero.meta_data?.secondary_label }}</a>
                            <button type="button" class="btn btn-luxury-secondary btn-lg" @click="$emit('click-wa')">{{ hero.meta_data?.whatsapp_label }}</button>
                            <button v-if="hasMarketplaceLinks" type="button" class="btn btn-luxury-secondary btn-lg" @click="$emit('open-buy-options')">{{ hero.meta_data?.buy_options_label }}</button>
                        </div>

                        <div class="social-share mt-4">
                            <button type="button" class="social-share__button" @click="$emit('share', 'facebook')">{{ hero.meta_data?.share_facebook_label }}</button>
                            <button type="button" class="social-share__button" @click="$emit('share', 'instagram')">{{ hero.meta_data?.share_instagram_label }}</button>
                            <button type="button" class="social-share__button" @click="$emit('share', 'tiktok')">{{ hero.meta_data?.share_tiktok_label }}</button>
                        </div>
                    </div>
                </div>
                <div class="col-lg-6 order-1 order-lg-2">
                    <div class="hero-bottle-stage">
                        <LuxuryBottlePlaceholder
                            v-if="shouldUseBottleImage"
                            :image-src="bottleImageUrl"
                            :tilt-enabled="hero.meta_data?.bottle?.tilt_desktop && !isMobile"
                            :floating="hero.meta_data?.bottle?.floating_mobile && isMobile"
                            :name="product?.name || hero.title"
                            :brand-label="hero.meta_data?.bottle?.brand_label"
                            :show-glow="hero.meta_data?.bottle?.show_glow"
                            :show-shadow="hero.meta_data?.bottle?.show_shadow"
                            :show-liquid="hero.meta_data?.bottle?.show_liquid"
                            :show-label="hero.meta_data?.bottle?.show_label"
                            :appearance="hero.meta_data?.bottle"
                        />
                        <div v-else-if="shouldUseProductImage" class="hero-visual-card">
                            <div class="hero-slider">
                                <button
                                    v-if="hasMultipleImages"
                                    type="button"
                                    class="hero-slider__nav hero-slider__nav--prev"
                                    aria-label="Gambar sebelumnya"
                                    @click="prevImage"
                                >
                                    ‹
                                </button>
                                <button
                                    type="button"
                                    class="hero-slider__image-button"
                                    :aria-label="`Lihat gambar ${product.name} lebih besar`"
                                    @click="openLightbox"
                                >
                                    <img :src="activeImage" :alt="product.name" class="hero-product-image" loading="eager">
                                </button>
                                <button
                                    v-if="hasMultipleImages"
                                    type="button"
                                    class="hero-slider__nav hero-slider__nav--next"
                                    aria-label="Gambar berikutnya"
                                    @click="nextImage"
                                >
                                    ›
                                </button>
                            </div>
                            <div v-if="hasMultipleImages" class="hero-slider__dots">
                                <button
                                    v-for="(image, index) in galleryImages"
                                    :key="`${image}-${index}`"
                                    type="button"
                                    class="hero-slider__dot"
                                    :class="{ 'hero-slider__dot--active': index === activeIndex }"
                                    :aria-label="`Tampilkan gambar ${index + 1}`"
                                    @click="setActiveIndex(index)"
                                ></button>
                            </div>
                        </div>
                        <LuxuryBottlePlaceholder
                            v-else
                            :tilt-enabled="hero.meta_data?.bottle?.tilt_desktop && !isMobile"
                            :floating="hero.meta_data?.bottle?.floating_mobile && isMobile"
                            :name="product?.name || hero.title"
                            :brand-label="hero.meta_data?.bottle?.brand_label"
                            :show-glow="hero.meta_data?.bottle?.show_glow"
                            :show-shadow="hero.meta_data?.bottle?.show_shadow"
                            :show-liquid="hero.meta_data?.bottle?.show_liquid"
                            :show-label="hero.meta_data?.bottle?.show_label"
                            :appearance="hero.meta_data?.bottle"
                        />
                    </div>
                </div>
            </div>
        </div>

        <div v-if="showLightbox" class="hero-lightbox" @click.self="closeLightbox">
            <button type="button" class="hero-lightbox__close" aria-label="Tutup popup gambar" @click="closeLightbox">
                ×
            </button>
            <div class="hero-lightbox__dialog">
                <div class="hero-lightbox__media">
                    <button
                        v-if="hasMultipleImages"
                        type="button"
                        class="hero-slider__nav hero-slider__nav--prev"
                        aria-label="Gambar sebelumnya"
                        @click="prevImage"
                    >
                        ‹
                    </button>
                    <img :src="activeImage" :alt="product.name" class="hero-lightbox__image">
                    <button
                        v-if="hasMultipleImages"
                        type="button"
                        class="hero-slider__nav hero-slider__nav--next"
                        aria-label="Gambar berikutnya"
                        @click="nextImage"
                    >
                        ›
                    </button>
                </div>
                <div v-if="hasMultipleImages" class="hero-slider__dots hero-slider__dots--lightbox">
                    <button
                        v-for="(image, index) in galleryImages"
                        :key="`lightbox-${image}-${index}`"
                        type="button"
                        class="hero-slider__dot"
                        :class="{ 'hero-slider__dot--active': index === activeIndex }"
                        :aria-label="`Tampilkan gambar ${index + 1}`"
                        @click="setActiveIndex(index)"
                    ></button>
                </div>
            </div>
        </div>
    </section>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import LuxuryBottlePlaceholder from './LuxuryBottlePlaceholder.vue';

defineEmits(['click-wa', 'share', 'open-buy-options']);

const props = defineProps({
    hero: { type: Object, default: null },
    product: { type: Object, default: null },
    isMobile: { type: Boolean, default: false },
    socialHub: { type: Object, default: () => ({}) },
});

const hasMarketplaceLinks = computed(() => Boolean(props.socialHub?.tokopedia_url || props.socialHub?.tiktok_shop_url));
const galleryImages = computed(() => {
    const images = props.product?.images?.filter(Boolean) ?? [];
    if (images.length) {
        return images;
    }

    return props.product?.image_url ? [props.product.image_url] : [];
});
const activeIndex = ref(0);
const bottleImageUrl = computed(() => props.hero?.meta_data?.bottle?.image_url || props.product?.bottle_image_url || '');
const shouldUseBottleImage = computed(() => Boolean(bottleImageUrl.value));
const shouldUseProductImage = computed(() => Boolean(galleryImages.value.length && props.hero?.meta_data?.bottle?.use_product_image_when_available));
const hasMultipleImages = computed(() => galleryImages.value.length > 1);
const activeImage = computed(() => galleryImages.value[activeIndex.value] ?? props.product?.image_url ?? '');
const showLightbox = ref(false);
const stockText = computed(() => {
    if (!props.product) {
        return props.hero?.meta_data?.stock_preorder_label;
    }

    if (props.product.stock > 0) {
        return `${props.product.stock} ${props.hero?.meta_data?.stock_ready_suffix}`;
    }

    return props.hero?.meta_data?.stock_preorder_label;
});

const formatCurrency = (value) => new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    maximumFractionDigits: 0,
}).format(value || 0);

const setActiveIndex = (index) => {
    if (!galleryImages.value.length) return;
    activeIndex.value = index < 0
        ? galleryImages.value.length - 1
        : index % galleryImages.value.length;
};

const prevImage = () => {
    setActiveIndex(activeIndex.value - 1);
};

const nextImage = () => {
    setActiveIndex(activeIndex.value + 1);
};

const openLightbox = () => {
    if (!activeImage.value) return;
    showLightbox.value = true;
    stopAutoplay();
};

const closeLightbox = () => {
    showLightbox.value = false;
    startAutoplay();
};

const handleKeydown = (event) => {
    if (!showLightbox.value) return;

    if (event.key === 'Escape') {
        closeLightbox();
        return;
    }

    if (event.key === 'ArrowLeft') {
        prevImage();
        return;
    }

    if (event.key === 'ArrowRight') {
        nextImage();
    }
};

let autoplayId = null;

const startAutoplay = () => {
    if (typeof window === 'undefined' || !hasMultipleImages.value) return;
    stopAutoplay();
    autoplayId = window.setInterval(() => {
        nextImage();
    }, 4000);
};

const stopAutoplay = () => {
    if (autoplayId) {
        window.clearInterval(autoplayId);
        autoplayId = null;
    }
};

watch(galleryImages, () => {
    activeIndex.value = 0;
    startAutoplay();
}, { immediate: true });

onMounted(() => {
    startAutoplay();
    if (typeof window !== 'undefined') {
        window.addEventListener('keydown', handleKeydown);
    }
});

onBeforeUnmount(() => {
    stopAutoplay();
    if (typeof window !== 'undefined') {
        window.removeEventListener('keydown', handleKeydown);
    }
});
</script>

<style scoped>
.hero-slider {
    position: relative;
}

.hero-slider__image-button {
    display: block;
    width: 100%;
    padding: 0;
    border: 0;
    background: transparent;
    cursor: zoom-in;
}

.hero-slider__nav {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    width: 2.4rem;
    height: 2.4rem;
    border: 0;
    border-radius: 999px;
    background: rgba(17, 24, 39, 0.68);
    color: #fff;
    font-size: 1.6rem;
    line-height: 1;
    z-index: 2;
}

.hero-slider__nav--prev {
    left: 0.9rem;
}

.hero-slider__nav--next {
    right: 0.9rem;
}

.hero-slider__dots {
    display: flex;
    justify-content: center;
    gap: 0.45rem;
    margin-top: 0.9rem;
}

.hero-slider__dot {
    width: 0.7rem;
    height: 0.7rem;
    border: 0;
    border-radius: 999px;
    background: rgba(17, 24, 39, 0.2);
}

.hero-slider__dot--active {
    background: var(--landing-accent, #c18b2f);
}

.hero-lightbox {
    position: fixed;
    inset: 0;
    z-index: 95;
    display: grid;
    place-items: center;
    padding: 1.5rem;
    background: rgba(4, 4, 4, 0.88);
    backdrop-filter: blur(12px);
}

.hero-lightbox__close {
    position: absolute;
    top: 1.2rem;
    right: 1.2rem;
    width: 2.8rem;
    height: 2.8rem;
    border: 0;
    border-radius: 999px;
    background: rgba(255, 255, 255, 0.08);
    color: #fff;
    font-size: 2rem;
    line-height: 1;
}

.hero-lightbox__dialog {
    width: min(100%, 980px);
}

.hero-lightbox__media {
    position: relative;
    padding: 1rem;
    border-radius: 1.8rem;
    border: 1px solid rgba(212, 175, 55, 0.18);
    background: linear-gradient(180deg, rgba(255,255,255,.05), rgba(255,255,255,.02));
    box-shadow: 0 30px 80px rgba(0, 0, 0, 0.32);
}

.hero-lightbox__image {
    display: block;
    width: 100%;
    max-height: calc(100vh - 11rem);
    object-fit: contain;
    border-radius: 1.25rem;
}

.hero-slider__dots--lightbox {
    margin-top: 1rem;
}
</style>
