<template>
    <section v-if="story?.is_active || notes.length" id="notes-journey" ref="rootRef" class="notes-journey section-shell">
        <div class="container">
            <div class="section-heading text-center mx-auto">
                <div class="section-kicker">{{ story?.meta_data?.kicker }}</div>
                <h2 class="section-title">{{ story?.title }}</h2>
                <p class="section-description">{{ story?.description }}</p>
            </div>
        </div>

        <div class="container-fluid px-0">
            <div class="notes-journey__desktop d-none d-lg-block">
                <div class="container">
                    <div class="notes-journey__pin-wrap">
                        <div class="row align-items-center">
                            <div class="col-lg-6">
                                <div class="journey-stage-copy">
                                    <article v-for="(note, index) in activeNotes" :key="note.section_name" :ref="(element) => setDesktopStage(element, index)" class="journey-stage-card">
                                        <div class="journey-stage-index">0{{ index + 1 }}</div>
                                        <h3>{{ note.title }}</h3>
                                        <p>{{ note.description }}</p>
                                    </article>
                                </div>
                            </div>
                            <div class="col-lg-6">
                                <div class="journey-bottle-frame">
                                    <LuxuryBottlePlaceholder
                                        :name="fallbackBottleName"
                                        :tilt-enabled="story?.meta_data?.bottle?.tilt_desktop"
                                        :brand-label="story?.meta_data?.bottle?.brand_label"
                                        :show-glow="story?.meta_data?.bottle?.show_glow"
                                        :show-shadow="story?.meta_data?.bottle?.show_shadow"
                                        :show-liquid="story?.meta_data?.bottle?.show_liquid"
                                        :show-label="story?.meta_data?.bottle?.show_label"
                                        :appearance="story?.meta_data?.bottle"
                                    />
                                    <div v-for="(note, index) in activeNotes" :key="`${note.section_name}-halo`" :ref="(element) => setDesktopHalo(element, index)" class="journey-halo"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="notes-journey__mobile d-lg-none">
                <div class="container">
                    <div class="journey-mobile-bottle mb-4">
                        <LuxuryBottlePlaceholder
                            :floating="story?.meta_data?.bottle?.floating_mobile"
                            :tilt-enabled="false"
                            :name="fallbackBottleName"
                            :brand-label="story?.meta_data?.bottle?.brand_label"
                            :show-glow="story?.meta_data?.bottle?.show_glow"
                            :show-shadow="story?.meta_data?.bottle?.show_shadow"
                            :show-liquid="story?.meta_data?.bottle?.show_liquid"
                            :show-label="story?.meta_data?.bottle?.show_label"
                            :appearance="story?.meta_data?.bottle"
                        />
                    </div>
                    <article v-for="(note, index) in activeNotes" :key="`${note.section_name}-mobile`" :ref="(element) => setMobileStage(element, index)" class="journey-stage-card journey-stage-card--mobile">
                        <div class="journey-stage-index">0{{ index + 1 }}</div>
                        <h3>{{ note.title }}</h3>
                        <p>{{ note.description }}</p>
                    </article>
                </div>
            </div>
        </div>
    </section>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import LuxuryBottlePlaceholder from './LuxuryBottlePlaceholder.vue';

const props = defineProps({
    story: { type: Object, default: null },
    notes: { type: Array, default: () => [] },
    productName: { type: String, default: '' },
});

const rootRef = ref(null);
const desktopStages = ref([]);
const desktopHalos = ref([]);
const mobileStages = ref([]);
let mediaContext = null;

const activeNotes = computed(() => props.notes.filter((note) => note?.is_active));
const fallbackBottleName = computed(() => props.story?.meta_data?.bottle_fallback_name || props.productName);
const setDesktopStage = (element, index) => { if (element) desktopStages.value[index] = element; };
const setDesktopHalo = (element, index) => { if (element) desktopHalos.value[index] = element; };
const setMobileStage = (element, index) => { if (element) mobileStages.value[index] = element; };

const destroyGsap = () => {
    if (mediaContext && typeof mediaContext.revert === 'function') {
        mediaContext.revert();
    }
    mediaContext = null;
};

const buildGsap = () => {
    destroyGsap();

    if (!rootRef.value || !window.gsap || !window.ScrollTrigger || !activeNotes.value.length) {
        return;
    }

    window.gsap.registerPlugin(window.ScrollTrigger);
    const mm = window.gsap.matchMedia();

    mm.add('(min-width: 769px)', () => {
        const stages = desktopStages.value.filter(Boolean);
        const halos = desktopHalos.value.filter(Boolean);
        window.gsap.set(stages, { autoAlpha: 0.18, y: 48 });
        window.gsap.set(halos, { autoAlpha: 0, scale: 0.86 });

        const timeline = window.gsap.timeline({
            scrollTrigger: {
                trigger: rootRef.value,
                start: 'top top',
                end: `+=${Math.max(activeNotes.value.length * 500, 1500)}`,
                pin: '.notes-journey__pin-wrap',
                scrub: 0.7,
            },
        });

        stages.forEach((stage, index) => {
            const halo = halos[index];
            timeline
                .to(stage, { autoAlpha: 1, y: 0, duration: 0.35 }, index)
                .to(halo, { autoAlpha: 0.92, scale: 1, duration: 0.35 }, index)
                .to(stage, { autoAlpha: index === stages.length - 1 ? 1 : 0.18, y: index === stages.length - 1 ? 0 : -18, duration: 0.28 }, index + 0.55)
                .to(halo, { autoAlpha: index === stages.length - 1 ? 0.92 : 0, scale: index === stages.length - 1 ? 1 : 1.14, duration: 0.28 }, index + 0.55);
        });
    });

    mm.add('(max-width: 768px)', () => {
        mobileStages.value.filter(Boolean).forEach((stage, index) => {
            window.gsap.fromTo(stage, {
                autoAlpha: 0,
                y: 40,
            }, {
                autoAlpha: 1,
                y: 0,
                duration: 0.7,
                ease: 'power2.out',
                scrollTrigger: {
                    trigger: stage,
                    start: 'top 82%',
                    end: 'bottom 40%',
                },
                delay: index * 0.04,
            });
        });
    });

    mediaContext = mm;
};

watch(activeNotes, async () => {
    await nextTick();
    buildGsap();
}, { deep: true });

onMounted(async () => {
    await nextTick();
    buildGsap();
});

onBeforeUnmount(() => {
    destroyGsap();
});
</script>
