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
                        <div v-if="shouldUseProductImage" class="hero-visual-card">
                            <img :src="product.image_url" :alt="product.name" class="hero-product-image" loading="eager">
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
    </section>
</template>

<script setup>
import { computed } from 'vue';
import LuxuryBottlePlaceholder from './LuxuryBottlePlaceholder.vue';

defineEmits(['click-wa', 'share', 'open-buy-options']);

const props = defineProps({
    hero: { type: Object, default: null },
    product: { type: Object, default: null },
    isMobile: { type: Boolean, default: false },
    socialHub: { type: Object, default: () => ({}) },
});

const hasMarketplaceLinks = computed(() => Boolean(props.socialHub?.tokopedia_url || props.socialHub?.tiktok_shop_url));
const shouldUseProductImage = computed(() => Boolean(props.product?.image_url && props.hero?.meta_data?.bottle?.use_product_image_when_available));
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
</script>
