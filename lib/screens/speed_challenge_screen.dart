import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/han_character.dart';
import '../data/han_seed_data.dart';
import '../state/app_state.dart';

class SpeedChallengeScreen extends StatefulWidget {
  final AppState appState;

  const SpeedChallengeScreen({super.key, required this.appState});

  @override
  State<SpeedChallengeScreen> createState() => _SpeedChallengeScreenState();
}

class _SpeedChallengeScreenState extends State<SpeedChallengeScreen> {
  static const int _initialTime = 60;
  int _secondsRemaining = _initialTime;
  Timer? _gameTimer;

  int _score = 0;
  int _combo = 1;
  int _maxCombo = 1;
  int _consecutiveCorrect = 0;
  int _correctCount = 0;
  int _wrongCount = 0;

  bool _isGameOver = false;
  bool _flashRed = false;

  late HanCharacter _currentChar;
  late List<String> _options;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _nextQuestion();
    _startGameTimer();
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _endGame();
      }
    });
  }

  void _nextQuestion() {
    final pool = seedCharacters.where((c) => c.isHan).toList();
    _currentChar = pool[_random.nextInt(pool.length)];

    final distractors = pool
        .where((c) => c.hanVietReading != _currentChar.hanVietReading)
        .map((c) => c.hanVietReading)
        .toSet()
        .toList()
      ..shuffle(_random);

    _options = [_currentChar.hanVietReading, ...distractors.take(3)]..shuffle(_random);
  }

  void _handleAnswer(String selectedReading) {
    if (_isGameOver) return;

    final isCorrect = selectedReading == _currentChar.hanVietReading;

    if (isCorrect) {
      _correctCount++;
      _consecutiveCorrect++;

      // Tăng combo sau mỗi 3 câu đúng
      if (_consecutiveCorrect % 3 == 0 && _combo < 5) {
        _combo++;
      }
      if (_combo > _maxCombo) _maxCombo = _combo;

      _score += 10 * _combo;
      _nextQuestion();
    } else {
      _wrongCount++;
      _combo = 1;
      _consecutiveCorrect = 0;
      // Phạt trừ 2 giây
      _secondsRemaining = max(0, _secondsRemaining - 2);

      setState(() => _flashRed = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _flashRed = false);
      });

      if (_secondsRemaining <= 0) {
        _endGame();
        return;
      }
      _nextQuestion();
    }

    setState(() {});
  }

  void _endGame() {
    _gameTimer?.cancel();
    _isGameOver = true;

    final xpEarned = max(10, (_score / 10).round());
    final gemsEarned = max(5, (_score / 50).round());

    widget.appState.saveSpeedChallengeScore(
      _score,
      xpEarned: xpEarned,
      gemsEarned: gemsEarned,
    );

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isGameOver) {
      return _buildGameOverView();
    }

    final timeProgress = _secondsRemaining / _initialTime;
    final timeColor = _secondsRemaining <= 10
        ? kRed
        : _secondsRemaining <= 25
            ? kOrange
            : kGreen;

    return Scaffold(
      backgroundColor: _flashRed ? const Color(0xFFFFEBEE) : kPaper,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 6),
            Text('Thử thách 60s', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded, color: kOrange, size: 20),
                const SizedBox(width: 4),
                Text('COMBO x$_combo', style: const TextStyle(fontWeight: FontWeight.w900, color: kOrange, fontSize: 13)),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: LinearProgressIndicator(
            value: timeProgress,
            minHeight: 8,
            backgroundColor: const Color(0xFFE4E9E3),
            color: timeColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Bảng thời gian & điểm số
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer_rounded, color: timeColor, size: 24),
                      const SizedBox(width: 6),
                      Text(
                        '${_secondsRemaining}s',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: timeColor),
                      ),
                    ],
                  ),
                  Text(
                    '$_score ĐIỂM',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF20372C)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Thẻ hiển thị chữ Hán to ở giữa
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFD6E3D7), width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentChar.character,
                        style: const TextStyle(
                          fontSize: 118,
                          height: 1.1,
                          fontWeight: FontWeight.w500,
                          color: kGreen,
                          fontFamilyFallback: ['NomNaTong', 'HanNomB'],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Nghĩa: ${_currentChar.meaning}',
                        style: const TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4 nút chọn đáp án tốc độ cao
              const Text('CHỌN ÂM HÁN-VIỆT ĐÚNG THẬT NHANH!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: Colors.black45)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _options.length,
                itemBuilder: (context, index) {
                  final reading = _options[index];
                  return FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF20372C),
                      side: const BorderSide(color: Color(0xFFD2E0D4), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 1,
                    ),
                    onPressed: () => _handleAnswer(reading),
                    child: Text(
                      reading.toUpperCase(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Màn hình Game Over / Báo cáo thành tích 60 giây
  Widget _buildGameOverView() {
    final isNewRecord = _score > widget.appState.speedChallengeHighScore;
    final xpEarned = max(10, (_score / 10).round());
    final gemsEarned = max(5, (_score / 50).round());

    return Scaffold(
      backgroundColor: kPaper,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD27A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flash_on_rounded, size: 56, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Hết giờ! ⚡',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF20372C)),
                ),
                const SizedBox(height: 6),
                if (isNewRecord)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE9AA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('🏆 KỶ LỤC MỚI CỦA BẠN!', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF9A6D0D))),
                  )
                else
                  Text('Kỷ lục hiện tại: ${widget.appState.speedChallengeHighScore} điểm', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE4E9E3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_score',
                        style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: kGreen),
                      ),
                      const Text('TỔNG ĐIỂM ĐẠT ĐƯỢC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black45, letterSpacing: 1.1)),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(label: 'Đúng', value: '$_correctCount', color: kGreen),
                          _StatItem(label: 'Sai', value: '$_wrongCount', color: kRed),
                          _StatItem(label: 'Max Combo', value: 'x$_maxCombo', color: kOrange),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                          const SizedBox(width: 4),
                          Text('+$xpEarned XP', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF9A6D0D))),
                          const SizedBox(width: 16),
                          const Icon(Icons.diamond_rounded, color: kBlue, size: 20),
                          const SizedBox(width: 4),
                          Text('+$gemsEarned Đá quý', style: const TextStyle(fontWeight: FontWeight.w900, color: kBlue)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kGreen,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    setState(() {
                      _score = 0;
                      _combo = 1;
                      _maxCombo = 1;
                      _consecutiveCorrect = 0;
                      _correctCount = 0;
                      _wrongCount = 0;
                      _secondsRemaining = _initialTime;
                      _isGameOver = false;
                      _nextQuestion();
                      _startGameTimer();
                    });
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Chơi lại 60 giây', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Về màn hình chính', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black54)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
