class AppConfig {
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const String serverUrl =
      'https://wired-doorframe-broiling.ngrok-free.dev';
  static const String baseUrl = '$serverUrl/api';
  static const String storageUrl = '$serverUrl/storage';

  static const String defaultUsername = 'Khách';
}
