import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/culture_article_service.dart';
import '../services/culture_share_service.dart';
import '../widgets/culture_sources_card.dart';
import 'culture_detail_screen.dart';

class HerbalKnowledgeScreen extends StatefulWidget {
  final String? initialDetailTitle;

  const HerbalKnowledgeScreen({super.key, this.initialDetailTitle});

  static const Color _ink = Color(0xFF1C201D);
  static const Color _green = Color(0xFF2F7D3C);
  static const Color _paper = Color(0xFFFBF7F0);

  static const List<_HerbCategory> _categories = [
    _HerbCategory("Tất cả", Icons.local_florist_rounded),
    _HerbCategory("Cây dược liệu", Icons.eco_rounded),
    _HerbCategory("Nghề thuốc Nam", Icons.medical_information_rounded),
    _HerbCategory("Tri thức dân gian", Icons.menu_book_rounded),
  ];

  static const List<_HerbItem> _items = [
    _HerbItem(
      title: "Lá tắm người Dao",
      subtitle: "Thanh lọc cơ thể, thư giãn, giữ ấm",
      image: "assets/khampha3.png",
      categories: ["Tri thức dân gian"],
      intro:
          "Lá tắm người Dao là bài thuốc dân gian truyền thống, kết hợp nhiều loại lá rừng có tính ấm, giúp làm sạch cơ thể, thư giãn tinh thần và giữ ấm sau một ngày lao động.",
      time: "20 - 30 phút",
      ingredients: [
        _Ingredient(
          "Lá mùi già",
          "Kháng khuẩn, giữ ấm cơ thể",
          "assets/khampha3.png",
        ),
        _Ingredient(
          "Lá bưởi rừng",
          "Thư giãn, giảm stress",
          "assets/khampha2.png",
        ),
        _Ingredient(
          "Lá ngải cứu",
          "Làm ấm, giảm đau nhức",
          "assets/khampha1.png",
        ),
        _Ingredient(
          "Lá sả",
          "Thơm nhẹ, đuổi côn trùng",
          "assets/banner_main.png",
        ),
      ],
      benefits: [
        "Làm sạch da, loại bỏ bụi bẩn và độc tố.",
        "Giữ ấm cơ thể, giảm đau nhức xương khớp.",
        "Thư giãn tinh thần, giảm mệt mỏi, căng thẳng.",
        "Hỗ trợ lưu thông khí huyết, giúp ngủ ngon hơn.",
      ],
      steps: [
        "Rửa sạch các loại lá.",
        "Đun sôi với khoảng 2 - 3 lít nước trong 15 - 20 phút.",
        "Pha thêm nước mát cho vừa nhiệt độ phù hợp.",
        "Dùng nước lá tắm toàn thân, ngâm hoặc xông hơi đều được.",
      ],
      warning:
          "Phụ nữ mang thai, người có bệnh da liễu nên tham khảo ý kiến thầy thuốc trước khi sử dụng.",
    ),
    _HerbItem(
      title: "Cây ích mẫu",
      subtitle: "Hỗ trợ điều hòa kinh nguyệt, bồi bổ khí huyết",
      image: "assets/khampha2.png",
      categories: ["Cây dược liệu"],
      intro:
          "Ích mẫu thường được nhắc đến trong các bài thuốc chăm sóc sức khỏe phụ nữ, giúp hỗ trợ khí huyết và phục hồi cơ thể.",
      time: "15 - 25 phút",
      ingredients: [
        _Ingredient("Thân ích mẫu", "Hỗ trợ khí huyết", "assets/khampha2.png"),
        _Ingredient("Gừng rừng", "Làm ấm cơ thể", "assets/khampha1.png"),
        _Ingredient("Lá thơm", "Tạo mùi dễ chịu", "assets/khampha3.png"),
      ],
      benefits: [
        "Hỗ trợ điều hòa cơ thể.",
        "Giúp làm ấm và thư giãn.",
        "Bổ trợ sức khỏe sau mệt mỏi.",
      ],
      steps: [
        "Làm sạch thảo dược.",
        "Sắc hoặc hãm theo hướng dẫn của người có kinh nghiệm.",
        "Dùng lượng vừa phải, không lạm dụng.",
      ],
      warning: "Không dùng tùy tiện cho phụ nữ mang thai.",
    ),
    _HerbItem(
      title: "Cây xạ đen",
      subtitle: "Thanh nhiệt, giải độc, hỗ trợ tăng sức đề kháng",
      image: "assets/khampha1.png",
      categories: ["Cây dược liệu"],
      intro:
          "Xạ đen là cây thuốc quen thuộc trong tri thức dân gian miền núi, thường được dùng để hỗ trợ thanh nhiệt và bồi bổ sức khỏe.",
      time: "20 phút",
      ingredients: [
        _Ingredient("Lá xạ đen", "Thanh nhiệt", "assets/khampha1.png"),
        _Ingredient("Thân xạ đen", "Bồi bổ", "assets/khampha2.png"),
      ],
      benefits: [
        "Hỗ trợ thanh nhiệt, giải độc.",
        "Giúp cơ thể nhẹ nhàng hơn.",
        "Bổ trợ sức khỏe khi dùng đúng cách.",
      ],
      steps: [
        "Rửa sạch lá và thân.",
        "Đun nước uống loãng.",
        "Dùng theo lượng phù hợp.",
      ],
      warning: "Người đang điều trị bệnh nên hỏi ý kiến bác sĩ trước khi dùng.",
    ),
    _HerbItem(
      title: "Rễ cây đương quy",
      subtitle: "Bổ huyết, điều kinh, tăng cường sức khỏe",
      image: "assets/banner_main.png",
      categories: ["Cây dược liệu"],
      intro:
          "Đương quy được dùng trong nhiều bài thuốc bồi bổ, thường kết hợp cùng các vị thuốc khác để chăm sóc sức khỏe.",
      time: "25 - 35 phút",
      ingredients: [
        _Ingredient("Rễ đương quy", "Bổ huyết", "assets/banner_main.png"),
        _Ingredient("Táo đỏ", "Bồi bổ", "assets/khampha2.png"),
      ],
      benefits: [
        "Hỗ trợ bồi bổ khí huyết.",
        "Giúp cơ thể phục hồi sau mệt mỏi.",
        "Có thể dùng trong các bài thuốc dưỡng sinh.",
      ],
      steps: [
        "Thái mỏng rễ đã làm sạch.",
        "Sắc cùng nước hoặc phối hợp vị thuốc khác.",
        "Dùng theo hướng dẫn phù hợp.",
      ],
      warning: "Không tự ý dùng liều cao hoặc dùng kéo dài.",
    ),
  ];

  @override
  State<HerbalKnowledgeScreen> createState() => _HerbalKnowledgeScreenState();
}

class _HerbalKnowledgeScreenState extends State<HerbalKnowledgeScreen> {
  static const Color _ink = HerbalKnowledgeScreen._ink;
  static const Color _green = HerbalKnowledgeScreen._green;
  static const Color _paper = HerbalKnowledgeScreen._paper;
  static const List<_HerbCategory> _categories =
      HerbalKnowledgeScreen._categories;
  static const List<_HerbItem> _fallbackItems = HerbalKnowledgeScreen._items;
  List<_HerbItem> _items = _fallbackItems;

  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  String _query = "";
  List<_HerbItem>? _searchResults;
  Timer? _searchDebounce;
  int _searchRequestId = 0;
  bool _openedInitialDetail = false;

  List<_HerbItem> get _filteredItems {
    return _query.trim().isEmpty
        ? _items
        : (_searchResults ?? const <_HerbItem>[]);
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
        category: 'Thảo dược',
        limit: 30,
      );
      if (!mounted || requestId != _searchRequestId) return;
      final parsed = rows
          .whereType<Map>()
          .map((row) => _HerbItem.fromAdmin(Map<String, dynamic>.from(row)))
          .whereType<_HerbItem>()
          .toList();
      setState(() => _searchResults = parsed);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadAdminHerbs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialDetailIfNeeded();
    });
  }

  Future<void> _loadAdminHerbs() async {
    final byMainCategory = await _fetchCultureArticles(category: "Thảo dược");
    final allRows = await _fetchCultureArticles(category: "");
    final rows = <dynamic>[
      ...byMainCategory,
      ...allRows.where(_isAdminHerbArticle),
    ];
    if (!mounted || rows.isEmpty) return;

    final parsed = rows
        .map((row) => _HerbItem.fromAdmin(row as Map<String, dynamic>))
        .whereType<_HerbItem>()
        .fold<List<_HerbItem>>([], (items, item) {
          final exists = items.any(
            (existing) =>
                existing.title.toLowerCase() == item.title.toLowerCase(),
          );
          if (!exists) items.add(item);
          return items;
        });

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
        _openHerbDetail(context, item);
        return;
      }
    }
  }

  Future<List<dynamic>> _fetchCultureArticles({
    required String category,
  }) async {
    try {
      final encodedCategory = Uri.encodeComponent(category);
      final url = category.trim().isEmpty
          ? '${ApiService.baseUrl}/culture_articles/list.php'
          : '${ApiService.baseUrl}/culture_articles/list.php?category=$encodedCategory';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      return [];
    } catch (_) {
      return [];
    }
  }

  bool _isAdminHerbArticle(dynamic row) {
    if (row is! Map) return false;
    final category = (row['category'] ?? '').toString().trim();
    if (_HerbItem.isHerbalCategory(category)) return true;

    final detailRaw = (row['detail_json'] ?? '').toString().trim();
    if (detailRaw.isEmpty) return false;
    try {
      final detail = Map<String, dynamic>.from(jsonDecode(detailRaw) as Map);
      final categories = _HerbItem.toStringList(
        detail['categories'] ??
            detail['category'] ??
            detail['herb_categories'] ??
            detail['type'],
      );
      return categories.any(_HerbItem.isHerbalCategory);
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    if (_showSearch) ...[
                      const SizedBox(height: 14),
                      _buildSearch(),
                    ],
                    const SizedBox(height: 22),
                    _buildCategories(context),
                    const SizedBox(height: 24),
                    const Text(
                      "Danh sách thảo dược",
                      style: TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_filteredItems.isEmpty)
                      _buildEmptySearch()
                    else
                      ..._filteredItems.map(
                        (item) => _buildHerbCard(context, item),
                      ),
                    const SizedBox(height: 10),
                    if (_query.trim().isEmpty) _buildMoreButton(),
                    const SizedBox(height: 24),
                    _buildTipBox(),
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
            "Thảo dược Dao",
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

  Widget _buildSearch() {
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(22),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: "Tìm thảo dược...",
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
            borderSide: const BorderSide(color: _green, width: 1.3),
          ),
        ),
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
            Image.asset("assets/nentrangthaoduoc.png", fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.72),
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
                    "Tinh hoa thảo dược\ncủa người Dao",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Tri thức dân gian được gìn giữ\nqua nhiều thế hệ.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
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

  Widget _buildCategories(BuildContext context) {
    return Row(
      children: _categories.map((category) {
        final isSelected = category.title == "Tất cả";
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openCategory(context, category.title),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isSelected ? _green : const Color(0xFFF0EDE8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    color: isSelected ? Colors.white : _green,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category.title,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _openCategory(BuildContext context, String category) {
    final items = category == "Tất cả"
        ? _items
        : _items.where((item) => item.categories.contains(category)).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _HerbCategoryScreen(category: category, items: items),
      ),
    );
  }

  Widget _buildHerbCard(BuildContext context, _HerbItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openHerbDetail(context, item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEDE7DE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _smartImage(
                  item.image,
                  width: 104,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 34,
                            minHeight: 34,
                          ),
                          onPressed: () => _saveHerbFromList(context, item),
                          icon: const Icon(
                            Icons.bookmark_border_rounded,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.categories
                          .take(2)
                          .map((tag) => _TagChip(text: tag))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _openHerbDetail(context, item),
                        style: TextButton.styleFrom(
                          foregroundColor: _green,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          "Chi tiết",
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreButton() {
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECE6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Xem thêm thảo dược",
            style: TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down_rounded, color: _ink),
        ],
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DED4)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: _green.withValues(alpha: 0.72),
            size: 34,
          ),
          const SizedBox(height: 8),
          const Text(
            "Không tìm thấy thảo dược phù hợp",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDEBD4)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bạn có biết?",
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Người Dao sử dụng thảo dược trong cuộc sống hằng ngày, từ tắm rửa, ăn uống đến chữa bệnh, để giữ gìn sức khỏe và cân bằng cơ thể.",
                  style: TextStyle(
                    color: _ink,
                    fontSize: 13,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.local_florist_outlined,
            color: _green.withValues(alpha: 0.75),
            size: 58,
          ),
        ],
      ),
    );
  }

  Future<void> _saveHerbFromList(BuildContext context, _HerbItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_culture_articles') ?? <String>[];
    final key = '${item.categories.first}|${item.title}';
    final existed = saved.contains(key);
    if (!existed) {
      saved.add(key);
      await prefs.setStringList('saved_culture_articles', saved);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existed
              ? "Bài viết đã có trong danh sách lưu."
              : "Đã lưu ${item.title}.",
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

void _openHerbDetail(BuildContext context, _HerbItem item) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => _HerbalDetailScreen(item: item)),
  );
}

class _HerbCategoryScreen extends StatelessWidget {
  final String category;
  final List<_HerbItem> items;

  const _HerbCategoryScreen({required this.category, required this.items});

  static const Color _ink = HerbalKnowledgeScreen._ink;
  static const Color _green = HerbalKnowledgeScreen._green;
  static const Color _paper = HerbalKnowledgeScreen._paper;

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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category == "Tất cả"
                          ? "Tất cả bài thảo dược"
                          : "Bài thảo dược về $category",
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${items.length} bài liên quan",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (items.isEmpty)
                      _buildEmpty()
                    else
                      ...items.map((item) => _buildRelatedCard(context, item)),
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
          Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedCard(BuildContext context, _HerbItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openHerbDetail(context, item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEDE7DE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _smartImage(
                  item.image,
                  width: 96,
                  height: 82,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.categories
                          .take(2)
                          .map((tag) => _TagChip(text: tag))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: _green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE7DE)),
      ),
      child: const Text(
        "Chưa có bài thảo dược trong danh mục này.",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HerbalDetailScreen extends StatelessWidget {
  final _HerbItem item;

  const _HerbalDetailScreen({required this.item});

  static const Color _ink = HerbalKnowledgeScreen._ink;
  static const Color _green = HerbalKnowledgeScreen._green;
  static const Color _paper = HerbalKnowledgeScreen._paper;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildHeroImage()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildMetaRow(),
                    const SizedBox(height: 28),
                    _SectionTitle("Giới thiệu"),
                    const SizedBox(height: 10),
                    _BodyText(item.intro),
                    if (item.ingredients.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      _SectionTitle("Đặc điểm nhận dạng"),
                      const SizedBox(height: 12),
                      _buildIngredients(),
                    ],
                    if (item.benefits.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      _SectionTitle("Vai trò trong đời sống người Dao"),
                      const SizedBox(height: 10),
                      ...item.benefits.map(
                        (text) =>
                            _IconLine(icon: Icons.groups_rounded, text: text),
                      ),
                    ],
                    if (item.steps.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      _SectionTitle("Công dụng theo kinh nghiệm dân gian"),
                      const SizedBox(height: 10),
                      ...item.steps.map(
                        (text) =>
                            _IconLine(icon: Icons.healing_rounded, text: text),
                      ),
                    ],
                    if (item.culturalValues.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      _SectionTitle("Giá trị văn hóa"),
                      const SizedBox(height: 10),
                      ...item.culturalValues.map(
                        (text) => _IconLine(
                          icon: Icons.auto_stories_rounded,
                          text: text,
                        ),
                      ),
                    ],
                    if (item.warning.trim().isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _buildWarning(),
                    ],
                    if (item.gallery.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      _SectionTitle("Hình ảnh"),
                      const SizedBox(height: 12),
                      _buildGallery(context),
                    ],
                    if (item.videoUrl.trim().isNotEmpty) ...[
                      const SizedBox(height: 26),
                      _SectionTitle("Video"),
                      const SizedBox(height: 12),
                      _buildVideoCard(context),
                    ],
                    if (!item.sources.isEmpty) ...[
                      const SizedBox(height: 26),
                      _SectionTitle("Nguồn tư liệu"),
                      const SizedBox(height: 12),
                      CultureSourcesCard(
                        sources: item.sources,
                        accentColor: _green,
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildBottomActions(context),
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
          Positioned.fill(
            left: 56,
            right: 104,
            child: Center(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Positioned(
            right: 52,
            child: IconButton(
              onPressed: () => _saveHerb(context),
              icon: const Icon(Icons.bookmark_border_rounded, color: _ink),
            ),
          ),
          Positioned(
            right: 14,
            child: IconButton(
              onPressed: () => _shareHerb(),
              icon: const Icon(Icons.share_outlined, color: _ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 250,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _smartImage(item.image, fit: BoxFit.contain),
              Positioned(
                left: 16,
                top: 16,
                child: _TagChip(text: item.categories.first),
              ),
              if (item.gallery.length > 1)
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Text(
                    "1/${item.gallery.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow() {
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      children: [
        _MetaItem(Icons.local_florist_rounded, item.categories.first),
        if (item.location.trim().isNotEmpty)
          _MetaItem(Icons.location_on_outlined, item.location),
      ],
    );
  }

  Widget _buildIngredients() {
    return Column(
      children: item.ingredients.map((ingredient) {
        final note = ingredient.note.trim();
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEDE7DE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.spa_rounded, color: _green, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  note.isEmpty ? ingredient.name : "${ingredient.name}: $note",
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 14,
                    height: 1.42,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF5D7BF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Lưu ý",
            style: TextStyle(
              color: Color(0xFFC6462B),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          _BodyText(item.warning),
        ],
      ),
    );
  }

  Widget _buildGallery(BuildContext context) {
    final images = item.gallery;
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _openHerbGallery(context, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _smartImage(
                images[index],
                width: 86,
                height: 68,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CultureDetailScreen(
            title: item.title,
            type: "video",
            mediaUrl: item.videoUrl,
            content: item.intro,
          ),
        ),
      ),
      child: Container(
        height: 174,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDE7DE)),
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
                    _smartImage(item.image, fit: BoxFit.cover),
                    Container(color: Colors.black.withValues(alpha: 0.12)),
                    Container(
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openHerbGallery(BuildContext context, int initialIndex) {
    final controller = PageController(initialPage: initialIndex);
    var currentIndex = initialIndex;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              PageView.builder(
                controller: controller,
                itemCount: item.gallery.length,
                onPageChanged: (index) =>
                    setDialogState(() => currentIndex = index),
                itemBuilder: (context, index) => Center(
                  child: InteractiveViewer(
                    child: _smartImage(
                      item.gallery[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 18,
                right: 18,
                child: IconButton.filled(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              if (currentIndex > 0)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _GalleryNavButton(
                      icon: Icons.chevron_left_rounded,
                      onPressed: () => controller.previousPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                ),
              if (currentIndex < item.gallery.length - 1)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _GalleryNavButton(
                      icon: Icons.chevron_right_rounded,
                      onPressed: () => controller.nextPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Center(
                  child: Text(
                    "${currentIndex + 1}/${item.gallery.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          "Tìm hiểu thêm thảo dược khác",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Future<void> _shareHerb() async {
    final intro = _shareSnippet(item.intro);
    final shareText = [
      "Bài viết trên App Văn hóa Dao",
      "",
      item.title,
      if (item.subtitle.trim().isNotEmpty) item.subtitle,
      "",
      "Danh mục: ${item.categories.join(', ')}",
      if (item.location.trim().isNotEmpty) "Địa phương: ${item.location}",
      if (intro.isNotEmpty) "",
      if (intro.isNotEmpty) intro,
      "",
      "Cùng lan tỏa tri thức văn hóa Dao.",
    ].join("\n");
    await CultureShareService.shareArticle(
      title: item.title,
      category: item.categories.join(', '),
      imageUrl: item.image,
      text: shareText,
    );
  }

  Future<void> _saveHerb(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_culture_articles') ?? <String>[];
    final key = '${item.categories.first}|${item.title}';
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
}

String _shareSnippet(String value) {
  final text = value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^["“”:\s]+'), '')
      .trim();
  if (text.length <= 220) return text;
  return "${text.substring(0, 220).trim()}...";
}

Widget _smartImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) {
    return _herbImageFallback(width, height);
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return Image.network(
      trimmed,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _herbImageFallback(width, height),
    );
  }

  return Image.asset(
    trimmed,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => _herbImageFallback(width, height),
  );
}

Widget _herbImageFallback(double? width, double? height) {
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

class _TagChip extends StatelessWidget {
  final String text;

  const _TagChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF335A35),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 40,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: HerbalKnowledgeScreen._green, size: 18),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: HerbalKnowledgeScreen._ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
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

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: HerbalKnowledgeScreen._ink,
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

class _IconLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HerbalKnowledgeScreen._green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: _BodyText(text)),
        ],
      ),
    );
  }
}

class _HerbCategory {
  final String title;
  final IconData icon;

  const _HerbCategory(this.title, this.icon);
}

class _Ingredient {
  final String name;
  final String note;
  final String image;

  const _Ingredient(this.name, this.note, this.image);
}

class _HerbItem {
  final String title;
  final String subtitle;
  final String image;
  final List<String> categories;
  final String intro;
  final String time;
  final List<_Ingredient> ingredients;
  final List<String> benefits;
  final List<String> steps;
  final String location;
  final List<String> culturalValues;
  final String warning;
  final List<String> gallery;
  final String videoUrl;
  final CultureSources sources;

  const _HerbItem({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.categories,
    required this.intro,
    required this.time,
    required this.ingredients,
    required this.benefits,
    required this.steps,
    required this.warning,
    this.location = "Người Dao",
    this.culturalValues = const [],
    this.gallery = const [],
    this.videoUrl = "",
    this.sources = const CultureSources(),
  });

  static _HerbItem? fromAdmin(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().trim();
    if (title.isEmpty) return null;

    final subtitle = (data['subtitle'] ?? '').toString().trim();
    var image = _normalizeCultureImageUrl(
      (data['image_url'] ?? '').toString().trim(),
    );
    final videoUrl = (data['video_url'] ?? '').toString().trim();
    final intro = (data['content'] ?? '').toString().trim();
    final detailRaw = (data['detail_json'] ?? '').toString().trim();

    String time = "Chưa cập nhật";
    String location = "Người Dao";
    List<String> categories = [];
    List<_Ingredient> ingredients = const [];
    List<String> benefits = const [];
    List<String> steps = const [];
    List<String> culturalValues = const [];
    String warning = "";
    List<String> gallery = const [];
    CultureSources sources = const CultureSources();

    if (detailRaw.isNotEmpty) {
      try {
        final detail = Map<String, dynamic>.from(
          (jsonDecode(detailRaw) as Map),
        );
        time = (detail['time'] ?? time).toString();
        location = (detail['location'] ?? location).toString();
        categories = _toStringList(
          detail['categories'] ??
              detail['category'] ??
              detail['herb_categories'] ??
              detail['type'],
        );
        benefits = _toStringList(detail['benefits']);
        steps = _toStringList(detail['steps']);
        culturalValues = _toStringList(detail['cultural_values']);
        warning = (detail['warning'] ?? warning).toString();
        gallery = _toStringList(detail['gallery'])
            .map(_normalizeCultureImageUrl)
            .where((item) => item.isNotEmpty)
            .toList();
        if (image.isEmpty && gallery.isNotEmpty) {
          image = gallery.first;
        }
        sources = CultureSources.fromDetail(detail);

        final ingRaw = detail['ingredients'];
        if (ingRaw is List) {
          ingredients = ingRaw
              .whereType<Map>()
              .map((e) {
                final m = Map<String, dynamic>.from(e);
                return _Ingredient(
                  (m['title'] ?? '').toString(),
                  (m['subtitle'] ?? '').toString(),
                  _normalizeCultureImageUrl((m['image'] ?? image).toString()),
                );
              })
              .where((it) => it.name.trim().isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }

    if (categories.isEmpty) {
      final dataCategory = (data['category'] ?? '').toString().trim();
      categories = isHerbalCategory(dataCategory) && dataCategory != "Thảo dược"
          ? [dataCategory]
          : ["Tri thức dân gian"];
    }

    if (benefits.isEmpty && intro.isNotEmpty) {
      benefits = [intro];
    }
    return _HerbItem(
      title: title,
      subtitle: subtitle.isNotEmpty ? subtitle : "Bài thảo dược dân gian",
      image: image,
      categories: categories,
      intro: intro.isNotEmpty ? intro : "Nội dung đang được cập nhật.",
      time: time,
      ingredients: ingredients,
      benefits: benefits,
      steps: steps,
      location: location,
      culturalValues: culturalValues,
      warning: warning,
      gallery: gallery,
      videoUrl: videoUrl,
      sources: sources,
    );
  }

  static List<String> toStringList(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return [];
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) return toStringList(decoded);
      } catch (_) {}
      return trimmed
          .split(RegExp(r'[,;|/]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is! List) return [];
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<String> _toStringList(dynamic value) => toStringList(value);

  static bool isHerbalCategory(String category) {
    final value = category.trim();
    return value == "Thảo dược" ||
        value == "Cây dược liệu" ||
        value == "Nghề thuốc Nam" ||
        value == "Tri thức dân gian" ||
        value == "Tắm người" ||
        value == "Chữa bệnh" ||
        value == "Dưỡng sinh" ||
        value == "Phụ nữ" ||
        value == "Giải độc" ||
        value == "Bồi bổ";
  }

  static String _normalizeCultureImageUrl(String value) {
    final text = value.trim();
    if (text.isEmpty) return "";
    final normalized = text.replaceAll('\\', '/');

    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      final fileName = _cultureImageFileName(normalized);
      if (fileName.isNotEmpty) {
        return '${ApiService.baseUrl}/culture_articles/image.php?file=${Uri.encodeComponent(fileName)}';
      }

      final uri = Uri.tryParse(normalized);
      if (uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
        final baseUri = Uri.parse(ApiService.baseUrl);
        return baseUri.replace(path: uri.path, query: uri.query).toString();
      }
      return normalized;
    }

    final hostBase = ApiService.baseUrl.replaceFirst(
      RegExp(r'/dao_api/?$'),
      '',
    );
    if (normalized.startsWith('/dao_api/')) {
      return '$hostBase$normalized';
    }
    if (normalized.startsWith('dao_api/')) {
      return '$hostBase/$normalized';
    }
    if (normalized.startsWith('/culture_articles/') ||
        normalized.startsWith('culture_articles/')) {
      final clean = normalized.replaceFirst(RegExp(r'^/+'), '');
      return '${ApiService.baseUrl}/$clean';
    }

    final fileName = _cultureImageFileName(normalized);
    if (fileName.isNotEmpty) {
      return '${ApiService.baseUrl}/culture_articles/image.php?file=${Uri.encodeComponent(fileName)}';
    }

    if (normalized.startsWith('/uploads/') ||
        normalized.startsWith('uploads/')) {
      final clean = normalized.replaceFirst(RegExp(r'^/+'), '');
      return '${ApiService.baseUrl}/$clean';
    }

    return normalized;
  }

  static String _cultureImageFileName(String value) {
    final path = Uri.tryParse(value)?.path ?? value;
    final normalized = path.replaceAll('\\', '/');
    final marker = RegExp(r'(?:^|/)(?:storage/)?uploads/culture/');
    final match = marker.firstMatch(normalized);
    if (match == null) return "";

    final fileName = normalized.substring(match.end).split('/').last.trim();
    return fileName;
  }
}
