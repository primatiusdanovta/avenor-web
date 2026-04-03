<template>
    <div class="landing-root articles-root" :style="themeVars">
        <div class="landing-noise"></div>
        <Navbar page-type="articles" :social-hub="socialHub" />

        <section class="section-shell article-section">
            <div class="container">
                <div class="article-stack">
                    <article
                        v-for="(card, index) in articlePage.cards"
                        :key="`${card.slug}-${index}`"
                        class="article-card"
                        tabindex="0"
                        role="link"
                        @click="goTo(card.url)"
                        @keydown.enter.prevent="goTo(card.url)"
                        @keydown.space.prevent="goTo(card.url)"
                    >
                        <a :href="card.url" class="article-card__media" @click.stop>
                            <img v-if="card.image_url" :src="card.image_url" :alt="card.title" class="article-card__image">
                            <div v-else class="article-card__placeholder">
                                <span>{{ card.title }}</span>
                            </div>
                        </a>
                        <div class="article-card__body">
                            <div class="article-card__meta">
                                <span>{{ card.author || 'Avenor Team' }}</span>
                                <span class="article-card__meta-dot"></span>
                                <span>{{ card.published_at || '-' }}</span>
                            </div>
                            <h2 class="article-card__title">
                                <a :href="card.url">{{ card.title }}</a>
                            </h2>
                            <p class="article-card__excerpt">{{ card.excerpt }}</p>
                            <a :href="card.url" class="article-card__link">Read Article</a>
                        </div>
                    </article>
                </div>

                <div class="article-pagination">
                    <div class="article-pagination__summary">
                        {{ paginationSummary }}
                    </div>
                    <div class="article-pagination__controls">
                        <a
                            class="article-pagination__button"
                            :class="{ 'article-pagination__button--disabled': !articlePage.pagination?.prev_page_url }"
                            :href="articlePage.pagination?.prev_page_url || '#'"
                            @click.prevent="goTo(articlePage.pagination?.prev_page_url)"
                        >Prev</a>
                        <div class="article-pagination__page">
                            Page {{ articlePage.pagination?.current_page || 1 }} / {{ articlePage.pagination?.last_page || 1 }}
                        </div>
                        <a
                            class="article-pagination__button"
                            :class="{ 'article-pagination__button--disabled': !articlePage.pagination?.next_page_url }"
                            :href="articlePage.pagination?.next_page_url || '#'"
                            @click.prevent="goTo(articlePage.pagination?.next_page_url)"
                        >Next</a>
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
    : { social_hub: {}, articles_page: {} };

const socialHub = computed(() => initialContent.social_hub || {});
const articlePage = computed(() => initialContent.articles_page || { cards: [], pagination: {} });
const themeVars = computed(() => ({
    '--landing-background': socialHub.value?.product_page?.theme_presets?.signature?.background || '',
    '--landing-accent': socialHub.value?.product_page?.theme_presets?.signature?.accent || '#d4af37',
    '--landing-accent-soft': socialHub.value?.product_page?.theme_presets?.signature?.accentSoft || '#f1d77a',
    '--landing-accent-deep': socialHub.value?.product_page?.theme_presets?.signature?.accentDeep || '#8d6a1f',
    '--landing-halo': socialHub.value?.product_page?.theme_presets?.signature?.halo || 'rgba(212, 175, 55, 0.32)',
}));

const paginationSummary = computed(() => {
    const from = articlePage.value.pagination?.from;
    const to = articlePage.value.pagination?.to;
    const total = articlePage.value.pagination?.total;

    if (!from || !to || !total) {
        return articlePage.value.cards?.length ? `${articlePage.value.cards.length} articles` : 'No articles yet';
    }

    return `${from}-${to} dari ${total} article`;
});

const goTo = (url) => {
    if (!url || typeof window === 'undefined') {
        return;
    }

    window.location.href = url;
};
</script>

<style scoped>
.article-section {
    padding-top: 7.5rem;
}

.article-stack {
    display: grid;
    gap: 1.5rem;
}

.article-card {
    display: grid;
    grid-template-columns: minmax(220px, 320px) 1fr;
    align-items: stretch;
    gap: 1.5rem;
    padding: 1.25rem;
    border: 1px solid rgba(212, 175, 55, 0.16);
    border-radius: 1.8rem;
    background:
        linear-gradient(135deg, rgba(255, 255, 255, 0.05), rgba(255, 255, 255, 0.02)),
        radial-gradient(circle at top right, rgba(212, 175, 55, 0.12), transparent 34%);
    box-shadow: 0 24px 60px rgba(0, 0, 0, 0.18);
    backdrop-filter: blur(16px);
    cursor: pointer;
    transition: transform 0.25s ease, border-color 0.25s ease, box-shadow 0.25s ease;
}

.article-card:hover,
.article-card:focus-visible {
    transform: translateY(-4px);
    border-color: rgba(212, 175, 55, 0.28);
    box-shadow: 0 28px 70px rgba(0, 0, 0, 0.24);
    outline: none;
}

.article-card__media {
    display: block;
    overflow: hidden;
    min-height: 240px;
    border-radius: 1.25rem;
    background: rgba(255, 255, 255, 0.04);
}

.article-card__image {
    width: 100%;
    height: 100%;
    min-height: 220px;
    object-fit: cover;
    transition: transform 0.45s ease;
}

.article-card__placeholder {
    display: grid;
    place-items: center;
    width: 100%;
    min-height: 240px;
    padding: 1.5rem;
    text-align: center;
    color: var(--landing-accent-soft, #f1d77a);
    font-family: 'Playfair Display', serif;
    font-size: clamp(1.4rem, 2.3vw, 1.9rem);
    background:
        radial-gradient(circle at top right, rgba(212, 175, 55, 0.12), transparent 35%),
        linear-gradient(180deg, rgba(255, 255, 255, 0.04), rgba(255, 255, 255, 0.02));
}

.article-card:hover .article-card__image {
    transform: scale(1.04);
}

.article-card__body {
    display: flex;
    flex-direction: column;
    justify-content: center;
    min-width: 0;
    padding-right: 0.5rem;
}

.article-card__meta {
    display: inline-flex;
    align-items: center;
    gap: 0.65rem;
    margin-bottom: 0.9rem;
    font-size: 0.84rem;
    letter-spacing: 0.06em;
    text-transform: uppercase;
    color: rgba(248, 241, 220, 0.7);
}

.article-card__meta-dot {
    width: 4px;
    height: 4px;
    border-radius: 999px;
    background: var(--landing-accent, #d4af37);
}

.article-card__title {
    margin-bottom: 0.8rem;
    font-size: clamp(1.5rem, 3vw, 2.2rem);
    line-height: 1.1;
    color: #f8f1dc;
}

.article-card__title a,
.article-card__link {
    color: inherit;
    text-decoration: none;
}

.article-card__excerpt {
    max-width: 60ch;
    margin-bottom: 1.25rem;
    color: rgba(248, 241, 220, 0.82);
}

.article-card__link {
    display: inline-flex;
    align-items: center;
    gap: 0.45rem;
    font-weight: 600;
    color: var(--landing-accent-soft, #f1d77a);
}

.article-pagination {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 1rem;
    margin-top: 2rem;
    padding: 1.2rem 1.4rem;
    border-radius: 1.4rem;
    border: 1px solid rgba(212, 175, 55, 0.14);
    background: rgba(255, 255, 255, 0.03);
}

.article-pagination__summary {
    color: rgba(248, 241, 220, 0.74);
}

.article-pagination__controls {
    display: inline-flex;
    align-items: center;
    gap: 0.75rem;
}

.article-pagination__button,
.article-pagination__page {
    padding: 0.7rem 1rem;
    border-radius: 999px;
    text-decoration: none;
}

.article-pagination__button {
    border: 1px solid rgba(212, 175, 55, 0.2);
    color: #f8f1dc;
}

.article-pagination__button--disabled {
    pointer-events: none;
    opacity: 0.45;
}

.article-pagination__page {
    background: rgba(255, 255, 255, 0.05);
    color: rgba(248, 241, 220, 0.72);
}

@media (max-width: 991.98px) {
    .article-card {
        grid-template-columns: 1fr;
    }

    .article-pagination {
        flex-direction: column;
        align-items: stretch;
    }

    .article-pagination__controls {
        justify-content: space-between;
    }
}

@media (max-width: 767.98px) {
    .article-section {
        padding-top: 6.5rem;
    }
}
</style>
