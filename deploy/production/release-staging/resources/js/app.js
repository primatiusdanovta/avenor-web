import './bootstrap'
import { createApp, h } from 'vue'
import { createInertiaApp, router } from '@inertiajs/vue3'
import { InertiaProgress } from '@inertiajs/progress'
import { adminPrefix, adminUrl } from './utils/admin'
import $ from 'jquery'
import 'bootstrap/dist/js/bootstrap.bundle.min.js'
import 'admin-lte/dist/css/adminlte.min.css'
import * as AdminLTEExports from 'admin-lte/dist/js/adminlte.min.js'

window.$ = window.jQuery = $
window.adminlte = {
    ...AdminLTEExports,
}

const prefixInertiaUrl = (value) => {
    if (typeof value !== 'string' || value === '' || value.startsWith('http://') || value.startsWith('https://')) {
        return value
    }

    if (value.startsWith(adminPrefix() + '/') || value === adminPrefix()) {
        return value
    }

    return value.startsWith('/') ? adminUrl(value) : value
}

const originalVisit = router.visit.bind(router)
router.visit = (href, options = {}) => originalVisit(prefixInertiaUrl(href), options)

for (const method of ['get', 'post', 'put', 'patch', 'delete']) {
    const originalMethod = router[method].bind(router)
    router[method] = (href, ...args) => originalMethod(prefixInertiaUrl(href), ...args)
}

const cleanupTransientOverlays = () => {
    document.body.classList.remove('sidebar-open', 'modal-open')
    document.querySelectorAll('.sidebar-overlay').forEach((element) => element.remove())
    document.querySelectorAll('.modal-backdrop-wrapper').forEach((element) => {
        if (!element.closest('[data-v-app]')) {
            element.remove()
        }
    })
}

const loadingOverlay = () => document.getElementById('global-loading-overlay')
const loadingBar = () => document.getElementById('global-loading-bar')
let loadingTimer = null
let loadingValue = 0

const showGlobalLoading = () => {
    const overlay = loadingOverlay()
    const bar = loadingBar()
    if (!overlay || !bar) return

    loadingValue = 12
    bar.style.width = loadingValue + '%'
    overlay.classList.add('is-visible')

    if (loadingTimer) window.clearInterval(loadingTimer)
    loadingTimer = window.setInterval(() => {
        loadingValue = Math.min(92, loadingValue + Math.max(4, (100 - loadingValue) * 0.08))
        bar.style.width = loadingValue + '%'
    }, 180)
}

const hideGlobalLoading = () => {
    const overlay = loadingOverlay()
    const bar = loadingBar()
    if (!overlay || !bar) return

    if (loadingTimer) {
        window.clearInterval(loadingTimer)
        loadingTimer = null
    }

    loadingValue = 100
    bar.style.width = '100%'
    window.setTimeout(() => {
        overlay.classList.remove('is-visible')
        bar.style.width = '0%'
        loadingValue = 0
    }, 180)
}

const applyAdminLteBodyClasses = () => {
    cleanupTransientOverlays()
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

router.on('start', () => {
    showGlobalLoading()
})

router.on('finish', () => {
    applyAdminLteBodyClasses()
    hideGlobalLoading()
})

router.on('error', () => {
    hideGlobalLoading()
})

router.on('invalid', () => {
    hideGlobalLoading()
})
