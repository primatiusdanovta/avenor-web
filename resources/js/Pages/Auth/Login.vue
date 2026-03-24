<template>
    <Head :title="`Login - ${branding.title}`" />

    <div class="login-page bg-adminlte">
        <div class="login-box">
            <div class="login-logo">
                <img :src="branding.logo" alt="Primatama" class="login-brand-logo mb-3">
                <div><b>Avenor</b> Web</div>
            </div>

            <div class="card card-outline card-primary shadow-lg">
                <div class="card-body login-card-body">
                    <p class="login-box-msg">{{ branding.subtitle }}</p>

                    <form @submit.prevent="submit">
                        <div class="input-group mb-3">
                            <input v-model="form.nama" type="text" class="form-control" placeholder="Username" autocomplete="username">
                            <div class="input-group-append">
                                <div class="input-group-text"><span class="fas fa-user"></span></div>
                            </div>
                        </div>
                        <div v-if="form.errors.nama" class="text-danger text-sm mb-3">{{ form.errors.nama }}</div>

                        <div class="input-group mb-3">
                            <input v-model="form.password" type="password" class="form-control" placeholder="Password" autocomplete="current-password">
                            <div class="input-group-append">
                                <div class="input-group-text"><span class="fas fa-lock"></span></div>
                            </div>
                        </div>
                        <div v-if="form.errors.password" class="text-danger text-sm mb-3">{{ form.errors.password }}</div>

                        <div class="row">
                            <div class="col-7">
                                <div class="icheck-primary">
                                    <input id="remember" v-model="form.remember" type="checkbox">
                                    <label for="remember">Ingat saya</label>
                                </div>
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

defineProps({ branding: Object });

const form = useForm({ nama: '', password: '', remember: true });

const submit = () => {
    form.post('/login', { preserveScroll: true });
};
</script>