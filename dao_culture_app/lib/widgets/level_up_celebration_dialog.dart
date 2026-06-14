import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../services/gamification_service.dart';

Future<void> showLevelUpCelebrationDialog(
  BuildContext context, {
  required int level,
  int? points,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _LevelUpCelebrationDialog(level: level, points: points),
  );
}

class _LevelUpCelebrationDialog extends StatefulWidget {
  final int level;
  final int? points;

  const _LevelUpCelebrationDialog({required this.level, this.points});

  @override
  State<_LevelUpCelebrationDialog> createState() =>
      _LevelUpCelebrationDialogState();
}

class _LevelUpCelebrationDialogState extends State<_LevelUpCelebrationDialog> {
  late final ConfettiController _leftConfetti;
  late final ConfettiController _rightConfetti;

  @override
  void initState() {
    super.initState();
    _leftConfetti = ConfettiController(duration: const Duration(seconds: 3));
    _rightConfetti = ConfettiController(duration: const Duration(seconds: 3));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _leftConfetti.play();
      _rightConfetti.play();
    });
  }

  @override
  void dispose() {
    _leftConfetti.dispose();
    _rightConfetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = GamificationService.titleForLevel(widget.level);
    final stage = GamificationService.journeyStageForLevel(widget.level);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 26,
            child: ConfettiWidget(
              confettiController: _leftConfetti,
              blastDirection: -pi / 3,
              emissionFrequency: 0.04,
              numberOfParticles: 18,
              gravity: 0.18,
              shouldLoop: false,
              colors: const [
                Color(0xFFF8A420),
                Color(0xFF2F8A4C),
                Color(0xFFD93829),
                Color(0xFF2458C4),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 26,
            child: ConfettiWidget(
              confettiController: _rightConfetti,
              blastDirection: -2 * pi / 3,
              emissionFrequency: 0.04,
              numberOfParticles: 18,
              gravity: 0.18,
              shouldLoop: false,
              colors: const [
                Color(0xFFF8A420),
                Color(0xFF2F8A4C),
                Color(0xFFD93829),
                Color(0xFF2458C4),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 98,
                  height: 98,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFF1C8), Color(0xFFEAF7EE)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF8A420),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF8A420).withValues(alpha: 0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFD93829),
                    size: 52,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "LÊN CẤP!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFD93829),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Bạn đã đạt Lv.${widget.level}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF2458C4),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bạn đã trở thành "$title"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1C2026),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF667286),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.points != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7EE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "+${widget.points} Điểm Hành Trình",
                      style: const TextStyle(
                        color: Color(0xFF2F8A4C),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD93829),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Tiếp tục hành trình",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
