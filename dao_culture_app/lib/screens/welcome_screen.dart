import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/welcome_bg.png'),
            fit: BoxFit.cover,
            alignment: Alignment(0.0, -0.30),
          ),
        ),
        child: SafeArea(
          child: Column(
            // 🟢 ĐÃ SỬA: Đưa toàn bộ nội dung vào giữa
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🟢 ĐÃ SỬA: Dùng Spacer(flex: 2) ở trên và Spacer(flex: 3) ở dưới
              // giúp toàn bộ nội dung nằm ở giữa nhưng được "xịt" lên trên một xíu
              const Spacer(flex: 2),

              Transform.translate(
                offset: const Offset(0, -45),
                child: Column(
                  children: [
                    // ẢNH THỨ 3 NẰM TRÊN CHỮ DAO CULTURE
                    Image.asset(
                      'assets/hoa_tiet.png',
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 0),

                    Transform.translate(
                      offset: const Offset(0, -10),
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
                    const SizedBox(height: 15),

                    const Text(
                      "Chào mừng bạn đến với:\n Bản sắc văn hóa dân tộc Dao",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'sans-serif',
                        color: Color.fromARGB(255, 51, 77, 85),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 20), // Khoảng cách từ chữ xuống nút
                    // 2. KHU VỰC CÁC NÚT BẤM
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // NÚT 1: KHÁM PHÁ NGAY (Dành cho Khách)
                          SizedBox(
                            width: 200,
                            child: ElevatedButton(
                              onPressed: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final savedUserId =
                                    prefs.getString('user_id')?.trim() ?? '';
                                final savedUsername =
                                    prefs.getString('username')?.trim() ?? '';
                                final username =
                                    savedUserId.isNotEmpty &&
                                        savedUsername.isNotEmpty &&
                                        savedUsername != 'Khách'
                                    ? savedUsername
                                    : 'Khách';
                                if (!context.mounted) return;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        HomeScreen(username: username),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF1A237E,
                                ), // Nền xanh chàm
                                foregroundColor: Colors.white, // Chữ trắng
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(55),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                "KHÁM PHÁ NGAY",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // DÒNG DƯỚI CÙNG: ĐĂNG KÝ
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Chưa có tài khoản? ",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 4, 85, 41),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LoginScreen(
                                          isFromWelcome: true,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Đăng nhập",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFB71C1C),
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(
                flex: 15,
              ), // 🟢 Lực đẩy từ dưới lên nhiều hơn, giúp nội dung xịt lên trên
            ],
          ),
        ),
      ),
    );
  }
}
