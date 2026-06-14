import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color _ink = Color(0xFF102321);
  static const Color _paper = Color(0xFFFFFBF6);
  static const Color _red = Color(0xFFD93829);

  late Future<List<AppNotification>> _notificationsFuture;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<List<AppNotification>> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final username = prefs.getString('username') ?? '';
    _userId = userId;
    if (userId.isEmpty || username.isEmpty || username == 'Khách') return [];
    return ApiService.getNotifications(userId: userId);
  }

  void _refresh() {
    setState(() {
      _notificationsFuture = _loadNotifications();
    });
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (_userId.isEmpty || notification.isRead) return;
    final success = await ApiService.markNotificationRead(
      userId: _userId,
      notificationId: notification.id,
    );
    if (success && mounted) _refresh();
  }

  Future<void> _openNotification(AppNotification notification) async {
    await _markAsRead(notification);
    if (!mounted) return;

    if (notification.postId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thông báo này không gắn với bài viết cụ thể.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final posts = await ApiService.getPosts(_userId);
    if (!mounted) return;

    Map<String, dynamic>? selectedPost;
    for (final item in posts) {
      if (item is Map<String, dynamic> &&
          item['id']?.toString() == notification.postId) {
        selectedPost = item;
        break;
      }
    }

    if (selectedPost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bài viết không còn tồn tại hoặc đã bị ẩn.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NotificationPostDetailScreen(
          post: selectedPost!,
          notification: notification,
          userId: _userId,
        ),
      ),
    );
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    if (_userId.isEmpty) return;
    if (!notification.isRead) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy mở đọc thông báo trước khi xóa.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await ApiService.deleteNotification(
      userId: _userId,
      notificationId: notification.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Đã xóa thông báo' : 'Không xóa được thông báo',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (success) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        elevation: 0,
        foregroundColor: _ink,
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _red));
          }

          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return _EmptyNotifications(onRefresh: _refresh);
          }

          return RefreshIndicator(
            color: _red,
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _NotificationCard(
                  notification: notifications[index],
                  onOpen: () => _openNotification(notifications[index]),
                  onDelete: () => _deleteNotification(notifications[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onOpen,
    required this.onDelete,
  });

  static const Color _ink = Color(0xFF102321);

  @override
  Widget build(BuildContext context) {
    final isUrgent =
        notification.type == 'community_violation' ||
        notification.type == 'post_hidden';

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFFFFCF3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isUrgent
                ? notification.color.withValues(alpha: 0.40)
                : notification.isRead
                ? const Color(0xFFEDE5DA)
                : notification.color.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: notification.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(notification.icon, color: notification.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (!notification.isRead) ...[
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 5, left: 8),
                          decoration: BoxDecoration(
                            color: notification.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: onOpen,
                          style: TextButton.styleFrom(
                            foregroundColor: notification.color,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 28),
                          ),
                          icon: const Icon(Icons.done_all_rounded, size: 17),
                          label: const Text(
                            'Đã đọc',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ] else
                        IconButton(
                          onPressed: onDelete,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: Color(0xFFD93829),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.76),
                      fontSize: 13.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(notification.createdAt),
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

  String _formatTime(DateTime? value) {
    if (value == null) return 'Vừa xong';

    final now = DateTime.now();
    final diff = now.difference(value);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';

    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}

class _EmptyNotifications extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyNotifications({required this.onRefresh});

  static const Color _ink = Color(0xFF102321);
  static const Color _red = Color(0xFFD93829);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                color: Color(0xFFFFECE8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: _red,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có thông báo',
              style: TextStyle(
                color: _ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bài viết mới, bài nổi bật và cảnh báo tiêu chuẩn cộng đồng sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink.withValues(alpha: 0.62),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tải lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationPostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;
  final AppNotification notification;
  final String userId;

  const _NotificationPostDetailScreen({
    required this.post,
    required this.notification,
    required this.userId,
  });

  static const Color _ink = Color(0xFF102321);
  static const Color _red = Color(0xFFD93829);

  @override
  Widget build(BuildContext context) {
    final content = post['content']?.toString() ?? '';
    final author =
        post['author_name']?.toString() ??
        post['username']?.toString() ??
        'Thành viên Dao';
    final time = post['created_at']?.toString() ?? '';
    final imageUrl = (post['image_url'] ?? post['media_url'] ?? '').toString();
    final mediaType = post['media_type']?.toString() ?? 'image';
    final gallery = _galleryUrls(post, imageUrl);
    final postId = post['id']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF6),
        foregroundColor: _ink,
        elevation: 0,
        title: const Text(
          'Bài viết',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _NotificationActivitySummary(notification: notification),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEDE5DA)),
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
                    _buildPostAuthorAvatar(post),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            time,
                            style: TextStyle(
                              color: _ink.withValues(alpha: 0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    content,
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.88),
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (gallery.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ...gallery.map(
                    (url) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 260,
                          child: mediaType == 'video'
                              ? Container(
                                  color: Colors.black87,
                                  child: const Center(
                                    child: Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: Colors.white,
                                      size: 58,
                                    ),
                                  ),
                                )
                              : Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFF5EFE6),
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Bình luận',
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<dynamic>>(
            future: ApiService.getComments(postId, userId: userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: _red)),
                );
              }

              final comments = snapshot.data ?? [];
              if (comments.isEmpty) {
                return Text(
                  'Chưa có bình luận nào.',
                  style: TextStyle(
                    color: _ink.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w700,
                  ),
                );
              }

              final orderedComments = List<dynamic>.from(comments);
              if (notification.commentId.isNotEmpty) {
                final targetIndex = orderedComments.indexWhere((item) {
                  final data = item as Map<String, dynamic>;
                  return data['id']?.toString() == notification.commentId;
                });
                if (targetIndex > 0) {
                  final targetComment = orderedComments.removeAt(targetIndex);
                  orderedComments.insert(0, targetComment);
                }
              }

              return Column(
                children: orderedComments.map((item) {
                  final data = item as Map<String, dynamic>;
                  final commentId = data['id']?.toString() ?? '';
                  final isTargetComment =
                      notification.commentId.isNotEmpty &&
                      notification.commentId == commentId;
                  final reactionCount =
                      int.tryParse((data['reaction_count'] ?? 0).toString()) ??
                      0;
                  final myReaction = data['my_reaction']?.toString() ?? '';
                  final topReaction = data['top_reaction']?.toString() ?? '';
                  final visibleReaction = myReaction.isNotEmpty
                      ? myReaction
                      : topReaction;
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isTargetComment
                          ? notification.color.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isTargetComment
                            ? notification.color.withValues(alpha: 0.42)
                            : const Color(0xFFEDE5DA),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['author_name']?.toString() ?? 'Người dùng',
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          data['content']?.toString() ?? '',
                          style: TextStyle(
                            color: _ink.withValues(alpha: 0.78),
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (reactionCount > 0 &&
                            visibleReaction.isNotEmpty) ...[
                          const SizedBox(height: 9),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: notification.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: notification.color.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                            ),
                            child: Text(
                              '${_reactionEmoji(visibleReaction)} $reactionCount',
                              style: TextStyle(
                                color: notification.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                        if (isTargetComment) ...[
                          const SizedBox(height: 9),
                          Text(
                            'Thông báo này liên quan đến bình luận này',
                            style: TextStyle(
                              color: notification.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostAuthorAvatar(Map<String, dynamic> post) {
    final avatar = post['author_avatar']?.toString().trim() ?? '';
    return CircleAvatar(
      radius: 23,
      backgroundColor: const Color(0xFFFFECE8),
      child: ClipOval(
        child: avatar.isEmpty
            ? const Icon(Icons.person_rounded, color: _red)
            : Image.network(
                avatar,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person_rounded, color: _red),
              ),
      ),
    );
  }

  List<String> _galleryUrls(Map<String, dynamic> post, String fallbackUrl) {
    final rawGallery = post['gallery_urls'];
    if (rawGallery is List) {
      final urls = rawGallery
          .map((item) => item.toString())
          .where((url) => url.trim().isNotEmpty)
          .toList();
      if (urls.isNotEmpty) return urls;
    }
    return fallbackUrl.trim().isEmpty ? [] : [fallbackUrl];
  }

  String _reactionEmoji(String reaction) {
    switch (reaction) {
      case 'love':
        return '❤️';
      case 'haha':
        return '😄';
      case 'wow':
        return '😮';
      case 'sad':
        return '😢';
      case 'like':
      default:
        return '👍';
    }
  }
}

class _NotificationActivitySummary extends StatelessWidget {
  final AppNotification notification;

  const _NotificationActivitySummary({required this.notification});

  static const Color _ink = Color(0xFF102321);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notification.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: notification.color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: notification.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(notification.icon, color: notification.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hoạt động vừa xảy ra',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  notification.message,
                  style: TextStyle(
                    color: _ink.withValues(alpha: 0.78),
                    fontSize: 13.5,
                    height: 1.35,
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
}
