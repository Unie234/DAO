import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<SharedPreferences> _prefs() {
    return SharedPreferences.getInstance();
  }

  static String _clean(String? value) {
    return (value ?? '').trim();
  }

  static Future<bool> isGuest() async {
    final prefs = await _prefs();
    final userId = _clean(prefs.getString('user_id'));
    final username = _clean(prefs.getString('username'));
    return userId.isEmpty || username.isEmpty || username == 'Khách';
  }

  static Future<String?> currentUserId() async {
    final prefs = await _prefs();
    final userId = _clean(prefs.getString('user_id'));
    return userId.isEmpty ? null : userId;
  }

  static Future<String> currentRole() async {
    final prefs = await _prefs();
    final userId = _clean(prefs.getString('user_id'));
    final username = _clean(prefs.getString('username'));
    if (userId.isEmpty || username.isEmpty || username == 'Khách') {
      return 'guest';
    }

    final role = _clean(prefs.getString('role')).toLowerCase();
    return role == 'admin' ? 'admin' : 'user';
  }

  static Future<bool> isAdmin() async {
    final userId = await currentUserId();
    return userId != null && await currentRole() == 'admin';
  }

  static Future<bool> isUser() async {
    return await currentRole() == 'user';
  }

  static Future<bool> canCreateCommunityPost() async {
    return await currentUserId() != null && await currentRole() != 'guest';
  }

  static Future<void> clearSession() async {
    final prefs = await _prefs();
    await prefs.clear();
  }
}
