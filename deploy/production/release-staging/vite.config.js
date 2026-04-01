import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js', 'resources/js/landing.js'],
            refresh: true,
        }),
        vue(),
    ],
    server: {
        watch: {
            ignored: ['**/storage/framework/views/**'],
        },
    },
    build: {
        rollupOptions: {
            output: {
                manualChunks(id) {
                    if (!id.includes('node_modules')) {
                        return;
                    }

                    if (id.includes('@inertiajs') || id.includes('vue')) {
                        return 'inertia-vue';
                    }

                    if (id.includes('admin-lte') || id.includes('bootstrap') || id.includes('jquery')) {
                        return 'adminlte-vendor';
                    }
                },
            },
        },
    },
});

