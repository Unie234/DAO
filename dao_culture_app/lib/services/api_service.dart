import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// ignore: duplicate_import
import 'package:flutter/foundation.dart';
// ignore: unused_import
import 'package:image_picker/image_picker.dart';

import '../app_config.dart';
import '../models/app_notification.dart';

class Topic {
  final String id;
  final String title;

  Topic({required this.id, required this.title});

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(id: json['id'].toString(), title: json['title']);
  }
}

class ApiService {
  static const String baseUrl = AppConfig.baseUrl;

  static Map<String, dynamic>? _decodeMapResponse(String body, String label) {
    try {
      String cleanBody = body.trim();
      if (cleanBody.startsWith('\uFEFF')) {
        cleanBody = cleanBody.substring(1);
      }
      if (cleanBody.startsWith('\xEF\xBB\xBF')) {
        cleanBody = cleanBody.substring(3);
      }
      if (!cleanBody.startsWith('{')) {
        debugPrint("$label không trả JSON object: $cleanBody");
        return null;
      }
      return json.decode(cleanBody) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Lỗi đọc JSON $label: $e");
      debugPrint("Body $label: $body");
      return null;
    }
  }

  static List<dynamic>? _decodeListResponse(String body, String label) {
    try {
      String cleanBody = body.trim();
      if (cleanBody.startsWith('\uFEFF')) {
        cleanBody = cleanBody.substring(1);
      }
      if (cleanBody.startsWith('\xEF\xBB\xBF')) {
        cleanBody = cleanBody.substring(3);
      }
      if (!cleanBody.startsWith('[')) {
        debugPrint("$label không trả JSON list: $cleanBody");
        return null;
      }
      return json.decode(cleanBody) as List<dynamic>;
    } catch (e) {
      debugPrint("Lỗi đọc JSON $label: $e");
      debugPrint("Body $label: $body");
      return null;
    }
  }

  // HÀM LẤY DANH SÁCH CHỦ ĐỀ

  static Future<List<Topic>> getTopics() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/topics/list.php'));
      if (response.statusCode == 200) {
        final jsonResponse = _decodeListResponse(response.body, 'getTopics');
        if (jsonResponse == null) return [];
        return jsonResponse
            .whereType<Map<String, dynamic>>()
            .map((data) => Topic.fromJson(data))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Lỗi kết nối getTopics: $e");
      return [];
    }
  }

  // HÀM LẤY TỪ VỰNG
  static Future<List<dynamic>> getVocabularyByTopic(int topicId) async {
    try {
      final String url = '$baseUrl/vocabulary/by_topic.php?topic_id=$topicId';
      debugPrint("👀 ĐANG GỌI API: $url");

      final response = await http.get(Uri.parse(url));
      debugPrint("📦 DỮ LIỆU TRẢ VỀ: ${response.body}");

      if (response.statusCode == 200) {
        return _decodeListResponse(response.body, 'getVocabularyByTopic') ?? [];
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("❌ LỖI TRUY VẤN: $e");
      return [];
    }
  }

  // ĐĂNG KÝ

  static Future<Map<String, dynamic>> register(
    String username,
    String password,
    String fullName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register.php'),
        body: {
          'username': username,
          'password': password,
          'full_name': fullName,
        },
      );
      final data = _decodeMapResponse(response.body, 'register');
      return data ??
          {"status": "error", "message": "Dữ liệu đăng ký không hợp lệ!"};
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối!"};
    }
  }

  //  HÀM ĐĂNG NHẬP
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/login.php'),
            body: {'username': username, 'password': password},
          )
          .timeout(const Duration(seconds: 12));

      debugPrint("=== DỮ LIỆU LOGIN XAMPP TRẢ VỀ ===");
      debugPrint(response.body);

      final data = _decodeMapResponse(response.body, 'login');
      return data ??
          {"status": "error", "message": "Dữ liệu đăng nhập không hợp lệ!"};
    } catch (e) {
      debugPrint("Lỗi kết nối login: $e");
      return {
        "status": "error",
        "message": "Không kết nối được máy chủ. Kiểm tra Wi-Fi/IP XAMPP nhé!",
      };
    }
  }

  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/request_password_reset.php'),
            body: {'email': email},
          )
          .timeout(const Duration(seconds: 20));

      final data = _decodeMapResponse(response.body, 'requestPasswordReset');
      return data ??
          {"status": "error", "message": "Dữ liệu gửi mã không hợp lệ!"};
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối khi gửi mã!"};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/reset_password.php'),
            body: {'email': email, 'otp': otp, 'new_password': newPassword},
          )
          .timeout(const Duration(seconds: 20));

      final data = _decodeMapResponse(response.body, 'resetPassword');
      return data ??
          {
            "status": "error",
            "message": "Dữ liệu đặt lại mật khẩu không hợp lệ!",
          };
    } catch (e) {
      return {
        "status": "error",
        "message": "Lỗi kết nối khi đặt lại mật khẩu!",
      };
    }
  }

  //  HÀM LẤY TIẾN ĐỘ
  static Future<List<int>> getUserProgress(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/progress/get.php?username=$username'),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((id) => int.parse(id.toString())).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> markLearningWord({
    required String userId,
    required int topicId,
    required int vocabularyId,
    required bool remembered,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/progress/mark_learning_word.php'),
            body: {
              'user_id': userId,
              'topic_id': topicId.toString(),
              'vocabulary_id': vocabularyId.toString(),
              'remembered': remembered ? '1' : '0',
              'score': remembered ? '1' : '0',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'markLearningWord');
        return data != null && data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("Lỗi markLearningWord: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getTopicLearningProgress({
    required String userId,
    required int topicId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/progress/topic_learning_progress.php?user_id=$userId&topic_id=$topicId',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _decodeMapResponse(
          response.body,
          'getTopicLearningProgress',
        );
        if (data != null && data['status'] == 'success') return data;
      }
      return null;
    } catch (e) {
      debugPrint("Lỗi getTopicLearningProgress: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getLearningOverview(
    String userId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/progress/learning_overview.php?user_id=$userId',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'getLearningOverview');
        if (data != null && data['status'] == 'success') return data;
      }
      return null;
    } catch (e) {
      debugPrint("Lỗi getLearningOverview: $e");
      return null;
    }
  }

  static Future<bool> addLearningDailyStats({
    required String userId,
    int learnedCount = 0,
    int quizCorrect = 0,
    int studyMinutes = 0,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/progress/add_daily_stats.php'),
            body: {
              'user_id': userId,
              'learned_count': learnedCount.toString(),
              'quiz_correct': quizCorrect.toString(),
              'study_minutes': studyMinutes.toString(),
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'addLearningDailyStats');
        return data != null && data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("Lỗi addLearningDailyStats: $e");
      return false;
    }
  }

  static Future<String> getStreak(String username) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/progress/update_streak.php'),
        body: {'username': username},
      );

      if (response.statusCode == 200) {
        String cleanBody = response.body.trim();
        if (cleanBody.startsWith('\xEF\xBB\xBF')) {
          cleanBody = cleanBody.substring(3);
        }

        Map<String, dynamic> data = json.decode(cleanBody);

        if (data.containsKey('streak')) {
          return data['streak'].toString();
        }
      }
      return "0";
    } catch (e) {
      debugPrint("Lỗi kết nối getStreak: $e");
      return "0";
    }
  }

  // CÁC HÀM CHO GÓC SẺ CHIA

  static Future<List<dynamic>> getPosts([
    String userId = "",
    String postId = "",
  ]) async {
    try {
      final uri = Uri.parse('$baseUrl/posts/list.php').replace(
        queryParameters: {
          if (userId.trim().isNotEmpty) 'user_id': userId.trim(),
          if (postId.trim().isNotEmpty) 'post_id': postId.trim(),
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final cleanBody = response.body
            .trim()
            .replaceFirst(RegExp(r'^\uFEFF'), '')
            .replaceFirst(RegExp(r'^\xEF\xBB\xBF'), '');
        var jsonData = jsonDecode(cleanBody);

        if (jsonData is Map<String, dynamic>) {
          if (jsonData['status'] == 'success') {
            return jsonData['data'] as List<dynamic>;
          } else {
            throw Exception(jsonData['message']);
          }
        } else if (jsonData is List) {
          return jsonData;
        }
        return [];
      } else {
        throw Exception("Lỗi kết nối Server: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi lấy bài viết: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getPopularPosts({int limit = 1}) async {
    try {
      final uri = Uri.parse('$baseUrl/posts/list.php').replace(
        queryParameters: {'sort': 'popular', 'limit': limit.toString()},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];

      final data = _decodeMapResponse(response.body, 'getPopularPosts');
      final posts = data?['data'];
      return posts is List ? posts : [];
    } catch (e) {
      debugPrint("Lỗi lấy bài cộng đồng nổi bật: $e");
      return [];
    }
  }

  static String vocabularyAudioUrl(String audioFile) {
    final value = audioFile.trim().replaceAll('\\', '/');
    if (value.isEmpty) return '';
    final fileName = value.split('/').last;
    return '$baseUrl/vocabulary/audio.php'
        '?file=${Uri.encodeComponent(fileName)}';
  }

  static Future<List<AppNotification>> getNotifications({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/notifications/list.php?user_id=$userId&limit=$limit',
            ),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'getNotifications');
        final items = data?['notifications'];
        if (items is List) {
          return items
              .whereType<Map<String, dynamic>>()
              .map(AppNotification.fromJson)
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Lỗi getNotifications: $e");
      return [];
    }
  }

  static Future<bool> markNotificationRead({
    required String userId,
    required String notificationId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/notifications/mark_read.php'),
            body: {'user_id': userId, 'notification_id': notificationId},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'markNotificationRead');
        return data != null && data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("Lỗi markNotificationRead: $e");
      return false;
    }
  }

  static Future<bool> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/notifications/delete.php'),
            body: {'user_id': userId, 'notification_id': notificationId},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'deleteNotification');
        return data != null && data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("Lỗi deleteNotification: $e");
      return false;
    }
  }

  static Future<bool> createPost(Map<String, dynamic> postData) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/posts/create.php'),
            headers: {"Content-Type": "application/json"},
            body: json.encode(postData),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        debugPrint("createPost response: ${response.body}");
        final result = json.decode(response.body);
        return result['status'] == 'success';
      }
      debugPrint("createPost HTTP ${response.statusCode}: ${response.body}");
      return false;
    } catch (e) {
      debugPrint("Lỗi tạo bài viết: $e");
      return false;
    }
  }

  static Future<bool> deletePost(
    String postId, {
    String userId = '',
    bool isAdmin = false,
  }) async {
    try {
      var adminUserId = '';
      if (isAdmin) {
        final prefs = await SharedPreferences.getInstance();
        adminUserId = prefs.getString('user_id')?.trim() ?? '';
      }
      final response = await http.post(
        Uri.parse('$baseUrl/posts/delete.php'),
        body: {
          'post_id': postId,
          'user_id': userId,
          'is_admin': isAdmin ? '1' : '0',
          if (isAdmin) 'admin_user_id': adminUserId,
        },
      );
      if (response.statusCode != 200) return false;
      final result = _decodeMapResponse(response.body, "deletePost");
      return result != null && result['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  static Future<bool> toggleLike(String postId, String userId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/posts/like.php'),
            headers: {"Content-Type": "application/json"},
            body: json.encode({'post_id': postId, 'user_id': userId}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        String cleanBody = response.body.trim();
        if (cleanBody.startsWith('\xEF\xBB\xBF')) {
          cleanBody = cleanBody.substring(3);
        }
        final result = json.decode(cleanBody);
        return result['status'] == 'liked' || result['status'] == 'unliked';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> togglePostReaction(
    String postId,
    String userId,
    String reaction,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/posts/reaction.php'),
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              'post_id': postId,
              'user_id': userId,
              'reaction': reaction,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final result = _decodeMapResponse(response.body, "reaction");
        return result != null && result['status'] != 'error';
      }
      return false;
    } catch (e) {
      debugPrint("Lỗi khi thả cảm xúc: $e");
      return false;
    }
  }

  static Future<bool> toggleSavePost(String postId, String userId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/posts/save.php'),
            headers: {"Content-Type": "application/json"},
            body: json.encode({'post_id': postId, 'user_id': userId}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final result = _decodeMapResponse(response.body, "toggleSavePost");
        return result != null && result['status'] != 'error';
      }
      return false;
    } catch (e) {
      debugPrint("Lỗi lưu bài viết: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getComments(
    String postId, {
    String userId = '',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comments/list.php?post_id=$postId&user_id=$userId'),
      );
      if (response.statusCode == 200) {
        return _decodeListResponse(response.body, 'getComments') ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> toggleCommentReaction(
    String commentId,
    String userId,
    String reaction,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/comments/reaction.php'),
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              'comment_id': commentId,
              'user_id': userId,
              'reaction': reaction,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final result = _decodeMapResponse(response.body, "commentReaction");
        return result != null && result['status'] != 'error';
      }
      return false;
    } catch (e) {
      debugPrint("Lỗi thả cảm xúc bình luận: $e");
      return false;
    }
  }

  //  HÀM BÌNH LUẬN ĐÃ ĐƯỢC HỢP NHẤT
  static Future<bool> addComment(
    String postId,
    String userId,
    String content, {
    String? parentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comments/add.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'post_id': postId,
          'user_id': userId,
          'content': content,
          if (parentId != null && parentId.isNotEmpty) 'parent_id': parentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("Lỗi khi thêm bình luận: $e");
      return false;
    }
  }

  static Future<bool> reportPost(
    String postId,
    String userId,
    String reason,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/posts/report.php'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'post_id': postId.trim(),
              'user_id': userId.trim(),
              'reason': reason.trim(),
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        debugPrint("reportPost HTTP ${response.statusCode}: ${response.body}");
        return false;
      }
      final data = _decodeMapResponse(response.body, 'reportPost');
      return data != null && data['status'] == 'success';
    } catch (e) {
      debugPrint("Lỗi reportPost: $e");
      return false;
    }
  }

  static Future<bool> sendFeedback(
    String userId,
    String userName,
    String content,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/feedbacks/send.php'),
        body: {'user_id': userId, 'user_name': userName, 'content': content},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> addPointsResult(
    String userId,
    int points,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/points/add.php'),
            body: {'user_id': userId, 'points': points.toString()},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return _decodeMapResponse(response.body, 'addPoints') ??
            {"status": "error", "message": "Dữ liệu cộng điểm không hợp lệ"};
      }
      return {
        "status": "error",
        "message": "Lỗi server ${response.statusCode}",
      };
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối cộng điểm"};
    }
  }

  static Future<bool> addPoints(String userId, int points) async {
    final result = await addPointsResult(userId, points);
    return result['status'] == 'success';
  }

  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/users/profile.php?user_id=$userId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'getUserProfile');
        return data ??
            {"status": "error", "message": "Dữ liệu hồ sơ không hợp lệ"};
      }
      return {"status": "error", "message": "Không tải được hồ sơ"};
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối hồ sơ"};
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required String fullName,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/update_profile.php'),
            body: {'user_id': userId, 'full_name': fullName},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'updateUserProfile');
        return data ?? {"status": "error", "message": "Dữ liệu không hợp lệ"};
      }
      return {
        "status": "error",
        "message": "Lỗi server ${response.statusCode}",
      };
    } catch (e) {
      debugPrint("Lỗi updateUserProfile: $e");
      return {"status": "error", "message": "Lỗi kết nối"};
    }
  }

  static Future<Map<String, dynamic>> uploadAvatar(
    String userId,
    XFile file,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/upload_avatar.php'),
      );

      request.fields['user_id'] = userId;

      if (kIsWeb) {
        final bytes = await file.readAsBytes();

        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            bytes,
            filename: file.name.isNotEmpty ? file.name : 'avatar.jpg',
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'avatar',
            file.path,
            filename: file.name,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return data;
      }

      return {
        'status': 'error',
        'message': data['message'] ?? 'Không tải được ảnh',
      };
    } catch (e) {
      debugPrint('Lỗi uploadAvatar: $e');

      return {'status': 'error', 'message': 'Lỗi tải ảnh: $e'};
    }
  }

  static Future<Map<String, dynamic>> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/change_password.php'),
            body: {
              'user_id': userId,
              'old_password': oldPassword,
              'new_password': newPassword,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        String cleanBody = response.body.trim();
        if (cleanBody.startsWith('\xEF\xBB\xBF')) {
          cleanBody = cleanBody.substring(3);
        }
        return json.decode(cleanBody);
      }
      return {"status": "error", "message": "Không đổi được mật khẩu"};
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối đổi mật khẩu"};
    }
  }

  static Future<List<dynamic>> getFeedbacks() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/feedbacks/list.php'));
      if (response.statusCode == 200) {
        String cleanBody = response.body.trim();
        if (cleanBody.startsWith('\xEF\xBB\xBF')) {
          cleanBody = cleanBody.substring(3);
        }
        return json.decode(cleanBody);
      }
      return [];
    } catch (e) {
      debugPrint("Lỗi lấy góp ý: $e");
      return [];
    }
  }

  // CÁC HÀM DÀNH CHO ADMIN DASHBOARD

  static Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/users.php'));
      if (response.statusCode == 200) {
        final data = _decodeListResponse(response.body, 'getUsers');
        if (data != null) return data;

        final mapData = _decodeMapResponse(response.body, 'getUsers');
        if (mapData != null && mapData['data'] is List) {
          return mapData['data'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> setUserLocked({
    required String userId,
    required bool locked,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/update_user_status.php'),
            body: {'user_id': userId, 'is_locked': locked ? '1' : '0'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'setUserLocked');
        return data ??
            {
              "status": "error",
              "message": "Dữ liệu cập nhật trạng thái không hợp lệ",
            };
      }
      return {
        "status": "error",
        "message": "Server trả lỗi ${response.statusCode}",
      };
    } catch (e) {
      debugPrint("Lỗi setUserLocked: $e");
      return {"status": "error", "message": "Lỗi kết nối khi cập nhật"};
    }
  }

  static Future<List<dynamic>> getReports() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/moderation/reports.php'),
      );
      if (response.statusCode == 200) {
        String cleanBody = response.body.trim();
        if (cleanBody.startsWith('\xEF\xBB\xBF')) {
          cleanBody = cleanBody.substring(3);
        }
        return json.decode(cleanBody);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> hidePost(String postId, {int banDays = 0}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/posts/hide.php'),
            body: {'post_id': postId, 'ban_days': banDays.toString()},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'hidePost');
        return data != null && data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("Lỗi hidePost: $e");
      return false;
    }
  }

  static Future<bool> resolveReport(String reportId, String status) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/moderation/resolve_report.php'),
            body: {'report_id': reportId, 'status': status},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'resolveReport');
        return data != null && data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("Lỗi resolveReport: $e");
      return false;
    }
  }

  static Future<bool> deleteUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/delete_user.php'),
        body: {'user_id': userId},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> addTopic(String title) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/topics/add.php'), body: {'title': title})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'addTopic');
        return data != null && data['status'] == 'success';
      }
      debugPrint("addTopic HTTP ${response.statusCode}: ${response.body}");
      return false;
    } catch (e) {
      debugPrint("Lỗi addTopic: $e");
      return false;
    }
  }

  static Future<bool> updateTopic(String id, String title) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/topics/update.php'),
            body: {'id': id, 'title': title},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'updateTopic');
        return data != null && data['status'] == 'success';
      }
      debugPrint("updateTopic HTTP ${response.statusCode}: ${response.body}");
      return false;
    } catch (e) {
      debugPrint("Lỗi updateTopic: $e");
      return false;
    }
  }

  static Future<bool> deleteTopic(String id) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/topics/delete.php'), body: {'id': id})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'deleteTopic');
        return data != null && data['status'] == 'success';
      }
      debugPrint("deleteTopic HTTP ${response.statusCode}: ${response.body}");
      return false;
    } catch (e) {
      debugPrint("Lỗi deleteTopic: $e");
      return false;
    }
  }

  static Future<bool> addVocabulary({
    required String topicId,
    required String daoWord,
    required String vietWord,
    required String audioFile,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/vocabulary/add.php'),
            body: {
              'topic_id': topicId,
              'dao_word': daoWord,
              'viet_word': vietWord,
              'audio_file': audioFile,
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'addVocabulary');
        return data != null && data['status'] == 'success';
      }
      debugPrint("addVocabulary HTTP ${response.statusCode}: ${response.body}");
      return false;
    } catch (e) {
      debugPrint("Lỗi addVocabulary: $e");
      return false;
    }
  }

  static Future<bool> updateVocabulary({
    required String id,
    required String topicId,
    required String daoWord,
    required String vietWord,
    required String audioFile,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/vocabulary/update.php'),
            body: {
              'id': id,
              'topic_id': topicId,
              'dao_word': daoWord,
              'viet_word': vietWord,
              'audio_file': audioFile,
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'updateVocabulary');
        return data != null && data['status'] == 'success';
      }
      debugPrint(
        "updateVocabulary HTTP ${response.statusCode}: ${response.body}",
      );
      return false;
    } catch (e) {
      debugPrint("Lỗi updateVocabulary: $e");
      return false;
    }
  }

  static Future<bool> deleteVocabulary(String id) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/vocabulary/delete.php'), body: {'id': id})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = _decodeMapResponse(response.body, 'deleteVocabulary');
        return data != null && data['status'] == 'success';
      }
      debugPrint(
        "deleteVocabulary HTTP ${response.statusCode}: ${response.body}",
      );
      return false;
    } catch (e) {
      debugPrint("Lỗi deleteVocabulary: $e");
      return false;
    }
  }

  // 🟢 HÀM "BỘ NÃO" GEMINI AI (MỚI THÊM)
  static Future<String> chatWithDaoAssistant(String userMessage) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/ai/chat.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': userMessage}),
          )
          .timeout(const Duration(seconds: 40));

      final data = _decodeMapResponse(response.body, 'chatWithDaoAssistant');
      if (response.statusCode == 200 && data?['status'] == 'success') {
        return (data?['text'] ?? '').toString();
      }

      final message = data?['message']?.toString().trim() ?? '';
      debugPrint("Lỗi Gemini backend ${response.statusCode}: ${response.body}");
      return message.isNotEmpty
          ? message
          : "Không thể kết nối với trợ lý AI lúc này.";
    } catch (e) {
      debugPrint("Lỗi chatWithDaoAssistant: $e");
      return "Không kết nối được với máy chủ trợ lý AI.";
    }
  }

  static Future<Map<String, dynamic>> askDaoCultureAssistant({
    required String message,
    String context = '',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/ai/assistant.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message, 'context': context}),
          )
          .timeout(const Duration(seconds: 75));
      final data = _decodeMapResponse(response.body, 'askDaoCultureAssistant');
      if (data != null) return data;
      return {
        'status': 'error',
        'message': 'Trợ lý AI trả về dữ liệu không hợp lệ.',
      };
    } catch (e) {
      debugPrint("Lỗi askDaoCultureAssistant: $e");
      return {
        'status': 'error',
        'message':
            'Không kết nối được với trợ lý AI. Vui lòng kiểm tra mạng và thử lại.',
      };
    }
  }

  static Future<String?> transcribeDaoAssistantAudio(String audioPath) async {
    const String apiKey = AppConfig.geminiApiKey;
    final audioFile = File(audioPath);
    if (!await audioFile.exists()) return null;

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    final requestBody = {
      "contents": [
        {
          "parts": [
            {
              "text":
                  "Hãy nghe file âm thanh này và chép lại nguyên văn lời người dùng bằng tiếng Việt. Chỉ trả về câu người dùng đã nói, không giải thích.",
            },
            {
              "inline_data": {
                "mime_type": "audio/mp4",
                "data": base64Encode(await audioFile.readAsBytes()),
              },
            },
          ],
        },
      ],
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 35));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
            ?.toString()
            .trim();
        if (text == null || text.isEmpty) return null;
        return text;
      }

      debugPrint("Lỗi nhận dạng giọng nói Gemini: ${response.body}");
      return null;
    } catch (e) {
      debugPrint("Lỗi transcribeDaoAssistantAudio: $e");
      return null;
    }
  }

  // Hàm tra cứu từ vựng tiếng Dao
  static Future<Map<String, String>?> searchWord(String keyword) async {
    try {
      final encodedKeyword = Uri.encodeComponent(keyword);
      final response = await http
          .get(
            Uri.parse('$baseUrl/vocabulary/search.php?keyword=$encodedKeyword'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        String cleanBody = response.body.trim();
        if (cleanBody.startsWith('\xEF\xBB\xBF')) {
          cleanBody = cleanBody.substring(3);
        }

        if (!cleanBody.startsWith('{')) {
          debugPrint("API từ điển không trả JSON: $cleanBody");
          return null;
        }

        final data = json.decode(cleanBody);
        if (data['status'] == 'success') {
          return {
            "id": data['id']?.toString() ?? "",
            "vietnamese": data['vietnamese'].toString(),
            "dao": data['dao'].toString(),
            "audio_file": data['audio_file']?.toString() ?? "",
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint("Lỗi tìm từ vựng: $e");
      return null;
    }
  }

  static Future<List<Map<String, String>>> getDictionaryFavorites(
    String userId,
  ) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/vocabulary/favorites.php?user_id=$userId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _decodeMapResponse(
          response.body,
          'getDictionaryFavorites',
        );
        if (data != null &&
            data['status'] == 'success' &&
            data['data'] is List) {
          return (data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map(
                (item) => {
                  "id": item['vocabulary_id']?.toString() ?? "",
                  "vietnamese": item['vietnamese_word']?.toString() ?? "",
                  "dao": item['dao_word']?.toString() ?? "",
                },
              )
              .where(
                (item) =>
                    item["vietnamese"]!.isNotEmpty && item["dao"]!.isNotEmpty,
              )
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Lỗi getDictionaryFavorites: $e");
      return [];
    }
  }

  static Future<bool> toggleDictionaryFavorite({
    required String userId,
    required Map<String, String> word,
    required bool favorite,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/vocabulary/favorite_toggle.php'),
            body: {
              'user_id': userId,
              'vocabulary_id': word['id'] ?? '',
              'vietnamese_word': word['vietnamese'] ?? '',
              'dao_word': word['dao'] ?? '',
              'favorite': favorite ? '1' : '0',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _decodeMapResponse(
          response.body,
          'toggleDictionaryFavorite',
        );
        return data != null && data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("Lỗi toggleDictionaryFavorite: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getLearningTopics(String userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/progress/topics.php?user_id=$userId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = _decodeMapResponse(response.body, 'getLearningTopics');

      return data?['data'] is List ? data!['data'] as List<dynamic> : [];
    } catch (e) {
      debugPrint('Lỗi getLearningTopics: $e');
      return [];
    }
  }
}
