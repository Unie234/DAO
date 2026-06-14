<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class PostController extends Controller
{
    public function image(Request $request)
    {
        $fileName = basename((string) $request->query('file'));

        if ($fileName === '') {
            return response()->json([
                'status' => 'error',
                'message' => 'Thiếu tên ảnh',
            ], 400);
        }

        $candidates = [
            "uploads/posts/{$fileName}",
            "uploads/{$fileName}",
        ];

        foreach ($candidates as $path) {
            if (!Storage::disk('public')->exists($path)) {
                continue;
            }

            return response()->file(
                storage_path("app/public/{$path}"),
                [
                    'Access-Control-Allow-Origin' => '*',
                    'Cross-Origin-Resource-Policy' => 'cross-origin',
                    'Cache-Control' => 'public, max-age=86400',
                ]
            );
        }

        return response()->json([
            'status' => 'error',
            'message' => 'Không tìm thấy ảnh',
        ], 404);
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

        $path = "uploads/posts/{$fileName}";
        if (!Storage::disk('public')->exists($path)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Không tìm thấy video',
            ], 404);
        }

        return response()->file(storage_path("app/public/{$path}"), [
            'Content-Type' => $this->videoContentType($path),
            'Access-Control-Allow-Origin' => '*',
            'Cross-Origin-Resource-Policy' => 'cross-origin',
            'Accept-Ranges' => 'bytes',
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }

    public function index(Request $request)
    {
        $userId = $request->input('user_id');
        $postId = $request->integer('post_id');
        $sort = trim((string) $request->query('sort', 'latest'));
        $limit = min(max($request->integer('limit'), 0), 50);

        $postsQuery = DB::table('posts as p')
            ->leftJoin('users as u', 'u.id', '=', 'p.user_id')
            ->where('p.status', 'active')
            ->select([
                'p.*',
                'u.username',
                'u.full_name as author_name',
                'u.avatar as author_avatar',
                'u.role as author_role',
            ])
            ->selectSub(function ($query) {
                $query->from('post_reactions')
                    ->whereColumn('post_id', 'p.id')
                    ->selectRaw('COUNT(*)');
            }, 'reaction_count')
            ->selectSub(function ($query) {
                $query->from('saved_posts')
                    ->whereColumn('post_id', 'p.id')
                    ->selectRaw('COUNT(*)');
            }, 'save_count')
            ->selectSub(function ($query) {
                $query->from('comments')
                    ->whereColumn('post_id', 'p.id')
                    ->selectRaw('COUNT(*)');
            }, 'comment_count')
            ->selectSub(function ($query) use ($userId) {
                $query->from('post_reactions')
                    ->whereColumn('post_id', 'p.id')
                    ->where('user_id', $userId ?: 0)
                    ->select('reaction')
                    ->limit(1);
            }, 'my_reaction')
            ->selectSub(function ($query) use ($userId) {
                $query->from('saved_posts')
                    ->whereColumn('post_id', 'p.id')
                    ->where('user_id', $userId ?: 0)
                    ->selectRaw('1')
                    ->limit(1);
            }, 'is_saved');

        if ($postId > 0) {
            $postsQuery->where('p.id', $postId);
        }

        if ($sort === 'popular') {
            $postsQuery
                ->orderByRaw(
                    '(reaction_count + comment_count + save_count) DESC'
                )
                ->orderByDesc('p.created_at');
        } else {
            $postsQuery->orderByDesc('p.created_at');
        }

        if ($limit > 0) {
            $postsQuery->limit($limit);
        }

        $posts = $postsQuery->get();

        $imageEndpoint = $request->getSchemeAndHttpHost()
            . '/api/posts/image.php';
        $videoEndpoint = $request->getSchemeAndHttpHost()
            . '/api/posts/video.php';

        $posts->transform(function ($post) use ($imageEndpoint, $videoEndpoint) {
            $post->author_avatar = $this->avatarUrl(
                $imageEndpoint,
                (string) ($post->author_avatar ?? '')
            );

            $isVideo = strtolower((string) ($post->media_type ?? 'image'))
                === 'video';
            $post->media_url = $this->postMediaUrl(
                $isVideo ? $videoEndpoint : $imageEndpoint,
                $post->media_url ?? ''
            );

            $gallery = json_decode((string) ($post->gallery_urls ?? ''), true);
            if (is_array($gallery)) {
                $post->gallery_urls = array_values(array_filter(array_map(
                    fn ($url) => $this->postMediaUrl(
                        $isVideo ? $videoEndpoint : $imageEndpoint,
                        (string) $url
                    ),
                    $gallery
                )));
            } else {
                $post->gallery_urls = [];
            }

            return $post;
        });

        return response()->json([
            'status' => 'success',
            'data' => $posts,
        ]);
    }

    private function postMediaUrl(string $endpoint, string $value): string
    {
        $path = parse_url(trim($value), PHP_URL_PATH);
        $fileName = basename(is_string($path) ? $path : '');

        if ($fileName === '') {
            return '';
        }

        return $endpoint . '?file=' . rawurlencode($fileName);
    }

    private function avatarUrl(string $imageEndpoint, string $value): string
    {
        $path = parse_url(trim($value), PHP_URL_PATH);
        $fileName = basename(is_string($path) ? $path : '');

        if ($fileName === '') {
            return '';
        }

        $baseUrl = str_replace(
            '/api/posts/image.php',
            '/api/users/avatar.php',
            $imageEndpoint
        );

        return $baseUrl . '?file=' . rawurlencode($fileName);
    }

    private function videoContentType(string $path): string
    {
        return match (strtolower(pathinfo($path, PATHINFO_EXTENSION))) {
            'mov' => 'video/quicktime',
            'webm' => 'video/webm',
            'm4v' => 'video/x-m4v',
            default => 'video/mp4',
        };
    }

    public function reaction(Request $request)
    {
        $request->validate([
            'post_id' => 'required|integer|exists:posts,id',
            'user_id' => 'required|integer|exists:users,id',
            'reaction' => 'required|string|in:like,love,haha,wow,sad,angry',
        ]);

        $existing = DB::table('post_reactions')->where([
            'post_id' => $request->post_id,
            'user_id' => $request->user_id,
        ])->first();

        if ($existing && $existing->reaction === $request->reaction) {
            DB::table('post_reactions')->where('id', $existing->id)->delete();
            return response()->json(['status' => 'removed']);
        }

        DB::table('post_reactions')->updateOrInsert(
            [
                'post_id' => $request->post_id,
                'user_id' => $request->user_id,
            ],
            [
                'reaction' => $request->reaction,
                'updated_at' => now(),
            ]
        );

        $this->notifyPostOwner(
            $request->integer('post_id'),
            $request->integer('user_id'),
            'post_reaction',
            'Bài viết có cảm xúc mới',
            'đã thả cảm xúc vào bài viết của bạn.',
            'reaction'
        );

        return response()->json(['status' => 'success']);
    }

    public function save(Request $request)
    {
        $request->validate([
            'post_id' => 'required|integer|exists:posts,id',
            'user_id' => 'required|integer|exists:users,id',
        ]);

        $key = [
            'post_id' => $request->post_id,
            'user_id' => $request->user_id,
        ];

        if (DB::table('saved_posts')->where($key)->exists()) {
            DB::table('saved_posts')->where($key)->delete();
            return response()->json(['status' => 'unsaved']);
        }

        DB::table('saved_posts')->insert($key + ['created_at' => now()]);
        return response()->json(['status' => 'saved']);
    }

    public function report(Request $request)
    {
        $request->validate([
            'post_id' => 'required|integer|exists:posts,id',
            'user_id' => 'required|integer|exists:users,id',
            'reason' => 'required|string|max:255',
        ]);

        $userId = $request->integer('user_id');

        DB::table('reports')->updateOrInsert(
            [
                'post_id' => $request->integer('post_id'),
                'user_id' => $userId,
                'status' => 'pending',
            ],
            [
                'reason' => trim((string) $request->input('reason')),
                'created_at' => now(),
            ]
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Đã gửi báo cáo cho quản trị viên.',
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'post_id' => 'nullable|integer',
            'content' => 'nullable|string|max:10000',
            'media_file' => 'nullable|file|mimes:jpg,jpeg,png,webp,gif,heic,heif,mp4,mov,webm,m4v|max:102400',
            'media_files' => 'nullable|array|max:8',
            'media_files.*' => 'nullable|file|mimes:jpg,jpeg,png,webp,gif,heic,heif|max:10240',
        ], [
            'media_file.mimes' => 'File chỉ hỗ trợ ảnh JPG, PNG, WEBP, GIF, HEIC hoặc video MP4, MOV, WEBM.',
            'media_file.max' => 'Video/file bài viết phải nhỏ hơn 100MB.',
            'media_files.max' => 'Mỗi bài chỉ chọn tối đa 8 ảnh.',
            'media_files.*.mimes' => 'Ảnh chỉ hỗ trợ JPG, PNG, WEBP, GIF hoặc HEIC.',
            'media_files.*.max' => 'Mỗi ảnh phải nhỏ hơn 10MB.',
        ]);

        $userId = $request->integer('user_id');
        $postId = $request->integer('post_id');
        $content = trim((string) $request->input('content'));
        $mediaUrls = [];
        $mediaType = 'image';

        if ($this->containsCommunityViolation($content)) {
            return response()->json([
                'status' => 'community_violation',
                'message' => 'Nội dung chứa từ ngữ không phù hợp với tiêu chuẩn cộng đồng.',
            ]);
        }

        foreach ($request->file('media_files', []) as $file) {
            $path = $file->store('uploads/posts', 'public');
            $mediaUrls[] = url("storage/$path");
        }

        if ($request->hasFile('media_file')) {
            $file = $request->file('media_file');
            $path = $file->store('uploads/posts', 'public');
            $mediaUrls[] = url("storage/$path");
            $mediaType = str_starts_with(
                (string) $file->getMimeType(),
                'video/'
            ) ? 'video' : 'image';
        }

        if ($content === '' && !$mediaUrls && $postId <= 0) {
            return response()->json([
                'status' => 'error',
                'message' => 'Bài viết cần có nội dung hoặc hình ảnh.',
            ], 422);
        }

        if ($postId > 0) {
            $post = DB::table('posts')->where('id', $postId)->first();

            if (!$post || (int) $post->user_id !== $userId) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Bạn không có quyền sửa bài viết này.',
                ], 403);
            }

            $update = ['content' => $content];

            if ($request->boolean('remove_media')) {
                $update += ['media_url' => '', 'gallery_urls' => '[]'];
            }

            if ($mediaUrls) {
                $update += [
                    'media_url' => $mediaUrls[0],
                    'gallery_urls' => json_encode($mediaUrls),
                    'media_type' => $mediaType,
                ];
            }

            DB::table('posts')->where('id', $postId)->update($update);

            return response()->json([
                'status' => 'success',
                'post_id' => $postId,
            ]);
        }

        $id = DB::table('posts')->insertGetId([
            'user_id' => $userId,
            'content' => $content,
            'media_url' => $mediaUrls[0] ?? '',
            'gallery_urls' => json_encode($mediaUrls),
            'media_type' => $mediaType,
            'status' => 'active',
            'created_at' => now(),
        ]);

        $author = DB::table('users')->find($userId);
        $authorName = $author?->full_name ?: $author?->username ?: 'Một thành viên';

        DB::table('users')
            ->where('id', '!=', $userId)
            ->where('is_locked', 0)
            ->select('id')
            ->orderBy('id')
            ->chunkById(200, function ($users) use ($id, $authorName) {
                $rows = [];
                foreach ($users as $user) {
                    $rows[] = [
                        'user_id' => $user->id,
                        'type' => 'new_post',
                        'title' => 'Bài viết mới',
                        'message' => "{$authorName} vừa đăng một bài viết mới.",
                        'post_id' => $id,
                        'comment_id' => null,
                        'unique_key' => "new_post_{$id}_{$user->id}",
                        'priority' => 'normal',
                        'is_read' => 0,
                        'created_at' => now(),
                    ];
                }
                if ($rows) {
                    DB::table('notifications')->insert($rows);
                }
            });

        return response()->json(['status' => 'success', 'post_id' => $id]);
    }

    private function containsCommunityViolation(string $content): bool
    {
        if ($content === '') return false;

        $normalized = trim((string) preg_replace(
            '/\s+/',
            ' ',
            preg_replace(
                '/[^a-z0-9\s]/',
                ' ',
                strtolower(Str::ascii($content))
            )
        ));
        $compact = preg_replace('/[^a-z0-9]/', '', $normalized) ?: '';

        $phrases = [
            // Tu ngu tho tuc, cong kich ca nhan hoac chui rua.
            'chui bay', 'chui tuc', 'noi tuc', 'vang tuc', 'tuc tiu',
            'dit me', 'du ma', 'do ngu', 'do mat day', 'mat day',
            'vo hoc', 'khon nan', 'con cho', 'cho chet', 'bien di',
            'danh chet', 'giet may', 'giet no', 'oc cho', 'suc vat',
            'dau buoi', 'con cac', 'cai lon', 'deo me', 'deo hieu',
            'deo biet',

            // Lua dao, kich dong, quang cao/rao ban/keo nguoi dung ra ngoai.
            'lua dao', 'kich dong', 'pha hoai', 'tay chay',
            'quang cao', 'quang ba', 'ban hang', 'rao ban', 'khuyen mai',
            'giam gia', 'sale', 'mua ngay', 'dat hang', 'chot don',
            'kiem tien', 'tuyen cong tac vien', 'tuyen ctv', 'nap tien',
            'vay tien', 'cho vay', 'zalo', 'telegram', 'so dien thoai',
            'lien he mua',

            // Che bai, phu nhan, xuc pham van hoa va phong tuc.
            'che bai van hoa', 'phe binh van hoa', 'noi xau van hoa',
            'bai xich van hoa', 'bai tru van hoa', 'ha thap van hoa',
            'xuc pham van hoa', 'van hoa lac hau', 'van hoa dao lac hau',
            'van hoa kem van minh', 'phong tuc lac hau', 'phong tuc xau',
            'hu tuc', 'me tin di doan', 'khong dang ton tai', 'bai viet nay te',
        ];
        foreach ($phrases as $phrase) {
            if (str_contains($normalized, $phrase)) return true;
            if (str_contains($compact, str_replace(' ', '', $phrase))) {
                return true;
            }
        }

        $blockedTokens = [
            'dm', 'dmm', 'dmmm', 'vcl', 'clm', 'clgt', 'cc', 'vl',
        ];
        $tokens = array_filter(explode(' ', $normalized));
        return collect($blockedTokens)->contains(
            fn (string $word) => in_array($word, $tokens, true)
        );
    }


    public function hide(Request $request)
    {
        $post = DB::table('posts')
            ->where('id', $request->integer('post_id'))
            ->first();

        if (!$post) {
            return response()->json(['status' => 'error'], 404);
        }

        DB::table('posts')->where('id', $post->id)->update([
            'status' => 'hidden',
        ]);

        $banDays = max(0, $request->integer('ban_days'));

        if ($post->user_id) {
            $updates = [
                'violation_count' => DB::raw('violation_count + 1'),
            ];

            if ($banDays > 0) {
                $updates['banned_until'] = now()->addDays($banDays);
            }

            DB::table('users')->where('id', $post->user_id)->update($updates);

            DB::table('notifications')->insert([
                'user_id' => $post->user_id,
                'type' => 'post_hidden',
                'title' => 'Bài viết đã bị ẩn',
                'message' => 'Bài viết của bạn vi phạm tiêu chuẩn cộng đồng.',
                'post_id' => $post->id,
                'unique_key' => 'post_hidden_'.$post->id.'_'.time(),
                'priority' => 'high',
                'is_read' => 0,
                'created_at' => now(),
            ]);
        }

        return response()->json(['status' => 'success']);
    }

    public function like(Request $request)
    {
        $data = $request->json()->all() ?: $request->all();

        $key = [
            'post_id' => (int) ($data['post_id'] ?? 0),
            'user_id' => (string) ($data['user_id'] ?? ''),
        ];

        if (DB::table('likes')->where($key)->exists()) {
            DB::table('likes')->where($key)->delete();
            return response()->json(['status' => 'unliked']);
        }

        DB::table('likes')->insert($key + ['created_at' => now()]);

        return response()->json(['status' => 'liked']);
    }

    public function destroy(Request $request)
    {
        $request->validate([
            'post_id' => 'required|integer',
            'user_id' => 'nullable|integer',
            'admin_user_id' => 'nullable|integer',
        ]);

        $post = DB::table('posts')->find($request->integer('post_id'));
        if (!$post) {
            return response()->json([
                'status' => 'error',
                'message' => 'Không tìm thấy bài viết.',
            ], 404);
        }

        $userId = $request->integer('user_id');
        $admin = DB::table('users')
            ->where('id', $request->integer('admin_user_id'))
            ->where('role', 'admin')
            ->first();

        if ((int) $post->user_id !== $userId && !$admin) {
            return response()->json([
                'status' => 'error',
                'message' => 'Bạn không có quyền xóa bài viết này.',
            ], 403);
        }

        DB::transaction(function () use ($post) {
            $commentIds = DB::table('comments')
                ->where('post_id', $post->id)
                ->pluck('id');

            if ($commentIds->isNotEmpty()) {
                DB::table('comment_reactions')
                    ->whereIn('comment_id', $commentIds)
                    ->delete();
            }

            DB::table('comments')->where('post_id', $post->id)->delete();
            DB::table('post_reactions')->where('post_id', $post->id)->delete();
            DB::table('saved_posts')->where('post_id', $post->id)->delete();
            DB::table('reports')->where('post_id', $post->id)->delete();
            DB::table('notifications')->where('post_id', $post->id)->delete();
            DB::table('posts')->where('id', $post->id)->delete();
        });

        return response()->json(['status' => 'success']);
    }

    private function notifyPostOwner(
        int $postId,
        int $actorId,
        string $type,
        string $title,
        string $action,
        string $keyPrefix
    ): void {
        $post = DB::table('posts')->find($postId);
        if (!$post || (int) $post->user_id === $actorId) {
            return;
        }

        $actor = DB::table('users')->find($actorId);
        $actorName = $actor?->full_name ?: $actor?->username ?: 'Một thành viên';

        DB::table('notifications')->updateOrInsert(
            [
                'unique_key' => "{$keyPrefix}_{$postId}_{$actorId}",
            ],
            [
                'user_id' => $post->user_id,
                'type' => $type,
                'title' => $title,
                'message' => "{$actorName} {$action}",
                'post_id' => $postId,
                'comment_id' => null,
                'priority' => 'normal',
                'is_read' => 0,
                'deleted_at' => null,
                'created_at' => now(),
            ]
        );
    }
}
