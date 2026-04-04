<template>
    <Teleport to="body">
        <Transition name="modal-fade">
            <div v-if="show" class="modal-backdrop-wrapper" @click.self="emit('close')">
                <div class="modal d-block" tabindex="-1" role="dialog" aria-modal="true">
                    <div class="modal-dialog" :class="dialogClass">
                        <div class="modal-content">
                            <div v-if="$slots.header || title" class="modal-header" :class="headerClass">
                                <slot name="header">
                                    <h5 class="modal-title">{{ title }}</h5>
                                </slot>
                                <button v-if="closable" type="button" class="btn-close" :class="closeClass" aria-label="Close" @click="emit('close')"></button>
                            </div>
                            <div class="modal-body">
                                <slot />
                            </div>
                            <div v-if="$slots.footer" class="modal-footer">
                                <slot name="footer" />
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </Transition>
    </Teleport>
</template>

<script setup>
import { computed, onBeforeUnmount, watch } from 'vue';

const props = defineProps({
    show: { type: Boolean, default: false },
    title: { type: String, default: '' },
    size: { type: String, default: 'md' },
    centered: { type: Boolean, default: true },
    closable: { type: Boolean, default: true },
    headerVariant: { type: String, default: '' },
});

const emit = defineEmits(['close']);

const dialogClass = computed(() => ({
    'modal-dialog-centered': props.centered,
    'modal-lg': props.size === 'lg',
    'modal-xl': props.size === 'xl',
    'modal-sm': props.size === 'sm',
    'modal-fullscreen-sm-down': props.size === 'mobile-full',
}));

const headerClass = computed(() => ({
    'bg-danger text-white': props.headerVariant === 'danger',
    'bg-success text-white': props.headerVariant === 'success',
    'bg-warning': props.headerVariant === 'warning',
    'bg-primary text-white': props.headerVariant === 'primary',
}));

const closeClass = computed(() => ({
    'btn-close-white': ['danger', 'success', 'primary'].includes(props.headerVariant),
}));

const handleKeydown = (event) => {
    if (!props.show || !props.closable) {
        return;
    }

    if (event.key === 'Escape') {
        emit('close');
    }
};

watch(() => props.show, (value) => {
    if (typeof document === 'undefined') {
        return;
    }

    document.body.classList.toggle('modal-open', value);

    if (value) {
        document.addEventListener('keydown', handleKeydown);
        return;
    }

    document.removeEventListener('keydown', handleKeydown);
}, { immediate: true });

onBeforeUnmount(() => {
    if (typeof document === 'undefined') {
        return;
    }

    document.body.classList.remove('modal-open');
    document.removeEventListener('keydown', handleKeydown);
});
</script>

<style scoped>
.modal-backdrop-wrapper {
    position: fixed;
    inset: 0;
    z-index: 1060;
    background: rgba(33, 37, 41, 0.58);
    overflow-y: auto;
    padding: 1rem;
}

.modal {
    position: static;
}

.modal-dialog {
    margin: 0.75rem auto;
    min-height: calc(100vh - 1.5rem);
    display: flex;
    align-items: center;
}

.modal-content {
    width: 100%;
    border-radius: 1rem;
    overflow: hidden;
}

.modal-fade-enter-active,
.modal-fade-leave-active {
    transition: opacity 0.2s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
    opacity: 0;
}

@media (max-width: 576px) {
    .modal-backdrop-wrapper {
        padding: 0.5rem;
    }

    .modal-dialog {
        min-height: calc(100vh - 1rem);
        margin: 0.5rem auto;
    }

    .modal-content {
        border-radius: 0.85rem;
    }
}
</style>
