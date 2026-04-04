<template>
    <div class="landing-root articles-root" :style="themeVars">
        <div class="landing-noise"></div>
        <Navbar page-type="articles" :social-hub="socialHub" />

        <section class="section-shell article-section">
            <div class="container">
                <div class="articles-hero">
                    <div class="articles-hero__copy">
                        <div class="hero-kicker">{{ hero.eyebrow || 'Journal' }}</div>
                        <h1 class="articles-hero__title">{{ hero.title || 'Stories that slow the scroll and deepen discovery.' }}</h1>
                        <p class="articles-hero__description">{{ hero.description || 'A curated line of articles about scent mood, ritual, and the details behind the Avenor atmosphere.' }}</p>
                    </div>
                    <div class="articles-hero__panel">
                        <div class="articles-hero__panel-label">Latest Issue</div>
                        <div class="articles-hero__panel-value">{{ articlePage.cards?.length || 0 }} articles</div>
                        <div class="articles-hero__panel-text">Editorial notes, fragrance rituals, and product discovery stories in one reading room.</div>
                        <div v-if="categorySpotlight.length" class="articles-hero__topics">
                            <div class="articles-hero__topics-label">Popular Topics</div>
                            <div class="articles-hero__topics-list">
                                <span v-for="topic in categorySpotlight" :key="topic" class="articles-hero__topic">{{ topic }}</span>
                            </div>
                        </div>
                    </div>
                </div>

                <article v-if="featuredCard" class="featured-article" @click="goTo(featuredCard.url)">
                    <a :href="featuredCard.url" class="featured-article__media" @click.stop>
                        <img v-if="featuredCard.image_url" :src="featuredCard.image_url" :alt="featuredCard.title" class="featured-article__image">
                    </a>
                    <div class="featured-article__body">
                        <div class="featured-article__badge">Featured Article</div>
                        <div class="featured-article__meta">
                            <span class="featured-article__category">{{ featuredCard.category || 'Journal' }}</span>
                            <span class="featured-article__meta-dot"></span>
                            <span>{{ featuredCard.author || 'Avenor Team' }}</span>
                            <span class="featured-article__meta-dot"></span>
                            <span>{{ featuredCard.published_at || '-' }}</span>
                        </div>
                        <h2 class="featured-article__title"><a :href="featuredCard.url">{{ featuredCard.title }}</a></h2>
                        <p class="featured-article__excerpt">{{ featuredCard.excerpt }}</p>
                        <a :href="featuredCard.url" class="featured-article__link">Read Full Story</a>
                    </div>
                </article>

                <div class="article-listing-shell">
                    <div class="article-listing-shell__header">
                        <div>
                            <div class="article-listing-shell__eyebrow">Latest Articles</div>
                            <h2 class="article-listing-shell__title">Fresh reads from the journal</h2>
                        </div>
                        <div class="article-listing-shell__summary">{{ paginationSummary }}</div>
                    </div>

                    <div class="article-stack">
                        <article
                            v-for="(card, index) in remainingCards"
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
                                    <span class="article-card__category">{{ card.category || 'Journal' }}</span>
                                    <span class="article-card__meta-dot"></span>
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
const articlePage = computed(() => initialContent.articles_page || { cards: [], pagination: {}, hero: {} });
const hero = computed(() => articlePage.value.hero || {});
const categorySpotlight = computed(() => articlePage.value.category_spotlight || []);
const featuredCard = computed(() => articlePage.value.cards?.[0] || null);
const remainingCards = computed(() => articlePage.value.cards?.slice(1) || []);
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

    return `${from}-${to} of ${total} articles`;
});

const goTo = (url) => {
    if (!url || typeof window === 'undefined') return;
    window.location.href = url;
};
</script>

<style scoped>
.article-section {
    padding-top: 7.5rem;
}

.articles-hero {
    display: grid;
    grid-template-columns: minmax(0, 1.5fr) minmax(260px, 0.8fr);
    gap: 1.5rem;
    align-items: stretch;
    margin-bottom: 2rem;
}

.articles-hero__copy,
.articles-hero__panel,
.featured-article,
.article-listing-shell,
.article-pagination {
    border: 1px solid rgba(212, 175, 55, 0.14);
    background:
        linear-gradient(135deg, rgba(255, 255, 255, 0.05), rgba(255, 255, 255, 0.02)),
        radial-gradient(circle at top right, rgba(212, 175, 55, 0.12), transparent 34%);
    box-shadow: 0 24px 60px rgba(0, 0, 0, 0.18);
    backdrop-filter: blur(16px);
}

.articles-hero__copy {
    padding: 2rem;
    border-radius: 2rem;
}

.articles-hero__title {
    margin: 0;
    color: #f8f1dc;
    font-size: clamp(2rem, 4vw, 3.8rem);
    line-height: 0.98;
}

.articles-hero__description {
    margin: 1rem 0 0;
    max-width: 62ch;
    color: rgba(248, 241, 220, 0.78);
    font-size: 1.02rem;
    line-height: 1.8;
}

.articles-hero__panel {
    display: grid;
    align-content: center;
    gap: 0.8rem;
    padding: 1.7rem;
    border-radius: 1.8rem;
}

.articles-hero__panel-label,
.article-listing-shell__eyebrow,
.featured-article__badge {
    font-size: 0.76rem;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--landing-accent-soft, #f1d77a);
}

.articles-hero__panel-value {
    font-size: clamp(1.8rem, 3vw, 2.8rem);
    line-height: 1;
    color: #f8f1dc;
    font-family: 'Playfair Display', serif;
}

.articles-hero__panel-text,
.article-listing-shell__summary {
    color: rgba(248, 241, 220, 0.72);
    line-height: 1.7;
}

.articles-hero__topics {
    display: grid;
    gap: 0.7rem;
    margin-top: 0.3rem;
}

.articles-hero__topics-label {
    color: rgba(248, 241, 220, 0.6);
    font-size: 0.75rem;
    letter-spacing: 0.14em;
    text-transform: uppercase;
}

.articles-hero__topics-list {
    display: flex;
    flex-wrap: wrap;
    gap: 0.55rem;
}

.articles-hero__topic {
    display: inline-flex;
    align-items: center;
    padding: 0.38rem 0.75rem;
    border-radius: 999px;
    background: rgba(255, 255, 255, 0.07);
    border: 1px solid rgba(212, 175, 55, 0.18);
    color: var(--landing-accent-soft, #f1d77a);
    font-size: 0.78rem;
    letter-spacing: 0.04em;
}

.featured-article {
    display: grid;
    grid-template-columns: 220px minmax(0, 1fr);
    gap: 1rem;
    margin-bottom: 2rem;
    padding: 0.95rem;
    border-radius: 2rem;
    cursor: pointer;
}

.featured-article__media {
    display: block;
    overflow: hidden;
    align-self: start;
    border-radius: 1.5rem;
    background: rgba(255, 255, 255, 0.06);
}

.featured-article__image {
    width: 100%;
    height: auto;
    aspect-ratio: 1 / 1.18;
    max-height: 260px;
    object-fit: contain;
    object-position: center;
}

.featured-article__body {
    display: flex;
    flex-direction: column;
    justify-content: center;
    min-width: 0;
}

.featured-article__meta,
.article-card__meta {
    display: inline-flex;
    align-items: center;
    gap: 0.65rem;
    flex-wrap: wrap;
    color: rgba(248, 241, 220, 0.72);
    font-size: 0.82rem;
    letter-spacing: 0.06em;
    text-transform: uppercase;
}

.featured-article__meta {
    margin-top: 0.45rem;
}

.featured-article__meta-dot,
.article-card__meta-dot {
    width: 4px;
    height: 4px;
    border-radius: 999px;
    background: var(--landing-accent, #d4af37);
}

.featured-article__category,
.article-card__category {
    padding: 0.3rem 0.65rem;
    border-radius: 999px;
    background: rgba(212, 175, 55, 0.14);
    color: var(--landing-accent-soft, #f1d77a);
}

.featured-article__title {
    margin: 0.45rem 0;
    color: #f8f1dc;
    font-size: clamp(1.35rem, 2vw, 2rem);
    line-height: 1.08;
}

.featured-article__title a,
.featured-article__link,
.article-card__title a,
.article-card__link {
    color: inherit;
    text-decoration: none;
}

.featured-article__excerpt,
.article-card__excerpt {
    color: rgba(248, 241, 220, 0.82);
    line-height: 1.75;
}

.featured-article__excerpt {
    max-width: 58ch;
    margin-bottom: 0.65rem;
    font-size: 0.95rem;
    line-height: 1.65;
}

.featured-article__link,
.article-card__link {
    display: inline-flex;
    align-items: center;
    gap: 0.45rem;
    font-weight: 600;
    color: var(--landing-accent-soft, #f1d77a);
}

.article-listing-shell {
    padding: 1rem;
    border-radius: 1.8rem;
}

.article-listing-shell__header {
    display: flex;
    justify-content: space-between;
    align-items: end;
    gap: 1rem;
    margin-bottom: 1.25rem;
}

.article-listing-shell__title {
    margin: 0.3rem 0 0;
    color: #f8f1dc;
    font-size: clamp(1.3rem, 2.1vw, 2rem);
}

.article-stack {
    display: grid;
    gap: 0.7rem;
}

.article-card {
    display: grid;
    grid-template-columns: 96px minmax(0, 1fr);
    align-items: start;
    gap: 0.8rem;
    padding: 0.72rem;
    border-radius: 1.05rem;
    border: 1px solid rgba(212, 175, 55, 0.12);
    background: rgba(255, 255, 255, 0.03);
    cursor: pointer;
    transition: transform 0.2s ease, border-color 0.2s ease;
}

.article-card:hover,
.article-card:focus-visible {
    transform: translateY(-2px);
    border-color: rgba(212, 175, 55, 0.24);
    outline: none;
}

.article-card__media {
    display: block;
    overflow: hidden;
    align-self: start;
    border-radius: 0.9rem;
    background: rgba(255, 255, 255, 0.06);
}

.article-card__image {
    width: 100%;
    height: auto;
    aspect-ratio: 1 / 1.12;
    max-height: 108px;
    object-fit: contain;
    object-position: center;
}

.article-card__placeholder {
    display: grid;
    place-items: center;
    width: 100%;
    min-height: 108px;
    padding: 0.75rem;
    text-align: center;
    color: var(--landing-accent-soft, #f1d77a);
    font-family: 'Playfair Display', serif;
    font-size: clamp(0.88rem, 1.1vw, 1rem);
}

.article-card__body {
    display: flex;
    flex-direction: column;
    justify-content: center;
    min-width: 0;
}

.article-card__meta {
    margin-bottom: 0.35rem;
    font-size: 0.72rem;
    gap: 0.45rem;
}

.article-card__title {
    margin: 0 0 0.35rem;
    font-size: clamp(0.98rem, 1.15vw, 1.08rem);
    line-height: 1.18;
    color: #f8f1dc;
}

.article-card__excerpt {
    margin-bottom: 0.45rem;
    font-size: 0.88rem;
    line-height: 1.55;
}

.article-pagination {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 1rem;
    margin-top: 2rem;
    padding: 1.2rem 1.4rem;
    border-radius: 1.4rem;
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
    .articles-hero,
    .featured-article,
    .article-card {
        grid-template-columns: 1fr;
    }

    .article-listing-shell__header,
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

    .articles-hero {
        gap: 1rem;
        margin-bottom: 1.3rem;
    }

    .articles-hero__copy,
    .articles-hero__panel,
    .featured-article,
    .article-listing-shell,
    .article-pagination {
        border-radius: 1.3rem;
    }

    .articles-hero__copy,
    .articles-hero__panel,
    .featured-article,
    .article-listing-shell,
    .article-pagination {
        padding: 1rem;
    }

    .featured-article {
        gap: 1rem;
        margin-bottom: 1.3rem;
    }

    .featured-article__media {
        max-width: 220px;
    }

    .featured-article__image {
        max-height: 220px;
    }

    .featured-article__title {
        font-size: 1.35rem;
    }

    .article-card {
        gap: 0.8rem;
    }

    .article-card__media {
        max-width: 108px;
    }

    .article-card__image,
    .article-card__placeholder {
        min-height: 108px;
    }

    .article-pagination__controls {
        flex-direction: column;
        gap: 0.65rem;
    }

    .article-pagination__button,
    .article-pagination__page {
        width: 100%;
        text-align: center;
    }
}
</style>

