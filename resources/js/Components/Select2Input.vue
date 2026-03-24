<template>
    <select ref="selectRef" class="form-control" :disabled="disabled" @change="handleNativeChange">
        <option v-if="placeholder" value="">{{ placeholder }}</option>
        <option v-for="item in normalizedOptions" :key="String(item.value)" :value="String(item.value)">{{ item.label }}</option>
    </select>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue';

const props = defineProps({
    modelValue: { type: [String, Number, null], default: '' },
    options: { type: Array, default: () => [] },
    valueKey: { type: String, default: 'value' },
    labelKey: { type: String, default: 'label' },
    placeholder: { type: String, default: 'Pilih data' },
    disabled: { type: Boolean, default: false },
});

const emit = defineEmits(['update:modelValue', 'change']);
const selectRef = ref(null);
let waitTimer = null;

const normalizedOptions = computed(() => props.options.map((item) => {
    if (typeof item === 'object' && item !== null) {
        return {
            value: item[props.valueKey],
            label: item[props.labelKey] ?? item.label ?? item.name ?? item.value,
            raw: item,
        };
    }

    return { value: item, label: item, raw: item };
}));

const optionsSignature = computed(() => JSON.stringify(normalizedOptions.value.map((item) => ({ value: String(item.value), label: item.label }))));

const syncValue = () => {
    if (!selectRef.value) return;

    const value = props.modelValue == null ? '' : String(props.modelValue);
    selectRef.value.value = value;

    if (window.jQuery?.fn?.select2) {
        window.jQuery(selectRef.value).val(value).trigger('change.select2');
    }
};

const rebuildOptions = () => {
    if (!selectRef.value) return;

    const currentValue = props.modelValue == null ? '' : String(props.modelValue);
    const element = selectRef.value;
    element.innerHTML = '';

    if (props.placeholder) {
        const placeholderOption = document.createElement('option');
        placeholderOption.value = '';
        placeholderOption.textContent = props.placeholder;
        element.appendChild(placeholderOption);
    }

    normalizedOptions.value.forEach((item) => {
        const option = document.createElement('option');
        option.value = String(item.value);
        option.textContent = item.label;
        if (String(item.value) === currentValue) {
            option.selected = true;
        }
        element.appendChild(option);
    });
};

const initSelect2 = () => {
    if (!selectRef.value || !window.jQuery || !window.jQuery.fn?.select2) {
        return false;
    }

    const $select = window.jQuery(selectRef.value);

    if ($select.hasClass('select2-hidden-accessible')) {
        $select.off('.select2input');
        $select.select2('destroy');
    }

    rebuildOptions();

    $select.select2({
        theme: 'bootstrap4',
        width: '100%',
        placeholder: props.placeholder,
        allowClear: Boolean(props.placeholder),
    });

    syncValue();
    $select.on('change.select2input', () => {
        const value = $select.val();
        emit('update:modelValue', value === '' ? '' : value);
        const selected = normalizedOptions.value.find((item) => String(item.value) === String(value));
        emit('change', selected?.raw ?? null);
    });

    return true;
};

const queueInit = () => {
    rebuildOptions();
    syncValue();

    if (waitTimer) {
        window.clearInterval(waitTimer);
    }

    if (initSelect2()) {
        return;
    }

    waitTimer = window.setInterval(() => {
        if (initSelect2()) {
            window.clearInterval(waitTimer);
            waitTimer = null;
        }
    }, 100);
};

const handleNativeChange = (event) => {
    if (window.jQuery?.fn?.select2 && window.jQuery(selectRef.value).hasClass('select2-hidden-accessible')) {
        return;
    }

    const value = event.target.value;
    emit('update:modelValue', value === '' ? '' : value);
    const selected = normalizedOptions.value.find((item) => String(item.value) === String(value));
    emit('change', selected?.raw ?? null);
};

onMounted(() => {
    queueInit();
});

watch(() => props.modelValue, async () => {
    await nextTick();
    syncValue();
});

watch(() => props.disabled, async () => {
    await nextTick();
    queueInit();
});

watch(optionsSignature, async () => {
    await nextTick();
    queueInit();
});

onBeforeUnmount(() => {
    if (waitTimer) {
        window.clearInterval(waitTimer);
    }

    if (selectRef.value && window.jQuery?.fn?.select2) {
        const $select = window.jQuery(selectRef.value);
        $select.off('.select2input');
        if ($select.hasClass('select2-hidden-accessible')) {
            $select.select2('destroy');
        }
    }
});
</script>
