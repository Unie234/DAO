import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../app_config.dart';

class StreakRescueService {
  static const String _baseUrl = AppConfig.baseUrl;

  static Map<String, dynamic>? _decodeMapResponse(String body, String label) {
    try {
      final cleanBody = body.trim();
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

  static Future<Map<String, dynamic>?> check(String userId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/streak_rescue/check.php?user_id=$userId'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      return _decodeMapResponse(response.body, 'checkStreakRescue');
    } catch (e) {
      debugPrint("Lỗi checkStreakRescue: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> complete({
    required String userId,
    required String missionId,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/streak_rescue/complete.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'mission_id': missionId,
              'correct_answers': correctAnswers,
              'total_questions': totalQuestions,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      return _decodeMapResponse(response.body, 'completeStreakRescue');
    } catch (e) {
      debugPrint("Lỗi completeStreakRescue: $e");
      return null;
    }
  }
}
