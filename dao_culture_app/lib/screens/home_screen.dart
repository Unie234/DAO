import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/streak_rescue_service.dart';
import '../widgets/ai_assistant.dart'; // 🟢 Gọi bé trợ lý ảo

// Import các trang của Uyên
import '../tabs/home_tab.dart';
import '../tabs/culture_tab.dart';
import '../screens/cultural_map_screen.dart';
import '../screens/community_screen.dart';
import '../screens/quiz_screen.dart';
import '../widgets/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. CÁC BIẾN QUẢN LÝ (GIỮ NGUYÊN)
  int _selectedIndex = 0;
  String _targetCategory = "Tất cả";
  String _targetCommunityPostId = "";
  late String _username;
  bool _isLoggedIn = false;
  String _streakCount = "0";
  String _avatarUrl = "";
  String _displayName = "Khách";
  bool _hasUnreadNotifications = false;
  bool _checkedStreakRescue = false;
  int _mapReloadVersion = 0;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _username = widget.username;
    _isLoggedIn = (_username.isNotEmpty && _username != "Khách");
    _displayName = _displayNameFromUsername(_username);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _loadProgress();
    _loadUserProfile();
    _loadUnreadNotifications();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // Các hàm xử lý logic của Uyên
  void _navigateToTab(int index, String category, {String? targetPostId}) {
    setState(() {
      if (index == 2) _mapReloadVersion++;
      _selectedIndex = index;
      _targetCategory = category;
      _targetCommunityPostId = index == 3 ? (targetPostId ?? "") : "";
    });
  }

  void _handleShowProgress() {
    setState(() {
      _selectedIndex = 4;
      _targetCategory = "Tất cả";
      _targetCommunityPostId = "";
    });
  }

  void _goToHomeTab() {
    if (!mounted) return;

    setState(() {
      _selectedIndex = 0;
      _targetCategory = "Tất cả";
      _targetCommunityPostId = "";
    });

    if (_isLoggedIn) {
      _loadUserProfile();
      _loadUnreadNotifications();
    }
  }

  String _displayNameFromUsername(String username) {
    if (username.isEmpty || username == "Khách") return "Khách";
    return username.split('@')[0];
  }

  Future<void> _loadProgress() async {
    if (!_isLoggedIn) {
      if (mounted) {
        setState(() => _streakCount = "0");
      }
      return;
    }

    final progress = await ApiService.getStreak(widget.username);
    if (mounted) {
      setState(() {
        _streakCount = progress;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    if (!_isLoggedIn) {
      if (mounted) {
        setState(() {
          _avatarUrl = "";
          _displayName = "Khách";
        });
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? "";
    if (userId.isEmpty) return;

    final result = await ApiService.getUserProfile(userId);
    if (!mounted) return;

    if (result['status'] == 'success') {
      final fullName = (result['full_name'] ?? "").toString().trim();
      final avatar = (result['avatar'] ?? "").toString().trim();
      setState(() {
        _avatarUrl = avatar.isEmpty ? "" : _withCacheVersion(avatar);
        _displayName = fullName.isNotEmpty
            ? fullName
            : _displayNameFromUsername(_username);
      });
      await prefs.setString('full_name', fullName);
      _checkStreakRescue(userId);
    }
  }

  String _withCacheVersion(String url) {
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _loadUnreadNotifications() async {
    if (!_isLoggedIn) {
      if (mounted) {
        setState(() => _hasUnreadNotifications = false);
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? "";

    if (userId.isEmpty) {
      if (mounted) {
        setState(() => _hasUnreadNotifications = false);
      }
      return;
    }

    final notifications = await ApiService.getNotifications(
      userId: userId,
      limit: 50,
    );

    if (!mounted) return;
    setState(() {
      _hasUnreadNotifications = notifications.any(
        (notification) => !notification.isRead,
      );
    });
  }

  Future<void> _checkStreakRescue(String userId) async {
    if (_checkedStreakRescue || userId.isEmpty) return;
    _checkedStreakRescue = true;

    final result = await StreakRescueService.check(userId);
    if (!mounted || result == null || result['eligible'] != true) return;

    final mission = result['mission'];
    if (mission is! Map) return;

    _showStreakRescueDialog(
      missionId: mission['id']?.toString() ?? "",
      requiredCorrect:
          int.tryParse((mission['required_correct'] ?? '4').toString()) ?? 4,
      requiredTotal:
          int.tryParse((mission['required_total'] ?? '5').toString()) ?? 5,
    );
  }

  void _showStreakRescueDialog({
    required String missionId,
    required int requiredCorrect,
    required int requiredTotal,
  }) {
    if (missionId.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Cứu chuỗi học tập",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Bạn đã bỏ lỡ 1 ngày. Hoàn thành quiz $requiredTotal câu và đúng ít nhất $requiredCorrect câu để giữ chuỗi học tập.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Để sau"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final rescued = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizScreen(
                    title: "Thử thách cứu chuỗi",
                    rescueMode: true,
                    rescueMissionId: missionId,
                    requiredCorrect: requiredCorrect,
                  ),
                ),
              );
              if (rescued == true) {
                _loadProgress();
              }
            },
            child: const Text("Cứu chuỗi"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 DANH SÁCH TABS (GIỮ NGUYÊN MỌI THAM SỐ TRUYỀN VÀO CỦA UYÊN)
    final List<Widget> tabs = [
      HomeTab(
        onNavigateToCulture: _navigateToTab,
        onShowLevelUp: (lvl) => {},
        onShowProgressDetails: _handleShowProgress,
        isLoggedIn: _isLoggedIn,
        streakCount: _streakCount,
        username: _displayName,
        avatarUrl: _avatarUrl,
        hasUnreadNotifications: _hasUnreadNotifications,
        onNotificationsChanged: _loadUnreadNotifications,
      ),
      CultureTab(initialCategory: _targetCategory),
      CulturalMapScreen(key: ValueKey(_mapReloadVersion)),
      CommunityScreen(
        onBackToHome: _goToHomeTab,
        initialPostId: _targetCommunityPostId,
      ),
      ProfileTab(
        onLogoutSuccess: () {
          if (mounted) {
            setState(() {
              _isLoggedIn = false;
              _username = "Khách";
              _displayName = "Khách";
              _streakCount = "0"; // Ép về 0 khi Logout
              _avatarUrl = "";
              _hasUnreadNotifications = false;
              _selectedIndex = 0;
              _targetCommunityPostId = "";
            });
          }
        },
        isLoggedIn: _isLoggedIn,
        username: _username,
      ),
    ];

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
          _goToHomeTab();
        }
      },
      child: Scaffold(
        extendBody: true,
        appBar: null,

        // 🟢 PHẦN CỐT LÕI: Stack để bé trợ lý nổi lên trên tất cả các trang con
        body: Stack(
          children: [
            // Lớp 1: Nội dung các trang
            IndexedStack(index: _selectedIndex, children: tabs),

            // Lớp 2: Hiệu ứng pháo hoa (Nằm trên nội dung trang)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
              ),
            ),

            // Lớp 3: Bé Trợ lý ảo AI hiện ở tất cả trang
            const DraggableAiAssistant(),
          ],
        ),

        // THANH ĐIỀU HƯỚNG DƯỚI ĐÁY (GIỮ NGUYÊN)
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: _buildBottomNavigationBar(),
          ),
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF1976D2),
      unselectedItemColor: Colors.grey.shade600,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (index) {
        setState(() {
          if (index == 2) _mapReloadVersion++;
          _selectedIndex = index;
          _targetCategory = "Tất cả";
          _targetCommunityPostId = "";
        });
        if (index == 0 && _isLoggedIn) {
          _loadUserProfile();
          _loadUnreadNotifications();
        }
      },
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Trang chủ',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_rounded),
          label: 'Khám phá',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          label: 'Bản đồ',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.people_alt_rounded),
          label: 'Cộng đồng',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Cá nhân',
        ),
      ],
    );
  }
}
