import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class GamificationAward {
  final int points;
  final int totalXP;
  final int level;
  final bool levelUp;
  final bool storedOnServer;
  final bool success;

  const GamificationAward({
    required this.points,
    required this.totalXP,
    required this.level,
    required this.levelUp,
    required this.storedOnServer,
    required this.success,
  });
}

class GamificationService {
  static const List<int> levelThresholds = [
    0,
    100,
    250,
    450,
    700,
    1000,
    1350,
    1750,
    2200,
    2700,
  ];

  static const List<String> levelTitles = [
    'Người bắt đầu hành trình',
    'Người gieo mầm tiếng Dao',
    'Người chăm học bản làng',
    'Người nhớ lời quê hương',
    'Người giữ nhịp học mỗi ngày',
    'Người khám phá văn hóa Dao',
    'Người nối lời truyền thống',
    'Người gìn giữ bản sắc',
    'Người truyền lửa tiếng Dao',
    'Đại sứ văn hóa Dao',
  ];

  static const List<String> journeyStages = [
    'Làm quen tiếng Dao',
    'Gia đình và đời sống',
    'Bản làng và thiên nhiên',
    'Lễ hội và phong tục',
    'Người gìn giữ bản sắc',
  ];

  static int levelForXP(int xp) {
    var level = 1;
    for (var i = 0; i < levelThresholds.length; i++) {
      if (xp >= levelThresholds[i]) {
        level = i + 1;
      }
    }
    return level;
  }

  static int nextLevelXP(int level) {
    if (level < levelThresholds.length) {
      return levelThresholds[level];
    }
    return levelThresholds.last;
  }

  static int currentLevelStartXP(int level) {
    final index = (level - 1).clamp(0, levelThresholds.length - 1);
    return levelThresholds[index];
  }

  static String titleForLevel(int level) {
    final index = (level - 1).clamp(0, levelTitles.length - 1);
    return levelTitles[index];
  }

  static String journeyStageForLevel(int level) {
    final stageIndex = ((level - 1) ~/ 2).clamp(0, journeyStages.length - 1);
    return journeyStages[stageIndex];
  }

  // 🔴 1. HÀM TÍNH CHUỖI NGÀY (LƯU TRÊN MÁY, 100% KHÔNG DÙNG FIREBASE)
  static Future<int> checkAndUpdateDailyStreak() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastLoginDate = prefs.getString('last_login_date');
    int currentStreak = prefs.getInt('current_streak') ?? 0;

    DateTime now = DateTime.now();
    String today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    if (lastLoginDate == today) {
      return currentStreak; // Hôm nay vào rồi thì giữ nguyên
    }

    if (lastLoginDate != null) {
      DateTime lastDate = DateTime.parse(lastLoginDate);
      int difference = DateTime(now.year, now.month, now.day)
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;

      if (difference == 1) {
        currentStreak += 1; // Đăng nhập liên tiếp
      } else if (difference > 1) {
        currentStreak = 1; // Bỏ lỡ ngày, quay về 1
      }
    } else {
      currentStreak = 1; // Lần đầu tải app
    }

    // Lưu lại trạng thái
    await prefs.setString('last_login_date', today);
    await prefs.setInt('current_streak', currentStreak);

    return currentStreak;
  }

  static Future<GamificationAward> awardXP(int pointsEarned) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id')?.trim() ?? '';
    final localXP = prefs.getInt('currentXP') ?? 0;
    final localLevel = prefs.getInt('currentLevel') ?? levelForXP(localXP);

    if (userId.isNotEmpty && pointsEarned > 0) {
      final result = await ApiService.addPointsResult(userId, pointsEarned);
      if (result['status'] == 'success') {
        final totalXP =
            int.tryParse(
              (result['total_xp'] ?? result['xp'] ?? localXP).toString(),
            ) ??
            localXP;
        final level =
            int.tryParse((result['level'] ?? levelForXP(totalXP)).toString()) ??
            levelForXP(totalXP);
        final levelUp = result['level_up'] == true || level > localLevel;

        await prefs.setInt('currentXP', totalXP);
        await prefs.setInt('currentLevel', level);

        return GamificationAward(
          points: pointsEarned,
          totalXP: totalXP,
          level: level,
          levelUp: levelUp,
          storedOnServer: true,
          success: true,
        );
      }
    }

    final newXP = localXP + pointsEarned;
    final newLevel = levelForXP(newXP);
    final isLevelUp = newLevel > localLevel;

    await prefs.setInt('currentXP', newXP);
    await prefs.setInt('currentLevel', newLevel);

    return GamificationAward(
      points: pointsEarned,
      totalXP: newXP,
      level: newLevel,
      levelUp: isLevelUp,
      storedOnServer: false,
      success: true,
    );
  }

  // Ham cu de cac man hinh khac van dung duoc.
  static Future<bool> addXP(int pointsEarned) async {
    final award = await awardXP(pointsEarned);
    return award.levelUp;
  }
}
