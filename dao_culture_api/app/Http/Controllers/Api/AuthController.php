<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Throwable;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $user = User::where('username', $request->username)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            Log::warning('Failed login attempt for username: ' . $request->username);
            return response()->json([
                'status' => 'error',
                'message' => 'Sai tài khoản hoặc mật khẩu!',
            ]);
        }

        if ($user->is_locked) {
            Log::warning('Attempt to login with locked account: ' . $request->username);
            return response()->json([
                'status' => 'error',
                'message' => 'Tài khoản đã bị khóa!',
            ]);
        }

        // $user->update(['last_login_date' => now()->toDateString()]);

        return response()->json([
            'status' => 'success',
            'user_id' => $user->id,
            'username' => $user->username,
            'full_name' => $user->full_name,
            'role' => $user->role,
            'streak_count' => $user->streak_count ?? 0,
        ]);
    }

    public function register(Request $request)
    {
        $request->validate([
            'username' => 'required|email|unique:users,username',
            'password' => 'required|min:8',
        ]);

        User::create([
            'username' => $request->username,
            'password' => Hash::make($request->password),
            'full_name' => $request->full_name ?: 'Thành viên mới',
            'role' => 'user',
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Đăng ký thành công!',
        ]);
    }

    public function requestPasswordReset(Request $request)
{
    $email = trim((string) $request->input('email'));

    $user = DB::table('users')
        ->where('username', $email)
        ->first();

    if (!$user) {
        return response()->json([
            'status' => 'error',
            'message' => 'Email chưa được đăng ký',
        ]);
    }

    $otp = (string) random_int(100000, 999999);

    DB::table('password_resets')
        ->where('email', $email)
        ->whereNull('used_at')
        ->update(['used_at' => now()]);

    DB::table('password_resets')->insert([
        'user_id' => $user->id,
        'email' => $email,
        'otp_hash' => Hash::make($otp),
        'expires_at' => now()->addMinutes(10),
        'used_at' => null,
        'created_at' => now(),
    ]);

    if (config('mail.default') === 'log' ||
        blank(config('mail.mailers.smtp.username')) ||
        blank(config('mail.mailers.smtp.password'))) {
        DB::table('password_resets')
            ->where('email', $email)
            ->whereNull('used_at')
            ->update(['used_at' => now()]);

        return response()->json([
            'status' => 'error',
            'message' => 'Máy chủ chưa cấu hình Gmail SMTP.',
        ], 503);
    }

    try {
        Mail::raw(
            "Mã OTP đặt lại mật khẩu của bạn là: {$otp}\n"
            ."Mã có hiệu lực trong 10 phút.",
            function ($message) use ($email) {
                $message
                    ->to($email)
                    ->subject('Mã OTP đặt lại mật khẩu - Dao Culture');
            }
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Mã OTP đã được gửi tới email của bạn.',
        ]);
    } catch (Throwable $exception) {
        DB::table('password_resets')
            ->where('email', $email)
            ->whereNull('used_at')
            ->update(['used_at' => now()]);
        Log::error('Không gửi được OTP', [
            'email' => $email,
            'error' => $exception->getMessage(),
        ]);

        return response()->json([
            'status' => 'error',
            'message' => 'Không gửi được OTP. Kiểm tra cấu hình Gmail.',
        ], 502);
    }
}

public function resetPassword(Request $request)
{
    $email = trim((string) $request->input('email'));
    $otp = trim((string) $request->input('otp'));
    $newPassword = (string) $request->input('new_password');

    $reset = DB::table('password_resets')
        ->where('email', $email)
        ->whereNull('used_at')
        ->where('expires_at', '>', now())
        ->orderByDesc('id')
        ->first();

    if (!$reset || !Hash::check($otp, $reset->otp_hash)) {
        return response()->json([
            'status' => 'error',
            'message' => 'Mã xác nhận sai hoặc đã hết hạn',
        ]);
    }

    DB::transaction(function () use ($email, $newPassword, $reset) {
        DB::table('users')
            ->where('username', $email)
            ->update(['password' => Hash::make($newPassword)]);

        DB::table('password_resets')
            ->where('id', $reset->id)
            ->update(['used_at' => now()]);
    });

    return response()->json([
        'status' => 'success',
        'message' => 'Đặt lại mật khẩu thành công',
    ]);
}
}
