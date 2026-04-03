<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    @php
        $seoTitle = data_get($seo, 'title') ?: data_get($initialContent, 'product.name', '');
        $seoDescription = data_get($seo, 'description', '');
        $seoKeywords = data_get($seo, 'meta_keywords', 'avenor perfume, parfum premium, parfum mewah, luxury fragrance, parfum indonesia');
        $canonicalUrl = data_get($seo, 'canonical_url', url()->current());
        $ogTitle = data_get($seo, 'og_title', $seoTitle);
        $ogDescription = data_get($seo, 'og_description', $seoDescription);
        $ogImage = data_get($seo, 'og_image', '');
        $ogImageAlt = data_get($seo, 'og_image_alt', $seoTitle);
        $robots = data_get($seo, 'robots', '');
        $seoAuthor = data_get($seo, 'author', 'Avenor Perfume');
        $twitterSite = data_get($seo, 'twitter_site', '');
        $twitterCreator = data_get($seo, 'twitter_creator', $twitterSite);
        $articlePublishedTime = data_get($seo, 'article.published_time');
        $articleModifiedTime = data_get($seo, 'article.modified_time');
        $articleAuthor = data_get($seo, 'article.author');
        $articleSection = data_get($seo, 'article.section');
        $productBrand = data_get($seo, 'product.brand');
        $productAvailability = data_get($seo, 'product.availability');
        $productPriceAmount = data_get($seo, 'product.price.amount');
        $productPriceCurrency = data_get($seo, 'product.price.currency', 'IDR');
        $pageKind = $pageType ?? data_get($initialContent, 'page_type', 'product');
        $ogType = $pageKind === 'product' ? 'product' : ($pageKind === 'article' ? 'article' : 'website');
        $schemaList = $schemas ?? data_get($initialContent, 'schemas', []);
        $facebookPixelId = data_get($tracking, 'facebook_pixel_id');
    @endphp
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ $seoTitle }}</title>
    <link rel="icon" type="image/png" href="{{ asset('img/logo.png') }}">
    <link rel="apple-touch-icon" href="{{ asset('img/logo.png') }}">
    <meta name="description" content="{{ $seoDescription }}">
    <meta name="keywords" content="{{ $seoKeywords }}">
    <meta name="author" content="{{ $seoAuthor }}">
    <meta name="robots" content="{{ $robots }}">
    <meta name="googlebot" content="{{ $robots }}">
    <meta name="theme-color" content="#0f0b08">
    <link rel="canonical" href="{{ $canonicalUrl }}">
    <link rel="alternate" hreflang="id-ID" href="{{ $canonicalUrl }}">
    <meta property="og:type" content="{{ $ogType }}">
    <meta property="og:site_name" content="Avenor Perfume">
    <meta property="og:locale" content="id_ID">
    <meta property="og:title" content="{{ $ogTitle }}">
    <meta property="og:description" content="{{ $ogDescription }}">
    <meta property="og:url" content="{{ $canonicalUrl }}">
    <meta property="og:image" content="{{ $ogImage }}">
    <meta property="og:image:alt" content="{{ $ogImageAlt }}">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="{{ $ogTitle }}">
    <meta name="twitter:description" content="{{ $ogDescription }}">
    <meta name="twitter:image" content="{{ $ogImage }}">
    <meta name="twitter:image:alt" content="{{ $ogImageAlt }}">
    @if ($twitterSite)
        <meta name="twitter:site" content="{{ $twitterSite }}">
    @endif
    @if ($twitterCreator)
        <meta name="twitter:creator" content="{{ $twitterCreator }}">
    @endif
    @if ($pageKind === 'article')
        @if ($articlePublishedTime)
            <meta property="article:published_time" content="{{ $articlePublishedTime }}">
        @endif
        @if ($articleModifiedTime)
            <meta property="article:modified_time" content="{{ $articleModifiedTime }}">
        @endif
        @if ($articleAuthor)
            <meta property="article:author" content="{{ $articleAuthor }}">
        @endif
        @if ($articleSection)
            <meta property="article:section" content="{{ $articleSection }}">
        @endif
    @endif
    @if ($pageKind === 'product')
        @if ($productBrand)
            <meta property="product:brand" content="{{ $productBrand }}">
        @endif
        @if ($productAvailability)
            <meta property="product:availability" content="{{ $productAvailability }}">
        @endif
        @if ($productPriceAmount)
            <meta property="product:price:amount" content="{{ $productPriceAmount }}">
            <meta property="product:price:currency" content="{{ $productPriceCurrency }}">
        @endif
    @endif
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Playfair+Display:wght@600;700;800&display=swap" rel="stylesheet">
    @vite(['resources/js/landing.js'])
    @include('partials.google-tag')
    @foreach ($schemaList as $schema)
        <script type="application/ld+json">{!! json_encode($schema, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) !!}</script>
    @endforeach
    @if ($facebookPixelId)
        <script>
            !function(f,b,e,v,n,t,s)
            {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
            n.callMethod.apply(n,arguments):n.queue.push(arguments)};
            if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
            n.queue=[];t=b.createElement(e);t.async=!0;
            t.src=v;s=b.getElementsByTagName(e)[0];
            s.parentNode.insertBefore(t,s)}(window, document,'script',
            'https://connect.facebook.net/en_US/fbevents.js');
            fbq('init', @json($facebookPixelId));
            fbq('track', 'PageView');
        </script>
        <noscript>
            <img height="1" width="1" style="display:none" src="https://www.facebook.com/tr?id={{ $facebookPixelId }}&ev=PageView&noscript=1" alt="">
        </noscript>
    @endif
</head>
<body>
    <div id="landing-app"></div>
    <script>
        window.AVENOR_PAGE_TYPE = @json($pageType ?? data_get($initialContent, 'page_type', ''));
        window.AVENOR_LANDING_FALLBACK_STATE = @json($fallbackContent ?? $initialContent);
        window.AVENOR_LANDING_INITIAL_STATE = @json($initialContent);
        window.AVENOR_PRODUCT_SLUG = @json(data_get($initialContent, 'product.slug'));
    </script>
    <script src="https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/gsap.min.js" defer></script>
    <script src="https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/ScrollTrigger.min.js" defer></script>
</body>
</html>
