import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'create_post_screen.dart';
import 'notifications_screen.dart';
import '../services/api_service.dart';

class CommunityScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final String? initialPostId;

  const CommunityScreen({super.key, this.onBackToHome, this.initialPostId});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final Color primaryPurple = const Color(0xFF8B78FF);
  final Color bgPastel = const Color(0xFFF4F6FD);
  final Color textDark = const Color(0xFF2D3142);
  final Color textLight = const Color(0xFF9094A6);
  final Color actionOrange = const Color(0xFFFF8B66);

  final String adminUid = "admin_123";

  String currentUid = "";
  String currentUserName = "Khách";
  String _selectedFeedFilter = "Tất cả";
  final ScrollController _feedScrollController = ScrollController();

  String get _focusedPostId => widget.initialPostId?.trim() ?? '';
  bool get _isFocusedPost => _focusedPostId.isNotEmpty;

  bool get _isLoggedIn {
    final uid = currentUid.trim().toLowerCase();
    return uid.isNotEmpty && uid != "0" && uid != "null";
  }

  bool _isPostOwner(String postAuthorUid) {
    final authorUid = postAuthorUid.trim().toLowerCase();
    return _isLoggedIn &&
        authorUid.isNotEmpty &&
        authorUid != "0" &&
        authorUid != "null" &&
        currentUid.trim() == postAuthorUid.trim();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUid = prefs.getString('user_id');
    String? savedName = prefs.getString('username');

    if (mounted) {
      setState(() {
        currentUid = savedUid ?? "";
        currentUserName = savedName ?? "Khách";
      });
      _refreshPosts();
    }
  }

  late Future<List<dynamic>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _refreshPosts();
  }

  @override
  void didUpdateWidget(covariant CommunityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPostId?.trim() != widget.initialPostId?.trim()) {
      _refreshPosts();
    }
  }

  @override
  void dispose() {
    _feedScrollController.dispose();
    super.dispose();
  }

  void _restoreFeedOffset(double offset) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_feedScrollController.hasClients) return;

      final position = _feedScrollController.position;
      _feedScrollController.jumpTo(
        offset
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble(),
      );
    });
  }

  void _updateFeedState(VoidCallback update) {
    final offset = _feedScrollController.hasClients
        ? _feedScrollController.offset
        : null;
    setState(update);
    if (offset != null) _restoreFeedOffset(offset);
  }

  void _refreshPosts() {
    final offset = _feedScrollController.hasClients
        ? _feedScrollController.offset
        : null;
    final postsFuture = ApiService.getPosts(currentUid, _focusedPostId);
    setState(() {
      _postsFuture = postsFuture;
    });
    if (offset != null) {
      postsFuture.whenComplete(() => _restoreFeedOffset(offset));
    }
  }

  void _showLoginDialog(BuildContext context, String actionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yêu cầu đăng nhập"),
        content: Text("Bạn cần đăng nhập để có thể $actionName."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Để sau", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text("Đăng nhập ngay"),
          ),
        ],
      ),
    );
  }

  void _deletePost(String postId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text(
          "Xóa bài viết?",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.redAccent,
          ),
        ),
        content: const Text("Bài viết sẽ tan biến vào hư không. Bạn chắc chứ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              bool success = await ApiService.deletePost(
                postId,
                userId: currentUid,
                isAdmin: currentUid.trim() == adminUid,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Đã xóa bài viết!"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                _refreshPosts();
              }
            },
            child: const Text(
              "Xóa ngay",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reportPostWithReason(String postId) async {
    if (!_isLoggedIn) {
      _showLoginDialog(context, "báo cáo bài viết");
      return;
    }
    if (postId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không xác định được bài viết cần báo cáo."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    var enteredReason = '';
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            "Báo cáo vi phạm",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: TextField(
            minLines: 3,
            maxLines: 5,
            maxLength: 255,
            textInputAction: TextInputAction.done,
            onChanged: (value) {
              setDialogState(() => enteredReason = value);
            },
            onSubmitted: (value) {
              final text = value.trim();
              if (text.isNotEmpty) Navigator.pop(dialogContext, text);
            },
            decoration: InputDecoration(
              labelText: "Lý do báo cáo",
              hintText: "Nhập lý do để admin xem xét...",
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                disabledBackgroundColor: Colors.orange.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: enteredReason.trim().isEmpty
                  ? null
                  : () {
                      FocusScope.of(dialogContext).unfocus();
                      Navigator.pop(dialogContext, enteredReason.trim());
                    },
              child: const Text(
                "Gửi báo cáo",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (reason == null || reason.trim().isEmpty) return;

    final success = await ApiService.reportPost(postId, currentUid, reason);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "Đã gửi báo cáo cho Admin!"
              : "Chưa gửi được báo cáo. Vui lòng thử lại.",
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  void _handleReaction(
    String postId,
    String reaction,
    Map<String, dynamic> post,
  ) async {
    if (!_isLoggedIn) {
      _showLoginDialog(context, "thả cảm xúc");
      return;
    }

    bool success = await ApiService.togglePostReaction(
      postId,
      currentUid,
      reaction,
    );
    if (success) {
      final currentReaction = post['my_reaction']?.toString() ?? '';
      final currentCount = _toInt(post['reaction_count'] ?? post['like_count']);
      _updateFeedState(() {
        if (currentReaction == reaction) {
          post['my_reaction'] = '';
          post['reaction_count'] = (currentCount - 1).clamp(0, 1 << 30);
        } else {
          post['my_reaction'] = reaction;
          post['reaction_count'] = currentReaction.isEmpty
              ? currentCount + 1
              : currentCount;
        }
      });
    }
  }

  void _showReactionPicker(
    BuildContext context,
    String postId,
    Map<String, dynamic> post,
  ) {
    if (!_isLoggedIn) {
      _showLoginDialog(context, "thả cảm xúc");
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(18),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _reactionOptions.map((item) {
              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _handleReaction(postId, item.key, post);
                },
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _handleShare(
    String content,
    String imageUrl,
    String mediaType,
  ) async {
    String shareText =
        "🔥 Xem bài viết hay trên App Văn hóa Dao:\n\n\"$content\"\n";
    if (imageUrl.isNotEmpty) {
      shareText += "\nXem ảnh/video tại đây: $imageUrl";
    }
    shareText += "\n\n🍀 Cùng mình lan tỏa bản sắc người Dao nhé!";
    await SharePlus.instance.share(ShareParams(text: shareText));
  }

  void _showCommentBottomSheet(
    BuildContext context,
    String postId,
    Map<String, dynamic> post,
  ) {
    final TextEditingController commentController = TextEditingController();
    String? replyingToId;
    String? replyingToName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      "Bình luận",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: FutureBuilder<List<dynamic>>(
                        future: ApiService.getComments(
                          postId,
                          userId: currentUid,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: primaryPurple,
                              ),
                            );
                          }
                          final comments = snapshot.data ?? [];
                          if (comments.isEmpty) {
                            return Center(
                              child: Text(
                                "Trở thành người đầu tiên\nbình luận về bài viết này nhé! ✨",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textLight,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            );
                          }
                          final parentComments = _parentComments(comments);
                          return ListView.builder(
                            itemCount: parentComments.length,
                            itemBuilder: (context, index) {
                              final data = parentComments[index];
                              final replies = _commentReplies(
                                comments,
                                _commentId(data),
                              );
                              return _buildCommentThread(
                                data,
                                replies,
                                postId: postId,
                                setModalState: setModalState,
                                onReply: (id, name) {
                                  if (!_isLoggedIn) {
                                    _showLoginDialog(
                                      context,
                                      "trả lời bình luận",
                                    );
                                    return;
                                  }
                                  setModalState(() {
                                    replyingToId = id;
                                    replyingToName = name;
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (replyingToId != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: primaryPurple.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Đang trả lời $replyingToName",
                                style: TextStyle(
                                  color: primaryPurple,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => setModalState(() {
                                replyingToId = null;
                                replyingToName = null;
                              }),
                              child: Icon(
                                Icons.close_rounded,
                                color: textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: replyingToId == null
                                  ? "Nhập bình luận..."
                                  : "Viết câu trả lời...",
                              hintStyle: TextStyle(color: textLight),
                              filled: true,
                              fillColor: bgPastel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            if (!_isLoggedIn) {
                              _showLoginDialog(context, "bình luận");
                              return;
                            }
                            final text = commentController.text.trim();
                            if (text.isEmpty) return;

                            commentController.clear();
                            bool success = await ApiService.addComment(
                              postId,
                              currentUid,
                              text,
                              parentId: replyingToId,
                            );
                            if (success) {
                              setModalState(() {
                                replyingToId = null;
                                replyingToName = null;
                              });
                              _updateFeedState(() {
                                post['comment_count'] =
                                    _toInt(post['comment_count']) + 1;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: primaryPurple,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryPurple.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _commentId(dynamic data) => data['id']?.toString() ?? '';

  String _commentParentId(dynamic data) {
    final value = data['parent_id']?.toString() ?? '';
    return value == '0' || value == 'null' ? '' : value;
  }

  List<dynamic> _parentComments(List<dynamic> comments) {
    return comments.where((item) => _commentParentId(item).isEmpty).toList();
  }

  List<dynamic> _commentReplies(List<dynamic> comments, String parentId) {
    return comments
        .where((item) => _commentParentId(item) == parentId)
        .toList();
  }

  Widget _buildCommentThread(
    dynamic data,
    List<dynamic> replies, {
    required String postId,
    required StateSetter setModalState,
    required void Function(String id, String name) onReply,
  }) {
    final author = data['author_name']?.toString() ?? 'Người dùng';

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          _buildCommentItem(
            data,
            postId: postId,
            setModalState: setModalState,
            onReply: onReply,
          ),
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 46, top: 10),
              child: Column(
                children: replies
                    .map(
                      (reply) => _buildCommentItem(
                        reply,
                        compact: true,
                        replyingToName: author,
                        postId: postId,
                        setModalState: setModalState,
                        onReply: onReply,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(
    dynamic data, {
    bool compact = false,
    String? replyingToName,
    required String postId,
    required StateSetter setModalState,
    required void Function(String id, String name) onReply,
  }) {
    final commentAuthor = data['author_name']?.toString() ?? 'Người dùng';
    final commentTime = data['created_at']?.toString() ?? "Vừa xong";
    final content = data['content']?.toString() ?? '';
    final myReaction = data['my_reaction']?.toString() ?? '';
    final topReaction = data['top_reaction']?.toString() ?? '';
    final visibleReaction = myReaction.isNotEmpty ? myReaction : topReaction;
    final reactionCount = (data['reaction_count'] ?? 0).toString();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: compact ? 15 : 20,
          backgroundColor: primaryPurple.withValues(alpha: 0.15),
          child: Text(
            commentAuthor.isNotEmpty ? commentAuthor[0].toUpperCase() : 'U',
            style: TextStyle(
              color: primaryPurple,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 12 : 16,
            ),
          ),
        ),
        SizedBox(width: compact ? 10 : 15),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(compact ? 12 : 16),
            decoration: BoxDecoration(
              color: compact ? Colors.white : bgPastel,
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(compact ? 16 : 20),
                bottomLeft: Radius.circular(compact ? 16 : 20),
                bottomRight: Radius.circular(compact ? 16 : 20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        commentAuthor,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 13 : 14,
                          color: textDark,
                        ),
                      ),
                    ),
                    Text(
                      commentTime,
                      style: TextStyle(
                        fontSize: 11,
                        color: textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (replyingToName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      "Trả lời $replyingToName",
                      style: TextStyle(
                        color: primaryPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: compact ? 14 : 15,
                    color: textDark.withValues(alpha: 0.82),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  children: [
                    InkWell(
                      onTap: () => onReply(_commentId(data), commentAuthor),
                      child: Text(
                        "Trả lời",
                        style: TextStyle(
                          color: primaryPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showCommentReactionPicker(
                        _commentId(data),
                        setModalState,
                      ),
                      child: Text(
                        visibleReaction.isNotEmpty
                            ? "${_reactionEmoji(visibleReaction)} $reactionCount"
                            : "Thả cảm xúc",
                        style: TextStyle(
                          color: visibleReaction.isNotEmpty
                              ? actionOrange
                              : textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCommentReactionPicker(String commentId, StateSetter setModalState) {
    if (!_isLoggedIn) {
      _showLoginDialog(context, "thả cảm xúc bình luận");
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(18),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _reactionOptions.map((item) {
              return InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  final success = await ApiService.toggleCommentReaction(
                    commentId,
                    currentUid,
                    item.key,
                  );
                  if (success) {
                    setModalState(() {});
                    _refreshPosts();
                  }
                },
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    _showGalleryViewer(context, [imageUrl], 0);
  }

  void _showGalleryViewer(
    BuildContext context,
    List<String> imageUrls,
    int initialIndex,
  ) {
    final pageController = PageController(initialPage: initialIndex);
    var currentIndex = initialIndex;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(15),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.92),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.82,
                  ),
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: imageUrls.length,
                    onPageChanged: (index) {
                      setDialogState(() => currentIndex = index);
                    },
                    itemBuilder: (context, index) => InteractiveViewer(
                      child: Center(
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white70,
                            size: 58,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (imageUrls.length > 1)
                Positioned(
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      "${currentIndex + 1}/${imageUrls.length}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: textDark.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(pageController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFAF8),
      body: Stack(
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Opacity(
                opacity: 0.28,
                child: Image.asset(
                  "assets/community_bg.png",
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFFFBFAF8)),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.90),
                    Colors.white.withValues(alpha: 0.80),
                    Colors.white.withValues(alpha: 0.86),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: RefreshIndicator(
              color: const Color(0xFFC20D14),
              onRefresh: () async => _refreshPosts(),
              child: FutureBuilder<List<dynamic>>(
                future: _postsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ListView(
                      controller: _feedScrollController,
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
                      children: [
                        _buildCommunityTop(
                          child: Center(child: Text("Lỗi: ${snapshot.error}")),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView(
                      controller: _feedScrollController,
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
                      children: [
                        _buildCommunityTop(
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 54),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFC20D14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final docs = _filteredPosts(snapshot.data ?? []);

                  return ListView(
                    controller: _feedScrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
                    children: [
                      if (_isFocusedPost)
                        _buildFocusedPostHeader()
                      else
                        _buildCommunityTop(child: _buildComposerCard()),
                      const SizedBox(height: 22),
                      if (docs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: _buildEmptyFeed(),
                        )
                      else
                        ...docs.map((data) {
                          final post = data as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: _buildGamifiedPostCard(
                              context,
                              post,
                              post['id'].toString(),
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusedPostHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 18, 0),
        child: Row(
          children: [
            IconButton(
              onPressed:
                  widget.onBackToHome ??
                  () {
                    Navigator.maybePop(context);
                  },
              icon: const Icon(Icons.arrow_back_rounded),
              color: const Color(0xFF111827),
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                "Bài viết cộng đồng",
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityTop({required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommunityHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildFeedFilters(), const SizedBox(height: 28), child],
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityHeader() {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      height: topInset + 270,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  "assets/community_bg.png",
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) =>
                      Image.asset("assets/banner_main.png", fit: BoxFit.cover),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.34),
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.32),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: topInset + 16,
                  right: 22,
                  child: _buildHeaderIcon(
                    Icons.notifications_none_rounded,
                    () {
                      if (!_isLoggedIn) {
                        _showLoginDialog(context, "xem thông báo");
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    showDot: true,
                    color: Colors.white,
                    dotColor: const Color(0xFFE10012),
                  ),
                ),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 34,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Cộng đồng",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          height: 1.02,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          shadows: [
                            Shadow(
                              color: Color(0x77000000),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 88,
                            height: 2,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE10012),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE10012),
                                width: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 62,
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.86),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Kết nối, chia sẻ và gìn giữ\nvăn hóa Dao",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1.32,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Color(0x77000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(
    IconData icon,
    VoidCallback onTap, {
    bool showDot = false,
    Color color = const Color(0xFF111827),
    Color dotColor = const Color(0xFFC20D14),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: color, size: 31),
            if (showDot)
              Positioned(
                right: 8,
                top: 6,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedFilters() {
    const filters = ["Tất cả", "Bài viết mới", "Đang quan tâm"];
    return SizedBox(
      height: 58,
      child: Row(
        children: filters.map((filter) {
          final selected = _selectedFeedFilter == filter;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedFeedFilter = filter),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFE10012)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    filter,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<dynamic> _filteredPosts(List<dynamic> posts) {
    final sortedPosts = List<dynamic>.from(posts);
    sortedPosts.sort((a, b) {
      final postA = a as Map<String, dynamic>;
      final postB = b as Map<String, dynamic>;
      return _postCreatedAt(postB).compareTo(_postCreatedAt(postA));
    });

    if (_selectedFeedFilter == "Bài viết mới") {
      return sortedPosts.take(5).toList();
    }

    if (_selectedFeedFilter == "Đang quan tâm") {
      sortedPosts.sort((a, b) {
        final postA = a as Map<String, dynamic>;
        final postB = b as Map<String, dynamic>;
        final scoreCompare = _postInteractionScore(
          postB,
        ).compareTo(_postInteractionScore(postA));
        if (scoreCompare != 0) return scoreCompare;
        return _postCreatedAt(postB).compareTo(_postCreatedAt(postA));
      });
    }

    return sortedPosts;
  }

  DateTime _postCreatedAt(Map<String, dynamic> post) {
    return DateTime.tryParse(post['created_at']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  int _postInteractionScore(Map<String, dynamic> post) {
    return _toInt(post['reaction_count']) +
        (_toInt(post['comment_count']) * 2) +
        _toInt(post['save_count']);
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Widget _buildComposerCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildAuthorAvatar({}, radius: 26),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _openCreatePost,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      "Bạn đang nghĩ gì?",
                      style: TextStyle(
                        color: Color(0xFF8A8F9D),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildComposerAction(
                Icons.image_rounded,
                "Ảnh",
                const Color(0xFF19B766),
              ),
              const SizedBox(width: 24),
              _buildComposerAction(
                Icons.play_circle_fill_rounded,
                "Video",
                actionOrange,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _openCreatePost,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text("Đăng bài"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC20D14),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComposerAction(IconData icon, String label, Color color) {
    return InkWell(
      onTap: _openCreatePost,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreatePost() {
    if (!_isLoggedIn) {
      _showLoginDialog(context, "đăng bài");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    ).then((value) => _refreshPosts());
  }

  Widget _buildEmptyFeed() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 58,
            color: const Color(0xFFC20D14).withValues(alpha: 0.35),
          ),
          const SizedBox(height: 14),
          const Text(
            "Chưa có bài viết cộng đồng",
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Hãy chia sẻ câu chuyện đầu tiên về văn hóa Dao.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamifiedPostCard(
    BuildContext context,
    Map<String, dynamic> data,
    String postId,
  ) {
    final String reactionCount =
        (data['reaction_count'] ?? data['like_count'] ?? 0).toString();
    final String myReaction = data['my_reaction']?.toString() ?? '';

    final String imageUrl = data['image_url'] ?? data['media_url'] ?? "";
    final String mediaType = data['media_type'] ?? "image";
    final galleryUrls = _galleryUrls(data, imageUrl);
    final String postAuthorUid = data['user_id'].toString();
    final bool isAdminPost =
        data['author_role']?.toString().toLowerCase() == 'admin' ||
        postAuthorUid == adminUid;
    final bool hasVideo = mediaType.toLowerCase() == 'video';
    final bool isSaved =
        data['is_saved'] == true ||
        data['is_saved']?.toString() == '1' ||
        data['is_saved']?.toString().toLowerCase() == 'true';
    final bool canManagePost =
        _isPostOwner(postAuthorUid) || currentUid.trim() == adminUid;
    final String timeString = data['created_at'] ?? "Vừa xong";
    final String content = data['content']?.toString() ?? "";
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAuthorAvatar(data),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 190),
                            child: Text(
                              data['author_name'] ?? "Thành viên Dao",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: textDark,
                              ),
                            ),
                          ),
                          if (isAdminPost)
                            _buildPostBadge(
                              "ADMIN",
                              const Color(0xFFFFEAA7),
                              const Color(0xFFD35400),
                            ),
                          if (isAdminPost && hasVideo)
                            _buildPostBadge(
                              "Có video",
                              const Color(0xFFEAF2FF),
                              const Color(0xFF1D4ED8),
                              icon: Icons.play_circle_fill_rounded,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 13,
                          color: textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isLoggedIn)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: textLight,
                      size: 28,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white,
                    elevation: 10,
                    onSelected: (value) async {
                      if (value == 'edit') {
                        if (!canManagePost) {
                          _showLoginDialog(context, "sửa bài viết của bạn");
                          return;
                        }
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreatePostScreen(
                              postId: postId,
                              initialContent: data['content']?.toString() ?? '',
                              initialImageUrl: imageUrl,
                            ),
                          ),
                        );
                        if (updated == true) _refreshPosts();
                      } else if (value == 'delete') {
                        if (!canManagePost) {
                          _showLoginDialog(context, "xóa bài viết của bạn");
                          return;
                        }
                        _deletePost(postId);
                      } else if (value == 'report') {
                        await _reportPostWithReason(postId);
                      }
                    },
                    itemBuilder: (context) => [
                      if (canManagePost) ...[
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                color: Colors.blueAccent,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Sửa bài',
                                style: TextStyle(color: Colors.blueAccent),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_sweep_rounded,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Xóa bài',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(
                                Icons.report_problem_rounded,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Báo cáo vi phạm',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),

            if (content.isNotEmpty) ...[
              const SizedBox(height: 14),
              _ExpandablePostText(
                content: content,
                color: textDark.withValues(alpha: 0.92),
                actionColor: primaryPurple,
              ),
            ],
            if (galleryUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildPostGallery(context, galleryUrls, mediaType),
            ],
            const SizedBox(height: 17),

            Container(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _postButton(
                    myReaction.isNotEmpty
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    myReaction.isNotEmpty
                        ? "${_reactionEmoji(myReaction)} $reactionCount"
                        : reactionCount,
                    () => _showReactionPicker(context, postId, data),
                    color: myReaction.isNotEmpty
                        ? const Color(0xFFE51B23)
                        : textLight,
                  ),
                  _postButton(
                    Icons.chat_bubble_outline_rounded,
                    (data['comment_count'] ?? 0).toString(),
                    () {
                      if (!_isLoggedIn) {
                        _showLoginDialog(context, "bình luận");
                        return;
                      }
                      _showCommentBottomSheet(context, postId, data);
                    },
                    color: textLight,
                  ),
                  _postButton(Icons.reply_rounded, "Chia sẻ", () {
                    if (!_isLoggedIn) {
                      _showLoginDialog(context, "chia sẻ bài viết");
                      return;
                    }
                    _handleShare(data['content'] ?? "", imageUrl, mediaType);
                  }, color: textLight),
                  _postButton(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    "Lưu",
                    () async {
                      if (!_isLoggedIn) {
                        _showLoginDialog(context, "lưu bài viết");
                        return;
                      }
                      final success = await ApiService.toggleSavePost(
                        postId,
                        currentUid,
                      );
                      if (success) {
                        _updateFeedState(() {
                          data['is_saved'] = !isSaved;
                          final saveCount = _toInt(data['save_count']);
                          data['save_count'] = isSaved
                              ? (saveCount - 1).clamp(0, 1 << 30)
                              : saveCount + 1;
                        });
                      }
                    },
                    color: isSaved ? const Color(0xFFC20D14) : textLight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _postButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    required Color color,
    Color bgColor = Colors.transparent,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostBadge(
    String label,
    Color backgroundColor,
    Color foregroundColor, {
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foregroundColor),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: foregroundColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorAvatar(Map<String, dynamic> data, {double radius = 24}) {
    final avatar = data['author_avatar']?.toString().trim() ?? "";
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFFDEBED),
      child: ClipOval(
        child: avatar.isEmpty
            ? _buildDefaultAuthorAvatar(radius)
            : Image.network(
                avatar,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAuthorAvatar(radius),
              ),
      ),
    );
  }

  Widget _buildDefaultAuthorAvatar(double radius) {
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Icon(
        Icons.person_rounded,
        color: const Color(0xFFC20D14),
        size: radius * 1.2,
      ),
    );
  }

  List<String> _galleryUrls(Map<String, dynamic> data, String fallbackUrl) {
    final rawGallery = data['gallery_urls'];
    if (rawGallery is List) {
      final urls = rawGallery
          .map((item) => item.toString())
          .where((url) => url.trim().isNotEmpty)
          .toList();
      if (urls.isNotEmpty) return urls;
    }

    if (fallbackUrl.trim().isNotEmpty) return [fallbackUrl];
    return [];
  }

  Widget _buildPostGallery(
    BuildContext context,
    List<String> galleryUrls,
    String mediaType,
  ) {
    if (galleryUrls.length == 1 || mediaType == 'video') {
      return _buildPostMedia(context, galleryUrls.first, mediaType);
    }

    final visibleUrls = galleryUrls.take(4).toList();
    final extraCount = galleryUrls.length - visibleUrls.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: galleryUrls.length == 2 ? 1.45 : 1.2,
        child: _buildGalleryLayout(
          context,
          galleryUrls,
          visibleUrls,
          extraCount,
        ),
      ),
    );
  }

  Widget _buildGalleryLayout(
    BuildContext context,
    List<String> galleryUrls,
    List<String> urls,
    int extraCount,
  ) {
    const gap = 3.0;

    if (urls.length == 2) {
      return Row(
        children: [
          Expanded(
            child: _buildGalleryTile(context, galleryUrls, urls[0], index: 0),
          ),
          const SizedBox(width: gap),
          Expanded(
            child: _buildGalleryTile(context, galleryUrls, urls[1], index: 1),
          ),
        ],
      );
    }

    if (urls.length == 3) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildGalleryTile(context, galleryUrls, urls[0], index: 0),
          ),
          const SizedBox(width: gap),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildGalleryTile(
                    context,
                    galleryUrls,
                    urls[1],
                    index: 1,
                  ),
                ),
                const SizedBox(height: gap),
                Expanded(
                  child: _buildGalleryTile(
                    context,
                    galleryUrls,
                    urls[2],
                    index: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildGalleryTile(
                  context,
                  galleryUrls,
                  urls[0],
                  index: 0,
                ),
              ),
              const SizedBox(width: gap),
              Expanded(
                child: _buildGalleryTile(
                  context,
                  galleryUrls,
                  urls[1],
                  index: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: gap),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildGalleryTile(
                  context,
                  galleryUrls,
                  urls[2],
                  index: 2,
                ),
              ),
              const SizedBox(width: gap),
              Expanded(
                child: _buildGalleryTile(
                  context,
                  galleryUrls,
                  urls[3],
                  index: 3,
                  extraCount: extraCount,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryTile(
    BuildContext context,
    List<String> galleryUrls,
    String imageUrl, {
    required int index,
    int extraCount = 0,
  }) {
    return GestureDetector(
      onTap: () => _showGalleryViewer(context, galleryUrls, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFFF4F1ED),
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
          if (extraCount > 0)
            Container(
              color: Colors.black.withValues(alpha: 0.48),
              alignment: Alignment.center,
              child: Text(
                '+$extraCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostMedia(
    BuildContext context,
    String imageUrl,
    String mediaType,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: double.infinity,
        height: 260,
        child: mediaType == 'video'
            ? PostVideoPlayer(videoUrl: imageUrl)
            : GestureDetector(
                onTap: () => _showFullImage(context, imageUrl),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFF4F1ED),
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
      ),
    );
  }

  String _reactionEmoji(String reaction) {
    for (final item in _reactionOptions) {
      if (item.key == reaction) return item.emoji;
    }
    return "🙂";
  }
}

class _ExpandablePostText extends StatefulWidget {
  final String content;
  final Color color;
  final Color actionColor;

  const _ExpandablePostText({
    required this.content,
    required this.color,
    required this.actionColor,
  });

  @override
  State<_ExpandablePostText> createState() => _ExpandablePostTextState();
}

class _ExpandablePostTextState extends State<_ExpandablePostText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 15,
      height: 1.45,
      color: widget.color,
      fontWeight: FontWeight.w600,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.content, style: textStyle),
          maxLines: 5,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final canExpand = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.content,
              maxLines: _expanded ? null : 5,
              overflow: _expanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: textStyle,
            ),
            if (canExpand || _expanded) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _expanded ? "Thu gọn" : "Xem thêm",
                    style: TextStyle(
                      color: widget.actionColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ReactionOption {
  final String key;
  final String emoji;
  final String label;

  const _ReactionOption(this.key, this.emoji, this.label);
}

const List<_ReactionOption> _reactionOptions = [
  _ReactionOption('like', '👍', 'Thích'),
  _ReactionOption('love', '❤️', 'Yêu'),
  _ReactionOption('haha', '😄', 'Vui'),
  _ReactionOption('wow', '😮', 'Wow'),
  _ReactionOption('sad', '😢', 'Buồn'),
];

class PostVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const PostVideoPlayer({super.key, required this.videoUrl});
  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller
        .initialize()
        .then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
          }
        })
        .catchError((error) {
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        });
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "Video bị lỗi 😢",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF8B78FF)),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        });
      },
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            if (!_controller.value.isPlaying)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
