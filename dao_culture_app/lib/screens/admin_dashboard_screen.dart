import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final Color darkBlue = const Color(0xFF1A237E);
  int _selectedIndex = 0;
  late Future<bool> _adminGuardFuture;
  late Future<List<dynamic>> _postsFuture;
  late Future<List<dynamic>> _usersFuture;
  late Future<List<dynamic>> _reportsFuture;
  late Future<List<dynamic>> _feedbacksFuture;
  late Future<List<Topic>> _topicsFuture;
  late Future<List<dynamic>> _vocabularyFuture;
  late Future<List<dynamic>> _cultureArticlesFuture;
  late Future<List<dynamic>> _cultureStatsFuture;
  late Future<List<dynamic>> _mapPlacesFuture;
  int? _selectedTopicId;
  String _selectedCultureCategory = "Trang phục";
  final Set<String> _hiddenLocalMapPlaceNames = {};

  static const List<String> _cultureCategories = [
    "Trang phục",
    "Lễ hội",
    "Phong tục",
    "Thảo dược",
  ];

  static const Map<String, String> _mapPlaceTypes = {
    'village': 'Làng văn hóa',
    'festival': 'Lễ hội',
    'herb': 'Thảo dược',
    'tourism': 'Điểm du lịch',
    'community_house': 'Nhà cộng đồng',
    'homestay': 'Homestay',
  };

  @override
  void initState() {
    super.initState();
    _postsFuture = Future.value([]);
    _usersFuture = Future.value([]);
    _reportsFuture = Future.value([]);
    _feedbacksFuture = Future.value([]);
    _topicsFuture = Future.value([]);
    _vocabularyFuture = Future.value([]);
    _cultureArticlesFuture = Future.value([]);
    _cultureStatsFuture = Future.value([]);
    _mapPlacesFuture = Future.value([]);
    _adminGuardFuture = _checkAdminAccess();
  }

  Future<bool> _checkAdminAccess() async {
    final isAdmin = await AuthService.isAdmin();
    if (isAdmin) {
      _refreshData();
    }
    return isAdmin;
  }

  Future<List<dynamic>> _fetchCultureArticles({
    required String category,
  }) async {
    try {
      final encodedCategory = Uri.encodeComponent(category);
      final url = category.trim().isEmpty
          ? '${ApiService.baseUrl}/culture_articles/list.php'
          : '${ApiService.baseUrl}/culture_articles/list.php?category=$encodedCategory';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final raw = jsonDecode(response.body);
      if (raw is List) return raw;
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> _fetchMapPlaces() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiService.baseUrl}/map_places/list.php?admin=1'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final raw = jsonDecode(response.body);
      if (raw is Map && raw['data'] is List) {
        return _mergeAdminMapPlaces(raw['data'] as List);
      }
      return [];
    } catch (_) {
      return _adminMapPlaceFallbacks;
    }
  }

  List<dynamic> _mergeAdminMapPlaces(List<dynamic> apiPlaces) {
    final merged = apiPlaces.whereType<Map<String, dynamic>>().toList();
    for (final fallback in _adminMapPlaceFallbacks) {
      final fallbackName =
          fallback['name']?.toString().trim().toLowerCase() ?? '';
      if (_hiddenLocalMapPlaceNames.contains(fallbackName)) continue;
      final exists = merged.any((place) {
        final name = place['name']?.toString().trim().toLowerCase() ?? '';
        return name == fallbackName ||
            (name.contains('a mé') && fallbackName.contains('a mé')) ||
            (name.contains('a me') && fallbackName.contains('a mé'));
      });
      if (!exists) merged.add(fallback);
    }
    return merged;
  }

  static List<String> _galleryUrlsFromRaw(dynamic raw) {
    if (raw is List) {
      return raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) return [];
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) return _galleryUrlsFromRaw(decoded);
    } catch (_) {}

    return text
        .split(RegExp(r'[\n,;|]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static const List<Map<String, dynamic>> _adminMapPlaceFallbacks = [
    {
      'name': 'Cafe A Mé - Tắm thuốc người Dao',
      'address': "Xã Cư Suê, Cư M'gar, Đắk Lắk",
      'short_description':
          'Địa điểm cafe kết hợp trải nghiệm tắm thuốc người Dao tại Cư Suê.',
      'cultural_description':
          'Điểm trải nghiệm giúp người dùng tìm hiểu đời sống văn hóa người Dao tại Đắk Lắk qua không gian cafe, thảo dược và dịch vụ tắm thuốc.',
      'dao_info':
          'Tắm thuốc là tri thức thảo dược gắn với chăm sóc sức khỏe trong văn hóa người Dao.',
      'tag': 'Trải nghiệm',
      'type': 'herb',
      'layer_type': 'service',
      'image_url': '',
      'gallery_urls': [],
      'latitude': 12.7550,
      'longitude': 108.0500,
      'has_directions': 1,
      'is_active': 1,
      '_local_fallback': true,
    },
  ];

  Future<_MapPlaceSaveResult> _saveMapPlace({
    String? id,
    required String name,
    required String address,
    required String shortDescription,
    required String culturalDescription,
    required String daoInfo,
    required String tag,
    required String type,
    required String layerType,
    required String imageUrl,
    required List<String> galleryUrls,
    required double latitude,
    required double longitude,
    required bool hasDirections,
    required bool isActive,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/map_places/save.php'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              if (id != null && id.trim().isNotEmpty) 'id': id,
              'name': name,
              'address': address,
              'short_description': shortDescription,
              'cultural_description': culturalDescription,
              'dao_info': daoInfo,
              'tag': tag,
              'type': type,
              'layer_type': layerType,
              'image_url': imageUrl,
              'gallery_urls': galleryUrls,
              'latitude': latitude,
              'longitude': longitude,
              'has_directions': hasDirections ? 1 : 0,
              'is_active': isActive ? 1 : 0,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        try {
          final raw = jsonDecode(response.body);
          if (raw is Map) {
            final errors = raw['errors'];
            if (errors is Map && errors.isNotEmpty) {
              final first = errors.values.first;
              final message = first is List && first.isNotEmpty
                  ? first.first.toString()
                  : first.toString();
              return _MapPlaceSaveResult.error(message);
            }
            final message = raw['message']?.toString().trim() ?? '';
            if (message.isNotEmpty) {
              return _MapPlaceSaveResult.error(message);
            }
          }
        } catch (_) {}
        return _MapPlaceSaveResult.error(
          "Server trả lỗi ${response.statusCode}",
        );
      }
      final raw = jsonDecode(response.body);
      if (raw is Map && raw['status'] == 'success') {
        return const _MapPlaceSaveResult.success();
      }
      return _MapPlaceSaveResult.error(
        raw is Map
            ? (raw['message']?.toString() ?? "Không lưu được địa điểm")
            : "Phản hồi lưu địa điểm không hợp lệ",
      );
    } catch (error) {
      return _MapPlaceSaveResult.error("Lỗi kết nối khi lưu địa điểm: $error");
    }
  }

  Future<String?> _uploadMapPlaceImage(XFile image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/map_places/upload_image.php'),
      );
      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            await image.readAsBytes(),
            filename: image.name.isNotEmpty ? image.name : 'map_place.jpg',
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) return null;

      final raw = jsonDecode(response.body);
      if (raw is Map && raw['status'] == 'success') {
        return raw['image_url']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _deleteMapPlaceById(String id) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/map_places/delete.php'),
            body: {'id': id},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return false;
      final raw = jsonDecode(response.body);
      return raw is Map && raw['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  Future<_CultureSaveResult> _saveCultureArticle({
    String? id,
    required String category,
    required String title,
    required String subtitle,
    required String content,
    required String imageUrl,
    required String videoUrl,
    required String detailJson,
    required bool isFeatured,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/culture_articles/save.php'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              if (id != null && id.trim().isNotEmpty) 'id': id,
              'category': category,
              'title': title,
              'subtitle': subtitle,
              'content': content,
              'image_url': imageUrl,
              'video_url': videoUrl,
              'detail_json': detailJson,
              'is_featured': isFeatured ? 1 : 0,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        try {
          final raw = jsonDecode(response.body);
          if (raw is Map) {
            final errors = raw['errors'];
            if (errors is Map && errors.isNotEmpty) {
              final first = errors.values.first;
              final message = first is List && first.isNotEmpty
                  ? first.first.toString()
                  : first.toString();
              return _CultureSaveResult.error(message);
            }
            final message = raw['message']?.toString().trim() ?? '';
            if (message.isNotEmpty) {
              return _CultureSaveResult.error(message);
            }
          }
        } catch (_) {}
        return _CultureSaveResult.error(
          "Server trả lỗi ${response.statusCode}",
        );
      }
      final raw = jsonDecode(response.body);
      if (raw is Map && raw['status'] == 'success') {
        return const _CultureSaveResult.success();
      }
      return _CultureSaveResult.error(
        raw is Map
            ? (raw['message']?.toString() ?? "Không lưu được bài viết")
            : "Phản hồi lưu bài không hợp lệ",
      );
    } catch (error) {
      return _CultureSaveResult.error("Lỗi kết nối khi lưu bài: $error");
    }
  }

  Future<String?> _uploadCultureArticleImage(XFile image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/culture_articles/upload_image.php'),
      );
      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            await image.readAsBytes(),
            filename: image.name.isNotEmpty ? image.name : 'culture_image.jpg',
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) return null;

      final raw = jsonDecode(response.body);
      if (raw is Map && raw['status'] == 'success') {
        return raw['image_url']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String> _uploadCultureArticleVideo(XFile video) async {
    const maxVideoBytes = 100 * 1024 * 1024;
    final videoSize = await video.length();
    if (videoSize > maxVideoBytes) {
      throw Exception("Video phải nhỏ hơn 100MB.");
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/culture_articles/upload_video.php'),
    )..headers['Accept'] = 'application/json';
    final contentType = _videoContentType(video.name);

    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'video',
          await video.readAsBytes(),
          filename: video.name.isNotEmpty ? video.name : 'culture_video.mp4',
          contentType: contentType,
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          video.path,
          filename: video.name,
          contentType: contentType,
        ),
      );
    }

    final streamed = await request.send().timeout(const Duration(seconds: 180));
    final response = await http.Response.fromStream(
      streamed,
    ).timeout(const Duration(seconds: 20));
    final rawBody = response.body.trim();
    final raw = rawBody.isEmpty ? null : jsonDecode(rawBody);

    if (response.statusCode != 200) {
      final message = raw is Map
          ? (raw['message'] ??
                    raw['error'] ??
                    'Lỗi server ${response.statusCode}')
                .toString()
          : 'Lỗi server ${response.statusCode}';
      throw Exception(message);
    }

    if (raw is Map && raw['status'] == 'success') {
      final videoUrl = raw['video_url']?.toString() ?? '';
      if (videoUrl.isNotEmpty) return videoUrl;
    }

    throw Exception("Máy chủ chưa trả về đường dẫn video.");
  }

  MediaType _videoContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'mov' => MediaType('video', 'quicktime'),
      'webm' => MediaType('video', 'webm'),
      'm4v' => MediaType('video', 'x-m4v'),
      _ => MediaType('video', 'mp4'),
    };
  }

  Future<bool> _deleteCultureArticleById(String id) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/culture_articles/delete.php'),
            body: {'id': id},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return false;
      final raw = jsonDecode(response.body);
      return raw is Map && raw['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  Future<bool> _deleteCommentById(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminUserId = prefs.getString('user_id') ?? '';
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/comments/delete.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': id, 'admin_user_id': adminUserId}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return false;
      final raw = jsonDecode(response.body);
      return raw is Map && raw['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  void _refreshData() {
    _postsFuture = ApiService.getPosts();
    _usersFuture = ApiService.getUsers();
    _reportsFuture = ApiService.getReports();
    _feedbacksFuture = ApiService.getFeedbacks();
    _topicsFuture = ApiService.getTopics();
    _cultureArticlesFuture = _fetchCultureArticles(
      category: _selectedCultureCategory,
    );
    _cultureStatsFuture = _fetchCultureArticles(category: "");
    _mapPlacesFuture = _fetchMapPlaces();
    if (_selectedTopicId != null) {
      _vocabularyFuture = ApiService.getVocabularyByTopic(_selectedTopicId!);
    }
  }

  void _refreshCurrentTab() {
    setState(_refreshData);
  }

  void _refreshVocabulary(int topicId) {
    setState(() {
      _selectedTopicId = topicId;
      _vocabularyFuture = ApiService.getVocabularyByTopic(topicId);
    });
  }

  void _refreshCultureArticles(String category) {
    setState(() {
      _selectedCultureCategory = category;
      _cultureArticlesFuture = _fetchCultureArticles(category: category);
      _cultureStatsFuture = _fetchCultureArticles(category: "");
    });
  }

  void _refreshMapPlaces() {
    setState(() {
      _mapPlacesFuture = _fetchMapPlaces();
    });
  }

  void _deletePost(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          "Xóa bài viết?",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Bạn có chắc chắn muốn xóa bài viết này khỏi cộng đồng không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ApiService.deletePost(
                postId,
                isAdmin: true,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? "Đã xóa bài viết vi phạm!"
                        : "Không xóa được bài viết!",
                  ),
                ),
              );
              if (success) _refreshCurrentTab();
            },
            child: const Text(
              "Xóa ngay",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReportAction(
    BuildContext context,
    Map<String, dynamic> report, {
    required int banDays,
    required bool hidePost,
  }) async {
    final reportId = report['id'].toString();
    final postId = report['post_id']?.toString() ?? "";
    bool success = false;

    if (hidePost && postId.isNotEmpty) {
      success = await ApiService.hidePost(postId, banDays: banDays);
      if (success) {
        success = await ApiService.resolveReport(reportId, "resolved");
      }
    } else {
      success = await ApiService.resolveReport(reportId, "rejected");
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? "Đã xử lý báo cáo" : "Không xử lý được báo cáo",
        ),
      ),
    );
    if (success) {
      setState(() {
        _reportsFuture = _reportsFuture.then(
          (reports) => reports
              .where((item) => item['id']?.toString() != reportId)
              .toList(),
        );
      });
    }
  }

  void _showTopicDialog({Topic? topic}) {
    final controller = TextEditingController(text: topic?.title ?? "");

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(topic == null ? "Thêm danh mục" : "Sửa danh mục"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Tên danh mục"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: darkBlue),
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isEmpty) return;

              final success = topic == null
                  ? await ApiService.addTopic(title)
                  : await ApiService.updateTopic(topic.id, title);

              if (!dialogContext.mounted || !mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? "Đã lưu danh mục" : "Không lưu được danh mục",
                  ),
                ),
              );
              if (success) _refreshCurrentTab();
            },
            child: const Text("Lưu", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteTopic(Topic topic) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Xóa danh mục?"),
        content: Text("Bạn có chắc chắn muốn xóa '${topic.title}' không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ApiService.deleteTopic(topic.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? "Đã xóa danh mục" : "Không xóa được danh mục",
                  ),
                ),
              );
              if (success) _refreshCurrentTab();
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showVocabularyDialog({
    Map<String, dynamic>? item,
    required List<Topic> topics,
  }) {
    final daoController = TextEditingController(
      text: item?['dao_word']?.toString() ?? "",
    );
    final vietController = TextEditingController(
      text: item?['viet_word']?.toString() ?? "",
    );
    final audioController = TextEditingController(
      text: item?['audio_file']?.toString() ?? "",
    );
    int topicId =
        int.tryParse(
          item?['topic_id']?.toString() ?? _selectedTopicId?.toString() ?? "",
        ) ??
        int.parse(topics.first.id);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? "Thêm từ vựng" : "Sửa từ vựng"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: topicId,
                  decoration: const InputDecoration(labelText: "Danh mục"),
                  items: topics
                      .map(
                        (topic) => DropdownMenuItem(
                          value: int.parse(topic.id),
                          child: Text(topic.title),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => topicId = value);
                    }
                  },
                ),
                TextField(
                  controller: daoController,
                  decoration: const InputDecoration(labelText: "Tiếng Dao"),
                ),
                TextField(
                  controller: vietController,
                  decoration: const InputDecoration(labelText: "Tiếng Việt"),
                ),
                TextField(
                  controller: audioController,
                  decoration: const InputDecoration(labelText: "File audio"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: darkBlue),
              onPressed: () async {
                final daoWord = daoController.text.trim();
                final vietWord = vietController.text.trim();
                final audioFile = audioController.text.trim();
                if (daoWord.isEmpty || vietWord.isEmpty) return;

                final success = item == null
                    ? await ApiService.addVocabulary(
                        topicId: topicId.toString(),
                        daoWord: daoWord,
                        vietWord: vietWord,
                        audioFile: audioFile,
                      )
                    : await ApiService.updateVocabulary(
                        id: item['id'].toString(),
                        topicId: topicId.toString(),
                        daoWord: daoWord,
                        vietWord: vietWord,
                        audioFile: audioFile,
                      );

                if (!dialogContext.mounted || !mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? "Đã lưu từ vựng" : "Không lưu được từ vựng",
                    ),
                  ),
                );
                if (success) _refreshVocabulary(topicId);
              },
              child: const Text("Lưu", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteVocabulary(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Xóa từ vựng?"),
        content: Text("Bạn có chắc chắn muốn xóa '${item['dao_word']}' không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ApiService.deleteVocabulary(
                item['id'].toString(),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? "Đã xóa từ vựng" : "Không xóa được từ vựng",
                  ),
                ),
              );
              if (success && _selectedTopicId != null) {
                _refreshVocabulary(_selectedTopicId!);
              }
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCultureArticleDialog({Map<String, dynamic>? item}) {
    String category = item?['category']?.toString() ?? _selectedCultureCategory;
    if (!_cultureCategories.contains(category)) {
      category = _cultureCategories.first;
    }

    final titleController = TextEditingController(
      text: item?['title']?.toString() ?? "",
    );
    final subtitleController = TextEditingController(
      text: item?['subtitle']?.toString() ?? "",
    );
    final contentController = TextEditingController(
      text: item?['content']?.toString() ?? "",
    );
    final imageController = TextEditingController(
      text: item?['image_url']?.toString() ?? "",
    );
    final videoController = TextEditingController(
      text: item?['video_url']?.toString() ?? "",
    );
    final detailController = TextEditingController(
      text: item?['detail_json']?.toString() ?? "",
    );
    bool isFeatured =
        item?['is_featured'] == true || item?['is_featured']?.toString() == '1';
    final detailMap = _decodeCultureDetail(detailController.text);
    final existingHerbalCategories = detailMap['categories'];
    final detailCategoryController = TextEditingController(
      text:
          detailMap['category']?.toString() ??
          (category == "Thảo dược" &&
                  existingHerbalCategories is List &&
                  existingHerbalCategories.isNotEmpty
              ? existingHerbalCategories.first.toString()
              : ""),
    );
    final locationController = TextEditingController(
      text: detailMap['location']?.toString() ?? "",
    );
    final timeController = TextEditingController(
      text: (detailMap['time'] ?? detailMap['season'] ?? "").toString(),
    );
    final tagsController = TextEditingController(
      text: _listToLines(
        category == "Thảo dược"
            ? detailMap['cultural_values']
            : detailMap['categories'],
      ),
    );
    final benefitsController = TextEditingController(
      text: _listToLines(detailMap['benefits']),
    );
    final stepsController = TextEditingController(
      text: _listToLines(detailMap['steps']),
    );
    final warningController = TextEditingController(
      text: detailMap['warning']?.toString() ?? "",
    );
    final galleryController = TextEditingController(
      text: _listToLines(detailMap['gallery']),
    );
    final ingredientsController = TextEditingController(
      text: _detailRowsToLines(detailMap['ingredients']),
    );
    final meaningsController = TextEditingController(
      text: _detailRowsToLines(detailMap['meanings']),
    );
    final contentSourcesController = TextEditingController(
      text: _sourceLines(detailMap, 'content'),
    );
    final imageSourcesController = TextEditingController(
      text: _sourceLines(detailMap, 'image'),
    );
    final videoSourcesController = TextEditingController(
      text: _sourceLines(detailMap, 'video'),
    );
    String selectedImagePath = "";
    Uint8List? selectedImageBytes;
    String imageUploadStatus = "";
    String videoUploadStatus = "";
    String galleryUploadStatus = "";
    bool isUploadingImage = false;
    bool isUploadingVideo = false;
    bool isUploadingGallery = false;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? "Thêm bài văn hóa" : "Sửa bài văn hóa"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: "Danh mục"),
                    items: _cultureCategories
                        .map(
                          (name) =>
                              DropdownMenuItem(value: name, child: Text(name)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => category = value);
                      }
                    },
                  ),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: _cultureFormLabels(category).titleLabel,
                      hintText: _cultureFormLabels(category).titleHint,
                    ),
                  ),
                  TextField(
                    controller: subtitleController,
                    decoration: InputDecoration(
                      labelText: "Mô tả ngắn",
                      hintText: _cultureFormLabels(category).subtitleHint,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isFeatured,
                    title: const Text(
                      "Ghim làm nội dung nổi bật",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      "Bài được ghim sẽ ưu tiên hiện ở trang chủ.",
                    ),
                    secondary: Icon(
                      isFeatured
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      color: isFeatured ? Colors.orange : Colors.grey,
                    ),
                    onChanged: (value) =>
                        setDialogState(() => isFeatured = value),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Ảnh bài viết",
                      style: TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (selectedImagePath.isNotEmpty ||
                      imageController.text.trim().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: selectedImagePath.isNotEmpty
                            ? kIsWeb && selectedImageBytes != null
                                  ? Image.memory(
                                      selectedImageBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(selectedImagePath),
                                      fit: BoxFit.cover,
                                    )
                            : _isCultureAssetImage(imageController.text)
                            ? Image.asset(
                                imageController.text.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFEDE7DE),
                                  child: const Icon(Icons.image_rounded),
                                ),
                              )
                            : Image.network(
                                _normalizeCultureImageUrl(
                                  imageController.text.trim(),
                                ),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFEDE7DE),
                                  child: const Icon(Icons.image_rounded),
                                ),
                              ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isUploadingImage || isSaving
                              ? null
                              : () async {
                                  final picked = await ImagePicker().pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 88,
                                    maxWidth: 1600,
                                  );
                                  if (picked == null) return;
                                  final bytes = kIsWeb
                                      ? await picked.readAsBytes()
                                      : null;

                                  setDialogState(() {
                                    selectedImagePath = picked.path;
                                    selectedImageBytes = bytes;
                                    isUploadingImage = true;
                                    imageUploadStatus = "Đang upload ảnh...";
                                  });

                                  final uploadedUrl =
                                      await _uploadCultureArticleImage(picked);

                                  if (!dialogContext.mounted || !mounted) {
                                    return;
                                  }

                                  setDialogState(() {
                                    isUploadingImage = false;
                                    if (uploadedUrl != null &&
                                        uploadedUrl.isNotEmpty) {
                                      imageController.text = uploadedUrl;
                                      imageUploadStatus =
                                          "Đã chọn và upload ảnh: ${picked.name}";
                                    } else {
                                      imageUploadStatus =
                                          "Upload ảnh chưa thành công, vui lòng chọn lại";
                                    }
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        uploadedUrl == null
                                            ? "Không upload được ảnh"
                                            : "Đã chọn và upload ảnh",
                                      ),
                                    ),
                                  );
                                },
                          icon: Icon(
                            isUploadingImage
                                ? Icons.cloud_upload_rounded
                                : Icons.photo_library_rounded,
                          ),
                          label: Text(
                            isUploadingImage ? "Đang upload..." : "Chọn ảnh",
                          ),
                        ),
                      ),
                      if (imageController.text.trim().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: "Xóa ảnh bìa",
                          onPressed: isUploadingImage || isSaving
                              ? null
                              : () => setDialogState(() {
                                  selectedImagePath = "";
                                  selectedImageBytes = null;
                                  imageController.clear();
                                  imageUploadStatus = "Đã xóa ảnh bài viết";
                                }),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ],
                  ),
                  _buildCultureMediaStatusBar(
                    isUploading: isUploadingImage,
                    currentValue: imageController.text,
                    message: imageUploadStatus,
                    existingLabel: "Bài đang có ảnh bài viết",
                    emptyLabel: "Chưa có ảnh bài viết",
                    icon: Icons.image_rounded,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Video bài viết",
                      style: TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isUploadingVideo || isSaving
                              ? null
                              : () async {
                                  final picked = await ImagePicker().pickVideo(
                                    source: ImageSource.gallery,
                                  );
                                  if (picked == null) return;

                                  setDialogState(() {
                                    isUploadingVideo = true;
                                    videoUploadStatus = "Đang upload video...";
                                  });
                                  String? uploadedUrl;
                                  String? uploadError;
                                  try {
                                    uploadedUrl =
                                        await _uploadCultureArticleVideo(
                                          picked,
                                        );
                                  } catch (e) {
                                    uploadError = e.toString().replaceFirst(
                                      'Exception: ',
                                      '',
                                    );
                                  } finally {
                                    if (dialogContext.mounted && mounted) {
                                      setDialogState(() {
                                        isUploadingVideo = false;
                                        if (uploadedUrl != null &&
                                            uploadedUrl.isNotEmpty) {
                                          videoController.text = uploadedUrl;
                                          videoUploadStatus =
                                              "Đã chọn và upload video: ${picked.name}";
                                        } else {
                                          videoUploadStatus =
                                              uploadError ??
                                              "Upload video chưa thành công, vui lòng chọn lại";
                                        }
                                      });
                                    }
                                  }

                                  if (!dialogContext.mounted || !mounted) {
                                    return;
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        uploadedUrl == null ||
                                                uploadedUrl.isEmpty
                                            ? "Không upload được video: ${uploadError ?? 'vui lòng thử lại'}"
                                            : "Đã chọn và upload video",
                                      ),
                                    ),
                                  );
                                },
                          icon: Icon(
                            isUploadingVideo
                                ? Icons.cloud_upload_rounded
                                : Icons.video_library_rounded,
                          ),
                          label: Text(
                            isUploadingVideo
                                ? "Đang upload video..."
                                : "Chọn video",
                          ),
                        ),
                      ),
                      if (videoController.text.trim().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: "Xóa video",
                          onPressed: isUploadingVideo || isSaving
                              ? null
                              : () => setDialogState(() {
                                  videoController.clear();
                                  videoUploadStatus = "Đã xóa video bài viết";
                                }),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ],
                  ),
                  _buildCultureMediaStatusBar(
                    isUploading: isUploadingVideo,
                    currentValue: videoController.text,
                    message: videoUploadStatus,
                    existingLabel: "Bài đang có video",
                    emptyLabel: "Chưa có video bài viết",
                    icon: Icons.videocam_rounded,
                  ),
                  TextField(
                    controller: videoController,
                    enabled: !isUploadingVideo && !isSaving,
                    decoration: const InputDecoration(
                      labelText: "Hoặc dán link video",
                      hintText:
                          "Ví dụ: https://.../video.mp4 hoặc link YouTube",
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    onChanged: (_) => setDialogState(() {
                      videoUploadStatus = videoController.text.trim().isEmpty
                          ? ""
                          : "Đã nhập link video";
                    }),
                  ),
                  if (videoController.text.trim().isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          videoController.text.trim().split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Thư viện ảnh",
                      style: TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isUploadingGallery || isSaving
                              ? null
                              : () async {
                                  final pickedImages = await ImagePicker()
                                      .pickMultiImage(
                                        imageQuality: 88,
                                        maxWidth: 1600,
                                      );
                                  if (pickedImages.isEmpty) return;

                                  setDialogState(() {
                                    isUploadingGallery = true;
                                    galleryUploadStatus =
                                        "Đang upload ảnh thư viện...";
                                  });
                                  final uploaded = <String>[];
                                  for (final image in pickedImages) {
                                    final url =
                                        await _uploadCultureArticleImage(image);
                                    if (url != null && url.isNotEmpty) {
                                      uploaded.add(url);
                                    }
                                  }

                                  if (!dialogContext.mounted || !mounted) {
                                    return;
                                  }

                                  setDialogState(() {
                                    isUploadingGallery = false;
                                    if (uploaded.isNotEmpty) {
                                      final current = galleryController.text
                                          .split('\n')
                                          .map((line) => line.trim())
                                          .where((line) => line.isNotEmpty)
                                          .toList();
                                      current.addAll(uploaded);
                                      galleryController.text = current
                                          .toSet()
                                          .join('\n');
                                    }
                                    galleryUploadStatus =
                                        uploaded.length == pickedImages.length
                                        ? "Đã upload ${uploaded.length} ảnh thư viện"
                                        : "Upload được ${uploaded.length}/${pickedImages.length} ảnh thư viện";
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        uploaded.length == pickedImages.length
                                            ? "Đã upload ${uploaded.length} ảnh thư viện"
                                            : "Upload được ${uploaded.length}/${pickedImages.length} ảnh",
                                      ),
                                    ),
                                  );
                                },
                          icon: Icon(
                            isUploadingGallery
                                ? Icons.cloud_upload_rounded
                                : Icons.photo_library_outlined,
                          ),
                          label: Text(
                            isUploadingGallery
                                ? "Đang upload ảnh..."
                                : "Chọn nhiều ảnh",
                          ),
                        ),
                      ),
                      if (galleryController.text.trim().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: "Xóa thư viện ảnh",
                          onPressed: isUploadingGallery || isSaving
                              ? null
                              : () => setDialogState(() {
                                  galleryController.clear();
                                  galleryUploadStatus = "Đã xóa thư viện ảnh";
                                }),
                          icon: const Icon(Icons.delete_sweep_outlined),
                        ),
                      ],
                    ],
                  ),
                  _buildCultureMediaStatusBar(
                    isUploading: isUploadingGallery,
                    currentValue: galleryController.text,
                    message: galleryUploadStatus,
                    existingLabel:
                        "${_linesToList(galleryController.text).length} ảnh đang có trong thư viện",
                    emptyLabel: "Chưa có ảnh trong thư viện",
                    icon: Icons.photo_library_rounded,
                  ),
                  if (galleryController.text.trim().isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "${_linesToList(galleryController.text).length} ảnh đã chọn",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (galleryController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildCultureGalleryPreview(
                      galleryController: galleryController,
                      onRemove: (index) => setDialogState(() {
                        final images = _linesToList(galleryController.text);
                        if (index < 0 || index >= images.length) return;
                        images.removeAt(index);
                        galleryController.text = images.join('\n');
                      }),
                      onMove: (fromIndex, toIndex) => setDialogState(() {
                        final images = _linesToList(galleryController.text);
                        if (fromIndex < 0 ||
                            fromIndex >= images.length ||
                            toIndex < 0 ||
                            toIndex >= images.length) {
                          return;
                        }
                        final moved = images.removeAt(fromIndex);
                        images.insert(toIndex, moved);
                        galleryController.text = images.join('\n');
                      }),
                    ),
                  ],
                  TextField(
                    controller: contentController,
                    minLines: 5,
                    maxLines: 10,
                    decoration: InputDecoration(
                      labelText: _cultureFormLabels(category).contentLabel,
                      hintText: _cultureFormLabels(category).contentHint,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildCultureDetailFields(
                    category: category,
                    detailCategoryController: detailCategoryController,
                    locationController: locationController,
                    timeController: timeController,
                    tagsController: tagsController,
                    benefitsController: benefitsController,
                    stepsController: stepsController,
                    warningController: warningController,
                    galleryController: galleryController,
                    ingredientsController: ingredientsController,
                    meaningsController: meaningsController,
                  ),
                  const SizedBox(height: 14),
                  _buildCultureSourceFields(
                    contentSourcesController: contentSourcesController,
                    imageSourcesController: imageSourcesController,
                    videoSourcesController: videoSourcesController,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: darkBlue),
              onPressed:
                  (isUploadingImage ||
                      isUploadingVideo ||
                      isUploadingGallery ||
                      isSaving)
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      final content = contentController.text.trim();
                      if (title.isEmpty || content.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Nhập tiêu đề và nội dung bài viết nhé",
                            ),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      final saveResult = await _saveCultureArticle(
                        id: item?['id']?.toString(),
                        category: category,
                        title: title,
                        subtitle: subtitleController.text.trim(),
                        content: content,
                        imageUrl: imageController.text.trim(),
                        videoUrl: videoController.text.trim(),
                        isFeatured: isFeatured,
                        detailJson: _buildCultureDetailJson(
                          category: category,
                          detailCategory: detailCategoryController.text.trim(),
                          location: locationController.text.trim(),
                          timeOrSeason: timeController.text.trim(),
                          tagsText: tagsController.text,
                          benefitsText: benefitsController.text,
                          stepsText: stepsController.text,
                          warning: warningController.text.trim(),
                          galleryText: galleryController.text,
                          ingredientsText: ingredientsController.text,
                          meaningsText: meaningsController.text,
                          contentSourcesText: contentSourcesController.text,
                          imageSourcesText: imageSourcesController.text,
                          videoSourcesText: videoSourcesController.text,
                        ),
                      );

                      if (!dialogContext.mounted || !mounted) return;
                      setDialogState(() => isSaving = false);
                      if (saveResult.success) {
                        Navigator.pop(dialogContext);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            saveResult.success
                                ? "Đã lưu bài viết"
                                : saveResult.message,
                          ),
                        ),
                      );
                      if (saveResult.success) {
                        _refreshCultureArticles(category);
                      }
                    },
              child: Text(
                isSaving ? "Đang lưu..." : "Lưu",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCultureGalleryPreview({
    required TextEditingController galleryController,
    required ValueChanged<int> onRemove,
    required void Function(int fromIndex, int toIndex) onMove,
  }) {
    final images = _linesToList(galleryController.text);
    if (images.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(images.length, (index) {
          final imageUrl = images[index];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 92,
                  height: 72,
                  child: _buildCultureGalleryImage(imageUrl),
                ),
              ),
              Positioned(
                left: 5,
                top: 5,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 4,
                right: 4,
                bottom: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGalleryMoveButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: index > 0,
                      onTap: () => onMove(index, index - 1),
                    ),
                    _buildGalleryMoveButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: index < images.length - 1,
                      onTap: () => onMove(index, index + 1),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: Material(
                  color: Colors.red.shade700,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onRemove(index),
                    child: const SizedBox(
                      width: 26,
                      height: 26,
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCultureMediaStatusBar({
    required bool isUploading,
    required String currentValue,
    required String message,
    required String existingLabel,
    required String emptyLabel,
    required IconData icon,
  }) {
    final hasMedia = currentValue.trim().isNotEmpty;
    final effectiveMessage = message.trim().isNotEmpty
        ? message.trim()
        : hasMedia
        ? "$existingLabel: ${_cultureMediaFileName(currentValue)}"
        : emptyLabel;
    final color = isUploading
        ? const Color(0xFF1A237E)
        : hasMedia || message.trim().startsWith("Đã")
        ? const Color(0xFF2E7D32)
        : Colors.grey.shade700;

    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            if (isUploading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, color: color, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                effectiveMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cultureMediaFileName(String value) {
    final first = value
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => value.trim());
    final normalized = first.replaceAll('\\', '/');
    final name = normalized.split('/').last;
    return name.isEmpty ? "đã có tệp" : name;
  }

  Widget _buildGalleryMoveButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled
          ? Colors.black.withValues(alpha: 0.62)
          : Colors.black.withValues(alpha: 0.22),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 24,
          height: 24,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildCultureGalleryImage(String imageUrl) {
    final value = imageUrl.trim();
    if (_isCultureAssetImage(value)) {
      return Image.asset(
        value,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildCultureImageFallback(),
      );
    }

    return Image.network(
      _normalizeCultureImageUrl(value),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildCultureImageFallback(),
    );
  }

  bool _isCultureAssetImage(String value) {
    return value.trim().startsWith('assets/');
  }

  String _normalizeCultureImageUrl(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '${ApiService.baseUrl}/culture_articles/image.php';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    final serverUrl = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    if (raw.startsWith('//')) return 'http:$raw';
    if (raw.startsWith('/')) return '$serverUrl$raw';
    if (raw.startsWith('api/') || raw.startsWith('storage/')) {
      return '$serverUrl/$raw';
    }
    if (raw.startsWith('uploads/culture/')) {
      return '$serverUrl/storage/$raw';
    }

    final normalized = raw.replaceAll('\\', '/');
    final fileName = normalized
        .split('/')
        .where((part) => part.isNotEmpty)
        .last;
    return '${ApiService.baseUrl}/culture_articles/image.php?file=${Uri.encodeComponent(fileName)}';
  }

  Widget _buildCultureImageFallback() {
    return Container(
      color: const Color(0xFFEDE7DE),
      alignment: Alignment.center,
      child: const Icon(Icons.image_rounded),
    );
  }

  Widget _buildCultureDetailFields({
    required String category,
    required TextEditingController detailCategoryController,
    required TextEditingController locationController,
    required TextEditingController timeController,
    required TextEditingController tagsController,
    required TextEditingController benefitsController,
    required TextEditingController stepsController,
    required TextEditingController warningController,
    required TextEditingController galleryController,
    required TextEditingController ingredientsController,
    required TextEditingController meaningsController,
  }) {
    final labels = _cultureFormLabels(category);
    final isHerbal = category == "Thảo dược";
    final isCostume = category == "Trang phục";
    Widget mainListField({
      required TextEditingController controller,
      required String label,
      required String hint,
    }) {
      return TextField(
        controller: controller,
        minLines: 3,
        maxLines: 6,
        decoration: InputDecoration(labelText: label, hintText: hint),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labels.detailTitle,
          style: TextStyle(fontWeight: FontWeight.bold, color: darkBlue),
        ),
        TextField(
          controller: detailCategoryController,
          decoration: InputDecoration(
            labelText: labels.detailCategoryLabel,
            hintText: labels.detailCategoryHint,
          ),
        ),
        TextField(
          controller: locationController,
          decoration: InputDecoration(
            labelText: labels.locationLabel,
            hintText: labels.locationHint,
          ),
        ),
        if (!isHerbal)
          TextField(
            controller: timeController,
            decoration: InputDecoration(
              labelText: labels.timeLabel,
              hintText: labels.timeHint,
            ),
          ),
        if (isCostume) ...[
          mainListField(
            controller: benefitsController,
            label: labels.benefitsLabel,
            hint: labels.benefitsHint,
          ),
          mainListField(
            controller: meaningsController,
            label: labels.mainListLabel,
            hint: labels.mainListHint,
          ),
          mainListField(
            controller: stepsController,
            label: labels.stepsLabel,
            hint: labels.stepsHint,
          ),
        ] else ...[
          mainListField(
            controller: isHerbal ? ingredientsController : meaningsController,
            label: labels.mainListLabel,
            hint: labels.mainListHint,
          ),
          mainListField(
            controller: benefitsController,
            label: labels.benefitsLabel,
            hint: labels.benefitsHint,
          ),
          mainListField(
            controller: stepsController,
            label: labels.stepsLabel,
            hint: labels.stepsHint,
          ),
        ],
        if (isHerbal)
          TextField(
            controller: tagsController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: "Giá trị văn hóa",
              hintText:
                  "Mỗi dòng một ý: Tri thức truyền đời, gắn với môi trường rừng...",
            ),
          ),
        if (!isCostume)
          TextField(
            controller: warningController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: labels.warningLabel,
              hintText: labels.warningHint,
            ),
          ),
      ],
    );
  }

  Widget _buildCultureSourceFields({
    required TextEditingController contentSourcesController,
    required TextEditingController imageSourcesController,
    required TextEditingController videoSourcesController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tư liệu tham khảo",
          style: TextStyle(fontWeight: FontWeight.bold, color: darkBlue),
        ),
        const SizedBox(height: 4),
        Text(
          "Mỗi dòng một nguồn. Có thể ghi tên tài liệu, tác giả/đơn vị, link và ngày truy cập.",
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
        TextField(
          controller: contentSourcesController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: "Nguồn nội dung",
            hintText:
                "Ví dụ: Ban Dân tộc tỉnh Quảng Ninh - https://... - truy cập 01/06/2026",
          ),
        ),
        TextField(
          controller: imageSourcesController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: "Nguồn hình ảnh",
            hintText: "Ví dụ: Báo Quảng Ninh - ảnh minh họa - https://...",
          ),
        ),
        TextField(
          controller: videoSourcesController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: "Nguồn video",
            hintText: "Ví dụ: YouTube: Tên kênh - https://...",
          ),
        ),
      ],
    );
  }

  _CultureFormLabels _cultureFormLabels(String category) {
    switch (category) {
      case "Trang phục":
        return const _CultureFormLabels(
          titleLabel: "Tên trang phục",
          titleHint: "Ví dụ: Trang phục nữ Dao Đỏ",
          subtitleHint: "Ví dụ: Hoa văn, màu sắc và bản sắc cộng đồng",
          contentLabel: "Giới thiệu về trang phục",
          contentHint:
              "Mô tả nguồn gốc, kiểu dáng, màu sắc, chất liệu và vai trò trong đời sống.",
          detailTitle: "Thông tin chi tiết trang phục",
          detailCategoryLabel: "Loại trang phục",
          detailCategoryHint:
              "Nữ, Nam, Trẻ em, Phụ kiện, Trang phục nghi lễ...",
          locationLabel: "Nhóm Dao / địa phương",
          locationHint: "Dao Đỏ ở Lào Cai, Dao Thanh Phán ở Quảng Ninh...",
          timeLabel: "Dịp sử dụng",
          timeHint: "Ngày thường, lễ cưới, lễ cấp sắc, lễ hội...",
          mainListLabel: "Ý nghĩa văn hóa",
          mainListHint:
              "Mỗi dòng: Hoa văn thêu tay | Thể hiện sự khéo léo và bản sắc người Dao",
          benefitsLabel: "Đặc điểm nổi bật",
          benefitsHint:
              "Mỗi dòng một ý: màu chàm, khăn đội đầu, hoa văn thêu tay...",
          stepsLabel: "Giá trị bảo tồn",
          stepsHint:
              "Mỗi dòng một ý: truyền nghề thêu, gìn giữ bản sắc trong lễ hội...",
          warningLabel: "",
          warningHint: "",
        );
      case "Lễ hội":
        return const _CultureFormLabels(
          titleLabel: "Tên lễ hội",
          titleHint: "Ví dụ: Tết Nhảy của người Dao",
          subtitleHint: "Ví dụ: Lễ hội đầu năm cầu bình an, mùa màng tốt tươi",
          contentLabel: "Giới thiệu về lễ hội",
          contentHint:
              "Nêu bối cảnh, mục đích, người tham gia và không khí chính của lễ hội.",
          detailTitle: "Thông tin chi tiết lễ hội",
          detailCategoryLabel: "Loại lễ hội",
          detailCategoryHint:
              "Mùa xuân, Nghi lễ, Cầu mùa, Sinh hoạt cộng đồng...",
          locationLabel: "Địa điểm tổ chức",
          locationHint: "Lào Cai, Hà Giang, trong bản, tại nhà thầy cúng...",
          timeLabel: "Thời gian / mùa tổ chức",
          timeHint: "Mùng 1 - Mùng 3 Tết, đầu năm, sau vụ mùa...",
          mainListLabel: "Ý nghĩa / điểm nổi bật",
          mainListHint:
              "Mỗi dòng: Tưởng nhớ tổ tiên | Gắn kết gia đình và cộng đồng",
          benefitsLabel: "Hoạt động chính",
          benefitsHint: "Mỗi dòng một hoạt động: múa, hát, cúng, rước lễ...",
          stepsLabel: "Trình tự lễ hội / nghi thức",
          stepsHint: "Mỗi dòng một bước theo thứ tự diễn ra",
          warningLabel: "Lưu ý khi tham gia",
          warningHint: "Ví dụ: Giữ thái độ trang nghiêm trong phần nghi lễ.",
        );
      case "Phong tục":
        return const _CultureFormLabels(
          titleLabel: "Tên phong tục",
          titleHint: "Ví dụ: Phong tục cưới hỏi của người Dao",
          subtitleHint: "Ví dụ: Nghi thức gắn kết hai gia đình",
          contentLabel: "Giới thiệu về phong tục",
          contentHint:
              "Mô tả hoàn cảnh thực hiện, nhân vật tham gia và giá trị văn hóa.",
          detailTitle: "Thông tin chi tiết phong tục",
          detailCategoryLabel: "Nhóm phong tục",
          detailCategoryHint:
              "Hôn nhân, Tang ma, Thờ cúng, Kiêng kỵ dân gian...",
          locationLabel: "Nơi thực hiện / phạm vi",
          locationHint: "Trong gia đình, làng bản, các nhóm Dao ở...",
          timeLabel: "Thời điểm thực hiện",
          timeHint: "Khi cưới hỏi, khi làm nhà, dịp đầu năm...",
          mainListLabel: "Ý nghĩa / vai trò",
          mainListHint:
              "Mỗi dòng: Kính trọng tổ tiên | Giữ gìn nề nếp gia đình",
          benefitsLabel: "Lễ vật / điểm chính",
          benefitsHint: "Mỗi dòng một ý: lễ vật, lời khấn, người chủ trì...",
          stepsLabel: "Các bước / nghi thức",
          stepsHint: "Mỗi dòng một bước theo trình tự thực hiện",
          warningLabel: "Điều cần lưu ý",
          warningHint:
              "Ví dụ: Nghi thức có thể khác nhau theo dòng họ và địa phương.",
        );
      case "Thảo dược":
      default:
        return const _CultureFormLabels(
          titleLabel: "Tên cây thuốc / tri thức thảo dược",
          titleHint: "Ví dụ: Lá tắm người Dao Đỏ",
          subtitleHint: "Ví dụ: Tri thức cây thuốc trong chăm sóc sức khỏe",
          contentLabel: "Giới thiệu",
          contentHint:
              "Nêu nguồn gốc, bối cảnh văn hóa và cách tri thức này hiện diện trong đời sống người Dao.",
          detailTitle: "Thông tin chi tiết thảo dược",
          detailCategoryLabel: "Nhóm chính",
          detailCategoryHint:
              "Cây dược liệu, Nghề thuốc Nam, Tri thức dân gian...",
          locationLabel: "Địa phương",
          locationHint: "Lào Cai, Hà Giang, vùng núi cao...",
          timeLabel: "",
          timeHint: "",
          mainListLabel: "Đặc điểm nhận dạng",
          mainListHint: "Mỗi dòng: Tên đặc điểm | Mô tả ngắn | ảnh nếu có",
          benefitsLabel: "Vai trò trong đời sống người Dao",
          benefitsHint:
              "Mỗi dòng một ý: dùng trong sinh hoạt, chăm sóc sau lao động, truyền dạy trong gia đình...",
          stepsLabel: "Công dụng theo kinh nghiệm dân gian",
          stepsHint:
              "Mỗi dòng một ý, tránh khẳng định thay thế điều trị y khoa.",
          warningLabel: "Lưu ý",
          warningHint:
              "Ví dụ: Không tự ý dùng cho phụ nữ mang thai, trẻ nhỏ hoặc người có bệnh nền.",
        );
    }
  }

  Map<String, dynamic> _decodeCultureDetail(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return {};
    try {
      final decoded = jsonDecode(text);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      return {};
    }
  }

  String _buildCultureDetailJson({
    required String category,
    required String detailCategory,
    required String location,
    required String timeOrSeason,
    required String tagsText,
    required String benefitsText,
    required String stepsText,
    required String warning,
    required String galleryText,
    required String ingredientsText,
    required String meaningsText,
    required String contentSourcesText,
    required String imageSourcesText,
    required String videoSourcesText,
  }) {
    final isHerbal = category == "Thảo dược";
    final data = <String, dynamic>{
      if (detailCategory.isNotEmpty) 'category': detailCategory,
      if (location.isNotEmpty) 'location': location,
      if (isHerbal && timeOrSeason.isNotEmpty) 'time': timeOrSeason,
      if (!isHerbal && timeOrSeason.isNotEmpty) 'season': timeOrSeason,
      if (warning.isNotEmpty) 'warning': warning,
      if (_linesToList(galleryText).isNotEmpty)
        'gallery': _linesToList(galleryText),
      if (_linesToList(stepsText).isNotEmpty) 'steps': _linesToList(stepsText),
    };
    final sources = <String, dynamic>{
      if (_linesToList(contentSourcesText).isNotEmpty)
        'content': _linesToList(contentSourcesText),
      if (_linesToList(imageSourcesText).isNotEmpty)
        'image': _linesToList(imageSourcesText),
      if (_linesToList(videoSourcesText).isNotEmpty)
        'video': _linesToList(videoSourcesText),
    };
    if (sources.isNotEmpty) data['sources'] = sources;

    if (isHerbal) {
      final culturalValues = _linesToList(tagsText);
      data.addAll({
        if (culturalValues.isNotEmpty) 'cultural_values': culturalValues,
        if (_linesToList(benefitsText).isNotEmpty)
          'benefits': _linesToList(benefitsText),
        if (_detailLinesToRows(ingredientsText).isNotEmpty)
          'ingredients': _detailLinesToRows(ingredientsText),
      });
    } else {
      data.addAll({
        if (_linesToList(benefitsText).isNotEmpty)
          'benefits': _linesToList(benefitsText),
        if (_detailLinesToRows(meaningsText).isNotEmpty)
          'meanings': _detailLinesToRows(meaningsText),
      });
    }

    return jsonEncode(data);
  }

  List<String> _linesToList(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  String _listToLines(dynamic value) {
    if (value is! List) return "";
    return value.map((item) => item.toString()).join("\n");
  }

  String _sourceLines(Map<String, dynamic> detail, String key) {
    final sources = detail['sources'];
    if (sources is Map && sources[key] is List) {
      return _listToLines(sources[key]);
    }
    return _listToLines(detail['${key}_sources']);
  }

  List<Map<String, String>> _detailLinesToRows(String text) {
    return text
        .split('\n')
        .map((line) {
          final parts = line.split('|').map((part) => part.trim()).toList();
          if (parts.isEmpty || parts.first.isEmpty) return <String, String>{};
          return {
            'title': parts[0],
            if (parts.length > 1 && parts[1].isNotEmpty) 'subtitle': parts[1],
            if (parts.length > 1 && parts[1].isNotEmpty) 'note': parts[1],
            if (parts.length > 1 && parts[1].isNotEmpty) 'text': parts[1],
            if (parts.length > 2 && parts[2].isNotEmpty) 'image': parts[2],
          };
        })
        .where((row) => row.isNotEmpty)
        .toList();
  }

  String _detailRowsToLines(dynamic value) {
    if (value is! List) return "";
    return value
        .whereType<Map>()
        .map((item) {
          final row = Map<String, dynamic>.from(item);
          final title = (row['title'] ?? '').toString();
          final note = (row['subtitle'] ?? row['note'] ?? row['text'] ?? '')
              .toString();
          final image = (row['image'] ?? '').toString();
          return [
            title,
            note,
            image,
          ].where((part) => part.isNotEmpty).join(" | ");
        })
        .where((line) => line.trim().isNotEmpty)
        .join("\n");
  }

  void _deleteCultureArticle(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Xóa bài văn hóa?"),
        content: Text(
          "Bạn có chắc chắn muốn xóa '${item['title'] ?? ''}' không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await _deleteCultureArticleById(
                item['id'].toString(),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? "Đã xóa bài viết" : "Không xóa được bài viết",
                  ),
                ),
              );
              if (success) _refreshCultureArticles(_selectedCultureCategory);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMapPlaceDialog({Map<String, dynamic>? item}) {
    String type = item?['type']?.toString() ?? 'village';
    if (!_mapPlaceTypes.containsKey(type)) type = 'village';
    String layerType = item?['layer_type']?.toString() ?? 'culture';
    if (layerType != 'service') layerType = 'culture';

    final nameController = TextEditingController(
      text: item?['name']?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: item?['address']?.toString() ?? '',
    );
    final tagController = TextEditingController(
      text: item?['tag']?.toString() ?? _mapPlaceTypes[type] ?? '',
    );
    final shortController = TextEditingController(
      text: item?['short_description']?.toString() ?? '',
    );
    final culturalController = TextEditingController(
      text: item?['cultural_description']?.toString() ?? '',
    );
    final daoInfoController = TextEditingController(
      text: item?['dao_info']?.toString() ?? '',
    );
    final imageController = TextEditingController(
      text: item?['image_url']?.toString() ?? '',
    );
    final galleryController = TextEditingController(
      text: _galleryUrlsFromRaw(item?['gallery_urls']).join('\n'),
    );
    final latitudeController = TextEditingController(
      text: item?['latitude']?.toString() ?? '',
    );
    final longitudeController = TextEditingController(
      text: item?['longitude']?.toString() ?? '',
    );
    bool hasDirections =
        item?['has_directions'] == null ||
        item?['has_directions'] == true ||
        item?['has_directions']?.toString() == '1';
    bool isActive =
        item?['is_active'] == null ||
        item?['is_active'] == true ||
        item?['is_active']?.toString() == '1';
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<String?> uploadPickedImage() async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 82,
            );
            if (picked == null) return null;
            setDialogState(() => isSaving = true);
            final uploadedUrl = await _uploadMapPlaceImage(picked);
            if (!context.mounted) return null;
            setDialogState(() => isSaving = false);
            if (uploadedUrl == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Không upload được ảnh")),
              );
              return null;
            }
            return uploadedUrl;
          }

          Future<void> pickCoverImage() async {
            final uploadedUrl = await uploadPickedImage();
            if (uploadedUrl == null) return;
            imageController.text = uploadedUrl;
          }

          Future<void> pickGalleryImage() async {
            final uploadedUrl = await uploadPickedImage();
            if (uploadedUrl == null) return;
            final currentGallery = galleryController.text.trim();
            galleryController.text = currentGallery.isEmpty
                ? uploadedUrl
                : "$currentGallery\n$uploadedUrl";
          }

          return AlertDialog(
            title: Text(item == null ? "Thêm địa điểm bản đồ" : "Sửa địa điểm"),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Tên địa điểm *",
                      ),
                    ),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: "Địa chỉ"),
                    ),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: "Loại địa điểm",
                      ),
                      items: _mapPlaceTypes.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          type = value;
                          tagController.text = _mapPlaceTypes[value] ?? '';
                        });
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: layerType,
                      decoration: const InputDecoration(labelText: "Nhóm"),
                      items: const [
                        DropdownMenuItem(
                          value: 'culture',
                          child: Text("Văn hóa"),
                        ),
                        DropdownMenuItem(
                          value: 'service',
                          child: Text("Dịch vụ"),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => layerType = value);
                        }
                      },
                    ),
                    TextField(
                      controller: tagController,
                      decoration: const InputDecoration(labelText: "Nhãn"),
                    ),
                    TextField(
                      controller: latitudeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Latitude *",
                      ),
                    ),
                    TextField(
                      controller: longitudeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Longitude *",
                      ),
                    ),
                    TextField(
                      controller: shortController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Mô tả ngắn",
                      ),
                    ),
                    TextField(
                      controller: culturalController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Nội dung chi tiết",
                      ),
                    ),
                    TextField(
                      controller: daoInfoController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Thông tin văn hóa Dao",
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: imageController,
                            decoration: const InputDecoration(
                              labelText: "Ảnh đại diện URL",
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: isSaving ? null : pickCoverImage,
                          icon: const Icon(Icons.image_rounded),
                          tooltip: "Chọn ảnh đại diện",
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: galleryController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: "Hình ảnh chi tiết",
                              hintText: "Mỗi dòng một URL ảnh",
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: isSaving ? null : pickGalleryImage,
                          icon: const Icon(Icons.add_photo_alternate_rounded),
                          tooltip: "Thêm ảnh chi tiết",
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      value: hasDirections,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Cho phép chỉ đường"),
                      onChanged: (value) {
                        setDialogState(() => hasDirections = value ?? true);
                      },
                    ),
                    CheckboxListTile(
                      value: isActive,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Hiển thị trên bản đồ"),
                      onChanged: (value) {
                        setDialogState(() => isActive = value ?? true);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: darkBlue),
                onPressed: isSaving
                    ? null
                    : () async {
                        final latitude = double.tryParse(
                          latitudeController.text.trim().replaceAll(',', '.'),
                        );
                        final longitude = double.tryParse(
                          longitudeController.text.trim().replaceAll(',', '.'),
                        );
                        if (nameController.text.trim().isEmpty ||
                            latitude == null ||
                            longitude == null ||
                            latitude < 8 ||
                            latitude > 24 ||
                            longitude < 102 ||
                            longitude > 110) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Tọa độ phải nằm trong Việt Nam: latitude 8-24, longitude 102-110",
                              ),
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        final galleryUrls = _galleryUrlsFromRaw(
                          galleryController.text,
                        );
                        final imageUrl = imageController.text.trim();
                        final normalizedGallery =
                            <String>[
                                  if (imageUrl.isNotEmpty) imageUrl,
                                  ...galleryUrls,
                                ]
                                .where((url) => url.trim().isNotEmpty)
                                .toSet()
                                .toList();
                        final result = await _saveMapPlace(
                          id: item?['id']?.toString(),
                          name: nameController.text.trim(),
                          address: addressController.text.trim(),
                          shortDescription: shortController.text.trim(),
                          culturalDescription: culturalController.text.trim(),
                          daoInfo: daoInfoController.text.trim(),
                          tag: tagController.text.trim(),
                          type: type,
                          layerType: layerType,
                          imageUrl: imageUrl,
                          galleryUrls: normalizedGallery,
                          latitude: latitude,
                          longitude: longitude,
                          hasDirections: hasDirections,
                          isActive: isActive,
                        );
                        if (!context.mounted) return;
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(result.message)));
                        if (result.success) {
                          Navigator.pop(dialogContext);
                          _refreshMapPlaces();
                        }
                      },
                child: Text(
                  isSaving ? "Đang lưu..." : "Lưu",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteMapPlace(Map<String, dynamic> item) {
    final isLocalFallback = item['_local_fallback'] == true;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Xóa địa điểm?"),
        content: Text(
          "Bạn có chắc chắn muốn xóa '${item['name'] ?? ''}' khỏi bản đồ không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (isLocalFallback) {
                final name = item['name']?.toString().trim().toLowerCase();
                if (name != null && name.isNotEmpty) {
                  _hiddenLocalMapPlaceNames.add(name);
                }
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã ẩn địa điểm gợi ý A Mé")),
                );
                _refreshMapPlaces();
                return;
              }
              final success = await _deleteMapPlaceById(item['id'].toString());
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? "Đã xóa địa điểm" : "Không xóa được địa điểm",
                  ),
                ),
              );
              if (success) _refreshMapPlaces();
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildModerationTab() {
    return Column(
      children: [
        _buildSectionHeader(
          icon: Icons.shield,
          title: "Kiểm duyệt Nội dung",
          subtitle: "Quản lý bài viết trong cộng đồng",
        ),
        const SizedBox(height: 15),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return const Center(
                  child: Text(
                    "Cộng đồng đang sạch sẽ!",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _refreshCurrentTab(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final data = posts[index] as Map<String, dynamic>;
                    final postId = data['id'].toString();
                    final author =
                        data['author_name'] ??
                        data['username'] ??
                        data['full_name'] ??
                        "Khách";
                    final content = data['content']?.toString() ?? "";
                    final createdAt = data['created_at']?.toString() ?? "";
                    final reactions =
                        (data['reaction_count'] ?? data['like_count'] ?? 0)
                            .toString();
                    final comments = (data['comment_count'] ?? 0).toString();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: darkBlue.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Icon(Icons.person, color: darkBlue),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        author.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        createdAt.isNotEmpty
                                            ? createdAt
                                            : "Vừa xong",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deletePost(context, postId),
                                ),
                              ],
                            ),
                            if (content.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                content,
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  height: 1.45,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            _buildAdminPostMediaPreview(data),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildAdminPostStat(
                                  Icons.favorite_rounded,
                                  reactions,
                                  const Color(0xFFE53935),
                                ),
                                const SizedBox(width: 14),
                                _buildAdminPostStat(
                                  Icons.mode_comment_rounded,
                                  comments,
                                  const Color(0xFF2F7DD3),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () =>
                                      _showPostCommentsDialog(postId, content),
                                  icon: const Icon(Icons.forum_rounded),
                                  label: const Text("Bình luận"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: darkBlue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPostCommentsDialog(String postId, String postContent) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Bình luận bài viết"),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<dynamic>>(
            future: ApiService.getComments(postId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final comments = snapshot.data ?? [];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (postContent.trim().isNotEmpty) ...[
                    Text(
                      postContent,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 24),
                  ],
                  if (comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text("Bài viết chưa có bình luận")),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final comment =
                              comments[index] as Map<String, dynamic>;
                          final commentId = comment['id']?.toString() ?? "";
                          final author =
                              comment['author_name']?.toString() ??
                              comment['user_name']?.toString() ??
                              "Người dùng";
                          final text =
                              comment['content']?.toString() ??
                              comment['text']?.toString() ??
                              "";
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              author,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(text),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: commentId.isEmpty
                                  ? null
                                  : () async {
                                      final success = await _deleteCommentById(
                                        commentId,
                                      );
                                      if (!dialogContext.mounted || !mounted) {
                                        return;
                                      }
                                      Navigator.pop(dialogContext);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? "Đã xóa bình luận"
                                                : "Không xóa được bình luận",
                                          ),
                                        ),
                                      );
                                      if (success) _refreshCurrentTab();
                                    },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPostMediaPreview(Map<String, dynamic> data) {
    final mediaType = data['media_type']?.toString().toLowerCase() ?? "";
    final urls = _adminPostMediaUrls(data, mediaType: mediaType);
    if (urls.isEmpty && mediaType != "video") {
      return const SizedBox.shrink();
    }

    final firstUrl = urls.isNotEmpty ? urls.first : "";
    final isVideo =
        mediaType == "video" ||
        firstUrl.toLowerCase().endsWith(".mp4") ||
        firstUrl.toLowerCase().contains("video");

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 190,
          width: double.infinity,
          color: const Color(0xFFF1F5F9),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (firstUrl.isNotEmpty && isVideo)
                _AdminReportVideo(url: firstUrl)
              else if (firstUrl.isNotEmpty)
                Image.network(
                  firstUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _buildAdminMediaFallback(isVideo),
                )
              else
                _buildAdminMediaFallback(isVideo),
              if (isVideo && firstUrl.isEmpty)
                Center(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.52),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
              if (urls.length > 1)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      "+${urls.length - 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminMediaFallback(bool isVideo) {
    return Center(
      child: Icon(
        isVideo ? Icons.videocam_rounded : Icons.image_rounded,
        color: Colors.grey.shade500,
        size: 48,
      ),
    );
  }

  Widget _buildAdminPostStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  List<String> _adminPostMediaUrls(
    Map<String, dynamic> data, {
    required String mediaType,
  }) {
    final urls = <String>[];
    for (final key in ['image_url', 'media_url', 'video_url']) {
      final value = data[key]?.toString().trim() ?? "";
      final normalized = _normalizeAdminPostMediaUrl(
        value,
        isVideo:
            key == 'video_url' || (key == 'media_url' && mediaType == 'video'),
      );
      if (normalized.isNotEmpty) urls.add(normalized);
    }

    final rawGallery =
        data['media_urls'] ?? data['gallery'] ?? data['gallery_urls'];
    if (rawGallery is List) {
      urls.addAll(
        rawGallery.map(
          (e) => _normalizeAdminPostMediaUrl(
            e.toString(),
            isVideo: mediaType == 'video',
          ),
        ),
      );
    } else if (rawGallery is String && rawGallery.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawGallery);
        if (decoded is List) {
          urls.addAll(
            decoded.map(
              (e) => _normalizeAdminPostMediaUrl(
                e.toString(),
                isVideo: mediaType == 'video',
              ),
            ),
          );
        }
      } catch (_) {
        urls.addAll(
          rawGallery
              .split(RegExp(r'[\s,;|]+'))
              .map(
                (e) => _normalizeAdminPostMediaUrl(
                  e,
                  isVideo: mediaType == 'video',
                ),
              ),
        );
      }
    }

    return urls.where((url) => url.isNotEmpty).toSet().toList();
  }

  String _normalizeAdminPostMediaUrl(String value, {required bool isVideo}) {
    final raw = value.trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') return '';

    final serverUrl = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final parsed = Uri.tryParse(raw);
    final path = parsed?.path ?? raw;
    final fileName = path.split('/').where((part) => part.isNotEmpty).last;
    if ((raw.startsWith('http://') || raw.startsWith('https://')) &&
        path.contains('/storage/uploads/posts/') &&
        fileName.isNotEmpty) {
      final endpoint = isVideo ? 'video.php' : 'image.php';
      return '${ApiService.baseUrl}/posts/$endpoint?file=${Uri.encodeComponent(fileName)}';
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    if (raw.startsWith('//')) return 'http:$raw';
    if (raw.startsWith('/')) return '$serverUrl$raw';
    if (raw.startsWith('uploads/posts/')) {
      final endpoint = isVideo ? 'video.php' : 'image.php';
      return '${ApiService.baseUrl}/posts/$endpoint?file=${Uri.encodeComponent(fileName)}';
    }
    if (raw.startsWith('api/') ||
        raw.startsWith('storage/') ||
        raw.startsWith('uploads/')) {
      return raw.startsWith('uploads/')
          ? '$serverUrl/storage/$raw'
          : '$serverUrl/$raw';
    }

    final endpoint = isVideo ? 'video.php' : 'image.php';
    return '${ApiService.baseUrl}/posts/$endpoint?file=${Uri.encodeComponent(fileName)}';
  }

  String _userField(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? "";
      if (value.isNotEmpty && value.toLowerCase() != "null") return value;
    }
    return "";
  }

  bool _isUserLocked(Map<String, dynamic> data) {
    final raw = _userField(data, [
      'is_locked',
      'locked',
      'is_blocked',
      'blocked',
      'status',
      'account_status',
      'is_active',
    ]).toLowerCase();
    if (raw.isEmpty) return false;
    if ([
      '1',
      'true',
      'locked',
      'blocked',
      'banned',
      'disabled',
    ].contains(raw)) {
      return true;
    }
    if (['0', 'false', 'active', 'enabled'].contains(raw)) return false;
    if (raw == 'inactive' && data.containsKey('is_active')) return true;
    return false;
  }

  String _userDisplayName(Map<String, dynamic> data) {
    final value = _userField(data, ['full_name', 'name', 'username', 'email']);
    return value.isEmpty ? "Chưa rõ tài khoản" : value;
  }

  String _userSubtitle(Map<String, dynamic> data) {
    final parts = <String>[];
    final id = _userField(data, ['id', 'user_id']);
    final username = _userField(data, ['username']);
    final email = _userField(data, ['email']);
    if (id.isNotEmpty) parts.add("ID: $id");
    if (username.isNotEmpty) parts.add(username);
    if (email.isNotEmpty && email != username) parts.add(email);
    return parts.isEmpty ? "Không có thông tin bổ sung" : parts.join(" • ");
  }

  Future<void> _toggleUserLock(Map<String, dynamic> user) async {
    final userId = _userField(user, ['id', 'user_id']);
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không tìm thấy ID người dùng")),
      );
      return;
    }

    final locked = _isUserLocked(user);
    final displayName = _userDisplayName(user);
    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(locked ? "Mở lại tài khoản?" : "Khóa tài khoản?"),
        content: Text(
          locked
              ? "Cho phép '$displayName' đăng nhập và sử dụng lại ứng dụng?"
              : "Tài khoản '$displayName' sẽ không thể đăng nhập sau khi bị khóa.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: locked ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: Icon(
              locked ? Icons.lock_open_rounded : Icons.lock_rounded,
              color: Colors.white,
            ),
            label: Text(
              locked ? "Mở lại" : "Khóa",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (shouldUpdate != true) return;

    final result = await ApiService.setUserLocked(
      userId: userId,
      locked: !locked,
    );
    if (!mounted) return;
    final success = result['status'] == 'success';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (locked ? "Đã mở lại tài khoản" : "Đã khóa tài khoản")
              : (result['message']?.toString() ?? "Không cập nhật được"),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    if (success) _refreshCurrentTab();
  }

  void _showUserDetails(Map<String, dynamic> user) {
    final role = _userField(user, ['role']).toLowerCase();
    final isAdmin = role == 'admin';
    final locked = _isUserLocked(user);
    final displayName = _userDisplayName(user);
    final createdAt = _userField(user, ['created_at', 'createdAt', 'created']);
    final fullName = _userField(user, ['full_name', 'name']);
    final username = _userField(user, ['username']);
    final email = _userField(user, ['email']);
    final phone = _userField(user, ['phone', 'phone_number']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: locked
                        ? Colors.red.shade50
                        : isAdmin
                        ? Colors.indigo.shade50
                        : Colors.green.shade50,
                    child: Icon(
                      locked
                          ? Icons.lock_rounded
                          : isAdmin
                          ? Icons.admin_panel_settings_rounded
                          : Icons.person_rounded,
                      color: locked
                          ? Colors.red
                          : isAdmin
                          ? darkBlue
                          : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          locked
                              ? "Tài khoản đang bị khóa"
                              : "Tài khoản chưa bị khóa",
                          style: TextStyle(
                            color: locked ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildUserInfoRow("ID", _userField(user, ['id', 'user_id'])),
              _buildUserInfoRow("Họ tên", fullName),
              _buildUserInfoRow("Tên đăng nhập", username),
              _buildUserInfoRow("Email", email),
              _buildUserInfoRow("Số điện thoại", phone),
              _buildUserInfoRow(
                "Vai trò",
                isAdmin ? "Quản trị viên" : "Người dùng",
              ),
              _buildUserInfoRow("Ngày tạo", createdAt),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: locked ? Colors.green : Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: isAdmin
                      ? null
                      : () {
                          Navigator.pop(sheetContext);
                          _toggleUserLock(user);
                        },
                  icon: Icon(
                    locked ? Icons.lock_open_rounded : Icons.lock_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    isAdmin
                        ? "Không khóa tài khoản admin"
                        : locked
                        ? "Mở lại tài khoản"
                        : "Khóa tài khoản",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTab() {
    return Column(
      children: [
        _buildSectionHeader(
          icon: Icons.people_alt,
          title: "Quản lý Người dùng",
          subtitle: "Xem thông tin, khóa hoặc mở lại tài khoản người dùng",
        ),
        const SizedBox(height: 15),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _usersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final users = (snapshot.data ?? [])
                  .whereType<Map<String, dynamic>>()
                  .toList();
              if (users.isEmpty) {
                return const Center(
                  child: Text(
                    "Chưa có dữ liệu người dùng",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _refreshCurrentTab(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data = users[index];
                    final String role = _userField(data, [
                      'role',
                    ]).toLowerCase();
                    final bool isAdmin = role == 'admin';
                    final bool locked = _isUserLocked(data);
                    final String displayName = _userDisplayName(data);
                    final Color statusColor = locked
                        ? Colors.red
                        : Colors.green;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: locked
                              ? Colors.red.shade50
                              : isAdmin
                              ? Colors.red.shade100
                              : Colors.blue.shade100,
                          child: Icon(
                            locked
                                ? Icons.lock_rounded
                                : isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            color: locked
                                ? Colors.red
                                : isAdmin
                                ? Colors.red
                                : Colors.blue,
                          ),
                        ),
                        title: Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userSubtitle(data),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    avatar: Icon(
                                      locked
                                          ? Icons.lock_rounded
                                          : Icons.check_circle_rounded,
                                      size: 15,
                                      color: statusColor,
                                    ),
                                    label: Text(
                                      locked ? "Đã khóa" : "Chưa khóa",
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(
                                      isAdmin ? "ADMIN" : "USER",
                                      style: TextStyle(
                                        color: isAdmin
                                            ? Colors.red
                                            : Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: "Xem chi tiết",
                              icon: Icon(
                                Icons.visibility_outlined,
                                color: darkBlue,
                              ),
                              onPressed: () => _showUserDetails(data),
                            ),
                            IconButton(
                              tooltip: locked
                                  ? "Mở lại tài khoản"
                                  : "Khóa tài khoản",
                              icon: Icon(
                                locked
                                    ? Icons.lock_open_rounded
                                    : Icons.lock_rounded,
                                color: isAdmin
                                    ? Colors.grey
                                    : locked
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              onPressed: isAdmin
                                  ? null
                                  : () => _toggleUserLock(data),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        _buildSectionHeader(
          icon: Icons.report,
          title: "Báo cáo Vi phạm",
          subtitle: "Ẩn bài vi phạm và cấm đăng tạm thời khi cần",
        ),
        const SizedBox(height: 15),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _reportsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final reports = snapshot.data ?? [];
              if (reports.isEmpty) {
                return const Center(child: Text("Chưa có báo cáo vi phạm"));
              }

              return RefreshIndicator(
                onRefresh: () async => _refreshCurrentTab(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index] as Map<String, dynamic>;
                    final postContent =
                        report['post_content']?.toString().trim() ?? "";
                    final reason =
                        (report['reason'] ??
                                report['report_reason'] ??
                                report['description'] ??
                                report['message'] ??
                                report['content'])
                            ?.toString()
                            .trim() ??
                        "";
                    final reporterName =
                        report['reporter_name'] ??
                        report['user_id'] ??
                        'Ẩn danh';
                    final authorName =
                        report['author_name'] ??
                        report['post_author_id'] ??
                        'Không rõ';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Lý do vi phạm: ${reason.isEmpty ? 'Không rõ' : reason}",
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Người báo cáo: $reporterName",
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Bài viết bị báo cáo",
                              style: TextStyle(
                                color: darkBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Tác giả: $authorName",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    postContent.isEmpty
                                        ? "Bài viết không còn nội dung hoặc đã bị xóa."
                                        : postContent,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.35,
                                    ),
                                  ),
                                  _buildAdminPostMediaPreview(report),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _handleReportAction(
                                    context,
                                    report,
                                    banDays: 0,
                                    hidePost: false,
                                  ),
                                  child: const Text("Bỏ qua"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                  onPressed: () => _handleReportAction(
                                    context,
                                    report,
                                    banDays: 0,
                                    hidePost: true,
                                  ),
                                  child: const Text(
                                    "Ẩn bài",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => _handleReportAction(
                                    context,
                                    report,
                                    banDays: 3,
                                    hidePost: true,
                                  ),
                                  child: const Text(
                                    "Ẩn + cấm 3 ngày",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackTab() {
    return Column(
      children: [
        _buildSectionHeader(
          icon: Icons.feedback,
          title: "Góp ý Người dùng",
          subtitle: "Xem phản hồi gửi từ cộng đồng",
        ),
        const SizedBox(height: 15),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _feedbacksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final feedbacks = snapshot.data ?? [];
              if (feedbacks.isEmpty) {
                return const Center(child: Text("Chưa có góp ý"));
              }

              return RefreshIndicator(
                onRefresh: () async => _refreshCurrentTab(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    final data = feedbacks[index] as Map<String, dynamic>;
                    final name =
                        data['user_name'] ??
                        data['username'] ??
                        data['user_id'] ??
                        "Người dùng";
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: darkBlue.withValues(alpha: 0.1),
                          child: Icon(Icons.chat_bubble, color: darkBlue),
                        ),
                        title: Text(
                          name.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(data['content']?.toString() ?? ""),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopicTab() {
    return Column(
      children: [
        _buildSectionHeader(
          icon: Icons.category,
          title: "Quản lý Danh mục",
          subtitle: "Thêm, sửa, xóa chủ đề học tập",
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: darkBlue),
              onPressed: () => _showTopicDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Thêm danh mục",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: FutureBuilder<List<Topic>>(
            future: _topicsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final topics = snapshot.data ?? [];
              if (topics.isEmpty) {
                return const Center(child: Text("Chưa có danh mục"));
              }

              return RefreshIndicator(
                onRefresh: () async => _refreshCurrentTab(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: darkBlue.withValues(alpha: 0.1),
                          child: Icon(Icons.folder, color: darkBlue),
                        ),
                        title: Text(
                          topic.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("ID: ${topic.id}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showTopicDialog(topic: topic),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteTopic(topic),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVocabularyTab() {
    return FutureBuilder<List<Topic>>(
      future: _topicsFuture,
      builder: (context, topicSnapshot) {
        if (topicSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final topics = topicSnapshot.data ?? [];
        if (topics.isEmpty) {
          return Column(
            children: [
              _buildSectionHeader(
                icon: Icons.translate,
                title: "Quản lý Từ điển",
                subtitle: "Cần có danh mục trước khi thêm từ vựng",
              ),
              const Expanded(child: Center(child: Text("Chưa có danh mục"))),
            ],
          );
        }

        final hasSelectedTopic = topics.any(
          (topic) => int.parse(topic.id) == _selectedTopicId,
        );
        if (_selectedTopicId == null || !hasSelectedTopic) {
          _selectedTopicId = int.parse(topics.first.id);
          _vocabularyFuture = ApiService.getVocabularyByTopic(
            _selectedTopicId!,
          );
        }

        return Column(
          children: [
            _buildSectionHeader(
              icon: Icons.translate,
              title: "Quản lý Từ điển",
              subtitle: "Thêm, sửa, xóa từ vựng tiếng Dao",
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
              child: DropdownButtonFormField<int>(
                value: _selectedTopicId,
                decoration: const InputDecoration(
                  labelText: "Chọn danh mục",
                  border: OutlineInputBorder(),
                ),
                items: topics
                    .map(
                      (topic) => DropdownMenuItem(
                        value: int.parse(topic.id),
                        child: Text(topic.title),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _refreshVocabulary(value);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: darkBlue),
                  onPressed: () => _showVocabularyDialog(topics: topics),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Thêm từ vựng",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _vocabularyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final words = snapshot.data ?? [];
                  if (words.isEmpty) {
                    return const Center(child: Text("Chưa có từ vựng"));
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      if (_selectedTopicId != null) {
                        _refreshVocabulary(_selectedTopicId!);
                      }
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: words.length,
                      itemBuilder: (context, index) {
                        final item = words[index] as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: darkBlue.withValues(alpha: 0.1),
                              child: Icon(Icons.menu_book, color: darkBlue),
                            ),
                            title: Text(
                              item['dao_word']?.toString() ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text("Nghĩa: ${item['viet_word'] ?? ''}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showVocabularyDialog(
                                    item: item,
                                    topics: topics,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteVocabulary(item),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCultureArticlesTab() {
    return Column(
      children: [
        _buildSectionHeader(
          icon: Icons.auto_stories,
          title: "Quản lý Văn hóa",
          subtitle:
              "Thêm, sửa bài cho Trang phục, Lễ hội, Phong tục, Thảo dược",
        ),
        _buildCultureStats(),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: darkBlue),
              onPressed: () => _showCultureArticleDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                "Thêm bài $_selectedCultureCategory",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _cultureArticlesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final articles = snapshot.data ?? [];
              if (articles.isEmpty) {
                return Center(
                  child: Text(
                    "Chưa có bài $_selectedCultureCategory",
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    _refreshCultureArticles(_selectedCultureCategory),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final item = articles[index] as Map<String, dynamic>;
                    final subtitle = item['subtitle']?.toString() ?? "";
                    final content = item['content']?.toString() ?? "";
                    final isFeatured =
                        item['is_featured'] == true ||
                        item['is_featured']?.toString() == '1';
                    final viewCount =
                        int.tryParse(item['view_count']?.toString() ?? '') ?? 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: CircleAvatar(
                          backgroundColor: darkBlue.withValues(alpha: 0.1),
                          child: Icon(Icons.article, color: darkBlue),
                        ),
                        title: Text(
                          item['title']?.toString() ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subtitle.isNotEmpty ? subtitle : content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (isFeatured)
                                    const Chip(
                                      label: Text("Đang ghim"),
                                      avatar: Icon(
                                        Icons.push_pin_rounded,
                                        size: 15,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  Chip(
                                    label: Text("$viewCount lượt xem"),
                                    avatar: const Icon(
                                      Icons.visibility_outlined,
                                      size: 15,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _showCultureArticleDialog(item: item),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteCultureArticle(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCultureStats() {
    return FutureBuilder<List<dynamic>>(
      future: _cultureStatsFuture,
      builder: (context, snapshot) {
        final articles = snapshot.data ?? const <dynamic>[];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _cultureCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _cultureCategories[index];
                final count = isLoading
                    ? null
                    : _cultureArticleCount(articles, category);
                return _buildCultureStatCard(
                  category,
                  count,
                  selected: category == _selectedCultureCategory,
                  onTap: () => _refreshCultureArticles(category),
                );
              },
            ),
          ),
        );
      },
    );
  }

  int _cultureArticleCount(List<dynamic> articles, String category) {
    return articles.where((article) {
      if (article is! Map) return false;
      return (article['category'] ?? '').toString().trim() == category;
    }).length;
  }

  Widget _buildCultureStatCard(
    String category,
    int? count, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    final icon = switch (category) {
      "Trang phục" => Icons.dry_cleaning_rounded,
      "Lễ hội" => Icons.festival_rounded,
      "Phong tục" => Icons.groups_3_rounded,
      "Thảo dược" => Icons.eco_rounded,
      _ => Icons.library_books_rounded,
    };
    final accentColor = switch (category) {
      "Trang phục" => const Color(0xFFC93A4A),
      "Lễ hội" => const Color(0xFFE07818),
      "Phong tục" => const Color(0xFF8A5A32),
      "Thảo dược" => const Color(0xFF2E8B57),
      _ => const Color(0xFFD93829),
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 136,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accentColor : accentColor.withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: selected ? 0.24 : 0.08),
              blurRadius: selected ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.18)
                    : accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : accentColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.grey.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    count == null ? "..." : "$count",
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF111827),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 45, color: darkBlue),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildMapPlacesTab() {
    return Column(
      children: [
        _buildSectionHeader(
          icon: Icons.map_rounded,
          title: "Địa điểm bản đồ",
          subtitle: "Thêm địa điểm văn hóa, lễ hội, dịch vụ gần người dùng",
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: darkBlue),
              onPressed: () => _showMapPlaceDialog(),
              icon: const Icon(Icons.add_location_alt, color: Colors.white),
              label: const Text(
                "Thêm địa điểm bản đồ",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _mapPlacesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final places = (snapshot.data ?? [])
                  .whereType<Map<String, dynamic>>()
                  .toList();
              if (places.isEmpty) {
                return const Center(
                  child: Text(
                    "Chưa có địa điểm bản đồ",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _refreshMapPlaces(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: places.length,
                  itemBuilder: (context, index) {
                    final item = places[index];
                    final galleryUrls = _galleryUrlsFromRaw(
                      item['gallery_urls'],
                    );
                    final imageUrl =
                        (item['image_url']?.toString().trim().isNotEmpty ??
                            false)
                        ? item['image_url'].toString().trim()
                        : (galleryUrls.isNotEmpty ? galleryUrls.first : '');
                    final typeLabel =
                        _mapPlaceTypes[item['type']?.toString()] ??
                        (item['tag']?.toString() ?? 'Địa điểm');
                    final isLocalFallback = item['_local_fallback'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageUrl.trim().isEmpty
                              ? Container(
                                  width: 58,
                                  height: 58,
                                  color: const Color(0xFFE8F1FF),
                                  child: Icon(
                                    Icons.place_rounded,
                                    color: darkBlue,
                                  ),
                                )
                              : Image.network(
                                  imageUrl,
                                  width: 58,
                                  height: 58,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 58,
                                    height: 58,
                                    color: const Color(0xFFE8F1FF),
                                    child: Icon(
                                      Icons.place_rounded,
                                      color: darkBlue,
                                    ),
                                  ),
                                ),
                        ),
                        title: Text(
                          item['name']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              "$typeLabel • ${item['address'] ?? ''}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isLocalFallback
                                  ? "Gợi ý có sẵn - bấm sửa rồi lưu để đưa lên backend"
                                  : "Tọa độ: ${item['latitude']}, ${item['longitude']}",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showMapPlaceDialog(item: item),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteMapPlace(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedTab() {
    switch (_selectedIndex) {
      case 0:
        return _buildModerationTab();
      case 1:
        return _buildUserTab();
      case 2:
        return _buildReportsTab();
      case 3:
        return _buildFeedbackTab();
      case 4:
        return _buildTopicTab();
      case 5:
        return _buildVocabularyTab();
      case 6:
        return _buildCultureArticlesTab();
      case 7:
        return _buildMapPlacesTab();
      default:
        return _buildModerationTab();
    }
  }

  List<_AdminMenuItem> get _adminMenuItems => const [
    _AdminMenuItem(Icons.shield_outlined, "Bài viết"),
    _AdminMenuItem(Icons.people_outline, "Người dùng"),
    _AdminMenuItem(Icons.report_outlined, "Báo cáo"),
    _AdminMenuItem(Icons.feedback_outlined, "Góp ý"),
    _AdminMenuItem(Icons.category_outlined, "Danh mục"),
    _AdminMenuItem(Icons.translate_outlined, "Từ điển"),
    _AdminMenuItem(Icons.auto_stories_outlined, "Văn hóa"),
    _AdminMenuItem(Icons.map_outlined, "Bản đồ"),
  ];

  Widget _buildAdminDrawer() {
    final items = _adminMenuItems;
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.74,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(22)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              22,
              MediaQuery.of(context).padding.top + 26,
              22,
              26,
            ),
            decoration: BoxDecoration(
              color: darkBlue,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Quản trị hệ thống",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Chọn mục quản lý",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = index == _selectedIndex;
                return ListTile(
                  selected: selected,
                  selectedTileColor: darkBlue.withValues(alpha: 0.08),
                  leading: Icon(
                    item.icon,
                    color: selected ? darkBlue : const Color(0xFF667085),
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: selected ? darkBlue : const Color(0xFF1F2937),
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                  trailing: selected
                      ? Icon(Icons.chevron_right_rounded, color: darkBlue)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = index);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text(
                "Đăng xuất",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openAdminDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminGuardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != true) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 70, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Bạn không có quyền truy cập trang quản trị."),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text("Quay lại đăng nhập"),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildAdminScaffold();
      },
    );
  }

  Widget _buildAdminScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      drawer: _buildAdminDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: "Menu quản trị",
            onPressed: () => _openAdminDrawer(context),
          ),
        ),
        title: const Text(
          "Quản trị hệ thống",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: darkBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildSelectedTab(),
    );
  }
}

class _AdminMenuItem {
  final IconData icon;
  final String label;

  const _AdminMenuItem(this.icon, this.label);
}

class _AdminReportVideo extends StatefulWidget {
  final String url;

  const _AdminReportVideo({required this.url});

  @override
  State<_AdminReportVideo> createState() => _AdminReportVideoState();
}

class _AdminReportVideoState extends State<_AdminReportVideo> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initializeFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !_controller.value.isInitialized) {
          return const Center(
            child: Icon(
              Icons.videocam_off_rounded,
              color: Colors.grey,
              size: 48,
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            setState(() {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
              if (!_controller.value.isPlaying)
                const Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CultureFormLabels {
  final String titleLabel;
  final String titleHint;
  final String subtitleHint;
  final String contentLabel;
  final String contentHint;
  final String detailTitle;
  final String detailCategoryLabel;
  final String detailCategoryHint;
  final String locationLabel;
  final String locationHint;
  final String timeLabel;
  final String timeHint;
  final String mainListLabel;
  final String mainListHint;
  final String benefitsLabel;
  final String benefitsHint;
  final String stepsLabel;
  final String stepsHint;
  final String warningLabel;
  final String warningHint;

  const _CultureFormLabels({
    required this.titleLabel,
    required this.titleHint,
    required this.subtitleHint,
    required this.contentLabel,
    required this.contentHint,
    required this.detailTitle,
    required this.detailCategoryLabel,
    required this.detailCategoryHint,
    required this.locationLabel,
    required this.locationHint,
    required this.timeLabel,
    required this.timeHint,
    required this.mainListLabel,
    required this.mainListHint,
    required this.benefitsLabel,
    required this.benefitsHint,
    required this.stepsLabel,
    required this.stepsHint,
    required this.warningLabel,
    required this.warningHint,
  });
}

class _CultureSaveResult {
  final bool success;
  final String message;

  const _CultureSaveResult._({required this.success, required this.message});

  const _CultureSaveResult.success()
    : this._(success: true, message: "Đã lưu bài viết");

  const _CultureSaveResult.error(String message)
    : this._(success: false, message: message);
}

class _MapPlaceSaveResult {
  final bool success;
  final String message;

  const _MapPlaceSaveResult._({required this.success, required this.message});

  const _MapPlaceSaveResult.success()
    : this._(success: true, message: "Đã lưu địa điểm");

  const _MapPlaceSaveResult.error(String message)
    : this._(success: false, message: message);
}
