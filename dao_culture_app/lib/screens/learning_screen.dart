import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
// ignore: unused_import
import '../services/learning_progress_service.dart';
import 'vocabulary_list_screen.dart';


class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  static const Color _ink = Color(0xFF0B302B);
  static const Color _green = Color(0xFF2F8E58);

Future<List<_TopicCardData>> _loadTopicCards() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id') ?? '';

  final rows = await ApiService.getLearningTopics(userId);

  return rows.map((row) {
    final data = Map<String, dynamic>.from(row);

    return _TopicCardData(
      topic: Topic(
        id: data['id'].toString(),
        title: data['title'].toString(),
      ),
      learned: int.tryParse(data['learned'].toString()) ?? 0,
      total: int.tryParse(data['total'].toString()) ?? 0,
    );
  }).toList();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/anhnenchude.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.02),
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.70),
                    Colors.white.withValues(alpha: 0.94),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.18, 0.42, 0.72, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: FutureBuilder<List<_TopicCardData>>(
              future: _loadTopicCards(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _green),
                  );
                }
                if (snapshot.hasError) {
                  return _buildMessage(
                    context,
                    'Không tải được chủ đề. Bạn thử lại sau nha.',
                  );
                }

                final cards = snapshot.data ?? [];
                if (cards.isEmpty) {
                  return _buildMessage(context, 'Chưa có chủ đề nào.');
                }

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(context)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _buildTopicCard(context, cards[index], index);
                        }, childCount: cards.length),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.72,
                            ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildBackButton(context),
              const SizedBox(width: 18),
              Expanded(
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: const TextSpan(
                    style: TextStyle(
                      color: _ink,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                    children: [
                      TextSpan(text: 'Chủ đề tiếng Dao '),
                      TextSpan(
                        text: '❖',
                        style: TextStyle(color: _green),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.pop(context),
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(Icons.chevron_left_rounded, color: _green, size: 38),
        ),
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, _TopicCardData data, int index) {
    final total = data.total;
    final learned = total == 0 ? 0 : data.learned.clamp(0, total);
    final progress = total == 0 ? 0.0 : learned / total;

    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final topicId = int.tryParse(data.topic.id) ?? 0;
          if (topicId <= 0) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VocabularyListScreen(
                topicId: topicId,
                topicTitle: data.topic.title,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    _topicVisual(data.topic.title, index),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 42, height: 1),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -8),
                child: Center(
                  child: Text(
                    data.topic.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: _green, size: 15),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '$learned/$total từ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF596865),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE8ECEB),
                  valueColor: const AlwaysStoppedAnimation<Color>(_green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context, String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
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
}

class _TopicCardData {
  final Topic topic;
  final int learned;
  final int total;

  const _TopicCardData({
    required this.topic,
    required this.learned,
    required this.total,
  });
}
