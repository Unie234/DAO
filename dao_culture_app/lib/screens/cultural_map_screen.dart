import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Path;
import '../models/cultural_place.dart';
import '../services/cultural_map_service.dart';
import 'cultural_place_detail_screen.dart';

class CulturalMapScreen extends StatefulWidget {
  const CulturalMapScreen({super.key});

  @override
  State<CulturalMapScreen> createState() => _CulturalMapScreenState();
}

class _CulturalMapScreenState extends State<CulturalMapScreen>
    with WidgetsBindingObserver {
  static const Color _ink = Color(0xFF102321);
  static const Color _paper = Color(0xFFF8F3EA);
  static const Color _red = Color(0xFFD93829);
  static const Color _green = Color(0xFF2F7D3C);
  static const Color _blue = Color(0xFF397FA8);
  static const Color _amber = Color(0xFFE49B2D);

  final MapController _mapController = MapController();
  static const LatLng _defaultMapCenter = LatLng(16.6, 106.2);

  CulturalPlaceType _activeType = CulturalPlaceType.all;
  String _query = "";
  bool _isLoadingPlaces = true;
  bool _usingFallbackPlaces = false;
  final bool _showCultureLayer = true;
  final bool _showServiceLayer = true;
  bool _isLocating = false;
  LatLng? _userLocation;
  CulturalPlace? _selectedRoutePlace;
  List<LatLng> _routePoints = const [];
  bool _isLoadingRoute = false;
  String _selectedRouteDistanceLabel = '';
  String _selectedRouteDurationLabel = '';

  List<CulturalPlace> _places = const [];

  static const List<CulturalPlace> _fallbackPlaces = [
    CulturalPlace(
      name: "Làng văn hóa Dao đỏ",
      address: "Xã Tả Phìn, Sa Pa, Lào Cai",
      distance: "12.5 km",
      shortDescription:
          "Không gian kiến trúc nhà truyền thống, nghề thêu và phong tục sinh hoạt của người Dao đỏ.",
      culturalDescription:
          "Làng văn hóa Dao đỏ là nơi lưu giữ nhiều giá trị văn hóa truyền thống qua kiến trúc nhà trình tường, trang phục thêu tay, nghi lễ cộng đồng và những câu chuyện truyền đời. Du khách có thể tìm hiểu nghề thêu, tắm lá thuốc và đời sống bản địa trong khung cảnh ruộng bậc thang.",
      daoInfo:
          "Người Dao đỏ nổi bật với khăn đội đầu đỏ, hoa văn thêu tinh xảo và tri thức tắm lá thuốc. Các sinh hoạt cộng đồng thường gắn với lễ cấp sắc, chợ phiên và không gian nhà sàn.",
      tag: "Làng văn hóa",
      type: CulturalPlaceType.village,
      mapPosition: Offset(0.30, 0.16),
      icon: Icons.home_work_rounded,
      color: _amber,
      imageAsset: "assets/khampha1.png",
      galleryAssets: [
        "assets/khampha1.png",
        "assets/banner_main.png",
        "assets/anhoduoi.png",
      ],
      latitude: 22.38568,
      longitude: 103.83718,
      hasDirections: true,
    ),
    CulturalPlace(
      name: "Lễ hội Nhảy lửa",
      address: "Hoàng Su Phì, Hà Giang",
      distance: "18.8 km",
      shortDescription:
          "Nghi lễ giàu tính tâm linh, thể hiện niềm tin, sức mạnh và sự gắn kết cộng đồng.",
      culturalDescription:
          "Lễ hội Nhảy lửa là nghi lễ đặc sắc của một số nhóm Dao, thường diễn ra trong không khí linh thiêng với tiếng trống, lời khấn và vòng lửa rực sáng. Nghi lễ phản ánh niềm tin vào sự che chở của thần linh và khát vọng bình an.",
      daoInfo:
          "Trong văn hóa Dao, lửa tượng trưng cho thanh lọc, sức mạnh và sự kết nối giữa con người với thế giới tâm linh.",
      tag: "Lễ hội",
      type: CulturalPlaceType.festival,
      mapPosition: Offset(0.43, 0.12),
      icon: Icons.local_fire_department_rounded,
      color: _red,
      imageAsset: "assets/banner_main.png",
      galleryAssets: [
        "assets/banner_main.png",
        "assets/khampha2.png",
        "assets/ao.png",
      ],
      latitude: 22.7429,
      longitude: 104.6819,
      hasDirections: false,
    ),
    CulturalPlace(
      name: "Vườn thảo dược Dao",
      address: "Ba Vì, Hà Nội",
      distance: "7.2 km",
      shortDescription:
          "Khu trải nghiệm cây thuốc, bài thuốc tắm lá và tri thức chăm sóc sức khỏe dân gian.",
      culturalDescription:
          "Vườn thảo dược giới thiệu những cây thuốc quen thuộc trong đời sống người Dao, từ lá tắm sau sinh đến các bài thuốc chăm sóc xương khớp. Không gian được thiết kế như một hành trình khám phá thiên nhiên và tri thức bản địa.",
      daoInfo:
          "Tri thức thảo dược là một phần quan trọng trong đời sống người Dao, thường được truyền qua nhiều thế hệ trong gia đình.",
      tag: "Thảo dược",
      type: CulturalPlaceType.herb,
      layer: CulturalPlaceLayer.service,
      mapPosition: Offset(0.49, 0.30),
      icon: Icons.eco_rounded,
      color: _green,
      imageAsset: "assets/khampha3.png",
      galleryAssets: [
        "assets/khampha3.png",
        "assets/anhoduoi.png",
        "assets/banner_main.png",
      ],
      latitude: 21.0708,
      longitude: 105.3611,
      hasDirections: true,
    ),
    CulturalPlace(
      name: "Điểm du lịch bản Dao",
      address: "Mẫu Sơn, Lạng Sơn",
      distance: "24.1 km",
      shortDescription:
          "Điểm dừng chân văn hóa kết hợp cảnh quan núi rừng, ẩm thực và chợ phiên.",
      culturalDescription:
          "Điểm du lịch bản Dao tại vùng núi Mẫu Sơn mang lại trải nghiệm khám phá khí hậu mát lành, kiến trúc bản địa, ẩm thực vùng cao và những câu chuyện về đời sống người Dao nơi biên viễn.",
      daoInfo:
          "Các bản Dao vùng Đông Bắc thường gắn với chợ phiên, sản vật núi rừng và những nghi lễ cầu mùa.",
      tag: "Điểm du lịch",
      type: CulturalPlaceType.tourism,
      mapPosition: Offset(0.66, 0.21),
      icon: Icons.photo_camera_rounded,
      color: _blue,
      imageAsset: "assets/anhoduoi.png",
      galleryAssets: [
        "assets/anhoduoi.png",
        "assets/khampha1.png",
        "assets/khampha2.png",
      ],
      latitude: 21.8547,
      longitude: 106.9544,
      hasDirections: true,
    ),
    CulturalPlace(
      name: "Nhà cộng đồng Dao",
      address: "Yên Bái",
      distance: "15.4 km",
      shortDescription:
          "Không gian sinh hoạt chung, trưng bày trang phục, nhạc cụ và ký ức cộng đồng.",
      culturalDescription:
          "Nhà cộng đồng là điểm gặp gỡ, lưu giữ hiện vật và tổ chức các hoạt động truyền dạy văn hóa. Đây là nơi người trẻ có thể học về hoa văn, tiếng nói, nghi lễ và câu chuyện của bản làng.",
      daoInfo:
          "Không gian cộng đồng giúp duy trì ký ức tập thể và kết nối các thế hệ trong văn hóa Dao.",
      tag: "Nhà cộng đồng",
      type: CulturalPlaceType.communityHouse,
      mapPosition: Offset(0.39, 0.26),
      icon: Icons.groups_rounded,
      color: Color(0xFF8B62C8),
      imageAsset: "assets/ao.png",
      galleryAssets: [
        "assets/ao.png",
        "assets/banner_main.png",
        "assets/khampha3.png",
      ],
      latitude: 21.7168,
      longitude: 104.8986,
      hasDirections: false,
    ),
    CulturalPlace(
      name: "Homestay Dao núi xanh",
      address: "Đà Bắc, Hòa Bình",
      distance: "9.6 km",
      shortDescription:
          "Homestay gần gũi thiên nhiên với bữa cơm bản địa, thảo dược và đêm văn nghệ.",
      culturalDescription:
          "Homestay Dao núi xanh hướng đến trải nghiệm chậm rãi: ngủ nhà sàn, thưởng thức món ăn bản địa, nghe kể chuyện văn hóa và đi bộ qua những cung đường núi nhẹ nhàng.",
      daoInfo:
          "Du lịch cộng đồng giúp văn hóa Dao được giới thiệu tự nhiên qua sinh hoạt, ẩm thực, trang phục và cách đón khách.",
      tag: "Homestay",
      type: CulturalPlaceType.homestay,
      layer: CulturalPlaceLayer.service,
      mapPosition: Offset(0.45, 0.35),
      icon: Icons.house_rounded,
      color: Color(0xFFE5B21A),
      imageAsset: "assets/khampha2.png",
      galleryAssets: [
        "assets/khampha2.png",
        "assets/anhoduoi.png",
        "assets/khampha1.png",
      ],
      latitude: 20.8768,
      longitude: 105.1398,
      hasDirections: true,
    ),
    CulturalPlace(
      name: "Tắm lá thuốc Dao đỏ",
      address: "Tả Phìn, Sa Pa, Lào Cai",
      distance: "13.1 km",
      shortDescription:
          "Trải nghiệm bài thuốc tắm lá truyền thống của người Dao đỏ vùng Sa Pa.",
      culturalDescription:
          "Tắm lá thuốc Dao đỏ là tri thức chăm sóc sức khỏe nổi tiếng, sử dụng nhiều loại cây rừng được phối theo kinh nghiệm gia truyền.",
      daoInfo:
          "Bài thuốc tắm thường được truyền trong gia đình, kết hợp hiểu biết về cây rừng, mùa hái lá và cách đun nấu.",
      tag: "Thảo dược",
      type: CulturalPlaceType.herb,
      layer: CulturalPlaceLayer.service,
      mapPosition: Offset(0.28, 0.17),
      icon: Icons.eco_rounded,
      color: _green,
      imageAsset: "assets/khampha3.png",
      galleryAssets: [
        "assets/khampha3.png",
        "assets/khampha1.png",
        "assets/anhoduoi.png",
      ],
      latitude: 22.38568,
      longitude: 103.83718,
      hasDirections: true,
    ),
    CulturalPlace(
      name: "Chợ phiên văn hóa Dao",
      address: "Sa Pa, Lào Cai",
      distance: "14.0 km",
      shortDescription:
          "Không gian giao thương, trang phục thổ cẩm và sản vật vùng cao.",
      culturalDescription:
          "Chợ phiên là nơi gặp gỡ của nhiều cộng đồng vùng cao, trong đó có người Dao, với trang phục, thổ cẩm, sản vật và thảo dược.",
      daoInfo:
          "Chợ phiên giúp văn hóa Dao hiện diện tự nhiên qua trang phục, tiếng nói, thổ cẩm và sản vật bản địa.",
      tag: "Điểm du lịch",
      type: CulturalPlaceType.tourism,
      mapPosition: Offset(0.32, 0.18),
      icon: Icons.photo_camera_rounded,
      color: _blue,
      imageAsset: "assets/anhoduoi.png",
      galleryAssets: [
        "assets/anhoduoi.png",
        "assets/banner_main.png",
        "assets/khampha2.png",
      ],
      latitude: 22.3364,
      longitude: 103.8438,
      hasDirections: true,
    ),
    CulturalPlace(
      name: "Làng Dao Nặm Đăm",
      address: "Quản Bạ, Hà Giang",
      distance: "31.7 km",
      shortDescription:
          "Làng du lịch cộng đồng của người Dao với nhà trình tường và cảnh quan núi đá.",
      culturalDescription:
          "Nặm Đăm là điểm du lịch cộng đồng nổi bật ở Hà Giang, nơi du khách có thể tìm hiểu kiến trúc nhà truyền thống, ẩm thực, thảo dược và sinh hoạt của người Dao.",
      daoInfo:
          "Người Dao ở Quản Bạ gìn giữ nhiều tri thức về nhà ở, nghi lễ gia đình, cây thuốc và du lịch cộng đồng.",
      tag: "Làng văn hóa",
      type: CulturalPlaceType.village,
      mapPosition: Offset(0.48, 0.13),
      icon: Icons.home_work_rounded,
      color: _amber,
      imageAsset: "assets/khampha1.png",
      galleryAssets: [
        "assets/khampha1.png",
        "assets/anhoduoi.png",
        "assets/banner_main.png",
      ],
      latitude: 23.0430,
      longitude: 104.9848,
      hasDirections: true,
    ),
    CulturalPlace(
      name: "Không gian lễ cấp sắc",
      address: "Bắc Hà, Lào Cai",
      distance: "22.3 km",
      shortDescription:
          "Tìm hiểu nghi lễ trưởng thành quan trọng trong đời sống tinh thần người Dao.",
      culturalDescription:
          "Lễ cấp sắc là nghi lễ đánh dấu sự trưởng thành về tâm linh của nam giới Dao, gắn với tranh thờ, lời cúng và vai trò của thầy cúng.",
      daoInfo:
          "Lễ cấp sắc thể hiện quan niệm về đạo đức, trách nhiệm gia đình và sự kết nối với tổ tiên.",
      tag: "Lễ hội",
      type: CulturalPlaceType.festival,
      mapPosition: Offset(0.35, 0.16),
      icon: Icons.local_fire_department_rounded,
      color: _red,
      imageAsset: "assets/banner_main.png",
      galleryAssets: [
        "assets/banner_main.png",
        "assets/ao.png",
        "assets/khampha2.png",
      ],
      latitude: 22.5356,
      longitude: 104.2910,
      hasDirections: false,
    ),
    CulturalPlace(
      name: "Nhà cộng đồng Dao Thanh Y",
      address: "Na Hang, Tuyên Quang",
      distance: "28.6 km",
      shortDescription:
          "Điểm sinh hoạt cộng đồng gắn với truyền dạy trang phục, hát múa và lễ nghi.",
      culturalDescription:
          "Nhà cộng đồng là nơi tổ chức gặp gỡ, biểu diễn văn nghệ, giới thiệu trang phục và lưu giữ ký ức bản làng.",
      daoInfo:
          "Không gian cộng đồng giữ vai trò quan trọng trong truyền dạy phong tục và tạo sự gắn kết giữa các thế hệ.",
      tag: "Nhà cộng đồng",
      type: CulturalPlaceType.communityHouse,
      mapPosition: Offset(0.54, 0.23),
      icon: Icons.groups_rounded,
      color: Color(0xFF8B62C8),
      imageAsset: "assets/ao.png",
      galleryAssets: [
        "assets/ao.png",
        "assets/khampha3.png",
        "assets/banner_main.png",
      ],
      latitude: 22.3475,
      longitude: 105.3958,
      hasDirections: false,
    ),
    CulturalPlace(
      name: "Homestay Dao Hồ Thầu",
      address: "Hoàng Su Phì, Hà Giang",
      distance: "34.2 km",
      shortDescription:
          "Homestay giữa ruộng bậc thang, gần gũi đời sống người Dao vùng núi.",
      culturalDescription:
          "Homestay Dao Hồ Thầu mang đến trải nghiệm lưu trú trong không gian ruộng bậc thang, bữa cơm gia đình, thảo dược và câu chuyện bản địa.",
      daoInfo:
          "Du lịch lưu trú tại bản giúp du khách cảm nhận văn hóa Dao qua sinh hoạt hằng ngày.",
      tag: "Homestay",
      type: CulturalPlaceType.homestay,
      layer: CulturalPlaceLayer.service,
      mapPosition: Offset(0.43, 0.14),
      icon: Icons.house_rounded,
      color: Color(0xFFE5B21A),
      imageAsset: "assets/khampha2.png",
      galleryAssets: [
        "assets/khampha2.png",
        "assets/khampha1.png",
        "assets/anhoduoi.png",
      ],
      latitude: 22.6895,
      longitude: 104.6107,
      hasDirections: true,
    ),
    CulturalPlace(
      name: "Hồ Ba Bể",
      address: "Xã Nam Mẫu, Ba Bể, Bắc Kạn",
      distance: "41.5 km",
      shortDescription: "Điểm du lịch vùng hồ, rừng và bản làng ở Bắc Kạn.",
      culturalDescription:
          "Hồ Ba Bể nằm trong Vườn quốc gia Ba Bể, là điểm du lịch sinh thái nổi bật của Bắc Kạn. Nội dung này được đặt như điểm tham quan vùng văn hóa, không gán là một làng Dao cụ thể.",
      daoInfo:
          "Bắc Kạn có nhiều dân tộc cùng sinh sống, trong đó có người Dao. Với Ba Bể, nên giới thiệu như điểm văn hóa - du lịch vùng hồ nếu chưa có dữ liệu bản Dao cụ thể.",
      tag: "Điểm du lịch",
      type: CulturalPlaceType.tourism,
      mapPosition: Offset(0.58, 0.21),
      icon: Icons.photo_camera_rounded,
      color: _blue,
      imageAsset: "assets/anhoduoi.png",
      galleryAssets: [
        "assets/anhoduoi.png",
        "assets/khampha3.png",
        "assets/banner_main.png",
      ],
      latitude: 22.4167,
      longitude: 105.6167,
      hasDirections: true,
    ),
    CulturalPlace(
      name: "Vườn cây thuốc Dao Yên Bái",
      address: "Nghĩa Lộ, Yên Bái",
      distance: "26.9 km",
      shortDescription:
          "Điểm giới thiệu cây thuốc, lá tắm và tri thức chăm sóc sức khỏe dân gian.",
      culturalDescription:
          "Vườn cây thuốc Dao Yên Bái giới thiệu các loài cây quen thuộc trong chăm sóc sức khỏe, cách thu hái và những câu chuyện truyền nghề.",
      daoInfo:
          "Tri thức cây thuốc là vốn văn hóa sống, gắn với môi trường rừng và kinh nghiệm nhiều thế hệ.",
      tag: "Thảo dược",
      type: CulturalPlaceType.herb,
      layer: CulturalPlaceLayer.service,
      mapPosition: Offset(0.36, 0.29),
      icon: Icons.eco_rounded,
      color: _green,
      imageAsset: "assets/khampha3.png",
      galleryAssets: [
        "assets/khampha3.png",
        "assets/khampha2.png",
        "assets/banner_main.png",
      ],
      latitude: 21.6004,
      longitude: 104.5088,
      hasDirections: false,
    ),
    CulturalPlace(
      name: "Bản Dao Ba Vì",
      address: "Ba Vì, Hà Nội",
      distance: "8.4 km",
      shortDescription:
          "Không gian cộng đồng Dao nổi tiếng với cây thuốc và du lịch cuối tuần.",
      culturalDescription:
          "Bản Dao Ba Vì là nơi du khách dễ tiếp cận để tìm hiểu nghề thuốc, tắm lá, ẩm thực và sinh hoạt cộng đồng của người Dao gần Hà Nội.",
      daoInfo:
          "Cộng đồng Dao Ba Vì được biết đến với nghề thuốc nam và các bài thuốc tắm lá truyền thống.",
      tag: "Làng văn hóa",
      type: CulturalPlaceType.village,
      mapPosition: Offset(0.50, 0.30),
      icon: Icons.home_work_rounded,
      color: _amber,
      imageAsset: "assets/khampha1.png",
      galleryAssets: [
        "assets/khampha1.png",
        "assets/khampha3.png",
        "assets/anhoduoi.png",
      ],
      latitude: 21.0719,
      longitude: 105.3740,
      hasDirections: true,
    ),
    CulturalPlace(
      name: "Không gian Dao Cao Bằng",
      address: "Cao Bằng",
      distance: "Điểm văn hóa",
      shortDescription:
          "Ghim giới thiệu đời sống, trang phục và ký ức cộng đồng Dao vùng Đông Bắc.",
      culturalDescription:
          "Không gian Dao Cao Bằng giới thiệu các nét sinh hoạt cộng đồng, trang phục, chợ phiên và tri thức bản địa của người Dao vùng núi Đông Bắc.",
      daoInfo:
          "Văn hóa Dao ở vùng Đông Bắc gắn với núi rừng, chợ phiên, nghi lễ gia đình và nghề thủ công truyền thống.",
      tag: "Làng văn hóa",
      type: CulturalPlaceType.village,
      mapPosition: Offset(0.59, 0.14),
      icon: Icons.home_work_rounded,
      color: _amber,
      imageAsset: "assets/khampha1.png",
      galleryAssets: [
        "assets/khampha1.png",
        "assets/banner_main.png",
        "assets/ao.png",
      ],
      latitude: 22.6666,
      longitude: 106.2639,
    ),
    CulturalPlace(
      name: "Tri thức Dao Thái Nguyên",
      address: "Thái Nguyên",
      distance: "Điểm văn hóa",
      shortDescription:
          "Nội dung giới thiệu nghề thuốc, sinh hoạt cộng đồng và ký ức bản làng Dao.",
      culturalDescription:
          "Ghim văn hóa Thái Nguyên tập trung vào tri thức dân gian, cây thuốc, sinh hoạt gia đình và sự giao thoa của cộng đồng Dao trong vùng trung du.",
      daoInfo:
          "Các cộng đồng Dao ở trung du giữ nhiều kinh nghiệm về cây thuốc, trang phục và nghi lễ vòng đời.",
      tag: "Thảo dược",
      type: CulturalPlaceType.herb,
      layer: CulturalPlaceLayer.service,
      mapPosition: Offset(0.55, 0.27),
      icon: Icons.eco_rounded,
      color: _green,
      imageAsset: "assets/khampha3.png",
      galleryAssets: [
        "assets/khampha3.png",
        "assets/khampha2.png",
        "assets/banner_main.png",
      ],
      latitude: 21.5942,
      longitude: 105.8482,
    ),
    CulturalPlace(
      name: "Trang phục Dao Phú Thọ",
      address: "Phú Thọ",
      distance: "Điểm văn hóa",
      shortDescription:
          "Ghim giới thiệu hoa văn, khăn áo và câu chuyện trang phục Dao.",
      culturalDescription:
          "Trang phục Dao Phú Thọ nhấn mạnh kỹ thuật thêu, phối màu, khăn đội đầu và cách trang phục kể lại ký ức của cộng đồng.",
      daoInfo:
          "Trang phục là một dấu hiệu nhận diện quan trọng, thể hiện nhóm Dao, tuổi tác, nghi lễ và thẩm mỹ cộng đồng.",
      tag: "Làng văn hóa",
      type: CulturalPlaceType.village,
      mapPosition: Offset(0.44, 0.31),
      icon: Icons.checkroom_rounded,
      color: _amber,
      imageAsset: "assets/ao.png",
      galleryAssets: [
        "assets/ao.png",
        "assets/khampha1.png",
        "assets/banner_main.png",
      ],
      latitude: 21.2684,
      longitude: 105.2045,
    ),
    CulturalPlace(
      name: "Bản Dao Sơn La",
      address: "Sơn La",
      distance: "Điểm văn hóa",
      shortDescription: "Không gian giới thiệu đời sống bản Dao vùng Tây Bắc.",
      culturalDescription:
          "Bản Dao Sơn La giới thiệu mối liên hệ giữa cộng đồng, nương rẫy, nhà ở, chợ phiên và các nghi lễ gia đình trong đời sống miền núi.",
      daoInfo:
          "Văn hóa Dao vùng Tây Bắc gắn với địa hình núi cao, sinh kế nông nghiệp và quan hệ cộng đồng bền chặt.",
      tag: "Làng văn hóa",
      type: CulturalPlaceType.village,
      mapPosition: Offset(0.28, 0.36),
      icon: Icons.home_work_rounded,
      color: _amber,
      imageAsset: "assets/khampha1.png",
      galleryAssets: [
        "assets/khampha1.png",
        "assets/anhoduoi.png",
        "assets/khampha2.png",
      ],
      latitude: 21.1022,
      longitude: 103.7289,
    ),
    CulturalPlace(
      name: "Dao Thanh Hóa",
      address: "Thanh Hóa",
      distance: "Điểm văn hóa",
      shortDescription:
          "Ghim mở rộng bản đồ văn hóa Dao xuống khu vực Bắc Trung Bộ.",
      culturalDescription:
          "Dao Thanh Hóa giới thiệu sự hiện diện của cộng đồng Dao ở vùng chuyển tiếp Bắc Bộ - Bắc Trung Bộ, với sinh hoạt bản làng, trang phục và tri thức dân gian.",
      daoInfo:
          "Bản đồ văn hóa toàn quốc cần thể hiện các vùng cư trú tiêu biểu, không chỉ những điểm du lịch nổi tiếng.",
      tag: "Nhà cộng đồng",
      type: CulturalPlaceType.communityHouse,
      mapPosition: Offset(0.49, 0.47),
      icon: Icons.groups_rounded,
      color: Color(0xFF8B62C8),
      imageAsset: "assets/banner_main.png",
      galleryAssets: [
        "assets/banner_main.png",
        "assets/ao.png",
        "assets/khampha3.png",
      ],
      latitude: 19.8067,
      longitude: 105.7852,
    ),
    CulturalPlace(
      name: "Dao Nghệ An",
      address: "Nghệ An",
      distance: "Điểm văn hóa",
      shortDescription: "Ghim giới thiệu tuyến văn hóa Dao ở Bắc Trung Bộ.",
      culturalDescription:
          "Dao Nghệ An là điểm nội dung văn hóa để mở rộng bản đồ xuống phía Nam hơn, giới thiệu đời sống cộng đồng, tri thức dân gian và sinh hoạt vùng núi.",
      daoInfo:
          "Các điểm cấp tỉnh giúp người dùng nhận biết vùng phân bố và câu chuyện văn hóa, không nhất thiết là điểm du lịch cụ thể.",
      tag: "Điểm du lịch",
      type: CulturalPlaceType.tourism,
      mapPosition: Offset(0.53, 0.55),
      icon: Icons.travel_explore_rounded,
      color: _blue,
      imageAsset: "assets/anhoduoi.png",
      galleryAssets: [
        "assets/anhoduoi.png",
        "assets/khampha1.png",
        "assets/banner_main.png",
      ],
      latitude: 19.2342,
      longitude: 104.9200,
    ),
    CulturalPlace(
      name: "Dao Quảng Ninh",
      address: "Quảng Ninh",
      distance: "Điểm văn hóa",
      shortDescription:
          "Ghim giới thiệu cộng đồng Dao vùng Đông Bắc ven biển và miền núi.",
      culturalDescription:
          "Dao Quảng Ninh giới thiệu sự kết nối giữa miền núi Đông Bắc, chợ phiên, nghề thủ công, trang phục và các sinh hoạt văn hóa địa phương.",
      daoInfo:
          "Vùng Đông Bắc có nhiều cộng đồng Dao với sắc thái văn hóa đa dạng, cần được thể hiện như các vùng văn hóa trên bản đồ.",
      tag: "Điểm du lịch",
      type: CulturalPlaceType.tourism,
      mapPosition: Offset(0.72, 0.29),
      icon: Icons.photo_camera_rounded,
      color: _blue,
      imageAsset: "assets/anhoduoi.png",
      galleryAssets: [
        "assets/anhoduoi.png",
        "assets/khampha2.png",
        "assets/banner_main.png",
      ],
      latitude: 21.0064,
      longitude: 107.2925,
    ),
    CulturalPlace(
      name: "Vùng tham khảo Hà Tĩnh",
      address: "Hà Tĩnh",
      distance: "Điểm văn hóa",
      shortDescription:
          "Ghim mở rộng bản đồ văn hóa Dao xuống khu vực Bắc Trung Bộ.",
      culturalDescription:
          "Dao Hà Tĩnh giúp bản đồ thể hiện tuyến hiện diện văn hóa xuống miền Trung, tập trung vào câu chuyện cư trú, sinh hoạt cộng đồng và ký ức bản làng.",
      daoInfo:
          "Các điểm cấp tỉnh dùng để định hướng vùng văn hóa tham khảo, không phải lúc nào cũng là điểm du lịch cụ thể.",
      tag: "Vùng tham khảo",
      type: CulturalPlaceType.communityHouse,
      mapPosition: Offset(0.55, 0.63),
      icon: Icons.groups_rounded,
      color: Color(0xFF8B62C8),
      imageAsset: "assets/banner_main.png",
      galleryAssets: [
        "assets/banner_main.png",
        "assets/ao.png",
        "assets/khampha1.png",
      ],
      latitude: 18.3559,
      longitude: 105.8877,
    ),
    CulturalPlace(
      name: "Vùng tham khảo Quảng Bình",
      address: "Quảng Bình",
      distance: "Điểm văn hóa",
      shortDescription: "Ghim mở rộng vùng quan sát văn hóa Dao ở miền Trung.",
      culturalDescription:
          "Ghim Quảng Bình là điểm tham khảo trên bản đồ toàn quốc, giúp người dùng nhìn thấy phạm vi mở rộng thay vì chỉ tập trung tại các tỉnh miền núi phía Bắc.",
      daoInfo:
          "Với điểm vùng văn hóa, nội dung ưu tiên giới thiệu bối cảnh, câu chuyện cộng đồng và hướng tìm hiểu thêm.",
      tag: "Vùng tham khảo",
      type: CulturalPlaceType.tourism,
      mapPosition: Offset(0.59, 0.70),
      icon: Icons.photo_camera_rounded,
      color: _blue,
      imageAsset: "assets/anhoduoi.png",
      galleryAssets: [
        "assets/anhoduoi.png",
        "assets/banner_main.png",
        "assets/khampha2.png",
      ],
      latitude: 17.6102,
      longitude: 106.3487,
    ),
    CulturalPlace(
      name: "Cộng đồng Dao Thôn 3 Cư Suê",
      address: "Thôn 3, xã Cư Suê, Cư M'gar, Đắk Lắk",
      distance: "Điểm văn hóa",
      shortDescription:
          "Điểm giới thiệu cộng đồng người Dao tại Thôn 3, xã Cư Suê.",
      culturalDescription:
          "Thôn 3, xã Cư Suê là một điểm cư trú của người Dao tại Cư M'gar, Đắk Lắk, góp thêm lát cắt văn hóa Tây Nguyên vào bản đồ.",
      daoInfo:
          "Người Dao ở Cư Suê vẫn gìn giữ nhiều nét văn hóa qua gia đình, lễ nghi, câu chuyện cộng đồng và sự kết nối với quê gốc.",
      tag: "Làng văn hóa",
      type: CulturalPlaceType.village,
      mapPosition: Offset(0.66, 0.86),
      icon: Icons.home_work_rounded,
      color: _amber,
      imageAsset: "assets/khampha1.png",
      galleryAssets: [
        "assets/khampha1.png",
        "assets/ao.png",
        "assets/banner_main.png",
      ],
      latitude: 12.7580,
      longitude: 108.0448,
      hasDirections: true,
    ),
    CulturalPlace(
      name: "Cộng đồng Dao Thôn 5 Cư Suê",
      address: "Thôn 5, xã Cư Suê, Cư M'gar, Đắk Lắk",
      distance: "Điểm văn hóa",
      shortDescription:
          "Điểm giới thiệu cộng đồng người Dao tại Thôn 5, xã Cư Suê.",
      culturalDescription:
          "Thôn 5, xã Cư Suê là một điểm cộng đồng người Dao tại Cư M'gar, góp phần làm rõ sự hiện diện của người Dao tại Đắk Lắk.",
      daoInfo:
          "Các cộng đồng người Dao tại Cư Suê góp phần làm phong phú bức tranh văn hóa các dân tộc ở Tây Nguyên.",
      tag: "Làng văn hóa",
      type: CulturalPlaceType.village,
      mapPosition: Offset(0.65, 0.87),
      icon: Icons.home_work_rounded,
      color: _amber,
      imageAsset: "assets/khampha1.png",
      galleryAssets: [
        "assets/khampha1.png",
        "assets/khampha3.png",
        "assets/banner_main.png",
      ],
      latitude: 12.7337,
      longitude: 108.0160,
      hasDirections: true,
    ),
    CulturalPlace(
      name: "Cộng đồng Dao thôn Ea Mô",
      address: "Thôn Ea Mô, xã Cư Suê, Cư M'gar, Đắk Lắk",
      distance: "Điểm văn hóa",
      shortDescription:
          "Điểm giới thiệu thôn Ea Mô, xã Cư Suê, nơi có cộng đồng người Dao sinh sống.",
      culturalDescription:
          "Thôn Ea Mô, xã Cư Suê là một địa danh văn hóa tại Cư M'gar, Đắk Lắk, được bổ sung để bản đồ phản ánh đúng hơn cộng đồng người Dao ở địa phương.",
      daoInfo:
          "Thôn Ea Mô từng được nhắc đến như một thôn văn hóa của xã Cư Suê, gắn với đời sống cộng đồng tại Cư M'gar.",
      tag: "Nhà cộng đồng",
      type: CulturalPlaceType.communityHouse,
      mapPosition: Offset(0.66, 0.86),
      icon: Icons.groups_rounded,
      color: Color(0xFF8B62C8),
      imageAsset: "assets/ao.png",
      galleryAssets: [
        "assets/ao.png",
        "assets/khampha3.png",
        "assets/banner_main.png",
      ],
      latitude: 12.7520,
      longitude: 108.0520,
      hasDirections: true,
    ),
    CulturalPlace(
      name: "Cafe A Mé - Tắm thuốc người Dao",
      address: "Xã Cư Suê, Cư M'gar, Đắk Lắk",
      distance: "Dịch vụ trải nghiệm",
      shortDescription:
          "Địa điểm cafe kết hợp trải nghiệm tắm thuốc người Dao tại Cư Suê.",
      culturalDescription:
          "Điểm trải nghiệm giúp người dùng tìm hiểu đời sống văn hóa người Dao tại Đắk Lắk qua không gian cafe, thảo dược và dịch vụ tắm thuốc.",
      daoInfo:
          "Tắm thuốc là tri thức thảo dược gắn với chăm sóc sức khỏe trong văn hóa người Dao.",
      tag: "Trải nghiệm",
      type: CulturalPlaceType.herb,
      layer: CulturalPlaceLayer.service,
      mapPosition: Offset(0.67, 0.87),
      icon: Icons.spa_rounded,
      color: _green,
      latitude: 12.7550,
      longitude: 108.0500,
      hasDirections: true,
      googleMapsUrl: "https://maps.app.goo.gl/sRffjm6GwPVbGX1B9",
    ),
    CulturalPlace(
      name: "Cộng đồng Dao xã Ea Tar",
      address: "Khu vực xã Ea Tar cũ, nay thuộc xã Ea Tul, tỉnh Đắk Lắk",
      distance: "Điểm văn hóa tham khảo",
      shortDescription:
          "Điểm giới thiệu khu vực xã Ea Tar, nơi có cộng đồng người Dao sinh sống.",
      culturalDescription:
          "Khu vực xã Ea Tar cũ, nay thuộc xã Ea Tul, tỉnh Đắk Lắk là nơi có người Dao sinh sống. Nội dung này được đặt như một điểm văn hóa tham khảo cấp xã, chưa gắn với một thôn hoặc địa chỉ cụ thể.",
      daoInfo:
          "Khi chưa có dữ liệu địa chỉ chính xác, điểm Ea Tar nên được giới thiệu ở mức khu vực để tránh hiểu nhầm là địa điểm chỉ đường đã được xác minh.",
      tag: "Làng văn hóa",
      type: CulturalPlaceType.village,
      mapPosition: Offset(0.67, 0.84),
      icon: Icons.home_work_rounded,
      color: _amber,
      imageAsset: "assets/khampha1.png",
      galleryAssets: [
        "assets/khampha1.png",
        "assets/ao.png",
        "assets/banner_main.png",
      ],
      latitude: 12.9322,
      longitude: 108.1016,
      hasDirections: false,
    ),
    CulturalPlace(
      name: "Vùng tham khảo Đắk Nông",
      address: "Đắk Nông",
      distance: "Điểm văn hóa",
      shortDescription:
          "Điểm văn hóa cho khu vực Tây Nguyên trên bản đồ văn hóa toàn quốc.",
      culturalDescription:
          "Ghim Đắk Nông giúp bản đồ có thêm điểm nhìn về khu vực Tây Nguyên, phù hợp khi ứng dụng muốn thể hiện phạm vi toàn quốc và các vùng văn hóa tham khảo.",
      daoInfo:
          "Các điểm phía Nam được đặt là Điểm văn hóa để tránh hiểu nhầm là địa điểm du lịch đã xác minh chi tiết.",
      tag: "Vùng tham khảo",
      type: CulturalPlaceType.village,
      mapPosition: Offset(0.63, 0.86),
      icon: Icons.home_work_rounded,
      color: _amber,
      imageAsset: "assets/khampha1.png",
      galleryAssets: [
        "assets/khampha1.png",
        "assets/banner_main.png",
        "assets/anhoduoi.png",
      ],
      latitude: 12.2646,
      longitude: 107.6098,
    ),
    CulturalPlace(
      name: "Vùng tham khảo Lâm Đồng",
      address: "Lâm Đồng",
      distance: "Điểm văn hóa",
      shortDescription: "Ghim mở rộng bản đồ xuống Nam Tây Nguyên.",
      culturalDescription:
          "Ghim Lâm Đồng bổ sung góc nhìn phía Nam cho bản đồ văn hóa, giúp người dùng nhận ra ứng dụng không chỉ giới hạn ở các tỉnh phía Bắc.",
      daoInfo:
          "Khi chưa có điểm cụ thể, điểm tỉnh nên được dùng như điểm nội dung tham khảo thay vì điểm chỉ đường.",
      tag: "Vùng tham khảo",
      type: CulturalPlaceType.tourism,
      mapPosition: Offset(0.67, 0.91),
      icon: Icons.photo_camera_rounded,
      color: _blue,
      imageAsset: "assets/anhoduoi.png",
      galleryAssets: [
        "assets/anhoduoi.png",
        "assets/khampha2.png",
        "assets/banner_main.png",
      ],
      latitude: 11.5753,
      longitude: 108.1429,
    ),
    CulturalPlace(
      name: "Vùng tham khảo Bình Phước",
      address: "Bình Phước",
      distance: "Điểm văn hóa",
      shortDescription: "Ghim phía Nam giúp cân bằng bản đồ văn hóa toàn quốc.",
      culturalDescription:
          "Ghim Bình Phước là điểm mở rộng cho vùng Đông Nam Bộ, phục vụ mục tiêu trình bày bản đồ trên phạm vi cả nước.",
      daoInfo:
          "Các điểm phía Nam có thể được thay bằng địa điểm cụ thể hơn khi bạn có dữ liệu khảo sát hoặc nguồn địa phương.",
      tag: "Vùng tham khảo",
      type: CulturalPlaceType.communityHouse,
      mapPosition: Offset(0.61, 0.94),
      icon: Icons.groups_rounded,
      color: Color(0xFF8B62C8),
      imageAsset: "assets/banner_main.png",
      galleryAssets: [
        "assets/banner_main.png",
        "assets/ao.png",
        "assets/khampha3.png",
      ],
      latitude: 11.7512,
      longitude: 106.7235,
    ),
  ];

  List<CulturalPlace> get _visiblePlaces {
    final filtered = _places.where((place) {
      if (_isReferencePlace(place)) return false;

      final matchesType =
          _activeType == CulturalPlaceType.all || place.type == _activeType;
      final matchesLayer =
          (place.layer == CulturalPlaceLayer.culture && _showCultureLayer) ||
          (place.layer == CulturalPlaceLayer.service && _showServiceLayer);
      final matchesQuery =
          _query.trim().isEmpty ||
          place.name.toLowerCase().contains(_query.toLowerCase()) ||
          place.address.toLowerCase().contains(_query.toLowerCase()) ||
          place.tag.toLowerCase().contains(_query.toLowerCase());
      return matchesType && matchesLayer && matchesQuery;
    }).toList();

    return filtered;
  }

  bool _isReferencePlace(CulturalPlace place) {
    final name = place.name.toLowerCase();
    final address = place.address.toLowerCase();
    final tag = place.tag.toLowerCase();
    final description = place.daoInfo.toLowerCase();
    if (name.contains("ea tar") ||
        name.contains("ea tul") ||
        address.contains("ea tar") ||
        address.contains("ea tul")) {
      return false;
    }
    return name.contains("vùng tham khảo") ||
        tag.contains("vùng tham khảo") ||
        description.contains("điểm nội dung tham khảo") ||
        description.contains("điểm vùng văn hóa");
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _places = _fallbackPlaces;
    _loadPlaces();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPlaces();
    }
  }

  Future<void> _loadPlaces() async {
    final apiPlaces = await CulturalMapService.getPlaces();
    if (!mounted) return;

    setState(() {
      _places = apiPlaces.isEmpty
          ? _fallbackPlaces
          : _mergeApiAndFallbackPlaces(apiPlaces);
      _usingFallbackPlaces = apiPlaces.isEmpty;
      _isLoadingPlaces = false;
    });
  }

  Future<CulturalPlace> _freshPlaceForDetail(CulturalPlace place) async {
    await _loadPlaces();
    if (!mounted) return place;
    return _places.firstWhere(
      (item) => _isSameMapPlace(item, place),
      orElse: () => place,
    );
  }

  List<CulturalPlace> _mergeApiAndFallbackPlaces(
    List<CulturalPlace> apiPlaces,
  ) {
    final merged = <CulturalPlace>[...apiPlaces];
    for (final fallback in _fallbackPlaces) {
      final exists = merged.any((place) => _isSameMapPlace(place, fallback));
      if (!exists) merged.add(fallback);
    }
    return merged;
  }

  bool _isSameMapPlace(CulturalPlace first, CulturalPlace second) {
    final firstName = _normalizeMapPlaceText(first.name);
    final secondName = _normalizeMapPlaceText(second.name);
    if (firstName == secondName) return true;

    if (first.latitude != 0 &&
        first.longitude != 0 &&
        second.latitude != 0 &&
        second.longitude != 0 &&
        (first.latitude - second.latitude).abs() < 0.0008 &&
        (first.longitude - second.longitude).abs() < 0.0008) {
      return true;
    }

    final firstText = _normalizeMapPlaceText("${first.name} ${first.address}");
    final secondText = _normalizeMapPlaceText(
      "${second.name} ${second.address}",
    );
    const anchors = ['a me', 'thon 3', 'thon 5', 'ea mo', 'ea tar', 'ea tul'];
    return anchors.any(
      (anchor) => firstText.contains(anchor) && secondText.contains(anchor),
    );
  }

  String _normalizeMapPlaceText(String value) {
    final lower = value.toLowerCase();
    final noAccent = lower
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll('đ', 'd');
    return noAccent.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  Future<void> _loadCurrentLocation({bool moveCamera = false}) async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) _showSnack("Vui lòng bật định vị để xem vị trí hiện tại.");
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) _showSnack("Ứng dụng chưa được cấp quyền định vị.");
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final location = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() => _userLocation = location);
      if (moveCamera) _moveCameraToVisibleLocation(location);
    } catch (_) {
      if (mounted) _showSnack("Không lấy được vị trí hiện tại.");
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _moveCameraToVisibleLocation(LatLng location) {
    if (_routePoints.length >= 2) {
      final screenHeight = MediaQuery.sizeOf(context).height;
      final bottomSheetSpace = (screenHeight * 0.55).clamp(420.0, 560.0);

      _mapController.rotate(0);
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: _routePoints,
          padding: EdgeInsets.fromLTRB(56, 180, 56, bottomSheetSpace),
          maxZoom: 11,
        ),
      );
      return;
    }

    const targetZoom = 13.0;
    const centerOffsetLatitude = 0.004;
    final visibleCenter = LatLng(
      location.latitude - centerOffsetLatitude,
      location.longitude,
    );
    _mapController.moveAndRotate(visibleCenter, targetZoom, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned.fill(child: _buildMapCanvas()),
            Positioned(
              left: 18,
              right: 18,
              top: MediaQuery.of(context).padding.top + 16,
              child: _buildSearchAndFilter(),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 24,
              child: _buildNearbyPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: Colors.grey.shade600),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: "Tìm kiếm địa điểm văn hóa...",
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildCircleButton(
          _isLocating ? Icons.hourglass_top_rounded : Icons.my_location_rounded,
          () => _loadCurrentLocation(moveCamera: true),
          tooltip: "Vị trí của bạn",
        ),
        const SizedBox(width: 10),
        _buildCircleButton(
          Icons.tune_rounded,
          _showFilterSheet,
          tooltip: "Lọc địa điểm",
        ),
      ],
    );
  }

  Widget _buildMapCanvas() {
    final markers = <Marker>[
      ..._visiblePlaces.map(
        (place) => Marker(
          point: _placeLatLng(place),
          width: 92,
          height: 64,
          alignment: Alignment.topCenter,
          child: _buildMarker(place),
        ),
      ),
      if (_userLocation != null)
        Marker(
          point: _userLocation!,
          width: 54,
          height: 54,
          child: _buildUserLocationMarker(),
        ),
      if (_routePoints.length >= 2) ...[
        Marker(
          point: _routePoints.first,
          width: 42,
          height: 42,
          child: _buildRouteEndpointMarker(
            icon: Icons.person_pin_circle_rounded,
            color: _blue,
          ),
        ),
        Marker(
          point: _routePoints.last,
          width: 42,
          height: 42,
          child: _buildRouteEndpointMarker(
            icon: Icons.flag_rounded,
            color: _red,
          ),
        ),
      ],
    ];

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _defaultMapCenter,
            initialZoom: 5,
            minZoom: 4,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              retinaMode: RetinaMode.isHighDensity(context),
              userAgentPackageName: 'com.dao.culture.app',
            ),
            if (_routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(points: _routePoints, color: _red, strokeWidth: 5),
                ],
              ),
            MarkerLayer(markers: markers),
          ],
        ),
        if (_isLoadingPlaces)
          Positioned(
            left: 18,
            right: 18,
            top: MediaQuery.of(context).padding.top + 146,
            child: _buildMapNotice("Đang tải địa điểm văn hóa Dao..."),
          )
        else if (_usingFallbackPlaces)
          Positioned(
            left: 18,
            right: 18,
            top: MediaQuery.of(context).padding.top + 146,
            child: _buildMapNotice(
              "Đang dùng dữ liệu mẫu. Bật backend để tải địa điểm thật.",
            ),
          ),
      ],
    );
  }

  LatLng _placeLatLng(CulturalPlace place) {
    if (place.latitude != 0 && place.longitude != 0) {
      return LatLng(place.latitude, place.longitude);
    }
    return _defaultMapCenter;
  }

  double? _distanceMeters(CulturalPlace place) {
    if (_userLocation == null || place.latitude == 0 || place.longitude == 0) {
      return null;
    }

    return const Distance().as(
      LengthUnit.Meter,
      _userLocation!,
      _placeLatLng(place),
    );
  }

  List<CulturalPlace> get _nearbyPlaces {
    final places = _visiblePlaces
        .where((place) => place.latitude != 0 && place.longitude != 0)
        .toList();
    if (_userLocation == null) return places.take(3).toList();

    places.sort((a, b) {
      final distanceA = _distanceMeters(a) ?? double.infinity;
      final distanceB = _distanceMeters(b) ?? double.infinity;
      return distanceA.compareTo(distanceB);
    });
    return places.take(3).toList();
  }

  String _distanceLabel(CulturalPlace place) {
    if (_userLocation == null || place.latitude == 0 || place.longitude == 0) {
      return place.distance.isNotEmpty ? place.distance : "Chưa có vị trí";
    }

    final meters = _distanceMeters(place) ?? 0;
    if (meters < 1000) return "${meters.round()} m";
    return "${(meters / 1000).toStringAsFixed(1)} km";
  }

  String get _activeFilterLabel {
    for (final item in _filterItems) {
      if (item.type == _activeType) return item.label;
    }
    return "Tất cả";
  }

  void _clearRoute() {
    setState(() {
      _selectedRoutePlace = null;
      _routePoints = const [];
      _selectedRouteDistanceLabel = '';
      _selectedRouteDurationLabel = '';
    });
  }

  String _routeDistanceLabel(dynamic value) {
    final meters = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (meters == null || meters <= 0) return '';
    if (meters < 1000) return "${meters.round()} m";
    return "${(meters / 1000).toStringAsFixed(1)} km";
  }

  String _routeDurationLabel(dynamic value) {
    final seconds = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (seconds == null || seconds <= 0) return '';
    final minutes = (seconds / 60).round();
    if (minutes < 60) return "$minutes phút";
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return remaining == 0 ? "$hours giờ" : "$hours giờ $remaining phút";
  }

  Widget _buildUserLocationMarker() {
    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _blue.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: _blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteEndpointMarker({
    required IconData icon,
    required Color color,
  }) {
    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 19),
      ),
    );
  }

  Widget _buildMapNotice(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _isLoadingPlaces ? Icons.cloud_sync_rounded : Icons.info_rounded,
            color: _isLoadingPlaces ? _blue : _amber,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarker(CulturalPlace place) {
    final layerColor = place.layer == CulturalPlaceLayer.service
        ? _green
        : _red;
    final isRouteTarget =
        _selectedRoutePlace?.name == place.name &&
        _selectedRoutePlace?.address == place.address;
    return GestureDetector(
      onTap: () => _showPlaceSheet(place),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isRouteTarget
                    ? _red
                    : layerColor.withValues(alpha: 0.72),
                width: isRouteTarget ? 4 : 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: place.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(place.icon, color: Colors.white, size: 16),
              ),
            ),
          ),
          if (isRouteTarget) ...[
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxWidth: 86),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _red.withValues(alpha: 0.32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 9.8,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircleButton(
    IconData icon,
    VoidCallback onTap, {
    String? tooltip,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      elevation: 7,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip ?? "",
          child: SizedBox(
            width: 54,
            height: 54,
            child: Icon(icon, color: _ink, size: 26),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyPanel() {
    final nearby = _nearbyPlaces;
    final hasLocation = _userLocation != null;
    final hasRoute = _selectedRouteDistanceLabel.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: (hasRoute ? _red : _blue).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasRoute ? Icons.route_rounded : Icons.my_location_rounded,
                  color: hasRoute ? _red : _blue,
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  hasRoute
                      ? "Đường đi trong app"
                      : hasLocation
                      ? "Địa điểm Dao gần bạn"
                      : "Bấm định vị để xem điểm gần bạn",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (!hasRoute && _activeType != CulturalPlaceType.all)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F2EA),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    _activeFilterLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              if (hasRoute)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: "Xóa tuyến đường",
                  onPressed: _clearRoute,
                  icon: const Icon(Icons.close_rounded, color: _ink, size: 20),
                ),
              if (_isLoadingRoute)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _red),
                ),
            ],
          ),
          if (hasRoute)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _red.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded, color: _red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${_selectedRoutePlace?.name ?? "Điểm đến"} - $_selectedRouteDistanceLabel${_selectedRouteDurationLabel.isEmpty ? "" : " - $_selectedRouteDurationLabel"}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 12.2,
                          height: 1.25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (hasLocation)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "Khoảng cách có dấu ≈ là ước tính gần đúng. Bấm địa điểm để vẽ đường đi.",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ink.withValues(alpha: 0.58),
                  fontSize: 10.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (nearby.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildFeaturedNearbyPlace(nearby.first),
            if (nearby.length > 1) ...[
              const SizedBox(height: 3),
              ...nearby.skip(1).map((place) => _buildNearbyPlaceRow(place)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturedNearbyPlace(CulturalPlace place) {
    final selected =
        _selectedRoutePlace?.name == place.name &&
        _selectedRoutePlace?.address == place.address;
    final distanceText = selected && _selectedRouteDistanceLabel.isNotEmpty
        ? _selectedRouteDistanceLabel
        : "≈ ${_distanceLabel(place)}";

    return InkWell(
      onTap: () => _showRouteToPlace(place),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? _red.withValues(alpha: 0.10)
              : const Color(0xFFF7F2EA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? _red.withValues(alpha: 0.32)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            _MapPlaceImage(place: place, width: 74, height: 64, radius: 14),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: place.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          place.tag,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: place.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        distanceText,
                        style: const TextStyle(
                          color: _red,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    selected && _selectedRouteDurationLabel.isNotEmpty
                        ? "Tuyến đường: $_selectedRouteDurationLabel"
                        : _mapEventText(place),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.65),
                      fontSize: 11.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? _red : _ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyPlaceRow(CulturalPlace place) {
    final selected =
        _selectedRoutePlace?.name == place.name &&
        _selectedRoutePlace?.address == place.address;
    final eventText = _mapEventText(place);
    final distanceText = selected && _selectedRouteDistanceLabel.isNotEmpty
        ? _selectedRouteDistanceLabel
        : "≈ ${_distanceLabel(place)}";
    final secondaryText = selected && _selectedRouteDurationLabel.isNotEmpty
        ? "Tuyến đường: $_selectedRouteDurationLabel"
        : eventText;

    return InkWell(
      onTap: () => _showRouteToPlace(place),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        margin: const EdgeInsets.only(top: 7),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? _red.withValues(alpha: 0.10)
              : const Color(0xFFF7F2EA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? _red.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            _MapPlaceImage(place: place, width: 44, height: 44, radius: 12),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    secondaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.68),
                      fontSize: 11.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  distanceText,
                  style: const TextStyle(
                    color: _red,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  selected ? Icons.route_rounded : Icons.touch_app_rounded,
                  color: selected ? _red : _ink.withValues(alpha: 0.45),
                  size: 15,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _mapEventText(CulturalPlace place) {
    if (place.type == CulturalPlaceType.festival) {
      return "Lễ hội / nghi lễ: ${place.name}";
    }
    if (place.type == CulturalPlaceType.herb) {
      return "Trải nghiệm: cây thuốc, lá tắm Dao";
    }
    if (place.type == CulturalPlaceType.homestay) {
      return "Trải nghiệm: lưu trú, ẩm thực, sinh hoạt bản Dao";
    }
    if (place.type == CulturalPlaceType.tourism) {
      return "Có: thổ cẩm, chợ phiên, sản vật vùng Dao";
    }
    if (place.type == CulturalPlaceType.communityHouse) {
      return "Có: sinh hoạt cộng đồng, trang phục, lễ nghi";
    }
    return "Bản Dao / không gian văn hóa gần bạn";
  }

  void _showPlaceSheet(CulturalPlace place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PlacePreviewSheet(
          place: place,
          distanceLabel: _distanceLabel(place),
          onDetail: () async {
            final navigator = Navigator.of(context);
            navigator.pop();
            final detailPlace = await _freshPlaceForDetail(place);
            if (!mounted) return;
            navigator.push(
              MaterialPageRoute(
                builder: (_) => CulturalPlaceDetailScreen(place: detailPlace),
              ),
            );
          },
          onDirections: () {
            Navigator.pop(context);
            _showRouteToPlace(place);
          },
        );
      },
    );
  }

  Future<void> _showRouteToPlace(CulturalPlace place) async {
    if (place.latitude == 0 || place.longitude == 0) {
      _showSnack("Địa điểm này chưa có tọa độ chỉ đường.");
      return;
    }

    if (_userLocation == null) {
      await _loadCurrentLocation(moveCamera: false);
      if (_userLocation == null) {
        _showSnack("Chưa lấy được vị trí của bạn để chỉ đường.");
        return;
      }
    }

    setState(() {
      _isLoadingRoute = true;
      _selectedRoutePlace = place;
      _routePoints = const [];
      _selectedRouteDistanceLabel = '';
      _selectedRouteDurationLabel = '';
    });

    try {
      final start = _userLocation!;
      final destination = _placeLatLng(place);
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&steps=false',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw Exception("routing ${response.statusCode}");
      }

      final decoded = jsonDecode(response.body);
      final routes = decoded is Map ? decoded['routes'] : null;
      final firstRoute = routes is List && routes.isNotEmpty
          ? routes.first
          : null;
      final geometry = firstRoute is Map ? firstRoute['geometry'] : null;
      final coordinates = geometry is Map ? geometry['coordinates'] : null;
      if (coordinates is! List || coordinates.length < 2) {
        throw Exception("empty route");
      }
      final routeDistance = firstRoute is Map ? firstRoute['distance'] : null;
      final routeDuration = firstRoute is Map ? firstRoute['duration'] : null;

      final route = coordinates
          .whereType<List>()
          .where((point) => point.length >= 2)
          .map(
            (point) => LatLng(
              (point[1] as num).toDouble(),
              (point[0] as num).toDouble(),
            ),
          )
          .toList();

      if (!mounted || route.length < 2) return;
      setState(() {
        _routePoints = route;
        _selectedRouteDistanceLabel = _routeDistanceLabel(routeDistance);
        _selectedRouteDurationLabel = _routeDurationLabel(routeDuration);
      });
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: [start, destination, ...route],
          padding: const EdgeInsets.fromLTRB(48, 150, 48, 250),
        ),
      );
    } catch (_) {
      if (mounted) {
        _showSnack("Chưa tải được tuyến đường. Vui lòng thử lại sau.");
      }
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  void _showFilterSheet() {
    var selected = _activeType;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
              decoration: const BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Bộ lọc điểm văn hóa",
                            style: TextStyle(
                              color: _ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 18,
                      runSpacing: 20,
                      children: _filterItems.map((item) {
                        final isActive = selected == item.type;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => selected = item.type);
                            setState(() {
                              _activeType = item.type;
                              _selectedRoutePlace = null;
                              _routePoints = const [];
                              _selectedRouteDistanceLabel = '';
                              _selectedRouteDurationLabel = '';
                            });
                            Navigator.pop(context);
                          },
                          child: SizedBox(
                            width: 86,
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    color: isActive ? item.color : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: item.color.withValues(
                                          alpha: 0.18,
                                        ),
                                        blurRadius: 14,
                                        offset: const Offset(0, 7),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: isActive ? Colors.white : item.color,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                Text(
                                  item.label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _MapPlaceImage extends StatelessWidget {
  final CulturalPlace place;
  final double width;
  final double height;
  final double radius;

  const _MapPlaceImage({
    required this.place,
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = place.imageUrl.trim().isNotEmpty
        ? place.imageUrl.trim()
        : place.galleryUrls
              .map((item) => item.trim())
              .firstWhere((item) => item.isNotEmpty, orElse: () => '');
    final imageAsset = place.imageAsset.trim().isNotEmpty
        ? place.imageAsset.trim()
        : place.galleryAssets
              .map((item) => item.trim())
              .firstWhere((item) => item.isNotEmpty, orElse: () => '');

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildDefault(),
            )
          : imageAsset.isNotEmpty
          ? Image.asset(
              imageAsset,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildDefault(),
            )
          : _buildDefault(),
    );
  }

  Widget _buildDefault() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: place.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(place.icon, color: place.color, size: height * 0.42),
    );
  }
}

class _PlacePreviewSheet extends StatelessWidget {
  final CulturalPlace place;
  final String distanceLabel;
  final Future<void> Function() onDetail;
  final VoidCallback onDirections;

  const _PlacePreviewSheet({
    required this.place,
    required this.distanceLabel,
    required this.onDetail,
    required this.onDirections,
  });

  static const Color _ink = Color(0xFF102321);
  static const Color _red = Color(0xFFD93829);

  @override
  Widget build(BuildContext context) {
    final hasRoutePoint = place.latitude != 0 && place.longitude != 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBF5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MapPlaceImage(
                  place: place,
                  width: 126,
                  height: 112,
                  radius: 18,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 22,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _InfoLine(icon: Icons.place_rounded, text: place.address),
                      const SizedBox(height: 6),
                      _InfoLine(
                        icon: Icons.near_me_rounded,
                        text: "Cách bạn $distanceLabel",
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              place.shortDescription,
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Tag(label: place.tag),
                const SizedBox(width: 8),
                _Tag(
                  label: place.layer == CulturalPlaceLayer.service
                      ? "Dịch vụ trải nghiệm"
                      : "Văn hóa cộng đồng",
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onDetail(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      side: BorderSide(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                      backgroundColor: const Color(0xFFF5EFE6),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "Xem chi tiết",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasRoutePoint ? onDirections : null,
                    icon: Icon(
                      hasRoutePoint
                          ? Icons.directions_rounded
                          : Icons.info_outline_rounded,
                      size: 18,
                    ),
                    label: Text(hasRoutePoint ? "Chỉ đường" : "Chưa có tọa độ"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      disabledBackgroundColor: const Color(0xFFE8DED4),
                      disabledForegroundColor: _ink.withValues(alpha: 0.58),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
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
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7C4B3B), size: 16),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EAE0),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF392B22),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FilterItem {
  final String label;
  final CulturalPlaceType type;
  final IconData icon;
  final Color color;

  const _FilterItem(this.label, this.type, this.icon, this.color);
}

const List<_FilterItem> _filterItems = [
  _FilterItem(
    "Tất cả",
    CulturalPlaceType.all,
    Icons.travel_explore_rounded,
    Color(0xFFD93829),
  ),
  _FilterItem(
    "Lễ hội",
    CulturalPlaceType.festival,
    Icons.local_fire_department_rounded,
    Color(0xFFD93829),
  ),
  _FilterItem(
    "Làng văn hóa",
    CulturalPlaceType.village,
    Icons.home_work_rounded,
    Color(0xFFE49B2D),
  ),
  _FilterItem(
    "Thảo dược",
    CulturalPlaceType.herb,
    Icons.eco_rounded,
    Color(0xFF2F7D3C),
  ),
  _FilterItem(
    "Điểm du lịch",
    CulturalPlaceType.tourism,
    Icons.photo_camera_rounded,
    Color(0xFF397FA8),
  ),
  _FilterItem(
    "Nhà cộng đồng",
    CulturalPlaceType.communityHouse,
    Icons.groups_rounded,
    Color(0xFF8B62C8),
  ),
  _FilterItem(
    "Homestay",
    CulturalPlaceType.homestay,
    Icons.house_rounded,
    Color(0xFFE5B21A),
  ),
];
