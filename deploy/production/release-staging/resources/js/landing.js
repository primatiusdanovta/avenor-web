import { createApp } from 'vue';
import 'bootstrap/dist/css/bootstrap.min.css';
import './landing/landing.css';
import LandingApp from './landing/LandingApp.vue';
import MasterGateway from './landing/MasterGateway.vue';

const pageType = typeof window !== 'undefined' ? (window.AVENOR_PAGE_TYPE || 'product') : 'product';
const rootComponent = pageType === 'master' ? MasterGateway : LandingApp;

createApp(rootComponent).mount('#landing-app');
