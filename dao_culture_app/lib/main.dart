import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/admin_dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart'; // Gọi file WelcomeScreen chứa ảnh em bé của bạn

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Tắt chữ "DEBUG" ở góc phải màn hình
      title: 'Văn hóa dân tộc Dao',
      theme: ThemeData(
        // Dùng màu xanh chàm làm chủ đạo cho hợp với văn hóa Dao
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        useMaterial3: true,
      ),
      home: const SessionGate(),
    );
  }
}

class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  Future<Widget> _resolveStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id')?.trim() ?? '';
    final username = prefs.getString('username')?.trim() ?? '';
    final role = prefs.getString('role')?.trim().toLowerCase() ?? 'guest';

    if (userId.isEmpty || username.isEmpty || username == 'Khách') {
      return const WelcomeScreen();
    }

    if (role == 'admin') {
      return const AdminDashboardScreen();
    }

    return HomeScreen(username: username);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolveStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!;
        }

        return const Scaffold(
          backgroundColor: Color(0xFFFBF8F2),
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
