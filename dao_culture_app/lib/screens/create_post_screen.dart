import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
// 🟢 MỚI THÊM: Cần có cái này để lấy tên và ID người dùng đăng bài
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart'; // Đảm bảo đường dẫn này trỏ đúng file ApiService của bạn
import '../widgets/level_up_celebration_dialog.dart';
import 'login_screen.dart';

class CreatePostScreen extends StatefulWidget {
  final String? postId;
  final String? initialContent;
  final String? initialImageUrl;

  const CreatePostScreen({
    super.key,
    this.postId,
    this.initialContent,
    this.initialImageUrl,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  File? _selectedMedia;
  XFile? _selectedMediaXFile;
  Uint8List? _selectedMediaBytes;
  final List<File> _selectedImages = [];
  final List<XFile> _selectedImageXFiles = [];
  final List<Uint8List> _selectedImageBytes = [];
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _isVideo = false;
  bool _removeExistingMedia = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }
    if (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty) {
      _existingImageUrl = widget.initialImageUrl;
      _isVideo = widget.initialImageUrl!.contains('.mp4');
    }
  }

  // 🔴 MÁY QUÉT TỪ NGỮ VI PHẠM (ĐÃ CHỈNH SỬA CHO PHÙ HỢP VĂN HÓA)
  bool _containsBadWords(String text) {
    final normalizedText = _normalizeModerationText(text);
    final compactText = normalizedText.replaceAll(RegExp(r'[^a-z0-9]'), '');
    const blockedPhrases = [
      // Tu ngu tho tuc, cong kich ca nhan hoac chui rua.
      'chui bay',
      'chui tuc',
      'chui the',
      'chueir tuc',
      'noi tuc',
      'vang tuc',
      'tuc tiu',
      'me no',
      'may thich gi',
      'do ngu',
      'do dien',
      'do khung',
      'do mat day',
      'mat day',
      'vo hoc',
      'khon nan',
      'con cho',
      'cho chet',
      'bien di',
      'danh chet',
      'giet may',
      'giet no',
      'dit me',
      'du ma',
      'dau buoi',
      'con cac',
      'cai lon',
      'deo me',
      'deo hieu',
      'deo biet',
      'oc cho',
      'suc vat',

      // Lua dao, kich dong, quang cao/rao ban/keo nguoi dung ra ngoai.
      'lua dao',
      'pha hoai',
      'kich dong',
      'tay chay',
      'quang cao',
      'quang ba',
      'ban hang',
      'rao ban',
      'khuyen mai',
      'giam gia',
      'sale',
      'mua ngay',
      'dat hang',
      'chot don',
      'kiem tien',
      'tuyen cong tac vien',
      'tuyen ctv',
      'nap tien',
      'vay tien',
      'cho vay',
      'zalo',
      'telegram',
      'so dien thoai',
      'lien he mua',

      // Che bai, phu nhan, xuc pham van hoa va phong tuc.
      'che bai van hoa',
      'phe binh van hoa',
      'noi xau van hoa',
      'bai xich van hoa',
      'bai tru van hoa',
      'ha thap van hoa',
      'xuc pham van hoa',
      'van hoa lac hau',
      'van hoa dao lac hau',
      'van hoa kem van minh',
      'phong tuc lac hau',
      'phong tuc xau',
      'hu tuc',
      'me tin di doan',
      'khong dang ton tai',
    ];

    for (String phrase in blockedPhrases) {
      if (normalizedText.contains(phrase)) return true;
      if (compactText.contains(phrase.replaceAll(' ', ''))) return true;
    }

    const blockedWords = [
      'dm',
      'dmm',
      'dmmm',
      'vcl',
      'clm',
      'clgt',
      'cc',
      'vl',
    ];
    final textWords = normalizedText
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toSet();
    for (String word in blockedWords) {
      if (textWords.contains(word)) return true;
    }
    return false;
  }

  String _normalizeModerationText(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
        .replaceAll('đ', 'd')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  // --- HÀM CHỌN ẢNH HOẶC VIDEO ---
  Future<void> _pickMedia(bool isVideoRequest) async {
    final picker = ImagePicker();

    if (isVideoRequest) {
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = kIsWeb ? await pickedFile.readAsBytes() : null;
        setState(() {
          _isVideo = true;
          _selectedMedia = kIsWeb ? null : File(pickedFile.path);
          _selectedMediaXFile = pickedFile;
          _selectedMediaBytes = bytes;
          _clearSelectedImages();
          _existingImageUrl = null;
          _removeExistingMedia = false;
        });
      }
      return;
    }

    final pickedFiles = await picker.pickMultiImage(imageQuality: 82);
    if (pickedFiles.isEmpty) return;
    final limitedFiles = pickedFiles.take(8).toList();
    final webBytes = kIsWeb
        ? await Future.wait(limitedFiles.map((file) => file.readAsBytes()))
        : <Uint8List>[];

    setState(() {
      _isVideo = false;
      _clearSelectedSingleMedia();
      _existingImageUrl = null;
      _removeExistingMedia = false;
      _selectedImageXFiles
        ..clear()
        ..addAll(limitedFiles);
      _selectedImageBytes
        ..clear()
        ..addAll(webBytes);
      _selectedImages
        ..clear()
        ..addAll(
          kIsWeb ? <File>[] : limitedFiles.map((file) => File(file.path)),
        );
    });
  }

  Future<void> _pickAndCropSingleImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (pickedFile == null) return;

    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _isVideo = false;
        _selectedMedia = null;
        _selectedMediaXFile = pickedFile;
        _selectedMediaBytes = bytes;
        _clearSelectedImages();
        _existingImageUrl = null;
        _removeExistingMedia = false;
      });
      return;
    }

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cắt và chỉnh sửa ảnh',
          toolbarColor: const Color(0xFF1A237E),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.original,
          ],
        ),
      ],
    );

    setState(() {
      _isVideo = false;
      _selectedMedia = File(croppedFile?.path ?? pickedFile.path);
      _selectedMediaXFile = XFile(croppedFile?.path ?? pickedFile.path);
      _selectedMediaBytes = null;
      _clearSelectedImages();
      _existingImageUrl = null;
      _removeExistingMedia = false;
    });
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 82,
    );
    if (pickedFile == null) return;
    final bytes = kIsWeb ? await pickedFile.readAsBytes() : null;

    setState(() {
      _isVideo = false;
      _selectedMedia = kIsWeb ? null : File(pickedFile.path);
      _selectedMediaXFile = pickedFile;
      _selectedMediaBytes = bytes;
      _clearSelectedImages();
      _existingImageUrl = null;
      _removeExistingMedia = false;
    });
  }

  bool get _hasSelectedMedia {
    return _hasLocalSelectedMedia || _existingImageUrl != null;
  }

  bool get _hasLocalSelectedMedia {
    return _selectedMedia != null ||
        _selectedMediaXFile != null ||
        _selectedImages.isNotEmpty ||
        _selectedImageXFiles.isNotEmpty;
  }

  String _fileName(File file) {
    final normalized = file.path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  String _xFileName(XFile file) {
    final normalized = (file.name.isNotEmpty ? file.name : file.path)
        .replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  void _clearSelectedSingleMedia() {
    _selectedMedia = null;
    _selectedMediaXFile = null;
    _selectedMediaBytes = null;
  }

  void _clearSelectedImages() {
    _selectedImages.clear();
    _selectedImageXFiles.clear();
    _selectedImageBytes.clear();
  }

  String get _mediaStatusText {
    if (_isLoading && _hasLocalSelectedMedia) {
      return _isVideo
          ? "Đang tải video lên máy chủ..."
          : "Đang tải ảnh lên máy chủ...";
    }

    if (_selectedImages.isNotEmpty || _selectedImageXFiles.isNotEmpty) {
      final imageCount = _selectedImages.isNotEmpty
          ? _selectedImages.length
          : _selectedImageXFiles.length;
      final firstName = _selectedImages.isNotEmpty
          ? _fileName(_selectedImages.first)
          : _xFileName(_selectedImageXFiles.first);
      final extra = imageCount > 1 ? " và ${imageCount - 1} ảnh khác" : "";
      return "Đã chọn $imageCount ảnh: $firstName$extra";
    }

    if (_selectedMedia != null || _selectedMediaXFile != null) {
      final name = _selectedMedia != null
          ? _fileName(_selectedMedia!)
          : _xFileName(_selectedMediaXFile!);
      return _isVideo ? "Đã chọn video: $name" : "Đã chọn ảnh: $name";
    }

    if (_existingImageUrl != null) {
      return _isVideo
          ? "Video hiện tại của bài viết"
          : "Ảnh hiện tại của bài viết";
    }

    return "";
  }

  IconData get _mediaStatusIcon {
    if (_isLoading && _hasLocalSelectedMedia) {
      return Icons.cloud_upload_rounded;
    }
    if (_isVideo) return Icons.videocam_rounded;
    return Icons.check_circle_rounded;
  }

  Future<bool> _ensureCanPost() async {
    final prefs = await SharedPreferences.getInstance();
    final username = (prefs.getString('username') ?? '').trim();
    final userId = (prefs.getString('user_id') ?? '').trim();

    if (userId.isNotEmpty && username.isNotEmpty && username != 'Khách') {
      return true;
    }

    if (!mounted) return false;
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Yêu cầu đăng nhập"),
        content: const Text(
          "Bạn cần đăng nhập tài khoản người dùng để đăng bài.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Để sau"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Đăng nhập"),
          ),
        ],
      ),
    );

    if (shouldLogin == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
    return false;
  }

  // --- HÀM LƯU BÀI VIẾT (GỌI API XAMPP) ---
  Future<void> _savePost() async {
    if (!await _ensureCanPost()) return;
    if (!mounted) return;

    final content = _contentController.text.trim();

    // 1. Kiểm tra rỗng
    if (content.isEmpty && !_hasSelectedMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Uyên ơi, nhập nội dung hoặc chọn file đã nhé!"),
        ),
      );
      return;
    }

    // 2. CHỐT CHẶN BẢO VỆ CỘNG ĐỒNG
    if (_containsBadWords(content)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bài viết của bạn vi phạm tiêu chuẩn cộng đồng."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 3. LẤY THÔNG TIN NGƯỜI ĐĂNG TỪ BỘ NHỚ MÁY
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String username = (prefs.getString('username') ?? '').trim();
      String userId = (prefs.getString('user_id') ?? '').trim();

      if (userId.isEmpty || username.isEmpty || username == 'Khách') {
        throw Exception("Bạn cần đăng nhập để đăng bài.");
      }

      // 4. CHUẨN BỊ "XE TẢI" ĐỂ CHỞ CẢ ẢNH VÀ CHỮ LÊN XAMPP TRONG 1 LẦN
      final uri = Uri.parse('${ApiService.baseUrl}/posts/create.php');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';

      // Xếp chữ lên xe
      request.fields['content'] = content;
      request.fields['user_id'] = userId;
      request.fields['username'] = username;

      // Nếu là chế độ sửa bài viết, gửi kèm postId
      if (widget.postId != null) {
        request.fields['post_id'] = widget.postId!;
        request.fields['remove_media'] = _removeExistingMedia ? '1' : '0';
      }

      // Xếp file (ảnh/video) lên xe nếu có
      if (_selectedMedia != null || _selectedMediaXFile != null) {
        if (_isVideo) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đang tải video lên máy chủ, vui lòng đợi..."),
              duration: Duration(seconds: 4),
            ),
          );
        }

        request.files.add(await _singleMediaMultipartFile());
      }

      final imageCount = kIsWeb
          ? _selectedImageXFiles.length
          : _selectedImages.length;
      for (var index = 0; index < imageCount; index++) {
        request.files.add(await _galleryImageMultipartFile(index));
      }

      // 5. Khởi hành gửi lên XAMPP!
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 180),
      );
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        String cleanBody = response.body.trim();
        if (cleanBody.startsWith('\xEF\xBB\xBF')) {
          cleanBody = cleanBody.substring(3);
        }
        var result = json.decode(cleanBody);

        if (result['status'] == 'success') {
          // Chỉ cộng điểm khi tạo bài mới (không cộng khi sửa bài)
          Map<String, dynamic>? pointsResult;
          if (widget.postId == null) {
            pointsResult = await ApiService.addPointsResult(userId, 15);
            if (!mounted) return;
          }

          final pointsLevel =
              int.tryParse((pointsResult?['level'] ?? '').toString()) ?? 0;
          final didLevelUp =
              pointsResult?['level_up'] == true && pointsLevel > 0;
          final pointsMessage =
              pointsResult != null && pointsResult['status'] == 'success'
              ? "Đăng bài thành công! Bạn nhận +15 EXP."
              : "Đăng bài thành công rồi nè!";

          if (didLevelUp) {
            await showLevelUpCelebrationDialog(
              context,
              level: pointsLevel,
              points: 15,
            );
            if (!mounted) return;
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(pointsMessage)));
          }
          Navigator.pop(
            context,
            true,
          ); // Đóng form, trả về true để load lại bảng tin
        } else if (result['status'] == 'community_violation') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ??
                    "Bài viết của bạn vi phạm tiêu chuẩn cộng đồng.",
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          throw Exception("Máy chủ từ chối: ${result['message']}");
        }
      } else {
        throw Exception(_serverErrorMessage(response));
      }
    } catch (e) {
      debugPrint("LỖI XẢY RA: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi rồi: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<http.MultipartFile> _singleMediaMultipartFile() async {
    if (kIsWeb) {
      final file = _selectedMediaXFile;
      final bytes = _selectedMediaBytes;
      if (file == null || bytes == null) {
        throw Exception("Không đọc được file đã chọn.");
      }
      await _ensureCommunityXFileSize(file, isVideo: _isVideo);
      return http.MultipartFile.fromBytes(
        'media_file',
        bytes,
        filename: _xFileName(file),
        contentType: _communityMediaContentType(
          _xFileName(file),
          isVideo: _isVideo,
        ),
      );
    }

    final file = _selectedMedia;
    if (file == null) throw Exception("Không đọc được file đã chọn.");
    await _ensureCommunityMediaSize(file, isVideo: _isVideo);
    return http.MultipartFile.fromPath(
      'media_file',
      file.path,
      filename: _fileName(file),
      contentType: _communityMediaContentType(file.path, isVideo: _isVideo),
    );
  }

  Future<http.MultipartFile> _galleryImageMultipartFile(int index) async {
    if (kIsWeb) {
      final file = _selectedImageXFiles[index];
      final bytes = _selectedImageBytes[index];
      await _ensureCommunityXFileSize(file, isVideo: false);
      return http.MultipartFile.fromBytes(
        'media_files[]',
        bytes,
        filename: _xFileName(file),
        contentType: _communityMediaContentType(
          _xFileName(file),
          isVideo: false,
        ),
      );
    }

    final file = _selectedImages[index];
    await _ensureCommunityMediaSize(file, isVideo: false);
    return http.MultipartFile.fromPath(
      'media_files[]',
      file.path,
      filename: _fileName(file),
      contentType: _communityMediaContentType(file.path, isVideo: false),
    );
  }

  Future<void> _ensureCommunityMediaSize(
    File file, {
    required bool isVideo,
  }) async {
    final maxBytes = isVideo ? 100 * 1024 * 1024 : 10 * 1024 * 1024;
    final size = await file.length();
    if (size > maxBytes) {
      final limit = isVideo ? "100MB" : "10MB";
      throw Exception(
        isVideo ? "Video phải nhỏ hơn $limit." : "Ảnh phải nhỏ hơn $limit.",
      );
    }
  }

  Future<void> _ensureCommunityXFileSize(
    XFile file, {
    required bool isVideo,
  }) async {
    final maxBytes = isVideo ? 100 * 1024 * 1024 : 10 * 1024 * 1024;
    final size = await file.length();
    if (size > maxBytes) {
      final limit = isVideo ? "100MB" : "10MB";
      throw Exception(
        isVideo ? "Video phải nhỏ hơn $limit." : "Ảnh phải nhỏ hơn $limit.",
      );
    }
  }

  Widget _selectedSingleImagePreview() {
    if (kIsWeb && _selectedMediaBytes != null) {
      return Image.memory(_selectedMediaBytes!, fit: BoxFit.cover);
    }
    if (_selectedMedia != null) {
      return Image.file(_selectedMedia!, fit: BoxFit.cover);
    }
    return Image.network(_existingImageUrl!, fit: BoxFit.cover);
  }

  MediaType _communityMediaContentType(String path, {required bool isVideo}) {
    final extension = path.split('.').last.toLowerCase();
    if (isVideo) {
      return switch (extension) {
        'mov' => MediaType('video', 'quicktime'),
        'webm' => MediaType('video', 'webm'),
        'm4v' => MediaType('video', 'x-m4v'),
        _ => MediaType('video', 'mp4'),
      };
    }

    return switch (extension) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'gif' => MediaType('image', 'gif'),
      'heic' => MediaType('image', 'heic'),
      'heif' => MediaType('image', 'heif'),
      _ => MediaType('image', 'jpeg'),
    };
  }

  String _serverErrorMessage(http.Response response) {
    try {
      final raw = json.decode(response.body.trim());
      if (raw is Map) {
        final errors = raw['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          return first.toString();
        }

        final message = raw['message']?.toString().trim() ?? '';
        if (message.isNotEmpty) return message;
      }
    } catch (_) {}

    return "Lỗi kết nối máy chủ XAMPP! Mã lỗi: ${response.statusCode}";
  }

  Widget _buildSelectedImageGrid() {
    final itemCount = kIsWeb
        ? _selectedImageBytes.length
        : _selectedImages.length;
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: kIsWeb
              ? Image.memory(_selectedImageBytes[index], fit: BoxFit.cover)
              : Image.file(_selectedImages[index], fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _buildMediaStatusBar() {
    final isUploading = _isLoading && _hasLocalSelectedMedia;
    final color = isUploading
        ? const Color(0xFF1A237E)
        : const Color(0xFF2E7D32);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          if (isUploading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(_mediaStatusIcon, color: color, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _mediaStatusText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.postId != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEditing ? "Sửa bài viết" : "Tạo bài viết mới",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Center(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "ĐANG TẢI",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _savePost,
                  child: Text(
                    isEditing ? "LƯU" : "ĐĂNG",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 8,
                    decoration: const InputDecoration(
                      hintText: "Bạn đang muốn chia sẻ điều gì...",
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  if (_hasSelectedMedia)
                    Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 280,
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _isVideo
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.video_file,
                                            color: Colors.white,
                                            size: 60,
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            "Đã chọn 1 Video",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child:
                                          (_selectedImages.isNotEmpty ||
                                              _selectedImageXFiles.isNotEmpty)
                                          ? _buildSelectedImageGrid()
                                          : (_selectedMedia != null ||
                                                _selectedMediaXFile != null)
                                          ? _selectedSingleImagePreview()
                                          : Image.network(
                                              _existingImageUrl!,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                            ),
                            if (_isLoading && _hasLocalSelectedMedia)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          "Đang tải lên...",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () => setState(() {
                                        _clearSelectedSingleMedia();
                                        _clearSelectedImages();
                                        _removeExistingMedia =
                                            _existingImageUrl != null ||
                                            (widget.initialImageUrl != null &&
                                                widget
                                                    .initialImageUrl!
                                                    .isNotEmpty) ||
                                            _removeExistingMedia;
                                        _existingImageUrl = null;
                                        _isVideo = false;
                                      }),
                                child: const CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  radius: 15,
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildMediaStatusBar(),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Text(
                  "Thêm vào bài viết: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isLoading ? null : () => _pickMedia(false),
                  icon: const Icon(
                    Icons.photo_library,
                    color: Colors.green,
                    size: 30,
                  ),
                  tooltip: "Chọn nhiều ảnh",
                ),
                IconButton(
                  onPressed: _isLoading ? null : _takePhoto,
                  icon: const Icon(
                    Icons.photo_camera_rounded,
                    color: Colors.redAccent,
                    size: 30,
                  ),
                  tooltip: "Chụp ảnh",
                ),
                IconButton(
                  onPressed: _isLoading ? null : _pickAndCropSingleImage,
                  icon: const Icon(Icons.crop, color: Colors.orange, size: 30),
                  tooltip: "Chọn và cắt 1 ảnh",
                ),
                IconButton(
                  onPressed: _isLoading ? null : () => _pickMedia(true),
                  icon: const Icon(
                    Icons.videocam,
                    color: Colors.blue,
                    size: 32,
                  ),
                  tooltip: "Video",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
