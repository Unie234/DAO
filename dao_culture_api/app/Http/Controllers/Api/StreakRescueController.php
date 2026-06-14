<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StreakRescueController extends Controller
{
    public function check(Request $request)
    {
        $userId = $request->integer('user_id');
        $user = DB::table('users')->where('id', $userId)->first();

        if (!$user || !$user->last_login_date) {
            return response()->json([
                'status' => 'success',
                'eligible' => false,
            ]);
        }

        $lastLogin = now()->parse($user->last_login_date)->startOfDay();
        $today = now()->startOfDay();
        $missedDate = $today->copy()->subDay();

        // Chỉ cứu khi bỏ lỡ đúng một ngày.
        if ($lastLogin->diffInDays($today) !== 2) {
            return response()->json([
                'status' => 'success',
                'eligible' => false,
            ]);
        }

        $mission = DB::table('streak_rescue_missions')
            ->where('user_id', $userId)
            ->where('missed_date', $missedDate->toDateString())
            ->first();

        if (!$mission) {
            $id = DB::table('streak_rescue_missions')->insertGetId([
                'user_id' => $userId,
                'missed_date' => $missedDate->toDateString(),
                'rescue_date' => $today->toDateString(),
                'previous_streak' => $user->streak_count ?? 0,
                'mission_type' => 'quiz',
                'required_total' => 5,
                'required_correct' => 4,
                'status' => 'pending',
                'correct_answers' => 0,
                'total_questions' => 0,
                'created_at' => now(),
            ]);

            $mission = DB::table('streak_rescue_missions')->find($id);
        }

        if ($mission->status !== 'pending') {
            return response()->json([
                'status' => 'success',
                'eligible' => false,
            ]);
        }

        return response()->json([
            'status' => 'success',
            'eligible' => true,
            'mission' => $mission,
        ]);
    }

    public function complete(Request $request)
    {
        $userId = $request->integer('user_id');
        $missionId = $request->integer('mission_id');
        $correct = $request->integer('correct_answers');
        $total = $request->integer('total_questions');

        $mission = DB::table('streak_rescue_missions')
            ->where('id', $missionId)
            ->where('user_id', $userId)
            ->where('status', 'pending')
            ->first();

        if (!$mission) {
            return response()->json([
                'status' => 'error',
                'rescued' => false,
                'message' => 'Nhiệm vụ không còn hiệu lực',
            ]);
        }

        $passed = $total >= $mission->required_total
            && $correct >= $mission->required_correct;

        DB::transaction(function () use (
            $mission,
            $userId,
            $correct,
            $total,
            $passed
        ) {
            DB::table('streak_rescue_missions')
                ->where('id', $mission->id)
                ->update([
                    'status' => $passed ? 'completed' : 'failed',
                    'correct_answers' => $correct,
                    'total_questions' => $total,
                    'completed_at' => now(),
                ]);

            if ($passed) {
                DB::table('users')->where('id', $userId)->update([
                    'streak_count' => $mission->previous_streak,
                    'last_login_date' => now()->toDateString(),
                ]);
            }
        });

        return response()->json([
            'status' => 'success',
            'rescued' => $passed,
            'streak' => $passed ? $mission->previous_streak : 0,
        ]);
    }
}