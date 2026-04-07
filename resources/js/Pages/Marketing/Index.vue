<template>
    <FieldTeamIndex v-bind="$props" />
</template>

<script setup>
import FieldTeamIndex from '../FieldTeam/Index.vue';

defineProps({
    filters: Object,
    fieldMembers: Array,
    selectedMember: { type: Object, default: null },
    statuses: Array,
    periodFilters: Object,
    entityLabel: { type: String, default: 'Marketing' },
    entityLabelPlural: { type: String, default: 'Marketing' },
    entityRole: { type: String, default: 'marketing' },
    roleOptions: { type: Array, default: () => [] },
});
</script>
