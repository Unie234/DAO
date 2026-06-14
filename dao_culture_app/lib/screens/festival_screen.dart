import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';
import '../services/culture_article_service.dart';
import '../services/culture_share_service.dart';
import '../utils/vietnamese_search.dart';
import '../widgets/culture_sources_card.dart';
import 'culture_detail_screen.dart';

class FestivalScreen extends StatefulWidget {
  final String? initialDetailTitle;

  const FestivalScreen({super.key, this.initialDetailTitle});

  @override
  State<FestivalScreen> createState() => _FestivalScreenState();
}

class _FestivalScreenState extends State<FestivalScreen> {
  static const Color _ink = Color(0xFF171B1F);
  static const Color _paper = Color(0xFFFBF8F2);
  static const Color _red = Color(0xFFD52B24);
  static const Color _green = Color(0xFF2F7D3C);
  static const Color _gold = Color(0xFFE49B2D);

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "Tất cả";
  String _query = "";
  bool _showSearch = false;
  List<_FestivalItem> _items = _fallbackItems;
  List<_FestivalItem>? _searchResults;
  Timer? _searchDebounce;
  int _searchRequestId = 0;
  bool _openedInitialDetail = false;

  static const List<String> _categories = ["Tất cả", "Mùa xuân", "Nghi lễ"];

  static const List<_FestivalItem> _fallbackItems = [
    _FestivalItem(
      title: "Tết Nhảy",
      subtitle: "Lễ hội đầu năm đặc sắc của người Dao Đỏ.",
      location: "Lào Cai",
      category: "Mùa xuân",
      season: "Mùng 1 - Mùng 3 Tết",
      image: "assets/banner_main.png",
      gallery: [
        "assets/banner_main.png",
        "assets/khampha1.png",
        "assets/khampha2.png",
        "assets/khampha3.png",
      ],
      hasVideo: true,
      videoTitle: "Tái hiện Tết Nhảy người Dao",
      description:
          "Tết Nhảy là một trong những lễ hội quan trọng nhất của người Dao Đỏ. Lễ hội diễn ra vào dịp đầu năm mới với ý nghĩa cầu may mắn, sức khỏe, mùa màng bội thu và xua đuổi tà ma, điều không may.",
      meanings: [
        _FestivalMeaning(
          title: "Bảo tồn truyền thống",
          text: "Giữ gìn bản sắc văn hóa độc đáo của người Dao.",
          icon: Icons.groups_rounded,
          color: _red,
        ),
        _FestivalMeaning(
          title: "Gắn kết cộng đồng",
          text: "Tăng cường tinh thần đoàn kết, tương thân tương ái.",
          icon: Icons.diversity_3_rounded,
          color: _green,
        ),
        _FestivalMeaning(
          title: "Cầu mùa bội thu",
          text: "Cầu mong mùa màng tốt tươi, cuộc sống ấm no.",
          icon: Icons.grass_rounded,
          color: _gold,
        ),
      ],
      steps: [
        "Chuẩn bị lễ vật",
        "Nghi thức cúng tổ tiên",
        "Điệu nhảy truyền thống",
        "Giao lưu cộng đồng",
        "Tiệc lễ hội",
      ],
    ),
    _FestivalItem(
      title: "Lễ Cầu Mùa",
      subtitle: "Cầu mong mùa màng bội thu, cuộc sống ấm no, hạnh phúc.",
      location: "Hà Giang",
      category: "Nghi lễ",
      season: "Đầu vụ mùa",
      image: "assets/khampha1.png",
      gallery: [
        "assets/khampha1.png",
        "assets/banner_main.png",
        "assets/ao.png",
      ],
      description:
          "Lễ Cầu Mùa là nghi lễ thể hiện niềm tin của cộng đồng vào thiên nhiên, tổ tiên và sự che chở của thần linh trong đời sống sản xuất.",
    ),
    _FestivalItem(
      title: "Lễ Cúng Rừng",
      subtitle: "Nghi lễ tôn thờ thần rừng, bảo vệ thiên nhiên và bản làng.",
      location: "Cao Bằng",
      category: "Nghi lễ",
      season: "Đầu năm",
      image: "assets/khampha2.png",
      gallery: [
        "assets/khampha2.png",
        "assets/khampha1.png",
        "assets/banner_main.png",
      ],
      description:
          "Lễ Cúng Rừng nhắc nhở cộng đồng sống hài hòa với thiên nhiên, biết ơn rừng và giữ gìn nguồn sống của bản làng.",
    ),
    _FestivalItem(
      title: "Lễ Hội Xuân",
      subtitle: "Ngày hội vui xuân, giao lưu văn hóa và gắn kết cộng đồng.",
      location: "Tuyên Quang",
      category: "Mùa xuân",
      season: "Mùa xuân",
      image: "assets/khampha3.png",
      gallery: [
        "assets/khampha3.png",
        "assets/banner_main.png",
        "assets/ao.png",
      ],
      description:
          "Lễ Hội Xuân là dịp cộng đồng gặp gỡ, chúc phúc, trình diễn trang phục, làn điệu dân gian và các trò chơi truyền thống.",
    ),
    _FestivalItem(
      title: "Các lễ hội khác",
      subtitle: "Những lễ hội truyền thống đặc sắc khác của người Dao.",
      location: "Nhiều địa điểm",
      category: "Nghi lễ",
      season: "Theo từng địa phương",
      image: "assets/ao.png",
      gallery: ["assets/ao.png", "assets/khampha1.png", "assets/khampha3.png"],
      description:
          "Mỗi nhóm Dao và mỗi địa phương có cách tổ chức lễ hội riêng, tạo nên sự phong phú trong đời sống văn hóa cộng đồng.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminFestivals();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialDetailIfNeeded();
    });
  }

  Future<void> _loadAdminFestivals() async {
    final rows = await _fetchCultureArticles(category: "Lễ hội");
    if (!mounted || rows.isEmpty) return;

    final parsed = rows
        .whereType<Map>()
        .map((row) => _FestivalItem.fromAdmin(Map<String, dynamic>.from(row)))
        .whereType<_FestivalItem>()
        .toList();

    if (parsed.isEmpty) return;
    setState(() => _items = parsed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialDetailIfNeeded();
    });
  }

  void _openInitialDetailIfNeeded() {
    if (!mounted || _openedInitialDetail) return;
    final detailTitle = widget.initialDetailTitle?.trim();
    if (detailTitle == null || detailTitle.isEmpty) return;

    for (final item in _items) {
      if (item.title.toLowerCase() == detailTitle.toLowerCase()) {
        _openedInitialDetail = true;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                _FestivalDetailScreen(item: item, relatedItems: _items),
          ),
        );
        return;
      }
    }
  }

  Future<List<dynamic>> _fetchCultureArticles({
    required String category,
  }) async {
    try {
      final encodedCategory = Uri.encodeComponent(category);
      final response = await http
          .get(
            Uri.parse(
              '${AppConfig.baseUrl}/culture_articles/list.php?category=$encodedCategory',
            ),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final decoded = jsonDecode(response.body);
      return decoded is List ? decoded : [];
    } catch (_) {
      return [];
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<_FestivalItem> get _filteredItems {
    final source = _query.trim().isEmpty
        ? _items
        : (_searchResults ?? const <_FestivalItem>[]);
    return source.where((item) {
      final matchesCategory =
          _selectedCategory == "Tất cả" || item.category == _selectedCategory;
      return matchesCategory;
    }).toList();
  }

  void _onSearchChanged(String value) {
    final requestId = ++_searchRequestId;
    setState(() {
      _query = value;
      _searchResults = null;
    });
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) return;

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final rows = await CultureArticleService.searchArticles(
        value,
        category: 'Lễ hội',
        limit: 30,
      );
      if (!mounted || requestId != _searchRequestId) return;
      final parsed = rows
          .whereType<Map>()
          .map((row) => _FestivalItem.fromAdmin(Map<String, dynamic>.from(row)))
          .whereType<_FestivalItem>()
          .toList();
      setState(() => _searchResults = parsed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                child: Column(
                  children: [
                    _buildHero(),
                    if (_showSearch) ...[
                      const SizedBox(height: 14),
                      _buildSearch(),
                    ],
                    const SizedBox(height: 18),
                    _buildCategories(),
                    const SizedBox(height: 18),
                    ..._filteredItems.map(_buildFestivalCard),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: _ink),
            ),
          ),
          const Text(
            "Lễ hội Dao",
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Positioned(
            right: 8,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchController.clear();
                    _query = "";
                  }
                });
              },
              icon: Icon(
                _showSearch ? Icons.close_rounded : Icons.search_rounded,
                color: _ink,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              "assets/banner_main.png",
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.70),
                    Colors.black.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Lễ hội Dao",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      fontFamily: "serif",
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Khám phá các lễ hội truyền thống\ncủa người Dao Việt Nam",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(22),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: "Tìm lễ hội...",
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF8C8177),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Color(0xFFE8DED4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Color(0xFFE8DED4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: _red, width: 1.3),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category == _selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = category),
            showCheckmark: false,
            selectedColor: _red,
            backgroundColor: Colors.white,
            side: BorderSide(color: selected ? _red : const Color(0xFFE5DAD0)),
            labelStyle: TextStyle(
              color: selected ? Colors.white : _ink,
              fontWeight: FontWeight.w800,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFestivalCard(_FestivalItem item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              _FestivalDetailScreen(item: item, relatedItems: _items),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDE4DA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: _FestivalThumb(item: item),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        fontFamily: "serif",
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 13,
                        height: 1.32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: _red,
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right_rounded, color: _ink, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class _FestivalDetailScreen extends StatelessWidget {
  final _FestivalItem item;
  final List<_FestivalItem> relatedItems;

  const _FestivalDetailScreen({required this.item, required this.relatedItems});

  static const Color _ink = _FestivalScreenState._ink;
  static const Color _paper = _FestivalScreenState._paper;
  static const Color _red = _FestivalScreenState._red;
  static const Color _green = _FestivalScreenState._green;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildMedia(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(),
                    const SizedBox(height: 16),
                    _buildMeta(),
                    const SizedBox(height: 22),
                    _SectionTitle("Giới thiệu"),
                    const SizedBox(height: 8),
                    _BodyText(item.description),
                    if (_meaningItems.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionTitle("Ý nghĩa văn hóa"),
                      const SizedBox(height: 12),
                      _buildMeanings(),
                    ],
                    if (item.steps.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionTitle("Các hoạt động chính"),
                      const SizedBox(height: 14),
                      _buildSteps(),
                    ],
                    if (item.gallery.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const _SectionTitle("Thư viện ảnh"),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildGallery(),
                    ],
                    const SizedBox(height: 24),
                    if (item.hasVideo) ...[
                      _SectionTitle("Video lễ hội"),
                      const SizedBox(height: 12),
                      _buildVideoCard(context),
                      const SizedBox(height: 20),
                    ],
                    if (!item.sources.isEmpty) ...[
                      CultureSourcesCard(
                        sources: item.sources,
                        accentColor: _red,
                      ),
                      const SizedBox(height: 20),
                    ],
                    _buildRelated(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          decoration: BoxDecoration(
            color: _paper,
            border: Border(
              top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
            ),
          ),
          child: _buildBottomActions(context),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: _ink),
            ),
          ),
          Positioned(
            left: 64,
            right: 104,
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            right: 52,
            child: IconButton(
              onPressed: () => _showSaved(context),
              icon: const Icon(Icons.bookmark_border_rounded, color: _ink),
            ),
          ),
          Positioned(
            right: 14,
            child: IconButton(
              onPressed: () => _shareFestival(),
              icon: const Icon(Icons.share_outlined, color: _ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    return SizedBox(
      height: 314,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _festivalMediaImage(
            item.image,
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 22,
              decoration: const BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: const TextStyle(
            color: _ink,
            fontSize: 26,
            height: 1.12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item.subtitle,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 14,
            height: 1.42,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMeta() {
    return Column(
      children: [
        _MetaChip(Icons.location_on_outlined, item.location),
        const SizedBox(height: 8),
        _MetaChip(Icons.calendar_month_rounded, item.season),
        const SizedBox(height: 8),
        _MetaChip(Icons.sell_outlined, item.category),
      ],
    );
  }

  Widget _buildMeanings() {
    final meanings = _meaningItems;
    return Column(
      children: meanings
          .map(
            (meaning) => Padding(
              padding: EdgeInsets.only(
                bottom: meaning == meanings.last ? 0 : 10,
              ),
              child: _MeaningCard(meaning: meaning),
            ),
          )
          .toList(),
    );
  }

  List<_FestivalMeaning> get _meaningItems {
    if (item.meanings.isNotEmpty) return item.meanings;
    if (item.isFromAdmin) return const [];
    return const [
      _FestivalMeaning(
        title: "Gắn kết",
        text: "Kết nối gia đình, dòng họ và cộng đồng.",
        icon: Icons.groups_rounded,
        color: _red,
      ),
      _FestivalMeaning(
        title: "Tâm linh",
        text: "Thể hiện lòng biết ơn với tổ tiên.",
        icon: Icons.spa_rounded,
        color: _green,
      ),
      _FestivalMeaning(
        title: "Bản sắc",
        text: "Giữ gìn trang phục, lời hát và nghi lễ.",
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFFE49B2D),
      ),
    ];
  }

  Widget _buildSteps() {
    final showNumbers = item.steps.length > 1;
    return Column(
      children: [
        ...List.generate(item.steps.length, (index) {
          final step = item.steps[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showNumbers) ...[
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    step,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGallery() {
    return SizedBox(
      height: 66,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: item.gallery.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onTap: () => _openGallery(context, index),
              child: _festivalMediaImage(
                item.gallery[index],
                width: 88,
                height: 66,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context) {
    return GestureDetector(
      onTap: item.videoUrl.isEmpty ? null : () => _openVideo(context),
      child: Container(
        height: 174,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDE4DA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    _festivalMediaImage(item.image, fit: BoxFit.cover),
                    Container(color: Colors.black.withValues(alpha: 0.12)),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.48),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.6),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.videoTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _ink),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openVideo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CultureDetailScreen(
          title: item.videoTitle,
          type: "video",
          mediaUrl: item.videoUrl,
          content: item.description,
        ),
      ),
    );
  }

  void _openGallery(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (_) {
        final controller = PageController(initialPage: initialIndex);
        var currentIndex = initialIndex;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void goTo(int index) {
              if (index < 0 || index >= item.gallery.length) return;
              controller.animateToPage(
                index,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
              );
              setDialogState(() => currentIndex = index);
            }

            return Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: controller,
                    itemCount: item.gallery.length,
                    onPageChanged: (index) =>
                        setDialogState(() => currentIndex = index),
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4,
                        child: Center(
                          child: _festivalMediaImage(
                            item.gallery[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                  if (currentIndex > 0)
                    Positioned(
                      left: 18,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _GalleryNavButton(
                          icon: Icons.chevron_left_rounded,
                          onPressed: () => goTo(currentIndex - 1),
                        ),
                      ),
                    ),
                  if (currentIndex < item.gallery.length - 1)
                    Positioned(
                      right: 18,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _GalleryNavButton(
                          icon: Icons.chevron_right_rounded,
                          onPressed: () => goTo(currentIndex + 1),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 24,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.58),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          "${currentIndex + 1}/${item.gallery.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: SafeArea(
                      child: IconButton.filled(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRelated(BuildContext context) {
    final related = relatedItems
        .where((festival) => festival.title != item.title)
        .toList();
    related.sort((a, b) {
      final aScore = vietnameseRelatedScore(
        [item.title, item.subtitle, item.description, item.category],
        [a.title, a.subtitle, a.description, a.category],
      );
      final bScore = vietnameseRelatedScore(
        [item.title, item.subtitle, item.description, item.category],
        [b.title, b.subtitle, b.description, b.category],
      );
      return bScore.compareTo(aScore);
    });
    final visibleRelated = related.take(3).toList();
    if (visibleRelated.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE4DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Lễ hội liên quan",
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...visibleRelated.map(
            (festival) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _festivalMediaImage(
                  festival.image,
                  width: 42,
                  height: 34,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                festival.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => _FestivalDetailScreen(
                    item: festival,
                    relatedItems: relatedItems,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          "Tìm hiểu lễ hội khác",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Future<void> _showSaved(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_culture_articles') ?? <String>[];
    final key = '${item.category}|${item.title}';
    if (!saved.contains(key)) {
      saved.add(key);
      await prefs.setStringList('saved_culture_articles', saved);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Đã lưu ${item.title}."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareFestival() async {
    final intro = _shareSnippet(item.description);
    final shareText = [
      "Bài viết trên App Văn hóa Dao",
      "",
      item.title,
      if (item.subtitle.trim().isNotEmpty) item.subtitle,
      "",
      "Danh mục: ${item.category}",
      "Thời gian: ${item.season}",
      "Địa điểm: ${item.location}",
      if (intro.isNotEmpty) "",
      if (intro.isNotEmpty) intro,
      "",
      "Cùng lan tỏa bản sắc người Dao.",
    ].join("\n");
    await CultureShareService.shareArticle(
      title: item.title,
      category: item.category,
      imageUrl: item.image,
      text: shareText,
    );
  }
}

String _shareSnippet(String value) {
  final text = value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^["“”:\s]+'), '')
      .trim();
  if (text.length <= 220) return text;
  return "${text.substring(0, 220).trim()}...";
}

class _FestivalThumb extends StatelessWidget {
  final _FestivalItem item;

  const _FestivalThumb({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _festivalMediaImage(
            item.image,
            width: 144,
            height: 104,
            fit: BoxFit.cover,
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DED4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _FestivalDetailScreen._red, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _FestivalDetailScreen._ink,
                fontSize: 13,
                height: 1.32,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GalleryNavButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 30),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _MeaningCard extends StatelessWidget {
  final _FestivalMeaning meaning;

  const _MeaningCard({required this.meaning});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DED4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: meaning.color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: meaning.color.withValues(alpha: 0.45)),
            ),
            child: Icon(meaning.icon, color: meaning.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meaning.title,
                  style: const TextStyle(
                    color: _FestivalDetailScreen._ink,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (meaning.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    meaning.text,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _FestivalDetailScreen._ink,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;

  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade800,
        fontSize: 14,
        height: 1.55,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _FestivalItem {
  final String title;
  final String subtitle;
  final String location;
  final String category;
  final String season;
  final String image;
  final List<String> gallery;
  final bool hasVideo;
  final String videoUrl;
  final String videoTitle;
  final String description;
  final List<_FestivalMeaning> meanings;
  final List<String> steps;
  final CultureSources sources;
  final bool isFromAdmin;

  const _FestivalItem({
    required this.title,
    required this.subtitle,
    required this.location,
    required this.category,
    required this.season,
    required this.image,
    required this.gallery,
    this.hasVideo = false,
    this.videoUrl = "",
    this.videoTitle = "Tư liệu lễ hội người Dao",
    required this.description,
    this.meanings = const [],
    this.sources = const CultureSources(),
    this.isFromAdmin = false,
    this.steps = const [
      "Chuẩn bị lễ vật",
      "Nghi thức cúng lễ",
      "Sinh hoạt cộng đồng",
      "Giao lưu văn hóa",
      "Kết thúc lễ",
    ],
  });

  static _FestivalItem? fromAdmin(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().trim();
    if (title.isEmpty) return null;

    final detail = _decodeDetail(data['detail_json']);
    final subtitle = (data['subtitle'] ?? '').toString().trim();
    final image = _normalizeCultureImageUrl(
      (data['image_url'] ?? '').toString().trim(),
    );
    final video = _normalizeCultureVideoUrl(
      (data['video_url'] ?? '').toString().trim(),
    );
    final content = (data['content'] ?? '').toString().trim();
    final gallery = _toStringList(
      detail['gallery'],
    ).map(_normalizeCultureImageUrl).where((item) => item.isNotEmpty).toList();

    return _FestivalItem(
      title: title,
      subtitle: subtitle.isNotEmpty ? subtitle : "Lễ hội truyền thống",
      location: (detail['location'] ?? "Người Dao").toString(),
      category: (detail['category'] ?? "Nghi lễ").toString(),
      season: (detail['season'] ?? "Theo từng địa phương").toString(),
      image: image,
      gallery: gallery,
      hasVideo: video.isNotEmpty,
      videoUrl: video,
      videoTitle: (detail['videoTitle'] ?? "Tư liệu lễ hội người Dao")
          .toString(),
      description: content.isNotEmpty
          ? content
          : "Nội dung đang được cập nhật.",
      meanings: _meaningsFromDetail(detail['meanings']),
      sources: CultureSources.fromDetail(detail),
      steps: _toStringList(detail['steps']),
      isFromAdmin: true,
    );
  }

  static Map<String, dynamic> _decodeDetail(dynamic raw) {
    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return {};
    try {
      final decoded = jsonDecode(text);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      return {};
    }
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List) return [];
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<_FestivalMeaning> _meaningsFromDetail(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) {
          final data = Map<String, dynamic>.from(item);
          return _FestivalMeaning(
            title: (data['title'] ?? '').toString(),
            text: (data['text'] ?? data['note'] ?? '').toString(),
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFFD52B24),
          );
        })
        .where((item) => item.title.trim().isNotEmpty)
        .toList();
  }

  static String _normalizeCultureImageUrl(String value) {
    final text = value.trim();
    if (text.isEmpty) return "";

    const marker = '/uploads/culture/';
    final markerIndex = text.indexOf(marker);
    if (markerIndex != -1) {
      final fileName = text.substring(markerIndex + marker.length);
      return '${AppConfig.baseUrl}/culture_articles/image.php?file=${Uri.encodeComponent(fileName)}';
    }

    if (text.startsWith('uploads/culture/')) {
      final fileName = text.substring('uploads/culture/'.length);
      return '${AppConfig.baseUrl}/culture_articles/image.php?file=${Uri.encodeComponent(fileName)}';
    }

    return text;
  }

  static String _normalizeCultureVideoUrl(String value) {
    final text = value.trim();
    if (text.isEmpty) return "";

    const marker = '/uploads/culture_videos/';
    final markerIndex = text.indexOf(marker);
    if (markerIndex != -1) {
      final fileName = text.substring(markerIndex + marker.length);
      return '${AppConfig.baseUrl}/uploads/culture_videos/${Uri.encodeComponent(fileName)}';
    }

    if (text.startsWith('uploads/culture_videos/')) {
      final fileName = text.substring('uploads/culture_videos/'.length);
      return '${AppConfig.baseUrl}/uploads/culture_videos/${Uri.encodeComponent(fileName)}';
    }

    return text;
  }
}

class _FestivalMeaning {
  final String title;
  final String text;
  final IconData icon;
  final Color color;

  const _FestivalMeaning({
    required this.title,
    required this.text,
    required this.icon,
    required this.color,
  });
}

Widget _festivalMediaImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Alignment alignment = Alignment.center,
}) {
  final value = path.trim();
  if (value.isEmpty) {
    return _festivalImageFallback(width, height);
  }
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return Image.network(
      value,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, __, ___) => _festivalImageFallback(width, height),
    );
  }

  return Image.asset(
    value,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    errorBuilder: (_, __, ___) => _festivalImageFallback(width, height),
  );
}

Widget _festivalImageFallback(double? width, double? height) {
  return Container(
    width: width,
    height: height,
    color: const Color(0xFFF4EFE8),
    alignment: Alignment.center,
    child: const Text(
      "Chưa có ảnh",
      style: TextStyle(color: Color(0xFF8C8177), fontWeight: FontWeight.w700),
    ),
  );
}
