import 'dart:math';
import 'package:flutter/material.dart';

import '../core/database/database_service.dart';
import '../core/theme/app_colors.dart';
import '../data/han_character.dart';
import '../data/han_seed_data.dart';
import '../data/models/cjk_character.dart';
import '../state/app_state.dart';
import '../widgets/type_badge.dart';
import '../widgets/character_pronunciation_controls.dart';

class FlashcardScreen extends StatefulWidget {
  final AppState appState;
  final DatabaseService? databaseService;

  const FlashcardScreen({
    super.key,
    required this.appState,
    this.databaseService,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> with SingleTickerProviderStateMixin {
  late List<HanCharacter> _deck;
  int _currentIndex = 0;
  bool _isFront = true;
  int _cardsMasteredCount = 0;
  int _cardsReviewNeededCount = 0;
  int _xpEarned = 0;
  bool _isSessionFinished = false;

  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _initDeck();
  }

  void _initDeck() {
    // Ưu tiên các chữ chưa thuộc (mastery < 3)
    final lowMastery = seedCharacters
        .where((c) => c.isHan && widget.appState.masteryOf(c.character) < 3)
        .toList()
      ..shuffle();

    if (lowMastery.length >= 12) {
      _deck = lowMastery.take(15).toList();
    } else {
      final all = seedCharacters.where((c) => c.isHan).toList()..shuffle();
      _deck = all.take(15).toList();
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  void _handleRating(int rating) {
    final currentCard = _deck[_currentIndex];

    if (rating == 3) {
      // Đã thuộc làu: tăng mastery +1, thưởng +5 XP
      _cardsMasteredCount++;
      _xpEarned += 5;
      final currentMastery = widget.appState.masteryOf(currentCard.character);
      widget.appState.updateMastery(currentCard.character, currentMastery + 1);
    } else if (rating == 1) {
      // Chưa thuộc: đưa về cuối hàng đợi để hỏi lại
      _cardsReviewNeededCount++;
      _deck.add(currentCard);
    }

    _flipController.reset();
    _isFront = true;

    if (_currentIndex + 1 < _deck.length) {
      setState(() {
        _currentIndex++;
      });
    } else {
      setState(() {
        _isSessionFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSessionFinished) {
      return _buildFinishedView();
    }

    final card = _deck[_currentIndex];
    final progress = (_currentIndex + 1) / _deck.length;

    return Scaffold(
      backgroundColor: kPaper,
      appBar: AppBar(
        title: const Text('Lật thẻ Flashcard', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE4E9E3),
            color: kGreen,
            minHeight: 5,
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Thẻ ${_currentIndex + 1}/${_deck.length}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: kGreen, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  child: GestureDetector(
                    onTap: _flipCard,
                    child: AnimatedBuilder(
                      animation: _flipAnimation,
                      builder: (context, _) {
                        final angle = _flipAnimation.value * pi;
                        final isUnderHalf = _flipAnimation.value < 0.5;

                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // 3D Perspective
                            ..rotateY(angle),
                          child: isUnderHalf
                              ? _buildFrontCard(card)
                              : Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..rotateY(pi),
                                  child: _buildBackCard(card),
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Thanh 3 nút đánh giá trí nhớ
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isFront ? 'Chạm vào thẻ để lật xem đáp án' : 'Bạn nhớ chữ này thế nào?',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kRed,
                            side: const BorderSide(color: Color(0xFFFFCDD2)),
                            backgroundColor: const Color(0xFFFFF5F5),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _handleRating(1),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close_rounded, size: 22),
                              SizedBox(height: 3),
                              Text('Chưa nhớ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB98216),
                            side: const BorderSide(color: Color(0xFFFFECB3)),
                            backgroundColor: const Color(0xFFFFFDF5),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _handleRating(2),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.help_outline_rounded, size: 22),
                              SizedBox(height: 3),
                              Text('Tạm nhớ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: kGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _handleRating(3),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded, size: 22),
                              SizedBox(height: 3),
                              Text('Đã thuộc', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mặt trước thẻ Flashcard
  Widget _buildFrontCard(HanCharacter card) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 460),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD6E3D7), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TypeBadge(type: card.type, compact: true),
              CharacterPronunciationControls(
                hanVietReading: card.hanVietReading,
                supplementaryLanguage: widget.appState.supplementaryLanguage,
                cjkCharacter: widget.appState.cjkCharacterFor(card.character),
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              card.character,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 108,
                height: 1.1,
                fontWeight: FontWeight.w500,
                color: kGreen,
                fontFamilyFallback: ['NomNaTong', 'HanNomB'],
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: kGreenLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded, color: kGreen, size: 16),
                SizedBox(width: 6),
                Text('Chạm để lật xem nghĩa & âm đọc', style: TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mặt sau thẻ Flashcard
  Widget _buildBackCard(HanCharacter card) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 460),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FDF9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kGreen, width: 2.0),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.character,
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: kGreen, fontFamilyFallback: ['NomNaTong', 'HanNomB']),
                ),
                CharacterPronunciationControls(
                  hanVietReading: card.hanVietReading,
                  supplementaryLanguage: widget.appState.supplementaryLanguage,
                  cjkCharacter: widget.appState.cjkCharacterFor(card.character),
                ),
              ],
            ),
            const Divider(color: Color(0xFFD6E3D7), height: 24),
            Text(
              card.hanVietReading.toUpperCase(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kOrange, letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              card.meaning,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF20372C), height: 1.3),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Bộ thủ: ${card.radical.isEmpty ? "—" : card.radical} • Cấu tạo: ${card.structure}',
                style: const TextStyle(fontSize: 12, color: kOrange, fontWeight: FontWeight.w800),
              ),
            ),
            if (card.mnemonic != null && card.mnemonic!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7DF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded, size: 18, color: Color(0xFFB98216)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        card.mnemonic!,
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF5E4A25), height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (card.examples.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ví dụ: ${card.examples.join(", ")}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Màn hình kết thúc buổi học Flashcard
  Widget _buildFinishedView() {
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
                    color: Color(0xFFFFE9B5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, size: 54, color: kOrange),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Hoàn thành buổi Flashcard!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF20372C)),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bạn đã xem hết ${_deck.length} lượt thẻ flashcard.',
                  style: const TextStyle(color: Colors.black54, fontSize: 15),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE4E9E3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(label: 'Đã thuộc', value: '$_cardsMasteredCount', color: kGreen),
                      Container(width: 1, height: 40, color: const Color(0xFFE4E9E3)),
                      _StatColumn(label: 'Cần ôn lại', value: '$_cardsReviewNeededCount', color: kRed),
                      Container(width: 1, height: 40, color: const Color(0xFFE4E9E3)),
                      _StatColumn(label: 'XP nhận được', value: '+$_xpEarned', color: kOrange),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kGreen,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                      _cardsMasteredCount = 0;
                      _cardsReviewNeededCount = 0;
                      _xpEarned = 0;
                      _isSessionFinished = false;
                      _initDeck();
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Ôn tiếp 15 thẻ khác', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
