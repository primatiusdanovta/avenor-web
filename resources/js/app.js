import './bootstrap'
import { createApp, h } from 'vue'
import { createInertiaApp, router } from '@inertiajs/vue3'
import { InertiaProgress } from '@inertiajs/progress'
import $ from 'jquery'
import 'bootstrap/dist/js/bootstrap.bundle.min.js'
import 'admin-lte/dist/css/adminlte.min.css'
import * as AdminLTEExports from 'admin-lte/dist/js/adminlte.min.js'

window.$ = window.jQuery = $
window.adminlte = {
    ...AdminLTEExports,
}

const applyAdminLteBodyClasses = () => {
    document.body.classList.add('layout-fixed', 'sidebar-expand-lg', 'bg-body-tertiary')
    document.body.classList.remove('sidebar-mini')
}

createInertiaApp({
    resolve: (name) => {
        const pages = import.meta.glob('./Pages/**/*.vue')
        return pages[`./Pages/${name}.vue`]()
    },
    setup({ el, App, props, plugin }) {
        createApp({ render: () => h(App, props) })
            .use(plugin)
            .mount(el)

        applyAdminLteBodyClasses()
    },
})

InertiaProgress.init({
    color: '#0f766e',
    showSpinner: false,
})

router.on('finish', () => {
    applyAdminLteBodyClasses()
})
