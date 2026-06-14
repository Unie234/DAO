<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FeedbackController extends Controller
{
    public function store(Request $r) {
        DB::table('feedbacks')->insert([
            'user_id'=>$r->input('user_id'), 'user_name'=>$r->input('user_name'),
            'content'=>$r->input('content'), 'created_at'=>now()
        ]);
        return response()->json(['status'=>'success']);
    }

    public function index() {
        return response()->json(
            DB::table('feedbacks')->orderByDesc('created_at')->get()
        );
    }
}