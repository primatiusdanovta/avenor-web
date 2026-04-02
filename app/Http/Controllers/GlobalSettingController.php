<?php

namespace App\Http\Controllers;

use App\Models\GlobalSetting;
use App\Support\HeroVideoOptimizer;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Inertia\Inertia;
use Inertia\Response;
use RuntimeException;
use Symfony\Component\HttpFoundation\StreamedResponse;
use Throwable;

class GlobalSettingController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        return Inertia::render('GlobalSettings/Index', [
            'masterSocialHub' => GlobalSetting::masterSocialHub(),
        ]);
    }

    public function updateMasterSocialHub(Request $request, HeroVideoOptimizer $heroVideoOptimizer): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $validated = $request->validate([
            'master_page' => ['nullable', 'array'],
            'master_page.hero' => ['nullable', 'array'],
            'master_page.hero.eyebrow' => ['nullable', 'string', 'max:100'],
            'master_page.hero.title' => ['nullable', 'string', 'max:255'],
            'master_page.hero.description' => ['nullable', 'string', 'max:2000'],
            'master_page.social_hub_section' => ['nullable', 'array'],
            'master_page.social_hub_section.eyebrow' => ['nullable', 'string', 'max:100'],
            'master_page.social_hub_section.title' => ['nullable', 'string', 'max:255'],
            'master_page.social_hub_section.description' => ['nullable', 'string', 'max:2000'],
            'master_page.collection_section' => ['nullable', 'array'],
            'master_page.collection_section.eyebrow' => ['nullable', 'string', 'max:100'],
            'master_page.collection_section.title' => ['nullable', 'string', 'max:255'],
            'master_page.collection_section.description' => ['nullable', 'string', 'max:2000'],
            'master_page.collection_section.card_active_status' => ['nullable', 'string', 'max:100'],
            'master_page.collection_section.card_inactive_status' => ['nullable', 'string', 'max:100'],
            'master_page.collection_section.card_active_cta' => ['nullable', 'string', 'max:100'],
            'master_page.collection_section.card_inactive_cta' => ['nullable', 'string', 'max:100'],
            'master_page.manifesto' => ['nullable', 'array'],
            'master_page.manifesto.eyebrow' => ['nullable', 'string', 'max:100'],
            'master_page.manifesto.title' => ['nullable', 'string', 'max:255'],
            'master_page.manifesto.description' => ['nullable', 'string', 'max:2000'],
            'master_page.discovery' => ['nullable', 'array'],
            'master_page.discovery.eyebrow' => ['nullable', 'string', 'max:100'],
            'master_page.discovery.title' => ['nullable', 'string', 'max:255'],
            'master_page.discovery.description' => ['nullable', 'string', 'max:2000'],
            'master_page.discovery.preview_eyebrow' => ['nullable', 'string', 'max:100'],
            'master_page.discovery.preview_cards' => ['nullable', 'array'],
            'master_page.discovery.preview_cards.*' => ['nullable', 'array'],
            'master_page.discovery.preview_cards.*.title' => ['nullable', 'string', 'max:255'],
            'master_page.discovery.preview_cards.*.description' => ['nullable', 'string', 'max:1000'],
            'master_page.footer' => ['nullable', 'array'],
            'master_page.footer.eyebrow' => ['nullable', 'string', 'max:100'],
            'master_page.footer.title' => ['nullable', 'string', 'max:255'],
            'master_page.footer.description' => ['nullable', 'string', 'max:2000'],
            'master_page.footer.instagram_label' => ['nullable', 'string', 'max:100'],
            'master_page.footer.tiktok_label' => ['nullable', 'string', 'max:100'],
            'master_page.footer.facebook_label' => ['nullable', 'string', 'max:100'],
            'master_page.footer.whatsapp_label' => ['nullable', 'string', 'max:100'],
            'master_page.system_messages' => ['nullable', 'array'],
            'master_page.system_messages.loading' => ['nullable', 'string', 'max:255'],
            'master_page.system_messages.error' => ['nullable', 'string', 'max:255'],

            'product_page' => ['nullable', 'array'],
            'product_page.default_theme_key' => ['nullable', 'string', 'max:100'],
            'product_page.default_seo_fallback_key' => ['nullable', 'string', 'max:100'],
            'product_page.navigation' => ['nullable', 'array'],
            'product_page.navigation.home_label' => ['nullable', 'string', 'max:100'],
            'product_page.navigation.collection_label' => ['nullable', 'string', 'max:100'],
            'product_page.navigation.discovery_label' => ['nullable', 'string', 'max:100'],
            'product_page.navigation.contact_label' => ['nullable', 'string', 'max:100'],
            'product_page.hero' => ['nullable', 'array'],
            'product_page.hero.eyebrow_default' => ['nullable', 'string', 'max:100'],
            'product_page.hero.badge' => ['nullable', 'string', 'max:100'],
            'product_page.hero.description_fallback' => ['nullable', 'string', 'max:255'],
            'product_page.hero.price_label' => ['nullable', 'string', 'max:100'],
            'product_page.hero.stock_label' => ['nullable', 'string', 'max:100'],
            'product_page.hero.stock_ready_suffix' => ['nullable', 'string', 'max:100'],
            'product_page.hero.stock_preorder_label' => ['nullable', 'string', 'max:100'],
            'product_page.hero.primary_cta_label' => ['nullable', 'string', 'max:100'],
            'product_page.hero.primary_cta_href' => ['nullable', 'string', 'max:255'],
            'product_page.hero.secondary_cta_label' => ['nullable', 'string', 'max:100'],
            'product_page.hero.secondary_cta_href' => ['nullable', 'string', 'max:255'],
            'product_page.hero.whatsapp_label' => ['nullable', 'string', 'max:100'],
            'product_page.hero.buy_options_label' => ['nullable', 'string', 'max:100'],
            'product_page.hero.share_facebook_label' => ['nullable', 'string', 'max:100'],
            'product_page.hero.share_instagram_label' => ['nullable', 'string', 'max:100'],
            'product_page.hero.share_tiktok_label' => ['nullable', 'string', 'max:100'],
            'product_page.hero.share_text_prefix' => ['nullable', 'string', 'max:150'],
            'product_page.story' => ['nullable', 'array'],
            'product_page.story.kicker' => ['nullable', 'string', 'max:100'],
            'product_page.story.title_template' => ['nullable', 'string', 'max:255'],
            'product_page.story.description' => ['nullable', 'string', 'max:1000'],
            'product_page.story.bottle_fallback_name' => ['nullable', 'string', 'max:100'],
            'product_page.story.bottle' => ['nullable', 'array'],
            'product_page.story.bottle.use_product_image_when_available' => ['nullable', 'boolean'],
            'product_page.story.bottle.floating_mobile' => ['nullable', 'boolean'],
            'product_page.story.bottle.tilt_desktop' => ['nullable', 'boolean'],
            'product_page.story.bottle.show_glow' => ['nullable', 'boolean'],
            'product_page.story.bottle.show_shadow' => ['nullable', 'boolean'],
            'product_page.story.bottle.show_liquid' => ['nullable', 'boolean'],
            'product_page.story.bottle.show_label' => ['nullable', 'boolean'],
            'product_page.story.bottle.brand_label' => ['nullable', 'string', 'max:100'],
            'product_page.story.bottle.cap_top' => ['nullable', 'string', 'max:50'],
            'product_page.story.bottle.cap_middle' => ['nullable', 'string', 'max:50'],
            'product_page.story.bottle.cap_bottom' => ['nullable', 'string', 'max:50'],
            'product_page.story.bottle.liquid_from' => ['nullable', 'string', 'max:100'],
            'product_page.story.bottle.liquid_to' => ['nullable', 'string', 'max:100'],
            'product_page.story.bottle.label_background' => ['nullable', 'string', 'max:100'],
            'product_page.story.bottle.label_border' => ['nullable', 'string', 'max:100'],
            'product_page.notes' => ['nullable', 'array'],
            'product_page.notes.top_title' => ['nullable', 'string', 'max:100'],
            'product_page.notes.middle_title' => ['nullable', 'string', 'max:100'],
            'product_page.notes.base_title' => ['nullable', 'string', 'max:100'],
            'product_page.notes.top_fallback_description' => ['nullable', 'string', 'max:1000'],
            'product_page.notes.middle_fallback_description' => ['nullable', 'string', 'max:1000'],
            'product_page.notes.base_fallback_description' => ['nullable', 'string', 'max:1000'],
            'product_page.notes.detail_fallback_suffix' => ['nullable', 'string', 'max:255'],
            'product_page.ingredients' => ['nullable', 'array'],
            'product_page.ingredients.section_kicker' => ['nullable', 'string', 'max:100'],
            'product_page.ingredients.title' => ['nullable', 'string', 'max:255'],
            'product_page.ingredients.description_template' => ['nullable', 'string', 'max:1000'],
            'product_page.ingredients.card_eyebrow' => ['nullable', 'string', 'max:100'],
            'product_page.ingredients.item_fallback_description' => ['nullable', 'string', 'max:255'],
            'product_page.education' => ['nullable', 'array'],
            'product_page.education.section_kicker' => ['nullable', 'string', 'max:100'],
            'product_page.education.default_title' => ['nullable', 'string', 'max:255'],
            'product_page.education.default_description' => ['nullable', 'string', 'max:1000'],
            'product_page.education.card_eyebrow' => ['nullable', 'string', 'max:100'],
            'product_page.education.default_tips' => ['nullable', 'array'],
            'product_page.education.default_tips.*' => ['nullable', 'string', 'max:255'],
            'product_page.faq' => ['nullable', 'array'],
            'product_page.faq.kicker' => ['nullable', 'string', 'max:100'],
            'product_page.faq.title' => ['nullable', 'string', 'max:255'],
            'product_page.faq.description' => ['nullable', 'string', 'max:1000'],
            'product_page.marketplace' => ['nullable', 'array'],
            'product_page.marketplace.title' => ['nullable', 'string', 'max:100'],
            'product_page.marketplace.tokopedia_label' => ['nullable', 'string', 'max:100'],
            'product_page.marketplace.tiktok_shop_label' => ['nullable', 'string', 'max:100'],
            'product_page.marketplace.empty_state' => ['nullable', 'string', 'max:255'],
            'product_page.sticky_cta' => ['nullable', 'array'],
            'product_page.sticky_cta.label' => ['nullable', 'string', 'max:100'],
            'product_page.system_messages' => ['nullable', 'array'],
            'product_page.system_messages.loading' => ['nullable', 'string', 'max:255'],
            'product_page.system_messages.error' => ['nullable', 'string', 'max:255'],
            'product_page.contact' => ['nullable', 'array'],
            'product_page.contact.whatsapp_message_template' => ['nullable', 'string', 'max:255'],
            'product_page.theme_presets' => ['nullable', 'array'],
            'product_page.theme_presets.signature' => ['nullable', 'array'],
            'product_page.theme_presets.signature.label' => ['nullable', 'string', 'max:100'],
            'product_page.theme_presets.signature.eyebrow' => ['nullable', 'string', 'max:100'],
            'product_page.theme_presets.signature.accent' => ['nullable', 'string', 'max:50'],
            'product_page.theme_presets.signature.accentSoft' => ['nullable', 'string', 'max:50'],
            'product_page.theme_presets.signature.accentDeep' => ['nullable', 'string', 'max:50'],
            'product_page.theme_presets.signature.background' => ['nullable', 'string', 'max:4000'],
            'product_page.theme_presets.signature.halo' => ['nullable', 'string', 'max:100'],
            'product_page.theme_presets.fresh' => ['nullable', 'array'],
            'product_page.theme_presets.fresh.label' => ['nullable', 'string', 'max:100'],
            'product_page.theme_presets.fresh.eyebrow' => ['nullable', 'string', 'max:100'],
            'product_page.theme_presets.fresh.accent' => ['nullable', 'string', 'max:50'],
            'product_page.theme_presets.fresh.accentSoft' => ['nullable', 'string', 'max:50'],
            'product_page.theme_presets.fresh.accentDeep' => ['nullable', 'string', 'max:50'],
            'product_page.theme_presets.fresh.background' => ['nullable', 'string', 'max:4000'],
            'product_page.theme_presets.fresh.halo' => ['nullable', 'string', 'max:100'],
            'product_page.theme_presets.floral' => ['nullable', 'array'],
            'product_page.theme_presets.floral.label' => ['nullable', 'string', 'max:100'],
            'product_page.theme_presets.floral.eyebrow' => ['nullable', 'string', 'max:100'],
            'product_page.theme_presets.floral.accent' => ['nullable', 'string', 'max:50'],
            'product_page.theme_presets.floral.accentSoft' => ['nullable', 'string', 'max:50'],
            'product_page.theme_presets.floral.accentDeep' => ['nullable', 'string', 'max:50'],
            'product_page.theme_presets.floral.background' => ['nullable', 'string', 'max:4000'],
            'product_page.theme_presets.floral.halo' => ['nullable', 'string', 'max:100'],
            'product_page.theme_presets.woody' => ['nullable', 'array'],
            'product_page.theme_presets.woody.label' => ['nullable', 'string', 'max:100'],
            'product_page.theme_presets.woody.eyebrow' => ['nullable', 'string', 'max:100'],
            'product_page.theme_presets.woody.accent' => ['nullable', 'string', 'max:50'],
            'product_page.theme_presets.woody.accentSoft' => ['nullable', 'string', 'max:50'],
            'product_page.theme_presets.woody.accentDeep' => ['nullable', 'string', 'max:50'],
            'product_page.theme_presets.woody.background' => ['nullable', 'string', 'max:4000'],
            'product_page.theme_presets.woody.halo' => ['nullable', 'string', 'max:100'],
            'product_page.seo_fallbacks' => ['nullable', 'array'],
            'product_page.seo_fallbacks.signature' => ['nullable', 'array'],
            'product_page.seo_fallbacks.signature.label' => ['nullable', 'string', 'max:100'],
            'product_page.seo_fallbacks.signature.title_template' => ['nullable', 'string', 'max:255'],
            'product_page.seo_fallbacks.signature.description_template' => ['nullable', 'string', 'max:1000'],
            'product_page.seo_fallbacks.signature.og_title_template' => ['nullable', 'string', 'max:255'],
            'product_page.seo_fallbacks.signature.og_description_template' => ['nullable', 'string', 'max:1000'],
            'product_page.seo_fallbacks.signature.og_image_url' => ['nullable', 'string', 'max:2048'],
            'product_page.seo_fallbacks.signature.robots' => ['nullable', 'string', 'max:100'],
            'product_page.seo_fallbacks.fresh' => ['nullable', 'array'],
            'product_page.seo_fallbacks.fresh.label' => ['nullable', 'string', 'max:100'],
            'product_page.seo_fallbacks.fresh.title_template' => ['nullable', 'string', 'max:255'],
            'product_page.seo_fallbacks.fresh.description_template' => ['nullable', 'string', 'max:1000'],
            'product_page.seo_fallbacks.fresh.og_title_template' => ['nullable', 'string', 'max:255'],
            'product_page.seo_fallbacks.fresh.og_description_template' => ['nullable', 'string', 'max:1000'],
            'product_page.seo_fallbacks.fresh.og_image_url' => ['nullable', 'string', 'max:2048'],
            'product_page.seo_fallbacks.fresh.robots' => ['nullable', 'string', 'max:100'],
            'product_page.seo_fallbacks.floral' => ['nullable', 'array'],
            'product_page.seo_fallbacks.floral.label' => ['nullable', 'string', 'max:100'],
            'product_page.seo_fallbacks.floral.title_template' => ['nullable', 'string', 'max:255'],
            'product_page.seo_fallbacks.floral.description_template' => ['nullable', 'string', 'max:1000'],
            'product_page.seo_fallbacks.floral.og_title_template' => ['nullable', 'string', 'max:255'],
            'product_page.seo_fallbacks.floral.og_description_template' => ['nullable', 'string', 'max:1000'],
            'product_page.seo_fallbacks.floral.og_image_url' => ['nullable', 'string', 'max:2048'],
            'product_page.seo_fallbacks.floral.robots' => ['nullable', 'string', 'max:100'],
            'product_page.seo_fallbacks.woody' => ['nullable', 'array'],
            'product_page.seo_fallbacks.woody.label' => ['nullable', 'string', 'max:100'],
            'product_page.seo_fallbacks.woody.title_template' => ['nullable', 'string', 'max:255'],
            'product_page.seo_fallbacks.woody.description_template' => ['nullable', 'string', 'max:1000'],
            'product_page.seo_fallbacks.woody.og_title_template' => ['nullable', 'string', 'max:255'],
            'product_page.seo_fallbacks.woody.og_description_template' => ['nullable', 'string', 'max:1000'],
            'product_page.seo_fallbacks.woody.og_image_url' => ['nullable', 'string', 'max:2048'],
            'product_page.seo_fallbacks.woody.robots' => ['nullable', 'string', 'max:100'],

            'tiktok_url' => ['nullable', 'string', 'max:2048'],
            'instagram_url' => ['nullable', 'string', 'max:2048'],
            'facebook_url' => ['nullable', 'string', 'max:2048'],
            'whatsapp_url' => ['nullable', 'string', 'max:2048'],
            'product_whatsapp_url' => ['nullable', 'string', 'max:2048'],
            'tokopedia_url' => ['nullable', 'string', 'max:2048'],
            'tiktok_shop_url' => ['nullable', 'string', 'max:2048'],
            'cards' => ['nullable', 'array'],
            'cards.tiktok' => ['nullable', 'array'],
            'cards.tiktok.eyebrow' => ['nullable', 'string', 'max:100'],
            'cards.tiktok.title' => ['nullable', 'string', 'max:255'],
            'cards.tiktok.description' => ['nullable', 'string', 'max:1000'],
            'cards.instagram' => ['nullable', 'array'],
            'cards.instagram.eyebrow' => ['nullable', 'string', 'max:100'],
            'cards.instagram.title' => ['nullable', 'string', 'max:255'],
            'cards.instagram.description' => ['nullable', 'string', 'max:1000'],
            'cards.whatsapp' => ['nullable', 'array'],
            'cards.whatsapp.eyebrow' => ['nullable', 'string', 'max:100'],
            'cards.whatsapp.title' => ['nullable', 'string', 'max:255'],
            'cards.whatsapp.description' => ['nullable', 'string', 'max:1000'],
            'hero_video_file' => ['nullable', 'file', 'mimetypes:video/mp4,video/webm,video/quicktime', 'max:65536'],
            'remove_hero_video' => ['nullable', 'boolean'],
        ]);

        GlobalSetting::ensureDefaults();
        $current = GlobalSetting::getValue('master_social_hub');
        $payload = array_replace_recursive(GlobalSetting::defaultMasterSocialHub(), $validated);
        $existingHeroVideoPath = (string) data_get($current, 'hero_video_path', '');
        $shouldRemoveHeroVideo = (bool) ($validated['remove_hero_video'] ?? false);

        unset($payload['hero_video_file'], $payload['remove_hero_video']);

        if ($shouldRemoveHeroVideo) {
            $payload['hero_video_path'] = '';
            $payload['hero_video_mime'] = '';
        } else {
            $payload['hero_video_path'] = $existingHeroVideoPath;
            $payload['hero_video_mime'] = (string) data_get($current, 'hero_video_mime', '');
        }

        try {
            if ($request->hasFile('hero_video_file')) {
                $optimizedVideo = $heroVideoOptimizer->optimizeAndStore($request->file('hero_video_file'));
                $payload['hero_video_path'] = $optimizedVideo['path'];
                $payload['hero_video_mime'] = $optimizedVideo['mime'];
            }
        } catch (RuntimeException $exception) {
            return back()->withErrors([
                'hero_video_file' => $exception->getMessage(),
            ]);
        } catch (Throwable $exception) {
            Log::error('Master hero upload failed.', [
                'message' => $exception->getMessage(),
                'trace' => $exception->getTraceAsString(),
            ]);

            return back()->withErrors([
                'hero_video_file' => 'Upload hero video gagal di server production. File asli tidak dapat diproses.',
            ]);
        }

        GlobalSetting::query()->updateOrCreate(
            ['key' => 'master_social_hub'],
            ['value' => $payload]
        );

        if (($shouldRemoveHeroVideo || $request->hasFile('hero_video_file')) && $existingHeroVideoPath !== '') {
            Storage::disk('public')->delete($existingHeroVideoPath);
        }

        return redirect()->route('global-settings.index')->with('success', 'Global settings berhasil diperbarui.');
    }

    public function showMasterHeroVideo(): StreamedResponse
    {
        $settings = GlobalSetting::getValue('master_social_hub');
        $path = (string) data_get($settings, 'hero_video_path', '');

        abort_if($path === '', 404);
        abort_unless(Storage::disk('public')->exists($path), 404);

        return Storage::disk('public')->response($path);
    }
}
