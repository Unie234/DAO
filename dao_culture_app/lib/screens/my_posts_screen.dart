import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../services/api_service.dart';
import 'create_post_screen.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final Color darkBlue = const Color(0xFF1A237E);
  String _currentUid = "";
  late Future<List<dynamic>> _myPostsFuture;

  @override
  void initState() {
    super.initState();
    _myPostsFuture = _loadMyPosts();
  }

  Future<List<dynamic>> _loadMyPosts() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUid = prefs.getString('user_id') ?? "";

    if (_currentUid.isEmpty) {
      return [];
    }

    final posts = await ApiService.getPosts(_currentUid);
    return posts
        .where((post) => post['user_id'].toString() == _currentUid)
        .toList();
  }

  void _refreshMyPosts() {
    setState(() {
      _myPostsFuture = _loadMyPosts();
    });
  }

  // --- HÀM THẢ TIM ---
  void _handleLike(String postId) async {
    if (_currentUid.isEmpty) return;

    final success = await ApiService.togglePostReaction(
      postId,
      _currentUid,
      'like',
    );
    if (success && mounted) {
      _refreshMyPosts();
    }
  }

  // --- HÀM CHIA SẺ ---
  void _handleShare(String content) {
    // ignore: deprecated_member_use
    Share.share("Khám phá văn hóa Dao cùng mình nhé: \n\n$content");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      appBar: AppBar(
        title: const Text(
          "Bài viết của tôi",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: darkBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // CHỈ LẤY BÀI VIẾT CÓ USER_ID CỦA BẠN TỪ PHP/XAMPP
      body: FutureBuilder<List<dynamic>>(
        future: _myPostsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Lỗi tải dữ liệu"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.post_add, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 15),
                  const Text(
                    "Bạn chưa có bài viết nào.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index] as Map<String, dynamic>;
              return _buildMyPostCard(context, data, data['id'].toString());
            },
          );
        },
      ),
    );
  }

  Widget _buildMyPostCard(
    BuildContext context,
    Map<String, dynamic> data,
    String postId,
  ) {
    final String likeCount = (data['reaction_count'] ?? data['like_count'] ?? 0)
        .toString();
    final String commentCount = (data['comment_count'] ?? 0).toString();
    final bool isLiked =
        (data['my_reaction']?.toString().isNotEmpty ?? false) ||
        data['is_liked'] == true;
    final String imageUrl = data['image_url'] ?? data['media_url'] ?? "";
    final String mediaType = data['media_type']?.toString() ?? "image";
    final galleryUrls = _galleryUrls(data, imageUrl);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: _buildAuthorAvatar(data),
            title: Text(
              data['author_name'] ?? data['username'] ?? "Người dùng",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text("Bài viết của bạn"),

            // MENU SỬA/XÓA
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatePostScreen(
                        postId: postId,
                        initialContent: data['content'],
                        initialImageUrl: imageUrl,
                      ),
                    ),
                  ).then((value) => _refreshMyPosts());
                } else if (value == 'delete') {
                  bool confirm =
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Xóa bài viết"),
                          content: const Text(
                            "Bạn có chắc chắn muốn xóa bài viết này không?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Hủy"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Xóa",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ) ??
                      false;

                  if (confirm) {
                    final success = await ApiService.deletePost(
                      postId,
                      userId: _currentUid,
                    );

                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? "Đã xóa bài viết"
                              : "Không xóa được bài viết",
                        ),
                      ),
                    );
                    if (success) _refreshMyPosts();
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text("Sửa bài viết")),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    "Xóa bài viết",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(data['content'] ?? ""),
          ),
          const SizedBox(height: 10),
          if (galleryUrls.isNotEmpty) _buildPostGallery(galleryUrls, mediaType),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _postButton(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  likeCount,
                  () => _handleLike(postId),
                  color: isLiked ? Colors.red : Colors.grey.shade700,
                ),
                _postButton(Icons.chat_bubble_outline, commentCount, () {}),
                _postButton(
                  Icons.share_outlined,
                  "Chia sẻ",
                  () => _handleShare(data['content'] ?? ""),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _postButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: color ?? Colors.grey.shade700),
      label: Text(
        label,
        style: TextStyle(color: color ?? Colors.grey.shade700),
      ),
    );
  }

  Widget _buildAuthorAvatar(Map<String, dynamic> data) {
    final avatar = data['author_avatar']?.toString().trim() ?? "";
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFFFECE8),
      child: ClipOval(
        child: avatar.isEmpty
            ? const Icon(Icons.person_rounded, color: Colors.redAccent)
            : Image.network(
                avatar,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person_rounded, color: Colors.redAccent),
              ),
      ),
    );
  }

  Widget _buildPostMedia(String mediaUrl, String mediaType) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: mediaType == 'video'
            ? _MyPostVideoPlayer(videoUrl: mediaUrl)
            : Image.network(
                mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
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
    return fallbackUrl.trim().isEmpty ? [] : [fallbackUrl];
  }

  Widget _buildPostGallery(List<String> urls, String mediaType) {
    if (urls.length == 1 || mediaType == 'video') {
      return _buildPostMedia(urls.first, mediaType);
    }

    final visibleUrls = urls.take(4).toList();
    final extraCount = urls.length - visibleUrls.length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: AspectRatio(
        aspectRatio: urls.length == 2 ? 1.45 : 1.2,
        child: _buildGalleryLayout(visibleUrls, extraCount),
      ),
    );
  }

  Widget _buildGalleryLayout(List<String> urls, int extraCount) {
    const gap = 3.0;
    if (urls.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildGalleryTile(urls[0])),
          const SizedBox(width: gap),
          Expanded(child: _buildGalleryTile(urls[1])),
        ],
      );
    }

    if (urls.length == 3) {
      return Row(
        children: [
          Expanded(flex: 2, child: _buildGalleryTile(urls[0])),
          const SizedBox(width: gap),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildGalleryTile(urls[1])),
                const SizedBox(height: gap),
                Expanded(child: _buildGalleryTile(urls[2])),
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
              Expanded(child: _buildGalleryTile(urls[0])),
              const SizedBox(width: gap),
              Expanded(child: _buildGalleryTile(urls[1])),
            ],
          ),
        ),
        const SizedBox(height: gap),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildGalleryTile(urls[2])),
              const SizedBox(width: gap),
              Expanded(
                child: _buildGalleryTile(urls[3], extraCount: extraCount),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryTile(String imageUrl, {int extraCount = 0}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade200,
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
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _MyPostVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _MyPostVideoPlayer({required this.videoUrl});

  @override
  State<_MyPostVideoPlayer> createState() => _MyPostVideoPlayerState();
}

class _MyPostVideoPlayerState extends State<_MyPostVideoPlayer> {
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
        .catchError((_) {
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
      return Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Text(
          "Video bị lỗi",
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
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
      child: Center(
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
      ),
    );
  }
}
