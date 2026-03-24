<template>
    <div class="position-relative">
        <input
            ref="inputRef"
            v-model="search"
            type="text"
            class="form-control"
            :placeholder="placeholder"
            :disabled="disabled"
            @focus="open = true"
            @keydown.down.prevent="move(1)"
            @keydown.up.prevent="move(-1)"
            @keydown.enter.prevent="pickHighlighted"
            @blur="deferClose"
        >
        <div v-if="open && !disabled" class="list-group position-absolute w-100 shadow-sm" style="z-index: 1050; max-height: 240px; overflow-y: auto;">
            <button
                v-for="(item, index) in filteredItems"
                :key="item[valueKey]"
                type="button"
                class="list-group-item list-group-item-action text-left"
                :class="{ active: index === highlightedIndex }"
                @mousedown.prevent="selectItem(item)"
            >
                {{ item[labelKey] }}
            </button>
            <div v-if="!filteredItems.length" class="list-group-item text-muted">{{ emptyText }}</div>
        </div>
    </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue';

const props = defineProps({
    items: { type: Array, default: () => [] },
    modelValue: { type: [String, Number, null], default: null },
    placeholder: { type: String, default: 'Pilih data' },
    emptyText: { type: String, default: 'Data tidak ditemukan' },
    labelKey: { type: String, default: 'option_label' },
    valueKey: { type: String, default: 'id' },
    disabled: { type: Boolean, default: false },
});

const emit = defineEmits(['update:modelValue', 'change']);
const inputRef = ref(null);
const search = ref('');
const open = ref(false);
const highlightedIndex = ref(0);

const selectedItem = computed(() => props.items.find((item) => String(item[props.valueKey]) === String(props.modelValue ?? '')) ?? null);
const filteredItems = computed(() => {
    const keyword = search.value.toLowerCase().trim();
    if (!keyword) return props.items;
    return props.items.filter((item) => String(item[props.labelKey] ?? '').toLowerCase().includes(keyword));
});

watch(() => props.modelValue, () => {
    search.value = selectedItem.value?.[props.labelKey] ?? search.value;
}, { immediate: true });

watch(filteredItems, () => {
    highlightedIndex.value = 0;
});

const selectItem = (item) => {
    search.value = item[props.labelKey];
    emit('update:modelValue', item[props.valueKey]);
    emit('change', item);
    open.value = false;
};

const move = (delta) => {
    if (!open.value) {
        open.value = true;
        return;
    }
    if (!filteredItems.value.length) return;
    const max = filteredItems.value.length - 1;
    highlightedIndex.value = Math.min(max, Math.max(0, highlightedIndex.value + delta));
};

const pickHighlighted = () => {
    const item = filteredItems.value[highlightedIndex.value];
    if (item) selectItem(item);
};

const deferClose = () => {
    window.setTimeout(() => {
        open.value = false;
        search.value = selectedItem.value?.[props.labelKey] ?? search.value;
    }, 120);
};
</script>