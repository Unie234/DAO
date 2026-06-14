<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class LearningController extends Controller
{
    public function topics()
    {
        return response()->json(DB::table('topics')->orderBy('id')->get());
    }

    public function vocabulary(Request $request)
    {
        return response()->json(
            DB::table('vocabulary')
                ->where('topic_id', $request->topic_id)
                ->orderBy('id')
                ->get()
        );
    }

    public function audio(Request $request)
    {
        $requested = basename((string) $request->query('file'));
        if ($requested === '') {
            return response()->json([
                'status' => 'error',
                'message' => 'Thiếu tên file âm thanh.',
            ], 400);
        }

        $baseName = pathinfo($requested, PATHINFO_FILENAME);
        $extension = strtolower(pathinfo($requested, PATHINFO_EXTENSION));
        $candidates = array_values(array_unique(array_filter([
            "audio/{$requested}",
            "audio_mp3/{$requested}",
            $extension !== 'aac' ? "audio/{$baseName}.aac" : null,
            $extension !== 'mp3' ? "audio_mp3/{$baseName}.mp3" : null,
        ])));

        foreach ($candidates as $path) {
            if (!Storage::disk('public')->exists($path)) {
                continue;
            }

            return response()->file(
                storage_path("app/public/{$path}"),
                [
                    'Content-Type' => $this->audioContentType($path),
                    'Access-Control-Allow-Origin' => '*',
                    'Cross-Origin-Resource-Policy' => 'cross-origin',
                    'Accept-Ranges' => 'bytes',
                    'Cache-Control' => 'public, max-age=86400',
                ]
            );
        }

        return response()->json([
            'status' => 'error',
            'message' => 'Không tìm thấy file âm thanh.',
        ], 404);
    }

    public function search(Request $request)
    {
        $keyword = trim((string) $request->keyword);
        if ($keyword === '') {
            return response()->json(['status' => 'error']);
        }

        $word = DB::table('vocabulary')
            ->where(function ($query) use ($keyword) {
                $query->where('viet_word', 'like', "%{$keyword}%")
                    ->orWhere('dao_word', 'like', "%{$keyword}%");
            })
            ->orderByRaw(
                'CASE
                    WHEN viet_word = ? THEN 0
                    WHEN dao_word = ? THEN 1
                    WHEN viet_word LIKE ? THEN 2
                    WHEN dao_word LIKE ? THEN 3
                    ELSE 4
                END',
                [$keyword, $keyword, "{$keyword}%", "{$keyword}%"]
            )
            ->orderBy('id')
            ->first();

        if (!$word) {
            return response()->json(['status' => 'error']);
        }

        return response()->json([
            'status' => 'success',
            'id' => $word->id,
            'vietnamese' => $word->viet_word,
            'dao' => $word->dao_word,
            'audio_file' => $word->audio_file,
        ]);
    }

    private function audioContentType(string $path): string
    {
        return match (strtolower(pathinfo($path, PATHINFO_EXTENSION))) {
            'aac' => 'audio/aac',
            'm4a' => 'audio/mp4',
            'wav' => 'audio/wav',
            default => 'audio/mpeg',
        };
    }

    public function favorites(Request $request)
    {
        return response()->json([
            'status' => 'success',
            'data' => DB::table('dictionary_favorites')
                ->where('user_id', $request->user_id)
                ->orderByDesc('created_at')
                ->get(),
        ]);
    }

    public function toggleFavorite(Request $request)
    {
        $key = [
            'user_id' => $request->user_id,
            'vocabulary_id' => $request->vocabulary_id,
        ];

        if ($request->boolean('favorite')) {
            DB::table('dictionary_favorites')->updateOrInsert($key, [
                'vietnamese_word' => $request->vietnamese_word,
                'dao_word' => $request->dao_word,
            ]);
        } else {
            DB::table('dictionary_favorites')->where($key)->delete();
        }

        return response()->json(['status' => 'success']);
    }

    public function addTopic(Request $request)
    {
        $request->validate(['title' => 'required|string|max:255']);

        $id = DB::table('topics')->insertGetId([
            'title' => $request->title,
        ]);

        return response()->json(['status' => 'success', 'id' => $id]);
    }

    public function updateTopic(Request $request)
    {
        DB::table('topics')->where('id', $request->id)->update([
            'title' => $request->title,
        ]);

        return response()->json(['status' => 'success']);
    }

    public function deleteTopic(Request $request)
    {
        DB::transaction(function () use ($request) {
            DB::table('vocabulary')->where('topic_id', $request->id)->delete();
            DB::table('topics')->where('id', $request->id)->delete();
        });

        return response()->json(['status' => 'success']);
    }

    public function addVocabulary(Request $request)
    {
        $topic = DB::table('topics')->find($request->topic_id);

        $id = DB::table('vocabulary')->insertGetId([
            'topic_id' => $request->topic_id,
            'topic_title' => $topic?->title,
            'dao_word' => $request->dao_word,
            'viet_word' => $request->viet_word,
            'audio_file' => $request->audio_file ?? '',
        ]);

        return response()->json(['status' => 'success', 'id' => $id]);
    }

    public function updateVocabulary(Request $request)
    {
        $topic = DB::table('topics')->find($request->topic_id);

        DB::table('vocabulary')->where('id', $request->id)->update([
            'topic_id' => $request->topic_id,
            'topic_title' => $topic?->title,
            'dao_word' => $request->dao_word,
            'viet_word' => $request->viet_word,
            'audio_file' => $request->audio_file ?? '',
        ]);

        return response()->json(['status' => 'success']);
    }

    public function deleteVocabulary(Request $request)
    {
        DB::table('vocabulary')->where('id', $request->id)->delete();

        return response()->json(['status' => 'success']);
    }
}
