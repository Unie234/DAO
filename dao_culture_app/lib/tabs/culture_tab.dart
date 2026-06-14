import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/culture_detail_screen.dart';
import '../screens/customs_screen.dart';
import '../screens/dao_dictionary_screen.dart';
import '../screens/dao_learning_home_screen.dart';
import '../screens/festival_screen.dart';
import '../screens/featured_posts_screen.dart';
import '../screens/herbal_knowledge_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/traditional_costume_screen.dart';
import '../services/culture_article_service.dart';

class CultureTab extends StatefulWidget {
  final String initialCategory;
  const CultureTab({super.key, this.initialCategory = "Tất cả"});

  @override
  State<CultureTab> createState() => _CultureTabState();
}

class _CultureTabState extends State<CultureTab> {
  static const Color _ink = Color(0xFF12356A);
  static const Color _red = Color(0xFF1976D2);
  static const Color _green = Color(0xFF2F8A4C);
  static const Color _amber = Color(0xFFE9A11D);
  static const Color _paper = Color(0xFFFFFCF8);

  late String _activeCategory;
  PageController? _heroPageController;
  Timer? _heroTimer;
  int _heroIndex = 0;
  Future<List<dynamic>>? _featuredArticlesFuture;
  String _featuredArticlesCategory = "";

  final List<String> _heroImages = const [
    "assets/khampha1.png",
    "assets/khampha2.png",
    "assets/khampha3.png",
  ];

  final List<_ExploreCategory> _categories = const [
    _ExploreCategory(
      "Trang phục",
      subtitle: "Khám phá trang phục truyền thống của người Dao",
      color: Color(0xFFD52B24),
      visualBackground: Color(0xFFFFF0EE),
      visualGlow: Color(0xFFFFB9AE),
      visual: "assets/culture_category_costume.png",
    ),
    _ExploreCategory(
      "Lễ hội",
      subtitle: "Tìm hiểu các lễ hội đặc sắc và ý nghĩa",
      color: _amber,
      visualBackground: Color(0xFFFFF4DE),
      visualGlow: Color(0xFFF4C04C),
      visual: "assets/culture_category_festival.png",
    ),
    _ExploreCategory(
      "Phong tục",
      subtitle: "Khám phá phong tục, tập quán truyền thống",
      color: Color(0xFF7B61C8),
      visualBackground: Color(0xFFF1ECFF),
      visualGlow: Color(0xFFC9B7FF),
      visual: "assets/culture_category_customs.png",
    ),
    _ExploreCategory(
      "Thảo dược",
      subtitle: "Tri thức dân gian về cây thuốc và sức khỏe",
      color: _green,
      visualBackground: Color(0xFFE4F5E3),
      visualGlow: Color(0xFF9EDB91),
      visual: "assets/culture_category_herbs.png",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.initialCategory;
    _heroPageController = PageController();
    _startHeroAutoSlide();
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPageController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CultureTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != oldWidget.initialCategory) {
      _activeCategory = widget.initialCategory;
      _featuredArticlesFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  22,
                  MediaQuery.of(context).padding.top + 20,
                  22,
                  120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildHeroCard(context),
                    const SizedBox(height: 26),
                    const Text(
                      "Danh mục văn hóa",
                      style: TextStyle(
                        color: _ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryStrip(),
                    const SizedBox(height: 30),
                    _buildLearningDictionarySection(context),
                    const SizedBox(height: 30),
                    _buildSectionTitle(
                      "Bài viết nổi bật",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FeaturedPostsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeaturedPosts(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RichText(
                  maxLines: 1,
                  text: const TextSpan(
                    style: TextStyle(
                      color: _ink,
                      fontSize: 23,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Roboto',
                    ),
                    children: [
                      TextSpan(text: "Khám phá "),
                      TextSpan(
                        text: "văn hóa Dao",
                        style: TextStyle(color: _red),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Gìn giữ bản sắc - Kết nối tương lai",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none_rounded, size: 30),
              ),
              Positioned(
                right: 7,
                top: 7,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: _red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    _heroPageController ??= PageController(initialPage: _heroIndex);
    _startHeroAutoSlide();

    return Container(
      height: 235,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _heroPageController,
              itemCount: _heroImages.length,
              onPageChanged: (index) {
                setState(() {
                  _heroIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.asset(
                  _heroImages[index],
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _heroImages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: _heroIndex == index ? 18 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _heroIndex == index
                          ? _red
                          : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required VoidCallback onTap}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Text(
                  "Xem tất cả",
                  style: TextStyle(
                    color: _red,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, color: _red, size: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryStrip() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth
            .clamp(0.0, double.infinity)
            .toDouble();
        final useSingleColumn = availableWidth < 320;
        final cardWidth = useSingleColumn
            ? availableWidth
            : (availableWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _categories
              .map(
                (category) => SizedBox(
                  width: cardWidth,
                  child: _buildCategoryItem(category),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildCategoryItem(_ExploreCategory category) {
    final isActive = _activeCategory == category.title;

    return GestureDetector(
      onTap: () {
        if (category.title == "Trang phục") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TraditionalCostumeScreen()),
          );
          return;
        }

        if (category.title == "Lễ hội") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FestivalScreen()),
          );
          return;
        }

        if (category.title == "Phong tục") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomsScreen()),
          );
          return;
        }

        if (category.title == "Thảo dược") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HerbalKnowledgeScreen()),
          );
          return;
        }

        _setCategory(category.title);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 112,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? category.color : const Color(0xFFF0E6DD),
            width: isActive ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: category.color.withValues(alpha: isActive ? 0.17 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 84,
              child: _buildCategoryVisual(category),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF59615D),
                      fontSize: 10,
                      height: 1.28,
                      fontWeight: FontWeight.w600,
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

  Widget _buildCategoryVisual(_ExploreCategory category) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.94),
            category.visualBackground,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 6,
            top: 7,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: category.visualGlow.withValues(alpha: 0.62),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -8,
            bottom: -9,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: category.visualGlow.withValues(alpha: 0.24),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(2),
            child: Image.asset(category.visual, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningDictionarySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Học tiếng Dao & Tra cứu từ vựng",
          style: TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildLearningFeatureCard(context)),
            const SizedBox(width: 12),
            Expanded(child: _buildDictionaryFeatureCard(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildLearningFeatureCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DaoLearningHomeScreen()),
      ),
      child: Container(
        height: 190,
        padding: const EdgeInsets.fromLTRB(14, 16, 10, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFCF8), Color(0xFFDFF6E8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildFeatureVisualBadge(
                  visual: "assets/culture_learning_pronunciation.png",
                  background: const Color(0xFFE0F5EA),
                  glow: const Color(0xFF8ED3A5),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Học từ vựng, phiên âm",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF2F8A4C),
                      fontSize: 15,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Luyện nghe, nói và phát âm",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF355C46),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            _buildFeatureAction(
              label: "Bắt đầu học",
              background: Color(0xFF2F8A4C),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDictionaryFeatureCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DaoDictionaryScreen()),
      ),
      child: Container(
        height: 190,
        padding: const EdgeInsets.fromLTRB(14, 16, 12, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFCFEFF), Color(0xFFDFF4FF)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildFeatureVisualBadge(
                  visual: "assets/culture_dictionary_lookup.png",
                  background: const Color(0xFFD8EFFC),
                  glow: const Color(0xFF9FD7F2),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Tra cứu từ vựng",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _ink,
                      fontSize: 15,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Tra cứu 150 từ tiếng Dao thông dụng theo chủ đề",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF36505B),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            _buildFeatureAction(
              label: "Tra cứu ngay",
              background: const Color(0xFF227FC4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureAction({
    required String label,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureVisualBadge({
    required String visual,
    required Color background,
    required Color glow,
  }) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.96), background],
        ),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: glow.withValues(alpha: 0.48),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(1),
            child: Image.asset(visual, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedPosts(BuildContext context) {
    final category = _activeCategory == "Tất cả" ? "" : _activeCategory;

    return FutureBuilder<List<dynamic>>(
      future: _getFeaturedArticlesFuture(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 265,
            child: Center(child: CircularProgressIndicator(color: _red)),
          );
        }

        final posts = (snapshot.data ?? [])
            .whereType<Map<String, dynamic>>()
            .map(_FeaturedPost.fromAdmin)
            .whereType<_FeaturedPost>()
            .toList();

        if (posts.isEmpty) {
          return Container(
            height: 112,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7EEF8)),
            ),
            child: const Text(
              "Chưa có bài viết admin đăng",
              style: TextStyle(
                color: Color(0xFF667286),
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        return SizedBox(
          height: 265,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) =>
                _buildPostCard(context, posts[index]),
          ),
        );
      },
    );
  }

  Future<List<dynamic>> _getFeaturedArticlesFuture(String category) {
    if (_featuredArticlesFuture == null ||
        _featuredArticlesCategory != category) {
      _featuredArticlesCategory = category;
      _featuredArticlesFuture = CultureArticleService.getArticles(
        category: category,
      );
    }
    return _featuredArticlesFuture!;
  }

  Widget _buildPostCard(BuildContext context, _FeaturedPost post) {
    return GestureDetector(
      onTap: () => _openDetail(context, post),
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildCultureImage(post.image, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.10),
                      Colors.black.withValues(alpha: 0.86),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          post.date,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.schedule_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.duration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  void _setCategory(String category) {
    setState(() {
      _activeCategory = category;
    });
  }

  void _startHeroAutoSlide() {
    if (_heroTimer?.isActive ?? false) return;

    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final controller = _heroPageController;
      if (!mounted || controller == null || !controller.hasClients) return;

      final nextIndex = (_heroIndex + 1) % _heroImages.length;
      controller.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _openDetail(BuildContext context, _FeaturedPost post) {
    if (post.category == "Trang phục") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TraditionalCostumeScreen(initialDetailTitle: post.title),
        ),
      );
      return;
    }

    if (post.category == "Lễ hội") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FestivalScreen(initialDetailTitle: post.title),
        ),
      );
      return;
    }

    if (post.category == "Phong tục") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomsScreen(initialDetailTitle: post.title),
        ),
      );
      return;
    }

    if (post.category == "Thảo dược") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HerbalKnowledgeScreen(initialDetailTitle: post.title),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CultureDetailScreen(
          title: post.title,
          type: post.hasVideo ? "video" : "image",
          mediaUrl: post.hasVideo
              ? post.videoUrl
              : _networkImageOrEmpty(post.image),
          content: post.content,
        ),
      ),
    );
  }

  static String _networkImageOrEmpty(String image) {
    return image.startsWith('http://') || image.startsWith('https://')
        ? image
        : "";
  }

  Widget _buildCultureImage(String image, {required BoxFit fit}) {
    if (image.trim().isEmpty) {
      return _buildImageFallback();
    }
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildImageFallback(),
      );
    }
    return Image.asset(
      image,
      fit: fit,
      errorBuilder: (_, __, ___) => _buildImageFallback(),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: const Color(0xFFF4EFE8),
      alignment: Alignment.center,
      child: const Text(
        "Chưa có ảnh",
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF8C8177), fontWeight: FontWeight.w700),
      ),
    );
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
    if (text.length >= 10) {
      final date = DateTime.tryParse(text);
      if (date != null) {
        return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      }
    }
    return text.isNotEmpty ? text : "Vừa đăng";
  }
}

class _ExploreCategory {
  final String title;
  final String subtitle;
  final Color color;
  final Color visualBackground;
  final Color visualGlow;
  final String visual;

  const _ExploreCategory(
    this.title, {
    required this.subtitle,
    required this.color,
    required this.visualBackground,
    required this.visualGlow,
    required this.visual,
  });
}

class _FeaturedPost {
  final String title;
  final String date;
  final String duration;
  final String category;
  final String image;
  final String videoUrl;
  final String content;
  final bool hasVideo;

  const _FeaturedPost({
    required this.title,
    required this.date,
    required this.duration,
    required this.category,
    required this.image,
    required this.videoUrl,
    required this.content,
    this.hasVideo = false,
  });

  static _FeaturedPost? fromAdmin(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().trim();
    if (title.isEmpty) return null;

    final category = (data['category'] ?? 'Văn hóa').toString().trim();
    final image = _CultureTabState._normalizeCultureImageUrl(
      (data['image_url'] ?? '').toString(),
    );
    final videoUrl = (data['video_url'] ?? '').toString().trim();
    final content = (data['content'] ?? data['subtitle'] ?? '')
        .toString()
        .trim();

    return _FeaturedPost(
      title: title,
      date: _CultureTabState._formatArticleDate(
        (data['updated_at'] ?? data['created_at'] ?? '').toString(),
      ),
      duration: "Bài admin",
      category: category,
      image: image,
      videoUrl: videoUrl,
      content: content.isNotEmpty ? content : "Nội dung đang được cập nhật.",
      hasVideo: videoUrl.isNotEmpty,
    );
  }
}
