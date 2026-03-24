<template>
    <Head :title="`Login - ${branding.title}`" />

    <div class="login-page">
        <div class="login-card">
            <img :src="branding.logo" alt="Primatama" class="login-logo">
            <p class="login-eyebrow">Secure Access</p>
            <h1>{{ branding.title }}</h1>
            <p class="login-subtitle">{{ branding.subtitle }}</p>

            <form class="login-form" @submit.prevent="submit">
                <label class="field">
                    <span>Username</span>
                    <input v-model="form.nama" type="text" autocomplete="username" placeholder="Masukkan username">
                    <small v-if="form.errors.nama" class="field-error">{{ form.errors.nama }}</small>
                </label>

                <label class="field">
                    <span>Password</span>
                    <input v-model="form.password" type="password" autocomplete="current-password" placeholder="Masukkan password">
                    <small v-if="form.errors.password" class="field-error">{{ form.errors.password }}</small>
                </label>

                <label class="remember-row">
                    <input v-model="form.remember" type="checkbox">
                    <span>Ingat saya</span>
                </label>

                <button type="submit" class="primary-button" :disabled="form.processing">
                    {{ form.processing ? 'Memproses...' : 'Login' }}
                </button>
            </form>
        </div>
    </div>
</template>

<script setup>
import { Head, useForm } from '@inertiajs/vue3';

defineProps({
    branding: {
        type: Object,
        required: true,
    },
});

const form = useForm({
    nama: '',
    password: '',
    remember: true,
});

const submit = () => {
    form.post('/login', {
        preserveScroll: true,
    });
};
</script>