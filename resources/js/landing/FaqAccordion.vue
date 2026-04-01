<template>
    <section v-if="items.length" id="faq-block" class="faq-block section-shell">
        <div class="container">
            <div class="section-heading text-center mx-auto">
                <div class="section-kicker">{{ faqContent?.kicker }}</div>
                <h2 class="section-title">{{ faqContent?.title }}</h2>
                <p class="section-description">{{ faqContent?.description }}</p>
            </div>

            <div class="faq-list">
                <article v-for="(item, index) in items" :key="`${index}-${item.question}`" class="faq-item" :class="{ 'faq-item--open': openIndex === index }">
                    <button type="button" class="faq-item__trigger" @click="toggle(index)">
                        <span>{{ item.question }}</span>
                        <span class="faq-item__icon">{{ openIndex === index ? '-' : '+' }}</span>
                    </button>
                    <div v-if="openIndex === index" class="faq-item__body">
                        {{ item.answer }}
                    </div>
                </article>
            </div>
        </div>
    </section>
</template>

<script setup>
import { ref } from 'vue';

defineProps({
    items: { type: Array, default: () => [] },
    faqContent: { type: Object, default: () => ({}) },
});

const openIndex = ref(0);
const toggle = (index) => {
    openIndex.value = openIndex.value === index ? -1 : index;
};
</script>
