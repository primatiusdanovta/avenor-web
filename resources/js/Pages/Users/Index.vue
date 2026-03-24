<template>
    <Head title="Users" />

    <div class="stack">
        <section class="panel-card">
            <div class="panel-head">
                <div>
                    <h3>Form Handling + SPA Visit</h3>
                    <p>Filter dikirim lewat Inertia form, lalu hasilnya diperbarui tanpa full page reload.</p>
                </div>
            </div>

            <form class="filter-grid" @submit.prevent="submit">
                <label class="field">
                    <span>Cari Username</span>
                    <input v-model="form.search" type="text" placeholder="mis. superadmin">
                </label>

                <label class="field">
                    <span>Role</span>
                    <select v-model="form.role">
                        <option value="">Semua role</option>
                        <option v-for="role in roles" :key="role" :value="role">{{ role }}</option>
                    </select>
                </label>

                <div class="filter-actions">
                    <button type="submit" class="primary-button" :disabled="form.processing">Filter</button>
                    <button type="button" class="ghost-button" @click="reset">Reset</button>
                </div>
            </form>
        </section>

        <section class="panel-card">
            <div class="panel-head">
                <h3>Daftar Users</h3>
                <p>{{ users.total }} user ditemukan.</p>
            </div>

            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Username</th>
                            <th>Role</th>
                            <th>Status</th>
                            <th>Created At</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="user in users.data" :key="user.id_user">
                            <td>{{ user.id_user }}</td>
                            <td>{{ user.nama }}</td>
                            <td>{{ user.role }}</td>
                            <td>{{ user.status }}</td>
                            <td>{{ user.created_at }}</td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div class="pagination-row">
                <Link
                    v-for="link in users.links"
                    :key="`${link.label}-${link.url}`"
                    :href="link.url || '/users'"
                    class="page-link"
                    :class="{ active: link.active, disabled: !link.url }"
                    v-html="link.label"
                    preserve-scroll
                />
            </div>
        </section>
    </div>
</template>

<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    filters: {
        type: Object,
        required: true,
    },
    roles: {
        type: Array,
        required: true,
    },
    users: {
        type: Object,
        required: true,
    },
});

const form = useForm({
    search: props.filters.search ?? '',
    role: props.filters.role ?? '',
});

const submit = () => {
    form.get('/users', {
        preserveState: true,
        preserveScroll: true,
        replace: true,
    });
};

const reset = () => {
    form.search = '';
    form.role = '';
    submit();
};
</script>