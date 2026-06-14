import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Thêm thư viện Cache ảnh
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/gamification_service.dart';
import '../widgets/level_up_celebration_dialog.dart';
import '../app_config.dart';

class CultureDetailScreen extends StatefulWidget {
  final String title;
  final String type; // 'video', 'image', hoặc 'text'
  final String mediaUrl;
  final String content;
  final int xpReward;

  const CultureDetailScreen({
    super.key,
    required this.title,
    required this.type,
    required this.mediaUrl,
    required this.content,
    this.xpReward = 5,
  });

  @override
  State<CultureDetailScreen> createState() => _CultureDetailScreenState();
}

class _CultureDetailScreenState extends State<CultureDetailScreen> {
  final Color primaryPurple = const Color(0xFF8B78FF);
  final Color textDark = const Color(0xFF2D3142);

  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _showVideoControls = true;
  bool _videoLoadFailed = false;
  bool _canEarnReward = false;
  bool _isCheckingLogin = true;
  bool _usesVideoPlayer = false;
  late final String _resolvedMediaUrl;

  @override
  void initState() {
    super.initState();
    _resolvedMediaUrl = _normalizeVideoUrl(widget.mediaUrl);
    _checkLoginRewardAccess();
    if (widget.type == 'video' &&
        _resolvedMediaUrl.isNotEmpty &&
        _canPlayInlineVideo(_resolvedMediaUrl)) {
      _usesVideoPlayer = true;
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(_resolvedMediaUrl),
      );
      _videoController
          .initialize()
          .timeout(const Duration(seconds: 15))
          .then((_) {
            if (mounted) {
              _videoController.addListener(_handleVideoTick);
              setState(() {
                _isVideoInitialized = true;
                _videoLoadFailed = false;
              });
            }
          })
          .catchError((_) {
            if (mounted) {
              setState(() => _videoLoadFailed = true);
            }
          });
    }
  }

  Future<void> _checkLoginRewardAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id')?.trim() ?? '';
    final username = prefs.getString('username')?.trim() ?? '';

    if (!mounted) return;
    setState(() {
      _canEarnReward =
          userId.isNotEmpty && username.isNotEmpty && username != 'Khách';
      _isCheckingLogin = false;
    });
  }

  @override
  void dispose() {
    if (_usesVideoPlayer) {
      _videoController.removeListener(_handleVideoTick);
      _videoController.dispose();
    }
    super.dispose();
  }

  void _handleVideoTick() {
    if (!mounted || widget.type != 'video' || !_isVideoInitialized) return;
    setState(() {});
  }

  void _toggleVideoPlayback() {
    if (!_isVideoInitialized) return;
    setState(() {
      if (_videoController.value.isPlaying) {
        _videoController.pause();
        _showVideoControls = true;
      } else {
        _videoController.play();
        _showVideoControls = true;
      }
    });
  }

  bool _canPlayInlineVideo(String value) {
    final url = value.trim().toLowerCase();
    if (url.isEmpty) return false;
    if (url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('facebook.com') ||
        url.contains('tiktok.com')) {
      return false;
    }
    return url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.m4v') ||
        url.endsWith('.webm') ||
        url.contains('/culture_articles/video.php') ||
        url.contains('/uploads/');
  }

  Future<void> _openExternalVideo() async {
    final uri = Uri.tryParse(_resolvedMediaUrl);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Không mở được link video.")));
  }

  String _normalizeVideoUrl(String value) {
    final text = value.trim().replaceAll('\\', '/');
    if (text.isEmpty) return '';

    const marker = '/uploads/culture_videos/';
    final markerIndex = text.indexOf(marker);
    if (markerIndex != -1) {
      final fileName = text.substring(markerIndex + marker.length);
      return '${AppConfig.baseUrl}/culture_articles/video.php'
          '?file=${Uri.encodeComponent(fileName)}';
    }
    if (text.startsWith('uploads/culture_videos/')) {
      final fileName = text.substring('uploads/culture_videos/'.length);
      return '${AppConfig.baseUrl}/culture_articles/video.php'
          '?file=${Uri.encodeComponent(fileName)}';
    }
    if (text.startsWith('http://') || text.startsWith('https://')) {
      final uri = Uri.tryParse(text);
      if (uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
        final server = Uri.parse(AppConfig.serverUrl);
        return server.replace(path: uri.path, query: uri.query).toString();
      }
    }
    return text;
  }

  Future<void> _finishContent() async {
    if (!_canEarnReward) {
      Navigator.pop(context);
      return;
    }

    final award = await GamificationService.awardXP(widget.xpReward);
    if (!mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (award.levelUp) {
      await showLevelUpCelebrationDialog(
        context,
        level: award.level,
        points: award.points,
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Tuyệt vời! Bạn nhận được +${award.points} Điểm Hành Trình!',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == 'video') {
      return _buildVideoScaffold(context);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: widget.type == 'video' ? 430 : 300,
            pinned: true,
            backgroundColor: primaryPurple,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.black87,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(background: _buildMediaWidget()),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              transform: Matrix4.translationValues(0, -20, 0),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: textDark,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        widget.type == 'video'
                            ? "🎬 Video bài giảng"
                            : "📖 Bài đọc tham khảo",
                        style: TextStyle(
                          color: primaryPurple,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      widget.content,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8B66),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 5,
                        ),
                        onPressed: _isCheckingLogin ? null : _finishContent,
                        child: Text(
                          _canEarnReward
                              ? "Hoàn thành (+${widget.xpReward} Điểm)"
                              : "Đọc xong",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100C1F),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildMediaWidget()),
            Positioned(
              left: 12,
              top: 10,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.92),
                  foregroundColor: Colors.black87,
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaWidget() {
    if (widget.type == 'video') {
      if (!_usesVideoPlayer) {
        return Container(
          color: Colors.black87,
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Video này là link ngoài.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _openExternalVideo,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text("Mở video"),
              ),
            ],
          ),
        );
      }
      if (_videoLoadFailed) {
        return Container(
          color: Colors.black87,
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: const Text(
            "Không tải được video.\nVui lòng kiểm tra kết nối hoặc đường dẫn video.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }

      if (!_isVideoInitialized) {
        return Container(
          color: Colors.black87,
          child: Center(child: CircularProgressIndicator(color: primaryPurple)),
        );
      }
      final aspectRatio = _videoController.value.aspectRatio == 0
          ? 16 / 9
          : _videoController.value.aspectRatio;

      return Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenAspect =
                      constraints.maxWidth / constraints.maxHeight;
                  final useHeight = aspectRatio < screenAspect;
                  return Center(
                    child: useHeight
                        ? SizedBox(
                            height: constraints.maxHeight,
                            child: AspectRatio(
                              aspectRatio: aspectRatio,
                              child: VideoPlayer(_videoController),
                            ),
                          )
                        : SizedBox(
                            width: constraints.maxWidth,
                            child: AspectRatio(
                              aspectRatio: aspectRatio,
                              child: VideoPlayer(_videoController),
                            ),
                          ),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleVideoPlayback,
                child: const SizedBox.expand(),
              ),
            ),
            if (!_videoController.value.isPlaying)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            if (_showVideoControls || !_videoController.value.isPlaying)
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: _buildVideoControls(),
              ),
          ],
        ),
      );
    } else if (widget.type == 'image') {
      if (widget.mediaUrl.trim().isEmpty) {
        return Container(
          color: const Color(0xFFF4EFE8),
          alignment: Alignment.center,
          child: const Text(
            "Chưa có ảnh",
            style: TextStyle(
              color: Color(0xFF8C8177),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }
      // Đã đổi sang CachedNetworkImage để tiết kiệm dữ liệu Firebase
      return CachedNetworkImage(
        imageUrl: widget.mediaUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            Center(child: CircularProgressIndicator(color: primaryPurple)),
        errorWidget: (context, url, error) =>
            const Icon(Icons.error, color: Colors.red),
      );
    }
    return Container(color: primaryPurple);
  }

  Widget _buildVideoControls() {
    final position = _videoController.value.position;
    final duration = _videoController.value.duration;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            _formatDuration(position),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                min: 0,
                max: duration.inMilliseconds <= 0
                    ? 1
                    : duration.inMilliseconds.toDouble(),
                value: position.inMilliseconds
                    .clamp(
                      0,
                      duration.inMilliseconds <= 0
                          ? 1
                          : duration.inMilliseconds,
                    )
                    .toDouble(),
                activeColor: Colors.white,
                inactiveColor: Colors.white.withValues(alpha: 0.35),
                onChanged: (value) {
                  setState(() => _showVideoControls = true);
                  _videoController.seekTo(
                    Duration(milliseconds: value.round()),
                  );
                },
              ),
            ),
          ),
          Text(
            _formatDuration(duration),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
