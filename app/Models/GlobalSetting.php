<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GlobalSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'key',
        'value',
    ];

    protected function casts(): array
    {
        return [
            'value' => 'array',
        ];
    }

    public static function ensureDefaults(): void
    {
        foreach (static::defaultRows() as $row) {
            static::query()->firstOrCreate(['key' => $row['key']], $row);
        }
    }

    public static function defaultRows(): array
    {
        return [[
            'key' => 'master_social_hub',
            'value' => static::defaultMasterSocialHub(),
        ]];
    }

    public static function getValue(string $key, array $fallback = []): array
    {
        static::ensureDefaults();

        $defaultValue = collect(static::defaultRows())
            ->firstWhere('key', $key)['value'] ?? [];

        $storedValue = static::query()->firstWhere('key', $key)?->value ?? [];

        return array_replace_recursive(
            is_array($defaultValue) ? $defaultValue : [],
            is_array($storedValue) ? $storedValue : [],
            $fallback
        );
    }

    public static function masterSocialHub(): array
    {
        return static::resolveMasterSocialHub(static::getValue('master_social_hub'));
    }

    public static function resolveMasterSocialHub(array $value): array
    {
        $merged = array_replace_recursive(static::defaultMasterSocialHub(), $value);
        $heroVideoPath = (string) ($merged['hero_video_path'] ?? '');
        $salesAppApkPath = (string) ($merged['sales_app_apk_path'] ?? '');

        $merged['hero_video_url'] = $heroVideoPath !== ''
            ? route('global-settings.master-hero-video', ['v' => md5($heroVideoPath)])
            : null;
        $merged['hero_video_name'] = $heroVideoPath !== '' ? basename($heroVideoPath) : null;
        $merged['sales_app_apk_url'] = $salesAppApkPath !== ''
            ? route('global-settings.sales-app-apk', ['v' => md5($salesAppApkPath)])
            : null;
        $merged['sales_app_apk_name'] = $salesAppApkPath !== ''
            ? ((string) ($merged['sales_app_apk_original_name'] ?? basename($salesAppApkPath)))
            : null;

        return $merged;
    }

    public static function defaultMasterSocialHub(): array
    {
        return [
            'master_page' => [
                'hero' => static::defaultMasterHero(),
                'navigation' => [
                    'items' => [
                        ['label' => 'Home', 'href' => '#top', 'side' => 'left'],
                        ['label' => 'Social Hub', 'href' => '#social-hub', 'side' => 'left'],
                        ['label' => 'The Collection', 'href' => '#collection', 'side' => 'left'],
                        ['label' => 'Discovery', 'href' => '#discovery', 'side' => 'right'],
                        ['label' => 'Contact', 'href' => '#main-footer', 'side' => 'right'],
                        ['label' => 'Carrers', 'href' => '/carrers', 'side' => 'right'],
                    ],
                ],
                'social_hub_section' => [
                    'eyebrow' => 'Social Hub',
                    'title' => 'Follow the brand atmosphere across channels',
                    'description' => 'Connect with the brand through short-form reviews, editorial visuals, and direct WhatsApp consultation.',
                ],
                'collection_section' => [
                    'eyebrow' => 'The Collection',
                    'title' => 'Explore the full collection',
                    'description' => 'Each discovery card opens a dedicated scent narrative.',
                    'card_active_status' => 'Discovery Ready',
                    'card_inactive_status' => 'Coming Soon',
                    'card_active_cta' => 'Explore the Scent',
                    'card_inactive_cta' => 'Awaiting Discovery',
                ],
                'manifesto' => [
                    'eyebrow' => 'Brand Manifesto',
                    'title' => 'Crafted in small batches for unique souls.',
                    'description' => 'Avenor builds perfume as atmosphere first. Every bottle is composed to feel intimate, memorable, and quietly bold from first spray to dry down.',
                ],
                'discovery' => [
                    'eyebrow' => 'Journal / Discovery',
                    'title' => 'Learn how each scent performs before you choose',
                    'description' => 'A quick preview from our fragrance education blocks before you move into a full product story.',
                    'preview_eyebrow' => 'Educational Preview',
                    'preview_cards' => [
                        [
                            'title' => 'Layering Rituals',
                            'description' => 'Learn where to spray, how to preserve performance, and how to choose the right scent profile for your mood.',
                        ],
                        [
                            'title' => 'Discovery Notes',
                            'description' => 'Understand the profile, texture, and character of each scent before entering a full product narrative.',
                        ],
                        [
                            'title' => 'Signature Match Guide',
                            'description' => 'Compare mood, projection, and wearing moment so each visitor can narrow down the right scent faster.',
                        ],
                    ],
                ],
                'footer' => [
                    'eyebrow' => 'Avenor Perfume',
                    'title' => 'A modern dark luxury fragrance house',
                    'description' => 'Curated scent stories, refined education, and direct discovery journeys for every variant.',
                    'instagram_label' => 'Instagram',
                    'tiktok_label' => 'TikTok',
                    'facebook_label' => 'Facebook',
                    'whatsapp_label' => 'WhatsApp',
                ],
                'system_messages' => [
                    'loading' => 'Curating the gateway...',
                    'error' => 'The master gateway could not be loaded right now.',
                ],
            ],
            'careers_page' => [
                'hero' => [
                    'eyebrow' => 'Carrers',
                    'title' => 'Build the next chapter of Avenor with us.',
                    'description' => 'We are looking for thoughtful builders, operators, and storytellers who care about craft, customer experience, and brand detail.',
                ],
                'section' => [
                    'kicker' => 'Open Roles',
                    'title' => 'Find a role that matches your strengths',
                    'description' => 'Each role card can open the same apply modal with a form that you control from the backend.',
                ],
                'cards' => [
                    [
                        'title' => 'Brand & Content Executive',
                        'description' => 'Own content planning, campaign execution, and day-to-day storytelling for fragrance launches.',
                        'button_label' => 'Apply',
                    ],
                    [
                        'title' => 'Retail Operations Lead',
                        'description' => 'Help us improve booth readiness, stock discipline, and customer experience on the ground.',
                        'button_label' => 'Apply',
                    ],
                ],
                'form' => [
                    'title' => 'Apply for {job_title}',
                    'description' => 'Complete the form below and upload supporting files if needed.',
                    'submit_label' => 'Send Application',
                    'success_message' => 'Lamaran berhasil dikirim.',
                ],
                'form_fields' => [
                    [
                        'key' => 'full_name',
                        'label' => 'Full Name',
                        'type' => 'text',
                        'required' => true,
                        'placeholder' => 'Your full name',
                    ],
                    [
                        'key' => 'email',
                        'label' => 'Email',
                        'type' => 'email',
                        'required' => true,
                        'placeholder' => 'name@example.com',
                    ],
                    [
                        'key' => 'phone',
                        'label' => 'Phone Number',
                        'type' => 'tel',
                        'required' => true,
                        'placeholder' => '08xxxxxxxxxx',
                    ],
                    [
                        'key' => 'cover_letter',
                        'label' => 'Why do you want to join Avenor?',
                        'type' => 'textarea',
                        'required' => true,
                        'placeholder' => 'Tell us briefly about yourself and why this role fits you.',
                    ],
                    [
                        'key' => 'cv_file',
                        'label' => 'CV / Resume',
                        'type' => 'file',
                        'required' => true,
                        'accept' => '.pdf,.doc,.docx',
                    ],
                ],
            ],
            'product_page' => [
                'default_theme_key' => 'signature',
                'default_seo_fallback_key' => 'signature',
                'navigation' => [
                    'home_label' => 'Home',
                    'collection_label' => 'Collection',
                    'discovery_label' => 'Discovery',
                    'contact_label' => 'Contact',
                ],
                'hero' => [
                    'eyebrow_default' => 'Dark Luxury',
                    'badge' => 'Variant Discovery',
                    'description_fallback' => 'Luxury fragrance crafted for a refined and memorable impression.',
                    'price_label' => 'Price',
                    'stock_label' => 'Stock',
                    'stock_ready_suffix' => 'ready',
                    'stock_preorder_label' => 'Pre-order',
                    'primary_cta_label' => 'Explore The Notes',
                    'primary_cta_href' => '#notes-journey',
                    'secondary_cta_label' => 'Customer Education',
                    'secondary_cta_href' => '#education-block',
                    'whatsapp_label' => 'Direct to WhatsApp',
                    'buy_options_label' => 'Buy Options',
                    'share_facebook_label' => 'Facebook',
                    'share_instagram_label' => 'Instagram',
                    'share_tiktok_label' => 'TikTok',
                    'share_text_prefix' => 'Take a look at',
                ],
                'story' => [
                    'kicker' => 'Narrative Scroll',
                    'title_template' => 'A scent journey shaped around {product_name}.',
                    'description' => 'Every layer reveals a different atmosphere, moving from the first impression to a lasting dry down that defines the character of this variant.',
                    'bottle_fallback_name' => 'Avenor',
                    'bottle' => [
                        'use_product_image_when_available' => true,
                        'floating_mobile' => true,
                        'tilt_desktop' => true,
                        'show_glow' => true,
                        'show_shadow' => true,
                        'show_liquid' => true,
                        'show_label' => true,
                        'brand_label' => 'AVENOR',
                        'cap_top' => '#f3e5b0',
                        'cap_middle' => '#d4af37',
                        'cap_bottom' => '#8d6a1f',
                        'liquid_from' => 'rgba(241,215,122,.12)',
                        'liquid_to' => 'rgba(212,175,55,.52)',
                        'label_background' => 'rgba(10,10,10,.34)',
                        'label_border' => 'rgba(212,175,55,.18)',
                    ],
                ],
                'notes' => [
                    'top_title' => 'Top Notes',
                    'middle_title' => 'Heart Notes',
                    'base_title' => 'Base Notes',
                    'top_fallback_description' => 'Bright opening notes create the first impression with clarity, lift, and immediate presence.',
                    'middle_fallback_description' => 'The heart brings the emotional signature of the fragrance and defines its core character.',
                    'base_fallback_description' => 'The base leaves a lingering trail with depth, warmth, and long-wearing identity.',
                    'detail_fallback_suffix' => 'shapes this layer of the scent journey.',
                ],
                'ingredients' => [
                    'section_kicker' => 'Ingredient Bento',
                    'title' => 'Ingredient Transparency',
                    'description_template' => 'Explore the fragrance structure behind {product_name} through a concise bento layout of notes and materials.',
                    'card_eyebrow' => 'Tap to Reveal',
                    'item_fallback_description' => 'Signature element in this fragrance composition.',
                ],
                'education' => [
                    'section_kicker' => 'Scent Education',
                    'default_title' => 'Customer Education',
                    'default_description' => 'Learn how to wear, store, and understand this fragrance more deeply.',
                    'card_eyebrow' => 'Education Block',
                    'default_tips' => [
                        'Apply on pulse points such as wrist and neck.',
                        'Moisturized skin helps the scent last longer.',
                        'Store the bottle away from direct sunlight and heat.',
                    ],
                ],
                'faq' => [
                    'kicker' => 'FAQ',
                    'title' => 'Questions before you commit to the scent',
                    'description' => 'Clear answers to reduce hesitation and help visitors move with confidence.',
                ],
                'marketplace' => [
                    'title' => 'Buy Options',
                    'tokopedia_label' => 'Tokopedia',
                    'tiktok_shop_label' => 'TikTok Shop',
                    'empty_state' => 'Marketplace links have not been configured from the administrator panel yet.',
                ],
                'sticky_cta' => [
                    'label' => 'Buy This Scent',
                ],
                'system_messages' => [
                    'loading' => 'Composing the experience...',
                    'error' => 'The product landing could not be loaded right now.',
                ],
                'contact' => [
                    'whatsapp_message_template' => 'Hi, I\'m interested in {product_name}. Can you tell me more?',
                ],
                'theme_presets' => [
                    'signature' => [
                        'label' => 'Signature',
                        'eyebrow' => 'Modern Dark Luxury',
                        'accent' => '#d4af37',
                        'accentSoft' => '#f1d77a',
                        'accentDeep' => '#8d6a1f',
                        'background' => 'radial-gradient(circle at 50% 0%, rgba(212, 175, 55, 0.18), transparent 36%), radial-gradient(circle at 0% 20%, rgba(255, 255, 255, 0.06), transparent 20%), radial-gradient(circle at 100% 30%, rgba(255, 255, 255, 0.06), transparent 24%), linear-gradient(180deg, #0a0a0a 0%, #050505 100%)',
                        'halo' => 'rgba(212, 175, 55, 0.32)',
                    ],
                    'fresh' => [
                        'label' => 'Fresh',
                        'eyebrow' => 'Fresh Dark Luxury',
                        'accent' => '#d4af37',
                        'accentSoft' => '#f0dd8e',
                        'accentDeep' => '#3f6772',
                        'background' => 'radial-gradient(circle at 18% 18%, rgba(212, 175, 55, 0.18), transparent 34%), radial-gradient(circle at 82% 16%, rgba(63, 103, 114, 0.20), transparent 24%), linear-gradient(180deg, #0a0a0a 0%, #071015 100%)',
                        'halo' => 'rgba(63, 103, 114, 0.32)',
                    ],
                    'floral' => [
                        'label' => 'Floral',
                        'eyebrow' => 'Floral Dark Luxury',
                        'accent' => '#d4af37',
                        'accentSoft' => '#f1d77a',
                        'accentDeep' => '#a97c50',
                        'background' => 'radial-gradient(circle at 20% 20%, rgba(212, 175, 55, 0.20), transparent 34%), radial-gradient(circle at 80% 10%, rgba(205, 133, 170, 0.16), transparent 28%), linear-gradient(180deg, #0a0a0a 0%, #120b10 100%)',
                        'halo' => 'rgba(205, 133, 170, 0.32)',
                    ],
                    'woody' => [
                        'label' => 'Woody',
                        'eyebrow' => 'Woody Dark Luxury',
                        'accent' => '#d4af37',
                        'accentSoft' => '#d2b071',
                        'accentDeep' => '#7a5930',
                        'background' => 'radial-gradient(circle at 18% 18%, rgba(212, 175, 55, 0.16), transparent 32%), radial-gradient(circle at 78% 20%, rgba(122, 89, 48, 0.20), transparent 26%), linear-gradient(180deg, #0a0a0a 0%, #090604 100%)',
                        'halo' => 'rgba(122, 89, 48, 0.34)',
                    ],
                ],
                'seo_fallbacks' => [
                    'signature' => [
                        'label' => 'Signature SEO',
                        'title_template' => '{product_name} | Avenor Perfume',
                        'description_template' => 'Discover {product_name} by Avenor Perfume.',
                        'og_title_template' => '{product_name} | Avenor Perfume',
                        'og_description_template' => 'Discover {product_name} by Avenor Perfume.',
                        'og_image_url' => '',
                        'robots' => 'index,follow',
                    ],
                    'fresh' => [
                        'label' => 'Fresh SEO',
                        'title_template' => '{product_name} | Fresh Signature by Avenor',
                        'description_template' => 'Explore {product_name}, a fresh and refined scent story by Avenor Perfume.',
                        'og_title_template' => '{product_name} | Fresh Signature by Avenor',
                        'og_description_template' => 'Explore {product_name}, a fresh and refined scent story by Avenor Perfume.',
                        'og_image_url' => '',
                        'robots' => 'index,follow',
                    ],
                    'floral' => [
                        'label' => 'Floral SEO',
                        'title_template' => '{product_name} | Floral Luxury by Avenor',
                        'description_template' => 'Discover {product_name}, a floral luxury fragrance crafted by Avenor Perfume.',
                        'og_title_template' => '{product_name} | Floral Luxury by Avenor',
                        'og_description_template' => 'Discover {product_name}, a floral luxury fragrance crafted by Avenor Perfume.',
                        'og_image_url' => '',
                        'robots' => 'index,follow',
                    ],
                    'woody' => [
                        'label' => 'Woody SEO',
                        'title_template' => '{product_name} | Woody Elegance by Avenor',
                        'description_template' => 'Meet {product_name}, a woody and elegant fragrance journey by Avenor Perfume.',
                        'og_title_template' => '{product_name} | Woody Elegance by Avenor',
                        'og_description_template' => 'Meet {product_name}, a woody and elegant fragrance journey by Avenor Perfume.',
                        'og_image_url' => '',
                        'robots' => 'index,follow',
                    ],
                ],
            ],
            'tiktok_url' => '',
            'instagram_url' => '',
            'facebook_url' => '',
            'whatsapp_url' => '',
            'product_whatsapp_url' => '',
            'tokopedia_url' => '',
            'tiktok_shop_url' => '',
            'hero_video_path' => '',
            'hero_video_mime' => '',
            'sales_app_apk_path' => '',
            'sales_app_apk_mime' => '',
            'sales_app_apk_original_name' => '',
            'cards' => [
                'tiktok' => [
                    'eyebrow' => 'TikTok',
                    'title' => 'Review Highlights',
                    'description' => 'Short-form fragrance impressions, reactions, and launch moments.',
                ],
                'instagram' => [
                    'eyebrow' => 'Instagram',
                    'title' => 'Aesthetic Grid',
                    'description' => 'Editorial visuals, rituals, and product stories in a curated gallery.',
                ],
                'whatsapp' => [
                    'eyebrow' => 'WhatsApp',
                    'title' => 'Consult with Our Scent Expert',
                    'description' => 'Start a direct conversation and get guided toward the right scent.',
                ],
            ],
        ];
    }

    public static function defaultMasterHero(): array
    {
        return [
            'eyebrow' => 'Avenor Perfume',
            'title' => 'The Scent of Discovery',
            'description' => 'awakens curiosity, guiding you to explore deeper and leave a refined, memorable impression.',
        ];
    }
}
