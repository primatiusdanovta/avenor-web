import axios from 'axios';
import { adminUrl, adminPrefix } from './utils/admin';
window.axios = axios;

window.axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';
window.axios.defaults.baseURL = adminPrefix();
window.axios.interceptors.request.use((config) => {
    if (typeof config.url === 'string' && config.url.startsWith('/') && !config.url.startsWith(adminPrefix() + '/')) {
        config.url = adminUrl(config.url);
    }

    return config;
});
