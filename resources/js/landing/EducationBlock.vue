<template>
    <section v-if="shouldRender" id="education-block" class="education-block section-shell">
        <div class="container">
            <div class="section-heading text-center mx-auto">
                <div class="section-kicker">{{ education.meta_data?.kicker }}</div>
                <h2 class="section-title">{{ education.title }}</h2>
                <p class="section-description">{{ education.description }}</p>
            </div>

            <div v-if="tips.length" class="row g-3 g-lg-4 education-grid">
                <div v-for="(tip, index) in tips" :key="`${index}-${tip}`" class="col-12 col-md-6 col-xl-4">
                    <div class="education-card h-100">
                        <div class="education-card__eyebrow">{{ education.meta_data?.card_eyebrow }}</div>
                        <div class="education-tip__index mb-3">0{{ index + 1 }}</div>
                        <p class="mb-0">{{ tip }}</p>
                    </div>
                </div>
            </div>
        </div>
    </section>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
    education: { type: Object, default: null },
});

const tips = computed(() => props.education?.meta_data?.tips ?? []);
const shouldRender = computed(() => Boolean(
    props.education?.is_active
    && (props.education?.title || props.education?.description || tips.value.length)
));
</script>
