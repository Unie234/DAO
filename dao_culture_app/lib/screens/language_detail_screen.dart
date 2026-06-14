import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';

class LanguageDetailScreen extends StatefulWidget {
  final int id;
  final String title;
  final String tiengDao;
  final String tiengViet;
  final String audioUrl; // Đường dẫn file mẫu từ MySQL

  const LanguageDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.tiengDao,
    required this.tiengViet,
    required this.audioUrl,
  });

  @override
  State<LanguageDetailScreen> createState() => _LanguageDetailScreenState();
}

class _LanguageDetailScreenState extends State<LanguageDetailScreen> {
  // Công cụ phát nhạc và ghi âm
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _isEvaluating = false; // Trạng thái AI đang chấm điểm
  String _aiFeedback = ""; // Lời nhận xét của AI

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // 🟢 1. HÀM NGHE FILE GỐC
  Future<void> _playReferenceAudio() async {
    try {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lỗi phát âm thanh mẫu!")));
    }
  }

  // 🟢 2. HÀM BẮT ĐẦU GHI ÂM (Khi nhấn giữ nút)
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/user_record.m4a';

        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _aiFeedback = ""; // Xóa nhận xét cũ
        });
      }
    } catch (e) {
      debugPrint("Lỗi ghi âm: $e");
    }
  }

  // 🟢 3. HÀM DỪNG GHI ÂM VÀ GỬI AI CHẤM ĐIỂM (Khi thả tay)
  Future<void> _stopRecordingAndEvaluate() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isEvaluating = true; // Hiện vòng xoay chờ AI
      });

      if (path != null) {
        // 👉 ĐÃ SỬA: Bổ sung thêm widget.audioUrl vào đây!
        String result = await ApiService.chatWithDaoAssistant(
          "Hãy đánh giá phát âm tiếng Dao cho câu '${widget.tiengDao}'. File ghi âm: $path. File mẫu: ${widget.audioUrl}.",
        );

        setState(() {
          _aiFeedback = result;
          _isEvaluating = false;
        });
      }
    } catch (e) {
      setState(() => _isEvaluating = false);
      debugPrint("Lỗi khi gửi AI: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // --- THẺ HIỂN THỊ TỪ VỰNG ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    widget.tiengDao,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.tiengViet,
                    style: const TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Nút nghe file mẫu
                  ElevatedButton.icon(
                    onPressed: _playReferenceAudio,
                    icon: const Icon(Icons.volume_up),
                    label: const Text("Nghe mẫu"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // --- KHU VỰC KẾT QUẢ AI CHẤM ĐIỂM ---
            if (_isEvaluating)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text(
                    "AI đang phân tích giọng của bạn...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              )
            else if (_aiFeedback.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  _aiFeedback,
                  style: const TextStyle(fontSize: 16, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),

            const Spacer(),

            // --- NÚT GHI ÂM (NHẤN GIỮ) ---
            const Text(
              "Nhấn giữ để đọc",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecordingAndEvaluate(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isRecording ? 100 : 80,
                height: _isRecording ? 100 : 80,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : const Color(0xFF1A237E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (_isRecording)
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 10,
                      )
                    else
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: _isRecording ? 50 : 40,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
