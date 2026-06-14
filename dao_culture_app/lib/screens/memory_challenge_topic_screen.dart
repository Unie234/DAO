import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'vocabulary_memory_challenge_screen.dart';

class MemoryChallengeTopicScreen extends StatelessWidget {
  const MemoryChallengeTopicScreen({super.key});

  static const Color _ink = Color(0xFF1C2026);
  static const Color _red = Color(0xFF1976D2);
  static const Color _paper = Color(0xFFF2F8FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: FutureBuilder<List<Topic>>(
                future: ApiService.getTopics(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _red),
                    );
                  }

                  final topics = snapshot.data ?? [];
                  if (topics.isEmpty) {
                    return const Center(child: Text("Chưa có chủ đề nào."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    itemCount: topics.length,
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      return _buildTopicCard(context, topic, index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        height: 70,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 52,
                height: 52,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 24,
                  tooltip: "Quay lại",
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: _ink),
                ),
              ),
            ),
            const Positioned.fill(
              left: 64,
              right: 64,
              child: Center(
                child: Text(
                  "Chọn chủ đề thử thách",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, Topic topic, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5FF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(
            child: Text(
              _topicVisual(topic.title, index),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, height: 1),
            ),
          ),
        ),
        title: Text(
          topic.title,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w900),
        ),
        subtitle: const Text("Luyện nhớ từ trong chủ đề này"),
        trailing: const Icon(Icons.chevron_right_rounded, color: _red),
        onTap: () => _openChallenge(context, topic),
      ),
    );
  }

  Future<void> _openChallenge(BuildContext context, Topic topic) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: _red)),
    );

    final vocabulary = await ApiService.getVocabularyByTopic(
      int.parse(topic.id),
    );

    if (!context.mounted) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VocabularyMemoryChallengeScreen(
          topicTitle: topic.title,
          vocabulary: vocabulary,
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
