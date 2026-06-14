import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../app_config.dart';

class CultureArticleService {
  static const String baseUrl = AppConfig.baseUrl;

  static dynamic _decodeResponseBody(String body) {
    final cleanBody = body
        .trim()
        .replaceFirst(RegExp(r'^\uFEFF'), '')
        .replaceFirst(RegExp(r'^\xEF\xBB\xBF'), '');
    return jsonDecode(cleanBody);
  }

  static Future<List<dynamic>> getArticles({
    String category = '',
    String mode = '',
    int limit = 0,
  }) async {
    try {
      final params = <String, String>{};
      if (category.trim().isNotEmpty) {
        params['category'] = category.trim();
      }
      if (mode.trim().isNotEmpty) {
        params['mode'] = mode.trim();
      }
      if (limit > 0) {
        params['limit'] = limit.toString();
      }
      final uri = Uri.parse(
        '$baseUrl/culture_articles/list.php',
      ).replace(queryParameters: params.isEmpty ? null : params);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint(
          "getCultureArticles HTTP ${response.statusCode}: ${response.body}",
        );
        return [];
      }

      final decoded = _decodeResponseBody(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map && decoded['data'] is List) {
        return decoded['data'] as List<dynamic>;
      }
      debugPrint("getCultureArticles không trả list: ${response.body}");
      return [];
    } catch (e) {
      debugPrint("Lỗi getCultureArticles: $e");
      return [];
    }
  }

  static Future<List<dynamic>> searchArticles(
    String keyword, {
    String category = '',
    int limit = 8,
  }) async {
    try {
      final params = <String, String>{
        'keyword': keyword.trim(),
        'limit': limit.toString(),
        if (category.trim().isNotEmpty) 'category': category.trim(),
      };
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/culture_articles/search.php',
            ).replace(queryParameters: params),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint(
          "searchCultureArticles HTTP ${response.statusCode}: ${response.body}",
        );
        return [];
      }

      final decoded = _decodeResponseBody(response.body);
      if (decoded is Map && decoded['data'] is List) {
        return decoded['data'] as List<dynamic>;
      }
      if (decoded is List) return decoded;

      debugPrint("searchCultureArticles không trả list: ${response.body}");
      return [];
    } catch (e) {
      debugPrint("Lỗi searchCultureArticles: $e");
      return [];
    }
  }

  static Future<bool> incrementView(String articleId) async {
    if (articleId.trim().isEmpty) return false;
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/culture_articles/increment_view.php'),
            body: {'id': articleId.trim()},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return false;
      final decoded = _decodeResponseBody(response.body);
      return decoded is Map && decoded['status'] == 'success';
    } catch (e) {
      debugPrint("Lỗi incrementCultureArticleView: $e");
      return false;
    }
  }
}
