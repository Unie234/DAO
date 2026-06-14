<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use RuntimeException;

class AiController extends Controller
{
    public function assistant(Request $request)
    {
        $validated = $request->validate([
            'message' => 'required|string|max:2000',
            'context' => 'nullable|string|max:6000',
        ]);

        $question = trim($validated['message']);
        $context = trim((string) ($validated['context'] ?? ''));
        $normalized = $this->normalizeQuestion($question);
        $searchText = $this->isFollowUpQuestion($normalized) && $context !== ''
            ? $this->normalizeQuestion("{$context} {$question}")
            : $normalized;

        $candidates = $this->rankCultureArticles($searchText);

        try {
            // Bước xác minh nguồn được gộp vào prompt sinh câu trả lời để mỗi
            // câu hỏi có nguồn nội bộ chỉ cần một lượt gọi Gemini.
            $verified = array_slice(
                array_values(array_filter(
                    $candidates,
                    fn ($article) => $this->matchesPrimaryIntent(
                        $searchText,
                        $article
                    )
                )),
                0,
                3
            );

            if ($verified !== []) {
                try {
                $answer = $this->answerFromInternalSources(
                    $question,
                    $context,
                    $verified
                );

                if ($answer !== null) {
                    return response()->json([
                        'status' => 'success',
                        'text' => $answer,
                        'source_type' => 'internal',
                        'normalized_question' => $normalized,
                        'related_articles' => array_map(
                            fn ($article) => $this->articlePayload($article),
                            $verified
                        ),
                    ]);
                }
                } catch (\Throwable $exception) {
                    if (!$this->isTemporaryGeminiError($exception)) {
                        throw $exception;
                    }

                    Log::warning('Gemini unavailable, using internal source', [
                        'question' => $question,
                        'message' => $exception->getMessage(),
                    ]);

                    return response()->json([
                        'status' => 'success',
                        'text' => $this->internalSourceFallback($verified),
                        'source_type' => 'internal_fallback',
                        'normalized_question' => $normalized,
                        'related_articles' => array_map(
                            fn ($article) => $this->articlePayload($article),
                            $verified
                        ),
                    ]);
                }
            }

            return response()->json([
                'status' => 'success',
                'text' => $this->answerWithoutInternalSource(
                    $question,
                    $context
                ),
                'source_type' => 'reference',
                'normalized_question' => $normalized,
                'related_articles' => [],
            ]);
        } catch (\Throwable $exception) {
            Log::error('Dao assistant pipeline error', [
                'question' => $question,
                'message' => $exception->getMessage(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => $this->friendlyGeminiError($exception),
            ], 502);
        }
    }

    public function chat(Request $request)
    {
        $validated = $request->validate([
            'message' => 'required|string|max:30000',
        ]);

        $apiKey = (string) config('services.gemini.key');
        $model = (string) config('services.gemini.model', 'gemini-2.5-flash');

        if ($apiKey === '') {
            return response()->json([
                'status' => 'error',
                'message' => 'Backend chưa cấu hình GEMINI_API_KEY.',
            ], 503);
        }

        $prompt = 'Bạn là trợ lý AI của ứng dụng tìm hiểu văn hóa người Dao '
            . 'tại Việt Nam. Hãy ưu tiên làm đúng theo yêu cầu, ngữ cảnh và '
            . 'dữ liệu được gửi trong nội dung bên dưới. Chỉ trả lời các nội '
            . 'dung liên quan đến văn hóa Dao, học tập trong app, phong tục, '
            . 'lễ hội, trang phục, ẩm thực, thảo dược, ngôn ngữ và cộng đồng. '
            . 'Nếu dữ liệu hoặc câu hỏi nêu nhóm Dao cụ thể như Dao Đỏ thì '
            . 'phải giữ đúng tên nhóm đó. Không trả lời toán học, lập trình '
            . 'hoặc chủ đề không liên quan đến ứng dụng. Trả lời bằng tiếng '
            . 'Việt, ngắn gọn, tự nhiên, không dùng markdown nếu không được '
            . "yêu cầu.\n\nNội dung cần xử lý:\n"
            . $validated['message'];

        try {
            $response = Http::withHeaders([
                'x-goog-api-key' => $apiKey,
            ])
                ->acceptJson()
                ->timeout(35)
                ->post(
                    "https://generativelanguage.googleapis.com/v1beta/"
                    . "models/{$model}:generateContent",
                    [
                        'contents' => [
                            [
                                'role' => 'user',
                                'parts' => [
                                    ['text' => $prompt],
                                ],
                            ],
                        ],
                    ]
                );

            if (!$response->successful()) {
                Log::warning('Gemini API error', [
                    'status' => $response->status(),
                    'body' => $response->json(),
                ]);

                $googleMessage = $response->json('error.message');

                return response()->json([
                    'status' => 'error',
                    'message' => $googleMessage
                        ?: 'Gemini không xử lý được yêu cầu.',
                ], 502);
            }

            $text = trim((string) $response->json(
                'candidates.0.content.parts.0.text',
                ''
            ));

            if ($text === '') {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Gemini không trả về nội dung.',
                ], 502);
            }

            return response()->json([
                'status' => 'success',
                'text' => $text,
            ]);
        } catch (\Throwable $exception) {
            Log::error('Gemini connection error', [
                'message' => $exception->getMessage(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Không kết nối được với Gemini.',
            ], 502);
        }
    }

    private function normalizeQuestion(string $value): string
    {
        $normalized = strtolower(Str::ascii($value));
        $replacements = [
            '/\bng\s*dao\b|\bnguoi\s*d\b/' => ' nguoi dao ',
            '/\bd\s*do\b|\bdao\s*d\b/' => ' dao do ',
            '/\blcs\b|\bcap\s*xac\b|\bcx\b/' => ' le cap sac ',
            '/\btp\b/' => ' trang phuc ',
            '/\bpt\b/' => ' phong tuc ',
            '/\btd\b/' => ' thao duoc ',
            '/\bko\b|\bkhum\b|\bhok\b|\bhum\b|\bk\b/' => ' khong ',
            '/\bdc\b|\bdk\b/' => ' duoc ',
            '/\blm\b/' => ' lam ',
            '/\bntn\b/' => ' nhu the nao ',
            '/\bmn\b/' => ' moi nguoi ',
        ];
        foreach ($replacements as $pattern => $replacement) {
            $normalized = preg_replace($pattern, $replacement, $normalized);
        }

        return trim((string) preg_replace(
            '/\s+/',
            ' ',
            preg_replace('/[^a-z0-9\s]/', ' ', $normalized)
        ));
    }

    private function isFollowUpQuestion(string $question): bool
    {
        $tokens = array_values(array_filter(explode(' ', $question)));
        if (count($tokens) <= 3) return true;

        return collect([
            'con no', 'the nao', 'vi sao vay', 'co duoc khong',
            'y nghia gi', 'dien ra sao',
        ])->contains(fn ($phrase) => str_contains($question, $phrase));
    }

    private function rankCultureArticles(string $question): array
    {
        $stopWords = [
            'la', 'gi', 'co', 'cua', 'nguoi', 'dao', 've', 'va',
            'nhu', 'the', 'nao', 'cho', 'biet', 'hoi', 'bai', 'viet',
            'tai', 'sao', 'duoc', 'khong', 'trong',
        ];
        $tokens = array_values(array_unique(array_filter(
            explode(' ', $question),
            fn ($token) => strlen($token) >= 2 &&
                !in_array($token, $stopWords, true)
        )));
        $expanded = array_values(array_unique([
            ...$tokens,
            ...$this->semanticTerms($question),
        ]));

        return DB::table('culture_articles')
            ->orderByDesc('view_count')
            ->limit(200)
            ->get()
            ->map(function ($article) use ($question, $expanded) {
                $title = $this->normalizeQuestion((string) $article->title);
                $subtitle = $this->normalizeQuestion(
                    (string) $article->subtitle
                );
                $content = $this->normalizeQuestion((string) $article->content);
                $category = $this->normalizeQuestion(
                    (string) $article->category
                );
                $score = 0;

                if ($title === $question) $score += 320;
                if ($question !== '' && str_contains($title, $question)) {
                    $score += 220;
                } elseif ($question !== '' &&
                    str_contains("{$title} {$subtitle}", $question)) {
                    $score += 130;
                }

                foreach ($expanded as $term) {
                    if ($this->containsTerm($title, $term)) {
                        $score += 42;
                    } elseif ($this->containsTerm($subtitle, $term)) {
                        $score += 24;
                    } elseif ($this->containsTerm($content, $term)) {
                        $score += 8;
                    } elseif ($this->fuzzyContains($title, $term)) {
                        $score += 12;
                    }
                }

                if ($this->categoryForQuestion($question) === $category) {
                    $score += 35;
                }
                if (!$this->matchesGenderIntent(
                    $question,
                    "{$title} {$subtitle} {$category}"
                )) {
                    $score = 0;
                }
                if (!$this->matchesPrimaryIntent($question, $article)) {
                    $score = 0;
                }

                $article->_assistant_score = $score;
                return $article;
            })
            ->filter(fn ($article) => $article->_assistant_score >= 45)
            ->sortByDesc('_assistant_score')
            ->take(8)
            ->values()
            ->all();
    }

    private function semanticTerms(string $question): array
    {
        $dictionary = [
            'cap sac' => [
                'cap sac', 'truong thanh', 'phap danh', 'len den',
            ],
            'cuoi' => [
                'cuoi', 'hon nhan', 'co dau', 'chu re',
                'ruoc dau', 'don dau', 'phu the',
            ],
            'thuoc tam' => [
                'thuoc tam', 'tam thuoc', 'thao duoc',
                'duoc lieu', 'cay thuoc',
            ],
            'tang le' => [
                'tang le', 'ma chay', 'ta mo', 'nguoi da khuat',
            ],
            'trang phuc' => [
                'trang phuc', 'quan ao', 'le phuc', 'theu', 'hoa van',
            ],
            'le hoi' => [
                'le hoi', 'tet', 'nhay lua', 'cau mua', 'cung rung',
            ],
        ];

        $terms = [];
        foreach ($dictionary as $concept => $variants) {
            if (!collect($variants)->contains(
                fn ($variant) => str_contains($question, $variant)
            )) {
                continue;
            }
            $terms = [...$terms, $concept, ...$variants];
        }
        return $terms;
    }

    private function categoryForQuestion(string $question): string
    {
        if (collect([
            'trang phuc', 'quan ao', 'le phuc', 'khan', 'theu',
        ])->contains(fn ($term) => str_contains($question, $term))) {
            return 'trang phuc';
        }
        if (collect([
            'le hoi', 'nhay lua', 'tet nhay', 'cau mua',
        ])->contains(fn ($term) => str_contains($question, $term))) {
            return 'le hoi';
        }
        if (collect([
            'thuoc', 'thao duoc', 'duoc lieu', 'cay thuoc',
        ])->contains(fn ($term) => str_contains($question, $term))) {
            return 'thao duoc';
        }
        if (collect([
            'phong tuc', 'hon nhan', 'cuoi', 'tang le', 'tin nguong',
        ])->contains(fn ($term) => str_contains($question, $term))) {
            return 'phong tuc';
        }
        return '';
    }

    private function matchesPrimaryIntent(string $question, object $article): bool
    {
        $title = $this->normalizeQuestion((string) $article->title);
        $subtitle = $this->normalizeQuestion((string) $article->subtitle);
        $category = $this->normalizeQuestion((string) $article->category);
        $content = $this->normalizeQuestion((string) $article->content);
        $headline = trim("{$title} {$subtitle} {$category}");
        $fullText = trim("{$headline} {$content}");

        $checks = [
            'dao_do' => [
                'ask' => ['dao do'],
                'match' => ['dao do'],
                'headlineOnly' => false,
            ],
            'cap_sac' => [
                'ask' => ['cap sac', 'le cap sac', 'dai le cap sac'],
                'match' => ['cap sac', 'le cap sac', 'dai le cap sac'],
                'headlineOnly' => true,
            ],
            'wedding' => [
                'ask' => [
                    'phu the', 'cuoi', 'hon nhan', 'co dau', 'chu re',
                    'ruoc dau', 'don dau', 'trang phuc cuoi',
                ],
                'match' => [
                    'phu the', 'cuoi', 'hon nhan', 'co dau', 'chu re',
                    'ruoc dau', 'don dau', 'trang phuc cuoi',
                ],
                'headlineOnly' => true,
            ],
            'embroidery' => [
                'ask' => ['theu', 'theu tay', 'nghe thuat theu'],
                'match' => ['theu', 'theu tay', 'nghe thuat theu'],
                'headlineOnly' => true,
            ],
            'female_costume' => [
                'ask' => [
                    'trang phuc nu', 'phu nu', 'con gai',
                    'trang phuc phu nu',
                ],
                'match' => [
                    'trang phuc nu', 'phu nu', 'con gai',
                    'trang phuc phu nu', 'co dau',
                ],
                'headlineOnly' => true,
            ],
            'costume' => [
                'ask' => ['trang phuc', 'le phuc', 'quan ao'],
                'match' => ['trang phuc', 'le phuc', 'quan ao'],
                'headlineOnly' => true,
            ],
        ];

        foreach ($checks as $check) {
            if (!$this->containsAnyTerm($question, $check['ask'])) {
                continue;
            }

            $text = $check['headlineOnly'] ? $headline : $fullText;
            if (!$this->containsAnyTerm($text, $check['match'])) {
                return false;
            }
        }

        if (!$this->containsAnyTerm($question, $checks['cap_sac']['ask']) &&
            $this->containsAnyTerm($title, $checks['cap_sac']['match'])) {
            return false;
        }

        if (!$this->containsAnyTerm($question, $checks['wedding']['ask']) &&
            $this->containsAnyTerm($title, $checks['wedding']['match'])) {
            return false;
        }

        return true;
    }

    private function containsAnyTerm(string $text, array $terms): bool
    {
        return collect($terms)->contains(
            fn (string $term) => $this->containsTerm($text, $term)
        );
    }

    private function containsTerm(string $text, string $term): bool
    {
        return preg_match(
            '/(?:^|\s)'.preg_quote($term, '/').'(?=\s|$)/',
            $text
        ) === 1;
    }

    private function fuzzyContains(string $text, string $term): bool
    {
        if (strlen($term) < 4 || str_contains($term, ' ')) return false;
        foreach (explode(' ', $text) as $token) {
            if (abs(strlen($token) - strlen($term)) <= 1 &&
                levenshtein($token, $term) <= 1) {
                return true;
            }
        }
        return false;
    }

    private function matchesGenderIntent(
        string $question,
        string $articleText
    ): bool {
        $femaleQuestion = $this->containsTerm($question, 'nu') ||
            str_contains($question, 'phu nu') ||
            str_contains($question, 'co dau');
        $maleQuestion = $this->containsTerm($question, 'nam') ||
            str_contains($question, 'nam gioi') ||
            str_contains($question, 'dan ong');

        if ($femaleQuestion) {
            return str_contains($articleText, 'phu nu') ||
                str_contains($articleText, 'trang phuc nu') ||
                str_contains($articleText, 'co dau');
        }
        if ($maleQuestion) {
            return str_contains($articleText, 'nam gioi') ||
                str_contains($articleText, 'trang phuc nam') ||
                str_contains($articleText, 'dan ong');
        }
        return true;
    }

    private function verifyArticlesWithGemini(
        string $question,
        string $context,
        array $candidates
    ): array {
        if ($candidates === []) return [];

        $sources = collect($candidates)->map(function ($article) {
            return [
                'id' => (string) $article->id,
                'title' => (string) $article->title,
                'category' => (string) $article->category,
                'subtitle' => Str::limit((string) $article->subtitle, 300),
                'content' => Str::limit((string) $article->content, 1000),
            ];
        })->values()->all();

        $prompt = 'Bạn là bộ xác minh nguồn cho trợ lý văn hóa Dao. '
            .'Chọn tối đa 3 bài thật sự chứa thông tin có thể trả lời trực tiếp '
            .'câu hỏi. Không chọn chỉ vì cùng danh mục hoặc có vài từ chung. '
            .'Nếu không bài nào đủ phù hợp, trả về []. Chỉ trả JSON array ID, '
            ."không giải thích.\nNgữ cảnh: {$context}\nCâu hỏi: {$question}\n"
            .'Ứng viên: '.json_encode(
                $sources,
                JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
            );
        $raw = $this->callGemini($prompt);
        $ids = $this->decodeJsonArray($raw);
        if ($ids === []) return [];

        return collect($candidates)
            ->filter(fn ($article) => in_array((string) $article->id, $ids, true))
            ->sortBy(fn ($article) => array_search(
                (string) $article->id,
                $ids,
                true
            ))
            ->take(3)
            ->values()
            ->all();
    }

    private function answerFromInternalSources(
        string $question,
        string $context,
        array $articles
    ): ?string {
        $sources = collect($articles)->map(fn ($article) => [
            'title' => $article->title,
            'category' => $article->category,
            'subtitle' => $article->subtitle,
            'content' => Str::limit((string) $article->content, 2200),
        ])->values()->all();

        $answer = $this->callGemini(
            'Bạn là trợ lý văn hóa Dao. Trả lời câu hỏi chỉ dựa trên nguồn '
            .'nội bộ được cung cấp, không thêm kiến thức ngoài nguồn. '
            .'Nguồn phải đủ trả lời tất cả ý chính trong câu hỏi. Nếu nguồn '
            .'chỉ liên quan một phần hoặc thiếu một ý chính, chỉ trả về đúng '
            .'mã INTERNAL_SOURCE_NOT_ENOUGH. '
            .'Nếu thông tin khác nhau theo nhóm Dao hoặc địa phương, nói rõ. '
            .'Trả lời tiếng Việt tự nhiên, 3-6 câu, không markdown, không nhắc '
            ."đến quá trình tìm kiếm.\nNgữ cảnh: {$context}\n"
            ."Câu hỏi: {$question}\nNguồn nội bộ: "
            .json_encode(
                $sources,
                JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
            )
        );
        if (str_contains($answer, 'INTERNAL_SOURCE_NOT_ENOUGH')) return null;
        return $answer;
    }

    private function answerWithoutInternalSource(
        string $question,
        string $context
    ): string {
        return $this->callGemini(
            'Bạn là trợ lý văn hóa Dao tại Việt Nam. Kho dữ liệu nội bộ không '
            .'có nguồn đủ phù hợp, vì vậy hãy trả lời thận trọng như thông tin '
            .'tham khảo. Mở đầu đúng bằng "Thông tin tham khảo từ AI:". '
            .'Không bịa chi tiết; nếu tùy nhóm Dao hoặc địa phương phải nói rõ. '
            .'Chỉ trả lời chủ đề liên quan văn hóa Dao. Trả lời tiếng Việt '
            ."3-5 câu, không markdown.\nNgữ cảnh: {$context}\n"
            ."Câu hỏi: {$question}"
        );
    }

    private function callGemini(string $prompt): string
    {
        $apiKey = (string) config('services.gemini.key');
        $model = (string) config('services.gemini.model', 'gemini-2.5-flash');
        if ($apiKey === '') {
            throw new RuntimeException('GEMINI_NOT_CONFIGURED');
        }

        $response = null;
        for ($attempt = 0; $attempt < 3; $attempt++) {
            $response = Http::withHeaders(['x-goog-api-key' => $apiKey])
                ->acceptJson()
                ->timeout(35)
                ->post(
                "https://generativelanguage.googleapis.com/v1beta/"
                ."models/{$model}:generateContent",
                [
                    'contents' => [[
                        'role' => 'user',
                        'parts' => [['text' => $prompt]],
                    ]],
                ]
            );

            if ($response->status() !== 503 || $attempt === 2) break;
            usleep(($attempt + 1) * 900000);
        }

        if (!$response->successful()) {
            $message = (string) $response->json('error.message', '');
            throw new RuntimeException(
                "GEMINI_HTTP_{$response->status()}:{$message}"
            );
        }

        $text = trim((string) $response->json(
            'candidates.0.content.parts.0.text',
            ''
        ));
        if ($text === '') throw new RuntimeException('GEMINI_EMPTY_RESPONSE');
        return $text;
    }

    private function isTemporaryGeminiError(\Throwable $exception): bool
    {
        $message = strtolower($exception->getMessage());
        return str_contains($message, 'gemini_http_429') ||
            str_contains($message, 'gemini_http_503') ||
            str_contains($message, 'quota') ||
            str_contains($message, 'high demand');
    }

    private function internalSourceFallback(array $articles): string
    {
        $article = $articles[0];
        $content = trim(strip_tags(
            (string) ($article->content ?: $article->subtitle)
        ));
        $content = preg_replace('/\s+/u', ' ', $content) ?: '';
        $excerpt = Str::limit($content, 520);

        return 'Gemini đang tạm bận, nên mình hiển thị thông tin từ bài viết '
            .'nội bộ phù hợp nhất. Theo bài “'.$article->title.'”: '.$excerpt;
    }

    private function decodeJsonArray(string $value): array
    {
        $start = strpos($value, '[');
        $end = strrpos($value, ']');
        if ($start === false || $end === false || $end <= $start) return [];
        $decoded = json_decode(substr($value, $start, $end - $start + 1), true);
        if (!is_array($decoded)) return [];
        return array_values(array_map('strval', $decoded));
    }

    private function articlePayload(object $article): array
    {
        return [
            'id' => (string) $article->id,
            'title' => (string) $article->title,
            'subtitle' => (string) $article->subtitle,
            'category' => (string) $article->category,
            'content' => (string) $article->content,
            'image_url' => (string) $article->image_url,
            'video_url' => (string) $article->video_url,
        ];
    }

    private function friendlyGeminiError(\Throwable $exception): string
    {
        $message = $exception->getMessage();
        if (str_contains($message, 'GEMINI_NOT_CONFIGURED')) {
            return 'Trợ lý AI chưa được cấu hình trên máy chủ.';
        }
        if (str_contains($message, '429') ||
            str_contains(strtolower($message), 'quota')) {
            return 'Trợ lý AI đang quá tải. Bạn vui lòng thử lại sau ít phút.';
        }
        if (str_contains($message, '503') ||
            str_contains(strtolower($message), 'high demand')) {
            return 'Gemini đang bận và chưa thể phản hồi. Bạn thử lại sau nhé.';
        }
        if (str_contains($message, 'EMPTY_RESPONSE')) {
            return 'Gemini không trả về nội dung. Bạn hãy thử diễn đạt lại câu hỏi.';
        }
        return 'Không kết nối được với trợ lý AI. Vui lòng kiểm tra mạng và thử lại.';
    }
}
