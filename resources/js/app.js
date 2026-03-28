import './bootstrap';
import 'bootstrap/dist/js/bootstrap.bundle.min.js';
import 'admin-lte/dist/css/adminlte.min.css';
import 'admin-lte/dist/js/adminlte.js';
import { createApp, h } from 'vue';
import { createInertiaApp, router } from '@inertiajs/vue3';
import { InertiaProgress } from '@inertiajs/progress';
import $ from 'jquery';

window.$ = window.jQuery = $;

await import('admin-lte/dist/js/adminlte.min.js');

const applyAdminLteBodyClasses = () => {
    document.body.classList.add('layout-fixed', 'sidebar-expand-lg', 'sidebar-mini', 'bg-body-tertiary');
};

InertiaProgress.init({
    color: '#0d6efd',
    showSpinner: false,
});

createInertiaApp({
    resolve: (name) => {
        const pages = import.meta.glob('./Pages/**/*.vue', { eager: true });
        return pages[`./Pages/${name}.vue`];
    },
    setup({ el, App, props, plugin }) {
        createApp({ render: () => h(App, props) })
            .use(plugin)
            .mount(el);

        applyAdminLteBodyClasses();
    },
});

router.on('finish', () => {
    applyAdminLteBodyClasses();
});
