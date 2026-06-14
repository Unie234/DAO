import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';
import '../services/api_service.dart';
import '../services/learning_progress_service.dart';
import 'vocabulary_memory_challenge_screen.dart';

class VocabularyListScreen extends StatefulWidget {
  final int topicId;
  final String topicTitle;

  const VocabularyListScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
  });

  @override
  State<VocabularyListScreen> createState() => _VocabularyListScreenState();
}

class _VocabularyListScreenState extends State<VocabularyListScreen> {
  static const Color _ink = Color(0xFF0B302B);
  static const Color _green = Color(0xFF2F8E58);
  static const Color _lightGreen = Color(0xFFE6F3EB);
  static const Color _paper = Color(0xFFF5FAF7);

  final AudioPlayer _audioPlayer = AudioPlayer();
  late final Future<List<dynamic>> _vocabularyFuture;
  late final DateTime _sessionStartedAt;
  Set<String> _learnedWordIds = {};
  Set<String> _rememberedWordIds = {};
  Set<String> _favoriteWordKeys = {};
  int _currentIndex = 0;
  bool _progressLoaded = false;

  @override
  void initState() {
    super.initState();
    _sessionStartedAt = DateTime.now();
    _vocabularyFuture = ApiService.getVocabularyByTopic(widget.topicId);
    _loadFavoriteWords();
  }

  @override
  void dispose() {
    unawaited(LearningProgressService.saveStudyDuration(_sessionStartedAt));
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: _vocabularyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _green),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return _buildStateMessage("Không tải được từ vựng.");
            }

            final words = snapshot.data!;
            if (words.isEmpty) {
              return _buildStateMessage("Chủ đề này chưa có từ vựng.");
            }

            _ensureProgressLoaded(words);

            final safeIndex = _currentIndex.clamp(0, words.length - 1);
            final word = words[safeIndex] as Map<String, dynamic>;
            final daoWord = (word['dao_word'] ?? '').toString();
            final vietWord = (word['viet_word'] ?? '').toString();
            final pronunciation = (word['pronunciation'] ?? '').toString();
            final audioFile = (word['audio_file'] ?? '').toString();
            final imageUrl = _resolveWordImageUrl(word);
            final wordKey = LearningProgressService.wordKey(word);
            final isRemembered = _rememberedWordIds.contains(wordKey);
            final isFavorite = _favoriteWordKeys.contains(_favoriteKey(word));
            final learnedCount = _learnedWordIds.length.clamp(0, words.length);

            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                children: [
                  _buildHeader(safeIndex, words.length, word, isFavorite),
                  const SizedBox(height: 10),
                  _buildDotProgress(safeIndex, words.length),
                  const SizedBox(height: 22),
                  Expanded(
                    child: Center(
                      child: _buildFlashcard(
                        vietWord: vietWord,
                        daoWord: daoWord,
                        pronunciation: pronunciation,
                        audioFile: audioFile,
                        imageUrl: imageUrl,
                        isRemembered: isRemembered,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStudyHint(),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBottomButton(
                          "Chưa nhớ",
                          Colors.grey.shade200,
                          _ink,
                          Icons.replay_rounded,
                          () => _markAndMove(word, words, remembered: false),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildBottomButton(
                          "Đã nhớ",
                          _green,
                          Colors.white,
                          Icons.check_rounded,
                          () => _markAndMove(word, words, remembered: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildTopicProgress(learnedCount, words.length),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    int index,
    int total,
    Map<String, dynamic> word,
    bool isFavorite,
  ) {
    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: _ink),
            ),
          ),
          Positioned.fill(
            left: 54,
            right: 54,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Chủ đề: ${widget.topicTitle}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${index + 1} / $total",
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -4,
            child: IconButton(
              onPressed: () => _toggleFavorite(word),
              icon: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavorite ? _green : _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotProgress(int index, int total) {
    final visible = total.clamp(1, 12);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(visible, (dotIndex) {
        final isActive = dotIndex == index.clamp(0, visible - 1);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: isActive ? 9 : 7,
          height: isActive ? 9 : 7,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: isActive ? _green : const Color(0xFFDCE9E1),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildFlashcard({
    required String vietWord,
    required String daoWord,
    required String pronunciation,
    required String audioFile,
    required String imageUrl,
    required bool isRemembered,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 330, maxHeight: 520),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E9DE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -14,
            child: Icon(
              Icons.landscape_rounded,
              size: 92,
              color: _green.withValues(alpha: 0.10),
            ),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _lightGreen,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        "Từ vựng",
                        style: TextStyle(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isRemembered
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFE2A058),
                      size: 26,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildWordIllustration(imageUrl: imageUrl),
                const SizedBox(height: 20),
                _buildAdaptiveWordText(
                  vietWord.isEmpty ? "..." : vietWord,
                  baseSize: 33,
                  minSize: 23,
                  weight: FontWeight.w900,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _buildAdaptiveWordText(
                  daoWord.isEmpty ? "..." : daoWord,
                  baseSize: 24,
                  minSize: 18,
                  weight: FontWeight.w900,
                  maxLines: 4,
                  color: _green,
                ),
                if (pronunciation.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    "/${pronunciation.trim()}/",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF767A82),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: () => _playAudio(audioFile),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: _lightGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up_rounded, color: _green, size: 22),
                        SizedBox(width: 8),
                        Text(
                          "Nghe phát âm",
                          style: TextStyle(
                            color: _green,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveWordText(
    String text, {
    required double baseSize,
    required double minSize,
    required FontWeight weight,
    required int maxLines,
    Color color = _ink,
  }) {
    final length = text.characters.length;
    final fontSize = length > 34
        ? minSize
        : length > 24
        ? baseSize - 7
        : length > 16
        ? baseSize - 4
        : baseSize;

    return Text(
      text,
      maxLines: maxLines,
      textAlign: TextAlign.center,
      overflow: TextOverflow.visible,
      softWrap: true,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        height: 1.12,
        fontWeight: weight,
      ),
    );
  }

  Widget _buildWordIllustration({required String imageUrl}) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Image.network(
          imageUrl,
          width: 144,
          height: 144,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
        ),
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 144,
      height: 144,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F1),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE6DAD2)),
      ),
      child: Center(
        child: Text(
          "Chưa có ảnh",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _resolveWordImageUrl(Map<String, dynamic> word) {
    final raw =
        (word['image_url'] ??
                word['image_file'] ??
                word['image'] ??
                word['picture'] ??
                '')
            .toString()
            .trim();

    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return '${AppConfig.baseUrl}$raw';
    if (raw.startsWith('uploads/')) return '${AppConfig.baseUrl}/$raw';
    return '${AppConfig.baseUrl}/uploads/vocabulary/$raw';
  }

  Widget _buildBottomButton(
    String label,
    Color background,
    Color foreground,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            if (background == _green)
              BoxShadow(
                color: _green.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyHint() {
    return const Text(
      "Bấm một lựa chọn bên dưới để lưu tiến độ\nvà chuyển sang từ tiếp theo.",
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0xFF8A8D93),
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildTopicProgress(int learned, int total) {
    final value = total == 0 ? 0.0 : learned / total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: _green, size: 18),
          const SizedBox(width: 10),
          const Text(
            "Tiến độ chủ đề",
            style: TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: const Color(0xFFD6E5DC),
                valueColor: const AlwaysStoppedAnimation<Color>(_green),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "$learned/$total từ",
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _ensureProgressLoaded(List<dynamic> words) async {
    if (_progressLoaded) return;
    _progressLoaded = true;

    final progress = await LearningProgressService.topicWordSets(
      widget.topicId,
    );

    if (!mounted) return;
    setState(() {
      _learnedWordIds = progress.learned;
      _rememberedWordIds = progress.remembered;
    });
  }

  Future<void> _loadFavoriteWords() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    if (userId.isEmpty) {
      if (!mounted) return;
      setState(() => _favoriteWordKeys = {});
      return;
    }

    final localKeys = prefs.getStringList(await _favoriteStorageKey()) ?? [];
    final serverFavorites = await ApiService.getDictionaryFavorites(userId);
    final keys = serverFavorites.isEmpty
        ? localKeys
        : serverFavorites
              .map(
                (item) =>
                    _favoriteKeyFromValues(item['vietnamese'], item['dao']),
              )
              .toList();

    if (serverFavorites.isNotEmpty) {
      await prefs.setStringList(await _favoriteStorageKey(), keys);
    }

    if (!mounted) return;
    setState(() => _favoriteWordKeys = keys.toSet());
  }

  Future<void> _toggleFavorite(Map<String, dynamic> word) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    if (userId.isEmpty) {
      _showLoginRequired("lưu từ yêu thích");
      return;
    }

    final key = _favoriteKey(word);
    final willFavorite = !_favoriteWordKeys.contains(key);
    final nextFavorites = {..._favoriteWordKeys};
    if (willFavorite) {
      nextFavorites.add(key);
    } else {
      nextFavorites.remove(key);
    }

    await prefs.setStringList(
      await _favoriteStorageKey(),
      nextFavorites.toList(),
    );

    final saved = await ApiService.toggleDictionaryFavorite(
      userId: userId,
      word: {
        "id": word['id']?.toString() ?? "",
        "vietnamese": word['viet_word']?.toString() ?? "",
        "dao": word['dao_word']?.toString() ?? "",
      },
      favorite: willFavorite,
    );

    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Chưa lưu được từ yêu thích. Vui lòng thử lại."),
        ),
      );
    }

    if (!mounted) return;
    setState(() => _favoriteWordKeys = nextFavorites);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(willFavorite ? "Đã lưu từ yêu thích." : "Đã bỏ lưu từ."),
      ),
    );
  }

  String _favoriteKey(Map<String, dynamic> word) {
    return _favoriteKeyFromValues(word['viet_word'], word['dao_word']);
  }

  String _favoriteKeyFromValues(dynamic vietnamese, dynamic dao) {
    return '${(vietnamese ?? '').toString().trim().toLowerCase()}|${(dao ?? '').toString().trim().toLowerCase()}';
  }

  Future<String> _favoriteStorageKey() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'guest';
    return 'dao_dictionary_favorites_$userId';
  }

  Future<void> _markAndMove(
    Map<String, dynamic> word,
    List<dynamic> words, {
    required bool remembered,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    if (userId.isEmpty) {
      _showLoginRequired("lưu tiến độ học");
      return;
    }

    final wordKey = LearningProgressService.wordKey(word);
    await LearningProgressService.markWord(
      topicId: widget.topicId,
      word: word,
      remembered: remembered,
    );

    if (!mounted) return;
    setState(() {
      _learnedWordIds = {..._learnedWordIds, wordKey};
      if (remembered) {
        _rememberedWordIds = {..._rememberedWordIds, wordKey};
      } else {
        _rememberedWordIds = {..._rememberedWordIds}..remove(wordKey);
      }
    });

    if (_currentIndex < words.length - 1) {
      _goToIndex(_currentIndex + 1);
    } else {
      _showTopicCompletedDialog(words);
    }
  }

  void _showLoginRequired(String action) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Vui lòng đăng nhập để $action.")));
  }

  Future<void> _playAudio(String audioFile) async {
    if (audioFile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Từ này chưa có âm thanh mẫu.")),
      );
      return;
    }

    try {
      final audioUrl = ApiService.vocabularyAudioUrl(audioFile);
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không phát được âm thanh mẫu.")),
      );
    }
  }

  void _showTopicCompletedDialog(List<dynamic> words) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          "Chúc mừng bạn!",
          textAlign: TextAlign.center,
          style: TextStyle(color: _green, fontWeight: FontWeight.w900),
        ),
        content: Text(
          "Bạn đã học hết ${words.length} từ trong chủ đề ${widget.topicTitle}.\n\nBạn có muốn làm Thử thách ghi nhớ để nhớ từ lâu hơn và nhận thêm XP/thành tích không?",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, height: 1.45),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  child: const Text("Để sau"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _green),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VocabularyMemoryChallengeScreen(
                          topicTitle: widget.topicTitle,
                          vocabulary: words,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Bắt đầu",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
