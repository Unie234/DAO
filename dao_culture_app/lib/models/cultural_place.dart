import 'package:flutter/material.dart';

import 'dart:convert';

import '../app_config.dart';

enum CulturalPlaceType {
  all,
  festival,
  village,
  herb,
  tourism,
  communityHouse,
  homestay,
}

enum CulturalPlaceLayer { culture, service }

class CulturalPlace {
  final String name;
  final String address;
  final String distance;
  final String shortDescription;
  final String culturalDescription;
  final String daoInfo;
  final String tag;
  final CulturalPlaceType type;
  final CulturalPlaceLayer layer;
  final Offset mapPosition;
  final IconData icon;
  final Color color;
  final String imageAsset;
  final String imageUrl;
  final List<String> galleryAssets;
  final List<String> galleryUrls;
  final double latitude;
  final double longitude;
  final bool hasDirections;
  final String googleMapsUrl;

  const CulturalPlace({
    required this.name,
    required this.address,
    required this.distance,
    required this.shortDescription,
    required this.culturalDescription,
    required this.daoInfo,
    required this.tag,
    required this.type,
    this.layer = CulturalPlaceLayer.culture,
    required this.mapPosition,
    required this.icon,
    required this.color,
    this.imageAsset = '',
    this.imageUrl = '',
    this.galleryAssets = const [],
    this.galleryUrls = const [],
    required this.latitude,
    required this.longitude,
    this.hasDirections = false,
    this.googleMapsUrl = '',
  });

  factory CulturalPlace.fromJson(Map<String, dynamic> json) {
    final type = _typeFromString(json['type']?.toString());
    return CulturalPlace(
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      distance: json['distance']?.toString() ?? '',
      shortDescription: json['short_description']?.toString() ?? '',
      culturalDescription: json['cultural_description']?.toString() ?? '',
      daoInfo: json['dao_info']?.toString() ?? '',
      tag: json['tag']?.toString() ?? _labelForType(type),
      type: type,
      layer: _layerFromJson(json['layer_type']?.toString(), type),
      mapPosition: _mapPositionFromJson(json, type),
      icon: _iconForType(type),
      color: _colorForType(type),
      imageAsset: json['image_asset']?.toString() ?? '',
      imageUrl: _normalizeMapMediaUrl(json['image_url']?.toString() ?? ''),
      galleryAssets: _galleryFromJson(json['gallery_assets']),
      galleryUrls: _galleryFromJson(
        json['gallery_urls'],
      ).map(_normalizeMapMediaUrl).where((item) => item.isNotEmpty).toList(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      hasDirections: _toBool(json['has_directions']),
      googleMapsUrl: json['google_maps_url']?.toString() ?? '',
    );
  }
}

CulturalPlaceLayer _layerFromJson(String? value, CulturalPlaceType type) {
  switch (value?.trim().toLowerCase()) {
    case 'service':
    case 'experience':
    case 'dich_vu':
      return CulturalPlaceLayer.service;
    case 'culture':
    case 'community':
    case 'van_hoa':
      return CulturalPlaceLayer.culture;
  }

  switch (type) {
    case CulturalPlaceType.herb:
    case CulturalPlaceType.homestay:
      return CulturalPlaceLayer.service;
    case CulturalPlaceType.festival:
    case CulturalPlaceType.village:
    case CulturalPlaceType.tourism:
    case CulturalPlaceType.communityHouse:
    case CulturalPlaceType.all:
      return CulturalPlaceLayer.culture;
  }
}

CulturalPlaceType _typeFromString(String? value) {
  switch (value) {
    case 'festival':
      return CulturalPlaceType.festival;
    case 'village':
      return CulturalPlaceType.village;
    case 'herb':
      return CulturalPlaceType.herb;
    case 'tourism':
      return CulturalPlaceType.tourism;
    case 'community_house':
      return CulturalPlaceType.communityHouse;
    case 'homestay':
      return CulturalPlaceType.homestay;
    default:
      return CulturalPlaceType.village;
  }
}

String _labelForType(CulturalPlaceType type) {
  switch (type) {
    case CulturalPlaceType.festival:
      return "Lễ hội";
    case CulturalPlaceType.village:
      return "Làng văn hóa";
    case CulturalPlaceType.herb:
      return "Thảo dược";
    case CulturalPlaceType.tourism:
      return "Điểm du lịch";
    case CulturalPlaceType.communityHouse:
      return "Nhà cộng đồng";
    case CulturalPlaceType.homestay:
      return "Homestay";
    case CulturalPlaceType.all:
      return "Tất cả";
  }
}

Offset _mapPositionForType(CulturalPlaceType type) {
  switch (type) {
    case CulturalPlaceType.festival:
      return const Offset(0.38, 0.14);
    case CulturalPlaceType.village:
      return const Offset(0.29, 0.21);
    case CulturalPlaceType.herb:
      return const Offset(0.50, 0.39);
    case CulturalPlaceType.tourism:
      return const Offset(0.62, 0.25);
    case CulturalPlaceType.communityHouse:
      return const Offset(0.42, 0.30);
    case CulturalPlaceType.homestay:
      return const Offset(0.47, 0.48);
    case CulturalPlaceType.all:
      return const Offset(0.50, 0.50);
  }
}

Offset _mapPositionFromJson(Map<String, dynamic> json, CulturalPlaceType type) {
  final x = _toDouble(json['map_x']);
  final y = _toDouble(json['map_y']);
  if (x > 0 && y > 0) return Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
  return _mapPositionForType(type);
}

IconData _iconForType(CulturalPlaceType type) {
  switch (type) {
    case CulturalPlaceType.festival:
      return Icons.local_fire_department_rounded;
    case CulturalPlaceType.village:
      return Icons.home_work_rounded;
    case CulturalPlaceType.herb:
      return Icons.eco_rounded;
    case CulturalPlaceType.tourism:
      return Icons.photo_camera_rounded;
    case CulturalPlaceType.communityHouse:
      return Icons.groups_rounded;
    case CulturalPlaceType.homestay:
      return Icons.house_rounded;
    case CulturalPlaceType.all:
      return Icons.travel_explore_rounded;
  }
}

Color _colorForType(CulturalPlaceType type) {
  switch (type) {
    case CulturalPlaceType.festival:
      return const Color(0xFFD93829);
    case CulturalPlaceType.village:
      return const Color(0xFFE49B2D);
    case CulturalPlaceType.herb:
      return const Color(0xFF2F7D3C);
    case CulturalPlaceType.tourism:
      return const Color(0xFF397FA8);
    case CulturalPlaceType.communityHouse:
      return const Color(0xFF8B62C8);
    case CulturalPlaceType.homestay:
      return const Color(0xFFE5B21A);
    case CulturalPlaceType.all:
      return const Color(0xFFD93829);
  }
}

List<String> _galleryFromJson(dynamic value) {
  if (value is List) {
    final gallery = value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (gallery.isNotEmpty) return gallery;
  }
  if (value is String) {
    final text = value.trim();
    if (text.isEmpty) return const [];
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) return _galleryFromJson(decoded);
    } catch (_) {}
    final gallery = text
        .split(RegExp(r'[\n,;|]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (gallery.isNotEmpty) return gallery;
  }
  return const [];
}

String _normalizeMapMediaUrl(String value) {
  final text = value.trim();
  if (text.isEmpty) return '';
  final normalized = text.replaceAll('\\', '/');
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    final uri = Uri.tryParse(normalized);
    if (uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      final baseUri = Uri.parse(AppConfig.baseUrl);
      return baseUri.replace(path: uri.path, query: uri.query).toString();
    }
    return normalized;
  }

  final hostBase = AppConfig.baseUrl.replaceFirst(RegExp(r'/dao_api/?$'), '');
  if (normalized.startsWith('/dao_api/')) return '$hostBase$normalized';
  if (normalized.startsWith('dao_api/')) return '$hostBase/$normalized';
  if (normalized.startsWith('/uploads/') || normalized.startsWith('uploads/')) {
    final clean = normalized.replaceFirst(RegExp(r'^/+'), '');
    return '${AppConfig.baseUrl}/$clean';
  }
  if (normalized.startsWith('/map_places/') ||
      normalized.startsWith('map_places/')) {
    final clean = normalized.replaceFirst(RegExp(r'^/+'), '');
    return '${AppConfig.baseUrl}/$clean';
  }
  return normalized;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase().trim();
  return text == '1' || text == 'true' || text == 'yes';
}
