<template>
    <Head title="Target Penjualan" />

    <div class="row">
        <div class="col-12">
            <div class="card card-outline card-primary">
                <div class="card-header">
                    <h3 class="card-title">Target Penjualan Marketing dan Reseller</h3>
                </div>
                <div class="card-body p-0 table-responsive">
                    <table class="table table-hover mb-0 align-middle">
                        <thead>
                            <tr>
                                <th>Role</th>
                                <th>Target Harian Qty</th>
                                <th>Bonus Harian</th>
                                <th>Target Mingguan Qty</th>
                                <th>Bonus Mingguan</th>
                                <th>Target Bulanan Qty</th>
                                <th>Bonus Bulanan</th>
                                <th>Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="form in forms" :key="form.id">
                                <td class="text-capitalize fw-bold">{{ form.role }}</td>
                                <td><input v-model="form.daily_target_qty" type="number" min="0" class="form-control" /></td>
                                <td><input v-model="form.daily_bonus" type="number" min="0" class="form-control" /></td>
                                <td><input v-model="form.weekly_target_qty" type="number" min="0" class="form-control" /></td>
                                <td><input v-model="form.weekly_bonus" type="number" min="0" class="form-control" /></td>
                                <td><input v-model="form.monthly_target_qty" type="number" min="0" class="form-control" /></td>
                                <td><input v-model="form.monthly_bonus" type="number" min="0" class="form-control" /></td>
                                <td>
                                    <button class="btn btn-sm btn-primary" :disabled="form.processing" @click="submit(form)">Simpan</button>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <div class="card-footer text-muted">
                    Target dan bonus diatur terpisah untuk marketing dan reseller. Dashboard seller akan menghitung pencapaian harian, mingguan, dan bulanan berdasarkan quantity penjualan.
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { Head, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    targets: {
        type: Array,
        default: () => [],
    },
});

const forms = props.targets.map((target) => useForm({
    id: target.id,
    role: target.role,
    daily_target_qty: target.daily_target_qty,
    daily_bonus: target.daily_bonus,
    weekly_target_qty: target.weekly_target_qty,
    weekly_bonus: target.weekly_bonus,
    monthly_target_qty: target.monthly_target_qty,
    monthly_bonus: target.monthly_bonus,
}));

const submit = (form) => {
    form.put(`/sales-targets/${form.id}`, {
        preserveScroll: true,
    });
};
</script>
