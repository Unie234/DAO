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

class TraditionalCostumeScreen extends StatefulWidget {
  final String? initialDetailTitle;

  const TraditionalCostumeScreen({super.key, this.initialDetailTitle});

  static const Color _ink = Color(0xFF171B1F);
  static const Color _paper = Color(0xFFFBF8F2);
  static const Color _red = Color(0xFFC71622);

  static const List<_CostumeTopic> _topics = [
    _CostumeTopic(
      title: "Trang phục nữ Dao Đỏ",
      subtitle: "Hoa văn thêu tay tinh xảo, rực rỡ và ý nghĩa",
      location: "Lào Cai",
      image: "assets/ao.png",
      category: "Nữ",
      description:
          "Trang phục nữ Dao Đỏ nổi bật với sắc đỏ, đen và các hoa văn thêu tay tinh xảo. Mỗi chi tiết đều gắn với bản sắc, niềm tin và đời sống của người Dao.",
    ),
    _CostumeTopic(
      title: "Trang phục nam Dao",
      subtitle: "Sử dụng trong nghi lễ và các dịp lễ hội",
      location: "Hà Giang",
      image: "assets/khampha1.png",
      category: "Nam",
      description:
          "Trang phục nam Dao giữ dáng vẻ gọn gàng, trang trọng và bền bỉ trong sinh hoạt cộng đồng cùng các nghi lễ quan trọng.",
    ),
    _CostumeTopic(
      title: "Khăn đội đầu truyền thống",
      subtitle: "Nét đặc trưng không thể thiếu của phụ nữ Dao",
      location: "Yên Bái",
      image: "assets/khampha2.png",
      category: "Phụ kiện",
      description:
          "Khăn đội đầu tạo điểm nhấn nhận diện và thể hiện sự khéo léo qua cách gấp, buộc và trang trí hoa văn.",
      isVideo: true,
    ),
    _CostumeTopic(
      title: "Trang sức bạc",
      subtitle: "Biểu tượng của vẻ đẹp và sự giàu có",
      location: "Tuyên Quang",
      image: "assets/anhoduoi.png",
      category: "Phụ kiện",
      description:
          "Trang sức bạc đi cùng trang phục để tạo âm sắc, ánh sáng và một điểm nhấn trang trọng trong ngày hội.",
    ),
    _CostumeTopic(
      title: "Nghề thêu thổ cẩm",
      subtitle: "Tinh hoa trong từng đường kim mũi chỉ",
      location: "Lào Cai",
      image: "assets/khampha3.png",
      category: "Phụ kiện",
      description:
          "Nghề thêu thổ cẩm lưu giữ tri thức hoa văn và cách phối màu được truyền qua nhiều thế hệ.",
    ),
    _CostumeTopic(
      title: "Trang phục trong Lễ Cấp Sắc",
      subtitle: "Trang phục thiêng liêng trong nghi lễ quan trọng",
      location: "Bắc Kạn",
      image: "assets/hoa_tiet.png",
      category: "Trang phục nghi lễ",
      description:
          "Trong Lễ Cấp Sắc, trang phục tạo nên sự nghiêm cẩn và đánh dấu vai trò mới của người đàn ông Dao.",
    ),
  ];

  @override
  State<TraditionalCostumeScreen> createState() =>
      _TraditionalCostumeScreenState();
}

class _TraditionalCostumeScreenState extends State<TraditionalCostumeScreen> {
  static const Color _ink = TraditionalCostumeScreen._ink;
  static const Color _paper = TraditionalCostumeScreen._paper;
  static const Color _red = TraditionalCostumeScreen._red;
  static const List<String> _categories = [
    "Tất cả",
    "Nữ",
    "Nam",
    "Trang phục nghi lễ",
    "Phụ kiện",
  ];

  final TextEditingController _searchController = TextEditingController();
  String _query = "";
  String _selectedCategory = _categories.first;
  bool _showSearch = false;
  List<_CostumeTopic> _topics = TraditionalCostumeScreen._topics;
  List<_CostumeTopic>? _searchResults;
  Timer? _searchDebounce;
  int _searchRequestId = 0;
  bool _openedInitialDetail = false;

  @override
  void initState() {
    super.initState();
    _loadAdminCostumes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialDetailIfNeeded();
    });
  }

  Future<void> _loadAdminCostumes() async {
    final rows = await _fetchCultureArticles(category: "Trang phục");
    if (!mounted || rows.isEmpty) return;

    final parsed = rows
        .whereType<Map>()
        .map((row) => _CostumeTopic.fromAdmin(Map<String, dynamic>.from(row)))
        .whereType<_CostumeTopic>()
        .toList();

    if (parsed.isEmpty) return;
    setState(() => _topics = parsed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialDetailIfNeeded();
    });
  }

  void _openInitialDetailIfNeeded() {
    if (!mounted || _openedInitialDetail) return;
    final detailTitle = widget.initialDetailTitle?.trim();
    if (detailTitle == null || detailTitle.isEmpty) return;

    for (final topic in _topics) {
      if (topic.title.toLowerCase() == detailTitle.toLowerCase()) {
        _openedInitialDetail = true;
        _openDetail(context, topic);
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

  List<_CostumeTopic> get _filteredTopics {
    final source = _query.trim().isEmpty
        ? _topics
        : (_searchResults ?? const <_CostumeTopic>[]);
    final filtered = source.where((topic) {
      final matchesCategory =
          _selectedCategory == _categories.first ||
          _costumeCategory(topic.category) == _selectedCategory;
      return matchesCategory && _matchesRequestedGender(topic);
    }).toList();
    if (_query.trim().isNotEmpty) {
      filtered.sort(
        (a, b) =>
            vietnameseSearchScore(_query, [
              b.title,
              b.subtitle,
              b.location,
              b.category,
              b.description,
            ]).compareTo(
              vietnameseSearchScore(_query, [
                a.title,
                a.subtitle,
                a.location,
                a.category,
                a.description,
              ]),
            ),
      );
    }
    return filtered;
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
        category: 'Trang phục',
        limit: 30,
      );
      if (!mounted || requestId != _searchRequestId) return;
      final parsed = rows
          .whereType<Map>()
          .map((row) => _CostumeTopic.fromAdmin(Map<String, dynamic>.from(row)))
          .whereType<_CostumeTopic>()
          .toList();
      setState(() => _searchResults = parsed);
    });
  }

  bool _matchesRequestedGender(_CostumeTopic topic) {
    final query = normalizeVietnameseSearch(_query);
    final words = query.split(' ').toSet();
    final requestedFemale = words.contains('nu');
    final requestedMale = words.contains('nam');
    if (!requestedFemale && !requestedMale) return true;

    final category = _costumeCategory(topic.category);
    if (requestedFemale) {
      if (category == 'Nữ') return true;
      if (category == 'Nam') return false;
    }
    if (requestedMale) {
      if (category == 'Nam') return true;
      if (category == 'Nữ') return false;
    }

    final text = normalizeVietnameseSearch(
      '${topic.title} ${topic.subtitle} ${topic.category}',
    );
    final isFemale =
        text.contains('trang phuc nu') ||
        text.contains('phu nu') ||
        text.contains('co dau') ||
        text.contains('nguoi vo');
    final isMale =
        text.contains('trang phuc nam') ||
        text.contains('nam gioi') ||
        text.contains('dan ong') ||
        text.contains('nguoi chong');

    if (requestedFemale) return isFemale && !isMale;
    return isMale && !isFemale;
  }

  String _costumeCategory(String value) {
    final normalized = normalizeVietnameseSearch(value);
    if (normalized.contains('nghi le') ||
        normalized.contains('cap sac') ||
        normalized.contains('cuoi')) {
      return "Trang phục nghi lễ";
    }
    if (normalized.contains('phu kien') ||
        normalized.contains('khan') ||
        normalized.contains('trang suc')) {
      return "Phụ kiện";
    }
    if (normalized.contains('tre') || normalized.contains('em')) {
      return "Trẻ em";
    }
    if (normalized.contains('nam')) return "Nam";
    if (normalized.contains('nu')) return "Nữ";
    return value.trim();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTopics = _filteredTopics;
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildCover()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showSearch) ...[
                      _buildSearch(),
                      const SizedBox(height: 16),
                    ],
                    _buildFilters(),
                    const SizedBox(height: 24),
                    const _CostumeSectionTitle("Bộ sưu tập trang phục"),
                    const SizedBox(height: 12),
                    if (filteredTopics.isEmpty)
                      _buildEmptyCollection()
                    else
                      ...filteredTopics.map(
                        (topic) => _buildTopicTile(context, topic),
                      ),
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
            "Trang phục Dao",
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

  Widget _buildCover() {
    return SizedBox(
      height: 286,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/nentrangphucdao.png",
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.02),
                  Colors.white.withValues(alpha: 0.08),
                  _paper,
                ],
                stops: const [0.0, 0.64, 1.0],
              ),
            ),
          ),
          const Positioned(
            left: 28,
            right: 120,
            top: 54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Trang phục Dao",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: _ink,
                    fontFamily: "serif",
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Nét đẹp thêu tay truyền thống\ncủa người Dao Việt Nam",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: _ink,
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
          hintText: "Tìm trang phục...",
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

  Widget _buildFilters() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
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

  Widget _buildTopicTile(BuildContext context, _CostumeTopic topic) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _openDetail(context, topic),
        child: Container(
          height: 142,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 13,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(15),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _costumeMediaImage(
                      topic.image,
                      width: 152,
                      height: double.infinity,
                      fit: topic.isFromAdmin ? BoxFit.contain : BoxFit.cover,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontFamily: "serif",
                          fontSize: 18,
                          height: 1.12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        topic.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: _red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              topic.location,
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
                child: Icon(Icons.chevron_right_rounded, color: _ink),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCollection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DED4)),
      ),
      child: const Text(
        "Không tìm thấy trang phục phù hợp.",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, _CostumeTopic topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _CostumeDetailScreen(item: topic, relatedItems: _topics),
      ),
    );
  }
}

class _CostumeDetailScreen extends StatelessWidget {
  final _CostumeTopic item;
  final List<_CostumeTopic> relatedItems;

  const _CostumeDetailScreen({required this.item, required this.relatedItems});

  static const Color _ink = TraditionalCostumeScreen._ink;
  static const Color _paper = TraditionalCostumeScreen._paper;
  static const Color _red = TraditionalCostumeScreen._red;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(
              child: Container(
                transform: Matrix4.translationValues(0, -16, 0),
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
                decoration: const BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: _ink,
                        fontFamily: "serif",
                        fontSize: 28,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildMeta(context),
                    const SizedBox(height: 20),
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ..._buildOptionalSections(context),
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
          child: SizedBox(
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
                "Khám phá trang phục khác",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Row(
        children: [
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          ),
          Expanded(
            child: Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 15,
                height: 1.12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _showSaved(context),
            icon: const Icon(Icons.bookmark_border_rounded, color: _ink),
          ),
          IconButton(
            onPressed: _shareCostume,
            icon: const Icon(Icons.share_outlined, color: _ink),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Stack(
      children: [
        _costumeMediaImage(
          item.image,
          height: 408,
          width: double.infinity,
          fit: item.isFromAdmin ? BoxFit.contain : BoxFit.cover,
          alignment: item.isFromAdmin ? Alignment.center : Alignment.topCenter,
        ),
        if (!item.isFromAdmin)
          const Positioned(
            bottom: 36,
            child: Row(children: [_Dot(active: true), _Dot(), _Dot(), _Dot()]),
          ),
      ],
    );
  }

  Widget _buildMeta(BuildContext context) {
    final maxMetaWidth = MediaQuery.sizeOf(context).width - 36;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxMetaWidth),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_outlined, color: _red, size: 19),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  item.location,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: _red.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            item.category,
            style: TextStyle(
              color: _red,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOptionalSections(BuildContext context) {
    final sections = <Widget>[];
    final parts = _partItems;
    final meanings = _meaningItems;
    final steps = item.steps;
    final showGallery = item.gallery.isNotEmpty || !item.isFromAdmin;
    final showVideo =
        item.videoUrl.trim().isNotEmpty || (!item.isFromAdmin && item.isVideo);
    final showRelated = _relatedArticles.isNotEmpty;

    void addSection(String title, Widget child, {double gap = 24}) {
      sections.add(SizedBox(height: gap));
      sections.add(_CostumeSectionTitle(title));
      sections.add(const SizedBox(height: 12));
      sections.add(child);
    }

    if (parts.isNotEmpty) {
      addSection(
        item.isFromAdmin ? "Đặc điểm nổi bật" : "Các thành phần chính",
        item.isFromAdmin
            ? Column(children: _buildPartLines(parts))
            : _buildPartCards(parts),
      );
    }
    if (meanings.isNotEmpty) {
      addSection(
        item.isFromAdmin ? "Ý nghĩa văn hóa" : "Ý nghĩa hoa văn",
        Column(children: _buildMeanings(meanings)),
      );
    }
    if (steps.isNotEmpty) {
      addSection(
        item.isFromAdmin ? "Giá trị bảo tồn" : "Các bước",
        Column(children: _buildSteps(steps)),
      );
    }
    if (showGallery) {
      addSection("Hình ảnh", _buildGallery(), gap: 22);
    }
    if (showVideo) {
      addSection("Video", _buildVideo(context), gap: 22);
    }
    if (!item.sources.isEmpty) {
      addSection(
        "Nguồn tư liệu",
        CultureSourcesCard(sources: item.sources, accentColor: _red),
        gap: 22,
      );
    }
    if (showRelated) {
      addSection(
        "Bài viết liên quan",
        Column(children: _buildArticles(context)),
        gap: 22,
      );
    }

    return sections;
  }

  List<String> get _partItems {
    if (item.benefits.isNotEmpty) return item.benefits;
    if (item.isFromAdmin) return const [];
    return const ["Khăn đội đầu", "Áo truyền thống", "Váy", "Trang sức bạc"];
  }

  List<_CostumeMeaning> get _meaningItems {
    if (item.meanings.isNotEmpty) return item.meanings;
    if (item.isFromAdmin) return const [];
    return const [
      _CostumeMeaning(
        title: "Hình núi rừng",
        subtitle: "Tượng trưng cho thiên nhiên và cuộc sống",
      ),
      _CostumeMeaning(
        title: "Hình cây sự sống",
        subtitle: "Mong ước sức khỏe, sinh sôi và phát triển",
      ),
      _CostumeMeaning(
        title: "Hình mặt trời",
        subtitle: "Biểu tượng của ánh sáng và sự sống",
      ),
      _CostumeMeaning(
        title: "Hình tổ tiên",
        subtitle: "Thể hiện lòng biết ơn và sự kết nối tâm linh",
      ),
    ];
  }

  Widget _buildPartCards(List<String> parts) {
    const icons = [
      (Icons.style_rounded, "Khăn đội đầu"),
      (Icons.checkroom_rounded, "Áo truyền thống"),
      (Icons.safety_divider_rounded, "Váy"),
      (Icons.diamond_outlined, "Trang sức bạc"),
    ];
    return Row(
      children: parts.indexed.map((entry) {
        final index = entry.$1;
        final part = entry.$2;
        final icon = icons[index % icons.length].$1;
        return Expanded(
          child: Container(
            height: 126,
            margin: EdgeInsets.only(right: index == parts.length - 1 ? 0 : 8),
            padding: const EdgeInsets.fromLTRB(6, 14, 6, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _red.withValues(alpha: 0.09),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _red, size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  part,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildPartLines(List<String> parts) {
    return parts.map((part) {
      final isGroupTitle = _isAdminGroupTitle(part);
      if (isGroupTitle) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8, bottom: 6),
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
          decoration: BoxDecoration(
            color: _red.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: _red.withValues(alpha: 0.9), width: 4),
            ),
          ),
          child: Text(
            part,
            style: const TextStyle(
              color: _ink,
              fontSize: 16,
              height: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.fromLTRB(0, 11, 0, 11),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 7),
              decoration: BoxDecoration(color: _red, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                part,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  bool _isAdminGroupTitle(String value) {
    final text = value.trim();
    if (!item.isFromAdmin || !text.endsWith(':')) return false;
    final withoutColon = text.substring(0, text.length - 1).trim();
    if (withoutColon.isEmpty) return false;

    final lower = withoutColon.toLowerCase();
    final groupKeywords = [
      'trang phục người chồng',
      'trang phục người chong',
      'trang phục người vợ',
      'trang phục người vo',
      'trang phục nam',
      'trang phục nữ',
      'trang phục nu',
      'người chồng',
      'người chong',
      'người vợ',
      'người vo',
      'nam',
      'nữ',
      'nu',
    ];
    return groupKeywords.any(lower.contains);
  }

  List<Widget> _buildMeanings(List<_CostumeMeaning> meanings) {
    return meanings.map((meaning) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: _red.withValues(alpha: 0.8), width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meaning.title,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w900),
            ),
            if (meaning.subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                meaning.subtitle,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildSteps(List<String> steps) {
    final showNumbers = steps.length > 1;
    return steps.indexed.map((entry) {
      final index = entry.$1;
      final step = entry.$2;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showNumbers) ...[
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(
                    color: _red,
                    fontSize: 12,
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
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildGallery() {
    final images = item.gallery.isNotEmpty
        ? item.gallery
        : item.isFromAdmin
        ? const <String>[]
        : const [
            "assets/ao.png",
            "assets/khampha2.png",
            "assets/hoa_tiet.png",
            "assets/khampha3.png",
            "assets/anhoduoi.png",
            "assets/khampha1.png",
          ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.16,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _costumeMediaImage(images[index], fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _buildVideo(BuildContext context) {
    final videoTitle = item.videoUrl.trim().isNotEmpty
        ? item.title
        : "Cách mặc trang phục Dao";
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: item.videoUrl.trim().isEmpty
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CultureDetailScreen(
                  title: item.title,
                  type: "video",
                  mediaUrl: item.videoUrl,
                  content: item.description,
                ),
              ),
            ),
      child: Container(
        height: 168,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    _costumeMediaImage(item.image, fit: BoxFit.cover),
                    Container(color: Colors.black.withValues(alpha: 0.12)),
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.6),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              videoTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildArticles(BuildContext context) {
    return _relatedArticles.map((article) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _costumeMediaImage(
              article.image,
              width: 56,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(
            article.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: _ink),
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => _CostumeDetailScreen(
                item: article,
                relatedItems: relatedItems,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<_CostumeTopic> get _relatedArticles {
    final candidates = relatedItems
        .where((candidate) => candidate.title != item.title)
        .toList();
    candidates.sort((a, b) {
      final aScore = vietnameseRelatedScore(
        [item.title, item.subtitle, item.category, item.description],
        [a.title, a.subtitle, a.category, a.description],
      );
      final bScore = vietnameseRelatedScore(
        [item.title, item.subtitle, item.category, item.description],
        [b.title, b.subtitle, b.category, b.description],
      );
      return bScore.compareTo(aScore);
    });
    return candidates.take(3).toList();
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

  Future<void> _shareCostume() async {
    final intro = _shareSnippet(item.description);
    final shareText = [
      "Bài viết trên App Văn hóa Dao",
      "",
      item.title,
      if (item.subtitle.trim().isNotEmpty) item.subtitle,
      "",
      "Danh mục: ${item.category}",
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

class _Dot extends StatelessWidget {
  final bool active;

  const _Dot({this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 11 : 9,
      height: active ? 11 : 9,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.72),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _CostumeSectionTitle extends StatelessWidget {
  final String text;

  const _CostumeSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: TraditionalCostumeScreen._ink,
        fontFamily: "serif",
        fontSize: 19,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _CostumeTopic {
  final String title;
  final String subtitle;
  final String location;
  final String image;
  final String category;
  final String description;
  final bool isVideo;
  final String videoUrl;
  final List<String> gallery;
  final List<String> benefits;
  final List<_CostumeMeaning> meanings;
  final List<String> steps;
  final bool isFromAdmin;
  final CultureSources sources;

  const _CostumeTopic({
    required this.title,
    required this.subtitle,
    required this.location,
    required this.image,
    required this.category,
    required this.description,
    this.isVideo = false,
    this.videoUrl = "",
    this.gallery = const [],
    this.benefits = const [],
    this.meanings = const [],
    this.steps = const [],
    this.isFromAdmin = false,
    this.sources = const CultureSources(),
  });

  static _CostumeTopic? fromAdmin(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().trim();
    if (title.isEmpty) return null;

    final detail = _decodeDetail(data['detail_json']);
    final subtitle = (data['subtitle'] ?? '').toString().trim();
    final image = _normalizeCultureImageUrl(
      (data['image_url'] ?? '').toString().trim(),
    );
    final video = (data['video_url'] ?? '').toString().trim();
    final content = (data['content'] ?? '').toString().trim();
    final gallery = detail['gallery'] is List
        ? (detail['gallery'] as List)
              .map((item) => _normalizeCultureImageUrl(item.toString()))
              .where((item) => item.isNotEmpty)
              .toList()
        : <String>[];

    return _CostumeTopic(
      title: title,
      subtitle: subtitle.isNotEmpty ? subtitle : "Trang phục truyền thống",
      location: (detail['location'] ?? "Người Dao").toString(),
      image: image,
      category: _adminCostumeCategory(
        (detail['category'] ?? '').toString(),
        title,
        subtitle,
        content,
      ),
      description: content.isNotEmpty
          ? content
          : "Nội dung đang được cập nhật.",
      videoUrl: video,
      gallery: gallery,
      benefits: _toStringList(detail['benefits']),
      meanings: _meaningsFromDetail(detail['meanings']),
      steps: _toStringList(detail['steps']),
      sources: CultureSources.fromDetail(detail),
      isFromAdmin: true,
      isVideo:
          video.isNotEmpty ||
          (detail['isVideo']?.toString().toLowerCase() == 'true'),
    );
  }

  static String _adminCostumeCategory(
    String detailCategory,
    String title,
    String subtitle,
    String content,
  ) {
    final explicit = detailCategory.trim();
    if (explicit.isNotEmpty) return explicit;

    final text = normalizeVietnameseSearch('$title $subtitle $content');
    if (text.contains('cap sac') ||
        text.contains('nghi le') ||
        text.contains('le cuoi')) {
      return "Trang phục nghi lễ";
    }
    if (text.contains('phu kien') ||
        text.contains('khan') ||
        text.contains('trang suc')) {
      return "Phụ kiện";
    }
    if (text.contains('tre em')) return "Trẻ em";
    if (text.contains('nam')) return "Nam";
    if (text.contains('nu') || text.contains('co dau')) return "Nữ";
    return "Tất cả";
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<_CostumeMeaning> _meaningsFromDetail(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) {
          final row = Map<String, dynamic>.from(item);
          final title = (row['title'] ?? '').toString().trim();
          final subtitle = (row['subtitle'] ?? row['note'] ?? row['text'] ?? '')
              .toString()
              .trim();
          if (title.isEmpty) return null;
          return _CostumeMeaning(title: title, subtitle: subtitle);
        })
        .whereType<_CostumeMeaning>()
        .toList();
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

  static String _normalizeCultureImageUrl(String value) {
    final text = value.trim();
    if (text.isEmpty) return "";
    final normalized = text.replaceAll('\\', '/');

    final marker = '/uploads/culture/';
    final markerIndex = normalized.indexOf(marker);
    if (markerIndex != -1) {
      final fileName = normalized.substring(markerIndex + marker.length);
      return '${AppConfig.baseUrl}/culture_articles/image.php?file=${Uri.encodeComponent(fileName)}';
    }

    if (normalized.startsWith('uploads/culture/')) {
      final fileName = normalized.substring('uploads/culture/'.length);
      return '${AppConfig.baseUrl}/culture_articles/image.php?file=${Uri.encodeComponent(fileName)}';
    }

    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      final uri = Uri.tryParse(normalized);
      if (uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
        final baseUri = Uri.parse(AppConfig.baseUrl);
        return baseUri.replace(path: uri.path, query: uri.query).toString();
      }
      return normalized;
    }

    final hostBase = AppConfig.baseUrl.replaceFirst(RegExp(r'/dao_api/?$'), '');
    if (normalized.startsWith('/dao_api/')) {
      return '$hostBase$normalized';
    }
    if (normalized.startsWith('dao_api/')) {
      return '$hostBase/$normalized';
    }
    if (normalized.startsWith('/culture_articles/') ||
        normalized.startsWith('culture_articles/')) {
      final clean = normalized.replaceFirst(RegExp(r'^/+'), '');
      return '${AppConfig.baseUrl}/$clean';
    }

    if (normalized.startsWith('/uploads/') ||
        normalized.startsWith('uploads/')) {
      final clean = normalized.replaceFirst(RegExp(r'^/+'), '');
      return '${AppConfig.baseUrl}/$clean';
    }

    return normalized;
  }
}

class _CostumeMeaning {
  final String title;
  final String subtitle;

  const _CostumeMeaning({required this.title, required this.subtitle});
}

Widget _costumeMediaImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Alignment alignment = Alignment.center,
}) {
  final value = path.trim();
  if (value.isEmpty) {
    return _costumeImageFallback(width, height);
  }
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return Image.network(
      value,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, __, ___) => _costumeImageFallback(width, height),
    );
  }

  return Image.asset(
    value,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    errorBuilder: (_, __, ___) => _costumeImageFallback(width, height),
  );
}

Widget _costumeImageFallback(double? width, double? height) {
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
