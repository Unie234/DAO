import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'gamification_service.dart';

class LearningProgressService {
  static String wordKey(Map<String, dynamic> word) {
    final id = (word['id'] ?? '').toString().trim();
    if (id.isNotEmpty) return id;

    final daoWord = (word['dao_word'] ?? '').toString().trim();
    final vietWord = (word['viet_word'] ?? '').toString().trim();
    return '$daoWord|$vietWord';
  }

  static Future<void> markWord({
    required int topicId,
    required Map<String, dynamic> word,
    required bool remembered,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id')?.trim() ?? '';
    final owner = _progressOwner(userId);
    final key = wordKey(word);
    final learned = _readProgressList(
      prefs,
      _learnedKey(topicId, owner),
      legacyKey: _legacyLearnedKey(topicId),
      allowLegacy: userId.isNotEmpty,
    );
    final rememberedWords = _readProgressList(
      prefs,
      _rememberedKey(topicId, owner),
      legacyKey: _legacyRememberedKey(topicId),
      allowLegacy: userId.isNotEmpty,
    );
    final today = _readProgressList(
      prefs,
      _todayLearnedKey(owner),
      legacyKey: _legacyTodayLearnedKey(),
      allowLegacy: userId.isNotEmpty,
    );
    final isNewLearnedWord = !learned.contains(key);
    final isNewTodayWord = !today.contains(key);

    if (isNewLearnedWord) learned.add(key);
    if (isNewTodayWord) today.add(key);

    if (remembered) {
      if (!rememberedWords.contains(key)) rememberedWords.add(key);
    } else {
      rememberedWords.remove(key);
    }

    await prefs.setStringList(_learnedKey(topicId, owner), learned);
    await prefs.setStringList(_rememberedKey(topicId, owner), rememberedWords);
    await prefs.setStringList(_todayLearnedKey(owner), today);

    final vocabularyId = int.tryParse((word['id'] ?? '').toString()) ?? 0;
    if (userId.isNotEmpty && vocabularyId > 0) {
      await ApiService.markLearningWord(
        userId: userId,
        topicId: topicId,
        vocabularyId: vocabularyId,
        remembered: remembered,
      );

      if (isNewTodayWord) {
        await ApiService.addLearningDailyStats(userId: userId, learnedCount: 1);
      }
    }
  }

  static Future<TopicLearningProgress> topicProgress({
    required int topicId,
    required String title,
    required int total,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id')?.trim() ?? '';
    final owner = _progressOwner(userId);

    if (userId.isNotEmpty) {
      final serverProgress = await ApiService.getTopicLearningProgress(
        userId: userId,
        topicId: topicId,
      );

      if (serverProgress != null) {
        final learnedCount =
            int.tryParse(serverProgress['learned_count'].toString()) ?? 0;
        final rememberedCount =
            int.tryParse(serverProgress['remembered_count'].toString()) ?? 0;

        return TopicLearningProgress(
          topicId: topicId,
          title: title,
          total: total,
          learned: learnedCount.clamp(0, total),
          remembered: rememberedCount.clamp(0, total),
        );
      }
    }

    final learned = _readProgressList(
      prefs,
      _learnedKey(topicId, owner),
      legacyKey: _legacyLearnedKey(topicId),
      allowLegacy: userId.isNotEmpty,
    );
    final remembered = _readProgressList(
      prefs,
      _rememberedKey(topicId, owner),
      legacyKey: _legacyRememberedKey(topicId),
      allowLegacy: userId.isNotEmpty,
    );

    return TopicLearningProgress(
      topicId: topicId,
      title: title,
      total: total,
      learned: learned.length.clamp(0, total),
      remembered: remembered.length.clamp(0, total),
    );
  }

  static Future<({Set<String> learned, Set<String> remembered})> topicWordSets(
    int topicId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id')?.trim() ?? '';
    final owner = _progressOwner(userId);

    if (userId.isNotEmpty) {
      final serverProgress = await ApiService.getTopicLearningProgress(
        userId: userId,
        topicId: topicId,
      );

      if (serverProgress != null) {
        return (
          learned: _dynamicListToStringSet(serverProgress['learned_ids']),
          remembered: _dynamicListToStringSet(serverProgress['remembered_ids']),
        );
      }
    }

    return (
      learned: _readProgressList(
        prefs,
        _learnedKey(topicId, owner),
        legacyKey: _legacyLearnedKey(topicId),
        allowLegacy: userId.isNotEmpty,
      ).toSet(),
      remembered: _readProgressList(
        prefs,
        _rememberedKey(topicId, owner),
        legacyKey: _legacyRememberedKey(topicId),
        allowLegacy: userId.isNotEmpty,
      ).toSet(),
    );
  }

  static Future<LearningOverview> overview(
    List<TopicLearningProgress> topics,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id')?.trim() ?? '';
    final owner = _progressOwner(userId);
    final localTodayLearned = _readProgressList(
      prefs,
      _todayLearnedKey(owner),
      legacyKey: _legacyTodayLearnedKey(),
      allowLegacy: userId.isNotEmpty,
    );
    final localQuizCorrect = _readProgressInt(
      prefs,
      _todayQuizKey(owner),
      legacyKey: _legacyTodayQuizKey(),
      allowLegacy: userId.isNotEmpty,
    );
    final localLearningMinutes = _readProgressInt(
      prefs,
      _todayMinutesKey(owner),
      legacyKey: _legacyTodayMinutesKey(),
      allowLegacy: userId.isNotEmpty,
    );

    if (userId.isNotEmpty) {
      final serverOverview = await ApiService.getLearningOverview(userId);
      if (serverOverview != null) {
        final overview = LearningOverview.fromJson(serverOverview);
        return overview.copyWith(
          todayLearned: overview.todayLearned > 0
              ? overview.todayLearned
              : localTodayLearned.length,
          todayQuizCorrect: overview.todayQuizCorrect > 0
              ? overview.todayQuizCorrect
              : localQuizCorrect,
          learningMinutes: overview.learningMinutes > 0
              ? overview.learningMinutes
              : localLearningMinutes,
        );
      }
    }

    final currentXP = prefs.getInt('currentXP') ?? 0;
    final currentLevel = prefs.getInt('currentLevel') ?? 1;

    final total = topics.fold<int>(0, (sum, topic) => sum + topic.total);
    final learned = topics.fold<int>(0, (sum, topic) => sum + topic.learned);
    final remembered = topics.fold<int>(
      0,
      (sum, topic) => sum + topic.remembered,
    );

    return LearningOverview(
      level: currentLevel,
      currentXP: currentXP,
      nextLevelXP: GamificationService.nextLevelXP(currentLevel),
      totalWords: total,
      learnedWords: learned,
      rememberedWords: remembered,
      todayLearned: localTodayLearned.length,
      todayQuizCorrect: localQuizCorrect,
      learningMinutes: localLearningMinutes,
      topics: topics,
    );
  }

  static Future<void> saveQuizResult({
    required int correct,
    required int total,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id')?.trim() ?? '';
    final owner = _progressOwner(userId);
    final current = _readProgressInt(
      prefs,
      _todayQuizKey(owner),
      legacyKey: _legacyTodayQuizKey(),
      allowLegacy: userId.isNotEmpty,
    );
    await prefs.setInt(_todayQuizKey(owner), current + correct);
    if (userId.isNotEmpty && correct > 0) {
      await ApiService.addLearningDailyStats(
        userId: userId,
        quizCorrect: correct,
      );
    }
  }

  static Future<void> saveStudyDuration(DateTime startedAt) async {
    final seconds = DateTime.now().difference(startedAt).inSeconds;
    if (seconds < 10) return;

    final minutes = (seconds / 60).ceil().clamp(1, 240);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id')?.trim() ?? '';
    final owner = _progressOwner(userId);
    final currentMinutes = _readProgressInt(
      prefs,
      _todayMinutesKey(owner),
      legacyKey: _legacyTodayMinutesKey(),
      allowLegacy: userId.isNotEmpty,
    );
    await prefs.setInt(
      _todayMinutesKey(owner),
      (currentMinutes + minutes).clamp(0, 240),
    );

    if (userId.isNotEmpty) {
      await ApiService.addLearningDailyStats(
        userId: userId,
        studyMinutes: minutes,
      );
    }
  }

  static String _progressOwner(String userId) {
    return userId.isEmpty ? 'guest' : 'user_$userId';
  }

  static List<String> _readProgressList(
    SharedPreferences prefs,
    String key, {
    required String legacyKey,
    required bool allowLegacy,
  }) {
    final current = prefs.getStringList(key);
    if (current != null) return current;
    if (!allowLegacy) return [];
    return prefs.getStringList(legacyKey) ?? [];
  }

  static int _readProgressInt(
    SharedPreferences prefs,
    String key, {
    required String legacyKey,
    required bool allowLegacy,
  }) {
    final current = prefs.getInt(key);
    if (current != null) return current;
    if (!allowLegacy) return 0;
    return prefs.getInt(legacyKey) ?? 0;
  }

  static String _learnedKey(int topicId, String owner) {
    return 'dao_${owner}_learned_topic_$topicId';
  }

  static String _rememberedKey(int topicId, String owner) {
    return 'dao_${owner}_remembered_topic_$topicId';
  }

  static String _legacyLearnedKey(int topicId) => 'dao_learned_topic_$topicId';
  static String _legacyRememberedKey(int topicId) {
    return 'dao_remembered_topic_$topicId';
  }

  static Set<String> _dynamicListToStringSet(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toSet();
    }
    return {};
  }

  static String _todayLearnedKey(String owner) {
    return 'dao_${owner}_today_learned_${_todayKey()}';
  }

  static String _todayQuizKey(String owner) {
    return 'dao_${owner}_today_quiz_correct_${_todayKey()}';
  }

  static String _todayMinutesKey(String owner) {
    return 'dao_${owner}_today_learning_minutes_${_todayKey()}';
  }

  static String _legacyTodayLearnedKey() {
    return 'dao_today_learned_${_todayKey()}';
  }

  static String _legacyTodayQuizKey() {
    return 'dao_today_quiz_correct_${_todayKey()}';
  }

  static String _legacyTodayMinutesKey() {
    return 'dao_today_learning_minutes_${_todayKey()}';
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class LearningOverview {
  final int level;
  final int currentXP;
  final int nextLevelXP;
  final int totalWords;
  final int learnedWords;
  final int rememberedWords;
  final int todayLearned;
  final int todayQuizCorrect;
  final int learningMinutes;
  final List<TopicLearningProgress> topics;

  const LearningOverview({
    required this.level,
    required this.currentXP,
    required this.nextLevelXP,
    required this.totalWords,
    required this.learnedWords,
    required this.rememberedWords,
    required this.todayLearned,
    required this.todayQuizCorrect,
    required this.learningMinutes,
    required this.topics,
  });

  factory LearningOverview.fromJson(Map<String, dynamic> json) {
    final topicItems = json['topics'];
    final parsedTopics = topicItems is List
        ? topicItems
              .whereType<Map<String, dynamic>>()
              .map(TopicLearningProgress.fromJson)
              .toList()
        : <TopicLearningProgress>[];

    return LearningOverview(
      level: int.tryParse((json['level'] ?? '1').toString()) ?? 1,
      currentXP: int.tryParse((json['current_xp'] ?? '0').toString()) ?? 0,
      nextLevelXP:
          int.tryParse((json['next_level_xp'] ?? '100').toString()) ?? 100,
      totalWords: int.tryParse((json['total_words'] ?? '0').toString()) ?? 0,
      learnedWords:
          int.tryParse((json['learned_words'] ?? '0').toString()) ?? 0,
      rememberedWords:
          int.tryParse((json['remembered_words'] ?? '0').toString()) ?? 0,
      todayLearned:
          int.tryParse((json['today_learned'] ?? '0').toString()) ?? 0,
      todayQuizCorrect:
          int.tryParse((json['today_quiz_correct'] ?? '0').toString()) ?? 0,
      learningMinutes:
          int.tryParse((json['learning_minutes'] ?? '0').toString()) ?? 0,
      topics: parsedTopics,
    );
  }

  LearningOverview copyWith({
    int? level,
    int? currentXP,
    int? nextLevelXP,
    int? totalWords,
    int? learnedWords,
    int? rememberedWords,
    int? todayLearned,
    int? todayQuizCorrect,
    int? learningMinutes,
    List<TopicLearningProgress>? topics,
  }) {
    return LearningOverview(
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      nextLevelXP: nextLevelXP ?? this.nextLevelXP,
      totalWords: totalWords ?? this.totalWords,
      learnedWords: learnedWords ?? this.learnedWords,
      rememberedWords: rememberedWords ?? this.rememberedWords,
      todayLearned: todayLearned ?? this.todayLearned,
      todayQuizCorrect: todayQuizCorrect ?? this.todayQuizCorrect,
      learningMinutes: learningMinutes ?? this.learningMinutes,
      topics: topics ?? this.topics,
    );
  }

  double get totalPercent {
    if (totalWords == 0) return 0;
    return learnedWords / totalWords;
  }

  int get totalPercentText => (totalPercent * 100).round();
}

class TopicLearningProgress {
  final int topicId;
  final String title;
  final int total;
  final int learned;
  final int remembered;

  const TopicLearningProgress({
    required this.topicId,
    required this.title,
    required this.total,
    required this.learned,
    required this.remembered,
  });

  factory TopicLearningProgress.fromJson(Map<String, dynamic> json) {
    return TopicLearningProgress(
      topicId:
          int.tryParse((json['topic_id'] ?? json['id'] ?? '0').toString()) ?? 0,
      title: (json['title'] ?? '').toString(),
      total: int.tryParse((json['total'] ?? '0').toString()) ?? 0,
      learned: int.tryParse((json['learned'] ?? '0').toString()) ?? 0,
      remembered: int.tryParse((json['remembered'] ?? '0').toString()) ?? 0,
    );
  }

  double get percent {
    if (total == 0) return 0;
    return learned / total;
  }

  int get percentText => (percent * 100).round();

  int get notRememberedCount {
    final count = learned - remembered;
    return count < 0 ? 0 : count;
  }
}
