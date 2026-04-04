import axios from 'axios';
import { adminUrl, adminPrefix } from './utils/admin';
window.axios = axios;

window.axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';
window.axios.interceptors.request.use((config) => {
    if (typeof config.url === 'string') {
        if (config.url.startsWith('http://') || config.url.startsWith('https://')) {
            return config;
        }

        if (config.url === adminPrefix() || config.url.startsWith(adminPrefix() + '/')) {
            config.baseURL = '';
            return config;
        }

        if (config.url.startsWith('/')) {
            config.baseURL = '';
            config.url = adminUrl(config.url);
            return config;
        }
    }

    return config;
});
