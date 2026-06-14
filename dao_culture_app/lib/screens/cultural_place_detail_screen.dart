import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/cultural_place.dart';

class CulturalPlaceDetailScreen extends StatelessWidget {
  final CulturalPlace place;

  const CulturalPlaceDetailScreen({super.key, required this.place});

  static const Color _ink = Color(0xFF102321);
  static const Color _red = Color(0xFFD93829);
  static const Color _paper = Color(0xFFFFFBF5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildCover(context)),
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0, -10, 0),
                  padding: const EdgeInsets.fromLTRB(22, 36, 22, 118),
                  decoration: const BoxDecoration(
                    color: _paper,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              place.name,
                              style: const TextStyle(
                                color: Color(0xFFC9271D),
                                fontSize: 28,
                                height: 1.12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            place.distance,
                            style: const TextStyle(
                              color: _red,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            color: Color(0xFF7C4B3B),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              place.address,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle("Giới thiệu"),
                      const SizedBox(height: 8),
                      Text(
                        place.culturalDescription,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 15,
                          height: 1.48,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle("Thông tin văn hóa Dao"),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EAE0),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: place.color.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(place.icon, color: place.color),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Text(
                                place.daoInfo,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 14,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _buildSectionTitle("Hình ảnh"),
                      const SizedBox(height: 12),
                      _buildGallery(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    final galleryImages = _galleryImages(place);
    final galleryCount = galleryImages.isEmpty ? 1 : galleryImages.length;
    final coverImage = _coverImage(place);

    return SizedBox(
      height: 330,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: galleryImages.isEmpty
                ? null
                : () => _openImageViewer(context, place, galleryImages, 0),
            child: _PlaceDetailImage(
              place: place,
              imageUrl: coverImage?.isNetwork == true
                  ? coverImage?.value
                  : null,
              imageAsset: coverImage?.isNetwork == false
                  ? coverImage?.value
                  : null,
              radius: 0,
              fit: BoxFit.cover,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.34),
                  Colors.black.withValues(alpha: 0.04),
                  Colors.black.withValues(alpha: 0.34),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 10,
            child: _roundIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 10,
            child: _roundIconButton(
              icon: Icons.ios_share_rounded,
              onTap: () => SharePlus.instance.share(
                ShareParams(
                  text:
                      "Khám phá ${place.name} tại ${place.address}. ${place.shortDescription}",
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 42,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "1/$galleryCount",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.22),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _ink,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildGallery(BuildContext context) {
    final galleryImages = _galleryImages(place);

    if (galleryImages.isEmpty) {
      return SizedBox(
        height: 104,
        child: _PlaceDetailImage(
          place: place,
          width: 132,
          height: 104,
          radius: 14,
        ),
      );
    }

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: galleryImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final image = galleryImages[index];
          return GestureDetector(
            onTap: () => _openImageViewer(context, place, galleryImages, index),
            child: Stack(
              children: [
                _PlaceDetailImage(
                  place: place,
                  imageUrl: image.isNetwork ? image.value : null,
                  imageAsset: image.isNetwork ? null : image.value,
                  width: 132,
                  height: 104,
                  radius: 14,
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.44),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.zoom_out_map_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

void _openImageViewer(
  BuildContext context,
  CulturalPlace place,
  List<_PlaceImageRef> images,
  int initialIndex,
) {
  if (images.isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _PlaceImageViewer(
        place: place,
        images: images,
        initialIndex: initialIndex,
      ),
    ),
  );
}

_PlaceImageRef? _coverImage(CulturalPlace place) {
  final imageUrl = place.imageUrl.trim();
  if (imageUrl.isNotEmpty) return _PlaceImageRef(imageUrl, true);

  final galleryUrl = place.galleryUrls
      .map((item) => item.trim())
      .firstWhere((item) => item.isNotEmpty, orElse: () => '');
  if (galleryUrl.isNotEmpty) return _PlaceImageRef(galleryUrl, true);

  final imageAsset = place.imageAsset.trim();
  if (imageAsset.isNotEmpty) return _PlaceImageRef(imageAsset, false);

  final galleryAsset = place.galleryAssets
      .map((item) => item.trim())
      .firstWhere((item) => item.isNotEmpty, orElse: () => '');
  if (galleryAsset.isNotEmpty) return _PlaceImageRef(galleryAsset, false);

  return null;
}

List<_PlaceImageRef> _galleryImages(CulturalPlace place) {
  final images = <_PlaceImageRef>[];
  final seen = <String>{};

  void addImage(String value, bool isNetwork) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final key = "${isNetwork ? 'url' : 'asset'}:$trimmed";
    if (!seen.add(key)) return;
    images.add(_PlaceImageRef(trimmed, isNetwork));
  }

  addImage(place.imageUrl, true);
  for (final item in place.galleryUrls) {
    addImage(item, true);
  }
  addImage(place.imageAsset, false);
  for (final item in place.galleryAssets) {
    addImage(item, false);
  }

  return images;
}

class _PlaceImageRef {
  final String value;
  final bool isNetwork;

  const _PlaceImageRef(this.value, this.isNetwork);
}

class _PlaceImageViewer extends StatefulWidget {
  final CulturalPlace place;
  final List<_PlaceImageRef> images;
  final int initialIndex;

  const _PlaceImageViewer({
    required this.place,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_PlaceImageViewer> createState() => _PlaceImageViewerState();
}

class _PlaceImageViewerState extends State<_PlaceImageViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final image = widget.images[index];
                return Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: _PlaceDetailImage(
                      place: widget.place,
                      imageUrl: image.isNetwork ? image.value : null,
                      imageAsset: image.isNetwork ? null : image.value,
                      radius: 0,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: 16,
              top: 12,
              child: _viewerButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              right: 16,
              top: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  "${_index + 1}/${widget.images.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewerButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white, size: 25),
        ),
      ),
    );
  }
}

class _PlaceDetailImage extends StatelessWidget {
  final CulturalPlace place;
  final String? imageUrl;
  final String? imageAsset;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  const _PlaceDetailImage({
    required this.place,
    this.imageUrl,
    this.imageAsset,
    this.width,
    this.height,
    required this.radius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl ?? place.imageUrl).trim();
    final asset = (imageAsset ?? place.imageAsset).trim();
    final child = url.isNotEmpty
        ? Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildDefault(),
          )
        : asset.isNotEmpty
        ? Image.asset(
            asset,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildDefault(),
          )
        : _buildDefault();

    if (radius <= 0) return child;
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }

  Widget _buildDefault() {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: place.color.withValues(alpha: 0.16),
        borderRadius: radius <= 0 ? null : BorderRadius.circular(radius),
      ),
      child: Icon(place.icon, color: place.color, size: (height ?? 120) * 0.34),
    );
  }
}
