<template>
    <div class="landing-root careers-root" :style="themeVars">
        <div class="landing-noise"></div>
        <Navbar page-type="carrers" :social-hub="socialHub" />

        <section class="section-shell">
            <div class="container">
                <div class="row g-4 mt-1">
                    <div v-for="(card, index) in careers.cards" :key="`${card.title}-${index}`" class="col-12 col-lg-6">
                        <article class="careers-card">
                            <div class="careers-card__eyebrow">Open Role</div>
                            <h3 class="careers-card__title">{{ card.title }}</h3>
                            <p class="careers-card__description">{{ card.description }}</p>
                            <button type="button" class="btn btn-luxury-primary btn-lg" @click="openApply(card)">
                                {{ card.button_label || careers.form?.submit_label || 'Apply' }}
                            </button>
                        </article>
                    </div>
                </div>
            </div>
        </section>

        <MainFooter :social-hub="socialHub" />

        <div v-if="showModal" class="career-modal" @click.self="closeModal">
            <div class="career-modal__panel">
                <button type="button" class="career-modal__close" @click="closeModal">&times;</button>
                <div class="section-kicker">{{ selectedCard?.title }}</div>
                <h3 class="career-modal__title">{{ formTitle }}</h3>
                <p class="career-modal__description">{{ careers.form?.description }}</p>

                <div v-if="successMessage" class="career-alert career-alert--success">{{ successMessage }}</div>
                <div v-if="errorMessage" class="career-alert career-alert--error">{{ errorMessage }}</div>

                <form @submit.prevent="submitApplication">
                    <div v-for="field in careers.form_fields" :key="field.key" class="form-group mb-3">
                        <label :for="field.key">{{ field.label }}</label>
                        <input
                            v-if="['text', 'email', 'tel'].includes(field.type)"
                            :id="field.key"
                            v-model="formValues[field.key]"
                            :type="field.type"
                            class="form-control"
                            :placeholder="field.placeholder || ''"
                        >
                        <textarea
                            v-else-if="field.type === 'textarea'"
                            :id="field.key"
                            v-model="formValues[field.key]"
                            class="form-control"
                            rows="4"
                            :placeholder="field.placeholder || ''"
                        ></textarea>
                        <select
                            v-else-if="field.type === 'select'"
                            :id="field.key"
                            v-model="formValues[field.key]"
                            class="form-control"
                        >
                            <option value="">Pilih salah satu</option>
                            <option v-for="option in field.options || []" :key="`${field.key}-${option}`" :value="option">{{ option }}</option>
                        </select>
                        <input
                            v-else-if="field.type === 'file'"
                            :id="field.key"
                            type="file"
                            class="form-control"
                            :accept="field.accept || ''"
                            @change="setFile(field.key, $event)"
                        >
                        <small v-if="field.helper" class="form-text text-muted">{{ field.helper }}</small>
                        <div v-if="validationErrors[field.key]" class="text-danger small mt-1">{{ validationErrors[field.key] }}</div>
                    </div>

                    <button type="submit" class="btn btn-luxury-primary btn-lg w-100" :disabled="submitting">
                        {{ submitting ? 'Mengirim...' : (careers.form?.submit_label || 'Send Application') }}
                    </button>
                </form>
            </div>
        </div>
    </div>
</template>

<script setup>
import { computed, reactive, ref } from 'vue';
import axios from 'axios';
import MainFooter from './MainFooter.vue';
import Navbar from './Navbar.vue';

const initialContent = typeof window !== 'undefined' && window.AVENOR_LANDING_INITIAL_STATE
    ? window.AVENOR_LANDING_INITIAL_STATE
    : { social_hub: {}, careers_page: {} };

const socialHub = computed(() => initialContent.social_hub || {});
const careers = computed(() => ({
    hero: initialContent.careers_page?.hero || {},
    section: initialContent.careers_page?.section || {},
    cards: initialContent.careers_page?.cards || [],
    form: initialContent.careers_page?.form || {},
    form_fields: initialContent.careers_page?.form_fields || [],
}));
const themeVars = computed(() => ({
    '--landing-background': socialHub.value?.product_page?.theme_presets?.signature?.background || '',
    '--landing-accent': socialHub.value?.product_page?.theme_presets?.signature?.accent || '#d4af37',
    '--landing-accent-soft': socialHub.value?.product_page?.theme_presets?.signature?.accentSoft || '#f1d77a',
    '--landing-accent-deep': socialHub.value?.product_page?.theme_presets?.signature?.accentDeep || '#8d6a1f',
    '--landing-halo': socialHub.value?.product_page?.theme_presets?.signature?.halo || 'rgba(212, 175, 55, 0.32)',
}));

const showModal = ref(false);
const submitting = ref(false);
const selectedCard = ref(null);
const successMessage = ref('');
const errorMessage = ref('');
const formValues = reactive({});
const fileValues = reactive({});
const validationErrors = reactive({});

const formTitle = computed(() => {
    const template = careers.value.form?.title || 'Apply for {job_title}';
    return template.replace('{job_title}', selectedCard.value?.title || '');
});

const resetForm = () => {
    errorMessage.value = '';
    Object.keys(validationErrors).forEach((key) => delete validationErrors[key]);
    Object.keys(formValues).forEach((key) => delete formValues[key]);
    Object.keys(fileValues).forEach((key) => delete fileValues[key]);

    careers.value.form_fields.forEach((field) => {
        formValues[field.key] = '';
    });
};

const openApply = (card) => {
    selectedCard.value = card;
    successMessage.value = '';
    resetForm();
    showModal.value = true;
};

const closeModal = () => {
    showModal.value = false;
    selectedCard.value = null;
};

const setFile = (key, event) => {
    fileValues[key] = event.target.files?.[0] ?? null;
};

const submitApplication = async () => {
    if (!selectedCard.value) {
        return;
    }

    submitting.value = true;
    successMessage.value = '';
    errorMessage.value = '';
    Object.keys(validationErrors).forEach((key) => delete validationErrors[key]);

    const payload = new FormData();
    payload.append('job_title', selectedCard.value.title);
    careers.value.form_fields.forEach((field) => {
        const key = field.key;
        if (field.type === 'file') {
            if (fileValues[key]) {
                payload.append(`fields[${key}]`, fileValues[key]);
            }
            return;
        }

        payload.append(`fields[${key}]`, formValues[key] ?? '');
    });

    try {
        const response = await axios.post('/carrers/apply', payload, {
            headers: {
                'Content-Type': 'multipart/form-data',
            },
        });
        resetForm();
        successMessage.value = response.data?.message || careers.value.form?.success_message || 'Lamaran berhasil dikirim.';
    } catch (error) {
        if (error.response?.status === 422) {
            const errors = error.response.data?.errors || {};
            Object.entries(errors).forEach(([key, messages]) => {
                const normalizedKey = String(key).replace(/^fields\./, '');
                validationErrors[normalizedKey] = Array.isArray(messages) ? messages[0] : messages;
            });
            errorMessage.value = 'Mohon cek kembali field yang masih belum valid.';
        } else {
            errorMessage.value = 'Lamaran belum berhasil dikirim. Coba lagi sebentar lagi.';
        }
    } finally {
        submitting.value = false;
    }
};
</script>

<style scoped>
.careers-card {
    height: 100%;
    padding: 2rem;
    border-radius: 1.75rem;
    border: 1px solid rgba(212, 175, 55, 0.2);
    background:
        radial-gradient(circle at top right, rgba(212, 175, 55, 0.12), transparent 30%),
        rgba(255, 255, 255, 0.03);
    box-shadow: 0 24px 60px rgba(0, 0, 0, 0.18);
}

.careers-card__eyebrow {
    margin-bottom: 0.85rem;
    font-size: 0.78rem;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--landing-accent, #d4af37);
}

.careers-card__title {
    margin-bottom: 0.85rem;
    font-size: clamp(1.5rem, 3vw, 2rem);
    color: #f8f1dc;
}

.careers-card__description {
    margin-bottom: 1.5rem;
    color: rgba(248, 241, 220, 0.8);
}

.career-modal {
    position: fixed;
    inset: 0;
    z-index: 60;
    display: grid;
    place-items: center;
    padding: 1.5rem;
    background: rgba(0, 0, 0, 0.58);
}

.career-modal__panel {
    position: relative;
    width: min(100%, 760px);
    max-height: calc(100vh - 3rem);
    overflow: auto;
    padding: 2rem;
    border-radius: 1.8rem;
    background: #f6efe6;
    color: #2b2117;
}

.career-modal__close {
    position: absolute;
    top: 1rem;
    right: 1rem;
    border: 0;
    background: transparent;
    font-size: 2rem;
    line-height: 1;
}

.career-modal__title {
    margin-bottom: 0.5rem;
    font-size: clamp(1.6rem, 3vw, 2.3rem);
}

.career-modal__description {
    margin-bottom: 1.5rem;
    color: rgba(43, 33, 23, 0.72);
}

.career-alert {
    margin-bottom: 1rem;
    padding: 0.85rem 1rem;
    border-radius: 1rem;
}

.career-alert--success {
    background: rgba(16, 185, 129, 0.12);
    color: #0f766e;
}

.career-alert--error {
    background: rgba(239, 68, 68, 0.12);
    color: #b91c1c;
}
</style>
