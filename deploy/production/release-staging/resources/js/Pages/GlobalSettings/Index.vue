
<template>
    <Head title="Global Settings" />

    <div class="row">
        <div class="col-xl-10">
            <div class="card card-outline card-dark">
                <div class="card-header d-flex flex-column flex-lg-row align-items-lg-center justify-content-between gap-3">
                    <div>
                        <h3 class="card-title mb-1">Global Settings by Page Target</h3>
                        <p class="text-muted small mb-0">Atur konten halaman `/`, `/product/{slug}`, footer global, dan microcopy utama dari satu panel.</p>
                    </div>
                    <div class="settings-tab-list">
                        <button v-for="panel in panelOptions" :key="panel.id" type="button" class="btn btn-sm" :class="activePanel === panel.id ? 'btn-dark' : 'btn-outline-dark'" @click="activePanel = panel.id">
                            {{ panel.label }}
                        </button>
                    </div>
                </div>
                <div class="card-body">
                    <div class="mb-4">
                        <p class="text-muted mb-0">Semua link social media di bawah ini menjadi sumber tunggal. Jika diubah, target tombol/link social yang memakai data global akan ikut berubah bersamaan.</p>
                    </div>

                    <div v-show="activePanel === 'media'" class="border rounded p-3 mb-4">
                        <h4 class="h6 text-uppercase text-muted mb-2">Target: "/" - Master Hero Video</h4>
                        <p class="text-muted small mb-3">Preview: video background pada hero section paling atas halaman `/`.</p>
                        <div class="row align-items-end">
                            <div class="col-md-8 form-group">
                                <label>Upload Hero Video</label>
                                <input type="file" class="form-control" accept="video/mp4,video/webm,video/quicktime" @change="handleHeroVideoChange">
                                <small class="form-text text-muted">Dipakai pada hero section halaman `/`. Disarankan MP4/WebM yang sudah dikompres.</small>
                            </div>
                            <div class="col-md-4 form-group">
                                <div class="custom-control custom-checkbox mt-4 pt-2">
                                    <input id="remove-hero-video" v-model="form.remove_hero_video" type="checkbox" class="custom-control-input">
                                    <label class="custom-control-label" for="remove-hero-video">Hapus video hero</label>
                                </div>
                            </div>
                            <div v-if="masterSocialHub?.hero_video_url" class="col-12 form-group mb-0">
                                <label class="d-block">Video Saat Ini</label>
                                <video :src="masterSocialHub.hero_video_url" controls muted playsinline style="width:100%;max-width:420px;border-radius:12px;background:#111"></video>
                                <small class="form-text text-muted">{{ masterSocialHub.hero_video_name || 'Hero video tersedia' }}</small>
                            </div>
                        </div>
                    </div>

                    <div v-show="activePanel === 'hero'" class="border rounded p-3 mb-4">
                        <h4 class="h6 text-uppercase text-muted mb-2">Target: "/" - Hero Copy</h4>
                        <p class="text-muted small mb-3">Preview: eyebrow, title, dan description utama di hero halaman `/`.</p>
                        <div class="row">
                            <div class="col-md-4 form-group">
                                <label>Hero Eyebrow</label>
                                <input v-model="form.master_page.hero.eyebrow" type="text" class="form-control">
                            </div>
                            <div class="col-md-8 form-group">
                                <label>Hero Title</label>
                                <input v-model="form.master_page.hero.title" type="text" class="form-control">
                            </div>
                            <div class="col-12 form-group mb-0">
                                <label>Hero Description</label>
                                <textarea v-model="form.master_page.hero.description" rows="2" class="form-control"></textarea>
                            </div>
                        </div>
                    </div>

                    <div v-show="activePanel === 'social'" class="border rounded p-3 mb-4">
                        <h4 class="h6 text-uppercase text-muted mb-2">Target: Shared Social Links</h4>
                        <p class="text-muted small mb-3">Preview: link tombol social di halaman `/`, `/product/{slug}`, footer, dan CTA yang memakai data global.</p>
                        <div class="row">
                            <div class="col-md-6 form-group"><label>TikTok URL</label><input v-model="form.tiktok_url" type="text" class="form-control"></div>
                            <div class="col-md-6 form-group"><label>Instagram URL</label><input v-model="form.instagram_url" type="text" class="form-control"></div>
                            <div class="col-md-6 form-group"><label>Facebook URL</label><input v-model="form.facebook_url" type="text" class="form-control"></div>
                            <div class="col-md-6 form-group"><label>WhatsApp URL (Global Social / Contact)</label><input v-model="form.whatsapp_url" type="text" class="form-control"></div>
                            <div class="col-md-6 form-group"><label>WhatsApp URL (Target: "/product/{slug}" Direct to WhatsApp)</label><input v-model="form.product_whatsapp_url" type="text" class="form-control"></div>
                            <div class="col-md-6 form-group"><label>Tokopedia URL</label><input v-model="form.tokopedia_url" type="text" class="form-control"></div>
                            <div class="col-md-6 form-group mb-0"><label>TikTok Shop URL</label><input v-model="form.tiktok_shop_url" type="text" class="form-control"></div>
                        </div>
                        <hr>
                        <h4 class="h6 text-uppercase text-muted mb-3">Target: "/" - Social Hub Section</h4>
                        <div class="row mb-3">
                            <div class="col-md-4 form-group"><label>Section Eyebrow</label><input v-model="form.master_page.social_hub_section.eyebrow" type="text" class="form-control"></div>
                            <div class="col-md-8 form-group"><label>Section Title</label><input v-model="form.master_page.social_hub_section.title" type="text" class="form-control"></div>
                            <div class="col-12 form-group"><label>Section Description</label><textarea v-model="form.master_page.social_hub_section.description" rows="2" class="form-control"></textarea></div>
                        </div>
                        <div class="row">
                            <div class="col-12"><h5 class="mb-3">Card: TikTok Review Highlight</h5></div>
                            <div class="col-md-4 form-group"><label>Eyebrow</label><input v-model="form.cards.tiktok.eyebrow" type="text" class="form-control"></div>
                            <div class="col-md-8 form-group"><label>Title</label><input v-model="form.cards.tiktok.title" type="text" class="form-control"></div>
                            <div class="col-12 form-group"><label>Description</label><textarea v-model="form.cards.tiktok.description" rows="2" class="form-control"></textarea></div>
                        </div>
                        <div class="row">
                            <div class="col-12"><h5 class="mb-3">Card: Instagram</h5></div>
                            <div class="col-md-4 form-group"><label>Eyebrow</label><input v-model="form.cards.instagram.eyebrow" type="text" class="form-control"></div>
                            <div class="col-md-8 form-group"><label>Title</label><input v-model="form.cards.instagram.title" type="text" class="form-control"></div>
                            <div class="col-12 form-group"><label>Description</label><textarea v-model="form.cards.instagram.description" rows="2" class="form-control"></textarea></div>
                        </div>
                        <div class="row mb-0">
                            <div class="col-12"><h5 class="mb-3">Card: WhatsApp</h5></div>
                            <div class="col-md-4 form-group"><label>Eyebrow</label><input v-model="form.cards.whatsapp.eyebrow" type="text" class="form-control"></div>
                            <div class="col-md-8 form-group"><label>Title</label><input v-model="form.cards.whatsapp.title" type="text" class="form-control"></div>
                            <div class="col-12 form-group mb-0"><label>Description</label><textarea v-model="form.cards.whatsapp.description" rows="2" class="form-control"></textarea></div>
                        </div>
                    </div>

                    <div v-show="activePanel === 'collection'" class="border rounded p-3 mb-4">
                        <h4 class="h6 text-uppercase text-muted mb-2">Target: "/" - The Collection Header</h4>
                        <p class="text-muted small mb-3">Preview: judul section collection dan microcopy di setiap product card pada halaman `/`.</p>
                        <div class="row">
                            <div class="col-md-4 form-group"><label>Section Eyebrow</label><input v-model="form.master_page.collection_section.eyebrow" type="text" class="form-control"></div>
                            <div class="col-md-8 form-group"><label>Section Title</label><input v-model="form.master_page.collection_section.title" type="text" class="form-control"></div>
                            <div class="col-12 form-group"><label>Section Description</label><textarea v-model="form.master_page.collection_section.description" rows="2" class="form-control"></textarea></div>
                            <div class="col-md-6 form-group"><label>Card Active Status</label><input v-model="form.master_page.collection_section.card_active_status" type="text" class="form-control"></div>
                            <div class="col-md-6 form-group"><label>Card Inactive Status</label><input v-model="form.master_page.collection_section.card_inactive_status" type="text" class="form-control"></div>
                            <div class="col-md-6 form-group"><label>Card Active CTA</label><input v-model="form.master_page.collection_section.card_active_cta" type="text" class="form-control"></div>
                            <div class="col-md-6 form-group mb-0"><label>Card Inactive CTA</label><input v-model="form.master_page.collection_section.card_inactive_cta" type="text" class="form-control"></div>
                        </div>
                    </div>

                    <div v-show="activePanel === 'manifesto'" class="border rounded p-3 mb-4">
                        <h4 class="h6 text-uppercase text-muted mb-2">Target: "/" - Brand Manifesto</h4>
                        <p class="text-muted small mb-3">Preview: blok manifesto brand setelah section collection di halaman `/`.</p>
                        <div class="row">
                            <div class="col-md-4 form-group"><label>Section Eyebrow</label><input v-model="form.master_page.manifesto.eyebrow" type="text" class="form-control"></div>
                            <div class="col-md-8 form-group"><label>Section Title</label><input v-model="form.master_page.manifesto.title" type="text" class="form-control"></div>
                            <div class="col-12 form-group mb-0"><label>Section Description</label><textarea v-model="form.master_page.manifesto.description" rows="3" class="form-control"></textarea></div>
                        </div>
                    </div>

                    <div v-show="activePanel === 'discovery'" class="border rounded p-3 mb-4">
                        <h4 class="h6 text-uppercase text-muted mb-2">Target: "/" - Journal / Discovery</h4>
                        <p class="text-muted small mb-3">Preview: header discovery dan daftar preview card edukasi di halaman `/`. Jika item lebih dari 2, frontend otomatis menampilkannya sebagai slider.</p>
                        <div class="row">
                            <div class="col-md-4 form-group"><label>Section Eyebrow</label><input v-model="form.master_page.discovery.eyebrow" type="text" class="form-control"></div>
                            <div class="col-md-8 form-group"><label>Section Title</label><input v-model="form.master_page.discovery.title" type="text" class="form-control"></div>
                            <div class="col-12 form-group"><label>Section Description</label><textarea v-model="form.master_page.discovery.description" rows="2" class="form-control"></textarea></div>
                            <div class="col-12 form-group"><label>Preview Eyebrow</label><input v-model="form.master_page.discovery.preview_eyebrow" type="text" class="form-control"></div>
                        </div>
                        <div class="card bg-light mt-3">
                            <div class="card-header d-flex justify-content-between align-items-center">
                                <strong>Discovery Preview Cards</strong>
                                <button type="button" class="btn btn-sm btn-outline-dark" @click="addDiscoveryPreview">Tambah Card</button>
                            </div>
                            <div class="card-body">
                                <div v-for="(card, index) in form.master_page.discovery.preview_cards" :key="'discovery-preview-' + index" class="border rounded p-3 mb-3">
                                    <div class="d-flex justify-content-between align-items-center mb-3">
                                        <strong>Preview Card {{ index + 1 }}</strong>
                                        <button type="button" class="btn btn-sm btn-outline-danger" @click="removeDiscoveryPreview(index)">Hapus</button>
                                    </div>
                                    <div class="form-group">
                                        <label>Title</label>
                                        <input v-model="card.title" type="text" class="form-control">
                                    </div>
                                    <div class="form-group mb-0">
                                        <label>Description</label>
                                        <textarea v-model="card.description" rows="2" class="form-control"></textarea>
                                    </div>
                                </div>
                                <div v-if="!form.master_page.discovery.preview_cards.length" class="text-muted">Belum ada discovery preview card. Tambahkan minimal satu card untuk slider/journal preview.</div>
                            </div>
                        </div>
                    </div>
                    <div v-show="activePanel === 'product'" class="border rounded p-3 mb-4">
                        <h4 class="h6 text-uppercase text-muted mb-2">Target: "/product/{slug}" - Product Landing Microcopy</h4>
                        <p class="text-muted small mb-3">Preview: navbar, hero CTA, story, notes, ingredients, education, FAQ, marketplace sheet, sticky CTA, prefilled WhatsApp, theme preset, dan SEO fallback preset di halaman detail produk.</p>
                        <div class="row">
                            <div class="col-12"><h5 class="mb-3">Navigation Labels</h5></div>
                            <div class="col-md-2 form-group"><label>Home Label</label><input v-model="form.product_page.navigation.home_label" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Brand Label</label><input v-model="form.product_page.navigation.brand_label" type="text" class="form-control"></div>
                            <div class="col-md-2 form-group"><label>Collection Label</label><input v-model="form.product_page.navigation.collection_label" type="text" class="form-control"></div>
                            <div class="col-md-2 form-group"><label>Discovery Label</label><input v-model="form.product_page.navigation.discovery_label" type="text" class="form-control"></div>
                            <div class="col-md-2 form-group"><label>Contact Label</label><input v-model="form.product_page.navigation.contact_label" type="text" class="form-control"></div>
                        </div>
                        <hr>
                        <div class="row">
                            <div class="col-12"><h5 class="mb-3">Theme & SEO Defaults</h5></div>
                            <div class="col-md-6 form-group">
                                <label>Default Theme Preset</label>
                                <select v-model="form.product_page.default_theme_key" class="form-control">
                                    <option v-for="key in presetKeys" :key="'theme-default-' + key" :value="key">{{ presetLabels[key] }}</option>
                                </select>
                            </div>
                            <div class="col-md-6 form-group">
                                <label>Default SEO Fallback Preset</label>
                                <select v-model="form.product_page.default_seo_fallback_key" class="form-control">
                                    <option v-for="key in presetKeys" :key="'seo-default-' + key" :value="key">{{ presetLabels[key] }}</option>
                                </select>
                            </div>
                        </div>
                        <hr>
                        <div class="row">
                            <div class="col-12"><h5 class="mb-3">Hero Labels & Actions</h5></div>
                            <div class="col-md-4 form-group"><label>Default Eyebrow</label><input v-model="form.product_page.hero.eyebrow_default" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Badge</label><input v-model="form.product_page.hero.badge" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Hero Description Fallback</label><input v-model="form.product_page.hero.description_fallback" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Share Text Prefix</label><input v-model="form.product_page.hero.share_text_prefix" type="text" class="form-control"></div>
                            <div class="col-md-3 form-group"><label>Price Label</label><input v-model="form.product_page.hero.price_label" type="text" class="form-control"></div>
                            <div class="col-md-3 form-group"><label>Stock Label</label><input v-model="form.product_page.hero.stock_label" type="text" class="form-control"></div>
                            <div class="col-md-3 form-group"><label>Ready Suffix</label><input v-model="form.product_page.hero.stock_ready_suffix" type="text" class="form-control"></div>
                            <div class="col-md-3 form-group"><label>Pre-order Label</label><input v-model="form.product_page.hero.stock_preorder_label" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Primary CTA Label</label><input v-model="form.product_page.hero.primary_cta_label" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Primary CTA Href</label><input v-model="form.product_page.hero.primary_cta_href" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>WhatsApp Label</label><input v-model="form.product_page.hero.whatsapp_label" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Secondary CTA Label</label><input v-model="form.product_page.hero.secondary_cta_label" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Secondary CTA Href</label><input v-model="form.product_page.hero.secondary_cta_href" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Buy Options Label</label><input v-model="form.product_page.hero.buy_options_label" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Share Facebook Label</label><input v-model="form.product_page.hero.share_facebook_label" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Share Instagram Label</label><input v-model="form.product_page.hero.share_instagram_label" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group mb-0"><label>Share TikTok Label</label><input v-model="form.product_page.hero.share_tiktok_label" type="text" class="form-control"></div>
                        </div>
                        <hr>
                        <div class="row">
                            <div class="col-12"><h5 class="mb-3">Theme Presets</h5></div>
                            <div v-for="key in presetKeys" :key="'theme-' + key" class="col-12 border rounded p-3 mb-3">
                                <h6 class="mb-3">{{ presetLabels[key] }}</h6>
                                <div class="row">
                                    <div class="col-md-4 form-group"><label>Preset Label</label><input v-model="form.product_page.theme_presets[key].label" type="text" class="form-control"></div>
                                    <div class="col-md-4 form-group"><label>Hero Eyebrow</label><input v-model="form.product_page.theme_presets[key].eyebrow" type="text" class="form-control"></div>
                                    <div class="col-md-4 form-group"><label>Accent</label><input v-model="form.product_page.theme_presets[key].accent" type="text" class="form-control"></div>
                                    <div class="col-md-4 form-group"><label>Accent Soft</label><input v-model="form.product_page.theme_presets[key].accentSoft" type="text" class="form-control"></div>
                                    <div class="col-md-4 form-group"><label>Accent Deep</label><input v-model="form.product_page.theme_presets[key].accentDeep" type="text" class="form-control"></div>
                                    <div class="col-md-4 form-group"><label>Halo</label><input v-model="form.product_page.theme_presets[key].halo" type="text" class="form-control"></div>
                                    <div class="col-12 form-group mb-0"><label>Background</label><textarea v-model="form.product_page.theme_presets[key].background" rows="2" class="form-control"></textarea></div>
                                </div>
                            </div>
                        </div>
                        <hr>
                        <div class="row">
                            <div class="col-12"><h5 class="mb-3">SEO Fallback Presets</h5></div>
                            <div v-for="key in presetKeys" :key="'seo-' + key" class="col-12 border rounded p-3 mb-3">
                                <h6 class="mb-3">{{ presetLabels[key] }}</h6>
                                <div class="row">
                                    <div class="col-md-4 form-group"><label>Preset Label</label><input v-model="form.product_page.seo_fallbacks[key].label" type="text" class="form-control"></div>
                                    <div class="col-md-4 form-group"><label>Robots</label><input v-model="form.product_page.seo_fallbacks[key].robots" type="text" class="form-control"></div>
                                    <div class="col-md-4 form-group"><label>OG Image URL</label><input v-model="form.product_page.seo_fallbacks[key].og_image_url" type="text" class="form-control"></div>
                                    <div class="col-md-6 form-group"><label>Title Template</label><input v-model="form.product_page.seo_fallbacks[key].title_template" type="text" class="form-control"></div>
                                    <div class="col-md-6 form-group"><label>OG Title Template</label><input v-model="form.product_page.seo_fallbacks[key].og_title_template" type="text" class="form-control"></div>
                                    <div class="col-md-6 form-group"><label>Description Template</label><textarea v-model="form.product_page.seo_fallbacks[key].description_template" rows="2" class="form-control"></textarea></div>
                                    <div class="col-md-6 form-group mb-0"><label>OG Description Template</label><textarea v-model="form.product_page.seo_fallbacks[key].og_description_template" rows="2" class="form-control"></textarea></div>
                                </div>
                            </div>
                        </div>
                        <hr>
                        <div class="row">
                            <div class="col-12"><h5 class="mb-3">Story & Notes</h5></div>
                            <div class="col-md-4 form-group"><label>Story Kicker</label><input v-model="form.product_page.story.kicker" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Story Title Template</label><input v-model="form.product_page.story.title_template" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Bottle Fallback Name</label><input v-model="form.product_page.story.bottle_fallback_name" type="text" class="form-control"></div>
                            <div class="col-12 form-group"><label>Story Description</label><textarea v-model="form.product_page.story.description" rows="2" class="form-control"></textarea></div>
                            <div class="col-12"><h6 class="mb-3 mt-2">Floating Bottle Placeholder</h6></div>
                            <div class="col-md-3 form-group"><label>Brand Label</label><input v-model="form.product_page.story.bottle.brand_label" type="text" class="form-control"></div>
                            <div class="col-md-3 form-group"><label>Cap Top</label><input v-model="form.product_page.story.bottle.cap_top" type="text" class="form-control"></div>
                            <div class="col-md-3 form-group"><label>Cap Middle</label><input v-model="form.product_page.story.bottle.cap_middle" type="text" class="form-control"></div>
                            <div class="col-md-3 form-group"><label>Cap Bottom</label><input v-model="form.product_page.story.bottle.cap_bottom" type="text" class="form-control"></div>
                            <div class="col-md-3 form-group"><label>Liquid From</label><input v-model="form.product_page.story.bottle.liquid_from" type="text" class="form-control"></div>
                            <div class="col-md-3 form-group"><label>Liquid To</label><input v-model="form.product_page.story.bottle.liquid_to" type="text" class="form-control"></div>
                            <div class="col-md-3 form-group"><label>Label Background</label><input v-model="form.product_page.story.bottle.label_background" type="text" class="form-control"></div>
                            <div class="col-md-3 form-group"><label>Label Border</label><input v-model="form.product_page.story.bottle.label_border" type="text" class="form-control"></div>
                            <div class="col-md-3 form-group"><label class="d-flex align-items-center gap-2 mb-0"><input v-model="form.product_page.story.bottle.use_product_image_when_available" type="checkbox"><span>Use product image when available</span></label></div>
                            <div class="col-md-3 form-group"><label class="d-flex align-items-center gap-2 mb-0"><input v-model="form.product_page.story.bottle.floating_mobile" type="checkbox"><span>Floating on mobile</span></label></div>
                            <div class="col-md-3 form-group"><label class="d-flex align-items-center gap-2 mb-0"><input v-model="form.product_page.story.bottle.tilt_desktop" type="checkbox"><span>Tilt on desktop</span></label></div>
                            <div class="col-md-3 form-group"><label class="d-flex align-items-center gap-2 mb-0"><input v-model="form.product_page.story.bottle.show_label" type="checkbox"><span>Show bottle label</span></label></div>
                            <div class="col-md-3 form-group"><label class="d-flex align-items-center gap-2 mb-0"><input v-model="form.product_page.story.bottle.show_glow" type="checkbox"><span>Show glow</span></label></div>
                            <div class="col-md-3 form-group"><label class="d-flex align-items-center gap-2 mb-0"><input v-model="form.product_page.story.bottle.show_shadow" type="checkbox"><span>Show shadow</span></label></div>
                            <div class="col-md-3 form-group mb-0"><label class="d-flex align-items-center gap-2 mb-0"><input v-model="form.product_page.story.bottle.show_liquid" type="checkbox"><span>Show liquid</span></label></div>
                            <div class="col-md-4 form-group"><label>Top Notes Title</label><input v-model="form.product_page.notes.top_title" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Heart Notes Title</label><input v-model="form.product_page.notes.middle_title" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Base Notes Title</label><input v-model="form.product_page.notes.base_title" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Top Notes Fallback</label><textarea v-model="form.product_page.notes.top_fallback_description" rows="2" class="form-control"></textarea></div>
                            <div class="col-md-4 form-group"><label>Heart Notes Fallback</label><textarea v-model="form.product_page.notes.middle_fallback_description" rows="2" class="form-control"></textarea></div>
                            <div class="col-md-4 form-group"><label>Base Notes Fallback</label><textarea v-model="form.product_page.notes.base_fallback_description" rows="2" class="form-control"></textarea></div>
                            <div class="col-12 form-group mb-0"><label>Detail Fallback Suffix</label><input v-model="form.product_page.notes.detail_fallback_suffix" type="text" class="form-control"></div>
                        </div>
                        <hr>
                        <div class="row">
                            <div class="col-12"><h5 class="mb-3">Ingredients & Education</h5></div>
                            <div class="col-md-4 form-group"><label>Ingredients Section Kicker</label><input v-model="form.product_page.ingredients.section_kicker" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Ingredients Title</label><input v-model="form.product_page.ingredients.title" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Ingredients Card Eyebrow</label><input v-model="form.product_page.ingredients.card_eyebrow" type="text" class="form-control"></div>
                            <div class="col-md-6 form-group"><label>Ingredients Description Template</label><textarea v-model="form.product_page.ingredients.description_template" rows="2" class="form-control"></textarea></div>
                            <div class="col-md-6 form-group"><label>Ingredient Item Fallback</label><input v-model="form.product_page.ingredients.item_fallback_description" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Education Section Kicker</label><input v-model="form.product_page.education.section_kicker" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Education Default Title</label><input v-model="form.product_page.education.default_title" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Education Card Eyebrow</label><input v-model="form.product_page.education.card_eyebrow" type="text" class="form-control"></div>
                            <div class="col-12 form-group"><label>Education Default Description</label><textarea v-model="form.product_page.education.default_description" rows="2" class="form-control"></textarea></div>
                            <div class="col-12 form-group mb-0">
                                <label>Education Default Tips</label>
                                <textarea v-model="educationTipsText" rows="4" class="form-control"></textarea>
                                <small class="form-text text-muted">Satu tips per baris. Dipakai saat product belum punya education tips khusus.</small>
                            </div>
                        </div>
                        <hr>
                        <div class="row">
                            <div class="col-12"><h5 class="mb-3">FAQ, Marketplace, Sticky CTA</h5></div>
                            <div class="col-md-3 form-group"><label>FAQ Kicker</label><input v-model="form.product_page.faq.kicker" type="text" class="form-control"></div>
                            <div class="col-md-9 form-group"><label>FAQ Title</label><input v-model="form.product_page.faq.title" type="text" class="form-control"></div>
                            <div class="col-12 form-group"><label>FAQ Description</label><textarea v-model="form.product_page.faq.description" rows="2" class="form-control"></textarea></div>
                            <div class="col-md-4 form-group"><label>Marketplace Title</label><input v-model="form.product_page.marketplace.title" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Tokopedia Label</label><input v-model="form.product_page.marketplace.tokopedia_label" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>TikTok Shop Label</label><input v-model="form.product_page.marketplace.tiktok_shop_label" type="text" class="form-control"></div>
                            <div class="col-12 form-group"><label>Marketplace Empty State</label><input v-model="form.product_page.marketplace.empty_state" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Sticky CTA Label</label><input v-model="form.product_page.sticky_cta.label" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Loading Message</label><input v-model="form.product_page.system_messages.loading" type="text" class="form-control"></div>
                            <div class="col-md-4 form-group"><label>Error Message</label><input v-model="form.product_page.system_messages.error" type="text" class="form-control"></div>
                            <div class="col-12 form-group mb-0"><label>WhatsApp Message Template</label><input v-model="form.product_page.contact.whatsapp_message_template" type="text" class="form-control"></div>
                        </div>

                    </div>

                    <div v-show="activePanel === 'footer'" class="border rounded p-3 mb-4">
                        <h4 class="h6 text-uppercase text-muted mb-2">Target: "/" & "/product/{slug}" - Main Footer</h4>
                        <p class="text-muted small mb-3">Preview: footer global di halaman `/` dan `/product/{slug}`, termasuk link label footer dan pesan loading/error master page.</p>
                        <div class="row">
                            <div class="col-md-4 form-group"><label>Footer Eyebrow</label><input v-model="form.master_page.footer.eyebrow" type="text" class="form-control"></div>
                            <div class="col-md-8 form-group"><label>Footer Title</label><input v-model="form.master_page.footer.title" type="text" class="form-control"></div>
                            <div class="col-12 form-group"><label>Footer Description</label><textarea v-model="form.master_page.footer.description" rows="2" class="form-control"></textarea></div>
                            <div class="col-md-3 form-group"><label>Instagram Label</label><input v-model="form.master_page.footer.instagram_label" type="text" class="form-control"></div>
                            <div class="col-md-3 form-group"><label>TikTok Label</label><input v-model="form.master_page.footer.tiktok_label" type="text" class="form-control"></div>
                            <div class="col-md-3 form-group"><label>Facebook Label</label><input v-model="form.master_page.footer.facebook_label" type="text" class="form-control"></div>
                            <div class="col-md-3 form-group"><label>WhatsApp Label</label><input v-model="form.master_page.footer.whatsapp_label" type="text" class="form-control"></div>
                            <div class="col-md-6 form-group"><label>Loading Message</label><input v-model="form.master_page.system_messages.loading" type="text" class="form-control"></div>
                            <div class="col-md-6 form-group mb-0"><label>Error Message</label><input v-model="form.master_page.system_messages.error" type="text" class="form-control"></div>
                        </div>
                    </div>

                    <button type="button" class="btn btn-dark" :disabled="form.processing" @click="submit">Simpan Global Settings</button>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { Head, useForm } from '@inertiajs/vue3';
import { ref, watch } from 'vue';
import AppLayout from '../../Layouts/AppLayout.vue';
import { adminUrl } from '../../utils/admin';

defineOptions({ layout: AppLayout });

const props = defineProps({
    masterSocialHub: { type: Object, default: () => ({}) },
});

const panelOptions = [
    { id: 'media', label: 'Media' },
    { id: 'hero', label: 'Hero' },
    { id: 'social', label: 'Social' },
    { id: 'collection', label: 'Collection' },
    { id: 'manifesto', label: 'Manifesto' },
    { id: 'discovery', label: 'Discovery' },
    { id: 'product', label: 'Product Page' },
    { id: 'footer', label: 'Footer' },
];

const activePanel = ref('media');

const presetKeys = ['signature', 'fresh', 'floral', 'woody'];
const presetLabels = {
    signature: 'Signature',
    fresh: 'Fresh',
    floral: 'Floral',
    woody: 'Woody',
};

const createThemePreset = (source = {}) => ({
    label: source.label ?? '',
    eyebrow: source.eyebrow ?? '',
    accent: source.accent ?? '',
    accentSoft: source.accentSoft ?? '',
    accentDeep: source.accentDeep ?? '',
    background: source.background ?? '',
    halo: source.halo ?? '',
});

const createSeoFallbackPreset = (source = {}) => ({
    label: source.label ?? '',
    title_template: source.title_template ?? '',
    description_template: source.description_template ?? '',
    og_title_template: source.og_title_template ?? '',
    og_description_template: source.og_description_template ?? '',
    og_image_url: source.og_image_url ?? '',
    robots: source.robots ?? '',
});

const createState = (source = {}) => ({
    _method: 'put',
    master_page: {
        hero: {
            eyebrow: source.master_page?.hero?.eyebrow ?? '',
            title: source.master_page?.hero?.title ?? '',
            description: source.master_page?.hero?.description ?? '',
        },
        social_hub_section: {
            eyebrow: source.master_page?.social_hub_section?.eyebrow ?? '',
            title: source.master_page?.social_hub_section?.title ?? '',
            description: source.master_page?.social_hub_section?.description ?? '',
        },
        collection_section: {
            eyebrow: source.master_page?.collection_section?.eyebrow ?? '',
            title: source.master_page?.collection_section?.title ?? '',
            description: source.master_page?.collection_section?.description ?? '',
            card_active_status: source.master_page?.collection_section?.card_active_status ?? '',
            card_inactive_status: source.master_page?.collection_section?.card_inactive_status ?? '',
            card_active_cta: source.master_page?.collection_section?.card_active_cta ?? '',
            card_inactive_cta: source.master_page?.collection_section?.card_inactive_cta ?? '',
        },
        manifesto: {
            eyebrow: source.master_page?.manifesto?.eyebrow ?? '',
            title: source.master_page?.manifesto?.title ?? '',
            description: source.master_page?.manifesto?.description ?? '',
        },
        discovery: {
            eyebrow: source.master_page?.discovery?.eyebrow ?? '',
            title: source.master_page?.discovery?.title ?? '',
            description: source.master_page?.discovery?.description ?? '',
            preview_eyebrow: source.master_page?.discovery?.preview_eyebrow ?? '',
            preview_cards: (source.master_page?.discovery?.preview_cards ?? []).map((item) => ({
                title: item?.title ?? '',
                description: item?.description ?? '',
            })),
        },
        footer: {
            eyebrow: source.master_page?.footer?.eyebrow ?? '',
            title: source.master_page?.footer?.title ?? '',
            description: source.master_page?.footer?.description ?? '',
            instagram_label: source.master_page?.footer?.instagram_label ?? '',
            tiktok_label: source.master_page?.footer?.tiktok_label ?? '',
            facebook_label: source.master_page?.footer?.facebook_label ?? '',
            whatsapp_label: source.master_page?.footer?.whatsapp_label ?? '',
        },
        system_messages: {
            loading: source.master_page?.system_messages?.loading ?? '',
            error: source.master_page?.system_messages?.error ?? '',
        },
    },
    product_page: {
        default_theme_key: source.product_page?.default_theme_key ?? 'signature',
        default_seo_fallback_key: source.product_page?.default_seo_fallback_key ?? 'signature',
        navigation: {
            home_label: source.product_page?.navigation?.home_label ?? '',
            brand_label: source.product_page?.navigation?.brand_label ?? '',
            collection_label: source.product_page?.navigation?.collection_label ?? '',
            discovery_label: source.product_page?.navigation?.discovery_label ?? '',
            contact_label: source.product_page?.navigation?.contact_label ?? '',
        },
        hero: {
            eyebrow_default: source.product_page?.hero?.eyebrow_default ?? '',
            badge: source.product_page?.hero?.badge ?? '',
            description_fallback: source.product_page?.hero?.description_fallback ?? '',
            price_label: source.product_page?.hero?.price_label ?? '',
            stock_label: source.product_page?.hero?.stock_label ?? '',
            stock_ready_suffix: source.product_page?.hero?.stock_ready_suffix ?? '',
            stock_preorder_label: source.product_page?.hero?.stock_preorder_label ?? '',
            primary_cta_label: source.product_page?.hero?.primary_cta_label ?? '',
            primary_cta_href: source.product_page?.hero?.primary_cta_href ?? '',
            secondary_cta_label: source.product_page?.hero?.secondary_cta_label ?? '',
            secondary_cta_href: source.product_page?.hero?.secondary_cta_href ?? '',
            whatsapp_label: source.product_page?.hero?.whatsapp_label ?? '',
            buy_options_label: source.product_page?.hero?.buy_options_label ?? '',
            share_facebook_label: source.product_page?.hero?.share_facebook_label ?? '',
            share_instagram_label: source.product_page?.hero?.share_instagram_label ?? '',
            share_tiktok_label: source.product_page?.hero?.share_tiktok_label ?? '',
            share_text_prefix: source.product_page?.hero?.share_text_prefix ?? '',
        },
        theme_presets: Object.fromEntries(
            presetKeys.map((key) => [key, createThemePreset(source.product_page?.theme_presets?.[key] ?? {})]),
        ),
        seo_fallbacks: Object.fromEntries(
            presetKeys.map((key) => [key, createSeoFallbackPreset(source.product_page?.seo_fallbacks?.[key] ?? {})]),
        ),
        story: {
            kicker: source.product_page?.story?.kicker ?? '',
            title_template: source.product_page?.story?.title_template ?? '',
            description: source.product_page?.story?.description ?? '',
            bottle_fallback_name: source.product_page?.story?.bottle_fallback_name ?? '',
            bottle: {
                use_product_image_when_available: source.product_page?.story?.bottle?.use_product_image_when_available ?? true,
                floating_mobile: source.product_page?.story?.bottle?.floating_mobile ?? true,
                tilt_desktop: source.product_page?.story?.bottle?.tilt_desktop ?? true,
                show_glow: source.product_page?.story?.bottle?.show_glow ?? true,
                show_shadow: source.product_page?.story?.bottle?.show_shadow ?? true,
                show_liquid: source.product_page?.story?.bottle?.show_liquid ?? true,
                show_label: source.product_page?.story?.bottle?.show_label ?? true,
                brand_label: source.product_page?.story?.bottle?.brand_label ?? 'AVENOR',
                cap_top: source.product_page?.story?.bottle?.cap_top ?? '#f3e5b0',
                cap_middle: source.product_page?.story?.bottle?.cap_middle ?? '#d4af37',
                cap_bottom: source.product_page?.story?.bottle?.cap_bottom ?? '#8d6a1f',
                liquid_from: source.product_page?.story?.bottle?.liquid_from ?? 'rgba(241,215,122,.12)',
                liquid_to: source.product_page?.story?.bottle?.liquid_to ?? 'rgba(212,175,55,.52)',
                label_background: source.product_page?.story?.bottle?.label_background ?? 'rgba(10,10,10,.34)',
                label_border: source.product_page?.story?.bottle?.label_border ?? 'rgba(212,175,55,.18)',
            },
        },
        notes: {
            top_title: source.product_page?.notes?.top_title ?? '',
            middle_title: source.product_page?.notes?.middle_title ?? '',
            base_title: source.product_page?.notes?.base_title ?? '',
            top_fallback_description: source.product_page?.notes?.top_fallback_description ?? '',
            middle_fallback_description: source.product_page?.notes?.middle_fallback_description ?? '',
            base_fallback_description: source.product_page?.notes?.base_fallback_description ?? '',
            detail_fallback_suffix: source.product_page?.notes?.detail_fallback_suffix ?? '',
        },
        ingredients: {
            section_kicker: source.product_page?.ingredients?.section_kicker ?? '',
            title: source.product_page?.ingredients?.title ?? '',
            description_template: source.product_page?.ingredients?.description_template ?? '',
            card_eyebrow: source.product_page?.ingredients?.card_eyebrow ?? '',
            item_fallback_description: source.product_page?.ingredients?.item_fallback_description ?? '',
        },
        education: {
            section_kicker: source.product_page?.education?.section_kicker ?? '',
            default_title: source.product_page?.education?.default_title ?? '',
            default_description: source.product_page?.education?.default_description ?? '',
            card_eyebrow: source.product_page?.education?.card_eyebrow ?? '',
            default_tips: (source.product_page?.education?.default_tips ?? []).map((tip) => String(tip ?? '')),
        },
        faq: {
            kicker: source.product_page?.faq?.kicker ?? '',
            title: source.product_page?.faq?.title ?? '',
            description: source.product_page?.faq?.description ?? '',
        },
        marketplace: {
            title: source.product_page?.marketplace?.title ?? '',
            tokopedia_label: source.product_page?.marketplace?.tokopedia_label ?? '',
            tiktok_shop_label: source.product_page?.marketplace?.tiktok_shop_label ?? '',
            empty_state: source.product_page?.marketplace?.empty_state ?? '',
        },
        sticky_cta: {
            label: source.product_page?.sticky_cta?.label ?? '',
        },
        system_messages: {
            loading: source.product_page?.system_messages?.loading ?? '',
            error: source.product_page?.system_messages?.error ?? '',
        },
        contact: {
            whatsapp_message_template: source.product_page?.contact?.whatsapp_message_template ?? '',
        },
    },
    tiktok_url: source.tiktok_url ?? '',
    instagram_url: source.instagram_url ?? '',
    facebook_url: source.facebook_url ?? '',
    whatsapp_url: source.whatsapp_url ?? '',
    product_whatsapp_url: source.product_whatsapp_url ?? '',
    tokopedia_url: source.tokopedia_url ?? '',
    tiktok_shop_url: source.tiktok_shop_url ?? '',
    cards: {
        tiktok: {
            eyebrow: source.cards?.tiktok?.eyebrow ?? '',
            title: source.cards?.tiktok?.title ?? '',
            description: source.cards?.tiktok?.description ?? '',
        },
        instagram: {
            eyebrow: source.cards?.instagram?.eyebrow ?? '',
            title: source.cards?.instagram?.title ?? '',
            description: source.cards?.instagram?.description ?? '',
        },
        whatsapp: {
            eyebrow: source.cards?.whatsapp?.eyebrow ?? '',
            title: source.cards?.whatsapp?.title ?? '',
            description: source.cards?.whatsapp?.description ?? '',
        },
    },
    hero_video_file: null,
    remove_hero_video: false,
});

const form = useForm(createState(props.masterSocialHub));
const educationTipsText = ref((form.product_page.education.default_tips || []).join('\n'));

watch(educationTipsText, (value) => {
    form.product_page.education.default_tips = String(value)
        .split(/\r?\n/)
        .map((item) => item.trim())
        .filter(Boolean);
});

const addDiscoveryPreview = () => {
    form.master_page.discovery.preview_cards.push({ title: '', description: '' });
};

const removeDiscoveryPreview = (index) => {
    form.master_page.discovery.preview_cards.splice(index, 1);
};

const handleHeroVideoChange = (event) => {
    form.hero_video_file = event.target.files?.[0] ?? null;

    if (form.hero_video_file) {
        form.remove_hero_video = false;
    }
};

const submit = () => {
    form.post(adminUrl('/global-settings/master-social-hub'), {
        forceFormData: true,
        preserveScroll: true,
    });
};
</script>






