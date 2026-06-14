<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;

class UserController extends Controller
{
    public function avatar(Request $request)
    {
        $fileName = basename((string) $request->query('file'));

        if ($fileName === '') {
            return response()->json([
                'status' => 'error',
                'message' => 'Thiếu tên ảnh',
            ], 400);
        }

        $path = "uploads/avatars/{$fileName}";

        if (!Storage::disk('public')->exists($path)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Không tìm thấy ảnh đại diện',
            ], 404);
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

    public function profile(Request $request)
    {
        $userId = $request->integer('user_id');

        $user = DB::table('users')->where('id', $userId)->first();

        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'Không tìm thấy người dùng',
            ], 404);
        }

        $postCount = DB::table('posts')
            ->where('user_id', $userId)
            ->count();

        return response()->json([
            'status' => 'success',
            'user_id' => $user->id,
            'username' => $user->username,
            'full_name' => $user->full_name,
            'role' => $user->role,
            'avatar' => $this->avatarUrl(
                $request,
                (string) ($user->avatar ?? '')
            ),
            'xp' => $user->xp ?? 0,
            'total_xp' => $user->total_xp ?? 0,
            'streak_count' => $user->streak_count ?? 0,
            'post_count' => $postCount,
            'visited_count' => 0,
        ]);
    }

    public function updateProfile(Request $request)
    {
        $user = User::find($request->user_id);

        if (!$user) {
            return response()->json(['status' => 'error']);
        }

        $user->full_name = $request->full_name;
        $user->save();

        return response()->json([
            'status' => 'success',
            'full_name' => $user->full_name,
        ]);
    }

    public function changePassword(Request $request)
    {
        $user = User::find($request->user_id);

        if (!$user || !Hash::check($request->old_password, $user->password)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Mật khẩu cũ không đúng',
            ]);
        }

        $user->password = Hash::make($request->new_password);
        $user->save();

        return response()->json([
            'status' => 'success',
            'message' => 'Đổi mật khẩu thành công',
        ]);
    }

    public function uploadAvatar(Request $request)
    {
        $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'avatar' => 'required|file|mimes:jpg,jpeg,png,webp|max:5120',
        ]);

        $user = DB::table('users')->find($request->integer('user_id'));

        if (!$user) {
            return response()->json(['status' => 'error'], 404);
        }

        $path = $request->file('avatar')->store('uploads/avatars', 'public');
        $avatarUrl = url("storage/$path");
        $publicAvatarUrl = $this->avatarUrl($request, $avatarUrl);

        DB::table('users')->where('id', $user->id)->update([
            'avatar' => $avatarUrl,
        ]);

        return response()->json([
            'status' => 'success',
            'avatar' => $publicAvatarUrl,
            'avatar_url' => $publicAvatarUrl,
        ]);
    }

    private function avatarUrl(Request $request, string $value): string
    {
        $path = parse_url(trim($value), PHP_URL_PATH);
        $fileName = basename(is_string($path) ? $path : '');

        if ($fileName === '') {
            return '';
        }

        return $request->getSchemeAndHttpHost()
            . '/api/users/avatar.php?file='
            . rawurlencode($fileName);
    }
}
