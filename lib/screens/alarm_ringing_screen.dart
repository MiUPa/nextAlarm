import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

class AlarmRingingScreen extends StatefulWidget {
  final Alarm alarm;

  const AlarmRingingScreen({
    super.key,
    required this.alarm,
  });

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _mathAnswer = 0;
  late int _correctAnswer;
  late String _mathQuestion;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _generateMathProblem();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _generateMathProblem() {
    final random = math.Random();
    final difficulty = widget.alarm.challengeDifficulty;

    if (difficulty <= 2) {
      // Easy: simple addition
      final a = random.nextInt(20) + 1;
      final b = random.nextInt(20) + 1;
      _mathQuestion = '$a + $b = ?';
      _correctAnswer = a + b;
    } else if (difficulty == 3) {
      // Medium: multiplication
      final a = random.nextInt(12) + 1;
      final b = random.nextInt(12) + 1;
      _mathQuestion = '$a × $b = ?';
      _correctAnswer = a * b;
    } else {
      // Hard: mixed operations
      final a = random.nextInt(50) + 10;
      final b = random.nextInt(20) + 1;
      final c = random.nextInt(10) + 1;
      _mathQuestion = '($a + $b) × $c = ?';
      _correctAnswer = (a + b) * c;
    }
  }

  void _checkAnswer() {
    if (_mathAnswer == _correctAnswer) {
      _stopAlarm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('不正解！もう一度試してください。'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _mathAnswer = 0;
      });
    }
  }

  void _stopAlarm() {
    final alarmService = Provider.of<AlarmService>(context, listen: false);
    alarmService.stopRingingAlarm();
    Navigator.of(context).pop();
  }

  Widget _buildChallengeContent() {
    switch (widget.alarm.challenge) {
      case WakeUpChallenge.math:
        return _buildMathChallenge();
      case WakeUpChallenge.none:
        return _buildSimpleStop();
      default:
        return _buildPlaceholderChallenge();
    }
  }

  Widget _buildMathChallenge() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '数学問題を解いてアラームを停止',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          _mathQuestion,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: TextField(
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: '答えを入力',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 2),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primary, width: 3),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _mathAnswer = int.tryParse(value) ?? 0;
              });
            },
            onSubmitted: (_) => _checkAnswer(),
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _mathAnswer != 0 ? _checkAnswer : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            '確認',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleStop() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: _stopAlarm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'アラームを停止',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderChallenge() {
    final challengeName = widget.alarm.challenge.toString().split('.').last;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.construction,
          size: 64,
          color: Colors.white.withOpacity(0.5),
        ),
        const SizedBox(height: 20),
        Text(
          '$challengeName チャレンジ',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '（このチャレンジはまだ実装されていません）',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _stopAlarm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'アラームを停止',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing alarm icon
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.2),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.error.withOpacity(0.2),
                            border: Border.all(
                              color: AppTheme.error.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.alarm,
                            size: 80,
                            color: AppTheme.error,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Time
                  Text(
                    '${widget.alarm.time.hour.toString().padLeft(2, '0')}:${widget.alarm.time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Label
                  Text(
                    widget.alarm.label,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Challenge content
                  _buildChallengeContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
