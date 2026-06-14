import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/customs_screen.dart';
import '../screens/culture_detail_screen.dart';
import '../screens/festival_screen.dart';
import '../screens/herbal_knowledge_screen.dart';
import '../screens/memory_challenge_topic_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/traditional_costume_screen.dart';
import '../screens/vocabulary_list_screen.dart';
import '../services/api_service.dart';
import '../services/culture_article_service.dart';
import '../services/gamification_service.dart';
import '../services/learning_progress_service.dart';

class HomeTab extends StatelessWidget {
  final void Function(int, String, {String? targetPostId}) onNavigateToCulture;
  final Function(int) onShowLevelUp;
  final VoidCallback onShowProgressDetails;
  final bool isLoggedIn;
  final String streakCount;
  final String username;
  final String avatarUrl;
  final bool hasUnreadNotifications;
  final VoidCallback? onNotificationsChanged;

  const HomeTab({
    super.key,
    required this.onNavigateToCulture,
    required this.onShowLevelUp,
    required this.onShowProgressDetails,
    this.isLoggedIn = false,
    this.streakCount = "0",
    this.username = "Khách",
    this.avatarUrl = "",
    this.hasUnreadNotifications = false,
    this.onNotificationsChanged,
  });

  static const Color _ink = Color(0xFF12356A);
  static const Color _red = Color(0xFF1976D2);
  static const Color _green = Color(0xFF2F8A4C);
  static const Color _amber = Color(0xFFE9A11D);
  static const double _heroAvatarSize = 64;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFCF8),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Column(
            children: [
              _buildTopArea(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                child: Column(
                  children: [
                    _buildSectionHeader("Tiếp tục học"),
                    const SizedBox(height: 12),
                    _buildContinueLearningCard(context),
                    const SizedBox(height: 22),
                    _buildSectionHeader("Nội dung nổi bật"),
                    const SizedBox(height: 12),
                    _buildFeaturedContentRail(context),
                    const SizedBox(height: 22),
                    _buildSectionHeader("Bài viết mới"),
                    const SizedBox(height: 12),
                    _buildLatestArticles(context),
                    const SizedBox(height: 22),
                    _buildSectionHeader("Cộng đồng nổi bật"),
                    const SizedBox(height: 12),
                    _buildCommunitySpotlight(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopArea(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Positioned.fill(child: _buildHeaderBackground()),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFFFCF8).withValues(alpha: 0.00),
                      const Color(0xFFFFFCF8).withValues(alpha: 0.12),
                      const Color(0xFFFFFCF8).withValues(alpha: 0.58),
                      const Color(0xFFFFFCF8).withValues(alpha: 0.92),
                      const Color(0xFFFFFCF8),
                    ],
                    stops: const [0.0, 0.42, 0.72, 0.92, 1.0],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                _buildHero(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 9, 16, 8),
                  child: _buildSearchBar(context),
                ),
              ],
            ),
          ],
        ),
        Container(
          color: const Color(0xFFFFFCF8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildMainBanner(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBackground() {
    return Image.asset(
      'assets/banner_main.png',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/auth_bg.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).padding.top + 166,
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 14,
        18,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildUserAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Xin chào,",
                      style: TextStyle(
                        color: _ink,
                        fontSize: 14,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoggedIn
                          ? "Người giữ hồn văn hóa Dao"
                          : "Đăng nhập để lưu tiến độ học",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  if (!isLoggedIn) {
                    _showLoginRequired(context, "xem thông báo");
                    return;
                  }
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                  onNotificationsChanged?.call();
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(Icons.notifications_none_rounded, size: 22),
                      ),
                      if (hasUnreadNotifications)
                        Positioned(
                          right: 10,
                          top: 9,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildProgressCardRealtime(context),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: _heroAvatarSize,
      height: _heroAvatarSize,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipOval(child: _buildAvatarContent()),
    );
  }

  void _showLoginRequired(BuildContext context, String actionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yêu cầu đăng nhập"),
        content: Text("Bạn cần đăng nhập để có thể $actionName."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Để sau"),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (avatarUrl.isEmpty) return _buildDefaultAvatarIcon(size: 42);

    if (avatarUrl.startsWith('http')) {
      return Image.network(
        avatarUrl,
        width: _heroAvatarSize,
        height: _heroAvatarSize,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultAvatarIcon(size: 42),
      );
    }

    final file = File(avatarUrl);
    if (!file.existsSync()) return _buildDefaultAvatarIcon(size: 42);

    return Image.file(
      file,
      width: _heroAvatarSize,
      height: _heroAvatarSize,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildDefaultAvatarIcon(size: 42),
    );
  }

  Widget _buildDefaultAvatarIcon({double size = 24}) {
    return Center(
      child: Icon(Icons.person_rounded, color: _red, size: size),
    );
  }

  Widget _buildProgressCardRealtime(BuildContext context) {
    if (!isLoggedIn) {
      return _buildGuestProgressCard(context);
    }

    final currentStreak = int.tryParse(streakCount) ?? 0;

    return FutureBuilder<_HomeProgressSnapshot>(
      future: _loadHomeProgress(),
      builder: (context, snapshot) {
        final progress = snapshot.data ?? const _HomeProgressSnapshot();
        return _buildProgressCard(currentStreak, progress);
      },
    );
  }

  Future<_HomeProgressSnapshot> _loadHomeProgress() async {
    if (!isLoggedIn) {
      return const _HomeProgressSnapshot();
    }

    final prefs = await SharedPreferences.getInstance();
    final localXP = prefs.getInt('currentXP') ?? 0;
    final localLevel = GamificationService.levelForXP(localXP);
    final userId = prefs.getString('user_id') ?? '';

    if (userId.isNotEmpty) {
      final profile = await ApiService.getUserProfile(userId);
      if (profile['status'] == 'success') {
        final serverXP = int.tryParse((profile['xp'] ?? '0').toString()) ?? 0;
        final totalXP =
            int.tryParse((profile['total_xp'] ?? '0').toString()) ?? 0;
        final journeyXP = [
          serverXP,
          totalXP,
          localXP,
        ].reduce((value, element) => value > element ? value : element);
        return _HomeProgressSnapshot(
          totalXP: journeyXP,
          level: GamificationService.levelForXP(journeyXP),
        );
      }
    }

    return _HomeProgressSnapshot(totalXP: localXP, level: localLevel);
  }

  Widget _buildGuestProgressCard(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _red.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded, color: _red),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tiến độ cá nhân chưa mở",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Đăng nhập để có điểm, cấp độ và thành tích",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF5E6A66),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int streak, _HomeProgressSnapshot progress) {
    return GestureDetector(
      onTap: onShowProgressDetails,
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.local_fire_department_rounded,
                iconColor: _red,
                value: "$streak ngày",
                label: "Chuỗi",
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                icon: Icons.stars_rounded,
                iconColor: _amber,
                value: _formatNumber(progress.totalXP),
                label: "Điểm",
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                icon: Icons.workspace_premium_rounded,
                iconColor: const Color(0xFFE66A2E),
                value: "Lv. ${progress.level}",
                label: "Cấp hiện tại",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ink.withValues(alpha: 0.70),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 36, color: const Color(0xFFE7E0D8));
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return InkWell(
      onTap: () => _showHomeSearch(context),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: Colors.grey.shade600, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Tìm bài viết văn hóa...",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHomeSearch(BuildContext context) {
    final rootContext = context;
    final searchController = TextEditingController();
    var query = "";
    var isLoading = false;
    var searchError = "";
    var results = <_HomeArticle>[];
    Timer? searchDebounce;
    var requestId = 0;
    var searchSheetOpen = true;

    void updateSearch(StateSetter setSheetState, String value) {
      query = value;
      searchDebounce?.cancel();

      final normalizedQuery = _normalizeHomeSearchText(query);
      if (normalizedQuery.isEmpty) {
        setSheetState(() {
          isLoading = false;
          searchError = "";
          results = <_HomeArticle>[];
        });
        return;
      }

      if (normalizedQuery.length < 2) {
        setSheetState(() {
          isLoading = false;
          searchError = "";
          results = <_HomeArticle>[];
        });
        return;
      }

      setSheetState(() {
        isLoading = true;
        searchError = "";
      });

      final currentRequest = ++requestId;
      searchDebounce = Timer(const Duration(milliseconds: 420), () async {
        final rows = await CultureArticleService.searchArticles(
          query,
          limit: 8,
        );
        if (!searchSheetOpen || currentRequest != requestId) return;

        try {
          setSheetState(() {
            results = rows
                .whereType<Map<String, dynamic>>()
                .map(_HomeArticle.fromAdmin)
                .whereType<_HomeArticle>()
                .toList();
            isLoading = false;
            searchError = "";
          });
        } catch (_) {
          setSheetState(() {
            isLoading = false;
            searchError = "Không thể tải kết quả tìm kiếm.";
          });
        }
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) {
          final normalizedQuery = _normalizeHomeSearchText(query);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.82,
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
              decoration: const BoxDecoration(
                color: Color(0xFFFBF8F2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6DED5),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      "Tìm kiếm",
                      style: TextStyle(
                        color: _ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) => updateSearch(setSheetState, value),
                      decoration: InputDecoration(
                        hintText: "Tìm bài viết văn hóa do admin đăng...",
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF8C8177),
                        ),
                        suffixIcon: query.trim().isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  updateSearch(setSheetState, "");
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFFE8DED4),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFFE8DED4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: _red, width: 1.3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: normalizedQuery.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 30),
                                child: Text(
                                  "Nhập từ khóa để tìm bài viết văn hóa.",
                                  style: TextStyle(
                                    color: Color(0xFF6B625A),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                          : normalizedQuery.length < 2
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 30),
                                child: Text(
                                  "Nhập ít nhất 2 ký tự để tìm kiếm.",
                                  style: TextStyle(
                                    color: Color(0xFF6B625A),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                          : isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 30),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : searchError.isNotEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 30,
                                ),
                                child: Text(
                                  searchError,
                                  style: const TextStyle(
                                    color: Color(0xFF6B625A),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                          : results.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 30),
                                child: Text(
                                  "Không tìm thấy bài viết phù hợp.",
                                  style: TextStyle(
                                    color: Color(0xFF6B625A),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: results.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, index) {
                                final article = results[index];
                                return ListTile(
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    Future<void>.delayed(
                                      const Duration(milliseconds: 260),
                                      () {
                                        if (!rootContext.mounted) return;
                                        _openSearchArticle(
                                          rootContext,
                                          article,
                                        );
                                      },
                                    );
                                  },
                                  tileColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: const BorderSide(
                                      color: Color(0xFFEDE5DA),
                                    ),
                                  ),
                                  leading: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: _red.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.article_rounded,
                                      color: _red,
                                    ),
                                  ),
                                  title: Text(
                                    article.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "${article.category} - ${article.subtitle}",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      searchSheetOpen = false;
      searchDebounce?.cancel();
      Future<void>.delayed(const Duration(milliseconds: 360), () {
        searchController.dispose();
      });
    });
  }

  String _normalizeHomeSearchText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
        .replaceAll('đ', 'd');
  }

  Widget _buildMainBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => onNavigateToCulture(1, "Tất cả"),
      child: Container(
        width: double.infinity,
        height: 238,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: _red.withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/anhoduoi.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.02),
                      Colors.black.withValues(alpha: 0.00),
                      Colors.white.withValues(alpha: 0.18),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              Positioned(
                right: 28,
                bottom: 70,
                child: SizedBox(
                  width: 188,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Khám phá",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 29,
                          height: 0.98,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 12,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        "văn hóa Dao",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          height: 1.0,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 12,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        "Gìn giữ bản sắc Dao",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 13),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _red,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: _red.withValues(alpha: 0.32),
                              blurRadius: 14,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Xem ngay",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      children: [
        Image.asset('assets/hoa_tiet.png', width: 20, height: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  Text(
                    "Xem tất cả",
                    style: TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 23),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContinueLearningCard(BuildContext context) {
    return FutureBuilder<List<TopicLearningProgress>>(
      future: _loadInProgressTopics(),
      builder: (context, snapshot) {
        final topics = snapshot.data ?? const <TopicLearningProgress>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildContinueLearningState(
            const CircularProgressIndicator(color: _red, strokeWidth: 2),
          );
        }

        if (topics.isEmpty) {
          return _buildContinueLearningState(
            const Text(
              "Chưa có bài học đang học dở.",
              style: TextStyle(
                color: Color(0xFF6D655E),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth > 390
                ? 340.0
                : (constraints.maxWidth * 0.90).clamp(276.0, 340.0);

            return SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: topics.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => SizedBox(
                  width: cardWidth,
                  child: _buildContinueTopicCard(context, topics[index]),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<TopicLearningProgress>> _loadInProgressTopics() async {
    if (!isLoggedIn) return [];

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';

    if (userId.isEmpty) return [];

    final rows = await ApiService.getLearningTopics(userId);

    return rows
        .whereType<Map<String, dynamic>>()
        .map(TopicLearningProgress.fromJson)
        .where(
          (topic) =>
              topic.total > 0 &&
              topic.learned > 0 &&
              topic.learned < topic.total,
        )
        .toList();
  }

  Widget _buildContinueTopicCard(
    BuildContext context,
    TopicLearningProgress topic,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VocabularyListScreen(
            topicId: topic.topicId,
            topicTitle: topic.title,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECE2D8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F4FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  _topicVisual(topic.title, topic.topicId),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 29, height: 1),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Chủ đề: ${topic.title}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${topic.learned} / ${topic.total} từ đã học",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6D655E),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: topic.percent,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFF0E5E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(_red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueLearningState(Widget child) {
    return Container(
      height: 76,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE2D8)),
      ),
      child: child,
    );
  }

  String _topicVisual(String title, int index) {
    final normalized = title.toLowerCase();
    if (normalized.contains('giao')) return '🗣️';
    if (normalized.contains('gia đình')) return '👨‍👩‍👧';
    if (normalized.contains('số')) return '①②③';
    if (normalized.contains('hướng') || normalized.contains('phương')) {
      return '🧭';
    }
    if (normalized.contains('địa')) return '📍';
    if (normalized.contains('thời gian')) return '🕰️';
    if (normalized.contains('thời tiết')) return '🌦️';
    if (normalized.contains('hành động')) return '🏃';
    if (normalized.contains('động')) return '🐃';
    if (normalized.contains('thực vật')) return '🌿';
    if (normalized.contains('ẩm')) return '🍲';
    if (normalized.contains('trang phục')) return '🥻';
    if (normalized.contains('màu')) return '🎨';
    if (normalized.contains('cơ thể')) return '🧍';
    if (normalized.contains('học')) return '📗';
    if (normalized.contains('hoạt')) return '🎶';
    if (normalized.contains('cảm')) return '💗';

    const fallback = [
      '🗣️',
      '👨‍👩‍👧',
      '①②③',
      '📍',
      '🕰️',
      '🌦️',
      '🐃',
      '🌿',
      '🍲',
      '🥻',
      '🎨',
      '🧍',
      '📗',
      '🎶',
      '💗',
    ];
    return fallback[index % fallback.length];
  }

  Widget _buildFeaturedContentRail(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: CultureArticleService.getArticles(mode: 'featured', limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 206,
            child: Center(child: CircularProgressIndicator(color: _red)),
          );
        }

        final items = (snapshot.data ?? [])
            .whereType<Map<String, dynamic>>()
            .map(_HomeHighlight.fromAdmin)
            .whereType<_HomeHighlight>()
            .take(5)
            .toList();

        if (items.isEmpty) {
          return Container(
            height: 96,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
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
          height: 206,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                _buildFeaturedTile(context, items[index]),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedTile(BuildContext context, _HomeHighlight item) {
    return GestureDetector(
      onTap: () => _openHighlightArticle(context, item),
      child: SizedBox(
        width: 122,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _buildHighlightImage(item.image),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 13,
                height: 1.16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _ink.withValues(alpha: 0.66),
                fontSize: 10.5,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightImage(String image) {
    if (image.trim().isEmpty) {
      return _highlightImageFallback();
    }
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        width: 122,
        height: 126,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _highlightImageFallback(),
      );
    }

    return Image.asset(
      image,
      width: 122,
      height: 126,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _highlightImageFallback(),
    );
  }

  Widget _highlightImageFallback() {
    return Container(
      width: 122,
      height: 126,
      color: const Color(0xFFF4EFE8),
      alignment: Alignment.center,
      child: const Text(
        "Chưa có ảnh",
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF8C8177), fontWeight: FontWeight.w700),
      ),
    );
  }

  void _openHighlightArticle(BuildContext context, _HomeHighlight item) {
    CultureArticleService.incrementView(item.id);
    _openArticleByCategory(
      context,
      title: item.title,
      category: item.category,
      videoUrl: item.videoUrl,
      image: item.image,
      content: item.content,
    );
  }

  void _openArticleByCategory(
    BuildContext context, {
    required String title,
    required String category,
    required String videoUrl,
    required String image,
    required String content,
  }) {
    final normalizedCategory = category.trim();
    if (normalizedCategory == "Trang phục") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TraditionalCostumeScreen(initialDetailTitle: title),
        ),
      );
      return;
    }

    if (normalizedCategory == "Lễ hội") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FestivalScreen(initialDetailTitle: title),
        ),
      );
      return;
    }

    if (normalizedCategory == "Phong tục") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomsScreen(initialDetailTitle: title),
        ),
      );
      return;
    }

    if (_isHerbalArticleCategory(normalizedCategory)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HerbalKnowledgeScreen(initialDetailTitle: title),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CultureDetailScreen(
          title: title,
          type: videoUrl.isNotEmpty ? "video" : "image",
          mediaUrl: videoUrl.isNotEmpty
              ? videoUrl
              : _networkImageOrEmpty(image),
          content: content,
        ),
      ),
    );
  }

  Widget buildLegacyCultureCategories(BuildContext context) {
    final items = [
      HomeCategory(
        title: "Trang phục",
        subtitle: "Tìm hiểu trang phục truyền thống của người Dao",
        icon: Icons.checkroom_rounded,
        color: const Color(0xFFE5F4FF),
        accent: _red,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TraditionalCostumeScreen()),
        ),
      ),
      HomeCategory(
        title: "Lễ hội",
        subtitle: "Khám phá các lễ hội đặc sắc của người Dao",
        icon: Icons.temple_buddhist_rounded,
        color: const Color(0xFFFFF4DE),
        accent: _amber,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FestivalScreen()),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth;
        if (constraints.maxWidth > 720) {
          cardWidth = (constraints.maxWidth - 12) / items.length;
        } else {
          cardWidth = (constraints.maxWidth * 0.68)
              .clamp(168.0, 220.0)
              .toDouble();
        }

        return SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return buildLegacyCategoryCard(items[index], width: cardWidth);
            },
          ),
        );
      },
    );
  }

  Widget buildLegacyCategoryCard(HomeCategory item, {required double width}) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        width: width,
        constraints: const BoxConstraints(minHeight: 104),
        padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
        decoration: BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: item.accent.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: item.accent.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.accent, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.74),
                      fontSize: 11.8,
                      height: 1.28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: item.accent, size: 24),
          ],
        ),
      ),
    );
  }

  Widget buildLegacyExperienceGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final smallCardWidth = (constraints.maxWidth - 12) / 2;

        return Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                buildLegacyExperienceCard(
                  width: smallCardWidth,
                  title: "Thử thách",
                  subtitle: "Chọn chủ đề",
                  icon: Icons.assignment_rounded,
                  color: const Color(0xFFE5F4FF),
                  accent: _red,
                  compact: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MemoryChallengeTopicScreen(),
                      ),
                    );
                  },
                ),
                buildLegacyExperienceCard(
                  width: smallCardWidth,
                  title: "Bản đồ",
                  subtitle: "Điểm văn hóa",
                  icon: Icons.location_on_rounded,
                  color: const Color(0xFFF1F6ED),
                  accent: _green,
                  compact: true,
                  onTap: () => onNavigateToCulture(2, "Tất cả"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            buildLegacyExperienceCard(
              width: constraints.maxWidth,
              title: "Hành trình của tôi",
              subtitle: "Theo dõi EXP, chuỗi ngày và huy hiệu",
              icon: Icons.workspace_premium_rounded,
              color: const Color(0xFFFFF4DE),
              accent: _amber,
              centered: true,
              onTap: onShowProgressDetails,
            ),
          ],
        );
      },
    );
  }

  Widget buildLegacyExperienceCard({
    required double width,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color accent,
    required VoidCallback onTap,
    bool compact = false,
    bool centered = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        constraints: BoxConstraints(minHeight: compact ? 118 : 132),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: centered
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: accent, size: 26),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.72),
                      fontSize: 12.2,
                      height: 1.28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: accent, size: 23),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: accent,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 15,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.72),
                      fontSize: 11.8,
                      height: 1.28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: accent, size: 26),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _ink.withValues(alpha: 0.72),
                            fontSize: 12.2,
                            height: 1.28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: accent, size: 25),
                ],
              ),
      ),
    );
  }

  Widget _buildLatestArticles(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: CultureArticleService.getArticles(mode: 'latest', limit: 3),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator(color: _red)),
          );
        }

        final articles = (snapshot.data ?? [])
            .whereType<Map<String, dynamic>>()
            .map(_HomeArticle.fromAdmin)
            .whereType<_HomeArticle>()
            .take(3)
            .toList();

        if (articles.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFE7EEF8)),
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
          children: articles
              .map(
                (article) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: GestureDetector(
                    onTap: () => _openAdminArticle(context, article),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: _buildArticleThumb(article.image),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 14,
                                  height: 1.2,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                article.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _ink.withValues(alpha: 0.66),
                                  fontSize: 11.2,
                                  height: 1.25,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    color: Color(0xFF8E847A),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    article.date,
                                    style: const TextStyle(
                                      color: Color(0xFF8E847A),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 34,
                            minHeight: 34,
                          ),
                          onPressed: () => _saveHomeArticle(context, article),
                          icon: const Icon(
                            Icons.bookmark_border_rounded,
                            color: Color(0xFF8E847A),
                            size: 19,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildArticleThumb(String image) {
    if (image.trim().isEmpty) {
      return _articleThumbFallback();
    }
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        width: 74,
        height: 74,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _articleThumbFallback(),
      );
    }

    return Image.asset(
      image,
      width: 74,
      height: 74,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _articleThumbFallback(),
    );
  }

  Widget _articleThumbFallback() {
    return Container(
      width: 74,
      height: 74,
      color: const Color(0xFFF4EFE8),
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined, color: _red),
    );
  }

  void _openAdminArticle(BuildContext context, _HomeArticle article) {
    CultureArticleService.incrementView(article.id);
    _openArticleByCategory(
      context,
      title: article.title,
      category: article.category,
      videoUrl: article.videoUrl,
      image: article.image,
      content: article.content,
    );
  }

  void _openSearchArticle(BuildContext context, _HomeArticle article) {
    CultureArticleService.incrementView(article.id);
    _openArticleByCategory(
      context,
      title: article.title,
      category: article.category,
      videoUrl: article.videoUrl,
      image: article.image,
      content: article.content,
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
    final text = value.trim().replaceAll('\\', '/');
    if (text.isEmpty) return "";

    const cultureMarker = 'uploads/culture/';
    final markerIndex = text.indexOf(cultureMarker);
    if (markerIndex >= 0) {
      final fileName = text.substring(markerIndex + cultureMarker.length);
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

  static String _buildAdminArticleContent({
    required String content,
    required String subtitle,
    required String detailJson,
  }) {
    final parts = <String>[];
    final intro = content.trim().isNotEmpty ? content.trim() : subtitle.trim();
    if (intro.isNotEmpty) parts.add(intro);

    final detail = _decodeAdminDetailJson(detailJson);
    if (detail.isNotEmpty) {
      _appendTextDetail(parts, "Phân loại", detail['category']);
      _appendTextDetail(parts, "Địa điểm", detail['location']);
      _appendTextDetail(parts, "Thời gian", detail['season'] ?? detail['time']);
      _appendListDetail(parts, "Đặc điểm / lợi ích", detail['benefits']);
      _appendRowsDetail(parts, "Ý nghĩa / thành phần", detail['meanings']);
      _appendRowsDetail(parts, "Thành phần", detail['ingredients']);
      _appendListDetail(parts, "Các bước thực hiện", detail['steps']);
      _appendTextDetail(parts, "Lưu ý", detail['warning']);
    }

    return parts.isNotEmpty
        ? parts.join("\n\n")
        : "Nội dung đang được cập nhật.";
  }

  static Map<String, dynamic> _decodeAdminDetailJson(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return {};
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  static void _appendTextDetail(
    List<String> parts,
    String title,
    dynamic value,
  ) {
    final text = value?.toString().trim() ?? "";
    if (text.isEmpty) return;
    parts.add("$title:\n$text");
  }

  static void _appendListDetail(
    List<String> parts,
    String title,
    dynamic value,
  ) {
    if (value is! List || value.isEmpty) return;
    final lines = value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .map((item) => "- $item")
        .toList();
    if (lines.isEmpty) return;
    parts.add("$title:\n${lines.join("\n")}");
  }

  static void _appendRowsDetail(
    List<String> parts,
    String title,
    dynamic value,
  ) {
    if (value is! List || value.isEmpty) return;
    final lines = <String>[];
    for (final item in value) {
      if (item is Map) {
        final rowTitle = (item['title'] ?? '').toString().trim();
        final text = (item['subtitle'] ?? item['note'] ?? item['text'] ?? '')
            .toString()
            .trim();
        if (rowTitle.isEmpty && text.isEmpty) continue;
        lines.add(text.isEmpty ? "- $rowTitle" : "- $rowTitle: $text");
      } else {
        final text = item.toString().trim();
        if (text.isNotEmpty) lines.add("- $text");
      }
    }
    if (lines.isEmpty) return;
    parts.add("$title:\n${lines.join("\n")}");
  }

  Widget _buildCommunitySpotlight(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getPopularPosts(limit: 1),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _communityShell(
            child: const SizedBox(
              height: 112,
              child: Center(child: CircularProgressIndicator(color: _red)),
            ),
          );
        }

        final posts = (snapshot.data ?? [])
            .whereType<Map<String, dynamic>>()
            .where((post) => _postContent(post).isNotEmpty)
            .toList();

        if (posts.isEmpty) {
          return _communityShell(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  "Chưa có bài viết cộng đồng nổi bật",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF667286),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }

        final post = posts.first;
        final author = _postAuthor(post);
        final content = _postContent(post);
        final images = _postImages(post).take(3).toList();
        final reactionCount = _postMetric(post, 'reaction_count');
        final likeCount = _postMetric(post, 'like_count');
        final commentCount = _postMetric(post, 'comment_count');
        final saveCount = _postMetric(post, 'save_count');
        final postId = post['id']?.toString() ?? '';

        return GestureDetector(
          onTap: () => onNavigateToCulture(
            3,
            "Tất cả",
            targetPostId: postId.isEmpty ? null : postId,
          ),
          child: _communityShell(
            minHeight: images.isNotEmpty ? 248 : 190,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildCommunityAvatar(post),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F4FF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        "Cộng đồng",
                        style: TextStyle(
                          color: _red,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink.withValues(alpha: 0.78),
                    fontSize: 12.5,
                    height: 1.36,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var index = 0; index < images.length; index++) ...[
                        if (index > 0) const SizedBox(width: 7),
                        _buildCommunityImage(images[index]),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 11),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F2EA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8DED4)),
                  ),
                  child: Row(
                    children: [
                      _communityMetric(
                        Icons.favorite_rounded,
                        reactionCount > 0 ? reactionCount : likeCount,
                        const Color(0xFFE54848),
                      ),
                      const SizedBox(width: 14),
                      _communityMetric(
                        Icons.chat_bubble_rounded,
                        commentCount,
                        const Color(0xFF1A5FB4),
                      ),
                      const SizedBox(width: 14),
                      _communityMetric(
                        Icons.bookmark_rounded,
                        saveCount,
                        const Color(0xFF8A5A20),
                      ),
                      const Spacer(),
                      const Text(
                        "Đang quan tâm",
                        style: TextStyle(
                          color: Color(0xFF8C8177),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static int _postMetric(Map<String, dynamic> post, String key) {
    return int.tryParse(post[key]?.toString() ?? '') ?? 0;
  }

  Widget _communityMetric(IconData icon, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            color: _ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _communityShell({required Widget child, double? minHeight}) {
    return Container(
      width: double.infinity,
      constraints: minHeight == null
          ? null
          : BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE1D2C2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCommunityAvatar(Map<String, dynamic> post) {
    final avatar = _normalizePostMediaUrl(
      (post['author_avatar'] ?? post['avatar_url'] ?? '').toString(),
    );
    return ClipOval(
      child: Container(
        width: 34,
        height: 34,
        color: const Color(0xFFE5F4FF),
        child: avatar.isEmpty
            ? _buildDefaultAvatarIcon(size: 21)
            : Image.network(
                avatar,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAvatarIcon(size: 21),
              ),
      ),
    );
  }

  Widget _buildCommunityImage(String url) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          height: 92,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 92,
            color: const Color(0xFFEDE4D9),
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported_rounded, color: _red),
          ),
        ),
      ),
    );
  }

  static String _postAuthor(Map<String, dynamic> post) {
    final author = (post['author_name'] ?? post['full_name'] ?? '').toString();
    final username = (post['username'] ?? '').toString();
    final value = author.trim().isNotEmpty ? author : username;
    return value.trim().isNotEmpty ? value.trim() : "Người dùng Dao";
  }

  static String _postContent(Map<String, dynamic> post) {
    return (post['content'] ?? post['caption'] ?? '').toString().trim();
  }

  static List<String> _postImages(Map<String, dynamic> post) {
    final urls = <String>[];
    void addUrl(dynamic value) {
      final url = _normalizePostMediaUrl(value?.toString() ?? '');
      if (url.isNotEmpty && !urls.contains(url)) urls.add(url);
    }

    addUrl(post['image_url']);
    if ((post['media_type'] ?? '').toString() != 'video') {
      addUrl(post['media_url']);
    }

    final gallery = post['gallery_urls'];
    if (gallery is List) {
      for (final item in gallery) {
        addUrl(item);
      }
    } else if (gallery is String && gallery.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(gallery);
        if (decoded is List) {
          for (final item in decoded) {
            addUrl(item);
          }
        }
      } catch (_) {
        for (final item in gallery.split(',')) {
          addUrl(item);
        }
      }
    }

    return urls;
  }

  static String _normalizePostMediaUrl(String value) {
    final text = value.trim().replaceAll('\\', '/');
    if (text.isEmpty) return '';

    final uri = Uri.tryParse(text);
    final path = uri?.path ?? text;
    final fileName = path
        .split('/')
        .where((part) => part.isNotEmpty)
        .lastOrNull;

    if (fileName != null &&
        (path.contains('/uploads/') ||
            path.startsWith('uploads/') ||
            path.contains('/storage/'))) {
      return '${ApiService.baseUrl}/posts/image.php'
          '?file=${Uri.encodeComponent(fileName)}';
    }

    if (text.startsWith('http://') || text.startsWith('https://')) {
      return text;
    }

    if (fileName == null) return '';
    return '${ApiService.baseUrl}/posts/image.php'
        '?file=${Uri.encodeComponent(fileName)}';
  }

  Future<void> _saveHomeArticle(
    BuildContext context,
    _HomeArticle article,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_culture_articles') ?? <String>[];
    final key = '${article.category}|${article.title}';
    final existed = saved.contains(key);
    if (!existed) {
      saved.add(key);
      await prefs.setStringList('saved_culture_articles', saved);
    }
    if (!context.mounted) return;
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

  Widget buildLegacyFeaturedStories(BuildContext context) {
    final stories = [
      _Story("Lễ cấp sắc", "Nghi lễ đánh dấu trưởng thành", "Phong tục"),
      _Story("Trang phục Dao", "Hoa văn, màu sắc và bản sắc", "Trang phục"),
      _Story("Thảo dược quý", "Tri thức cây thuốc dân gian", "Thảo dược"),
    ];

    return Column(
      children: stories.map((story) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => onNavigateToCulture(1, story.category),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEDE5DA)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/banner_main.png',
                      width: 78,
                      height: 66,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 78,
                        height: 66,
                        color: const Color(0xFFE5F4FF),
                        child: const Icon(Icons.image_rounded, color: _red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          story.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _ink.withValues(alpha: 0.70),
                            fontSize: 12.5,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _red,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildLegacyBottomHighlights(BuildContext context) {
    return _buildCommunitySpotlight(context);
  }
}

class HomeCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color accent;
  final VoidCallback onTap;

  const HomeCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.accent,
    required this.onTap,
  });
}

class _HomeHighlight {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String image;
  final String videoUrl;
  final String content;

  const _HomeHighlight({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.image,
    required this.videoUrl,
    required this.content,
  });

  static _HomeHighlight? fromAdmin(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().trim();
    if (title.isEmpty) return null;

    final category = (data['category'] ?? 'Văn hóa').toString().trim();
    final subtitle = (data['subtitle'] ?? '').toString().trim();
    final content = (data['content'] ?? '').toString().trim();
    final detailContent = HomeTab._buildAdminArticleContent(
      content: content,
      subtitle: subtitle,
      detailJson: (data['detail_json'] ?? '').toString(),
    );
    final image = HomeTab._normalizeCultureImageUrl(
      (data['image_url'] ?? '').toString(),
    );

    return _HomeHighlight(
      id: (data['id'] ?? '').toString(),
      title: title,
      subtitle: subtitle.isNotEmpty
          ? subtitle
          : content.isNotEmpty
          ? content
          : "Nội dung đang được cập nhật.",
      category: category,
      image: image,
      videoUrl: (data['video_url'] ?? '').toString().trim(),
      content: detailContent,
    );
  }
}

class _HomeArticle {
  final String id;
  final String title;
  final String subtitle;
  final String date;
  final String category;
  final String image;
  final String videoUrl;
  final String content;

  const _HomeArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.category,
    required this.image,
    required this.videoUrl,
    required this.content,
  });

  static _HomeArticle? fromAdmin(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().trim();
    if (title.isEmpty) return null;

    final category = (data['category'] ?? 'Văn hóa').toString().trim();
    final subtitle = (data['subtitle'] ?? '').toString().trim();
    final content = (data['content'] ?? '').toString().trim();
    final detailContent = HomeTab._buildAdminArticleContent(
      content: content,
      subtitle: subtitle,
      detailJson: (data['detail_json'] ?? '').toString(),
    );
    final image = HomeTab._normalizeCultureImageUrl(
      (data['image_url'] ?? '').toString(),
    );

    return _HomeArticle(
      id: (data['id'] ?? '').toString(),
      title: title,
      subtitle: subtitle.isNotEmpty
          ? subtitle
          : content.isNotEmpty
          ? content
          : "Nội dung đang được cập nhật.",
      date: HomeTab._formatArticleDate(
        (data['created_at'] ?? data['updated_at'] ?? '').toString(),
      ),
      category: category,
      image: image,
      videoUrl: (data['video_url'] ?? '').toString().trim(),
      content: detailContent,
    );
  }
}

class _Story {
  final String title;
  final String subtitle;
  final String category;

  const _Story(this.title, this.subtitle, this.category);
}

class _HomeProgressSnapshot {
  final int totalXP;
  final int level;

  const _HomeProgressSnapshot({this.totalXP = 0, this.level = 1});
}
