import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CultureSources {
  final List<String> content;
  final List<String> image;
  final List<String> video;

  const CultureSources({
    this.content = const [],
    this.image = const [],
    this.video = const [],
  });

  bool get isEmpty => content.isEmpty && image.isEmpty && video.isEmpty;
  int get total => content.length + image.length + video.length;

  static CultureSources fromDetail(Map<String, dynamic> detail) {
    final raw = detail['sources'];
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return CultureSources(
        content: _toLines(map['content']),
        image: _toLines(map['image']),
        video: _toLines(map['video']),
      );
    }

    return CultureSources(
      content: _toLines(detail['content_sources'] ?? detail['content_source']),
      image: _toLines(detail['image_sources'] ?? detail['image_source']),
      video: _toLines(detail['video_sources'] ?? detail['video_source']),
    );
  }

  static List<String> _toLines(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    final text = (value ?? '').toString().trim();
    if (text.isEmpty) return const [];
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}

class CultureSourcesCard extends StatelessWidget {
  final CultureSources sources;
  final Color accentColor;

  const CultureSourcesCard({
    super.key,
    required this.sources,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: accentColor, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Tư liệu tham khảo",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: () => _showSources(context),
                child: Text(
                  "Xem chi tiết",
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (sources.content.isNotEmpty)
                _SourceChip("Nội dung", sources.content.length, accentColor),
              if (sources.image.isNotEmpty)
                _SourceChip("Hình ảnh", sources.image.length, accentColor),
              if (sources.video.isNotEmpty)
                _SourceChip("Video", sources.video.length, accentColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Nội dung được biên soạn nhằm hỗ trợ học tập và góp phần gìn giữ văn hóa Dao.",
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.35,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showSources(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Tư liệu tham khảo",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              _SourceSection("Nguồn nội dung", sources.content, accentColor),
              _SourceSection("Nguồn hình ảnh", sources.image, accentColor),
              _SourceSection("Nguồn video", sources.video, accentColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SourceChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        "$label · $count nguồn",
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SourceSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;

  const _SourceSection(this.title, this.items, this.color);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...items.indexed.map((entry) {
            final item = entry.$2;
            final uri = _extractUri(item);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: uri == null ? null : () => _openUri(context, uri),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${entry.$1 + 1}.",
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: uri == null ? Colors.black : color,
                            decoration: uri == null
                                ? TextDecoration.none
                                : TextDecoration.underline,
                            decorationColor: color.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      if (uri != null) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.open_in_new_rounded, color: color, size: 16),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Uri? _extractUri(String text) {
    final match = RegExp(r'https?://[^\s,)>\]]+').firstMatch(text);
    if (match == null) return null;
    var url = match.group(0) ?? '';
    url = url.replaceAll(RegExp(r'[.,;:]+$'), '');
    return Uri.tryParse(url);
  }

  Future<void> _openUri(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Không mở được đường dẫn nguồn.")),
    );
  }
}
