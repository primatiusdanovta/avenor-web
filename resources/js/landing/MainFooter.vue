<template>
    <footer id="main-footer" class="main-footer section-shell pb-5 pt-0">
        <div class="container">
            <div class="footer-card">
                <div>
                    <div class="section-kicker">{{ footerContent.eyebrow }}</div>
                    <h2 class="section-title mb-2">{{ footerContent.title }}</h2>
                    <p class="section-description mb-0">{{ footerContent.description }}</p>
                </div>
                <div class="footer-links">
                    <a v-if="socialHub?.instagram_url" :href="socialHub.instagram_url" target="_blank" rel="noopener">{{ footerContent.instagram_label }}</a>
                    <a v-if="socialHub?.tiktok_url" :href="socialHub.tiktok_url" target="_blank" rel="noopener">{{ footerContent.tiktok_label }}</a>
                    <a v-if="socialHub?.facebook_url" :href="socialHub.facebook_url" target="_blank" rel="noopener">{{ footerContent.facebook_label }}</a>
                    <a v-if="socialHub?.whatsapp_url" :href="socialHub.whatsapp_url" target="_blank" rel="noopener">{{ footerContent.whatsapp_label }}</a>
                </div>
            </div>
        </div>
    </footer>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
    socialHub: { type: Object, default: () => ({}) },
});

const footerContent = computed(() => ({
    eyebrow: props.socialHub?.master_page?.footer?.eyebrow,
    title: props.socialHub?.master_page?.footer?.title,
    description: props.socialHub?.master_page?.footer?.description,
    instagram_label: props.socialHub?.master_page?.footer?.instagram_label,
    tiktok_label: props.socialHub?.master_page?.footer?.tiktok_label,
    facebook_label: props.socialHub?.master_page?.footer?.facebook_label,
    whatsapp_label: props.socialHub?.master_page?.footer?.whatsapp_label,
}));
</script>

<style scoped>
.main-footer,
.main-footer .section-title,
.main-footer .section-description,
.main-footer .footer-links a {
    color: #f8f1dc;
}

.main-footer .section-description {
    color: rgba(248, 241, 220, 0.82);
}

.main-footer .footer-links a {
    border-bottom-color: rgba(212, 175, 55, 0.35);
}
</style>
