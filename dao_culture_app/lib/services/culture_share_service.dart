import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../app_config.dart';

class CultureShareService {
  static String normalizeImageUrl(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return raw;

    final uri = Uri.tryParse(raw);
    if (uri == null) return raw;

    final isCultureImage =
        uri.path.contains('/uploads/culture/') ||
        uri.path.endsWith('/culture_articles/image.php');
    if (isCultureImage) {
      final fileName =
          uri.queryParameters['file'] ??
          (uri.pathSegments.isEmpty ? '' : uri.pathSegments.last);
      if (fileName.isNotEmpty) {
        return Uri.parse(
          '${AppConfig.baseUrl}/culture_articles/image.php',
        ).replace(queryParameters: {'file': fileName}).toString();
      }
    }

    if (!raw.startsWith('http')) return raw;

    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      final server = Uri.parse(AppConfig.serverUrl);
      return uri
          .replace(
            scheme: server.scheme,
            host: server.host,
            port: server.hasPort ? server.port : null,
          )
          .toString();
    }

    return raw;
  }

  static Future<void> shareArticle({
    required String title,
    required String category,
    required String imageUrl,
    required String text,
  }) async {
    final articleLink = Uri.parse(
      '${AppConfig.baseUrl}/culture_articles/share.php',
    ).replace(queryParameters: {'title': title}).toString();
    final shareText = '$text\n\nXem bài viết: $articleLink';
    final normalizedImage = normalizeImageUrl(imageUrl);

    if (normalizedImage.startsWith('http')) {
      try {
        final response = await http
            .get(Uri.parse(normalizedImage))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final contentType =
              response.headers['content-type']?.split(';').first ??
              'image/jpeg';
          final extension = switch (contentType) {
            'image/png' => 'png',
            'image/webp' => 'webp',
            _ => 'jpg',
          };
          await SharePlus.instance.share(
            ShareParams(
              title: title,
              subject: '$title - $category',
              text: shareText,
              files: [
                XFile.fromData(
                  response.bodyBytes,
                  mimeType: contentType,
                  name: 'bai-viet-van-hoa.$extension',
                ),
              ],
              fileNameOverrides: ['bai-viet-van-hoa.$extension'],
            ),
          );
          return;
        }
      } catch (_) {
        // Vẫn chia sẻ được nội dung và link nếu ảnh không tải được.
      }
    }

    await SharePlus.instance.share(
      ShareParams(title: title, subject: '$title - $category', text: shareText),
    );
  }
}
