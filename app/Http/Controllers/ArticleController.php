<?php

namespace App\Http\Controllers;

use App\Models\Article;
use App\Support\ArticleContentFormatter;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Inertia\Inertia;
use Inertia\Response;

class ArticleController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorizeManagement($request);

        $articles = Article::query()
            ->orderByDesc('published_at')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (Article $article) => [
                'id' => $article->id,
                'title' => $article->title,
                'slug' => $article->slug,
                'author' => $article->author,
                'category' => $article->category,
                'published_at' => optional($article->published_at)->format('Y-m-d'),
                'excerpt' => $article->excerpt,
                'body' => $article->body,
                'body_html' => ArticleContentFormatter::toHtml($article->body),
                'image_url' => $article->public_image_url,
                'seo_title' => $article->seo_title,
                'seo_description' => $article->seo_description,
                'seo_keywords' => $article->seo_keywords,
                'seo_canonical_url' => $article->seo_canonical_url,
                'seo_robots' => $article->seo_robots,
                'og_title' => $article->og_title,
                'og_description' => $article->og_description,
                'og_image_url' => $article->og_image_url,
                'og_image_alt' => $article->og_image_alt,
                'is_published' => (bool) $article->is_published,
                'public_url' => url('/article/' . $article->slug),
                'created_at' => optional($article->created_at)->format('Y-m-d H:i:s'),
            ])
            ->values();

        return Inertia::render('Articles/Index', [
            'articles' => $articles,
            'categories' => Article::DEFAULT_CATEGORIES,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->authorizeManagement($request);

        $validated = $this->validatePayload($request);
        $imagePath = $request->file('image')?->store('articles', 'public');

        Article::query()->create([
            ...$validated,
            'image_path' => $imagePath,
        ]);

        return redirect()->route('articles.manage')->with('success', 'Article berhasil ditambahkan.');
    }

    public function update(Request $request, Article $article): RedirectResponse
    {
        $this->authorizeManagement($request);

        $validated = $this->validatePayload($request, $article);
        $oldImagePath = $article->normalized_image_path;
        $newImagePath = null;

        if ($request->hasFile('image')) {
            $newImagePath = $request->file('image')->store('articles', 'public');
        }

        $article->update([
            ...$validated,
            'image_path' => $newImagePath ?: ((bool) ($validated['remove_image'] ?? false) ? null : $article->image_path),
        ]);

        if (($newImagePath || (bool) ($validated['remove_image'] ?? false)) && $oldImagePath && Storage::disk('public')->exists($oldImagePath)) {
            Storage::disk('public')->delete($oldImagePath);
        }

        return redirect()->route('articles.manage')->with('success', 'Article berhasil diperbarui.');
    }

    public function destroy(Request $request, Article $article): RedirectResponse
    {
        $this->authorizeManagement($request);

        $imagePath = $article->normalized_image_path;

        $article->delete();

        if ($imagePath && Storage::disk('public')->exists($imagePath)) {
            Storage::disk('public')->delete($imagePath);
        }

        return redirect()->route('articles.manage')->with('success', 'Article berhasil dihapus.');
    }

    public function showPublicImage(Article $article)
    {
        abort_if(! $article->normalized_image_path, 404);

        if (! Storage::disk('public')->exists($article->normalized_image_path)) {
            return response()->file(public_path('img/logo.png'));
        }

        return Storage::disk('public')->response($article->normalized_image_path);
    }

    private function authorizeManagement(Request $request): void
    {
        abort_unless($request->user()?->role === 'superadmin', 403);
    }

    private function validatePayload(Request $request, ?Article $article = null): array
    {
        return $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'slug' => ['nullable', 'string', 'max:255'],
            'author' => ['required', 'string', 'max:255'],
            'category' => ['nullable', 'string', 'max:100'],
            'published_at' => ['required', 'date'],
            'excerpt' => ['required', 'string', 'max:500'],
            'body' => ['required', 'string'],
            'seo_title' => ['nullable', 'string', 'max:255'],
            'seo_description' => ['nullable', 'string', 'max:500'],
            'seo_keywords' => ['nullable', 'string', 'max:1000'],
            'seo_canonical_url' => ['nullable', 'string', 'max:2048'],
            'seo_robots' => ['nullable', 'string', 'max:255'],
            'og_title' => ['nullable', 'string', 'max:255'],
            'og_description' => ['nullable', 'string', 'max:500'],
            'og_image_url' => ['nullable', 'string', 'max:2048'],
            'og_image_alt' => ['nullable', 'string', 'max:255'],
            'is_published' => ['nullable', 'boolean'],
            'remove_image' => ['nullable', 'boolean'],
            'image' => [$article ? 'nullable' : 'required', 'image', 'max:4096'],
        ]);
    }
}
