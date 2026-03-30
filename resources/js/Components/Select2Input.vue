<template>
    <select ref="selectRef" class="form-control" :disabled="disabled" :multiple="multiple" @change="handleNativeChange"></select>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue';

const props = defineProps({
    modelValue: { type: [String, Number, Array, null], default: '' },
    options: { type: Array, default: () => [] },
    valueKey: { type: String, default: 'value' },
    labelKey: { type: String, default: 'label' },
    placeholder: { type: String, default: 'Pilih data' },
    disabled: { type: Boolean, default: false },
    multiple: { type: Boolean, default: false },
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
const normalizedValue = computed(() => {
    if (props.multiple) {
        return Array.isArray(props.modelValue)
            ? props.modelValue.map((value) => String(value))
            : [];
    }

    return props.modelValue == null ? '' : String(props.modelValue);
});

const syncValue = () => {
    if (!selectRef.value) return;

    if (props.multiple) {
        const values = normalizedValue.value;
        Array.from(selectRef.value.options).forEach((option) => {
            option.selected = values.includes(option.value);
        });

        if (window.jQuery?.fn?.select2) {
            window.jQuery(selectRef.value).val(values).trigger('change.select2');
        }

        return;
    }

    const value = normalizedValue.value;
    selectRef.value.value = value;

    if (window.jQuery?.fn?.select2) {
        window.jQuery(selectRef.value).val(value).trigger('change.select2');
    }
};

const rebuildOptions = () => {
    if (!selectRef.value) return;

    const currentValue = normalizedValue.value;
    const selectedValues = props.multiple ? currentValue : [currentValue];
    const element = selectRef.value;
    element.innerHTML = '';

    if (props.placeholder && !props.multiple) {
        const placeholderOption = document.createElement('option');
        placeholderOption.value = '';
        placeholderOption.textContent = props.placeholder;
        element.appendChild(placeholderOption);
    }

    normalizedOptions.value.forEach((item) => {
        const option = document.createElement('option');
        option.value = String(item.value);
        option.textContent = item.label;
        option.selected = selectedValues.includes(String(item.value));
        element.appendChild(option);
    });
};

const emitSelection = (rawValue) => {
    if (props.multiple) {
        const values = Array.isArray(rawValue) ? rawValue.map((value) => String(value)) : [];
        emit('update:modelValue', values);
        const selected = normalizedOptions.value.filter((item) => values.includes(String(item.value))).map((item) => item.raw);
        emit('change', selected);
        return;
    }

    const value = rawValue === '' ? '' : String(rawValue ?? '');
    emit('update:modelValue', value === '' ? '' : value);
    const selected = normalizedOptions.value.find((item) => String(item.value) === value);
    emit('change', selected?.raw ?? null);
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
        allowClear: Boolean(props.placeholder) && !props.multiple,
        multiple: props.multiple,
    });

    syncValue();
    $select.on('change.select2input', () => {
        emitSelection($select.val());
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

    if (props.multiple) {
        emitSelection(Array.from(event.target.selectedOptions).map((option) => option.value));
        return;
    }

    emitSelection(event.target.value);
};

onMounted(() => {
    queueInit();
});

watch(() => props.modelValue, async () => {
    await nextTick();
    syncValue();
}, { deep: true });

watch(() => props.disabled, async () => {
    await nextTick();
    queueInit();
});

watch(() => props.multiple, async () => {
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
