<template>
    <section v-if="intro?.is_active && activeIngredients.length" id="ingredients-bento" class="ingredients-bento section-shell">
        <div class="container">
            <div class="section-heading text-center mx-auto">
                <div class="section-kicker">{{ intro.meta_data?.kicker }}</div>
                <h2 class="section-title">{{ intro.title }}</h2>
                <p class="section-description">{{ intro.description }}</p>
            </div>

            <div class="row g-3 g-lg-4">
                <div v-for="ingredient in activeIngredients" :key="ingredient.id" class="col-12 col-md-6 col-xl-4">
                    <button type="button" class="ingredient-card" :class="{ 'ingredient-card--open': openId === ingredient.id }" @click="toggleCard(ingredient.id)">
                        <span class="ingredient-card__icon" v-html="iconMap[ingredient.meta_data?.icon] || iconMap.spark"></span>
                        <span class="ingredient-card__title-wrap">
                            <span class="ingredient-card__eyebrow">{{ intro.meta_data?.card_eyebrow }}</span>
                            <span class="ingredient-card__title">{{ ingredient.title }}</span>
                        </span>
                        <span class="ingredient-card__description">{{ ingredient.description }}</span>
                    </button>
                </div>
            </div>
        </div>
    </section>
</template>

<script setup>
import { computed, ref } from 'vue';

const props = defineProps({
    intro: { type: Object, default: null },
    ingredients: { type: Array, default: () => [] },
});

const openId = ref(null);
const toggleCard = (id) => {
    openId.value = openId.value === id ? null : id;
};
const activeIngredients = computed(() => props.ingredients.filter((ingredient) => ingredient?.is_active));
const iconMap = {
    spark: '<svg viewBox="0 0 64 64" aria-hidden="true"><path d="M32 6l6 18 18 6-18 6-6 18-6-18-18-6 18-6 6-18z"/></svg>',
    bloom: '<svg viewBox="0 0 64 64" aria-hidden="true"><path d="M32 13c3 8 9 11 17 10-1 9-6 15-17 17-11-2-16-8-17-17 8 1 14-2 17-10zm0 28c5 0 9 4 9 10H23c0-6 4-10 9-10z"/></svg>',
    wood: '<svg viewBox="0 0 64 64" aria-hidden="true"><path d="M14 49c12-21 24-31 36-34-5 10-7 20-6 30-12 4-22 5-30 4zm18-3c0-9 2-16 7-23"/></svg>',
    pepper: '<svg viewBox="0 0 64 64" aria-hidden="true"><path d="M37 12c8 0 14 6 14 14 0 13-10 26-21 26-8 0-13-5-13-12 0-12 9-28 20-28zm-1 7c2-3 5-5 9-5"/></svg>',
    amber: '<svg viewBox="0 0 64 64" aria-hidden="true"><path d="M24 10h16l9 16-17 28L15 26l9-16z"/></svg>',
    smoke: '<svg viewBox="0 0 64 64" aria-hidden="true"><path d="M23 52c0-8 7-9 7-17 0-5-4-8-4-13 0-6 4-9 8-11m6 41c0-6 5-8 5-14 0-4-3-6-3-10 0-5 4-8 7-10"/></svg>',
    citrus: '<svg viewBox="0 0 64 64" aria-hidden="true"><path d="M32 12c11 0 20 9 20 20S43 52 32 52 12 43 12 32s9-20 20-20zm0 0c0 11-8 20-20 20m20-20c0 11 8 20 20 20"/></svg>',
    leaf: '<svg viewBox="0 0 64 64" aria-hidden="true"><path d="M14 44C15 25 29 13 50 12 49 33 37 47 18 50m5-11c5 0 12-5 19-14"/></svg>',
};
</script>
