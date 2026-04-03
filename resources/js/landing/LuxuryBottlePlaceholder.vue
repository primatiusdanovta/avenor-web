<template>
    <div ref="bottleRef" class="luxury-bottle" :class="{ 'luxury-bottle--floating': floating }" :style="bottleStyles">
        <div v-if="showGlow" class="luxury-bottle__glow"></div>
        <div v-if="showShadow" class="luxury-bottle__shadow"></div>
        <img v-if="imageSrc" :src="imageSrc" :alt="name" class="luxury-bottle__image">
        <template v-else>
            <div class="luxury-bottle__cap"></div>
            <div class="luxury-bottle__neck"></div>
            <div class="luxury-bottle__body">
                <div class="luxury-bottle__highlight luxury-bottle__highlight--left"></div>
                <div class="luxury-bottle__highlight luxury-bottle__highlight--right"></div>
                <div v-if="showLiquid" class="luxury-bottle__liquid"></div>
                <div v-if="showLabel" class="luxury-bottle__label">
                    <span class="luxury-bottle__label-mark">{{ displayBrandLabel }}</span>
                    <span class="luxury-bottle__label-name">{{ shortName }}</span>
                </div>
            </div>
        </template>
    </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';

const props = defineProps({
    floating: { type: Boolean, default: false },
    tiltEnabled: { type: Boolean, default: true },
    name: { type: String, default: 'Nocturne' },
    imageSrc: { type: String, default: '' },
    brandLabel: { type: String, default: 'AVENOR' },
    showGlow: { type: Boolean, default: true },
    showShadow: { type: Boolean, default: true },
    showLiquid: { type: Boolean, default: true },
    showLabel: { type: Boolean, default: true },
    appearance: { type: Object, default: () => ({}) },
});

const bottleRef = ref(null);
const shortName = computed(() => String(props.name || 'Nocturne').split(' ')[0]);
const displayBrandLabel = computed(() => props.brandLabel || 'AVENOR');
const bottleStyles = computed(() => ({
    '--bottle-cap-top': props.appearance?.cap_top || '#f3e5b0',
    '--bottle-cap-middle': props.appearance?.cap_middle || '#d4af37',
    '--bottle-cap-bottom': props.appearance?.cap_bottom || '#8d6a1f',
    '--bottle-liquid-from': props.appearance?.liquid_from || 'rgba(241,215,122,.12)',
    '--bottle-liquid-to': props.appearance?.liquid_to || 'rgba(212,175,55,.52)',
    '--bottle-label-background': props.appearance?.label_background || 'rgba(10,10,10,.34)',
    '--bottle-label-border': props.appearance?.label_border || 'rgba(212,175,55,.18)',
}));
let handlePointerMove = null;
let handlePointerLeave = null;

onMounted(() => {
    if (!props.tiltEnabled || !bottleRef.value) {
        return;
    }

    handlePointerMove = (event) => {
        const bounds = bottleRef.value.getBoundingClientRect();
        const centerX = bounds.left + bounds.width / 2;
        const centerY = bounds.top + bounds.height / 2;
        const rotateY = ((event.clientX - centerX) / bounds.width) * 18;
        const rotateX = ((centerY - event.clientY) / bounds.height) * 14;

        bottleRef.value.style.transform = `perspective(1200px) rotateX(${rotateX.toFixed(2)}deg) rotateY(${rotateY.toFixed(2)}deg) translateZ(0)`;
    };

    handlePointerLeave = () => {
        if (bottleRef.value) {
            bottleRef.value.style.transform = 'perspective(1200px) rotateX(0deg) rotateY(0deg) translateZ(0)';
        }
    };

    window.addEventListener('pointermove', handlePointerMove, { passive: true });
    window.addEventListener('pointerleave', handlePointerLeave);
});

onBeforeUnmount(() => {
    if (handlePointerMove) {
        window.removeEventListener('pointermove', handlePointerMove);
    }

    if (handlePointerLeave) {
        window.removeEventListener('pointerleave', handlePointerLeave);
    }
});
</script>
