<template>
    <AppLayout>
        <Head title="Account Receiveables" />

        <div class="row">
            <div class="col-lg-12">
                <div class="card card-outline card-success">
                    <div class="card-header"><h3 class="card-title">Daftar Account Receiveables</h3></div>
                    <div class="card-body p-0 table-responsive">
                        <table class="table table-hover mb-0">
                            <thead>
                                <tr>
                                    <th>Nama</th>
                                    <th>Nama Tempat</th>
                                    <th>Status</th>
                                    <th>Tanggal Titip</th>
                                    <th>Jatuh Tempo</th>
                                    <th>Nilai Titip</th>
                                    <th>Piutang Berjalan</th>
                                    <th>Detail Product</th>
                                    <th>Catatan</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="item in accountReceivables" :key="item.id">
                                    <td class="font-weight-bold">{{ item.receivable_name }}</td>
                                    <td>{{ item.place_name }}</td>
                                    <td><span class="badge badge-secondary text-uppercase">{{ item.status }}</span></td>
                                    <td>{{ item.consignment_date }}</td>
                                    <td>{{ item.due_date }}</td>
                                    <td>{{ toCurrency(item.consigned_value) }}</td>
                                    <td>{{ toCurrency(item.total_value) }}</td>
                                    <td>{{ item.items_summary || '-' }}</td>
                                    <td>{{ item.notes || '-' }}</td>
                                </tr>
                                <tr v-if="!accountReceivables.length">
                                    <td colspan="9" class="text-center text-muted py-4">Belum ada account receiveables.</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </AppLayout>
</template>

<script setup>
import { Head } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';

defineProps({ accountReceivables: Array });

const toCurrency = (value) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value || 0);
</script>
