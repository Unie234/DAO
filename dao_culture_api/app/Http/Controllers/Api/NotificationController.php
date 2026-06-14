<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $request->validate([
            'user_id' => 'required|integer|exists:users,id',
        ]);

        $items = DB::table('notifications')
            ->where('user_id', $request->integer('user_id'))
            ->whereNull('deleted_at')
            ->orderByDesc('created_at')
            ->limit(min(max($request->integer('limit', 20), 1), 100))
            ->get();

        return response()->json([
            'status' => 'success',
            'unread_count' => $items->where('is_read', 0)->count(),
            'notifications' => $items,
        ]);
    }

    public function read(Request $request)
    {
        $updated = DB::table('notifications')
            ->where('id', $request->integer('notification_id'))
            ->where('user_id', $request->integer('user_id'))
            ->update(['is_read' => 1]);

        return response()->json([
            'status' => $updated ? 'success' : 'error',
        ], $updated ? 200 : 404);
    }

    public function destroy(Request $request)
    {
        $updated = DB::table('notifications')
            ->where('id', $request->integer('notification_id'))
            ->where('user_id', $request->integer('user_id'))
            ->update(['deleted_at' => now()]);

        return response()->json([
            'status' => $updated ? 'success' : 'error',
        ], $updated ? 200 : 404);
    }
}
