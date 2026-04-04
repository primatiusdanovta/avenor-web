<template>
    <div class="landing-root article-detail-root" :style="themeVars">
        <div class="landing-noise"></div>
        <Navbar page-type="article" :social-hub="socialHub" />

        <section class="section-shell article-detail-section">
            <div class="container">
                <div class="article-detail">
                    <div class="section-heading text-center mx-auto">
                        <div class="hero-kicker">Article</div>
                        <div class="article-detail__category">{{ article.category || 'Journal' }}</div>
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

                    <section v-if="relatedArticles.length" class="article-suggestions">
                        <div class="article-suggestions__header">
                            <div class="article-suggestions__eyebrow">{{ suggestionsEyebrow }}</div>
                            <h2 class="article-suggestions__title">{{ suggestionsTitle }}</h2>
                            <p class="article-suggestions__lead">{{ suggestionsLead }}</p>
                        </div>
                        <div class="article-suggestions__grid">
                            <article v-for="item in relatedArticles" :key="item.slug" class="article-suggestion-card" @click="goTo(item.url)">
                                <a :href="item.url" class="article-suggestion-card__media" @click.stop>
                                    <img v-if="item.image_url" :src="item.image_url" :alt="item.title" class="article-suggestion-card__image">
                                </a>
                                <div class="article-suggestion-card__body">
                                    <div class="article-suggestion-card__meta">
                                        <span class="article-suggestion-card__category">{{ item.category || 'Journal' }}</span>
                                        <span class="article-suggestion-card__meta-dot"></span>
                                        <span>{{ item.author || 'Avenor Team' }}</span>
                                        <span class="article-suggestion-card__meta-dot"></span>
                                        <span>{{ item.published_at || '-' }}</span>
                                    </div>
                                    <h3 class="article-suggestion-card__title"><a :href="item.url">{{ item.title }}</a></h3>
                                    <p class="article-suggestion-card__excerpt">{{ item.excerpt }}</p>
                                    <a :href="item.url" class="article-suggestion-card__link">Read Article</a>
                                </div>
                            </article>
                        </div>
                    </section>

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
    : { social_hub: {}, article: {}, related_articles: [] };

const socialHub = computed(() => initialContent.social_hub || {});
const article = computed(() => initialContent.article || {});
const relatedArticles = computed(() => initialContent.related_articles || []);
const bodyHtml = computed(() => article.value.body_html || '');
const suggestionsEyebrow = computed(() => article.value.category ? `More in ${article.value.category}` : 'Continue Reading');
const suggestionsTitle = computed(() => article.value.category ? `Explore more ${article.value.category.toLowerCase()} articles` : 'Suggested articles for your next read');
const suggestionsLead = computed(() => article.value.category
    ? 'Readers who enjoy this topic usually continue with stories from the same editorial lane before moving into newer journal entries.'
    : 'A few more reads selected to keep the journey going after this story.');
const themeVars = computed(() => ({
    '--landing-background': socialHub.value?.product_page?.theme_presets?.signature?.background || '',
    '--landing-accent': socialHub.value?.product_page?.theme_presets?.signature?.accent || '#d4af37',
    '--landing-accent-soft': socialHub.value?.product_page?.theme_presets?.signature?.accentSoft || '#f1d77a',
    '--landing-accent-deep': socialHub.value?.product_page?.theme_presets?.signature?.accentDeep || '#8d6a1f',
    '--landing-halo': socialHub.value?.product_page?.theme_presets?.signature?.halo || 'rgba(212, 175, 55, 0.32)',
}));

const goTo = (url) => {
    if (!url || typeof window === 'undefined') return;
    window.location.href = url;
};
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

.article-detail__category,
.article-suggestion-card__category {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 0.38rem 0.8rem;
    border-radius: 999px;
    background: rgba(212, 175, 55, 0.14);
    color: var(--landing-accent-soft, #f1d77a);
    font-size: 0.76rem;
    letter-spacing: 0.14em;
    text-transform: uppercase;
}

.article-detail__category {
    margin-top: 0.85rem;
}

.article-detail__meta,
.article-suggestion-card__meta {
    display: inline-flex;
    align-items: center;
    gap: 0.65rem;
    flex-wrap: wrap;
    color: rgba(248, 241, 220, 0.72);
    text-transform: uppercase;
    letter-spacing: 0.08em;
    font-size: 0.84rem;
}

.article-detail__meta {
    margin-top: 1rem;
}

.article-detail__meta-dot,
.article-suggestion-card__meta-dot {
    width: 4px;
    height: 4px;
    border-radius: 999px;
    background: var(--landing-accent, #d4af37);
}

.article-detail__media,
.article-detail__body,
.article-suggestions {
    border: 1px solid rgba(212, 175, 55, 0.14);
    background:
        linear-gradient(180deg, rgba(255, 255, 255, 0.04), rgba(255, 255, 255, 0.02)),
        rgba(255, 255, 255, 0.02);
    box-shadow: 0 24px 60px rgba(0, 0, 0, 0.16);
}

.article-detail__media {
    width: min(100%, 798px);
    margin: 0 auto;
    overflow: hidden;
    border-radius: 2rem;
    min-height: 182px;
    background-color: rgba(255, 255, 255, 0.06);
}

.article-detail__image {
    width: 100%;
    height: min(24vw, 252px);
    min-height: 182px;
    max-height: 252px;
    object-fit: contain;
    object-position: center;
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
}

.article-detail__body {
    width: min(100%, 1140px);
    margin: 0 auto;
    padding: 2.5rem 2.75rem;
    border-radius: 1.8rem;
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

.article-suggestions {
    padding: 1.5rem;
    border-radius: 1.8rem;
}

.article-suggestions__eyebrow {
    font-size: 0.76rem;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--landing-accent-soft, #f1d77a);
}

.article-suggestions__title {
    margin: 0.35rem 0 0;
    color: #f8f1dc;
    font-size: clamp(1.4rem, 2.3vw, 2.1rem);
}

.article-suggestions__lead {
    margin: 0.7rem 0 0;
    max-width: 66ch;
    color: rgba(248, 241, 220, 0.72);
    line-height: 1.75;
}

.article-suggestions__grid {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 1rem;
    margin-top: 1.2rem;
}

.article-suggestion-card {
    display: grid;
    gap: 0.9rem;
    padding: 0.95rem;
    border-radius: 1.25rem;
    border: 1px solid rgba(212, 175, 55, 0.12);
    background: rgba(255, 255, 255, 0.03);
    cursor: pointer;
}

.article-suggestion-card__media {
    display: block;
    overflow: hidden;
    min-height: 170px;
    border-radius: 1rem;
    background: rgba(255, 255, 255, 0.05);
}

.article-suggestion-card__image {
    width: 100%;
    height: 100%;
    min-height: 170px;
    object-fit: contain;
    object-position: center;
}

.article-suggestion-card__title {
    margin: 0.55rem 0;
    color: #f8f1dc;
    font-size: 1.15rem;
    line-height: 1.2;
}

.article-suggestion-card__title a,
.article-suggestion-card__link {
    color: inherit;
    text-decoration: none;
}

.article-suggestion-card__excerpt {
    margin-bottom: 0.85rem;
    color: rgba(248, 241, 220, 0.8);
    line-height: 1.7;
}

.article-suggestion-card__link {
    color: var(--landing-accent-soft, #f1d77a);
    font-weight: 600;
}

.article-detail__back {
    display: flex;
    justify-content: center;
}

@media (max-width: 991.98px) {
    .article-suggestions__grid {
        grid-template-columns: 1fr;
    }
}

@media (max-width: 767.98px) {
    .article-detail-section {
        padding-top: 6.5rem;
    }

    .article-detail {
        gap: 1.25rem;
    }

    .article-detail__meta {
        justify-content: center;
        gap: 0.45rem;
        margin-top: 0.75rem;
        font-size: 0.72rem;
    }

    .article-detail__media,
    .article-detail__body,
    .article-suggestions {
        border-radius: 1.25rem;
    }

    .article-detail__media {
        width: 100%;
        min-height: 168px;
    }

    .article-detail__image {
        height: 168px;
        min-height: 168px;
    }

    .article-detail__body,
    .article-suggestions {
        padding: 1.2rem;
    }

    .article-detail__body :deep(p),
    .article-detail__body :deep(li) {
        line-height: 1.75;
        font-size: 0.98rem;
    }

    .article-suggestion-card__media,
    .article-suggestion-card__image {
        min-height: 180px;
    }

    .article-detail__back {
        width: 100%;
    }

    .article-detail__back .btn {
        width: 100%;
    }
}
</style>

