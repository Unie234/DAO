import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Vui lòng nhập email hợp lệ', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.requestPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _otpSent = result['status'] == 'success';
    });
    _showMessage(
      result['message'] ?? 'Không gửi được mã xác nhận',
      result['status'] == 'success' ? Colors.green : Colors.red,
    );
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final passwordRules = RegExp(r'^(?=.*[A-Z])(?=.*[!@#\$&*~]).{8,}$');

    if (otp.length != 6) {
      _showMessage('Mã xác nhận gồm 6 số', Colors.orange);
      return;
    }
    if (newPassword != confirmPassword) {
      _showMessage('Mật khẩu xác nhận chưa khớp', Colors.orange);
      return;
    }
    if (!passwordRules.hasMatch(newPassword)) {
      _showMessage(
        'Mật khẩu mới phải từ 8 ký tự, có chữ in hoa và ký tự đặc biệt',
        Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['status'] == 'success') {
      _showMessage(
        result['message'] ?? 'Đặt lại mật khẩu thành công',
        Colors.green,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      _showMessage(
        result['message'] ?? 'Không đặt lại được mật khẩu',
        Colors.red,
      );
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
              offset: const Offset(0, -10),
              child: Column(
                children: [
                  Image.asset(
                    'assets/hoa_tiet.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -18),
                    child: const Text(
                      'DAO\nCULTURE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        height: 0.88,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        letterSpacing: 1,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'QUÊN MẬT KHẨU',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          enabled: !_otpSent,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email tài khoản',
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: 15),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: 'Mã xác nhận',
                              prefixIcon: Icon(Icons.verified_user),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Mật khẩu mới',
                              prefixIcon: Icon(Icons.lock),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Nhập lại mật khẩu mới',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Color(0xFF1A237E),
                              )
                            : ElevatedButton(
                                onPressed: _otpSent ? _resetPassword : _sendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A237E),
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _otpSent
                                      ? 'ĐẶT LẠI MẬT KHẨU'
                                      : 'GỬI MÃ XÁC NHẬN',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                        if (_otpSent)
                          TextButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            child: const Text('Gửi lại mã'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
