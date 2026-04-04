<template>
    <div class="landing-root article-detail-root" :style="themeVars">
        <div class="landing-noise"></div>
        <Navbar page-type="article" :social-hub="socialHub" />

        <section class="section-shell article-detail-section">
            <div class="container">
                <div class="article-detail">
                    <div class="section-heading text-center mx-auto">
                        <div class="hero-kicker">Article</div>
                        <h1 class="hero-title">{{ article.title }}</h1>
                        <p class="hero-description">{{ article.excerpt }}</p>
                        <div class="article-detail__meta">
                            <span>{{ article.author || 'Avenor Team' }}</span>
                            <span class="article-detail__meta-dot"></span>
                            <span>{{ article.published_at || '-' }}</span>
                        </div>
                    </div>

                    <div class="article-detail__media">
                        <img v-if="article.image_url" :src="article.image_url" :alt="article.title" class="article-detail__image">
                        <div v-else class="article-detail__placeholder">
                            <span>{{ article.title }}</span>
                        </div>
                    </div>

                    <article class="article-detail__body" v-html="bodyHtml"></article>

                    <div class="article-detail__back">
                        <a href="/articles" class="btn btn-luxury-primary btn-lg">Back to Articles</a>
                    </div>
                </div>
            </div>
        </section>

        <MainFooter :social-hub="socialHub" />
    </div>
</template>

<script setup>
import { computed } from 'vue';
import MainFooter from './MainFooter.vue';
import Navbar from './Navbar.vue';

const initialContent = typeof window !== 'undefined' && window.AVENOR_LANDING_INITIAL_STATE
    ? window.AVENOR_LANDING_INITIAL_STATE
    : { social_hub: {}, article: {} };

const socialHub = computed(() => initialContent.social_hub || {});
const article = computed(() => initialContent.article || {});
const bodyHtml = computed(() => article.value.body_html || '');
const themeVars = computed(() => ({
    '--landing-background': socialHub.value?.product_page?.theme_presets?.signature?.background || '',
    '--landing-accent': socialHub.value?.product_page?.theme_presets?.signature?.accent || '#d4af37',
    '--landing-accent-soft': socialHub.value?.product_page?.theme_presets?.signature?.accentSoft || '#f1d77a',
    '--landing-accent-deep': socialHub.value?.product_page?.theme_presets?.signature?.accentDeep || '#8d6a1f',
    '--landing-halo': socialHub.value?.product_page?.theme_presets?.signature?.halo || 'rgba(212, 175, 55, 0.32)',
}));
</script>

<style scoped>
.article-detail-section {
    padding-top: 7.5rem;
}

.article-detail {
    display: grid;
    gap: 1.75rem;
    width: min(100%, 1140px);
    margin: 0 auto;
}

.hero-title {
    color: #f8f1dc;
}

.article-detail__meta {
    display: inline-flex;
    align-items: center;
    gap: 0.65rem;
    margin-top: 1rem;
    color: rgba(248, 241, 220, 0.72);
    text-transform: uppercase;
    letter-spacing: 0.08em;
    font-size: 0.84rem;
}

.article-detail__meta-dot {
    width: 4px;
    height: 4px;
    border-radius: 999px;
    background: var(--landing-accent, #d4af37);
}

.article-detail__media {
    width: min(100%, 1140px);
    margin: 0 auto;
    overflow: hidden;
    border-radius: 2rem;
    border: 1px solid rgba(212, 175, 55, 0.16);
    box-shadow: 0 30px 80px rgba(0, 0, 0, 0.2);
    min-height: 260px;
}

.article-detail__image {
    width: 100%;
    height: min(34vw, 360px);
    min-height: 260px;
    max-height: 360px;
    object-fit: cover;
}

.article-detail__placeholder {
    display: grid;
    place-items: center;
    min-height: 320px;
    padding: 2rem;
    text-align: center;
    color: var(--landing-accent-soft, #f1d77a);
    font-family: 'Playfair Display', serif;
    font-size: clamp(1.6rem, 3vw, 2.6rem);
    background:
        radial-gradient(circle at top right, rgba(212, 175, 55, 0.12), transparent 35%),
        linear-gradient(180deg, rgba(255, 255, 255, 0.04), rgba(255, 255, 255, 0.02));
}

.article-detail__body {
    width: min(100%, 1140px);
    margin: 0 auto;
    padding: 2.5rem 2.75rem;
    border-radius: 1.8rem;
    border: 1px solid rgba(212, 175, 55, 0.14);
    background:
        linear-gradient(180deg, rgba(255, 255, 255, 0.04), rgba(255, 255, 255, 0.02)),
        rgba(255, 255, 255, 0.02);
    box-shadow: 0 24px 60px rgba(0, 0, 0, 0.16);
}

.article-detail__body :deep(p),
.article-detail__body :deep(li) {
    margin: 0 0 1.2rem;
    color: rgba(248, 241, 220, 0.84);
    line-height: 1.9;
    font-size: 1.04rem;
}

.article-detail__body :deep(h1),
.article-detail__body :deep(h2),
.article-detail__body :deep(h3) {
    margin: 0 0 1rem;
    color: #f8f1dc;
}

.article-detail__body :deep(ul),
.article-detail__body :deep(ol) {
    margin: 0 0 1.4rem 1.3rem;
    color: rgba(248, 241, 220, 0.84);
}

.article-detail__back {
    display: flex;
    justify-content: center;
}

@media (max-width: 767.98px) {
    .article-detail-section {
        padding-top: 6.5rem;
    }

    .article-detail__image {
        height: 240px;
        min-height: 240px;
    }

    .article-detail__body {
        padding: 1.4rem;
    }
}
</style>
