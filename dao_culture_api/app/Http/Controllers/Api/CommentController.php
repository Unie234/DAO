<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CommentController extends Controller
{
    public function index(Request $request)
    {
        $userId = $request->integer('user_id');
        $postId = $request->integer('post_id');

        $comments = DB::table('comments as c')
            ->leftJoin('users as u', 'u.id', '=', 'c.user_id')
            ->where('c.post_id', $postId)
            ->select(
                'c.id',
                'c.post_id',
                'c.parent_id',
                'c.user_id',
                'c.text as content',
                'c.created_at',
                DB::raw('COALESCE(u.full_name, c.user_name) as author_name'),
                'u.avatar as author_avatar'
            )
            ->selectSub(
                fn ($query) => $query
                    ->from('comment_reactions')
                    ->whereColumn('comment_id', 'c.id')
                    ->selectRaw('COUNT(*)'),
                'reaction_count'
            )
            ->selectSub(
                fn ($query) => $query
                    ->from('comment_reactions')
                    ->whereColumn('comment_id', 'c.id')
                    ->where('user_id', $userId)
                    ->select('reaction')
                    ->limit(1),
                'my_reaction'
            )
            ->orderBy('c.created_at')
            ->get();

        $avatarEndpoint = $request->getSchemeAndHttpHost()
            . '/api/users/avatar.php';
        $comments->transform(function ($comment) use ($avatarEndpoint) {
            $path = parse_url(
                trim((string) ($comment->author_avatar ?? '')),
                PHP_URL_PATH
            );
            $fileName = basename(is_string($path) ? $path : '');
            $comment->author_avatar = $fileName === ''
                ? ''
                : $avatarEndpoint . '?file=' . rawurlencode($fileName);
            return $comment;
        });

        return response()->json($comments);
    }

    public function store(Request $request)
    {
        $userId = $request->integer('user_id');
        $postId = $request->integer('post_id');
        $parentId = $request->input('parent_id');
        $content = trim((string) $request->input('content'));

        $user = DB::table('users')->find($userId);
        $post = DB::table('posts')->find($postId);

        if (!$user || !$post) {
            return response()->json([
                'status' => 'error',
                'message' => 'Không tìm thấy người dùng',
            ], 404);
        }

        if ($content === '') {
            return response()->json([
                'status' => 'error',
                'message' => 'Nội dung không được để trống',
            ], 422);
        }

        $id = DB::table('comments')->insertGetId([
            'post_id' => $postId,
            'parent_id' => $parentId ?: null,
            'user_id' => $userId,
            'user_name' => $user->full_name ?: $user->username,
            'text' => $content,
            'created_at' => now(),
        ]);

        $recipientId = (int) $post->user_id;
        $type = 'post_comment';
        $title = 'Bài viết có bình luận mới';

        if ($parentId) {
            $parent = DB::table('comments')->find((int) $parentId);
            if ($parent && (int) $parent->post_id === $postId) {
                $recipientId = (int) $parent->user_id;
                $type = 'comment_reply';
                $title = 'Bình luận có phản hồi mới';
            }
        }

        if ($recipientId > 0 && $recipientId !== $userId) {
            $actorName = $user->full_name ?: $user->username;
            DB::table('notifications')->insert([
                'user_id' => $recipientId,
                'type' => $type,
                'title' => $title,
                'message' => "{$actorName} đã bình luận: {$content}",
                'post_id' => $postId,
                'comment_id' => $id,
                'unique_key' => "comment_{$id}_{$recipientId}",
                'priority' => 'normal',
                'is_read' => 0,
                'created_at' => now(),
            ]);
        }

        return response()->json([
            'status' => 'success',
            'id' => $id,
        ]);
    }

    public function reaction(Request $request)
    {
        $request->validate([
            'comment_id' => 'required|integer|exists:comments,id',
            'user_id' => 'required|integer|exists:users,id',
            'reaction' => 'required|string|in:like,love,haha,wow,sad,angry',
        ]);

        $reaction = (string) $request->input('reaction');

        $key = [
            'comment_id' => $request->integer('comment_id'),
            'user_id' => $request->integer('user_id'),
        ];

        $existing = DB::table('comment_reactions')->where($key)->first();

        if ($existing && $existing->reaction === $reaction) {
            DB::table('comment_reactions')
                ->where('id', $existing->id)
                ->delete();

            return response()->json(['status' => 'removed']);
        }

        DB::table('comment_reactions')->updateOrInsert($key, [
            'reaction' => $reaction,
            'updated_at' => now(),
        ]);

        $comment = DB::table('comments')->find($key['comment_id']);
        if ($comment && (int) $comment->user_id !== $key['user_id']) {
            $actor = DB::table('users')->find($key['user_id']);
            $actorName = $actor?->full_name ?: $actor?->username ?: 'Một thành viên';

            DB::table('notifications')->updateOrInsert(
                ['unique_key' => "comment_reaction_{$comment->id}_{$key['user_id']}"],
                [
                    'user_id' => $comment->user_id,
                    'type' => 'comment_reaction',
                    'title' => 'Bình luận có cảm xúc mới',
                    'message' => "{$actorName} đã thả cảm xúc vào bình luận của bạn.",
                    'post_id' => $comment->post_id,
                    'comment_id' => $comment->id,
                    'priority' => 'normal',
                    'is_read' => 0,
                    'deleted_at' => null,
                    'created_at' => now(),
                ]
            );
        }

        return response()->json(['status' => 'success']);
    }

    public function destroy(Request $request)
    {
        $commentId = $request->integer('comment_id')
            ?: $request->integer('id');
        $comment = DB::table('comments')->find($commentId);

        if (!$comment) {
            return response()->json(['status' => 'error'], 404);
        }

        $userId = $request->integer('user_id');
        $admin = DB::table('users')
            ->where('id', $request->integer('admin_user_id'))
            ->where('role', 'admin')
            ->first();

        if ($userId > 0 && (int) $comment->user_id !== $userId && !$admin) {
            return response()->json(['status' => 'error'], 403);
        }

        DB::transaction(function () use ($commentId) {
            $ids = DB::table('comments')
                ->where('id', $commentId)
                ->orWhere('parent_id', $commentId)
                ->pluck('id');

            DB::table('comment_reactions')->whereIn('comment_id', $ids)->delete();
            DB::table('notifications')->whereIn('comment_id', $ids)->delete();
            DB::table('comments')->whereIn('id', $ids)->delete();
        });

        return response()->json(['status' => 'success']);
    }
}
