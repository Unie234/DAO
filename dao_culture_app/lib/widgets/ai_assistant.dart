import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart'; // 🟢 Nhớ chạy: flutter pub add flutter_tts
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/culture_article_service.dart';
import '../services/culture_share_service.dart';
import '../screens/culture_detail_screen.dart';
import '../screens/customs_screen.dart';
import '../screens/festival_screen.dart';
import '../screens/herbal_knowledge_screen.dart';
import '../screens/traditional_costume_screen.dart';

class DraggableAiAssistant extends StatefulWidget {
  const DraggableAiAssistant({super.key});
  @override
  State<DraggableAiAssistant> createState() => _DraggableAiAssistantState();
}

class _DraggableAiAssistantState extends State<DraggableAiAssistant>
    with SingleTickerProviderStateMixin {
  Offset? position;
  String currentLanguage = "Tiếng Việt";
  final FlutterTts flutterTts = FlutterTts();
  static const MethodChannel _speechChannel = MethodChannel(
    'dao_culture_app/speech',
  );
  AnimationController? _assistantAnimationController;
  Animation<double>? _assistantFloatAnimation;
  bool _isDragging = false;
  static const double _assistantWidth = 108;
  static const double _assistantHeight = 142;
  static const double _bottomBarClearance = 74;
  static const String _chatHistoryPrefix = 'ai_chat_history_';
  List<Map<String, String>> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _startAssistantAnimation();
    _loadLanguageSetting();
    _loadChatHistory();
    // Cấu hình giọng nói
    flutterTts.setLanguage("vi-VN");
    flutterTts.setSpeechRate(0.5);
  }

  void _startAssistantAnimation() {
    if (_assistantAnimationController != null) return;
    _assistantAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _assistantFloatAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(
        parent: _assistantAnimationController!,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    _assistantAnimationController?.dispose();
    super.dispose();
  }

  Future<void> _loadLanguageSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(
      () => currentLanguage = prefs.getString('ai_language') ?? "Tiếng Việt",
    );
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = _chatHistoryKeyFor(prefs);
    if (historyKey == null) {
      _chatMessages = [];
      return;
    }

    final savedHistory = prefs.getString(historyKey);
    if (savedHistory == null || savedHistory.isEmpty) {
      _chatMessages = [];
      return;
    }

    try {
      final decoded = jsonDecode(savedHistory);
      if (decoded is List) {
        _chatMessages = decoded
            .whereType<Map>()
            .map(
              (item) => {
                "role": (item["role"] ?? "").toString(),
                "text": (item["text"] ?? "").toString(),
                if ((item["related_articles"] ?? "").toString().isNotEmpty)
                  "related_articles": (item["related_articles"] ?? "")
                      .toString(),
              },
            )
            .where(
              (item) => item["role"]!.isNotEmpty && item["text"]!.isNotEmpty,
            )
            .toList();
      }
    } catch (_) {
      _chatMessages = [];
    }
  }

  Future<void> _saveChatHistory(List<Map<String, String>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = _chatHistoryKeyFor(prefs);
    if (historyKey == null) return;

    await prefs.setString(historyKey, jsonEncode(messages));
  }

  String? _chatHistoryKeyFor(SharedPreferences prefs) {
    final userId = prefs.getString('user_id') ?? '';
    return '$_chatHistoryPrefix${userId.isEmpty ? 'guest' : userId}';
  }

  String _defaultGreeting(bool isVN) {
    return isVN
        ? "Chào bạn! Mình có vài gợi ý từ các bài viết văn hóa trong app, bạn có thể chọn một câu hoặc nhập câu hỏi riêng nhé."
        : "Mản chài! Kéo chà AI.";
  }

  Future<List<String>> _articleSeedSuggestions() async {
    final articles = await _loadRelatedCultureArticles('');
    final suggestions = <String>[];

    void add(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || suggestions.contains(trimmed)) return;
      suggestions.add(trimmed);
    }

    for (final raw in articles.whereType<Map>().take(12)) {
      final article = Map<String, dynamic>.from(raw);
      final title = article['title']?.toString().trim() ?? '';
      final category = article['category']?.toString().trim() ?? '';
      final content = article['content']?.toString().trim() ?? '';
      if (title.isEmpty || content.isEmpty) continue;

      if (category == 'Trang phục') {
        add("$title có đặc điểm gì nổi bật?");
      } else if (category == 'Thảo dược') {
        add("$title có vai trò gì trong đời sống người Dao?");
      } else if (category == 'Lễ hội') {
        add("$title có ý nghĩa văn hóa gì?");
      } else if (category == 'Phong tục') {
        add("$title thể hiện phong tục gì của người Dao?");
      } else {
        add("$title có gì đáng chú ý?");
      }

      if (suggestions.length >= 6) break;
    }

    return suggestions.take(6).toList();
  }

  List<String> _smartSuggestions(
    List<Map<String, String>> messages, {
    List<String> articleSuggestions = const [],
    bool preferArticleFirst = false,
  }) {
    final lastUserText =
        messages.reversed.firstWhere(
          (message) => message["role"] == "user",
          orElse: () => const {"text": ""},
        )["text"] ??
        "";
    final recentText = messages.reversed
        .take(6)
        .map((message) => message["text"] ?? "")
        .join(" ")
        .toLowerCase();
    final normalizedRecent = _normalizeForSearch(recentText);
    final normalizedLast = _normalizeForSearch(lastUserText);

    final suggestions = <String>[];
    void addUnique(List<String> items) {
      for (final item in items) {
        if (!suggestions.contains(item)) suggestions.add(item);
        if (suggestions.length >= 4) return;
      }
    }

    bool hasAny(String text, List<String> keys) {
      return keys.any(text.contains);
    }

    final relatedSuggestions = _relatedArticleSuggestions(messages);

    addUnique([...relatedSuggestions, ...articleSuggestions]);
    return suggestions.take(4).toList();

    // Các nhánh cũ bên dưới được giữ nguyên để không ảnh hưởng logic AI.
    // ignore: dead_code
    if (preferArticleFirst || normalizedLast.isEmpty) {
      addUnique([
        ...relatedSuggestions,
        ...articleSuggestions,
        "Lễ cấp sắc của người Dao có ý nghĩa gì?",
        "Trang phục Dao có đặc điểm nào nổi bật?",
        "Thuốc tắm người Dao gắn với tri thức gì?",
        "Phong tục cưới hỏi của người Dao có gì đặc biệt?",
      ]);
      return suggestions.take(4).toList();
    }

    addUnique(relatedSuggestions.take(2).toList());

    if (hasAny(normalizedLast, [
      'le phuc',
      'co dau',
      'chu re',
      'trang phuc cuoi',
      'ao cuoi',
    ])) {
      addUnique([
        "Trang phục cưới của người Dao có gì đặc biệt?",
        "Cô dâu Dao thường mặc lễ phục như thế nào?",
        "Hoa văn trên lễ phục cưới Dao có ý nghĩa gì?",
        "Lễ phục cô dâu khác trang phục ngày thường thế nào?",
      ]);
    }

    if (hasAny(normalizedLast, [
      'mam cung',
      'mam le',
      'cung tet',
      'to tien',
      'ban vuong',
    ])) {
      addUnique([
        "Mâm cúng của người Dao có ý nghĩa gì?",
        "Mâm cúng Tết của người Dao thường gửi gắm điều gì?",
        "Vì sao người Dao cúng tổ tiên và Bàn Vương?",
        "Lễ cúng Tết của người Dao diễn ra như thế nào?",
      ]);
    }

    if (hasAny(normalizedLast, ['thay cung', 'phap su', ' thay ']) ||
        hasAny(normalizedRecent, ['thay cung', 'phap su'])) {
      addUnique([
        "Thầy cúng làm gì trong lễ cấp sắc?",
        "Ai có thể trở thành thầy cúng?",
        "Pháp khí của thầy cúng có ý nghĩa gì?",
        "Vì sao thầy cúng quan trọng trong nghi lễ Dao?",
      ]);
    }

    if (hasAny(normalizedLast, ['cap sac', 'truong thanh', 'lon len']) ||
        hasAny(normalizedRecent, ['cap sac', 'truong thanh'])) {
      addUnique([
        "Lễ cấp sắc có ý nghĩa gì?",
        "Nữ giới có làm lễ cấp sắc không?",
        "Lễ cấp sắc thường diễn ra như thế nào?",
        "Sau lễ cấp sắc người đàn ông Dao được công nhận điều gì?",
      ]);
    }

    if (hasAny(normalizedLast, [
      'am thuc',
      'mon an',
      'nguyen lieu',
      'ruou',
      'banh',
    ])) {
      addUnique([
        "Người Dao có món ăn truyền thống nào?",
        "Món ăn trong ngày lễ của người Dao có gì đặc biệt?",
        "Ẩm thực Dao thường dùng nguyên liệu gì?",
        "Mâm cúng của người Dao thường có ý nghĩa gì?",
      ]);
    }

    if (hasAny(normalizedLast, [
      'trang phuc',
      'khan',
      'theu',
      'hoa van',
      'mau sac',
    ])) {
      addUnique([
        "Hoa văn trên trang phục Dao có ý nghĩa gì?",
        "Khăn đội đầu của người Dao có ý nghĩa gì?",
        "Trang phục nam và nữ Dao khác nhau thế nào?",
        "Màu sắc trên trang phục Dao thể hiện điều gì?",
      ]);
    }

    if (hasAny(normalizedLast, [
      'thuoc tam',
      'thao duoc',
      'cay thuoc',
      'la tam',
    ])) {
      addUnique([
        "Bài thuốc tắm của người Dao có ý nghĩa gì?",
        "Người Dao dùng thảo dược trong đời sống như thế nào?",
        "Thuốc tắm Dao thường dùng trong dịp nào?",
        "Khi tìm hiểu thuốc nam Dao cần lưu ý gì?",
      ]);
    }

    if (hasAny(normalizedLast, ['le hoi', 'nhay lua', 'tet nhay', 'tet'])) {
      addUnique([
        "Lễ hội phản ánh đời sống người Dao ra sao?",
        "Người Dao có những lễ hội tiêu biểu nào?",
        "Nhảy lửa của người Dao có ý nghĩa gì?",
        "Âm nhạc và múa trong lễ hội Dao có vai trò gì?",
      ]);
    }

    final topicRules = <MapEntry<List<String>, List<String>>>[
      MapEntry(
        ["trang phục", "quần áo", "áo", "váy", "khăn", "thêu", "bạc"],
        [
          "Ý nghĩa màu sắc trên trang phục Dao là gì?",
          "Khăn đội đầu của người Dao có ý nghĩa gì?",
          "Trang phục cưới của người Dao khác gì ngày thường?",
        ],
      ),
      MapEntry(
        ["cấp sắc", "nghi lễ", "lễ", "thầy cúng", "tín ngưỡng"],
        [
          "Lễ cấp sắc có ý nghĩa gì?",
          "Vì sao thầy cúng quan trọng trong văn hóa Dao?",
          "Các nghi lễ lớn của người Dao gồm những gì?",
        ],
      ),
      MapEntry(
        ["ẩm thực", "món ăn", "ăn", "rượu", "bánh", "cơm"],
        [
          "Người Dao có món ăn truyền thống nào?",
          "Ẩm thực Dao thường dùng nguyên liệu gì?",
          "Món ăn trong ngày lễ của người Dao có gì đặc biệt?",
        ],
      ),
      MapEntry(
        ["ngôn ngữ", "tiếng dao", "từ vựng", "nói", "dịch"],
        [
          "Một số câu chào hỏi tiếng Dao là gì?",
          "Tiếng Dao có những đặc điểm gì?",
          "Làm sao học từ vựng tiếng Dao dễ nhớ hơn?",
        ],
      ),
      MapEntry(
        ["thảo dược", "thuốc", "cây", "lá", "tắm"],
        [
          "Bài thuốc tắm của người Dao có ý nghĩa gì?",
          "Người Dao dùng thảo dược trong đời sống như thế nào?",
          "Cần lưu ý gì khi tìm hiểu thuốc nam của người Dao?",
        ],
      ),
      MapEntry(
        ["lễ hội", "tết", "hội", "nhảy", "múa", "hát"],
        [
          "Người Dao có những lễ hội tiêu biểu nào?",
          "Lễ hội phản ánh đời sống người Dao ra sao?",
          "Âm nhạc và múa trong lễ hội Dao có ý nghĩa gì?",
        ],
      ),
    ];

    for (final rule in topicRules) {
      if (rule.key.any(recentText.contains)) {
        addUnique(rule.value);
      }
    }

    addUnique([
      "Phong tục tiêu biểu của người Dao là gì?",
      "Trang phục người Dao có gì đặc biệt?",
      "Trang phục Dao Đỏ có gì nổi bật?",
      "Người Dao có những lễ hội quan trọng nào?",
    ]);

    return suggestions.take(4).toList();
  }

  List<String> _relatedArticleSuggestions(List<Map<String, String>> messages) {
    final latestAiMessage = messages.reversed.firstWhere(
      (message) =>
          message['role'] == 'ai' &&
          (message['related_articles'] ?? '').trim().isNotEmpty,
      orElse: () => const <String, String>{},
    );
    final articles = _decodeRelatedArticles(
      latestAiMessage['related_articles'] ?? '',
    );
    final suggestions = <String>[];

    for (final article in articles) {
      final title = article['title']?.toString().trim() ?? '';
      final category = article['category']?.toString().trim() ?? '';
      final content = article['content']?.toString().trim() ?? '';
      if (title.isEmpty || content.isEmpty) continue;

      final suggestion = switch (category) {
        'Trang phục' => '$title có đặc điểm gì nổi bật?',
        'Thảo dược' => '$title có vai trò gì trong đời sống người Dao?',
        'Lễ hội' => '$title có ý nghĩa văn hóa gì?',
        'Phong tục' => '$title diễn ra và có ý nghĩa như thế nào?',
        _ => '$title có gì đáng chú ý?',
      };
      if (!suggestions.contains(suggestion)) suggestions.add(suggestion);
      if (suggestions.length >= 2) break;
    }

    return suggestions;
  }

  String _relatedArticleCategory(String text) {
    final lower = text.toLowerCase();
    final normalized = _normalizeForSearch(text);
    if ([
      'mam cung',
      'mam le',
      'cung tet',
      'to tien',
      'ban vuong',
    ].any(normalized.contains)) {
      return "Phong tục";
    }
    if ([
      'le phuc',
      'co dau',
      'chu re',
      'trang phuc cuoi',
      'ao cuoi',
    ].any(normalized.contains)) {
      return "Trang phục";
    }
    if ([
      "trang phục",
      "quần áo",
      "áo",
      "váy",
      "khăn",
      "thêu",
      "bạc",
    ].any(lower.contains)) {
      return "Trang phục";
    }
    if (["lễ hội", "tết", "hội", "nhảy", "múa", "hát"].any(lower.contains)) {
      return "Lễ hội";
    }
    if ([
      "phong tục",
      "cấp sắc",
      "nghi lễ",
      "thầy cúng",
      "tín ngưỡng",
    ].any(lower.contains)) {
      return "Phong tục";
    }
    if (["thảo dược", "thuốc", "cây", "lá", "tắm"].any(lower.contains)) {
      return "Thảo dược";
    }
    if ([
      "ẩm thực",
      "món ăn",
      "ăn",
      "rượu",
      "bánh",
      "nguyên liệu",
    ].any(lower.contains)) {
      return "Ẩm thực";
    }
    return "";
  }

  String _normalizeForSearch(String value) {
    final lower = value.toLowerCase().trim();
    final withoutMarks = lower.split('').map((char) {
      const map = {
        'à': 'a',
        'á': 'a',
        'ạ': 'a',
        'ả': 'a',
        'ã': 'a',
        'â': 'a',
        'ầ': 'a',
        'ấ': 'a',
        'ậ': 'a',
        'ẩ': 'a',
        'ẫ': 'a',
        'ă': 'a',
        'ằ': 'a',
        'ắ': 'a',
        'ặ': 'a',
        'ẳ': 'a',
        'ẵ': 'a',
        'è': 'e',
        'é': 'e',
        'ẹ': 'e',
        'ẻ': 'e',
        'ẽ': 'e',
        'ê': 'e',
        'ề': 'e',
        'ế': 'e',
        'ệ': 'e',
        'ể': 'e',
        'ễ': 'e',
        'ì': 'i',
        'í': 'i',
        'ị': 'i',
        'ỉ': 'i',
        'ĩ': 'i',
        'ò': 'o',
        'ó': 'o',
        'ọ': 'o',
        'ỏ': 'o',
        'õ': 'o',
        'ô': 'o',
        'ồ': 'o',
        'ố': 'o',
        'ộ': 'o',
        'ổ': 'o',
        'ỗ': 'o',
        'ơ': 'o',
        'ờ': 'o',
        'ớ': 'o',
        'ợ': 'o',
        'ở': 'o',
        'ỡ': 'o',
        'ù': 'u',
        'ú': 'u',
        'ụ': 'u',
        'ủ': 'u',
        'ũ': 'u',
        'ư': 'u',
        'ừ': 'u',
        'ứ': 'u',
        'ự': 'u',
        'ử': 'u',
        'ữ': 'u',
        'ỳ': 'y',
        'ý': 'y',
        'ỵ': 'y',
        'ỷ': 'y',
        'ỹ': 'y',
        'đ': 'd',
      };
      return map[char] ?? char;
    }).join();

    return withoutMarks
        .replaceAll(RegExp(r'\bng\s+dao\b|\bnguoi\s+d\b'), ' nguoi dao ')
        .replaceAll(RegExp(r'\bd\s+do\b|\bdao\s+d\b'), ' dao do ')
        .replaceAll(RegExp(r'\blcs\b'), ' le cap sac ')
        .replaceAll(RegExp(r'\btp\b'), ' trang phuc ')
        .replaceAll(RegExp(r'\bpt\b'), ' phong tuc ')
        .replaceAll(RegExp(r'\btd\b'), ' thao duoc ')
        .replaceAll(RegExp(r'\bcx\b|\bcap\s+xac\b'), ' cap sac ')
        .replaceAll(RegExp(r'\bdc\b|\bdk\b|\bduoc\b'), ' duoc ')
        .replaceAll(RegExp(r'\blm\b'), ' lam ')
        .replaceAll(RegExp(r'\bhum\b|\bhok\b|\bko\b|\bkhum\b|\bk\b'), ' khong ')
        .replaceAll(RegExp(r'\bmn\b'), ' moi nguoi ')
        .replaceAll(RegExp(r'\bvs\b'), ' voi ')
        .replaceAll(RegExp(r'\bntn\b'), ' nhu the nao ')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _recentConversationContext(List<Map<String, String>> messages) {
    return messages.reversed
        .take(5)
        .map((message) => message['text'] ?? '')
        .where((text) => text.trim().isNotEmpty)
        .join(' ');
  }

  String _searchTextWithContext(String userText, String contextText) {
    final tokens = _searchTokens(userText);
    final normalized = _normalizeForSearch(userText);
    final hasClearTopic =
        _isCuisineQuestion(userText) ||
        normalized.contains('trang phuc') ||
        normalized.contains('le phuc') ||
        normalized.contains('co dau') ||
        normalized.contains('chu re') ||
        normalized.contains('trang phuc cuoi') ||
        normalized.contains('ao cuoi') ||
        normalized.contains('thao duoc') ||
        normalized.contains('thuoc tam') ||
        normalized.contains('mam cung') ||
        normalized.contains('mam le') ||
        normalized.contains('cung tet') ||
        normalized.contains('to tien') ||
        normalized.contains('ban vuong') ||
        normalized.contains('le hoi') ||
        normalized.contains('cap sac') ||
        normalized.contains('lay vo') ||
        normalized.contains('lay chong') ||
        normalized.contains('ket hon') ||
        normalized.contains('cuoi') ||
        normalized.contains('truoc khi duoc lay') ||
        normalized.contains('phong tuc');
    final isFollowUp =
        !hasClearTopic &&
        (tokens.length <= 3 ||
            normalized.contains('duoc lam khong') ||
            normalized.contains('lam khong') ||
            normalized.contains('nu ') ||
            normalized == 'nu');
    if (!isFollowUp || contextText.trim().isEmpty) return userText;
    return '$contextText $userText';
  }

  bool _isCuisineQuestion(String value) {
    final normalized = _normalizeForSearch(value);
    return [
      'am thuc',
      'mon an',
      'do an',
      'nguyen lieu',
      'ruou',
      'banh',
      'mam com',
      'nau',
      'an uong',
    ].any(normalized.contains);
  }

  bool _articleHasCuisineContent(Map<String, dynamic> article) {
    final titleCategorySubtitle = _normalizeForSearch(
      [
        article['title']?.toString() ?? '',
        article['subtitle']?.toString() ?? '',
        article['category']?.toString() ?? '',
      ].join(' '),
    );
    return [
      'am thuc',
      'mon an',
      'do an',
      'nguyen lieu',
      'ruou',
      'banh',
      'nau',
      'an uong',
    ].any(titleCategorySubtitle.contains);
  }

  bool _articleMatchesDetectedCategory(
    Map<String, dynamic> article,
    String detectedCategory,
  ) {
    if (detectedCategory.isEmpty) return true;
    final category = article['category']?.toString().trim() ?? '';
    return category == detectedCategory;
  }

  List<String> _daoGroupsInText(String value) {
    final normalized = _normalizeForSearch(value);
    const groups = [
      'dao do',
      'dao tien',
      'dao thanh phan',
      'dao thanh y',
      'dao quan chet',
      'dao quan trang',
      'dao ao dai',
      'dao lan ten',
    ];
    return groups.where(normalized.contains).toList();
  }

  bool _articleMatchesQuestionDaoGroup(
    Map<String, dynamic> article,
    String userText,
  ) {
    final questionGroups = _daoGroupsInText(userText);
    if (questionGroups.isEmpty) return true;

    final articleText = [
      article['title']?.toString() ?? '',
      article['subtitle']?.toString() ?? '',
      article['category']?.toString() ?? '',
      article['content']?.toString() ?? '',
    ].join(' ');
    final articleGroups = _daoGroupsInText(articleText);
    return questionGroups.any(articleGroups.contains);
  }

  bool _containsAnyPhrase(String text, List<String> phrases) {
    return phrases.any(text.contains);
  }

  bool _articleMatchesPrimaryIntent(
    Map<String, dynamic> article,
    String userText,
  ) {
    final question = _normalizeForSearch(userText);
    final title = _normalizeForSearch(article['title']?.toString() ?? '');
    final subtitle = _normalizeForSearch(article['subtitle']?.toString() ?? '');
    final category = _normalizeForSearch(article['category']?.toString() ?? '');
    final content = _normalizeForSearch(article['content']?.toString() ?? '');
    final headline = '$title $subtitle $category';
    final fullText = '$headline $content';

    const checks = [
      (ask: ['dao do'], match: ['dao do'], headlineOnly: false),
      (
        ask: ['cap sac', 'le cap sac', 'dai le cap sac'],
        match: ['cap sac', 'le cap sac', 'dai le cap sac'],
        headlineOnly: true,
      ),
      (
        ask: [
          'phu the',
          'cuoi',
          'hon nhan',
          'co dau',
          'chu re',
          'ruoc dau',
          'don dau',
          'trang phuc cuoi',
        ],
        match: [
          'phu the',
          'cuoi',
          'hon nhan',
          'co dau',
          'chu re',
          'ruoc dau',
          'don dau',
          'trang phuc cuoi',
        ],
        headlineOnly: true,
      ),
      (
        ask: ['theu', 'theu tay', 'nghe thuat theu'],
        match: ['theu', 'theu tay', 'nghe thuat theu'],
        headlineOnly: true,
      ),
      (
        ask: ['trang phuc nu', 'phu nu', 'con gai', 'trang phuc phu nu'],
        match: [
          'trang phuc nu',
          'phu nu',
          'con gai',
          'trang phuc phu nu',
          'co dau',
        ],
        headlineOnly: true,
      ),
      (
        ask: ['trang phuc', 'le phuc', 'quan ao'],
        match: ['trang phuc', 'le phuc', 'quan ao'],
        headlineOnly: true,
      ),
    ];

    for (final check in checks) {
      if (!_containsAnyPhrase(question, check.ask)) continue;
      final text = check.headlineOnly ? headline : fullText;
      if (!_containsAnyPhrase(text, check.match)) return false;
    }

    final asksCapSac = _containsAnyPhrase(question, checks[1].ask);
    final asksWedding = _containsAnyPhrase(question, checks[2].ask);
    if (!asksCapSac && _containsAnyPhrase(title, checks[1].match)) {
      return false;
    }
    if (!asksWedding && _containsAnyPhrase(title, checks[2].match)) {
      return false;
    }

    return true;
  }

  List<String> _requiredFocusPhrases(String normalizedQuestion) {
    if ([
      'mam cung',
      'mam le',
      'cung tet',
      'to tien',
      'ban vuong',
    ].any(normalizedQuestion.contains)) {
      return ['mam cung', 'mam le', 'cung tet', 'to tien', 'ban vuong'];
    }

    if (normalizedQuestion.contains('thay cung') ||
        normalizedQuestion.contains('phap su')) {
      return ['thay cung', 'phap su'];
    }

    if (normalizedQuestion.contains('le phuc') ||
        normalizedQuestion.contains('co dau') ||
        normalizedQuestion.contains('chu re') ||
        normalizedQuestion.contains('trang phuc cuoi') ||
        normalizedQuestion.contains('ao cuoi')) {
      return ['le phuc', 'co dau', 'chu re', 'trang phuc cuoi', 'ao cuoi'];
    }

    if (normalizedQuestion.contains('cap sac') ||
        normalizedQuestion.contains('truong thanh')) {
      return ['cap sac', 'truong thanh'];
    }

    if (normalizedQuestion.contains('lay vo') ||
        normalizedQuestion.contains('lay chong') ||
        normalizedQuestion.contains('ket hon') ||
        normalizedQuestion.contains('cuoi') ||
        normalizedQuestion.contains('truoc khi duoc lay')) {
      return [
        'cap sac',
        'truong thanh',
        'lay vo',
        'lay chong',
        'ket hon',
        'cuoi',
        'to hong',
      ];
    }

    return [];
  }

  Set<String> _focusedSearchTokens(String value) {
    const genericWords = {
      'van',
      'hoa',
      'phong',
      'tuc',
      'nghi',
      'hoi',
      'nghia',
      'quan',
      'trong',
      'vai',
      'tro',
      'sao',
      'tai',
      'can',
      'biet',
      'noi',
      'dung',
      'duoc',
      'truoc',
      'sau',
      'nam',
      'nu',
      'lay',
      'phuc',
    };

    return _searchTokens(
      value,
    ).where((token) => !genericWords.contains(token)).toSet();
  }

  bool _articleHasFocusedMatch(
    Map<String, dynamic> article,
    String userText,
    List<String> aiKeywords,
  ) {
    return _directArticleRelevanceScore(article, userText, aiKeywords) >= 35;
  }

  int _directArticleRelevanceScore(
    Map<String, dynamic> article,
    String userText,
    List<String> aiKeywords,
  ) {
    final normalizedQuestion = _normalizeForSearch(userText);
    final requiredPhrases = _requiredFocusPhrases(normalizedQuestion);
    final hints = _semanticHints(normalizedQuestion)
        .map(_normalizeForSearch)
        .where(
          (hint) =>
              hint.length >= 5 &&
              hint != 'nghi le' &&
              hint != 'tam linh' &&
              hint != 'le hoi',
        )
        .toSet();

    final normalizedTitle = _normalizeForSearch(
      article['title']?.toString() ?? '',
    );
    final normalizedSubtitle = _normalizeForSearch(
      article['subtitle']?.toString() ?? '',
    );
    final normalizedContent = _normalizeForSearch(
      article['content']?.toString() ?? '',
    );
    final textWithoutCategory =
        '$normalizedTitle $normalizedSubtitle $normalizedContent';
    final titleAndSubtitle = '$normalizedTitle $normalizedSubtitle';
    final articleTokens = _searchTokens(textWithoutCategory);
    final questionGroups = _daoGroupsInText(userText);
    final focusedTokens = {
      ..._focusedSearchTokens(userText),
      ...aiKeywords.expand(_focusedSearchTokens),
    };

    var score = 0;
    var hasRequiredPhrase = requiredPhrases.isEmpty;

    for (final phrase in requiredPhrases) {
      if (normalizedTitle.contains(phrase)) {
        score += 90;
        hasRequiredPhrase = true;
      } else if (normalizedSubtitle.contains(phrase)) {
        score += 65;
        hasRequiredPhrase = true;
      } else if (normalizedContent.contains(phrase)) {
        score += 45;
        hasRequiredPhrase = true;
      }
    }

    if (!hasRequiredPhrase) return 0;

    for (final group in questionGroups) {
      if (normalizedTitle.contains(group)) {
        score += 80;
      } else if (normalizedSubtitle.contains(group)) {
        score += 60;
      } else if (normalizedContent.contains(group)) {
        score += 45;
      }
    }

    for (final hint in hints) {
      if (normalizedTitle.contains(hint)) {
        score += 70;
      } else if (normalizedSubtitle.contains(hint)) {
        score += 50;
      } else if (normalizedContent.contains(hint)) {
        score += 28;
      }
    }

    var matchedTokens = 0;
    var titleMatchedTokens = 0;
    for (final token in focusedTokens) {
      final matched =
          textWithoutCategory.contains(token) ||
          _fuzzyContainsToken(articleTokens, token);
      if (!matched) continue;
      matchedTokens++;

      if (titleAndSubtitle.contains(token)) {
        titleMatchedTokens++;
        score += normalizedTitle.contains(token) ? 16 : 10;
      } else {
        score += 4;
      }
    }

    if (focusedTokens.isEmpty) {
      return score;
    }
    if (questionGroups.isNotEmpty && score >= 45 && matchedTokens == 0) {
      return score;
    }
    if (focusedTokens.length == 1 && matchedTokens == 0) {
      return 0;
    }
    if (focusedTokens.length > 1 &&
        matchedTokens < 2 &&
        titleMatchedTokens == 0) {
      return 0;
    }

    if (normalizedQuestion.contains('cap sac')) {
      if (normalizedTitle.startsWith('cap sac') ||
          normalizedTitle.contains('dai le cap sac') ||
          normalizedTitle.contains('le cap sac')) {
        score += 120;
      }

      final asksSpecificDetail = [
        'le phuc',
        'phap danh',
        'den cap sac',
      ].any(normalizedQuestion.contains);
      final isSpecificDetail = [
        'le phuc',
        'phap danh',
        'den cap sac',
      ].any(normalizedTitle.contains);
      if (!asksSpecificDetail && isSpecificDetail) score -= 130;
    }

    return score;
  }

  Set<String> _searchTokens(String value) {
    const stopWords = {
      'nguoi',
      'dao',
      'la',
      'gi',
      'co',
      'cua',
      'cho',
      'biet',
      've',
      'nhu',
      'the',
      'nao',
      'khong',
      'thi',
      'se',
      'lam',
      'khi',
      'nhung',
      'cac',
      'mot',
      'minh',
      'hoi',
      'hay',
      'tai',
      'sao',
      'vai',
      'tro',
      'quan',
      'trong',
    };

    return _normalizeForSearch(value)
        .split(' ')
        .where((word) => word.length >= 3 && !stopWords.contains(word))
        .toSet();
  }

  List<String> _semanticHints(String normalizedQuestion) {
    final hints = <String>[];
    void add(String value) {
      if (!hints.contains(value)) hints.add(value);
    }

    if (normalizedQuestion.contains('truong thanh') ||
        normalizedQuestion.contains('lon len') ||
        normalizedQuestion.contains('cap sac') ||
        normalizedQuestion.contains('cap xac') ||
        normalizedQuestion.contains('dao sac') ||
        normalizedQuestion.contains('thay cung')) {
      add('le cap sac');
      add('nghi le truong thanh');
      add('tam linh');
      add('thay cung');
    }

    if (normalizedQuestion.contains('lay vo') ||
        normalizedQuestion.contains('lay chong') ||
        normalizedQuestion.contains('ket hon') ||
        normalizedQuestion.contains('cuoi') ||
        normalizedQuestion.contains('truoc khi duoc lay')) {
      add('le cap sac');
      add('nghi le truong thanh');
      add('le to hong');
      add('hon nhan');
    }

    if (normalizedQuestion.contains('mam cung') ||
        normalizedQuestion.contains('mam le') ||
        normalizedQuestion.contains('cung tet') ||
        normalizedQuestion.contains('to tien') ||
        normalizedQuestion.contains('ban vuong')) {
      add('mam cung');
      add('cung tet');
      add('to tien');
      add('ban vuong');
    }

    if (normalizedQuestion.contains('tam la') ||
        normalizedQuestion.contains('thuoc tam') ||
        normalizedQuestion.contains('cay thuoc') ||
        normalizedQuestion.contains('thao duoc')) {
      add('thuoc tam');
      add('thao duoc');
      add('cay thuoc');
      add('la tam');
    }

    if (normalizedQuestion.contains('tet') ||
        normalizedQuestion.contains('dau nam') ||
        normalizedQuestion.contains('nhay') ||
        normalizedQuestion.contains('le hoi')) {
      add('tet nhay');
      add('le hoi');
      add('nghi le');
    }

    if (normalizedQuestion.contains('mac') ||
        normalizedQuestion.contains('quan ao') ||
        normalizedQuestion.contains('trang phuc') ||
        normalizedQuestion.contains('le phuc') ||
        normalizedQuestion.contains('co dau') ||
        normalizedQuestion.contains('chu re') ||
        normalizedQuestion.contains('trang phuc cuoi') ||
        normalizedQuestion.contains('ao cuoi') ||
        normalizedQuestion.contains('khan') ||
        normalizedQuestion.contains('theu')) {
      add('trang phuc');
      add('le phuc');
      add('trang phuc cuoi');
      add('co dau');
      add('chu re');
      add('hoa van');
      add('khan doi dau');
      add('theu');
    }

    return hints;
  }

  int _editDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var previous = List<int>.generate(b.length + 1, (index) => index);
    for (var i = 0; i < a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0);
      current[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        current[j + 1] = [
          current[j] + 1,
          previous[j + 1] + 1,
          previous[j] + cost,
        ].reduce((value, element) => value < element ? value : element);
      }
      previous = current;
    }
    return previous[b.length];
  }

  bool _fuzzyContainsToken(Set<String> articleTokens, String token) {
    if (articleTokens.contains(token)) return true;
    if (token.length < 4) return false;
    for (final articleToken in articleTokens) {
      final diff = _editDistance(articleToken, token);
      if (diff <= 1 || (token.length >= 7 && diff <= 2)) return true;
    }
    return false;
  }

  String _cleanAssistantText(String text) {
    return text
        .replaceAll(
          RegExp(
            r'(dựa trên|theo)\s+(bài|bài viết)[^:：]*[:：]?',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'bài viết hiện chưa nêu rõ[^.。!?]*[.。!?]?',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'nội dung bài[^.。!?]*(chưa|không)[^.。!?]*[.。!?]?',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'[#_`~]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isAdminSourceNotEnough(String text) {
    final compact = _normalizeForSearch(text).replaceAll(' ', '');
    return compact.contains('adminsourcenotenough');
  }

  int _scoreArticle(
    Map<String, dynamic> article,
    String userText,
    List<String> aiKeywords,
  ) {
    final normalizedQuestion = _normalizeForSearch(userText);
    final questionTokens = _searchTokens(userText);
    final hints = _semanticHints(normalizedQuestion);
    final expandedTokens = {
      ...questionTokens,
      ...hints.expand(_searchTokens),
      ...aiKeywords.expand(_searchTokens),
    };

    final title = article['title']?.toString() ?? '';
    final subtitle = article['subtitle']?.toString() ?? '';
    final category = article['category']?.toString() ?? '';
    final content = article['content']?.toString() ?? '';
    final normalizedTitle = _normalizeForSearch(title);
    final normalizedSubtitle = _normalizeForSearch(subtitle);
    final normalizedContent = _normalizeForSearch(content);
    final normalizedCategory = _normalizeForSearch(category);
    final fullText =
        '$normalizedTitle $normalizedSubtitle $normalizedCategory $normalizedContent';
    final articleTokens = _searchTokens(fullText);
    final questionGroups = _daoGroupsInText(userText);

    var score = 0;
    if (normalizedTitle.isNotEmpty &&
        normalizedQuestion.contains(normalizedTitle)) {
      score += 80;
    }
    if (normalizedTitle.isNotEmpty &&
        normalizedTitle.contains(normalizedQuestion)) {
      score += 60;
    }

    for (final hint in hints) {
      final normalizedHint = _normalizeForSearch(hint);
      if (normalizedTitle.contains(normalizedHint)) score += 55;
      if (normalizedSubtitle.contains(normalizedHint)) score += 30;
      if (normalizedContent.contains(normalizedHint)) score += 18;
    }

    for (final keyword in aiKeywords) {
      final normalizedKeyword = _normalizeForSearch(keyword);
      if (normalizedKeyword.length < 3) continue;
      if (normalizedTitle.contains(normalizedKeyword)) score += 38;
      if (normalizedSubtitle.contains(normalizedKeyword)) score += 22;
      if (normalizedContent.contains(normalizedKeyword)) score += 12;
    }

    for (final group in questionGroups) {
      if (normalizedTitle.contains(group)) {
        score += 90;
      } else if (normalizedSubtitle.contains(group)) {
        score += 75;
      } else if (normalizedContent.contains(group)) {
        score += 70;
      }
    }

    for (final token in expandedTokens) {
      if (normalizedTitle.split(' ').contains(token)) score += 12;
      if (normalizedSubtitle.split(' ').contains(token)) score += 6;
      if (normalizedContent.split(' ').contains(token)) score += 3;
      if (!fullText.contains(token) &&
          _fuzzyContainsToken(articleTokens, token)) {
        score += 4;
      }
    }

    final detectedCategory = _relatedArticleCategory(userText);
    if (detectedCategory.isNotEmpty && category == detectedCategory) {
      score += 20;
    }

    return score;
  }

  List<Map<String, dynamic>> _rankRelatedArticles(
    List<dynamic> rawArticles,
    String userText, {
    List<String> aiKeywords = const [],
  }) {
    final cuisineQuestion = _isCuisineQuestion(userText);
    final detectedCategory = _relatedArticleCategory(userText);
    final ranked = rawArticles
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .where(
          (article) => !cuisineQuestion || _articleHasCuisineContent(article),
        )
        .where(
          (article) =>
              cuisineQuestion ||
              detectedCategory.isEmpty ||
              _articleMatchesDetectedCategory(article, detectedCategory) ||
              _directArticleRelevanceScore(article, userText, aiKeywords) >= 90,
        )
        .where((article) => _articleMatchesQuestionDaoGroup(article, userText))
        .where((article) => _articleMatchesPrimaryIntent(article, userText))
        .where(
          (article) => _articleHasFocusedMatch(article, userText, aiKeywords),
        )
        .map(
          (article) => {
            ...article,
            '_direct_score': _directArticleRelevanceScore(
              article,
              userText,
              aiKeywords,
            ),
            '_score': _scoreArticle(article, userText, aiKeywords),
          },
        )
        .where((article) {
          final title = article['title']?.toString().trim() ?? '';
          final directScore = article['_direct_score'] as int;
          final totalScore = article['_score'] as int;
          return title.isNotEmpty && directScore >= 35 && totalScore >= 70;
        })
        .toList();

    ranked.sort((a, b) {
      final directCompare = (b['_direct_score'] as int).compareTo(
        a['_direct_score'] as int,
      );
      if (directCompare != 0) return directCompare;
      return (b['_score'] as int).compareTo(a['_score'] as int);
    });
    return ranked.take(8).toList();
  }

  String _articleMatchKey(Map<String, dynamic> article) {
    final id = article['id']?.toString().trim() ?? '';
    if (id.isNotEmpty) return id;
    return _normalizeForSearch(article['title']?.toString() ?? '');
  }

  bool _titleDirectlyMatchesQuestionFocus(
    Map<String, dynamic> article,
    String userText,
  ) {
    final title = _normalizeForSearch(article['title']?.toString() ?? '');
    final requiredPhrases = _requiredFocusPhrases(
      _normalizeForSearch(userText),
    );
    return requiredPhrases.any(title.contains);
  }

  String _articleVerifierText(Map<String, dynamic> article) {
    String limit(String value, int maxLength) {
      final cleaned = _cleanAssistantText(value);
      if (cleaned.length <= maxLength) return cleaned;
      return '${cleaned.substring(0, maxLength).trim()}...';
    }

    final title = article['title']?.toString() ?? '';
    final subtitle = article['subtitle']?.toString() ?? '';
    final category = article['category']?.toString() ?? '';
    final content = article['content']?.toString() ?? '';
    return [
      'ID: ${_articleMatchKey(article)}',
      'Tiêu đề: ${limit(title, 160)}',
      'Danh mục: ${limit(category, 80)}',
      'Tóm tắt: ${limit(subtitle, 240)}',
      'Nội dung: ${limit(content, 900)}',
    ].join('\n');
  }

  List<String> _decodeVerifierIds(String response) {
    final start = response.indexOf('[');
    final end = response.lastIndexOf(']');
    if (start < 0 || end <= start) return [];
    try {
      final decoded = jsonDecode(response.substring(start, end + 1));
      if (decoded is! List) return [];
      return decoded.map((item) => item.toString().trim()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _verifyRelatedArticlesWithAi({
    required String userText,
    required String contextText,
    required List<Map<String, dynamic>> candidates,
  }) async {
    if (candidates.isEmpty) return [];

    final candidateText = candidates
        .map(_articleVerifierText)
        .join('\n\n---\n\n');
    final prompt =
        'Bạn là bộ lọc bài viết liên quan cho ứng dụng văn hóa Dao. '
        'Nhiệm vụ: chọn các bài admin thật sự trả lời trực tiếp câu hỏi người dùng. '
        'Chỉ chọn bài khi tiêu đề/tóm tắt/nội dung có thông tin sát với ý chính của câu hỏi. '
        'Không chọn bài chỉ vì cùng danh mục, cùng chữ "lễ", "phong tục", "trang phục", hoặc chỉ liên quan gián tiếp. '
        'Nếu câu hỏi nêu nhóm Dao cụ thể như Dao Đỏ, Dao Tiền, Dao Thanh Phán, Dao Thanh Y, Dao Quần Chẹt thì chỉ chọn bài có nhắc đúng nhóm đó; không chọn bài chỉ nói chung về người Dao. '
        'Nếu câu hỏi hỏi "lễ cấp sắc", chỉ chọn bài có nội dung về cấp sắc/trưởng thành, không chọn bài cưới/đón dâu/lễ phục nếu không trả lời cấp sắc. '
        'Nếu câu hỏi hỏi "lễ phục cô dâu", chỉ chọn bài về lễ phục, cô dâu, chú rể, trang phục cưới, không chọn bài cấp sắc chung. '
        'Nếu không có bài đủ sát, trả về []. '
        'Trả về đúng JSON array chứa ID bài theo thứ tự liên quan nhất, tối đa 3 ID. Không giải thích.\n\n'
        'Ngữ cảnh gần đây: $contextText\n'
        'Câu hỏi: $userText\n\n'
        'Danh sách bài ứng viên:\n$candidateText';

    try {
      final response = await ApiService.chatWithDaoAssistant(
        prompt,
      ).timeout(const Duration(seconds: 14));
      final orderedIds = _decodeVerifierIds(response);
      final idSet = orderedIds.toSet();
      if (orderedIds.isEmpty) return [];

      final selected = candidates
          .where((article) => idSet.contains(_articleMatchKey(article)))
          .toList();
      selected.sort((a, b) {
        final aIndex = orderedIds.indexOf(_articleMatchKey(a));
        final bIndex = orderedIds.indexOf(_articleMatchKey(b));
        return aIndex.compareTo(bIndex);
      });
      return selected.take(3).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> _extractAiKeywords(String userText) async {
    try {
      final prompt =
          'Từ câu hỏi sau, hãy rút ra tối đa 5 từ khóa văn hóa Dao liên quan. '
          'Chỉ trả về các từ khóa ngắn, phân tách bằng dấu phẩy, không giải thích: $userText';
      final response = await ApiService.chatWithDaoAssistant(
        prompt,
      ).timeout(const Duration(seconds: 12));
      return response
          .split(RegExp(r'[,;\n]'))
          .map(_cleanAssistantText)
          .map(_normalizeForSearch)
          .where((item) => item.length >= 3 && item.length <= 40)
          .take(5)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ignore: unused_element
  Future<String> _geminiFallbackAnswer(
    String userText,
    String contextText,
  ) async {
    final prompt =
        'Bạn là trợ lý am hiểu văn hóa người Dao ở Việt Nam, bao gồm các nhóm/ngành Dao khác nhau như Dao Đỏ khi dữ liệu có nêu, trả lời gần gũi nhưng phải thận trọng và đúng trọng tâm. '
        'Đây là câu trả lời tham khảo từ AI vì kho bài admin chưa có nội dung khớp đủ trực tiếp. '
        'Hãy mở đầu đúng bằng cụm "Thông tin tham khảo từ AI:" rồi trả lời ngay vào câu hỏi.\n'
        'Yêu cầu bắt buộc:\n'
        '- Hiểu cả câu hỏi sai chính tả, viết tắt, không dấu và câu hỏi nối tiếp dựa vào ngữ cảnh gần đây.\n'
        '- Chỉ trả lời đúng điều người dùng hỏi, không tự chuyển sang chủ đề khác.\n'
        '- Nếu câu hỏi hoặc dữ liệu nêu nhóm Dao cụ thể như Dao Đỏ thì phải giữ đúng tên nhóm đó; nếu thông tin khác nhau theo nhóm Dao hoặc địa phương, phải nói rõ "tùy nhóm Dao" hoặc "tùy địa phương".\n'
        '- Không bịa số liệu, tên nghi lễ, món ăn, cây thuốc hoặc phong tục nếu không chắc; khi chưa chắc hãy dùng "thường", "có nơi", "ở nhiều nhóm Dao".\n'
        '- Trả lời 3-5 câu, dễ đọc, không markdown, không dùng dấu *, không liệt kê dài.\n'
        '- Nếu người dùng hỏi sai như "Dao có bao nhiêu dân tộc", hãy nhẹ nhàng chỉnh: Dao là một dân tộc trong 54 dân tộc Việt Nam, bên trong có nhiều nhóm/ngành Dao.\n'
        'Ngữ cảnh gần đây: $contextText\n'
        'Câu hỏi hiện tại: $userText';

    final response = await ApiService.chatWithDaoAssistant(prompt);
    return _cleanAssistantText(response);
  }

  String _articleType(Map<String, dynamic> article) {
    final video = article['video_url']?.toString().trim() ?? '';
    final image = article['image_url']?.toString().trim() ?? '';
    if (video.isNotEmpty) return 'video';
    if (image.isNotEmpty) return 'image';
    return 'text';
  }

  String _articleMediaUrl(Map<String, dynamic> article) {
    final type = _articleType(article);
    if (type == 'video') return article['video_url']?.toString() ?? '';
    if (type == 'image') return article['image_url']?.toString() ?? '';
    return '';
  }

  bool _isFemaleEligibilityQuestion(String userText) {
    final normalized = _normalizeForSearch(userText);
    final mentionsFemale =
        normalized.contains('nu') ||
        normalized.contains('phu nu') ||
        normalized.contains('con gai') ||
        normalized.contains('gai');
    final asksPermission =
        normalized.contains('duoc') ||
        normalized.contains('khong') ||
        normalized.contains('lam');
    return mentionsFemale && asksPermission;
  }

  Future<String?> _composeAdminGroundedAnswer({
    required String userText,
    required String contextText,
    required List<Map<String, dynamic>> articles,
  }) async {
    final source = articles
        .take(3)
        .map((article) {
          final title = article['title']?.toString() ?? '';
          final subtitle = article['subtitle']?.toString() ?? '';
          final category = article['category']?.toString() ?? '';
          final content = article['content']?.toString() ?? '';
          return [
            if (title.trim().isNotEmpty) 'Tiêu đề: $title',
            if (category.trim().isNotEmpty) 'Danh mục: $category',
            if (subtitle.trim().isNotEmpty) 'Tóm tắt: $subtitle',
            if (content.trim().isNotEmpty) 'Nội dung: $content',
          ].join('\n');
        })
        .where((part) => part.trim().isNotEmpty)
        .join('\n\n---\n\n');
    final cleanedSource = _cleanAssistantText(source);
    final normalizedSource = _normalizeForSearch(source);

    if (_isFemaleEligibilityQuestion(userText) &&
        (normalizedSource.contains('nam gioi') ||
            normalizedSource.contains('dan ong') ||
            normalizedSource.contains('con trai'))) {
      return _cleanAssistantText(
        'Lễ cấp sắc trong văn hóa Dao thường gắn với nam giới, đánh dấu sự trưởng thành về mặt tâm linh và trách nhiệm với gia đình, cộng đồng. Với nữ giới, tùy nhóm Dao và địa phương có thể có các nghi lễ, vai trò tín ngưỡng khác nhau, nhưng không nên hiểu lễ cấp sắc của nam giới là nghi lễ bắt buộc giống nhau cho nữ.',
      );
    }

    final prompt =
        'Hãy trả lời đúng trọng tâm câu hỏi của người dùng bằng tiếng Việt, ngắn gọn 2-4 câu, tự nhiên như một người am hiểu văn hóa người Dao tại Việt Nam đang giải thích cho người đọc. '
        'Chỉ được sử dụng thông tin xuất hiện trong nguồn nội bộ từ các bài admin bên dưới. '
        'Nếu nguồn nội bộ không có đủ thông tin để trả lời trực tiếp câu hỏi hiện tại, chỉ trả về đúng mã ADMIN_SOURCE_NOT_ENOUGH, không giải thích thêm. '
        'Nếu câu hỏi hỏi riêng một nhóm Dao cụ thể như Dao Đỏ nhưng nguồn chỉ nói chung về người Dao hoặc nói nhóm Dao khác, chỉ trả về đúng mã ADMIN_SOURCE_NOT_ENOUGH. '
        'Không được tự bổ sung kiến thức bên ngoài, không suy đoán, không trả lời dựa trên hiểu biết chung khi nguồn admin chưa đủ. '
        'Không chép nguyên văn dài, không dùng markdown, không dùng dấu *, không nói "dựa trên bài", không nói "theo bài", không nói "bài viết chưa nêu", không nói "nội dung bài", không nhắc quá trình tìm bài. '
        'Nếu nguồn nêu nhóm Dao cụ thể như Dao Đỏ thì phải giữ đúng tên nhóm đó; nếu nguồn có nêu sự khác nhau theo nhóm Dao hoặc địa phương thì nói rõ; nếu nguồn không nêu thì không tự thêm.\n\n'
        'Ngữ cảnh hội thoại gần đây: $contextText\n'
        'Câu hỏi hiện tại: $userText\n'
        'Nguồn nội bộ từ các bài admin liên quan:\n$cleanedSource';

    try {
      final response = await ApiService.chatWithDaoAssistant(
        prompt,
      ).timeout(const Duration(seconds: 14));
      if (_isAdminSourceNotEnough(response)) {
        return null;
      }
      final cleaned = _cleanAssistantText(response);
      if (_isAdminSourceNotEnough(cleaned)) {
        return null;
      }
      if (cleaned.isNotEmpty) {
        return cleaned
            .replaceAll(
              RegExp(
                r'bài viết hiện chưa nêu rõ[^.。!?]*[.。!?]?',
                caseSensitive: false,
              ),
              '',
            )
            .trim();
      }
    } catch (_) {}

    return null;
  }

  String _relatedArticlesJson(List<Map<String, dynamic>> articles) {
    return jsonEncode(
      articles
          .map(
            (article) => {
              'id': article['id']?.toString() ?? '',
              'title': article['title']?.toString() ?? '',
              'subtitle': article['subtitle']?.toString() ?? '',
              'category': article['category']?.toString() ?? '',
              'content': article['content']?.toString() ?? '',
              'image_url': article['image_url']?.toString() ?? '',
              'video_url': article['video_url']?.toString() ?? '',
            },
          )
          .toList(),
    );
  }

  List<Map<String, dynamic>> _decodeRelatedArticles(String value) {
    if (value.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ignore: unused_element
  Future<Map<String, String>?> _answerFromAdminArticlesWithContext(
    String userText,
    String contextText,
  ) async {
    final articles = await _loadRelatedCultureArticles('');
    if (articles.isEmpty) return null;

    final searchText = _searchTextWithContext(userText, contextText);
    var ranked = _rankRelatedArticles(articles, searchText);
    if (ranked.isEmpty || (ranked.first['_score'] as int) < 34) {
      final aiKeywords = await _extractAiKeywords(searchText);
      if (aiKeywords.isNotEmpty) {
        ranked = _rankRelatedArticles(
          articles,
          searchText,
          aiKeywords: aiKeywords,
        );
      }
    }

    if (ranked.isEmpty) return null;

    final aiVerifiedArticles = await _verifyRelatedArticlesWithAi(
      userText: userText,
      contextText: contextText,
      candidates: ranked,
    );
    final verifiedArticles = <Map<String, dynamic>>[];
    final exactTitleMatches = ranked.where(
      (article) => _titleDirectlyMatchesQuestionFocus(article, searchText),
    );
    for (final article in [...exactTitleMatches, ...aiVerifiedArticles]) {
      if (verifiedArticles.any(
        (item) => _articleMatchKey(item) == _articleMatchKey(article),
      )) {
        continue;
      }
      verifiedArticles.add(article);
      if (verifiedArticles.length >= 3) break;
    }
    if (verifiedArticles.isEmpty) return null;

    final answerText = await _composeAdminGroundedAnswer(
      userText: userText,
      contextText: contextText,
      articles: verifiedArticles,
    );
    if (answerText == null || answerText.isEmpty) return null;
    final answer = answerText.isNotEmpty
        ? answerText
        : 'Mình tìm thấy nội dung liên quan trong kho admin.';

    return {
      'role': 'ai',
      'text': _cleanAssistantText(answer),
      'related_articles': _relatedArticlesJson(verifiedArticles),
    };
  }

  void _openRelatedArticle(BuildContext context, Map<String, dynamic> article) {
    final title = article['title']?.toString() ?? '';
    final category = article['category']?.toString() ?? '';
    if (title.trim().isEmpty) return;
    CultureArticleService.incrementView(article['id']?.toString() ?? '');

    Widget screen;
    if (category == 'Trang phục') {
      screen = TraditionalCostumeScreen(initialDetailTitle: title);
    } else if (category == 'Lễ hội') {
      screen = FestivalScreen(initialDetailTitle: title);
    } else if (category == 'Phong tục') {
      screen = CustomsScreen(initialDetailTitle: title);
    } else if (category == 'Thảo dược') {
      screen = HerbalKnowledgeScreen(initialDetailTitle: title);
    } else {
      screen = CultureDetailScreen(
        title: title,
        type: _articleType(article),
        mediaUrl: _articleMediaUrl(article),
        content: article['content']?.toString() ?? '',
      );
    }

    final navigator = Navigator.of(context);
    navigator.pop();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      navigator.push(MaterialPageRoute(builder: (_) => screen));
    });
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Map<String, String> message,
  ) {
    final isAI = message['role'] == 'ai';
    final relatedArticles = isAI
        ? _decodeRelatedArticles(message['related_articles'] ?? '')
        : <Map<String, dynamic>>[];
    final text = _cleanAssistantText(message['text'] ?? '');

    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: isAI ? double.infinity : null,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isAI ? const Color(0xFFFFFBF5) : const Color(0xFF1A5FB4),
          borderRadius: BorderRadius.circular(18),
          border: isAI ? Border.all(color: const Color(0xFFE7D8C8)) : null,
          boxShadow: isAI
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isAI ? const Color(0xFF17211F) : Colors.white,
                fontSize: 14,
                height: 1.42,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (relatedArticles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 17,
                    color: Color(0xFFD93829),
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Bài viết liên quan",
                    style: TextStyle(
                      color: Color(0xFF17211F),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...relatedArticles
                  .take(3)
                  .map(
                    (article) => _RelatedArticleCard(
                      article: article,
                      onTap: () => _openRelatedArticle(context, article),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Future<List<dynamic>> _loadRelatedCultureArticles(String category) async {
    try {
      final encodedCategory = Uri.encodeComponent(category);
      final url = category.trim().isEmpty
          ? '${ApiService.baseUrl}/culture_articles/list.php'
          : '${ApiService.baseUrl}/culture_articles/list.php?category=$encodedCategory';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body.trim());
      if (decoded is List) return decoded;
      if (decoded is Map && decoded['data'] is List) {
        return decoded['data'] as List;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  String _cleanTextForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'[#_`~]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _speakAiText(String text) async {
    final spokenText = _cleanTextForSpeech(text);
    if (spokenText.isEmpty) return;

    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.stop();
    await flutterTts.speak(spokenText);
  }

  @override
  Widget build(BuildContext context) {
    _startAssistantAnimation();
    final size = MediaQuery.of(context).size;
    bool isVN = currentLanguage == "Tiếng Việt";
    final currentPosition = _resolvedPosition(size);

    return Positioned(
      left: currentPosition.dx,
      top: currentPosition.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _showChatFunction(context),
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
            position = currentPosition;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            position = _clampPosition(
              (position ?? currentPosition) + details.delta,
              size,
            );
          });
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
        },
        onPanCancel: () {
          setState(() => _isDragging = false);
        },
        child: _buildAssistantImage(isVN),
      ),
    );
  }

  Offset _resolvedPosition(Size size) {
    final defaultPosition = Offset(
      size.width - _assistantWidth - 4,
      size.height - _assistantHeight - _bottomBarClearance,
    );

    return _clampPosition(position ?? defaultPosition, size);
  }

  Offset _clampPosition(Offset rawPosition, Size size) {
    final maxX = (size.width - _assistantWidth)
        .clamp(0.0, double.infinity)
        .toDouble();
    final maxY = (size.height - _assistantHeight - _bottomBarClearance)
        .clamp(0.0, double.infinity)
        .toDouble();
    final minY = maxY < 50 ? 0.0 : 50.0;

    return Offset(
      rawPosition.dx.clamp(0, maxX).toDouble(),
      rawPosition.dy.clamp(minY, maxY).toDouble(),
    );
  }

  Widget _buildAssistantImage(bool isVN) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation:
              _assistantFloatAnimation ?? const AlwaysStoppedAnimation(0),
          builder: (context, child) => Transform.translate(
            offset: Offset(
              0,
              _isDragging ? 0 : _assistantFloatAnimation?.value ?? 0,
            ),
            child: child,
          ),
          child: Image.asset(
            'assets/tro_ly_ai.png',
            width: _assistantWidth,
            height: _assistantHeight,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.face, size: 42, color: Colors.purple),
          ),
        ),
      ],
    );
  }

  // 💬 CHỨC NĂNG CHAT (CÓ GEMINI + GIỌNG NÓI)
  Future<void> _showChatFunction(BuildContext context) async {
    await _loadChatHistory();
    if (!context.mounted) return;
    final TextEditingController chatController = TextEditingController();
    final ScrollController chatScrollController = ScrollController();
    List<String> articleSuggestions = const [];
    bool isVN = currentLanguage == "Tiếng Việt";
    if (_chatMessages.isEmpty) {
      _chatMessages = [
        {"role": "ai", "text": _defaultGreeting(isVN)},
      ];
      await _saveChatHistory(_chatMessages);
      if (!context.mounted) return;
    }
    List<Map<String, String>> messages = _chatMessages;
    bool isTyping = false;
    bool isVoiceEnabled = true;
    bool isChatOpen = true;
    bool isTranscribingVoice = false;
    bool isRecordingVoice = false;
    bool hasAskedInThisChat = false;
    bool isLoadingArticleSuggestions = false;
    bool hasLoadedArticleSuggestions = false;
    int speechRequestId = 0;

    void scrollToLatest() {
      void scrollAfter(int milliseconds) {
        Future.delayed(Duration(milliseconds: milliseconds), () {
          if (!isChatOpen || !chatScrollController.hasClients) return;
          chatScrollController.animateTo(
            chatScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isChatOpen || !chatScrollController.hasClients) return;
        if (!chatScrollController.hasClients) return;
        chatScrollController.animateTo(
          chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
        scrollAfter(120);
        scrollAfter(320);
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          if (!hasLoadedArticleSuggestions && !isLoadingArticleSuggestions) {
            isLoadingArticleSuggestions = true;
            _articleSeedSuggestions()
                .then((items) {
                  if (!isChatOpen || items.isEmpty) return;
                  setStateDialog(() {
                    articleSuggestions = items;
                    hasLoadedArticleSuggestions = true;
                    isLoadingArticleSuggestions = false;
                  });
                })
                .catchError((_) {
                  if (!isChatOpen) return;
                  setStateDialog(() {
                    hasLoadedArticleSuggestions = true;
                    isLoadingArticleSuggestions = false;
                  });
                });
          }

          Future<void> sendMessage([String? suggestedQuestion]) async {
            final userText = (suggestedQuestion ?? chatController.text).trim();
            if (userText.isEmpty) return;
            final contextText = _recentConversationContext(messages);
            setStateDialog(() {
              messages.add({"role": "user", "text": userText});
              chatController.clear();
              isTyping = true;
              hasAskedInThisChat = true;
            });
            scrollToLatest();
            await _saveChatHistory(messages);

            final result = await ApiService.askDaoCultureAssistant(
              message: userText,
              context: contextText,
            );
            final related = result['related_articles'];
            final aiMessage = <String, String>{
              "role": "ai",
              "text": _cleanAssistantText(
                result['status'] == 'success'
                    ? (result['text'] ?? '').toString()
                    : (result['message'] ??
                              'Trợ lý AI chưa thể phản hồi. Bạn thử lại nhé.')
                          .toString(),
              ),
              if (related is List && related.isNotEmpty)
                "related_articles": jsonEncode(related),
            };
            if (!isChatOpen) return;

            setStateDialog(() {
              messages.add(aiMessage);
              isTyping = false;
            });
            scrollToLatest();
            await _saveChatHistory(messages);

            // 🟢 PHÁT GIỌNG NÓI
            if (isVoiceEnabled) await _speakAiText(aiMessage["text"] ?? "");
          }

          Future<void> toggleRecording() async {
            if (isTyping) return;
            if (!isChatOpen) return;

            if (isRecordingVoice) {
              try {
                await _speechChannel.invokeMethod('stopListening');
              } on MissingPluginException {
                // Older native builds do not expose stopListening yet.
              } catch (e) {
                debugPrint("Lỗi dừng nhận dạng giọng nói Android: $e");
              }
              if (!isChatOpen) return;
              setStateDialog(() {
                isRecordingVoice = false;
                isTranscribingVoice = true;
              });
              return;
            }

            await flutterTts.stop();
            final currentRequestId = ++speechRequestId;
            setStateDialog(() {
              isRecordingVoice = true;
              isTranscribingVoice = true;
            });

            String text = "";
            try {
              final transcript = await _speechChannel
                  .invokeMethod<String>('listenOnce')
                  .timeout(const Duration(seconds: 18));
              text = transcript?.trim() ?? "";
            } catch (e) {
              debugPrint("Lỗi nhận dạng giọng nói Android: $e");
            } finally {
              if (isChatOpen && currentRequestId == speechRequestId) {
                setStateDialog(() {
                  isRecordingVoice = false;
                  isTranscribingVoice = false;
                });
              }
            }

            if (!isChatOpen || currentRequestId != speechRequestId) return;
            if (text.isEmpty) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Chưa nhận ra giọng nói, bạn thử lại nhé."),
                ),
              );
              return;
            }

            chatController.text = text;
            chatController.selection = TextSelection.fromPosition(
              TextPosition(offset: chatController.text.length),
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  Text(
                    isVN ? "💬 Trợ lý Văn hóa Dao" : "💬 Kéo chà AI",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: Icon(
                      isVoiceEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: isVoiceEnabled ? Colors.purple : Colors.grey,
                    ),
                    title: Text(
                      isVN ? "AI đọc câu trả lời" : "AI đọc",
                      style: const TextStyle(fontSize: 13),
                    ),
                    value: isVoiceEnabled,
                    activeColor: Colors.purple,
                    onChanged: (value) {
                      setStateDialog(() => isVoiceEnabled = value);
                      if (!value) {
                        flutterTts.stop();
                      } else {
                        final lastAiMessage = messages.lastWhere(
                          (message) => message["role"] == "ai",
                          orElse: () => {"text": ""},
                        );
                        _speakAiText(lastAiMessage["text"] ?? "");
                      }
                    },
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: chatScrollController,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      itemCount: messages.length,
                      itemBuilder: (c, i) {
                        return _buildMessageBubble(context, messages[i]);
                      },
                    ),
                  ),
                  if (isTyping)
                    const Text(
                      "✨ AI đang suy nghĩ...",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  if (isTranscribingVoice)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEF4),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.mic_rounded,
                            size: 16,
                            color: Colors.pink,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isRecordingVoice
                                ? "Đang nghe... bấm mic lần nữa để dừng"
                                : "Đang xử lý giọng nói...",
                            style: const TextStyle(
                              color: Colors.pink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  _SuggestionChips(
                    suggestions: _smartSuggestions(
                      messages,
                      articleSuggestions: articleSuggestions,
                      preferArticleFirst: !hasAskedInThisChat,
                    ),
                    onSelected: isTyping ? null : sendMessage,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: chatController,
                            decoration: const InputDecoration(
                              hintText: "Hỏi gì đó...",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: isRecordingVoice
                              ? "Dừng ghi âm"
                              : "Nói bằng giọng nói",
                          icon: Icon(
                            isRecordingVoice
                                ? Icons.stop_circle_rounded
                                : Icons.mic_rounded,
                            color: isRecordingVoice
                                ? Colors.pink
                                : Colors.purple,
                          ),
                          onPressed: isTyping ? null : toggleRecording,
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.purple),
                          onPressed: sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      isChatOpen = false;
      flutterTts.stop();
      chatScrollController.dispose();
    });
  }
}

class _SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String>? onSelected;

  const _SuggestionChips({required this.suggestions, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ActionChip(
            avatar: const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: Colors.purple,
            ),
            label: Text(
              suggestion,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            backgroundColor: const Color(0xFFF2F7FF),
            side: const BorderSide(color: Color(0xFFDDEBFF)),
            onPressed: onSelected == null
                ? null
                : () => onSelected!(suggestion),
          );
        },
      ),
    );
  }
}

class _RelatedArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;
  final VoidCallback onTap;

  const _RelatedArticleCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = article['title']?.toString() ?? '';
    final subtitle = article['subtitle']?.toString() ?? '';
    final category = article['category']?.toString() ?? '';
    final imageUrl = CultureShareService.normalizeImageUrl(
      article['image_url']?.toString() ?? '',
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F1EA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6D7C8)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _articleFallbackIcon(category),
                    )
                  : _articleFallbackIcon(category),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF17211F),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle.isNotEmpty ? subtitle : category,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF17211F).withValues(alpha: 0.64),
                      fontSize: 11.5,
                      height: 1.22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Color(0xFFD93829),
            ),
          ],
        ),
      ),
    );
  }

  Widget _articleFallbackIcon(String category) {
    IconData icon = Icons.auto_stories_rounded;
    Color color = const Color(0xFFD93829);
    if (category == 'Trang phục') {
      icon = Icons.checkroom_rounded;
      color = const Color(0xFFE49B2D);
    } else if (category == 'Thảo dược') {
      icon = Icons.eco_rounded;
      color = const Color(0xFF2F7D3C);
    } else if (category == 'Phong tục') {
      icon = Icons.groups_rounded;
      color = const Color(0xFF8B62C8);
    }

    return Container(
      width: 48,
      height: 48,
      color: color.withValues(alpha: 0.14),
      child: Icon(icon, color: color, size: 23),
    );
  }
}
