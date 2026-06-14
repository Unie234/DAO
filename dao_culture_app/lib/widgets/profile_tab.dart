import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/customs_screen.dart';
import '../screens/culture_detail_screen.dart';
import '../screens/dao_dictionary_screen.dart';
import '../screens/festival_screen.dart';
import '../screens/herbal_knowledge_screen.dart';
import '../screens/my_posts_screen.dart';
import '../screens/traditional_costume_screen.dart';
import '../services/api_service.dart';
import '../services/culture_article_service.dart';
import '../services/gamification_service.dart';

class ProfileTab extends StatefulWidget {
  final VoidCallback onLogoutSuccess;
  final bool isLoggedIn;
  final String username;

  const ProfileTab({
    super.key,
    required this.onLogoutSuccess,
    this.isLoggedIn = false,
    this.username = "Khách",
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final Color darkBlue = const Color(0xFF102321);
  final Color softBg = const Color(0xFFFFFBF6);
  final Color daoRed = const Color(0xFFD93829);
  final Color guestInk = const Color(0xFF12356A);
  final Color guestBlue = const Color(0xFF1976D2);
  final Color guestSoftBlue = const Color(0xFFE5F4FF);
  final Color guestGold = const Color(0xFFE9A11D);
  final ImagePicker _picker = ImagePicker();

  String _userId = "";
  String _email = "";
  String _fullName = "";
  String _avatarUrl = "";
  int _postCount = 0;
  int _visitedCount = 0;
  int _badgeCount = 0;
  int _totalXp = 0;
  int _streakCount = 0;
  bool _isLoadingProfile = true;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadProfile();
    }
  }

  @override
  void didUpdateWidget(covariant ProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoggedIn && !oldWidget.isLoggedIn) {
      _loadProfile();
    }
    if (!widget.isLoggedIn && oldWidget.isLoggedIn) {
      setState(() {
        _userId = "";
        _email = "";
        _fullName = "";
        _avatarUrl = "";
        _postCount = 0;
        _visitedCount = 0;
        _badgeCount = 0;
        _totalXp = 0;
        _streakCount = 0;
        _isLoadingProfile = false;
        _isUploadingAvatar = false;
      });
    }
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('user_id') ?? "";
    final savedUsername = prefs.getString('username') ?? widget.username;
    final savedFullName = prefs.getString('full_name') ?? "";

    if (!mounted) return;
    setState(() {
      _userId = savedUserId;
      _email = savedUsername;
      _fullName = savedFullName;
      _isLoadingProfile = true;
    });

    if (savedUserId.isEmpty) {
      if (mounted) setState(() => _isLoadingProfile = false);
      return;
    }

    final result = await ApiService.getUserProfile(savedUserId);
    if (!mounted) return;

    if (result['status'] == 'success') {
      final profileFullName = (result['full_name'] ?? "").toString().trim();
      setState(() {
        _email = (result['username'] ?? savedUsername).toString();
        _fullName = profileFullName.isNotEmpty
            ? profileFullName
            : savedFullName.trim();
        _avatarUrl = (result['avatar'] ?? "").toString();
        _postCount = int.tryParse(result['post_count'].toString()) ?? 0;
        _visitedCount = int.tryParse(result['visited_count'].toString()) ?? 0;
        _totalXp =
            int.tryParse(result['total_xp'].toString()) ??
            int.tryParse(result['xp'].toString()) ??
            0;
        _streakCount = int.tryParse(result['streak_count'].toString()) ?? 0;
        _badgeCount = _calculateBadgeCount(
          totalXp: _totalXp,
          streakCount: _streakCount,
          postCount: _postCount,
          visitedCount: _visitedCount,
        );
        _isLoadingProfile = false;
      });
      if (profileFullName.isNotEmpty && profileFullName != savedFullName) {
        await prefs.setString('full_name', profileFullName);
      }
    } else {
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_userId.isEmpty || _isUploadingAvatar) return;

    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);

    final result = await ApiService.uploadAvatar(_userId, pickedFile);

    if (!mounted) return;

    if (result['status'] == 'success') {
      final newAvatar = (result['avatar_url'] ?? result['avatar'] ?? '')
          .toString();

      setState(() {
        _isUploadingAvatar = false;
        final separator = newAvatar.contains('?') ? '&' : '?';
        _avatarUrl =
            '$newAvatar${separator}v=${DateTime.now().millisecondsSinceEpoch}';
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('avatar', newAvatar);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật ảnh đại diện')));
    } else {
      setState(() => _isUploadingAvatar = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Không tải được ảnh'),
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            "Đổi mật khẩu",
            style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPasswordField("Mật khẩu hiện tại", oldPasswordController),
              const SizedBox(height: 12),
              _buildPasswordField("Mật khẩu mới", newPasswordController),
              const SizedBox(height: 12),
              _buildPasswordField(
                "Nhập lại mật khẩu mới",
                confirmPasswordController,
              ),
            ],
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
                      final oldPassword = oldPasswordController.text.trim();
                      final newPassword = newPasswordController.text.trim();
                      final confirmPassword = confirmPasswordController.text
                          .trim();

                      if (oldPassword.isEmpty ||
                          newPassword.isEmpty ||
                          confirmPassword.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Vui lòng nhập đầy đủ thông tin!"),
                          ),
                        );
                        return;
                      }

                      if (newPassword != confirmPassword) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Mật khẩu mới không trùng khớp!"),
                          ),
                        );
                        return;
                      }

                      final passwordRules = RegExp(
                        r'^(?=.*[A-Z])(?=.*[!@#\$&*~]).{8,}$',
                      );
                      if (!passwordRules.hasMatch(newPassword)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Mật khẩu mới phải từ 8 ký tự, có chữ in hoa và ký tự đặc biệt.",
                            ),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      final result = await ApiService.changePassword(
                        _userId,
                        oldPassword,
                        newPassword,
                      );

                      if (!mounted || !dialogContext.mounted) return;
                      setDialogState(() => isSaving = false);

                      if (result['status'] == 'success') {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Đổi mật khẩu thành công!"),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['message'] ?? "Không đổi được mật khẩu",
                            ),
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Lưu", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    widget.onLogoutSuccess();
  }

  bool _isSavedPost(dynamic post) {
    if (post is! Map) return false;
    if (_isSavedCultureArticle(post)) return true;
    final value = post['is_saved'];
    return value == true ||
        value?.toString() == '1' ||
        value?.toString().toLowerCase() == 'true';
  }

  bool _isSavedCultureArticle(dynamic post) {
    return post is Map && post['_source'] == 'admin_culture';
  }

  bool _isLikedPost(dynamic post) {
    if (post is! Map) return false;
    final liked = post['is_liked'];
    final reaction = post['my_reaction']?.toString().trim() ?? "";
    return reaction.isNotEmpty ||
        liked == true ||
        liked?.toString() == '1' ||
        liked?.toString().toLowerCase() == 'true';
  }

  bool _isVideoPost(dynamic post) {
    if (post is! Map) return false;
    if (_isSavedCultureArticle(post)) {
      final videoUrl = (post['video_url'] ?? '').toString().toLowerCase();
      return videoUrl.endsWith('.mp4') ||
          videoUrl.endsWith('.mov') ||
          videoUrl.endsWith('.webm');
    }
    final mediaType = (post['media_type'] ?? '').toString().toLowerCase();
    final mediaUrl = (post['media_url'] ?? post['image_url'] ?? '')
        .toString()
        .toLowerCase();
    return mediaType == 'video' ||
        mediaUrl.endsWith('.mp4') ||
        mediaUrl.endsWith('.mov') ||
        mediaUrl.endsWith('.webm');
  }

  String _postPreview(dynamic post) {
    if (post is! Map) return "Bài viết cộng đồng";
    if (_isSavedCultureArticle(post)) {
      final title = (post['title'] ?? '').toString().trim();
      final subtitle = (post['subtitle'] ?? post['content'] ?? '')
          .toString()
          .trim();
      if (subtitle.isEmpty) return title;
      return "$title\n$subtitle";
    }
    final content = (post['content'] ?? '').toString().trim();
    if (content.isNotEmpty) return content;
    return _isVideoPost(post) ? "Video cộng đồng đã lưu" : "Bài viết đã lưu";
  }

  String _savedPostMediaUrl(dynamic rawUrl, {bool cultureArticle = false}) {
    if (rawUrl == null) return "";
    final rawUrlText = rawUrl.toString();
    if (rawUrlText.trim().isEmpty) return "";
    if (cultureArticle) {
      return _normalizeCultureImageUrl(rawUrlText);
    }
    if (rawUrlText.startsWith('http://') || rawUrlText.startsWith('https://')) {
      return rawUrlText;
    }
    final path = rawUrlText.startsWith('/')
        ? rawUrlText.substring(1)
        : rawUrlText;
    return '${ApiService.baseUrl}/$path';
  }

  List<String> _savedPostMediaUrls(dynamic post) {
    if (post is! Map) return [];
    final isCultureArticle = _isSavedCultureArticle(post);

    final rawGallery = post['gallery_urls'];
    if (rawGallery is List) {
      final galleryUrls = rawGallery
          .map(
            (url) => _savedPostMediaUrl(url, cultureArticle: isCultureArticle),
          )
          .where((url) => url.trim().isNotEmpty)
          .toList();
      if (galleryUrls.isNotEmpty) return galleryUrls;
    }

    final rawUrl = post['image_url'] ?? post['media_url'] ?? '';
    final fallbackUrl = _savedPostMediaUrl(
      rawUrl,
      cultureArticle: isCultureArticle,
    );
    return fallbackUrl.isEmpty ? [] : [fallbackUrl];
  }

  String _savedPostPrimaryMediaUrl(dynamic post) {
    final mediaUrls = _savedPostMediaUrls(post);
    return mediaUrls.isEmpty ? "" : mediaUrls.first;
  }

  String _savedPostAuthor(dynamic post) {
    if (post is! Map) return "Thành viên Dao";
    if (_isSavedCultureArticle(post)) return "Bài viết admin";
    return (post['author_name'] ??
            post['full_name'] ??
            post['username'] ??
            "Thành viên Dao")
        .toString();
  }

  String _savedPostTime(dynamic post) {
    if (post is! Map) return "Vừa xong";
    if (_isSavedCultureArticle(post)) {
      return (post['category'] ?? "Văn hóa Dao").toString();
    }
    return (post['created_at'] ?? post['time_ago'] ?? "Vừa xong").toString();
  }

  String _savedPostId(dynamic post) {
    if (post is! Map) return "";
    return (post['id'] ?? post['post_id'] ?? "").toString();
  }

  int _postCountValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<List<dynamic>> _loadSavedPosts({bool videosOnly = false}) async {
    final communityPosts = _userId.isEmpty
        ? <dynamic>[]
        : await ApiService.getPosts(_userId);
    final savedCommunityPosts = communityPosts.where((post) {
      if (!_isSavedPost(post)) return false;
      return !videosOnly || _isVideoPost(post);
    }).toList();

    if (videosOnly) return savedCommunityPosts;

    final savedCultureArticles = await _loadSavedCultureArticles();
    return [...savedCultureArticles, ...savedCommunityPosts];
  }

  Future<List<Map<String, dynamic>>> _loadSavedCultureArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKeys = prefs.getStringList('saved_culture_articles') ?? [];
    if (savedKeys.isEmpty) return [];

    final articles = await CultureArticleService.getArticles();
    final articleMaps = articles.whereType<Map<String, dynamic>>().toList();
    final saved = <Map<String, dynamic>>[];

    for (final key in savedKeys) {
      final parts = key.split('|');
      final category = parts.isNotEmpty ? parts.first.trim() : '';
      final title = parts.length > 1 ? parts.sublist(1).join('|').trim() : key;
      final article = articleMaps.cast<Map<String, dynamic>?>().firstWhere(
        (item) {
          if (item == null) return false;
          final itemTitle = (item['title'] ?? '').toString().trim();
          if (itemTitle != title) return false;

          final itemCategory = (item['category'] ?? '').toString().trim();
          final itemGroup = _cultureGroupFor(itemCategory);
          final savedGroup = _cultureGroupFor(category);
          return category.isEmpty ||
              itemCategory == category ||
              itemGroup == savedGroup;
        },
        orElse: () {
          return articleMaps.cast<Map<String, dynamic>?>().firstWhere((item) {
            if (item == null) return false;
            return (item['title'] ?? '').toString().trim() == title;
          }, orElse: () => null);
        },
      );

      final displayCategory = (article?['category'] ?? '').toString().trim();
      final articleGroup = _cultureGroupFor(displayCategory);
      final savedGroup = _cultureGroupFor(category);
      final routeCategory = articleGroup != "Văn hóa Dao"
          ? articleGroup
          : savedGroup != "Văn hóa Dao"
          ? savedGroup
          : displayCategory.isNotEmpty
          ? displayCategory
          : category;

      saved.add({
        '_source': 'admin_culture',
        '_saved_key': key,
        'title': title,
        'category': routeCategory.isEmpty ? 'Văn hóa Dao' : routeCategory,
        'saved_category': category,
        'subtitle': (article?['subtitle'] ?? article?['content'] ?? '')
            .toString(),
        'content': (article?['content'] ?? article?['subtitle'] ?? '')
            .toString(),
        'image_url': _normalizeCultureImageUrl(
          (article?['image_url'] ?? '').toString(),
        ),
        'video_url': (article?['video_url'] ?? '').toString(),
        'created_at': (article?['created_at'] ?? '').toString(),
      });
    }

    return saved;
  }

  Future<Map<String, dynamic>> _loadFavoriteGroups() async {
    if (_userId.isEmpty) {
      return {'words': <Map<String, String>>[]};
    }

    final favoriteWords = await ApiService.getDictionaryFavorites(_userId);
    return {'words': favoriteWords};
  }

  void _showSavedPostsSheet({required bool videosOnly}) {
    final title = videosOnly ? "Video đã lưu" : "Bài viết yêu thích";
    final icon = videosOnly
        ? Icons.play_circle_rounded
        : Icons.bookmark_rounded;
    final accent = videosOnly
        ? const Color(0xFFFF9C00)
        : const Color(0xFFE93D5A);
    var savedPostsFuture = _loadSavedPosts(videosOnly: videosOnly);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.72,
          ),
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
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
                const SizedBox(height: 20),
                _buildSheetTitle(icon, title, accent),
                const SizedBox(height: 14),
                Flexible(
                  child: FutureBuilder<List<dynamic>>(
                    future: savedPostsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildSheetLoading();
                      }
                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return _buildSheetEmpty(
                          videosOnly
                              ? "Bạn chưa lưu video nào."
                              : "Bạn chưa lưu bài viết yêu thích nào.",
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isCultureArticle = _isSavedCultureArticle(item);
                          return _buildSavedPostTile(
                            item,
                            accent,
                            onOpen: isCultureArticle
                                ? () {
                                    final savedItem = item;
                                    Navigator.pop(sheetContext);
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (!mounted) return;
                                          _openSavedCultureArticle(savedItem);
                                        });
                                  }
                                : null,
                            onLike: isCultureArticle
                                ? null
                                : () async {
                                    final changed = await _toggleSavedPostLike(
                                      item,
                                    );
                                    if (changed && sheetContext.mounted) {
                                      setSheetState(() {});
                                    }
                                  },
                            onComment: isCultureArticle
                                ? null
                                : () => _showSavedPostComments(
                                    item,
                                    onCommentAdded: () {
                                      if (sheetContext.mounted) {
                                        setSheetState(() {});
                                      }
                                    },
                                  ),
                            onUnsave: () async {
                              final removed = isCultureArticle
                                  ? await _unsaveCultureArticle(item)
                                  : await _unsavePost(item);
                              if (!removed || !sheetContext.mounted) return;
                              setSheetState(() {
                                savedPostsFuture = _loadSavedPosts(
                                  videosOnly: videosOnly,
                                );
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFavoritesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
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
              const SizedBox(height: 20),
              _buildSheetTitle(
                Icons.favorite_rounded,
                "Yêu thích",
                const Color(0xFFE93D78),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _loadFavoriteGroups(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildSheetLoading();
                    }
                    final data = snapshot.data ?? {};
                    final favoriteWords =
                        ((data['words'] as List?) ?? <dynamic>[])
                            .whereType<Map<String, String>>()
                            .toList();
                    if (favoriteWords.isEmpty) {
                      return _buildSheetEmpty(
                        "Bạn chưa lưu từ vựng yêu thích.",
                      );
                    }
                    return ListView(
                      shrinkWrap: true,
                      children: [
                        if (favoriteWords.isNotEmpty) ...[
                          _buildMiniSectionTitle("Từ vựng yêu thích"),
                          const SizedBox(height: 8),
                          ...favoriteWords
                              .take(6)
                              .map((word) => _buildFavoriteWordTile(word)),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const DaoDictionaryScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.menu_book_rounded),
                              label: const Text("Mở từ điển"),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetTitle(IconData icon, String title, Color accent) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: accent, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF102321),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSheetLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 34),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildSheetEmpty(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B625A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF102321),
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildSavedPostTile(
    dynamic post,
    Color accent, {
    VoidCallback? onOpen,
    Future<void> Function()? onLike,
    VoidCallback? onComment,
    Future<void> Function()? onUnsave,
  }) {
    final mediaUrl = _savedPostPrimaryMediaUrl(post);
    final mediaUrls = _savedPostMediaUrls(post);
    final isVideo = _isVideoPost(post);
    final content = _postPreview(post);
    final isLiked = _isLikedPost(post);

    final isCultureArticle = _isSavedCultureArticle(post);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDE2D2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: accent.withValues(alpha: 0.12),
                  child: Icon(Icons.person_rounded, color: accent, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _savedPostAuthor(post),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF102321),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _savedPostTime(post),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8A8178),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isVideo ? Icons.play_circle_rounded : Icons.bookmark_rounded,
                  color: accent,
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
                  color: Color(0xFF2C2A27),
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSavedPostMedia(mediaUrl, mediaUrls, isVideo),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isCultureArticle) ...[
                  InkWell(
                    onTap: onLike,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 19,
                            color: isLiked ? accent : const Color(0xFF6B625A),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            (post is Map
                                    ? (post['reaction_count'] ??
                                          post['like_count'] ??
                                          0)
                                    : 0)
                                .toString(),
                            style: const TextStyle(
                              color: Color(0xFF6B625A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: onComment,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: Color(0xFF6B625A),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            (post is Map ? (post['comment_count'] ?? 0) : 0)
                                .toString(),
                            style: const TextStyle(
                              color: Color(0xFF6B625A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (isCultureArticle)
                  TextButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text("Xem"),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                if (onUnsave != null)
                  TextButton.icon(
                    onPressed: onUnsave,
                    icon: const Icon(Icons.bookmark_remove_rounded, size: 18),
                    label: const Text("Bỏ lưu"),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPostMedia(
    String primaryMediaUrl,
    List<String> mediaUrls,
    bool isVideo,
  ) {
    if (isVideo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: const Color(0xFF102321)),
              if (!primaryMediaUrl.toLowerCase().endsWith('.mp4') &&
                  !primaryMediaUrl.toLowerCase().endsWith('.mov') &&
                  !primaryMediaUrl.toLowerCase().endsWith('.webm'))
                _buildSavedPostMediaImage(
                  primaryMediaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: const Color(0xFF102321)),
                ),
              Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (mediaUrls.length == 1) {
      return _buildSavedPostImage(mediaUrls.first, aspectRatio: 16 / 9);
    }

    return GridView.builder(
      itemCount: mediaUrls.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) => _buildSavedPostImage(mediaUrls[index]),
    );
  }

  Widget _buildSavedPostImage(String imageUrl, {double aspectRatio = 1}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: _buildSavedPostMediaImage(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFF4F1ED),
            child: const Icon(
              Icons.broken_image_rounded,
              color: Color(0xFF9A938B),
            ),
          ),
        ),
      ),
    );
  }

  bool _isNetworkMediaUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  Widget _buildSavedPostMediaImage(
    String imageUrl, {
    required BoxFit fit,
    required ImageErrorWidgetBuilder errorBuilder,
  }) {
    if (_isNetworkMediaUrl(imageUrl)) {
      return Image.network(imageUrl, fit: fit, errorBuilder: errorBuilder);
    }

    return Image.asset(imageUrl, fit: fit, errorBuilder: errorBuilder);
  }

  Future<bool> _toggleSavedPostLike(dynamic post) async {
    final postId = _savedPostId(post);
    if (_userId.isEmpty || postId.isEmpty || post is! Map) return false;

    final wasLiked = _isLikedPost(post);
    final count = _postCountValue(
      post['reaction_count'] ?? post['like_count'] ?? 0,
    );
    final changed = await ApiService.togglePostReaction(
      postId,
      _userId,
      'like',
    );
    if (!changed) return false;

    post['my_reaction'] = wasLiked ? '' : 'like';
    post['is_liked'] = !wasLiked;
    post['reaction_count'] = wasLiked
        ? (count - 1).clamp(0, 1 << 30)
        : count + 1;
    return true;
  }

  String _normalizeCultureImageUrl(String value) {
    final text = value.trim();
    if (text.isEmpty) return "";
    final normalized = text.replaceAll('\\', '/');
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      final uri = Uri.tryParse(normalized);
      if (uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
        final baseUri = Uri.parse(CultureArticleService.baseUrl);
        return baseUri.replace(path: uri.path, query: uri.query).toString();
      }
      return normalized;
    }

    final hostBase = CultureArticleService.baseUrl.replaceFirst(
      RegExp(r'/dao_api/?$'),
      '',
    );
    if (normalized.startsWith('/dao_api/')) {
      return '$hostBase$normalized';
    }
    if (normalized.startsWith('dao_api/')) {
      return '$hostBase/$normalized';
    }
    if (normalized.startsWith('/culture_articles/') ||
        normalized.startsWith('culture_articles/')) {
      final clean = normalized.replaceFirst(RegExp(r'^/+'), '');
      return '${CultureArticleService.baseUrl}/$clean';
    }

    const marker = '/uploads/culture/';
    final markerIndex = normalized.indexOf(marker);
    if (markerIndex != -1) {
      final fileName = normalized.substring(markerIndex + marker.length);
      return '${CultureArticleService.baseUrl}/culture_articles/image.php?file=${Uri.encodeComponent(fileName)}';
    }

    if (normalized.startsWith('uploads/culture/')) {
      final fileName = normalized.substring('uploads/culture/'.length);
      return '${CultureArticleService.baseUrl}/culture_articles/image.php?file=${Uri.encodeComponent(fileName)}';
    }

    if (normalized.startsWith('/uploads/') ||
        normalized.startsWith('uploads/')) {
      final clean = normalized.replaceFirst(RegExp(r'^/+'), '');
      return '${CultureArticleService.baseUrl}/$clean';
    }

    return normalized;
  }

  void _openSavedCultureArticle(dynamic item) {
    if (item is! Map) return;
    final title = (item['title'] ?? '').toString();
    final category = _cultureGroupFor(
      (item['category'] ?? item['saved_category'] ?? '').toString(),
    );
    final videoUrl = (item['video_url'] ?? '').toString().trim();

    Widget screen;
    if (category == "Trang phục") {
      screen = TraditionalCostumeScreen(initialDetailTitle: title);
    } else if (category == "Lễ hội") {
      screen = FestivalScreen(initialDetailTitle: title);
    } else if (category == "Phong tục") {
      screen = CustomsScreen(initialDetailTitle: title);
    } else if (category == "Thảo dược" || _isHerbalCategory(category)) {
      screen = HerbalKnowledgeScreen(initialDetailTitle: title);
    } else {
      screen = CultureDetailScreen(
        title: title,
        type: videoUrl.isNotEmpty ? "video" : "image",
        mediaUrl: videoUrl.isNotEmpty
            ? videoUrl
            : (item['image_url'] ?? '').toString(),
        content: (item['content'] ?? item['subtitle'] ?? '').toString(),
      );
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  bool _isHerbalCategory(String category) {
    final value = category.trim();
    return value == "Thảo dược" ||
        value == "Tắm người" ||
        value == "Chữa bệnh" ||
        value == "Dưỡng sinh" ||
        value == "Phụ nữ" ||
        value == "Giải độc" ||
        value == "Bồi bổ";
  }

  String _cultureGroupFor(String category) {
    final value = category.trim().toLowerCase();
    if (value.isEmpty) return "Văn hóa Dao";
    if (value.contains("trang phục") ||
        value.contains("lễ phục") ||
        value.contains("thêu") ||
        value.contains("phụ kiện")) {
      return "Trang phục";
    }
    if (value.contains("lễ hội") || value.contains("nghi lễ")) {
      return "Lễ hội";
    }
    if (value.contains("phong tục") ||
        value.contains("tang ma") ||
        value.contains("kiêng") ||
        value.contains("tín ngưỡng") ||
        value.contains("tâm linh")) {
      return "Phong tục";
    }
    if (_isHerbalCategory(category)) return "Thảo dược";
    return category.trim();
  }

  void _showSavedPostComments(
    dynamic post, {
    required VoidCallback onCommentAdded,
  }) {
    final postId = _savedPostId(post);
    if (_userId.isEmpty || postId.isEmpty || post is! Map) return;

    final commentController = TextEditingController();
    var commentsFuture = ApiService.getComments(postId, userId: _userId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.76,
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
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
                  _buildSheetTitle(
                    Icons.chat_bubble_rounded,
                    "Bình luận",
                    const Color(0xFFE93D5A),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: FutureBuilder<List<dynamic>>(
                      future: commentsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildSheetLoading();
                        }
                        final comments = snapshot.data ?? [];
                        if (comments.isEmpty) {
                          return _buildSheetEmpty(
                            "Chưa có bình luận cho bài viết này.",
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          itemCount: comments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              _buildSavedPostCommentTile(comments[index]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: "Nhập bình luận...",
                            filled: true,
                            fillColor: const Color(0xFFF8F5EF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: () async {
                          final content = commentController.text.trim();
                          if (content.isEmpty) return;

                          final added = await ApiService.addComment(
                            postId,
                            _userId,
                            content,
                          );
                          if (!added || !sheetContext.mounted) return;

                          commentController.clear();
                          post['comment_count'] =
                              _postCountValue(post['comment_count']) + 1;
                          onCommentAdded();
                          setSheetState(() {
                            commentsFuture = ApiService.getComments(
                              postId,
                              userId: _userId,
                            );
                          });
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFE93D5A),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(commentController.dispose);
  }

  Widget _buildSavedPostCommentTile(dynamic comment) {
    final author =
        (comment is Map
                ? comment['author_name'] ??
                      comment['full_name'] ??
                      comment['username']
                : null)
            ?.toString() ??
        "Thành viên Dao";
    final content = (comment is Map ? comment['content'] : '').toString();
    final time =
        (comment is Map ? comment['created_at'] ?? comment['time_ago'] : null)
            ?.toString() ??
        "Vừa xong";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE2D2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFFDEBED),
            child: Icon(
              Icons.person_rounded,
              color: Color(0xFFE93D5A),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF102321),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF8A8178),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  style: const TextStyle(
                    color: Color(0xFF2C2A27),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _unsavePost(dynamic post) async {
    final postId = _savedPostId(post);
    if (_userId.isEmpty || postId.isEmpty) return false;

    final removed = await ApiService.toggleSavePost(postId, _userId);
    if (!mounted) return removed;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removed
              ? "Đã bỏ lưu bài viết yêu thích."
              : "Không bỏ lưu được bài viết.",
        ),
      ),
    );
    return removed;
  }

  Future<bool> _unsaveCultureArticle(dynamic post) async {
    if (post is! Map) return false;
    final key = (post['_saved_key'] ?? '').toString();
    if (key.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_culture_articles') ?? <String>[];
    final removed = saved.remove(key);
    if (removed) {
      await prefs.setStringList('saved_culture_articles', saved);
    }
    if (!mounted) return removed;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removed ? "Đã bỏ lưu bài viết admin." : "Không bỏ lưu được bài viết.",
        ),
      ),
    );
    return removed;
  }

  Widget _buildFavoriteWordTile(Map<String, String> word) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE2D2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.translate_rounded, color: Color(0xFFE93D78)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "${word['vietnamese'] ?? ''} - ${word['dao'] ?? ''}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF102321),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPersonalInfo() {
    final nameController = TextEditingController(text: _displayName);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5E8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.person_rounded, color: daoRed),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Thông tin cá nhân",
                          style: TextStyle(
                            color: Color(0xFF102321),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameController,
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText: "Tên hiển thị",
                      prefixIcon: const Icon(Icons.badge_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8F5EF),
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoLine(
                    Icons.alternate_email_rounded,
                    "Tài khoản đăng nhập",
                    _email,
                  ),
                  _buildInfoLine(
                    Icons.article_rounded,
                    "Bài đã đăng",
                    _postCount.toString(),
                  ),
                  _buildInfoLine(
                    Icons.workspace_premium_rounded,
                    "Huy hiệu",
                    _badgeCount.toString(),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final nextName = nameController.text.trim();
                              if (nextName.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Tên hiển thị không được để trống",
                                    ),
                                  ),
                                );
                                return;
                              }

                              setSheetState(() => isSaving = true);
                              final result = await ApiService.updateUserProfile(
                                userId: _userId,
                                fullName: nextName,
                              );

                              if (!mounted || !sheetContext.mounted) return;
                              setSheetState(() => isSaving = false);

                              if (result['status'] == 'success') {
                                setState(() => _fullName = nextName);
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString('full_name', nextName);
                                if (!mounted || !sheetContext.mounted) return;
                                Navigator.pop(sheetContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Đã cập nhật tên hiển thị"),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result['message'] ??
                                          "Không cập nhật được tên",
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: const Text("Lưu thay đổi"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: daoRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    final controller = TextEditingController();
    bool isAnonymous = false;
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Hỗ trợ & góp ý",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                minLines: 4,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: "Bạn nghĩ sao về app này?...",
                  filled: true,
                  fillColor: const Color(0xFFF6F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: isAnonymous,
                    activeColor: daoRed,
                    onChanged: isSending
                        ? null
                        : (value) {
                            setDialogState(() {
                              isAnonymous = value ?? false;
                            });
                          },
                  ),
                  const Text(
                    "Gửi ẩn danh",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(dialogContext),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: daoRed),
              onPressed: isSending
                  ? null
                  : () async {
                      final content = controller.text.trim();
                      if (content.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Vui lòng nhập nội dung góp ý"),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSending = true);
                      final nameToSend = isAnonymous
                          ? "Người dùng ẩn danh"
                          : _displayName;
                      final success = await ApiService.sendFeedback(
                        _userId,
                        nameToSend,
                        content,
                      );

                      if (!mounted || !dialogContext.mounted) return;
                      setDialogState(() => isSending = false);
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? "Đã gửi góp ý, cảm ơn bạn!"
                                : "Không gửi được góp ý",
                          ),
                        ),
                      );
                    },
              child: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Gửi", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: daoRed, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF7B756F),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? "Chưa cập nhật" : value,
                  style: const TextStyle(
                    color: Color(0xFF102321),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBadgesSheet() {
    final badges = _buildBadges();
    final unlockedCount = badges.where((badge) => badge.unlocked).length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6DED5),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2DB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFF8A420),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Huy hiệu của tôi",
                      style: TextStyle(
                        color: Color(0xFF102321),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBadgeSummary(unlockedCount, badges.length),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: badges.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final badge = badges[index];
                    return _buildBadgeTile(badge);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeSummary(int unlockedCount, int totalCount) {
    final progress = totalCount == 0 ? 0.0 : unlockedCount / totalCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE2D2)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFC857), Color(0xFFD93829)],
              ),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$unlockedCount/$totalCount huy hiệu đã mở khóa",
                  style: const TextStyle(
                    color: Color(0xFF102321),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: const Color(0xFFD93829),
                    backgroundColor: const Color(0xFFEDE2D2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_BadgeItem> _buildBadges() {
    return [
      _BadgeItem(
        Icons.emoji_events_rounded,
        "Người khởi đầu",
        "Có mặt trong hành trình văn hóa Dao",
        true,
        const Color(0xFFF8A420),
        category: "Hành trình",
        current: 1,
        target: 1,
      ),
      _BadgeItem(
        Icons.local_fire_department_rounded,
        "Giữ lửa học tập",
        "Đạt chuỗi học 3 ngày",
        _streakCount >= 3,
        const Color(0xFFFF6B35),
        category: "Chuỗi ngày",
        current: _streakCount,
        target: 3,
      ),
      _BadgeItem(
        Icons.whatshot_rounded,
        "Lửa bền bỉ",
        "Đạt chuỗi học 7 ngày",
        _streakCount >= 7,
        const Color(0xFFE85D04),
        category: "Chuỗi ngày",
        current: _streakCount,
        target: 7,
      ),
      _BadgeItem(
        Icons.local_activity_rounded,
        "Ngọn lửa Dao",
        "Đạt chuỗi học 14 ngày",
        _streakCount >= 14,
        const Color(0xFFD93829),
        category: "Chuỗi ngày",
        current: _streakCount,
        target: 14,
      ),
      _BadgeItem(
        Icons.flare_rounded,
        "Lửa không tắt",
        "Đạt chuỗi học 30 ngày",
        _streakCount >= 30,
        const Color(0xFFB23A48),
        category: "Chuỗi ngày",
        current: _streakCount,
        target: 30,
      ),
      _BadgeItem(
        Icons.bolt_rounded,
        "Một mùa bền chí",
        "Đạt chuỗi học 60 ngày",
        _streakCount >= 60,
        const Color(0xFF8B2F3C),
        category: "Chuỗi ngày",
        current: _streakCount,
        target: 60,
      ),
      _BadgeItem(
        Icons.auto_stories_rounded,
        "Người học chăm chỉ",
        "Đạt 100 EXP",
        _totalXp >= 100,
        const Color(0xFF3D9143),
        category: "Kinh nghiệm",
        current: _totalXp,
        target: 100,
      ),
      _BadgeItem(
        Icons.school_rounded,
        "Bạn đồng hành văn hóa",
        "Đạt 250 EXP",
        _totalXp >= 250,
        const Color(0xFF397A4A),
        category: "Kinh nghiệm",
        current: _totalXp,
        target: 250,
      ),
      _BadgeItem(
        Icons.psychology_rounded,
        "Am hiểu văn hóa",
        "Đạt 450 EXP",
        _totalXp >= 450,
        const Color(0xFF8B62C8),
        category: "Kinh nghiệm",
        current: _totalXp,
        target: 450,
      ),
      _BadgeItem(
        Icons.diamond_rounded,
        "Tri thức bản làng",
        "Đạt 700 EXP",
        _totalXp >= 700,
        const Color(0xFF397FA8),
        category: "Kinh nghiệm",
        current: _totalXp,
        target: 700,
      ),
      _BadgeItem(
        Icons.military_tech_rounded,
        "Người gìn giữ",
        "Đạt 1000 EXP",
        _totalXp >= 1000,
        const Color(0xFFB23A48),
        category: "Kinh nghiệm",
        current: _totalXp,
        target: 1000,
      ),
      _BadgeItem(
        Icons.workspace_premium_rounded,
        "Đại sứ văn hóa Dao",
        "Đạt 1500 EXP",
        _totalXp >= 1500,
        const Color(0xFFF8A420),
        category: "Kinh nghiệm",
        current: _totalXp,
        target: 1500,
      ),
      _BadgeItem(
        Icons.shield_rounded,
        "Người giữ tri thức",
        "Đạt 3000 EXP",
        _totalXp >= 3000,
        const Color(0xFF2F6F88),
        category: "Kinh nghiệm",
        current: _totalXp,
        target: 3000,
      ),
      _BadgeItem(
        Icons.stars_rounded,
        "Bậc thầy văn hóa",
        "Đạt 5000 EXP",
        _totalXp >= 5000,
        const Color(0xFF7657D8),
        category: "Kinh nghiệm",
        current: _totalXp,
        target: 5000,
      ),
      _BadgeItem(
        Icons.article_rounded,
        "Người kể chuyện",
        "Đăng ít nhất 1 bài viết",
        _postCount >= 1,
        const Color(0xFFE93D5A),
        category: "Cộng đồng",
        current: _postCount,
        target: 1,
      ),
      _BadgeItem(
        Icons.forum_rounded,
        "Tiếng nói cộng đồng",
        "Đăng ít nhất 3 bài viết",
        _postCount >= 3,
        const Color(0xFFD93829),
        category: "Cộng đồng",
        current: _postCount,
        target: 3,
      ),
      _BadgeItem(
        Icons.campaign_rounded,
        "Lan tỏa bản sắc",
        "Đăng ít nhất 5 bài viết",
        _postCount >= 5,
        const Color(0xFFE66A2E),
        category: "Cộng đồng",
        current: _postCount,
        target: 5,
      ),
      _BadgeItem(
        Icons.groups_rounded,
        "Người kết nối",
        "Đăng ít nhất 10 bài viết",
        _postCount >= 10,
        const Color(0xFFC43E6A),
        category: "Cộng đồng",
        current: _postCount,
        target: 10,
      ),
      _BadgeItem(
        Icons.public_rounded,
        "Sứ giả cộng đồng",
        "Đăng ít nhất 25 bài viết",
        _postCount >= 25,
        const Color(0xFF8B62C8),
        category: "Cộng đồng",
        current: _postCount,
        target: 25,
      ),
      _BadgeItem(
        Icons.menu_book_rounded,
        "Người học mới",
        "Có mục học đã được ghi nhận",
        _visitedCount >= 1,
        const Color(0xFF397A4A),
        category: "Học tập",
        current: _visitedCount,
        target: 1,
      ),
      _BadgeItem(
        Icons.auto_stories_rounded,
        "Chăm chỉ học Dao",
        "Ghi nhận ít nhất 5 mục học",
        _visitedCount >= 5,
        const Color(0xFF3D9143),
        category: "Học tập",
        current: _visitedCount,
        target: 5,
      ),
      _BadgeItem(
        Icons.library_books_rounded,
        "Bước đều học tập",
        "Ghi nhận ít nhất 15 mục học",
        _visitedCount >= 15,
        const Color(0xFF397FA8),
        category: "Học tập",
        current: _visitedCount,
        target: 15,
      ),
      _BadgeItem(
        Icons.local_library_rounded,
        "Người gom chữ Dao",
        "Ghi nhận ít nhất 30 mục học",
        _visitedCount >= 30,
        const Color(0xFF3D9143),
        category: "Học tập",
        current: _visitedCount,
        target: 30,
      ),
      _BadgeItem(
        Icons.workspace_premium_rounded,
        "Kho tri thức nhỏ",
        "Ghi nhận ít nhất 100 mục học",
        _visitedCount >= 100,
        const Color(0xFFF8A420),
        category: "Học tập",
        current: _visitedCount,
        target: 100,
      ),
    ];
  }

  int _calculateBadgeCount({
    required int totalXp,
    required int streakCount,
    required int postCount,
    required int visitedCount,
  }) {
    final checks = [
      true,
      streakCount >= 3,
      streakCount >= 7,
      streakCount >= 14,
      streakCount >= 30,
      streakCount >= 60,
      totalXp >= 100,
      totalXp >= 250,
      totalXp >= 450,
      totalXp >= 700,
      totalXp >= 1000,
      totalXp >= 1500,
      totalXp >= 3000,
      totalXp >= 5000,
      postCount >= 1,
      postCount >= 3,
      postCount >= 5,
      postCount >= 10,
      postCount >= 25,
      visitedCount >= 1,
      visitedCount >= 5,
      visitedCount >= 15,
      visitedCount >= 30,
      visitedCount >= 100,
    ];
    return checks.where((unlocked) => unlocked).length;
  }

  Widget _buildBadgeTile(_BadgeItem badge) {
    final progress = badge.target <= 0
        ? (badge.unlocked ? 1.0 : 0.0)
        : (badge.current / badge.target).clamp(0.0, 1.0);
    final medalColor = badge.unlocked ? badge.color : const Color(0xFFB8B1AA);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: badge.unlocked
            ? badge.color.withValues(alpha: 0.08)
            : const Color(0xFFF5F2EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badge.unlocked
              ? badge.color.withValues(alpha: 0.38)
              : const Color(0xFFE6DED5),
        ),
        boxShadow: [
          if (badge.unlocked)
            BoxShadow(
              color: badge.color.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: badge.unlocked
                        ? [badge.color.withValues(alpha: 0.92), badge.color]
                        : [const Color(0xFFD8D2CA), const Color(0xFFAFA79F)],
                  ),
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 2,
                  ),
                ),
                child: Icon(badge.icon, color: Colors.white, size: 27),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: badge.unlocked
                        ? const Color(0xFF2F9E57)
                        : const Color(0xFF8F8880),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    badge.unlocked ? Icons.check_rounded : Icons.lock_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: medalColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge.category,
                        style: TextStyle(
                          color: medalColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      badge.unlocked ? "Đã đạt" : "Đang mở",
                      style: TextStyle(
                        color: medalColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  badge.title,
                  style: const TextStyle(
                    color: Color(0xFF102321),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  style: const TextStyle(
                    color: Color(0xFF756F68),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          color: medalColor,
                          backgroundColor: const Color(0xFFE6DED5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "${badge.current.clamp(0, badge.target)}/${badge.target}",
                      style: TextStyle(
                        color: medalColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      return _buildLoginRequired();
    }

    final displayName = _displayName;

    return Container(
      color: softBg,
      width: double.infinity,
      child: RefreshIndicator(
        onRefresh: _loadProfile,
        color: daoRed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 42, 18, 120),
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 18),
              _buildProfileCard(displayName),
              const SizedBox(height: 14),
              _buildStatsPanel(),
              const SizedBox(height: 14),
              _buildMenuSection(_contentMenuItems()),
              const SizedBox(height: 14),
              _buildMenuSection(_accountMenuItems()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Cá nhân",
            style: TextStyle(
              color: Color.fromARGB(255, 0, 0, 0),
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 9),
          Image.asset(
            "assets/hoa_tiet.png",
            width: 28,
            height: 28,
            color: daoRed,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.auto_awesome_rounded, color: daoRed, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String displayName) {
    final level = GamificationService.levelForXP(_totalXp);
    final currentLevelStart = GamificationService.currentLevelStartXP(level);
    final nextLevelXp = GamificationService.nextLevelXP(level);
    final levelRange = (nextLevelXp - currentLevelStart)
        .clamp(1, 999999)
        .toInt();
    final progressXp = ((_totalXp - currentLevelStart).clamp(
      0,
      levelRange,
    )).toInt();
    final progressValue = level >= GamificationService.levelThresholds.length
        ? 1.0
        : progressXp / levelRange;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173D61).withValues(alpha: 0.11),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  width: 372,
                  child: Image.asset(
                    "assets/banner_main.png",
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.42, 0.12),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white,
                          Colors.white.withValues(alpha: 0.72),
                          const Color(0xFFEAF6FF).withValues(alpha: 0.04),
                        ],
                        stops: const [0, 0.34, 0.8],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.01),
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.06),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -34,
                  left: -20,
                  child: Opacity(
                    opacity: 0.07,
                    child: Image.asset("assets/hoa_tiet.png", width: 188),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 132),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final identity = _buildIdentity(displayName, level);
                        if (constraints.maxWidth < 270) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAvatar(size: 100),
                              const SizedBox(height: 12),
                              identity,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildAvatar(size: 102),
                            const SizedBox(width: 11),
                            Container(
                              width: 1,
                              height: 98,
                              color: const Color(
                                0xFF2458C4,
                              ).withValues(alpha: 0.12),
                            ),
                            const SizedBox(width: 11),
                            Expanded(child: identity),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _buildXpPanel(
                totalXp: _totalXp,
                progressXp: progressXp,
                nextLevelXp: nextLevelXp,
                levelRange: levelRange,
                progressValue: progressValue,
                level: level,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({double size = 112}) {
    return GestureDetector(
      onTap: _pickAndUploadAvatar,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFFFF3E6),
              child: ClipOval(child: _buildProfileAvatarContent(size)),
            ),
          ),
          if (_isUploadingAvatar)
            Container(
              width: size - 8,
              height: size - 8,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2458C4),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity(String displayName, int level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2458C4),
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE7EEFF),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                "Lv.$level",
                style: TextStyle(
                  color: const Color(0xFF2458C4),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        _buildProfileMeta(Icons.diamond_rounded, "Người yêu văn hóa Dao"),
        const SizedBox(height: 8),
        _buildProfileMeta(
          Icons.email_outlined,
          _email.isEmpty ? "Chưa cập nhật tài khoản" : _email,
        ),
      ],
    );
  }

  Widget _buildProfileMeta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2759C7), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildXpPanel({
    required int totalXp,
    required int progressXp,
    required int nextLevelXp,
    required int levelRange,
    required double progressValue,
    required int level,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2458C4).withValues(alpha: 0.09),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 112,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 15),
            decoration: const BoxDecoration(
              color: Color(0xFF2458C4),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(22)),
            ),
            child: Column(
              children: [
                const Text(
                  "EXP hiện tại",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatNumber(totalXp),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$progressXp / $levelRange EXP",
                    style: const TextStyle(
                      color: Color(0xFF33404E),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 9,
                      value: progressValue,
                      backgroundColor: const Color(0xFFE6EDF7),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF2458C4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    level >= GamificationService.levelThresholds.length
                        ? "Bạn đã đạt cấp cao nhất hiện tại"
                        : "Còn ${nextLevelXp - totalXp} EXP để lên cấp ${level + 1}",
                    style: const TextStyle(
                      color: Color(0xFF596573),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatarContent(double size) {
    final defaultAvatar = Icon(
      Icons.person_rounded,
      color: daoRed,
      size: size * 0.56,
    );
    if (_avatarUrl.isEmpty) return defaultAvatar;
    if (_avatarUrl.startsWith('http')) {
      return Image.network(
        _avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => defaultAvatar,
      );
    }

    final avatarFile = File(_avatarUrl);
    if (!avatarFile.existsSync()) return defaultAvatar;
    return Image.file(
      avatarFile,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => defaultAvatar,
    );
  }

  Widget _buildStatsPanel() {
    if (_isLoadingProfile) {
      return const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173D61).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            Icons.article_rounded,
            _postCount.toString(),
            "Bài đã đăng",
            const Color(0xFFE93D5A),
          ),
          _buildStatDivider(),
          _buildStatItem(
            Icons.menu_book_rounded,
            _visitedCount.toString(),
            "Mục đã học",
            const Color(0xFF3DAA35),
          ),
          _buildStatDivider(),
          _buildStatItem(
            Icons.military_tech_rounded,
            _badgeCount.toString(),
            "Huy hiệu",
            const Color(0xFF7657D8),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: darkBlue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF65707D),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 66, color: const Color(0xFFE5EAF1));
  }

  List<_ProfileMenuItem> _contentMenuItems() {
    return [
      _ProfileMenuItem(
        Icons.article_outlined,
        "Bài viết của tôi",
        "Quản lý những bài viết bạn đã đăng",
        const Color(0xFFE93D5A),
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyPostsScreen()),
          );
        },
      ),
      _ProfileMenuItem(
        Icons.bookmark_rounded,
        "Bài viết yêu thích",
        "Những bài viết văn hóa bạn đã lưu",
        const Color(0xFFE93D5A),
        () {
          _showSavedPostsSheet(videosOnly: false);
        },
      ),
      _ProfileMenuItem(
        Icons.menu_book_rounded,
        "Từ vựng yêu thích",
        "Những từ vựng bạn đã lưu yêu thích",
        const Color(0xFF6C61B5),
        () {
          _showFavoritesSheet();
        },
      ),
      _ProfileMenuItem(
        Icons.workspace_premium_rounded,
        "Huy hiệu",
        "Thành tích bạn đã đạt được",
        const Color(0xFF7657D8),
        _showBadgesSheet,
      ),
    ];
  }

  List<_ProfileMenuItem> _accountMenuItems() {
    return [
      _ProfileMenuItem(
        Icons.person_rounded,
        "Thông tin cá nhân",
        "Quản lý thông tin tài khoản của bạn",
        const Color(0xFF668EE7),
        _showPersonalInfo,
      ),
      _ProfileMenuItem(
        Icons.lock_rounded,
        "Đổi mật khẩu",
        "Thay đổi mật khẩu tài khoản",
        const Color(0xFF32B4A5),
        _showChangePasswordDialog,
      ),
      _ProfileMenuItem(
        Icons.help_rounded,
        "Hỗ trợ & góp ý",
        "Gửi phản hồi cho chúng tôi",
        const Color(0xFFF0AE43),
        _showFeedbackDialog,
      ),
      _ProfileMenuItem(
        Icons.logout_rounded,
        "Đăng xuất",
        "Thoát khỏi tài khoản hiện tại",
        const Color(0xFFD93829),
        _logout,
      ),
    ];
  }

  Widget _buildMenuSection(List<_ProfileMenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1EAE1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildMenuItem(items[i]),
            if (i != items.length - 1) _buildDivider(),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(_ProfileMenuItem item) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF102321),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF756F68),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 26,
              color: Color(0xFF817B75),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 64,
      endIndent: 18,
      color: Color(0xFFF1EAE1),
    );
  }

  Widget _buildPasswordField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF6F7FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Container(
      width: double.infinity,
      color: softBg,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 42, 18, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuestTitle(),
              const SizedBox(height: 18),
              _buildGuestLoginCard(),
              const SizedBox(height: 14),
              _buildGuestBenefitPanel(),
              const SizedBox(height: 14),
              _buildGuestRegisterBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Cá nhân",
          style: TextStyle(
            color: guestInk,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 9),
        Image.asset(
          "assets/hoa_tiet.png",
          width: 28,
          height: 28,
          color: guestGold,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.auto_awesome_rounded, color: guestGold, size: 24),
        ),
      ],
    );
  }

  Widget _buildGuestLoginCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [guestSoftBlue, const Color(0xFFF7FBFF)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDCEBFF)),
        boxShadow: [
          BoxShadow(
            color: guestBlue.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/banner_main.png",
                fit: BoxFit.cover,
                alignment: const Alignment(0.55, 0.12),
                color: Colors.white.withValues(alpha: 0.28),
                colorBlendMode: BlendMode.srcATop,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFFF7FBFF).withValues(alpha: 0.98),
                      guestSoftBlue.withValues(alpha: 0.88),
                      Colors.white.withValues(alpha: 0.42),
                    ],
                    stops: const [0, 0.48, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -20,
              left: -26,
              child: Opacity(
                opacity: 0.10,
                child: Image.asset(
                  "assets/hoa_tiet.png",
                  width: 148,
                  color: guestBlue,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final content = _buildGuestLoginCopy();
                  if (constraints.maxWidth < 330) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGuestAvatarMark(),
                        const SizedBox(height: 18),
                        content,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildGuestAvatarMark(),
                      const SizedBox(width: 16),
                      Expanded(child: content),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestAvatarMark() {
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        shape: BoxShape.circle,
        border: Border.all(color: guestBlue.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: guestBlue.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(Icons.person_rounded, color: guestBlue, size: 72),
    );
  }

  Widget _buildGuestLoginCopy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Đăng nhập để lưu hành trình văn hóa của bạn",
          style: TextStyle(
            color: guestInk,
            fontSize: 20,
            height: 1.22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Lưu bài viết, theo dõi tiến độ học và tham gia cộng đồng người yêu văn hóa Dao.",
          style: TextStyle(
            color: Color(0xFF56616E),
            fontSize: 13,
            height: 1.42,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: guestBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text(
              "Đăng nhập ngay",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestBenefitPanel() {
    final benefits = [
      (
        Icons.bookmark_rounded,
        "Lưu nội dung yêu thích",
        "Lưu lại bài viết và nội dung bạn yêu thích",
        guestBlue,
      ),
      (
        Icons.workspace_premium_rounded,
        "Tích lũy EXP và huy hiệu",
        "Học tập, khám phá để nhận EXP và huy hiệu",
        guestGold,
      ),
      (
        Icons.menu_book_rounded,
        "Theo dõi tiến độ học tiếng Dao",
        "Ghi lại quá trình học và ôn luyện của bạn",
        const Color(0xFF2F8A4C),
      ),
      (
        Icons.forum_rounded,
        "Bình luận và tham gia cộng đồng",
        "Kết nối, chia sẻ và thảo luận cùng mọi người",
        const Color(0xFF4B7FCA),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFDCEBFF)),
        boxShadow: [
          BoxShadow(
            color: guestBlue.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < benefits.length; i++) ...[
            _buildGuestBenefit(
              benefits[i].$1,
              benefits[i].$2,
              benefits[i].$3,
              benefits[i].$4,
            ),
            if (i != benefits.length - 1)
              const Divider(
                height: 1,
                indent: 74,
                endIndent: 18,
                color: Color(0xFFE7EEF8),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuestBenefit(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: guestInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF667178),
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF717780),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildGuestRegisterBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Image.asset(
            "assets/hoa_tiet.png",
            width: 46,
            height: 46,
            color: Colors.white.withValues(alpha: 0.92),
            errorBuilder: (_, __, ___) => const Icon(
              Icons.diamond_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              "Sẵn sàng trở thành người giữ hồn văn hóa Dao?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: guestBlue,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.chevron_right_rounded, size: 19),
            label: const Text(
              "Đăng ký",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  String _buildDisplayName(String email) {
    if (email.isEmpty || email == "Khách") return "Người bạn Dao";
    final name = email.split('@').first.trim();
    if (name.isEmpty) return "Người bạn Dao";
    return name;
  }

  String get _displayName {
    if (_fullName.trim().isNotEmpty) return _fullName.trim();
    return _buildDisplayName(_email.isEmpty ? widget.username : _email);
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }
}

class _ProfileMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _ProfileMenuItem(
    this.icon,
    this.title,
    this.subtitle,
    this.color,
    this.onTap,
  );
}

class _BadgeItem {
  final IconData icon;
  final String title;
  final String description;
  final bool unlocked;
  final Color color;
  final String category;
  final int current;
  final int target;

  const _BadgeItem(
    this.icon,
    this.title,
    this.description,
    this.unlocked,
    this.color, {
    this.category = "Thành tích",
    this.current = 0,
    this.target = 1,
  });
}
