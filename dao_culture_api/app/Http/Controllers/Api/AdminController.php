<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminController extends Controller
{
    public function users()
    {
        return response()->json(
            DB::table('users')
                ->select(
                    'id', 'username', 'full_name', 'role',
                    'xp', 'total_xp', 'streak_count', 'avatar',
                    'violation_count', 'banned_until',
                    'is_locked', 'created_at'
                )
                ->orderByDesc('created_at')
                ->get()
        );
    }

    public function updateUserStatus(Request $request)
    {
        $updated = DB::table('users')
            ->where('id', $request->integer('user_id'))
            ->where('role', '!=', 'admin')
            ->update([
                'is_locked' => $request->boolean('is_locked') ? 1 : 0,
            ]);

        return response()->json([
            'status' => $updated ? 'success' : 'error',
            'message' => $updated
                ? 'Đã cập nhật tài khoản'
                : 'Không thể cập nhật tài khoản',
        ]);
    }

    public function deleteUser(Request $request)
    {
        $user = DB::table('users')
            ->where('id', $request->integer('user_id'))
            ->first();

        if (!$user || $user->role === 'admin') {
            return response()->json([
                'status' => 'error',
                'message' => 'Không thể xóa tài khoản này',
            ], 403);
        }

        DB::table('users')->where('id', $user->id)->delete();

        return response()->json(['status' => 'success']);
    }

    public function reports(Request $request)
    {
        $reports = DB::table('reports as r')
                ->leftJoin('posts as p', 'p.id', '=', 'r.post_id')
                ->leftJoin('users as reporter', 'reporter.id', '=', 'r.user_id')
                ->leftJoin('users as author', 'author.id', '=', 'p.user_id')
                ->select(
                    'r.id',
                    'r.post_id',
                    'r.user_id',
                    'r.reason',
                    'r.status',
                    'r.created_at',
                    'p.content as post_content',
                    'p.media_url',
                    'p.gallery_urls',
                    'p.media_type',
                    DB::raw(
                        "COALESCE(NULLIF(reporter.full_name, ''), "
                        ."reporter.username, r.user_id) as reporter_name"
                    ),
                    DB::raw(
                        "COALESCE(NULLIF(author.full_name, ''), "
                        ."author.username, p.user_id) as author_name"
                    )
                )
                ->where('r.status', 'pending')
                ->orderByDesc('r.created_at')
                ->get();

        $imageEndpoint = $request->getSchemeAndHttpHost()
            . '/api/posts/image.php';
        $videoEndpoint = $request->getSchemeAndHttpHost()
            . '/api/posts/video.php';

        $reports->transform(function ($report) use (
            $imageEndpoint,
            $videoEndpoint
        ) {
            $isVideo = strtolower((string) ($report->media_type ?? ''))
                === 'video';
            $endpoint = $isVideo ? $videoEndpoint : $imageEndpoint;
            $report->media_url = $this->postMediaUrl(
                $endpoint,
                (string) ($report->media_url ?? '')
            );

            $gallery = json_decode(
                (string) ($report->gallery_urls ?? ''),
                true
            );
            $report->gallery_urls = is_array($gallery)
                ? array_values(array_filter(array_map(
                    fn ($url) => $this->postMediaUrl(
                        $isVideo ? $videoEndpoint : $imageEndpoint,
                        (string) $url
                    ),
                    $gallery
                )))
                : [];

            return $report;
        });

        return response()->json($reports);
    }

    private function postMediaUrl(string $endpoint, string $value): string
    {
        $path = parse_url(trim($value), PHP_URL_PATH);
        $fileName = basename(is_string($path) ? $path : '');
        return $fileName === ''
            ? ''
            : $endpoint . '?file=' . rawurlencode($fileName);
    }

    public function resolveReport(Request $request)
    {
        $status = (string) $request->input('status');

        if (!in_array($status, ['resolved', 'rejected'], true)) {
            return response()->json(['status' => 'error'], 422);
        }

        $updated = DB::table('reports')
            ->where('id', $request->integer('report_id'))
            ->update(['status' => $status]);

        return response()->json([
            'status' => $updated ? 'success' : 'error',
            'message' => $updated
                ? 'Đã xử lý báo cáo.'
                : 'Không tìm thấy báo cáo cần xử lý.',
        ], $updated ? 200 : 404);
    }
}
