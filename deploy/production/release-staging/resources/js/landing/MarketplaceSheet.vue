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
                            <rect x="10" y="18" width="44" height="34" rx="10" fill="currentColor"></rect>
                            <path d="M21 24c0-6.1 4.9-11 11-11s11 4.9 11 11" fill="none" stroke="#ffffff" stroke-width="4" stroke-linecap="round"></path>
                            <circle cx="26" cy="34" r="3" fill="#ffffff"></circle>
                            <circle cx="38" cy="34" r="3" fill="#ffffff"></circle>
                        </svg>
                    </span>
                    <span>{{ labels?.tokopedia_label }}</span>
                </a>
                <a v-if="links?.tiktok_shop_url" class="marketplace-option marketplace-option--tiktok" :href="links.tiktok_shop_url" target="_blank" rel="noopener" @click="$emit('select', 'tiktok_shop')">
                    <span class="marketplace-option__logo" aria-hidden="true">
                        <svg viewBox="0 0 64 64" role="img">
                            <path d="M36 14c2 5.7 6.3 9.3 12 10.4v8.5c-3.9-.2-7.8-1.5-11-3.9V39c0 8-5.8 14-14 14s-14-6-14-13.6C9 31.8 15 26 22.6 26c1.4 0 2.8.2 4.1.7v8.8c-1-.8-2.3-1.2-3.8-1.2-3.4 0-6 2.3-6 5.4 0 3.2 2.5 5.5 5.8 5.5 3.6 0 5.7-2.4 5.7-7V14h7.6Z" fill="#25f4ee"></path>
                            <path d="M39 12c2 5.7 6.3 9.3 12 10.4v8.5c-3.9-.2-7.8-1.5-11-3.9V37c0 8-5.8 14-14 14s-14-6-14-13.6C12 29.8 18 24 25.6 24c1.4 0 2.8.2 4.1.7v8.8c-1-.8-2.3-1.2-3.8-1.2-3.4 0-6 2.3-6 5.4 0 3.2 2.5 5.5 5.8 5.5 3.6 0 5.7-2.4 5.7-7V12H39Z" fill="#fe2c55"></path>
                            <path d="M38 12c2 5.7 6.3 9.3 12 10.4v8.5c-3.9-.2-7.8-1.5-11-3.9V37c0 8-5.8 14-14 14s-14-6-14-13.6C11 29.8 17 24 24.6 24c1.4 0 2.8.2 4.1.7v8.8c-1-.8-2.3-1.2-3.8-1.2-3.4 0-6 2.3-6 5.4 0 3.2 2.5 5.5 5.8 5.5 3.6 0 5.7-2.4 5.7-7V12H38Z" fill="#ffffff"></path>
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
