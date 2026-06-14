import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../models/cultural_place.dart';

class CulturalMapService {
  static Future<List<CulturalPlace>> getPlaces() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.baseUrl}/map_places/list.php'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final body = response.body.trim();
      if (!body.startsWith('{')) return [];

      final decoded = json.decode(body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'success') {
        return [];
      }

      final data = decoded['data'];
      if (data is! List) return [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(CulturalPlace.fromJson)
          .toList();
    } catch (e) {
      debugPrint("Lỗi tải địa điểm bản đồ: $e");
      return [];
    }
  }
}
