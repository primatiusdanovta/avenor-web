import { createApp } from 'vue';
import 'bootstrap/dist/css/bootstrap.min.css';
import './landing/landing.css';
import ArticleDetailLanding from './landing/ArticleDetailLanding.vue';
import ArticlesLanding from './landing/ArticlesLanding.vue';
import CareersLanding from './landing/CareersLanding.vue';
import LandingApp from './landing/LandingApp.vue';
import MasterGateway from './landing/MasterGateway.vue';

const pageType = typeof window !== 'undefined' ? (window.AVENOR_PAGE_TYPE || 'product') : 'product';
const pageMap = {
    master: MasterGateway,
    articles: ArticlesLanding,
    article: ArticleDetailLanding,
    carrers: CareersLanding,
};
const rootComponent = pageMap[pageType] || LandingApp;

createApp(rootComponent).mount('#landing-app');
