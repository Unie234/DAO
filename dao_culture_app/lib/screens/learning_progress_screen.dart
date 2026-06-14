import 'package:flutter/material.dart';

import '../services/gamification_service.dart';
import '../services/learning_progress_service.dart';

class LearningProgressScreen extends StatelessWidget {
  final LearningOverview initialOverview;

  const LearningProgressScreen({super.key, required LearningOverview overview})
    : initialOverview = overview;

  static const Color _ink = Color(0xFF1C2026);
  static const Color _red = Color(0xFF1976D2);
  static const Color _paper = Color(0xFFF2F8FF);
  static const Color _gold = Color(0xFFE99A28);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: FutureBuilder<LearningOverview>(
          future: LearningProgressService.overview(initialOverview.topics),
          builder: (context, snapshot) {
            final overview = snapshot.data ?? initialOverview;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverToBoxAdapter(
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      color: _red,
                      backgroundColor: Color(0xFFD9ECFF),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      children: [
                        _buildLevelCard(overview),
                        const SizedBox(height: 14),
                        _buildJourneyCard(overview),
                        const SizedBox(height: 14),
                        _buildTodayCard(overview),
                        const SizedBox(height: 14),
                        _buildTopicProgressCard(overview),
                        const SizedBox(height: 14),
                        _buildAchievementsCard(overview),
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

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 4,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: _ink),
            ),
          ),
          const Text(
            "Tiến độ học tập",
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(LearningOverview overview) {
    final title = GamificationService.titleForLevel(overview.level);
    final stage = GamificationService.journeyStageForLevel(overview.level);
    final levelStart = GamificationService.currentLevelStartXP(overview.level);
    final levelEnd = overview.nextLevelXP;
    final levelRange = (levelEnd - levelStart).clamp(1, 999999);
    final xpInLevel = (overview.currentXP - levelStart).clamp(0, levelRange);
    final percent = overview.level >= GamificationService.levelThresholds.length
        ? 1.0
        : xpInLevel / levelRange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Icon(Icons.auto_awesome_rounded, color: _red, size: 38),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lv.${overview.level}  ·  $title",
                  style: const TextStyle(
                    color: _red,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stage,
                  style: const TextStyle(
                    color: Color(0xFF506178),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  "${overview.currentXP} Điểm Hành Trình",
                  style: const TextStyle(
                    color: _red,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 7,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(_red),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  overview.level >= GamificationService.levelThresholds.length
                      ? "Bạn đã đạt danh hiệu cao nhất của hành trình"
                      : "Còn ${levelEnd - overview.currentXP} điểm để lên Lv.${overview.level + 1}",
                  style: const TextStyle(
                    color: Color(0xFF506178),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _gold,
              shape: BoxShape.circle,
            ),
            child: Text(
              "${overview.level}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyCard(LearningOverview overview) {
    final completedTopics = overview.topics
        .where((topic) => topic.total > 0 && topic.learned >= topic.total)
        .length;
    final rememberedPercent = overview.totalWords == 0
        ? 0
        : ((overview.rememberedWords / overview.totalWords) * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12356A),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF12356A).withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.landscape_rounded, color: Color(0xFFBFE3FF), size: 22),
              SizedBox(width: 8),
              Text(
                "Hành Trình Bản Sắc",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Mỗi từ bạn học là một dấu chân nhỏ trên hành trình gìn giữ tiếng Dao.",
            style: TextStyle(
              color: Color(0xFFE8F5FF),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildJourneyStat(
                  Icons.menu_book_rounded,
                  "${overview.learnedWords}/${overview.totalWords}",
                  "Từ đã học",
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildJourneyStat(
                  Icons.psychology_alt_rounded,
                  "$rememberedPercent%",
                  "Đã nhớ",
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildJourneyStat(
                  Icons.workspace_premium_rounded,
                  "$completedTopics",
                  "Chủ đề trọn vẹn",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayCard(LearningOverview overview) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.today_rounded, color: _gold, size: 18),
              SizedBox(width: 8),
              Text(
                "Hôm nay",
                style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
              ),
              Spacer(),
              Text(
                "Cập nhật tự động",
                style: TextStyle(
                  color: Color(0xFF8A8D93),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTodayStat(
                Icons.menu_book_rounded,
                Colors.green,
                "${overview.todayLearned} / 10 từ",
                "Đã học",
              ),
              _buildDivider(),
              _buildTodayStat(
                Icons.check_circle_rounded,
                Colors.deepPurple,
                "${overview.todayQuizCorrect} câu",
                "Quiz đúng",
              ),
              _buildDivider(),
              _buildTodayStat(
                Icons.access_time_rounded,
                Colors.blue,
                "${overview.learningMinutes} phút",
                "Thời gian học",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicProgressCard(LearningOverview overview) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tiến độ theo chủ đề",
            style: TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ...overview.topics.map((topic) => _buildTopicRow(topic)),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard(LearningOverview overview) {
    final completedTopics = overview.topics
        .where((topic) => topic.total > 0 && topic.learned >= topic.total)
        .length;
    final hasPerfectMemory = overview.todayQuizCorrect >= 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Thành tích",
            style: TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              _buildAchievement(
                Icons.spa_rounded,
                "Mầm tiếng Dao",
                overview.learnedWords > 0
                    ? "Đã học từ đầu tiên"
                    : "Học từ đầu tiên",
              ),
              _buildAchievement(
                Icons.emoji_events_rounded,
                "Chủ đề đầu tiên",
                completedTopics > 0
                    ? "Đã hoàn thành $completedTopics chủ đề"
                    : "Hoàn thành một chủ đề",
              ),
              _buildAchievement(
                Icons.local_fire_department_rounded,
                "Người giữ lửa",
                "Duy trì chuỗi học mỗi ngày",
              ),
              _buildAchievement(
                Icons.bolt_rounded,
                "Trí nhớ sắc bén",
                hasPerfectMemory
                    ? "Hôm nay đã đạt 10 câu"
                    : "Đạt 10/10 thử thách",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStat(
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
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
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF777A80),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 54, color: const Color(0xFFEAE5DE));
  }

  Widget _buildTopicRow(TopicLearningProgress topic) {
    final color = _topicColor(topic.title);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(_topicIcon(topic.title), color: color, size: 18),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: Text(
              topic.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: topic.percent,
                minHeight: 7,
                backgroundColor: const Color(0xFFEDE8DF),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "${topic.learned}/${topic.total} từ",
            style: const TextStyle(
              color: Color(0xFF5F6269),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(
              "${topic.percentText}%",
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievement(IconData icon, String title, String subtitle) {
    return SizedBox(
      width: 150,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3DD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _gold, size: 21),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF777A80),
                    fontSize: 10,
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

  Widget _buildJourneyStat(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFBFE3FF), size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE8F5FF),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFDDEBFA)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  IconData _topicIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('gia đình')) return Icons.family_restroom_rounded;
    if (lower.contains('màu')) return Icons.palette_rounded;
    if (lower.contains('vật')) return Icons.pets_rounded;
    if (lower.contains('đồ')) return Icons.chair_rounded;
    if (lower.contains('địa')) return Icons.location_on_rounded;
    return Icons.menu_book_rounded;
  }

  Color _topicColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('gia đình')) return const Color(0xFF4C9CE0);
    if (lower.contains('màu')) return const Color(0xFF7B4ACB);
    if (lower.contains('vật')) return const Color(0xFFE99A28);
    if (lower.contains('đồ')) return const Color(0xFF4D9AD6);
    if (lower.contains('địa')) return const Color(0xFF1976D2);
    return const Color(0xFF2F8A4C);
  }
}
