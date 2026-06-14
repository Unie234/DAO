import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Dùng để lưu ID

import '../services/api_service.dart';
import 'admin_dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'welcome_screen.dart';
import 'home_screen.dart'; // Nhớ import màn hình chính của bạn

class LoginScreen extends StatefulWidget {
  final bool isFromWelcome;

  const LoginScreen({super.key, this.isFromWelcome = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // ==========================================
  // HÀM ĐĂNG NHẬP ĐỒNG BỘ VỚI LOGIC ĐĂNG KÝ
  // ==========================================
  Future<void> _signIn() async {
    String username = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // 1. Kiểm tra không được để trống
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng điền đầy đủ Tên đăng nhập và Mật khẩu!"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Gọi hàm Login từ ApiService
      // 🟢 CÁI HỘP TÊN LÀ "result" NHÉ
      final result = await ApiService.login(username, password);

      if (!mounted) return;

      if (result['status'] == 'success') {
        // 3. LƯU DỮ LIỆU ĐỂ GÓC SẺ CHIA VÀ CHUỖI NGÀY NHẬN DIỆN
        // 🟢 SỬA TẠI LOGIN_SCREEN:
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final role = (result['role'] ?? 'user').toString().toLowerCase();

        await prefs.setString('user_id', result['user_id'].toString());
        await prefs.setString('username', result['username'].toString());
        await prefs.setString('full_name', (result['full_name'] ?? '').toString());
        await prefs.setString('role', role);

        // Cất số 2 vào ngăn tủ mang tên _streakCount
        await prefs.setInt(
          '_streakCount',
          int.tryParse(result['streak_count'].toString()) ?? 0,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đăng nhập thành công! 🎉"),
            backgroundColor: Colors.green,
          ),
        );

        // 4. Chuyển vào ứng dụng theo quyền
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => role == 'admin'
                ? const AdminDashboardScreen()
                : HomeScreen(username: result['username'].toString()),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Đăng nhập thất bại!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi kết nối máy chủ: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // PHẦN GIAO DIỆN UI (CHÉP Y XÌ TỪ ĐĂNG KÝ)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/auth_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                const SizedBox(height: 0),

                // LOGO VÀ TIÊU ĐỀ
                SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/hoa_tiet.png',
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 0),
                        Padding(
                          padding: const EdgeInsets.only(left: 0, right: 0),
                          child: Transform.translate(
                            offset: const Offset(0, -15),
                            child: const Text(
                              "DAO\nCULTURE",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 45,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'serif',
                                color: Color(0xFF111827),
                                height: 0.9,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // KHUNG FORM ĐĂNG NHẬP
                Container(
                  constraints: const BoxConstraints(minHeight: 390),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "ĐĂNG NHẬP",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Tên đăng nhập (Email)",
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: "Mật khẩu",
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Quên mật khẩu?",
                            style: TextStyle(
                              color: Color(0xFF1A237E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1A237E),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A237E),
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "VÀO ỨNG DỤNG",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Chưa có tài khoản? Đăng ký ngay",
                          style: TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
