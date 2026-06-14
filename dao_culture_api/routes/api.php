<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CultureController;
use App\Http\Controllers\Api\LearningController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\ProgressController;
use App\Http\Controllers\Api\PostController;
use App\Http\Controllers\Api\CommentController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\FeedbackController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\StreakRescueController;
use App\Http\Controllers\Api\AiController;

Route::post('ai/chat.php', [AiController::class, 'chat']);
Route::post('ai/assistant.php', [AiController::class, 'assistant']);
Route::post('users/login.php', [AuthController::class, 'login']);
Route::post('users/register.php', [AuthController::class, 'register']);
Route::post('users/upload_avatar.php',[UserController::class, 'uploadAvatar']);
Route::get('users/avatar.php', [UserController::class, 'avatar']);
Route::post(
    'users/request_password_reset.php',
    [AuthController::class, 'requestPasswordReset']
);

Route::post(
    'users/reset_password.php',
    [AuthController::class, 'resetPassword']
);
Route::get('culture_articles/search.php', [CultureController::class, 'search']);

Route::get('admin/users.php', [AdminController::class, 'users']);
Route::post('admin/update_user_status.php', [AdminController::class, 'updateUserStatus']);
Route::post('admin/delete_user.php', [AdminController::class, 'deleteUser']);

Route::get('moderation/reports.php', [AdminController::class, 'reports']);
Route::post('moderation/resolve_report.php', [AdminController::class, 'resolveReport']);

Route::get('topics/list.php', [LearningController::class, 'topics']);
Route::get('vocabulary/by_topic.php', [LearningController::class, 'vocabulary']);
Route::get('vocabulary/search.php', [LearningController::class, 'search']);
Route::get('vocabulary/audio.php', [LearningController::class, 'audio']);

Route::get('culture_articles/list.php', [CultureController::class, 'articles']);
Route::post('culture_articles/increment_view.php', [CultureController::class, 'incrementView']);
Route::get('culture_articles/image.php',[CultureController::class, 'image']);
Route::get('culture_articles/video.php',[CultureController::class, 'video']);
Route::get('culture_articles/share.php',[CultureController::class, 'share']);

Route::get('map_places/list.php', [CultureController::class, 'mapPlaces']);

Route::get('users/profile.php', [UserController::class, 'profile']);
Route::post('users/update_profile.php', [UserController::class, 'updateProfile']);
Route::post('users/change_password.php', [UserController::class, 'changePassword']);


Route::post('progress/mark_learning_word.php', [ProgressController::class, 'markWord']);
Route::get('progress/topic_learning_progress.php', [ProgressController::class, 'topicProgress']);
Route::get('progress/learning_overview.php', [ProgressController::class, 'overview']);
Route::post('progress/add_daily_stats.php', [ProgressController::class, 'addDailyStats']);

Route::post('points/add.php', [ProgressController::class, 'addPoints']);
Route::post('progress/update_streak.php', [ProgressController::class, 'updateStreak']);

Route::get('vocabulary/favorites.php', [LearningController::class, 'favorites']);
Route::post('vocabulary/favorite_toggle.php', [LearningController::class, 'toggleFavorite']);
Route::get('vocabulary/search.php', [LearningController::class, 'search']);

Route::post('topics/add.php', [LearningController::class, 'addTopic']);
Route::post('topics/update.php', [LearningController::class, 'updateTopic']);
Route::post('topics/delete.php', [LearningController::class, 'deleteTopic']);

Route::post('vocabulary/add.php', [LearningController::class, 'addVocabulary']);
Route::post('vocabulary/update.php', [LearningController::class, 'updateVocabulary']);
Route::post('vocabulary/delete.php', [LearningController::class, 'deleteVocabulary']);

Route::get('progress/topics.php', [ProgressController::class, 'topics']);

Route::get('posts/list.php', [PostController::class, 'index']);
Route::get('posts/image.php', [PostController::class, 'image']);
Route::get('posts/video.php', [PostController::class, 'video']);
Route::post('posts/reaction.php', [PostController::class, 'reaction']);
Route::post('posts/save.php', [PostController::class, 'save']);
Route::post('posts/report.php', [PostController::class, 'report']);
Route::post('posts/create.php', [PostController::class, 'store']);
Route::post('posts/delete.php', [PostController::class, 'destroy']);
Route::post('posts/hide.php', [PostController::class, 'hide']);
Route::post('posts/like.php', [PostController::class, 'like']);

Route::get('comments/list.php',[CommentController::class,'index']);
Route::post('comments/add.php',[CommentController::class,'store']);
Route::post('comments/reaction.php',[CommentController::class,'reaction']);
Route::post('comments/delete.php',[CommentController::class,'destroy']);

Route::get('notifications/list.php',[NotificationController::class,'index']);
Route::post('notifications/mark_read.php',[NotificationController::class,'read']);
Route::post('notifications/delete.php',[NotificationController::class,'destroy']);

Route::post('feedbacks/send.php',[FeedbackController::class,'store']);
Route::get('feedbacks/list.php',[FeedbackController::class,'index']);

Route::post('culture_articles/save.php',[CultureController::class, 'saveArticle']);
Route::post('culture_articles/upload_image.php',[CultureController::class, 'uploadArticleImage']);
Route::post('culture_articles/upload_video.php',[CultureController::class, 'uploadArticleVideo']);
Route::post('culture_articles/delete.php',[CultureController::class, 'deleteArticle']);
Route::post('map_places/save.php',[CultureController::class, 'saveMapPlace']);
Route::post('map_places/upload_image.php',[CultureController::class, 'uploadMapImage']);
Route::post('map_places/delete.php',[CultureController::class, 'deleteMapPlace']);

Route::get(
    'progress/get.php',
    [ProgressController::class, 'legacyProgress']
);
Route::get(
    'streak_rescue/check.php',
    [StreakRescueController::class, 'check']
);

Route::post(
    'streak_rescue/complete.php',
    [StreakRescueController::class, 'complete']
);
