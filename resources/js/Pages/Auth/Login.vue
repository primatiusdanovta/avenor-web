<template>
    <Head title="Login" />

    <div class="login-page bg-adminlte">
        <div class="login-box">
            <div class="login-logo">
                <img :src="branding.logo" alt="Primatama" class="login-brand-logo">
                <div><b>Avenor</b> Perfume</div>
            </div>

            <div class="card card-outline card-primary shadow-lg">
                <div class="card-body login-card-body">
                    <p class="login-box-msg">{{ branding.subtitle }}</p>

                    <form @submit.prevent="submit">
                        <div class="input-group mb-3 login-input-group">
                            <input v-model="form.nama" type="text" class="form-control" placeholder="Username" autocomplete="username">
                            <div class="input-group-append login-input-icon">
                                <div class="input-group-text"><span class="fas fa-user"></span></div>
                            </div>
                        </div>
                        <div v-if="form.errors.nama" class="text-danger text-sm mb-3">{{ form.errors.nama }}</div>

                        <div class="input-group mb-2 login-input-group">
                            <input v-model="form.password" :type="showPassword ? 'text' : 'password'" class="form-control" placeholder="Password" autocomplete="current-password">
                            <div class="input-group-append login-input-icon">
                                <button type="button" class="btn btn-outline-secondary login-password-toggle" @click="showPassword = !showPassword">
                                    <span :class="showPassword ? 'fas fa-eye-slash' : 'fas fa-eye'"></span>
                                </button>
                            </div>
                        </div>

                        <div v-if="form.errors.password" class="text-danger text-sm mb-3">{{ form.errors.password }}</div>

                        <div class="mb-3 p-3 rounded border bg-light">
                            <div class="d-flex justify-content-between align-items-center mb-2">
                                <label class="mb-0">Captcha</label>
                                <button type="button" class="btn btn-outline-secondary btn-sm" @click="refreshCaptcha">Captcha baru</button>
                            </div>
                            <div class="fw-bold mb-2">{{ captchaQuestion }}</div>
                            <input v-model="form.captcha_answer" type="text" inputmode="numeric" class="form-control" placeholder="Masukkan hasil captcha">
                        </div>
                        <div v-if="form.errors.captcha_answer" class="text-danger text-sm mb-3">{{ form.errors.captcha_answer }}</div>

                        <div class="row">
                            <div class="col-7">
                                <div class="icheck-primary">
                                    <input id="remember" v-model="form.remember" type="checkbox">
                                    <label for="remember">Ingat username saya</label>
                                </div>
                                <div class="small text-muted mt-2">Password tidak disimpan di browser.</div>
                            </div>
                            <div class="col-5">
                                <button type="submit" class="btn btn-primary btn-block" :disabled="form.processing">
                                    {{ form.processing ? 'Memproses...' : 'Login' }}
                                </button>
                            </div>
                        </div>
                    </form>

                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { Head, useForm } from '@inertiajs/vue3';
import { onMounted, ref } from 'vue';
import { adminUrl } from '@/utils/admin';

const props = defineProps({ branding: Object, captcha: Object });

const REMEMBER_KEY = 'avenor-login-remember';
const showPassword = ref(false);
const captchaQuestion = ref(props.captcha?.question || '');
const form = useForm({ nama: '', password: '', captcha_answer: '', remember: true });

const applyRememberedCredentials = () => {
    const raw = window.localStorage.getItem(REMEMBER_KEY);
    if (!raw) {
        return;
    }

    try {
        const parsed = JSON.parse(raw);
        form.nama = typeof parsed === 'string' ? parsed : (parsed?.nama ?? '');
        form.remember = Boolean(form.nama);
    } catch (error) {
        window.localStorage.removeItem(REMEMBER_KEY);
    }
};

const refreshCaptcha = async () => {
    try {
        const { data } = await window.axios.get(adminUrl('/login/captcha'));
        captchaQuestion.value = data.question;
    } finally {
        form.captcha_answer = '';
    }
};

const submit = () => {
    if (form.remember && form.nama.trim() !== '') {
        window.localStorage.setItem(REMEMBER_KEY, JSON.stringify({ nama: form.nama.trim() }));
    } else {
        window.localStorage.removeItem(REMEMBER_KEY);
    }

    form.post(adminUrl('/login'), {
        preserveScroll: true,
        onError: () => refreshCaptcha(),
    });
};

onMounted(() => {
    applyRememberedCredentials();
});
</script>

<style scoped>
.login-input-group :deep(.form-control),
.login-input-group :deep(.input-group-text),
.login-password-toggle {
    height: 44px;
}

.login-input-icon {
    width: 46px;
}

.login-input-icon .input-group-text,
.login-password-toggle {
    width: 100%;
    justify-content: center;
}
</style>
