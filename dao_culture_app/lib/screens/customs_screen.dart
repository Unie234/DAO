import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';
import '../services/culture_article_service.dart';
import '../services/culture_share_service.dart';
import '../widgets/culture_sources_card.dart';
import 'culture_detail_screen.dart';

class CustomsScreen extends StatefulWidget {
  final String? initialDetailTitle;

  const CustomsScreen({super.key, this.initialDetailTitle});

  static const Color _ink = Color(0xFF171B1F);
  static const Color _red = Color(0xFFC20D14);
  static const Color _green = Color(0xFF2F7D3C);
  static const Color _paper = Color(0xFFFBF7F0);

  static const List<_CustomCategory> _categories = [
    _CustomCategory("Tất cả", Icons.local_fire_department_rounded),
    _CustomCategory("Hôn nhân", Icons.groups_rounded),
    _CustomCategory("Nghi lễ vòng đời", Icons.celebration_rounded),
    _CustomCategory("Tín ngưỡng & tâm linh", Icons.account_balance_rounded),
    _CustomCategory("Tang ma", Icons.home_work_rounded),
    _CustomCategory("Kiêng kỵ dân gian", Icons.do_not_disturb_alt_rounded),
  ];

  static const List<_CustomItem> _items = [
    _CustomItem(
      title: "Lễ cấp sắc",
      subtitle: "Nghi lễ trưởng thành quan trọng của người Dao.",
      image: "assets/khampha1.png",
      category: "Nghi lễ vòng đời",
      location: "Cao Bằng, Lào Cai",
      time: "3 - 7 ngày",
      intro:
          "Lễ cấp sắc là nghi lễ quan trọng đánh dấu sự trưởng thành của người đàn ông Dao, được công nhận bởi tổ tiên và cộng đồng. Người được cấp sắc sẽ được trao quyền hành tâm linh, có thể cúng bái, làm thầy cúng và gánh vác trách nhiệm trong gia đình, dòng họ.",
      meanings: [
        _Meaning(
          "Trưởng thành",
          "Công nhận người đàn ông đã trưởng thành.",
          Icons.flag_rounded,
        ),
        _Meaning(
          "Tâm linh",
          "Được tổ tiên bảo hộ, ban phúc lành.",
          Icons.local_fire_department_rounded,
        ),
        _Meaning(
          "Cộng đồng",
          "Gắn kết gia đình, dòng họ và bản làng.",
          Icons.groups_rounded,
        ),
      ],
      steps: [
        "Chọn ngày lành, chuẩn bị lễ vật và dựng bàn thờ.",
        "Thầy cúng làm lễ xin phép tổ tiên.",
        "Người được cấp sắc trải qua các nghi thức thử thách.",
        "Thầy cúng trao sắc lệnh và đọc tên mới.",
        "Tiệc mừng và cảm tạ tổ tiên, kết thúc lễ.",
      ],
      warning:
          "Lễ cấp sắc chỉ dành cho nam giới Dao từ 12 tuổi trở lên và chưa từng được cấp sắc.",
    ),
    _CustomItem(
      title: "Lễ cưới",
      subtitle: "Nghi thức cưới hỏi truyền thống của người Dao.",
      image: "assets/khampha2.png",
      category: "Hôn nhân",
      location: "Các bản người Dao",
      time: "1 - 2 ngày",
      intro:
          "Lễ cưới người Dao thể hiện sự gắn kết giữa hai gia đình, coi trọng lời chúc phúc của họ hàng và những nghi thức xin dâu, đón dâu, ra mắt tổ tiên.",
      meanings: [
        _Meaning(
          "Gia đình",
          "Kết nối hai bên dòng họ.",
          Icons.diversity_1_rounded,
        ),
        _Meaning(
          "Bản sắc",
          "Giữ gìn trang phục và lời hát cưới.",
          Icons.style_rounded,
        ),
        _Meaning(
          "Chúc phúc",
          "Cầu mong hôn nhân bền chặt.",
          Icons.favorite_rounded,
        ),
      ],
      steps: [
        "Nhà trai chuẩn bị lễ vật.",
        "Đoàn đón dâu đến nhà gái theo giờ lành.",
        "Hai bên thực hiện nghi thức ra mắt tổ tiên.",
        "Gia đình chúc phúc cho đôi vợ chồng.",
      ],
      warning:
          "Các nghi thức có thể khác nhau theo từng nhóm Dao và từng địa phương.",
    ),
    _CustomItem(
      title: "Lễ đầy tháng",
      subtitle: "Nghi lễ cầu mong sức khỏe cho em bé.",
      image: "assets/banner_main.png",
      category: "Nghi lễ vòng đời",
      location: "Trong gia đình",
      time: "1 ngày",
      intro:
          "Lễ đầy tháng là dịp gia đình cảm tạ tổ tiên, cầu mong em bé khỏe mạnh, hay ăn chóng lớn và được cộng đồng đón nhận.",
      meanings: [
        _Meaning(
          "Bảo hộ",
          "Cầu tổ tiên che chở cho em bé.",
          Icons.shield_rounded,
        ),
        _Meaning(
          "Gia đình",
          "Gắn kết người thân trong nhà.",
          Icons.family_restroom_rounded,
        ),
        _Meaning(
          "May mắn",
          "Gửi lời chúc lành đầu đời.",
          Icons.auto_awesome_rounded,
        ),
      ],
      steps: [
        "Chuẩn bị mâm lễ trong gia đình.",
        "Người lớn khấn báo tổ tiên.",
        "Gia đình chúc phúc cho em bé.",
      ],
      warning:
          "Nghi lễ nên thực hiện trang trọng, phù hợp điều kiện từng gia đình.",
    ),
    _CustomItem(
      title: "Lễ cúng tổ tiên",
      subtitle: "Thể hiện lòng biết ơn với tổ tiên, ông bà.",
      image: "assets/anhoduoi.png",
      category: "Tín ngưỡng & tâm linh",
      location: "Nhà truyền thống",
      time: "Theo dịp lễ",
      intro:
          "Cúng tổ tiên là phong tục quan trọng trong đời sống tinh thần người Dao, thể hiện đạo lý nhớ nguồn và sự kết nối giữa các thế hệ.",
      meanings: [
        _Meaning(
          "Biết ơn",
          "Tưởng nhớ công lao tổ tiên.",
          Icons.volunteer_activism_rounded,
        ),
        _Meaning(
          "Tâm linh",
          "Kết nối với thế giới tổ tiên.",
          Icons.spa_rounded,
        ),
        _Meaning(
          "Nề nếp",
          "Giữ gìn truyền thống gia đình.",
          Icons.home_rounded,
        ),
      ],
      steps: [
        "Dọn dẹp bàn thờ, chuẩn bị lễ vật.",
        "Thắp hương và đọc lời khấn.",
        "Con cháu cùng tưởng nhớ tổ tiên.",
      ],
      warning: "Cần giữ thái độ trang nghiêm khi thực hiện nghi lễ.",
    ),
    _CustomItem(
      title: "Tết nhảy",
      subtitle: "Lễ hội lớn nhất của người Dao để cầu bình an.",
      image: "assets/ao.png",
      category: "Tín ngưỡng & tâm linh",
      location: "Làng bản người Dao",
      time: "Dịp đầu năm",
      intro:
          "Tết nhảy là lễ hội giàu tính cộng đồng, có múa, hát, nghi lễ cúng tổ tiên và các hoạt động cầu mùa, cầu bình an.",
      meanings: [
        _Meaning("Cầu mùa", "Cầu mong năm mới thuận lợi.", Icons.eco_rounded),
        _Meaning(
          "Cộng đồng",
          "Quy tụ dân bản cùng tham gia.",
          Icons.groups_rounded,
        ),
        _Meaning(
          "Nghệ thuật",
          "Thể hiện múa hát truyền thống.",
          Icons.music_note_rounded,
        ),
      ],
      steps: [
        "Chuẩn bị trang phục và lễ vật.",
        "Thực hiện nghi lễ cúng tổ tiên.",
        "Múa hát, nhảy nghi lễ và giao lưu cộng đồng.",
      ],
      warning: "Một số phần nghi lễ chỉ do người am hiểu phong tục thực hiện.",
    ),
    _CustomItem(
      title: "Nghi thức tang ma",
      subtitle: "Phong tục tiễn biệt người đã khuất theo nghi lễ Dao.",
      image: "assets/khampha3.png",
      category: "Tang ma",
      location: "Các bản người Dao",
      time: "Tùy từng dòng họ",
      intro:
          "Tang ma của người Dao chứa đựng nhiều nghi thức thể hiện lòng hiếu kính, niềm tin vào tổ tiên và mong muốn người đã khuất được đưa tiễn trang nghiêm.",
      meanings: [
        _Meaning(
          "Hiếu kính",
          "Thể hiện lòng biết ơn với người đã khuất.",
          Icons.volunteer_activism_rounded,
        ),
        _Meaning(
          "Tâm linh",
          "Cầu mong linh hồn được an yên.",
          Icons.spa_rounded,
        ),
        _Meaning(
          "Dòng họ",
          "Gắn kết con cháu trong gia đình.",
          Icons.groups_rounded,
        ),
      ],
      steps: [
        "Báo tin cho họ hàng và chuẩn bị nghi lễ.",
        "Thầy cúng thực hiện các bài cúng tiễn biệt.",
        "Gia đình làm lễ tưởng nhớ người đã khuất.",
        "Hoàn tất nghi thức theo phong tục từng dòng họ.",
      ],
      warning:
          "Các nghi thức tang ma cần thực hiện theo người am hiểu phong tục địa phương.",
    ),
    _CustomItem(
      title: "Kiêng kỵ dân gian",
      subtitle: "Những điều nên tránh trong sinh hoạt và nghi lễ.",
      image: "assets/hoa_tiet.png",
      category: "Kiêng kỵ dân gian",
      location: "Trong đời sống hằng ngày",
      time: "Theo từng dịp",
      intro:
          "Kiêng kỵ dân gian phản ánh kinh nghiệm sống, niềm tin tâm linh và cách người Dao giữ sự hài hòa giữa con người, gia đình và cộng đồng.",
      meanings: [
        _Meaning(
          "Ứng xử",
          "Nhắc nhở cách cư xử đúng mực.",
          Icons.handshake_rounded,
        ),
        _Meaning("Bình an", "Cầu tránh điều không may.", Icons.shield_rounded),
        _Meaning("Nề nếp", "Giữ gìn quy tắc cộng đồng.", Icons.home_rounded),
      ],
      steps: [
        "Tìm hiểu kiêng kỵ theo từng dịp lễ.",
        "Hỏi người lớn tuổi khi tham gia nghi thức.",
        "Tôn trọng quy tắc của gia đình và bản làng.",
      ],
      warning: "Một số kiêng kỵ khác nhau theo nhóm Dao và từng địa phương.",
    ),
  ];

  @override
  State<CustomsScreen> createState() => _CustomsScreenState();
}

class _CustomsScreenState extends State<CustomsScreen> {
  static const Color _ink = CustomsScreen._ink;
  static const Color _red = CustomsScreen._red;
  static const Color _green = CustomsScreen._green;
  static const Color _paper = CustomsScreen._paper;
  static const List<_CustomCategory> _categories = CustomsScreen._categories;
  static const List<_CustomItem> _fallbackItems = CustomsScreen._items;
  List<_CustomItem> _items = _fallbackItems;

  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  String _query = "";
  List<_CustomItem>? _searchResults;
  Timer? _searchDebounce;
  int _searchRequestId = 0;
  bool _openedInitialDetail = false;

  @override
  void initState() {
    super.initState();
    _loadAdminCustoms();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialDetailIfNeeded();
    });
  }

  Future<void> _loadAdminCustoms() async {
    final rows = await _fetchCultureArticles(category: "Phong tục");
    if (!mounted || rows.isEmpty) return;

    final parsed = rows
        .whereType<Map>()
        .map((row) => _CustomItem.fromAdmin(Map<String, dynamic>.from(row)))
        .whereType<_CustomItem>()
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
        _openCustomDetail(context, item);
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

  List<_CustomItem> get _filteredItems {
    return _query.trim().isEmpty
        ? _items
        : (_searchResults ?? const <_CustomItem>[]);
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
        category: 'Phong tục',
        limit: 30,
      );
      if (!mounted || requestId != _searchRequestId) return;
      final parsed = rows
          .whereType<Map>()
          .map((row) => _CustomItem.fromAdmin(Map<String, dynamic>.from(row)))
          .whereType<_CustomItem>()
          .toList();
      setState(() => _searchResults = parsed);
    });
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
                      "Danh sách phong tục",
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
                        (item) => _buildCustomCard(context, item),
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
            "Phong tục Dao",
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
          hintText: "Tìm phong tục...",
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

  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset("assets/khampha1.png", fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.78),
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
                    "Khám phá\nphong tục truyền thống\ncủa người Dao",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      height: 1.16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Gin giữ bản sắc - Kết nối tương lai",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category.title == "Tất cả";
          return SizedBox(
            width: 92,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openCustomCategory(context, category.title),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: selected ? _red : const Color(0xFFF0EDE8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category.icon,
                      color: selected ? Colors.white : _green,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? _red : _ink,
                      fontSize: 11,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openCustomCategory(BuildContext context, String category) {
    final items = category == "Tất cả"
        ? _items
        : _items
              .where((item) => _sameCustomCategory(item.category, category))
              .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CustomCategoryScreen(category: category, items: items),
      ),
    );
  }

  Widget _buildCustomCard(BuildContext context, _CustomItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openCustomDetail(context, item),
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
                child: _customMediaImage(
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
                          onPressed: () => _saveCustomArticle(context, item),
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
                    _CustomChip(text: item.category),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _openCustomDetail(context, item),
                        style: TextButton.styleFrom(
                          foregroundColor: _red,
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
            "Xem thêm phong tục",
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
            color: _red.withValues(alpha: 0.72),
            size: 34,
          ),
          const SizedBox(height: 8),
          const Text(
            "Không tìm thấy phong tục phù hợp",
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
                  "Người Dao có hệ thống phong tục phong phú, được truyền từ đời này sang đời khác, thể hiện niềm tin tâm linh và triết lý sống sâu sắc.",
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
            Icons.eco_outlined,
            color: _green.withValues(alpha: 0.75),
            size: 58,
          ),
        ],
      ),
    );
  }
}

void _openCustomDetail(BuildContext context, _CustomItem item) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => _CustomDetailScreen(item: item)),
  );
}

String _normalizeCustomCategory(String value) {
  final text = value.trim();
  if (text == "Tín ngưỡng thờ cúng") return "Tín ngưỡng & tâm linh";
  return text;
}

bool _sameCustomCategory(String a, String b) {
  return _normalizeCustomCategory(a) == _normalizeCustomCategory(b);
}

Future<void> _saveCustomArticle(BuildContext context, _CustomItem item) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList('saved_culture_articles') ?? <String>[];
  final key = '${item.category}|${item.title}';
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

class _CustomCategoryScreen extends StatelessWidget {
  final String category;
  final List<_CustomItem> items;

  const _CustomCategoryScreen({required this.category, required this.items});

  static const Color _ink = CustomsScreen._ink;
  static const Color _red = CustomsScreen._red;
  static const Color _paper = CustomsScreen._paper;

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
                          ? "Tất cả phong tục Dao"
                          : "Phong tục về $category",
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

  Widget _buildRelatedCard(BuildContext context, _CustomItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openCustomDetail(context, item),
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
                child: _customMediaImage(
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
                    _CustomChip(text: item.category),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: _red),
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
        "Chưa có bài phong tục trong danh mục này.",
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

class _CustomDetailScreen extends StatelessWidget {
  final _CustomItem item;

  const _CustomDetailScreen({required this.item});

  static const Color _ink = CustomsScreen._ink;
  static const Color _red = CustomsScreen._red;
  static const Color _paper = CustomsScreen._paper;

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
                    const _SectionTitle("Giới thiệu"),
                    const SizedBox(height: 10),
                    _BodyText(item.intro),
                    if (item.meanings.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      const _SectionTitle("Ý nghĩa"),
                      const SizedBox(height: 12),
                      _buildMeanings(),
                    ],
                    if (item.steps.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      Text(
                        "Các bước trong ${item.title.toLowerCase()}",
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._stepWidgets(),
                    ],
                    if (item.gallery.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const _SectionTitle("Hình ảnh"),
                      const SizedBox(height: 12),
                      _buildGallery(context),
                    ],
                    if (item.videoUrl.trim().isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const _SectionTitle("Video phong tục"),
                      const SizedBox(height: 12),
                      _buildVideoCard(context),
                    ],
                    if (item.warning.trim().isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _buildWarning(),
                    ],
                    if (!item.sources.isEmpty) ...[
                      const SizedBox(height: 24),
                      CultureSourcesCard(
                        sources: item.sources,
                        accentColor: _red,
                      ),
                    ],
                    const SizedBox(height: 24),
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
              onPressed: () => _saveCustom(context),
              icon: const Icon(Icons.bookmark_border_rounded, color: _ink),
            ),
          ),
          Positioned(
            right: 14,
            child: IconButton(
              onPressed: () => _shareCustom(),
              icon: const Icon(Icons.share_outlined, color: _ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          height: 240,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: const Color(0xFFEDE7DE),
                child: _customMediaImage(item.image, fit: BoxFit.contain),
              ),
              Positioned(
                left: 14,
                top: 14,
                child: _CustomChip(text: item.category, dark: true),
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
        _MetaItem(Icons.local_florist_rounded, item.category),
        _MetaItem(Icons.schedule_rounded, "Thời gian: ${item.time}"),
        _MetaItem(Icons.location_on_outlined, "Phổ biến ở: ${item.location}"),
      ],
    );
  }

  Widget _buildMeanings() {
    return Column(
      children: item.meanings.map((meaning) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEDE7DE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(meaning.icon, color: _red, size: 22),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meaning.title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (meaning.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meaning.note,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          height: 1.32,
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
      }).toList(),
    );
  }

  List<Widget> _stepWidgets() {
    final widgets = <Widget>[];
    final showNumbers = item.steps.length > 1;
    for (var i = 0; i < item.steps.length; i++) {
      widgets.add(
        _StepLine(number: i + 1, text: item.steps[i], showNumber: showNumbers),
      );
    }
    return widgets;
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
            onTap: () => _openCustomGallery(context, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _customMediaImage(
                images[index],
                width: 86,
                height: 68,
                fit: BoxFit.contain,
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
                    _customMediaImage(item.image, fit: BoxFit.cover),
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

  void _openCustomGallery(BuildContext context, int initialIndex) {
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
                    child: _customMediaImage(
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
          "Tìm hiểu phong tục khác",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Future<void> _shareCustom() async {
    final intro = _shareSnippet(item.intro);
    final shareText = [
      "Bài viết trên App Văn hóa Dao",
      "",
      item.title,
      if (item.subtitle.trim().isNotEmpty) item.subtitle,
      "",
      "Danh mục: ${item.category}",
      "Thời gian: ${item.time}",
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

  Future<void> _saveCustom(BuildContext context) async {
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
}

String _shareSnippet(String value) {
  final text = value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^["“”:\s]+'), '')
      .trim();
  if (text.length <= 220) return text;
  return "${text.substring(0, 220).trim()}...";
}

class _CustomChip extends StatelessWidget {
  final String text;
  final bool dark;

  const _CustomChip({required this.text, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: dark ? CustomsScreen._red : const Color(0xFFEFF4EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: dark ? Colors.white : const Color(0xFF335A35),
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
          Icon(icon, color: CustomsScreen._green, size: 18),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: CustomsScreen._ink,
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

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: CustomsScreen._ink,
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

class _StepLine extends StatelessWidget {
  final int number;
  final String text;
  final bool showNumber;

  const _StepLine({
    required this.number,
    required this.text,
    this.showNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showNumber) ...[
            Container(
              width: 23,
              height: 23,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: CustomsScreen._red,
                shape: BoxShape.circle,
              ),
              child: Text(
                "$number",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(child: _BodyText(text)),
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

class _CustomCategory {
  final String title;
  final IconData icon;

  const _CustomCategory(this.title, this.icon);
}

class _Meaning {
  final String title;
  final String note;
  final IconData icon;

  const _Meaning(this.title, this.note, this.icon);
}

class _CustomItem {
  final String title;
  final String subtitle;
  final String image;
  final String category;
  final String location;
  final String time;
  final String intro;
  final List<_Meaning> meanings;
  final List<String> steps;
  final String warning;
  final List<String> gallery;
  final String videoUrl;
  final CultureSources sources;

  const _CustomItem({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.category,
    required this.location,
    required this.time,
    required this.intro,
    required this.meanings,
    required this.steps,
    required this.warning,
    this.gallery = const [],
    this.videoUrl = "",
    this.sources = const CultureSources(),
  });

  static _CustomItem? fromAdmin(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().trim();
    if (title.isEmpty) return null;

    final detail = _decodeDetail(data['detail_json']);
    final subtitle = (data['subtitle'] ?? '').toString().trim();
    final image = _normalizeCultureImageUrl(
      (data['image_url'] ?? '').toString().trim(),
    );
    final videoUrl = (data['video_url'] ?? '').toString().trim();
    final content = (data['content'] ?? '').toString().trim();
    final gallery = _toStringList(
      detail['gallery'],
    ).map(_normalizeCultureImageUrl).where((item) => item.isNotEmpty).toList();

    return _CustomItem(
      title: title,
      subtitle: subtitle.isNotEmpty ? subtitle : "Phong tục truyền thống",
      image: image,
      category: _normalizeCustomCategory(
        (detail['category'] ?? "Tín ngưỡng & tâm linh").toString(),
      ),
      location: (detail['location'] ?? "Người Dao").toString(),
      time: (detail['time'] ?? detail['season'] ?? "Theo từng địa phương")
          .toString(),
      intro: content.isNotEmpty ? content : "Nội dung đang được cập nhật.",
      meanings: _meaningsFromDetail(detail['meanings']),
      steps: _toStringList(detail['steps']),
      warning: (detail['warning'] ?? "").toString(),
      gallery: gallery,
      videoUrl: videoUrl,
      sources: CultureSources.fromDetail(detail),
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
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return [];
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) return _toStringList(decoded);
      } catch (_) {}
      return trimmed
          .split(RegExp(r'[\n,;|]'))
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

  static String _normalizeCultureImageUrl(String value) {
    final text = value.trim();
    if (text.isEmpty) return "";
    final normalized = text.replaceAll('\\', '/');

    const marker = '/uploads/culture/';
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

  static List<_Meaning> _meaningsFromDetail(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) {
          final data = Map<String, dynamic>.from(item);
          return _Meaning(
            (data['title'] ?? '').toString(),
            (data['note'] ?? data['text'] ?? '').toString(),
            Icons.auto_awesome_rounded,
          );
        })
        .where((item) => item.title.trim().isNotEmpty)
        .toList();
  }
}

Widget _customMediaImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  final value = path.trim();
  if (value.isEmpty) {
    return _customImageFallback(width, height);
  }
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return Image.network(
      value,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _customImageFallback(width, height),
    );
  }

  return Image.asset(
    value,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => _customImageFallback(width, height),
  );
}

Widget _customImageFallback(double? width, double? height) {
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
