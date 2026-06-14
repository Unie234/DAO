import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/learning_progress_service.dart';
import 'learning_screen.dart';
import 'learning_progress_screen.dart';
import 'memory_challenge_topic_screen.dart';
import 'vocabulary_list_screen.dart';

class DaoLearningHomeScreen extends StatefulWidget {
  const DaoLearningHomeScreen({super.key});

  @override
  State<DaoLearningHomeScreen> createState() => _DaoLearningHomeScreenState();
}

class _DaoLearningHomeScreenState extends State<DaoLearningHomeScreen> {
  static const Color _ink = Color(0xFF1B1E24);
  static const Color _red = Color(0xFFD52B24);
  static const Color _blue = Color(0xFF1976D2);
  static const Color _paper = Color(0xFFF2F8FF);

  List<_LearningTool> get _tools => const [
    _LearningTool(
      title: "Từ vựng",
      subtitle: "15 chủ đề",
      icon: Icons.menu_book_rounded,
      color: _blue,
      background: Color(0xFFEAF5FF),
      action: _LearningAction.vocabulary,
    ),
    _LearningTool(
      title: "Thử thách",
      subtitle: "Vượt qua mỗi ngày",
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFE99A28),
      background: Color(0xFFFFF3DD),
      action: _LearningAction.memoryChallenge,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: FutureBuilder<LearningOverview>(
          future: _loadOverview(),
          builder: (context, snapshot) {
            final overview = snapshot.data ?? _emptyOverview;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(),
                        const SizedBox(height: 16),
                        _buildToolGrid(context),
                        const SizedBox(height: 16),
                        _buildProgressHeader(context, overview),
                        const SizedBox(height: 10),
                        _buildProgressCard(context, overview),
                        const SizedBox(height: 18),
                        _buildSectionHeader(context),
                        const SizedBox(height: 12),
                        _buildSuggestedTopics(context, overview.topics),
                        const SizedBox(height: 96),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<LearningOverview> _loadOverview() async {
    final topics = await ApiService.getTopics();
    final progress = await Future.wait(
      topics.map((topic) async {
        final topicId = int.tryParse(topic.id) ?? 0;
        final words = await ApiService.getVocabularyByTopic(topicId);
        return LearningProgressService.topicProgress(
          topicId: topicId,
          title: topic.title,
          total: words.length,
        );
      }),
    );

    return LearningProgressService.overview(progress);
  }

  static const LearningOverview _emptyOverview = LearningOverview(
    level: 1,
    currentXP: 0,
    nextLevelXP: 100,
    totalWords: 0,
    learnedWords: 0,
    rememberedWords: 0,
    todayLearned: 0,
    todayQuizCorrect: 0,
    learningMinutes: 0,
    topics: [],
  );

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.fromLTRB(12, 8, 18, 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4FAFF), Color(0xFFE8F5FF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 4,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.arrow_back_rounded, color: _ink),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 52,
            top: 12,
            right: 42,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        "Học tiếng Dao",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF102A56),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text("❖", style: TextStyle(color: _red, fontSize: 20)),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: -18,
            top: -20,
            child: Icon(
              Icons.terrain_rounded,
              size: 92,
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      height: 204,
      padding: const EdgeInsets.fromLTRB(22, 20, 0, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Hôm nay bạn muốn học gì?",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF12356A),
                    fontSize: 22,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Khám phá tiếng Dao qua\n15 chủ đề văn hóa",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF667286),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 180,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -10,
                  bottom: 2,
                  child: Image.asset(
                    "assets/culture_dictionary_lookup.png",
                    width: 172,
                    height: 142,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.menu_book_rounded,
                      size: 112,
                      color: _blue.withValues(alpha: 0.30),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 24,
                  child: Icon(
                    Icons.local_florist_rounded,
                    color: const Color(0xFF5F9A57).withValues(alpha: 0.75),
                    size: 42,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tools.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.75,
      ),
      itemBuilder: (context, index) {
        final tool = _tools[index];
        return GestureDetector(
          onTap: () => _openTool(context, tool.action),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(tool.icon, color: tool.color, size: 32),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tool.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 11.5,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tool.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF616A77),
                          fontSize: 9.5,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF45505E),
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressHeader(BuildContext context, LearningOverview overview) {
    return GestureDetector(
      onTap: () => _openProgress(context, overview),
      child: Row(
        children: const [
          Expanded(
            child: Text(
              "Tiến độ học tập",
              style: TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            "Xem chi tiết",
            style: TextStyle(
              color: _blue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: _blue, size: 20),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, LearningOverview overview) {
    final percent = overview.totalPercent.clamp(0.0, 1.0);
    final learnedToday = overview.todayLearned;

    return GestureDetector(
      onTap: () => _openProgress(context, overview),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 6,
                    backgroundColor: const Color(0xFFE8ECE7),
                    valueColor: const AlwaysStoppedAnimation<Color>(_blue),
                    strokeCap: StrokeCap.round,
                  ),
                  Text(
                    "${overview.totalPercentText}%",
                    style: TextStyle(
                      color: _blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "${overview.learnedWords} / ${overview.totalWords} từ",
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: percent,
                      backgroundColor: const Color(0xFFE9EEF5),
                      valueColor: const AlwaysStoppedAnimation<Color>(_blue),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF39B66A),
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Đã nhớ: ${overview.rememberedWords} từ",
                        style: const TextStyle(
                          color: Color(0xFF647080),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.track_changes_rounded,
                        color: _blue,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Mục tiêu hôm nay: ${learnedToday > 0 ? learnedToday : 5} từ",
                        style: const TextStyle(
                          color: Color(0xFF647080),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Gợi ý chủ đề",
            style: TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _openLearning(context),
          child: const Row(
            children: [
              Text(
                "Xem tất cả",
                style: TextStyle(
                  color: _blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: _blue, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedTopics(
    BuildContext context,
    List<TopicLearningProgress> progress,
  ) {
    final topics = _buildRecommendedTopics(progress);
    if (topics.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: topics.map((topic) {
          final index = topics.indexOf(topic);
          final color = _topicColor(index);
          final background = _topicBackground(index);
          final visual = _topicVisual(topic.title, index);

          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => _openSuggestedTopic(context, topic),
              child: Container(
                width: 104,
                padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            visual,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 30, height: 1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      topic.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${topic.learned}/${topic.total} từ",
                      style: const TextStyle(
                        color: Color(0xFF5F6269),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${topic.percentText}% · Chưa nhớ ${topic.notRememberedCount}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: topic.percent,
                        minHeight: 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.62),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Text(
                        "Học ngay",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<TopicLearningProgress> _buildRecommendedTopics(
    List<TopicLearningProgress> progress,
  ) {
    final topics = progress.where((topic) => topic.total > 0).toList();
    topics.sort((a, b) {
      final aInProgress = a.learned > 0 && a.learned < a.total;
      final bInProgress = b.learned > 0 && b.learned < b.total;
      if (aInProgress != bInProgress) return aInProgress ? -1 : 1;
      if (aInProgress && bInProgress) {
        return b.percent.compareTo(a.percent);
      }

      final aNotStarted = a.learned == 0;
      final bNotStarted = b.learned == 0;
      if (aNotStarted != bNotStarted) return aNotStarted ? -1 : 1;

      final aCompleted = a.total > 0 && a.learned >= a.total;
      final bCompleted = b.total > 0 && b.learned >= b.total;
      if (aCompleted != bCompleted) return aCompleted ? 1 : -1;

      return a.topicId.compareTo(b.topicId);
    });

    return topics;
  }

  Future<void> _openLearning(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LearningScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openProgress(
    BuildContext context,
    LearningOverview overview,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningProgressScreen(overview: overview),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openSuggestedTopic(
    BuildContext context,
    TopicLearningProgress topic,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VocabularyListScreen(
          topicId: topic.topicId,
          topicTitle: topic.title,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openTool(BuildContext context, _LearningAction action) async {
    if (action == _LearningAction.memoryChallenge) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MemoryChallengeTopicScreen()),
      );
      if (mounted) setState(() {});
      return;
    }

    _openLearning(context);
  }
}

enum _LearningAction { vocabulary, memoryChallenge }

class _LearningTool {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;
  final _LearningAction action;

  const _LearningTool({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
    required this.action,
  });
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

Color _topicColor(int index) {
  return const [
    Color(0xFF4C9CE0),
    Color(0xFF7B4ACB),
    Color(0xFFE99A28),
    Color(0xFF2F8A4C),
  ][index % 4];
}

Color _topicBackground(int index) {
  return const [
    Color(0xFFEAF5FF),
    Color(0xFFF3ECFF),
    Color(0xFFFFF3DD),
    Color(0xFFEAF7ED),
  ][index % 4];
}
