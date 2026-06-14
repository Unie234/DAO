import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/gamification_service.dart';
import '../services/learning_progress_service.dart';
import '../widgets/level_up_celebration_dialog.dart';

class VocabularyMemoryChallengeScreen extends StatefulWidget {
  final String topicTitle;
  final List<dynamic> vocabulary;

  const VocabularyMemoryChallengeScreen({
    super.key,
    required this.topicTitle,
    required this.vocabulary,
  });

  @override
  State<VocabularyMemoryChallengeScreen> createState() =>
      _VocabularyMemoryChallengeScreenState();
}

class _VocabularyMemoryChallengeScreenState
    extends State<VocabularyMemoryChallengeScreen> {
  static const Color _ink = Color(0xFF1C2026);
  static const Color _red = Color(0xFF1976D2);
  static const Color _green = Color(0xFF2F8A4C);
  static const Color _paper = Color(0xFFF2F8FF);

  late final List<_MemoryQuestion> _questions;
  late final DateTime _sessionStartedAt;
  bool _studyDurationSaved = false;
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _sessionStartedAt = DateTime.now();
    _questions = _buildQuestions();
  }

  @override
  void dispose() {
    if (!_studyDurationSaved) {
      unawaited(LearningProgressService.saveStudyDuration(_sessionStartedAt));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: _paper,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                "Chủ đề này cần ít nhất 2 từ để tạo thử thách ghi nhớ.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: _paper,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  LinearProgressIndicator(
                    value: (_currentIndex + 1) / _questions.length,
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(99),
                    backgroundColor: const Color(0xFFD9ECFF),
                    valueColor: const AlwaysStoppedAnimation<Color>(_red),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${_currentIndex + 1}/${_questions.length}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF777A80),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Từ này nghĩa là gì?",
                          style: TextStyle(
                            color: Color(0xFF777A80),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          question.daoWord,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 30,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  ...List.generate(question.options.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildOption(question, index),
                    );
                  }),
                  const Spacer(),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isAnswered ? _next : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentIndex < _questions.length - 1
                            ? "Tiếp tục"
                            : "Xem kết quả",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: _ink),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Thử thách ghi nhớ",
                style: TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                widget.topicTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(_MemoryQuestion question, int index) {
    final isSelected = _selectedIndex == index;
    final isCorrect = index == question.correctIndex;
    Color borderColor = const Color(0xFFDDEBFA);
    Color background = Colors.white;
    Color textColor = _ink;

    if (_isAnswered) {
      if (isCorrect) {
        borderColor = _green;
        background = const Color(0xFFEAF7ED);
        textColor = _green;
      } else if (isSelected) {
        borderColor = _red;
        background = const Color(0xFFE8F5FF);
        textColor = _red;
      }
    }

    return GestureDetector(
      onTap: _isAnswered ? null : () => _answer(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                question.options[index],
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (_isAnswered && isCorrect)
              const Icon(Icons.check_circle_rounded, color: _green)
            else if (_isAnswered && isSelected)
              const Icon(Icons.cancel_rounded, color: _red),
          ],
        ),
      ),
    );
  }

  void _answer(int index) {
    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
      if (index == _questions[_currentIndex].correctIndex) {
        _score++;
      }
    });
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _isAnswered = false;
      });
      return;
    }

    _showResult();
  }

  Future<void> _showResult() async {
    final percent = _score / _questions.length;
    final xp = _score == _questions.length
        ? 35
        : (percent >= 0.8 ? 25 : (percent >= 0.5 ? 12 : 5));
    final award = await GamificationService.awardXP(xp);
    await _saveAchievement(percent);
    await LearningProgressService.saveStudyDuration(_sessionStartedAt);
    _studyDurationSaved = true;
    await LearningProgressService.saveQuizResult(
      correct: _score,
      total: _questions.length,
    );

    if (!mounted) return;
    if (award.levelUp) {
      await showLevelUpCelebrationDialog(
        context,
        level: award.level,
        points: award.points,
      );
      if (!mounted) return;
    }

    final isHighScore = _score >= 7;
    final resultColor = isHighScore ? _green : _red;
    final resultIcon = isHighScore
        ? Icons.celebration_rounded
        : Icons.auto_awesome_rounded;
    final resultTitle = isHighScore ? "Xuất sắc quá!" : "Cố lên nhé!";
    final encouragement = isHighScore
        ? "Bạn nhớ rất tốt rồi. Vỗ tay cho mình một cái nào, tiếp tục giữ phong độ này nhé!"
        : "Bạn đã hoàn thành thử thách rồi. Cứ ôn lại các từ vừa sai, lần sau chắc chắn sẽ tốt hơn.";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: resultColor.withValues(alpha: 0.20)),
            boxShadow: [
              BoxShadow(
                color: resultColor.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      resultColor.withValues(alpha: 0.18),
                      const Color(0xFFFFF3DD),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(resultIcon, color: resultColor, size: 48),
              ),
              const SizedBox(height: 14),
              Text(
                resultTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: resultColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F8FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$_score/${_questions.length}",
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "câu đúng",
                      style: TextStyle(
                        color: Color(0xFF667286),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                encouragement,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF344054),
                  fontSize: 15,
                  height: 1.42,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: resultColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "+$xp Điểm Hành Trình",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: resultColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: resultColor,
                        side: BorderSide(color: resultColor, width: 1.4),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _currentIndex = 0;
                          _score = 0;
                          _selectedIndex = null;
                          _isAnswered = false;
                        });
                      },
                      child: const Text(
                        "Làm lại",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: resultColor,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, true);
                      },
                      child: const Text(
                        "Xong",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_MemoryQuestion> _buildQuestions() {
    final source = widget.vocabulary
        .whereType<Map<String, dynamic>>()
        .where(
          (word) =>
              (word['dao_word'] ?? '').toString().trim().isNotEmpty &&
              (word['viet_word'] ?? '').toString().trim().isNotEmpty,
        )
        .toList();

    if (source.length < 2) return [];

    final random = Random();
    final shuffled = [...source]..shuffle(random);
    final selected = shuffled.take(min(10, shuffled.length)).toList();

    return selected.map((word) {
      final correct = (word['viet_word'] ?? '').toString();
      final distractors =
          source
              .map((item) => (item['viet_word'] ?? '').toString())
              .where((option) => option.isNotEmpty && option != correct)
              .toSet()
              .toList()
            ..shuffle(random);
      final options = [correct, ...distractors.take(3)]..shuffle(random);

      return _MemoryQuestion(
        daoWord: (word['dao_word'] ?? '').toString(),
        options: options,
        correctIndex: options.indexOf(correct),
      );
    }).toList();
  }

  Future<void> _saveAchievement(double percent) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'memory_challenge_${widget.topicTitle}';
    await prefs.setString(
      key,
      '${DateTime.now().toIso8601String()}|$_score/${_questions.length}|$percent',
    );
  }
}

class _MemoryQuestion {
  final String daoWord;
  final List<String> options;
  final int correctIndex;

  const _MemoryQuestion({
    required this.daoWord,
    required this.options,
    required this.correctIndex,
  });
}
