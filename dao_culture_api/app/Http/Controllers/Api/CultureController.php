<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class CultureController extends Controller
{
    public function articles(Request $request)
    {
        $query = DB::table('culture_articles');

        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        if ($request->mode === 'featured') {
            $featuredExists = DB::table('culture_articles')
                ->where('is_featured', 1)
                ->exists();
            if ($featuredExists) {
                $query->where('is_featured', 1);
            }
        }

        $query->orderByDesc(
            $request->mode === 'latest' ? 'created_at' : 'view_count'
        );

        if ($request->integer('limit') > 0) {
            $query->limit($request->integer('limit'));
        }

        return response()->json($query->get());
    }

    public function incrementView(Request $request)
    {
        DB::table('culture_articles')
            ->where('id', $request->id)
            ->increment('view_count');

        return response()->json(['status' => 'success']);
    }

    public function mapPlaces(Request $request)
    {
        $query = DB::table('map_places')->orderBy('id');

        if (!$request->boolean('admin')) {
            $query->where('is_active', 1);
        }

        return response()->json([
            'status' => 'success',
            'data' => $query->get(),
        ]);
    }

    public function image(Request $request)
    {
        $fileName = basename((string) $request->query('file'));

        if ($fileName === '') {
            return response()->json([
                'status' => 'error',
                'message' => 'Thiếu tên ảnh',
            ], 400);
        }

        $path = "uploads/culture/{$fileName}";

        if (!Storage::disk('public')->exists($path)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Không tìm thấy ảnh',
            ], 404);
        }

        $fullPath = storage_path('app/public/' . $path);

        if (!file_exists($fullPath)) {
            return response()->json([
                'message' => 'Không tìm thấy file'
            ], 404);
        }

        return response()->file($fullPath, [
            'Access-Control-Allow-Origin' => '*',
            'Cross-Origin-Resource-Policy' => 'cross-origin',
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }

    public function video(Request $request)
    {
        $fileName = basename((string) $request->query('file'));

        if ($fileName === '') {
            return response()->json([
                'status' => 'error',
                'message' => 'Thiếu tên video',
            ], 400);
        }

        $path = "uploads/culture_videos/{$fileName}";
        if (!Storage::disk('public')->exists($path)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Không tìm thấy video',
            ], 404);
        }

        return response()->file(
            storage_path("app/public/{$path}"),
            [
                'Access-Control-Allow-Origin' => '*',
                'Cross-Origin-Resource-Policy' => 'cross-origin',
                'Accept-Ranges' => 'bytes',
                'Cache-Control' => 'public, max-age=86400',
            ]
        );
    }

    public function share(Request $request)
    {
        $title = trim((string) $request->query('title', ''));
        $article = DB::table('culture_articles')
            ->where('title', $title)
            ->first();

        if (!$article) {
            return response(
                '<!doctype html><html lang="vi"><meta charset="utf-8">' .
                '<title>Không tìm thấy bài viết</title>' .
                '<body><h1>Không tìm thấy bài viết</h1></body></html>',
                404
            )->header('Content-Type', 'text/html; charset=UTF-8');
        }

        $imageFile = $this->cultureMediaFileName(
            (string) ($article->image_url ?? '')
        );
        $imageUrl = $imageFile === ''
            ? ''
            : $request->getSchemeAndHttpHost() .
                '/api/culture_articles/image.php?file=' .
                rawurlencode($imageFile);
        $pageUrl = $request->fullUrl();
        $pageTitle = e((string) $article->title);
        $subtitle = trim((string) ($article->subtitle ?? ''));
        $description = e(Str::limit(
            strip_tags($subtitle !== ''
                ? $subtitle
                : (string) ($article->content ?? '')),
            180
        ));
        $content = nl2br(e((string) ($article->content ?? '')));
        $safeImageUrl = e($imageUrl);
        $safePageUrl = e($pageUrl);

        $html = <<<HTML
<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{$pageTitle}</title>
  <meta name="description" content="{$description}">
  <meta property="og:type" content="article">
  <meta property="og:title" content="{$pageTitle}">
  <meta property="og:description" content="{$description}">
  <meta property="og:url" content="{$safePageUrl}">
  <meta property="og:image" content="{$safeImageUrl}">
  <meta name="twitter:card" content="summary_large_image">
  <style>
    body { margin: 0; background: #f7f2eb; color: #1d2421; font: 17px/1.65 Arial, sans-serif; }
    article { max-width: 760px; margin: 32px auto; background: white; border-radius: 18px; overflow: hidden; box-shadow: 0 8px 30px #00000016; }
    img { width: 100%; max-height: 480px; object-fit: cover; display: block; }
    .content { padding: 28px; }
    h1 { margin: 0 0 10px; line-height: 1.25; color: #9e271f; }
    .subtitle { color: #59625e; font-weight: 600; }
  </style>
</head>
<body>
  <article>
    <img src="{$safeImageUrl}" alt="{$pageTitle}">
    <div class="content">
      <h1>{$pageTitle}</h1>
      <p class="subtitle">{$description}</p>
      <div>{$content}</div>
    </div>
  </article>
</body>
</html>
HTML;

        return response($html)
            ->header('Content-Type', 'text/html; charset=UTF-8');
    }

    public function saveArticle(Request $request)
    {
        $request->validate([
            'category' => 'required|string|max:50',
            'title' => 'required|string|max:255',
            'content' => 'required|string',
        ]);

        $values = [
            'category' => (string) $request->input('category'),
            'title' => (string) $request->input('title'),
            'subtitle' => (string) ($request->input('subtitle') ?? ''),
            'content' => (string) $request->input('content'),
            'image_url' => (string) ($request->input('image_url') ?? ''),
            'video_url' => (string) ($request->input('video_url') ?? ''),
            'detail_json' => (string) (
                $request->input('detail_json') ?? '{}'
            ),
            'is_featured' => $request->boolean('is_featured') ? 1 : 0,
            'updated_at' => now(),
        ];

        $id = $request->integer('id');

        if ($id > 0) {
            DB::table('culture_articles')->where('id', $id)->update($values);
        } else {
            $values['created_at'] = now();
            $values['view_count'] = 0;
            $id = DB::table('culture_articles')->insertGetId($values);
        }

        return response()->json([
            'status' => 'success',
            'id' => $id,
        ]);
    }

    public function uploadArticleImage(Request $request)
    {
        $request->validate([
            'image' => 'required|image|max:10240',
        ]);

        $path = $request->file('image')
            ->store('uploads/culture', 'public');

        $imageUrl = url("storage/$path");

        return response()->json([
            'status' => 'success',
            'image_url' => $imageUrl,
        ]);
    }

    public function uploadArticleVideo(Request $request)
    {
        $request->validate([
            'video' => 'required|file|mimes:mp4,mov,webm,m4v|max:102400',
        ]);

        $path = $request->file('video')
            ->store('uploads/culture_videos', 'public');

        $videoUrl = url("storage/$path");

        return response()->json([
            'status' => 'success',
            'video_url' => $videoUrl,
        ]);
    }

    public function deleteArticle(Request $request)
    {
        $deleted = DB::table('culture_articles')
            ->where('id', $request->integer('id'))
            ->delete();

        return response()->json([
            'status' => $deleted ? 'success' : 'error',
        ]);
    }

    public function saveMapPlace(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'latitude' => 'required|numeric|between:8,24',
            'longitude' => 'required|numeric|between:102,110',
        ]);

        $gallery = $request->input('gallery_urls', []);

        if (!is_array($gallery)) {
            $decoded = json_decode((string) $gallery, true);
            $gallery = is_array($decoded) ? $decoded : [];
        }

        $values = [
            'name' => $request->input('name'),
            'address' => (string) ($request->input('address') ?? ''),
            'short_description' => (string) (
                $request->input('short_description') ?? ''
            ),
            'cultural_description' => (string) (
                $request->input('cultural_description') ?? ''
            ),
            'dao_info' => (string) ($request->input('dao_info') ?? ''),
            'tag' => (string) ($request->input('tag') ?? ''),
            'type' => (string) ($request->input('type') ?? 'village'),
            'layer_type' => (string) (
                $request->input('layer_type') ?? 'culture'
            ),
            'image_url' => (string) ($request->input('image_url') ?? ''),
            'gallery_urls' => json_encode(
                $gallery,
                JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
            ),
            'latitude' => $request->input('latitude'),
            'longitude' => $request->input('longitude'),
            'has_directions' => $request->boolean('has_directions') ? 1 : 0,
            'is_active' => $request->boolean('is_active') ? 1 : 0,
            'updated_at' => now(),
        ];

        $id = $request->integer('id');

        if ($id > 0) {
            DB::table('map_places')->where('id', $id)->update($values);
        } else {
            $values['created_at'] = now();
            $id = DB::table('map_places')->insertGetId($values);
        }

        return response()->json([
            'status' => 'success',
            'id' => $id,
        ]);
    }

    public function uploadMapImage(Request $request)
    {
        $request->validate([
            'image' => 'required|image|max:10240',
        ]);

        $path = $request->file('image')
            ->store('uploads/map_places', 'public');

        $imageUrl = url("storage/$path");

        return response()->json([
            'status' => 'success',
            'image_url' => $imageUrl,
        ]);
    }

    public function deleteMapPlace(Request $request)
    {
        $deleted = DB::table('map_places')
            ->where('id', $request->integer('id'))
            ->delete();

        return response()->json([
            'status' => $deleted ? 'success' : 'error',
        ]);
    }

    public function search(Request $request)
    {
        $keyword = trim((string) $request->query('keyword', ''));
        $category = trim((string) $request->query('category', ''));
        $limit = min(max($request->integer('limit', 8), 1), 30);

        if (mb_strlen($keyword) < 2) {
            return response()->json([
                'status' => 'success',
                'data' => [],
            ]);
        }

        $normalizedKeyword = $this->normalizeSearchText($keyword);
        $stopWords = [
            'la', 'gi', 'co', 'cua', 'nguoi', 'dao', 've',
            'nhu', 'the', 'nao', 'cho', 'biet', 'bai', 'viet',
            'tim', 'kiem', 'noi', 'dung',
        ];
        $keywordTokens = array_values(array_unique(array_filter(
            explode(' ', $normalizedKeyword),
            fn (string $token) => mb_strlen($token) >= 2 &&
                !in_array($token, $stopWords, true)
        )));
        $focusPhrase = implode(' ', $keywordTokens);
        $concepts = $this->searchConcepts($normalizedKeyword);

        $query = DB::table('culture_articles');
        if ($category !== '') {
            $query->where('category', $category);
        }

        $articles = $query
            ->orderByDesc('view_count')
            ->orderByDesc('created_at')
            ->limit(200)
            ->get()
            ->map(function ($article) use (
                $normalizedKeyword,
                $keywordTokens,
                $focusPhrase,
                $concepts
            ) {
                $title = $this->normalizeSearchText(
                    (string) ($article->title ?? '')
                );
                $subtitle = $this->normalizeSearchText(
                    (string) ($article->subtitle ?? '')
                );
                $content = $this->normalizeSearchText(
                    (string) ($article->content ?? '')
                );
                $searchable = trim("{$title} {$subtitle} {$content}");
                $score = 0;

                if ($title === $normalizedKeyword) {
                    $score += 300;
                } elseif ($normalizedKeyword !== '' &&
                    str_contains($title, $normalizedKeyword)) {
                    $score += 220;
                }

                if ($focusPhrase !== '' && str_contains($title, $focusPhrase)) {
                    $score += 180;
                } elseif ($focusPhrase !== '' &&
                    str_contains($subtitle, $focusPhrase)) {
                    $score += 100;
                } elseif ($focusPhrase !== '' &&
                    str_contains($content, $focusPhrase)) {
                    $score += 55;
                }

                foreach ($keywordTokens as $token) {
                    if ($this->containsSearchTerm($title, $token)) {
                        $score += 35;
                    } elseif ($this->containsSearchTerm($subtitle, $token)) {
                        $score += 18;
                    } elseif ($this->containsSearchTerm(
                        $content,
                        $token
                    )) {
                        $score += 6;
                    }
                }

                foreach ($concepts as $concept => $variants) {
                    $matchedTitle = false;
                    $matchedBody = false;

                    foreach ($variants as $variant) {
                        if ($this->containsSearchTerm($title, $variant)) {
                            $matchedTitle = true;
                        } elseif ($this->containsSearchTerm(
                            "{$subtitle} {$content}",
                            $variant
                        )) {
                            $matchedBody = true;
                        }
                    }

                    if ($matchedTitle) {
                        $score += 90;
                    } elseif ($matchedBody) {
                        $score += 35;
                    }
                }

                if (!$this->matchesRequiredIntent($concepts, $searchable)) {
                    $score = 0;
                }

                if (isset($concepts['cap sac'])) {
                    if (str_contains($title, 'dai le cap sac') ||
                        str_starts_with($title, 'le cap sac')) {
                        $score += 160;
                    } elseif (str_contains($title, 'cap sac')) {
                        $score += 90;
                    }
                }

                $matchedTokens = count(array_filter(
                    $keywordTokens,
                    fn (string $token) =>
                        $this->containsSearchTerm($searchable, $token)
                ));
                $minimumMatches = count($keywordTokens) <= 2
                    ? 1
                    : (int) ceil(count($keywordTokens) * 0.6);
                if ($concepts === [] &&
                    $matchedTokens < $minimumMatches &&
                    !str_contains($searchable, $focusPhrase)) {
                    $score = 0;
                }

                $article->_search_score = $score;
                return $article;
            })
            ->filter(fn ($article) => $article->_search_score > 0)
            ->sortByDesc('_search_score')
            ->take($limit)
            ->values()
            ->map(function ($article) {
                unset($article->_search_score);
                return $article;
            });

        return response()->json([
            'status' => 'success',
            'data' => $articles,
        ]);
    }

    private function normalizeSearchText(string $value): string
    {
        return trim((string) preg_replace(
            '/\s+/',
            ' ',
            preg_replace(
                '/[^a-z0-9\s]/',
                ' ',
                strtolower(Str::ascii($value))
            )
        ));
    }

    private function cultureMediaFileName(string $value): string
    {
        if ($value === '') return '';

        $query = parse_url($value, PHP_URL_QUERY);
        if (is_string($query) && $query !== '') {
            parse_str($query, $parameters);
            if (!empty($parameters['file'])) {
                return basename((string) $parameters['file']);
            }
        }

        $path = parse_url($value, PHP_URL_PATH);
        return basename(is_string($path) ? $path : $value);
    }

    private function containsSearchTerm(string $text, string $term): bool
    {
        return preg_match(
            '/(?:^|\s)'.preg_quote($term, '/').'(?=\s|$)/',
            $text
        ) === 1;
    }

    private function searchConcepts(string $query): array
    {
        $dictionary = [
            'nu' => ['nu', 'phu nu', 'co dau', 'nguoi vo', 'phai dep'],
            'nam' => ['nam', 'nam gioi', 'dan ong', 'nguoi chong', 'chu re'],
            'tre em' => ['tre em', 'tre nho', 'em be', 'con tre'],
            'cap sac' => [
                'cap sac', 'truong thanh', 'phap danh',
                'len den', 'den cap sac',
            ],
            'cuoi' => [
                'cuoi', 'hon nhan', 'co dau', 'chu re',
                'ruoc dau', 'don dau', 'phu the',
            ],
            'tang le' => [
                'tang le', 'ma chay', 'ta mo', 'tao mo',
                'nguoi da khuat', 'trung tang',
            ],
            'thuoc' => [
                'thuoc', 'thuoc nam', 'thao duoc',
                'duoc lieu', 'cay thuoc',
            ],
            'thuoc tam' => [
                'thuoc tam', 'tam thuoc', 'nuoc tam',
            ],
            'rung' => [
                'rung', 'than rung', 'cung rung',
                'bao ve rung', 'cay rung',
            ],
            'trang suc' => [
                'trang suc', 'bac', 'kieng', 'xa tich', 'phu kien',
            ],
        ];

        $concepts = [];
        foreach ($dictionary as $concept => $variants) {
            foreach ($variants as $variant) {
                if ($this->containsSearchTerm($query, $variant)) {
                    $concepts[$concept] = $variants;
                    break;
                }
            }
        }

        return $concepts;
    }

    private function matchesRequiredIntent(
        array $concepts,
        string $searchable
    ): bool {
        foreach ($concepts as $concept => $variants) {
            if (in_array($concept, ['nu', 'nam'], true)) continue;

            $matched = collect($variants)->contains(
                fn (string $term) =>
                    $this->containsSearchTerm($searchable, $term)
            );
            if (!$matched) return false;
        }

        if (isset($concepts['nu'])) {
            $female = collect($concepts['nu'])->contains(
                fn (string $term) =>
                    $this->containsSearchTerm($searchable, $term)
            );
            $maleOnly = collect([
                'nam gioi', 'dan ong', 'nguoi chong', 'chu re',
            ])->contains(
                fn (string $term) =>
                    $this->containsSearchTerm($searchable, $term)
            );
            if (!$female || $maleOnly) return false;
        }

        if (isset($concepts['nam'])) {
            $male = collect($concepts['nam'])->contains(
                fn (string $term) =>
                    $this->containsSearchTerm($searchable, $term)
            );
            $femaleOnly = collect([
                'phu nu', 'co dau', 'nguoi vo', 'phai dep',
            ])->contains(
                fn (string $term) =>
                    $this->containsSearchTerm($searchable, $term)
            );
            if (!$male || $femaleOnly) return false;
        }

        return true;
    }
}
