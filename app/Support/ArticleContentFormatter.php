<?php

namespace App\Support;

use Illuminate\Support\Str;

class ArticleContentFormatter
{
    public static function toHtml(?string $content): string
    {
        $content = trim((string) $content);

        if ($content === '') {
            return '';
        }

        if (Str::contains($content, ['<p', '<h1', '<h2', '<h3', '<ul', '<ol', '<li', '<br', '<strong', '<em', '<a '])) {
            return $content;
        }

        $paragraphs = preg_split("/\r?\n\r?\n+/", $content) ?: [];

        return collect($paragraphs)
            ->map(fn (string $paragraph) => '<p>' . nl2br(e(trim($paragraph))) . '</p>')
            ->filter(fn (string $paragraph) => $paragraph !== '<p></p>')
            ->implode("\n");
    }
}
