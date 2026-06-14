<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProgressController extends Controller
{
    public function markWord(Request $request)
    {
        $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'topic_id' => 'required|integer|exists:topics,id',
            'vocabulary_id' => 'required|integer|exists:vocabulary,id',
        ]);

        DB::table('learning_progress')->updateOrInsert(
            [
                'user_id' => $request->user_id,
                'vocabulary_id' => $request->vocabulary_id,
            ],
            [
                'topic_id' => $request->topic_id,
                'learned' => 1,
                'remembered' => $request->boolean('remembered'),
                'score' => $request->integer('score'),
                'updated_at' => now(),
            ]
        );

        return response()->json(['status' => 'success']);
    }

    public function topicProgress(Request $request)
    {
        $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'topic_id' => 'required|integer|exists:topics,id',
        ]);

        $rows = DB::table('learning_progress')
            ->where('user_id', $request->user_id)
            ->where('topic_id', $request->topic_id)
            ->get();

        return response()->json([
            'status' => 'success',
            'learned_ids' => $rows->pluck('vocabulary_id'),
            'remembered_ids' => $rows->where('remembered', 1)
                ->pluck('vocabulary_id')->values(),
            'learned_count' => $rows->count(),
            'remembered_count' => $rows->where('remembered', 1)->count(),
        ]);
    }

    public function addDailyStats(Request $request)
    {
        $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'learned_count' => 'nullable|integer|min:0|max:1000',
            'quiz_correct' => 'nullable|integer|min:0|max:1000',
            'study_minutes' => 'nullable|integer|min:0|max:1440',
        ]);

        $date = now()->toDateString();

        $current = DB::table('learning_daily_stats')
            ->where('user_id', $request->user_id)
            ->where('study_date', $date)
            ->first();

        if ($current) {
            DB::table('learning_daily_stats')
                ->where('id', $current->id)
                ->update([
                    'learned_count' => $current->learned_count
                        + $request->integer('learned_count'),
                    'quiz_correct' => $current->quiz_correct
                        + $request->integer('quiz_correct'),
                    'study_minutes' => $current->study_minutes
                        + $request->integer('study_minutes'),
                ]);
        } else {
            DB::table('learning_daily_stats')->insert([
                'user_id' => $request->user_id,
                'study_date' => $date,
                'learned_count' => $request->integer('learned_count'),
                'quiz_correct' => $request->integer('quiz_correct'),
                'study_minutes' => $request->integer('study_minutes'),
            ]);
        }

        return response()->json(['status' => 'success']);
    }

    public function overview(Request $request)
    {
        $request->validate([
            'user_id' => 'required|integer|exists:users,id',
        ]);

        $userId = $request->integer('user_id');
        $user = DB::table('users')->find($userId);
        $topics = $this->topicRows($userId);
        $today = DB::table('learning_daily_stats')
            ->where('user_id', $userId)
            ->where('study_date', now()->toDateString())
            ->first();

        $totalWords = (int) $topics->sum('total');
        $learnedWords = (int) $topics->sum('learned');
        $rememberedWords = (int) $topics->sum('remembered');
        $currentXp = max(
            (int) ($user->xp ?? 0),
            (int) ($user->total_xp ?? 0)
        );
        $level = $this->levelForXp($currentXp);

        return response()->json([
            'status' => 'success',
            'level' => $level,
            'current_xp' => $currentXp,
            'next_level_xp' => $this->nextLevelXp($level),
            'total_words' => $totalWords,
            'learned_words' => $learnedWords,
            'remembered_words' => $rememberedWords,
            'today_learned' => (int) ($today->learned_count ?? 0),
            'today_quiz_correct' => (int) ($today->quiz_correct ?? 0),
            'learning_minutes' => (int) ($today->study_minutes ?? 0),
            'topic_count' => $topics->where('learned', '>', 0)->count(),
            'topics' => $topics,
            'daily_stats' => DB::table('learning_daily_stats')
                ->where('user_id', $userId)
                ->orderByDesc('study_date')
                ->limit(7)
                ->get(),
        ]);
    }

    public function addPoints(Request $request)
    {
        $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'points' => 'required|integer|min:0|max:10000',
        ]);

        $points = $request->integer('points');
        $user = DB::table('users')->find($request->integer('user_id'));
        $oldTotal = max(
            (int) ($user->xp ?? 0),
            (int) ($user->total_xp ?? 0)
        );
        $oldLevel = $this->levelForXp($oldTotal);
        $newTotal = $oldTotal + $points;
        $newLevel = $this->levelForXp($newTotal);

        DB::table('users')->where('id', $user->id)->update([
            'xp' => $newTotal,
            'total_xp' => $newTotal,
        ]);

        return response()->json([
            'status' => 'success',
            'points' => $points,
            'xp' => $newTotal,
            'total_xp' => $newTotal,
            'level' => $newLevel,
            'next_level_xp' => $this->nextLevelXp($newLevel),
            'level_up' => $newLevel > $oldLevel,
        ]);
    }

    public function updateStreak(Request $request)
    {
        $user = DB::table('users')
            ->where('username', $request->username)
            ->first();

        if (!$user) {
            return response()->json(['streak' => 0]);
        }

        $today = now()->toDateString();
        $yesterday = now()->subDay()->toDateString();
        $streak = (int) ($user->streak_count ?? 0);

        if ($user->last_login_date === $yesterday) {
            $streak++;
        } elseif ($user->last_login_date !== $today) {
            $streak = 1;
        }

        DB::table('users')->where('id', $user->id)->update([
            'streak_count' => $streak,
            'last_login_date' => $today,
        ]);

        return response()->json(['status' => 'success', 'streak' => $streak]);
    }

    public function topics(Request $request)
    {
        $request->validate([
            'user_id' => 'required|integer|exists:users,id',
        ]);

        $topics = $this->topicRows($request->integer('user_id'));

        return response()->json([
            'status' => 'success',
            'data' => $topics,
        ]);
    }

    private function topicRows(int $userId)
    {
        return DB::table('topics as t')
            ->leftJoin('vocabulary as v', 'v.topic_id', '=', 't.id')
            ->leftJoin('learning_progress as lp', function ($join) use ($userId) {
                $join->on('lp.vocabulary_id', '=', 'v.id')
                    ->where('lp.user_id', '=', $userId);
            })
            ->select(
                't.id',
                't.title',
                DB::raw('COUNT(DISTINCT v.id) as total'),
                DB::raw('COUNT(DISTINCT lp.vocabulary_id) as learned'),
                DB::raw(
                    'COUNT(DISTINCT CASE WHEN lp.remembered = 1
                    THEN lp.vocabulary_id END) as remembered'
                )
            )
            ->groupBy('t.id', 't.title')
            ->orderBy('t.id')
            ->get();
    }

    private function levelForXp(int $xp): int
    {
        $thresholds = [0, 100, 250, 450, 700, 1000, 1350, 1750, 2200, 2700];
        $level = 1;

        foreach ($thresholds as $index => $threshold) {
            if ($xp >= $threshold) {
                $level = $index + 1;
            }
        }

        return $level;
    }

    private function nextLevelXp(int $level): int
    {
        $thresholds = [0, 100, 250, 450, 700, 1000, 1350, 1750, 2200, 2700];
        return $level < count($thresholds)
            ? $thresholds[$level]
            : $thresholds[array_key_last($thresholds)];
    }

    public function legacyProgress(Request $request)
    {
        $ids = DB::table('user_progress')
            ->where('username', $request->input('username'))
            ->where('status', 'Passed')
            ->pluck('word_id');

        return response()->json($ids);
    }
}
