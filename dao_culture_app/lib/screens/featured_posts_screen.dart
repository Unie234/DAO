import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/culture_article_service.dart';
import 'customs_screen.dart';
import 'culture_detail_screen.dart';
import 'festival_screen.dart';
import 'herbal_knowledge_screen.dart';
import 'traditional_costume_screen.dart';

class FeaturedPostsScreen extends StatefulWidget {
  const FeaturedPostsScreen({super.key});

  @override
  State<FeaturedPostsScreen> createState() => _FeaturedPostsScreenState();
}

class _FeaturedPostsScreenState extends State<FeaturedPostsScreen> {
  static const Color _ink = Color(0xFF171B1F);
  static const Color _red = Color(0xFFA72C25);
  static const Color _paper = Color(0xFFFBF8F2);

  String _activeFilter = "Tất cả";
  late final Future<List<dynamic>> _articlesFuture =
      CultureArticleService.getArticles();

  final List<String> _filters = const [
    "Tất cả",
    "Có video",
    "Trang phục",
    "Lễ hội",
    "Phong tục",
    "Thảo dược",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                child: Column(
                  children: [
                    _buildSearch(),
                    const SizedBox(height: 16),
                    _buildFilters(),
                    const SizedBox(height: 18),
                    FutureBuilder<List<dynamic>>(
                      future: _articlesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(
                              child: CircularProgressIndicator(color: _red),
                            ),
                          );
                        }

                        final articles = _filteredArticles(
                          (snapshot.data ?? [])
                              .whereType<Map<String, dynamic>>()
                              .map(_FeaturedArticle.fromAdmin)
                              .whereType<_FeaturedArticle>()
                              .toList(),
                        );

                        if (articles.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text(
                              "Chưa có bài viết admin đăng",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF667286),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: articles.map(_buildArticle).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_FeaturedArticle> _filteredArticles(List<_FeaturedArticle> articles) {
    if (_activeFilter == "Tất cả") return articles;
    if (_activeFilter == "Có video") {
      return articles.where((article) => article.hasVideo).toList();
    }
    if (_activeFilter == "Thảo dược") {
      return articles
          .where((article) => _isHerbalArticleCategory(article.category))
          .toList();
    }
    return articles
        .where((article) => article.category == _activeFilter)
        .toList();
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink),
            ),
          ),
          const Text(
            "Bài viết nổi bật",
            style: TextStyle(
              color: _red,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFE7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.grey.shade600, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Tìm kiếm bài viết",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filters.map((filter) {
          final isActive = filter == _activeFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(filter),
              selected: isActive,
              showCheckmark: false,
              selectedColor: _red,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isActive ? _red : const Color(0xFFE7C88E),
              ),
              labelStyle: TextStyle(
                color: isActive ? Colors.white : _ink,
                fontWeight: FontWeight.w800,
              ),
              onSelected: (_) => setState(() => _activeFilter = filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildArticle(_FeaturedArticle article) {
    return GestureDetector(
      onTap: () => _openArticle(article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildArticleImage(article.image),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: article.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      article.category,
                      style: const TextStyle(
                        color: Color(0xFF5A3329),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 17,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    article.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF3B3B3B),
                      fontSize: 13,
                      height: 1.28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        article.duration,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          article.date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 34,
                          minHeight: 34,
                        ),
                        onPressed: () => _saveArticle(article),
                        icon: const Icon(
                          Icons.bookmark_border_rounded,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleImage(String image) {
    if (image.trim().isEmpty) {
      return _buildImageFallback();
    }
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        width: 170,
        height: 118,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImageFallback(),
      );
    }

    return Image.asset(
      image,
      width: 170,
      height: 118,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildImageFallback(),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      width: 170,
      height: 118,
      color: const Color(0xFFF4EFE8),
      alignment: Alignment.center,
      child: const Text(
        "Chưa có ảnh",
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF8C8177), fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _saveArticle(_FeaturedArticle article) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_culture_articles') ?? <String>[];
    final key = '${article.category}|${article.title}';
    final existed = saved.contains(key);
    if (!existed) {
      saved.add(key);
      await prefs.setStringList('saved_culture_articles', saved);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existed
              ? "Bài viết đã có trong danh sách lưu."
              : "Đã lưu ${article.title}.",
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openArticle(_FeaturedArticle article) {
    if (article.category == "Trang phục") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TraditionalCostumeScreen(initialDetailTitle: article.title),
        ),
      );
      return;
    }

    if (article.category == "Lễ hội") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FestivalScreen(initialDetailTitle: article.title),
        ),
      );
      return;
    }

    if (article.category == "Phong tục") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomsScreen(initialDetailTitle: article.title),
        ),
      );
      return;
    }

    if (_isHerbalArticleCategory(article.category)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HerbalKnowledgeScreen(initialDetailTitle: article.title),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CultureDetailScreen(
          title: article.title,
          type: article.videoUrl.isNotEmpty ? "video" : "image",
          mediaUrl: article.videoUrl.isNotEmpty
              ? article.videoUrl
              : _networkImageOrEmpty(article.image),
          content: article.content,
        ),
      ),
    );
  }

  static String _networkImageOrEmpty(String image) {
    return image.startsWith('http://') || image.startsWith('https://')
        ? image
        : "";
  }

  static bool _isHerbalArticleCategory(String category) {
    final value = category.trim();
    return value == "Thảo dược" ||
        value == "Tắm người" ||
        value == "Chữa bệnh" ||
        value == "Dưỡng sinh" ||
        value == "Phụ nữ" ||
        value == "Giải độc" ||
        value == "Bồi bổ";
  }

  static String _normalizeCultureImageUrl(String value) {
    final text = value.trim();
    if (text.isEmpty) return "";

    const marker = '/uploads/culture/';
    final markerIndex = text.indexOf(marker);
    if (markerIndex != -1) {
      final fileName = text.substring(markerIndex + marker.length);
      return '${CultureArticleService.baseUrl}/culture_articles/image.php?file=${Uri.encodeComponent(fileName)}';
    }

    if (text.startsWith('uploads/culture/')) {
      final fileName = text.substring('uploads/culture/'.length);
      return '${CultureArticleService.baseUrl}/culture_articles/image.php?file=${Uri.encodeComponent(fileName)}';
    }

    return text;
  }

  static String _formatArticleDate(String value) {
    final text = value.trim();
    final date = DateTime.tryParse(text);
    if (date != null) {
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    }
    return text.isNotEmpty ? text : "Vừa đăng";
  }
}

class _FeaturedArticle {
  final String title;
  final String subtitle;
  final String category;
  final Color color;
  final String image;
  final String duration;
  final String date;
  final String videoUrl;
  final String content;
  final bool hasVideo;
  final String videoTime;

  const _FeaturedArticle({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.color,
    required this.image,
    required this.duration,
    required this.date,
    required this.videoUrl,
    required this.content,
    this.hasVideo = false,
    this.videoTime = "",
  });

  static _FeaturedArticle? fromAdmin(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().trim();
    if (title.isEmpty) return null;

    final category = (data['category'] ?? 'Văn hóa').toString().trim();
    final subtitle = (data['subtitle'] ?? '').toString().trim();
    final content = (data['content'] ?? '').toString().trim();
    final image = _FeaturedPostsScreenState._normalizeCultureImageUrl(
      (data['image_url'] ?? '').toString(),
    );
    final videoUrl = (data['video_url'] ?? '').toString().trim();

    return _FeaturedArticle(
      title: title,
      subtitle: subtitle.isNotEmpty
          ? subtitle
          : content.isNotEmpty
          ? content
          : "Nội dung đang được cập nhật.",
      category: category,
      color: _categoryColor(category),
      image: image,
      duration: "Bài admin",
      date: _FeaturedPostsScreenState._formatArticleDate(
        (data['updated_at'] ?? data['created_at'] ?? '').toString(),
      ),
      videoUrl: videoUrl,
      content: content.isNotEmpty
          ? content
          : subtitle.isNotEmpty
          ? subtitle
          : "Nội dung đang được cập nhật.",
      hasVideo: videoUrl.isNotEmpty,
      videoTime: videoUrl.isNotEmpty ? "Video" : "",
    );
  }

  static Color _categoryColor(String category) {
    switch (category) {
      case "Trang phục":
        return const Color(0xFFFFF0EE);
      case "Lễ hội":
        return const Color(0xFFFFF4DE);
      case "Phong tục":
        return const Color(0xFFF1ECFF);
      case "Thảo dược":
        return const Color(0xFFE4F5E3);
      default:
        return const Color(0xFFE5F4FF);
    }
  }
}
