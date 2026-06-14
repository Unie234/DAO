import 'package:flutter/material.dart';

import 'customs_screen.dart';
import 'festival_screen.dart';
import 'herbal_knowledge_screen.dart';
import 'traditional_costume_screen.dart';

class AllCultureCategoriesScreen extends StatelessWidget {
  const AllCultureCategoriesScreen({super.key});

  static const Color _ink = Color(0xFF171B1F);
  static const Color _red = Color(0xFFA72C25);
  static const Color _paper = Color(0xFFFBF8F2);

  List<_CultureCategoryData> get _items => const [
    _CultureCategoryData(
      title: "Trang phục",
      subtitle:
          "Tìm hiểu trang phục truyền thống của người Dao qua hoa văn, màu sắc và ý nghĩa.",
      count: "12 bài viết",
      image: "assets/ao.png",
      visual: "🥻",
    ),
    _CultureCategoryData(
      title: "Lễ hội",
      subtitle:
          "Khám phá các lễ hội truyền thống đặc sắc và ý nghĩa tâm linh của người Dao.",
      count: "8 bài viết",
      image: "assets/khampha2.png",
      visual: "🎊",
    ),
    _CultureCategoryData(
      title: "Phong tục",
      subtitle:
          "Những phong tục, tập quán đặc trưng trong đời sống hằng ngày của người Dao.",
      count: "10 bài viết",
      image: "assets/khampha1.png",
      visual: "🙏",
    ),
    _CultureCategoryData(
      title: "Thảo dược",
      subtitle:
          "Tri thức về cây thuốc dân gian và cách sử dụng trong chữa bệnh của người Dao.",
      count: "6 bài viết",
      image: "assets/khampha3.png",
      visual: "🌿",
    ),
  ];

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
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                child: Column(
                  children: [
                    _buildSearch(),
                    const SizedBox(height: 18),
                    ..._items.map((item) => _buildCategoryCard(context, item)),
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
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink),
            ),
          ),
          const Text(
            "Tất cả danh mục văn hóa",
            style: TextStyle(
              color: _red,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFE7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.grey.shade600, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Tìm kiếm danh mục văn hóa",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, _CultureCategoryData item) {
    return GestureDetector(
      onTap: () => _openCategory(context, item.title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF4E8),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: Image.asset(
                item.image,
                width: 165,
                height: 118,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF7E9E3),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              item.visual,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20, height: 1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4E3C32),
                        fontSize: 13,
                        height: 1.32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.article_outlined,
                          color: Color(0xFF7A4B35),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.count,
                          style: const TextStyle(
                            color: Color(0xFF4E3C32),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF7A4B35),
                          size: 26,
                        ),
                      ],
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

  void _openCategory(BuildContext context, String title) {
    final Widget? screen = switch (title) {
      "Trang phục" => const TraditionalCostumeScreen(),
      "Lễ hội" => const FestivalScreen(),
      "Phong tục" => const CustomsScreen(),
      "Thảo dược" => const HerbalKnowledgeScreen(),
      _ => null,
    };

    if (screen == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _CultureCategoryData {
  final String title;
  final String subtitle;
  final String count;
  final String image;
  final String visual;

  const _CultureCategoryData({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.image,
    required this.visual,
  });
}
