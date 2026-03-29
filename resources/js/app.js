import './bootstrap';
import 'bootstrap/dist/js/bootstrap.bundle.min.js';
import $ from 'jquery';

// Set jQuery to window BEFORE loading AdminLTE
window.$ = window.jQuery = $;

import 'admin-lte/dist/css/adminlte.min.css';

// Import AdminLTE as ES module and create a writable wrapper
// AdminLTE exports are frozen/non-extensible, so we wrap them

import * as AdminLTEExports from 'admin-lte/dist/js/adminlte.min.js';

// Create a new object with all exports (this creates a writable copy)
// and add our custom init method
window.adminlte = {
    ...AdminLTEExports,
    // Add custom init method
    init: function() {
        
    }
};



import { createApp, h } from 'vue';
import { createInertiaApp, router } from '@inertiajs/vue3';
import { InertiaProgress } from '@inertiajs/progress';

// Setup AdminLTE v4 - ES6 class architecture with no jQuery plugins


// Don't setup AdminLTE yet - wait until DOM is ready
// setupAdminLTE() is called after Vue mounts instead

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
        
        // Initialize AdminLTE components after Inertia mounts
        // Use longer timeout to ensure Vue has fully rendered the sidebar
        setTimeout(() => {
           
        }, 300);
    },
});

router.on('finish', () => {
    applyAdminLteBodyClasses();
    
    // Reinitialize AdminLTE components after Inertia navigation
    // Use longer timeout to ensure all DOM elements are updated
    setTimeout(() => {
        
    }, 300);
});
