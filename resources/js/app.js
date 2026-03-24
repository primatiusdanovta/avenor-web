// import './bootstrap';
// import { createApp, h } from 'vue';
// import { createInertiaApp, progress } from '@inertiajs/vue3';

// createInertiaApp({
//     resolve: (name) => {
//         const pages = import.meta.glob('./Pages/**/*.vue', { eager: true });
//         return pages[`./Pages/${name}.vue`];
//     },
//     setup({ el, App, props, plugin }) {
//         createApp({ render: () => h(App, props) })
//             .use(plugin)
//             .mount(el);
//     },
// });

// progress.init({
//     color: '#0f766e',
//     showSpinner: false,
// });
import './bootstrap'
import { createApp, h } from 'vue'
import { createInertiaApp, router, progress } from '@inertiajs/vue3'

import $ from 'jquery'
window.$ = window.jQuery = $

import 'bootstrap'
import 'admin-lte'

createInertiaApp({
    resolve: (name) => {
        const pages = import.meta.glob('./Pages/**/*.vue', { eager: true })
        return pages[`./Pages/${name}.vue`]
    },
    setup({ el, App, props, plugin }) {
        createApp({ render: () => h(App, props) })
            .use(plugin)
            .mount(el)
    },
})

progress.init({
    color: '#0f766e',
    showSpinner: false,
})

router.on('finish', () => {
    setTimeout(() => {
        if (window.$) {
            $('[data-widget="pushmenu"]').PushMenu?.('init')
            $('[data-widget="treeview"]').Treeview?.('init')
        }
    }, 100)
})