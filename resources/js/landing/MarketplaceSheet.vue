<template>
    <div v-if="show" class="marketplace-sheet" @click.self="$emit('close')">
        <div class="marketplace-sheet__panel">
            <div class="marketplace-sheet__header">
                <h3>{{ labels?.title }}</h3>
                <button type="button" class="marketplace-sheet__close" @click="$emit('close')">x</button>
            </div>
            <div class="marketplace-sheet__actions">
                <a v-if="links?.tokopedia_url" class="marketplace-option marketplace-option--tokopedia" :href="links.tokopedia_url" target="_blank" rel="noopener" @click="$emit('select', 'tokopedia')">
                    <span class="marketplace-option__logo" aria-hidden="true">
                        <svg viewBox="0 0 64 64" role="img">
                            <path d="M15 24c1.8-5.8 7.1-10 13.3-10 4.5 0 8.7 2.2 11.2 5.8 1.7-1.3 3.9-2.1 6.2-2.1 5.7 0 10.3 4.6 10.3 10.3v16.5c0 5.6-4.5 10.1-10.1 10.1H18.1C12.5 54.6 8 50.1 8 44.5V28.4C8 22.7 12.4 18 18 18c1 0 2 .1 3 .4" fill="currentColor"></path>
                            <circle cx="27" cy="35" r="3.5" fill="#ffffff"></circle>
                            <circle cx="39" cy="35" r="3.5" fill="#ffffff"></circle>
                            <path d="M23 22.5c0-3.1 2.5-5.5 5.5-5.5s5.5 2.4 5.5 5.5" fill="none" stroke="#ffffff" stroke-width="3.5" stroke-linecap="round"></path>
                            <path d="M36 24.5c.7-1.7 2.3-2.8 4.2-2.8 2.5 0 4.5 2 4.5 4.5" fill="none" stroke="#ffffff" stroke-width="3" stroke-linecap="round"></path>
                        </svg>
                    </span>
                    <span>{{ labels?.tokopedia_label }}</span>
                </a>
                <a v-if="links?.tiktok_shop_url" class="marketplace-option marketplace-option--tiktok" :href="links.tiktok_shop_url" target="_blank" rel="noopener" @click="$emit('select', 'tiktok_shop')">
                    <span class="marketplace-option__logo" aria-hidden="true">
                        <svg viewBox="0 0 64 64" role="img">
                            <path d="M28 14h8.2c1.3 5.1 4.7 8.2 10.8 9.6v8.3c-3.1-.1-6.2-1-8.9-2.6v11.2c0 7.9-5.9 13.5-14 13.5-7.9 0-13.9-5.8-13.9-13.2 0-7 5.7-12.4 12.7-12.4 1.3 0 2.5.2 3.8.6v8.4a6.5 6.5 0 0 0-3.2-.8c-3 0-5.3 2.1-5.3 4.9 0 3 2.2 5.1 5.1 5.1 3.4 0 5.6-2.2 5.6-6.7V14Z" fill="#25f4ee"></path>
                            <path d="M31 11h8.2c1.3 5.1 4.7 8.2 10.8 9.6v8.3c-3.1-.1-6.2-1-8.9-2.6v11.2c0 7.9-5.9 13.5-14 13.5-7.9 0-13.9-5.8-13.9-13.2 0-7 5.7-12.4 12.7-12.4 1.3 0 2.5.2 3.8.6v8.4a6.5 6.5 0 0 0-3.2-.8c-3 0-5.3 2.1-5.3 4.9 0 3 2.2 5.1 5.1 5.1 3.4 0 5.6-2.2 5.6-6.7V11Z" fill="#fe2c55"></path>
                            <path d="M29.6 12.2h7c1.2 5 4.6 8.3 10.1 9.7v5.2a14.2 14.2 0 0 1-8.7-2.9V38c0 7.2-5.1 12.2-12.1 12.2-6.3 0-10.9-4.5-10.9-10.4 0-5.6 4.4-9.9 10.2-9.9.9 0 1.9.1 2.8.4v5.4a5.4 5.4 0 0 0-2.2-.5c-2.8 0-4.8 1.9-4.8 4.5 0 2.8 2 4.7 4.8 4.7 3.5 0 5.4-2.3 5.4-6.2V12.2Z" fill="#ffffff"></path>
                        </svg>
                    </span>
                    <span>{{ labels?.tiktok_shop_label }}</span>
                </a>
                <div v-if="!links?.tokopedia_url && !links?.tiktok_shop_url" class="text-muted text-center">
                    {{ labels?.empty_state }}
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
defineEmits(['close', 'select']);

defineProps({
    show: { type: Boolean, default: false },
    links: { type: Object, default: () => ({}) },
    labels: { type: Object, default: () => ({}) },
});
</script>
