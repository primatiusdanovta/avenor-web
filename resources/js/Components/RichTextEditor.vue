<template>
    <div class="rich-editor">
        <div class="rich-editor__toolbar">
            <button v-for="action in actions" :key="action.label" type="button" class="btn btn-sm btn-outline-secondary" @click="runAction(action)">
                {{ action.label }}
            </button>
        </div>
        <div
            ref="editorRef"
            class="rich-editor__surface form-control"
            contenteditable="true"
            @input="emitValue"
            @blur="emitValue"
        ></div>
    </div>
</template>

<script setup>
import { onMounted, ref, watch } from 'vue';

const props = defineProps({
    modelValue: { type: String, default: '' },
});

const emit = defineEmits(['update:modelValue']);
const editorRef = ref(null);

const actions = [
    { label: 'Paragraph', command: 'formatBlock', value: 'p' },
    { label: 'H2', command: 'formatBlock', value: 'h2' },
    { label: 'Bold', command: 'bold' },
    { label: 'Italic', command: 'italic' },
    { label: 'Underline', command: 'underline' },
    { label: 'Bullet', command: 'insertUnorderedList' },
    { label: 'Number', command: 'insertOrderedList' },
    { label: 'Link', command: 'createLink', prompt: 'Masukkan URL link:' },
    { label: 'Clear', command: 'removeFormat' },
];

const syncEditor = (value) => {
    if (!editorRef.value) {
        return;
    }

    if (editorRef.value.innerHTML !== value) {
        editorRef.value.innerHTML = value || '';
    }
};

const emitValue = () => {
    emit('update:modelValue', editorRef.value?.innerHTML ?? '');
};

const runAction = (action) => {
    editorRef.value?.focus();

    if (action.prompt) {
        const value = window.prompt(action.prompt, 'https://');
        if (!value) {
            return;
        }
        document.execCommand(action.command, false, value);
        emitValue();
        return;
    }

    document.execCommand(action.command, false, action.value ?? null);
    emitValue();
};

onMounted(() => {
    syncEditor(props.modelValue);
});

watch(() => props.modelValue, (value) => {
    syncEditor(value);
});
</script>

<style scoped>
.rich-editor {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
}

.rich-editor__toolbar {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
}

.rich-editor__surface {
    min-height: 280px;
    overflow-y: auto;
    background: #fff;
    line-height: 1.7;
}

.rich-editor__surface:focus {
    outline: none;
    box-shadow: none;
}
</style>
