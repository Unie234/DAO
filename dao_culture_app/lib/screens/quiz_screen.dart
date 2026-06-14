import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/streak_rescue_service.dart';

class QuizScreen extends StatefulWidget {
  final String title;
  final bool rescueMode;
  final String rescueMissionId;
  final int requiredCorrect;

  const QuizScreen({
    super.key,
    required this.title,
    this.rescueMode = false,
    this.rescueMissionId = "",
    this.requiredCorrect = 4,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const List<Map<String, dynamic>> _allQuestions = [
    {
      'question': 'Từ "Cám ơn" trong tiếng Dao nói như thế nào?',
      'options': ['Chao mán', 'O mán', 'Nhây', 'Pỉa'],
      'correctIndex': 1,
    },
    {
      'question': 'Khi muốn nói "Chào bạn", bạn sẽ dùng từ nào?',
      'options': ['Búa', 'Múa', 'Chao mán', 'O mán'],
      'correctIndex': 2,
    },
    {
      'question': 'Từ "Múa" trong tiếng Dao có nghĩa là gì?',
      'options': ['Tôi/Tao', 'Đi thôi', 'Cám ơn', 'Bạn/Mày'],
      'correctIndex': 3,
    },
    {
      'question': 'Hành động "Đi" trong tiếng Dao là gì?',
      'options': ['Pỉa', 'Búa', 'Nhây', 'Múa'],
      'correctIndex': 0,
    },
    {
      'question': 'Từ "Búa" có nghĩa là gì?',
      'options': ['Cái búa', 'Nói', 'Ngủ', 'Ăn'],
      'correctIndex': 1,
    },
    {
      'question': 'Đại từ nhân xưng "Tôi/Tao" đọc là:',
      'options': ['Pỉa', 'Múa', 'Nhây', 'Chao'],
      'correctIndex': 2,
    },
    {
      'question': 'Hoàn thành câu chào: "... mán" (Chào bạn)',
      'options': ['O', 'Pỉa', 'Chao', 'Búa'],
      'correctIndex': 2,
    },
    {
      'question': 'Người Dao nói "O mán" khi nào?',
      'options': ['Xin lỗi', 'Tạm biệt', 'Chào hỏi', 'Cảm ơn'],
      'correctIndex': 3,
    },
    {
      'question': 'Ghép cặp đúng: Pỉa = ?',
      'options': ['Đi', 'Đứng', 'Ngồi', 'Nói'],
      'correctIndex': 0,
    },
    {
      'question': 'Ghép cặp đúng: Nhây = ?',
      'options': ['Họ', 'Chúng tôi', 'Tôi/Tao', 'Bạn/Mày'],
      'correctIndex': 2,
    },
  ];

  late final List<Map<String, dynamic>> _questions = widget.rescueMode
      ? List<Map<String, dynamic>>.from(_allQuestions.take(5))
      : List<Map<String, dynamic>>.from(_allQuestions);

  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  int _selectedOptionIndex = -1;

  void _submitAnswer(int index) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _selectedOptionIndex = index;

      if (index == _questions[_currentQuestionIndex]['correctIndex']) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswered = false;
        _selectedOptionIndex = -1;
      });
    } else {
      _showResultDialog();
    }
  }

  // --- CƠ CHẾ MỚI: KHUYẾN KHÍCH TRẢI NGHIỆM VĂN HÓA ---
  // HÀM XỬ LÝ KẾT QUẢ ĐÃ ĐƯỢC CHỈNH LẠI THEO ĐIỂM HÀNH TRÌNH
  Future<void> _showResultDialog() async {
    int totalQuestions = _questions.length;
    double percent = _score / totalQuestions;

    if (widget.rescueMode) {
      await _showRescueResultDialog(totalQuestions);
      return;
    }

    int xpEarned = 0;
    String title = "";
    String message = "";

    if (_score == totalQuestions) {
      xpEarned = 35;
      title = "🎉 Giỏi quá bạn ơi!";
      message =
          "Bạn đã trả lời đúng tất cả $_score/$totalQuestions câu. Thưởng nóng 35 Điểm Hành Trình cho trí nhớ siêu phàm của bạn!";
    } else if (percent >= 0.8) {
      xpEarned = 25;
      title = "👏 Rất tốt!";
      message =
          "Bạn đúng $_score/$totalQuestions câu. Bạn có muốn làm lại để lấy trọn vẹn điểm tối đa không?";
    } else if (percent >= 0.5) {
      xpEarned = 12;
      title = "👏 Cố thêm chút nữa!";
      message =
          "Bạn đúng $_score/$totalQuestions câu. Cứ luyện tiếp, hành trình của bạn đang tiến lên rồi đó.";
    } else {
      xpEarned = 5;
      title = "🌱 Không sao đâu!";
      message =
          "Bạn đúng $_score/$totalQuestions câu. Tiếng Dao hơi khó chút xíu, tặng bạn 5 Điểm Hành Trình khích lệ.";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _score == totalQuestions
                ? Colors.green
                : (percent >= 0.7 ? Colors.blue : Colors.orange),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Text(
                "+$xpEarned Điểm",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              // NÚT CHƠI LẠI (Chỉ hiện khi chưa đạt 100%)
              if (_score < totalQuestions)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      side: const BorderSide(color: Colors.orange, width: 2),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentQuestionIndex = 0;
                        _score = 0;
                        _isAnswered = false;
                        _selectedOptionIndex = -1;
                      });
                    },
                    child: const Text(
                      "Thử lại",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),

              if (_score < totalQuestions) const SizedBox(width: 10),

              // NÚT ĐI TIẾP
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Tắt Dialog
                    Navigator.pop(context, true); // Quay về
                  },
                  child: Text(
                    _score == totalQuestions ? "Về Hành Trình" : "Đi tiếp",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showRescueResultDialog(int totalQuestions) async {
    final passed = _score >= widget.requiredCorrect;
    Map<String, dynamic>? rescueResult;

    if (passed) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? "";
      if (userId.isNotEmpty && widget.rescueMissionId.isNotEmpty) {
        rescueResult = await StreakRescueService.complete(
          userId: userId,
          missionId: widget.rescueMissionId,
          correctAnswers: _score,
          totalQuestions: totalQuestions,
        );
      }
    }

    if (!mounted) return;

    final rescued = rescueResult?['rescued'] == true;
    final title = rescued
        ? "Đã cứu chuỗi!"
        : passed
        ? "Chưa lưu được kết quả"
        : "Chưa đạt nhiệm vụ";
    final message = rescued
        ? "Bạn đúng $_score/$totalQuestions câu. Chuỗi học tập đã được giữ lại."
        : passed
        ? "Bạn đã đạt điểm, nhưng app chưa xác nhận được với máy chủ. Hãy thử lại khi kết nối ổn định."
        : "Bạn đúng $_score/$totalQuestions câu. Cần đúng ít nhất ${widget.requiredCorrect}/$totalQuestions câu để cứu chuỗi.";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: rescued ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          if (!rescued)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _currentQuestionIndex = 0;
                  _score = 0;
                  _isAnswered = false;
                  _selectedOptionIndex = -1;
                });
              },
              child: const Text("Làm lại"),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, rescued);
            },
            child: Text(rescued ? "Xong" : "Để sau"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    "${_currentQuestionIndex + 1}/${_questions.length}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentQuestionIndex + 1) / _questions.length,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.orange,
                      ),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  currentQuestion['question'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),

              ...List.generate(currentQuestion['options'].length, (index) {
                Color buttonColor = Colors.white;
                Color textColor = Colors.black87;
                Color borderColor = Colors.grey.shade300;

                if (_isAnswered) {
                  if (index == currentQuestion['correctIndex']) {
                    buttonColor = Colors.green.shade50;
                    borderColor = Colors.green;
                    textColor = Colors.green.shade800;
                  } else if (index == _selectedOptionIndex) {
                    buttonColor = Colors.red.shade50;
                    borderColor = Colors.red;
                    textColor = Colors.red.shade800;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: InkWell(
                    onTap: () => _submitAnswer(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: buttonColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Text(
                        currentQuestion['options'][index],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }),

              const Spacer(),

              if (_isAnswered)
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _nextQuestion,
                    child: const Text(
                      "Tiếp tục",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
}
