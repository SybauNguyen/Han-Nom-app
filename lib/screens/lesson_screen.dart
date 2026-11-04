import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/han_character.dart';
import '../data/han_seed_data.dart';
import '../data/question.dart';
import '../services/ad_service.dart';
import '../state/app_state.dart';
import '../widgets/fill_in_the_blank_widget.dart';
import '../widgets/hanzi_canvas.dart';
import '../widgets/interactive_sentence.dart';
import '../widgets/introduce_word_widget.dart';
import '../widgets/matching_pairs_widget.dart';
import '../widgets/stats_widgets.dart';
import '../widgets/translate_sentence_widget.dart';
import '../widgets/type_badge.dart';
import 'writing_lesson_screen.dart';

class LessonScreen extends StatefulWidget {
  final AppState appState;
  final int? lessonIndex;
  /// Track độc lập: 'Hán' hoặc 'Nôm'.
  final String trackType;
  /// Số bài trong track (1-based), không phải chỉ số toàn cục.
  final int? trackLessonNumber;
  final bool reviewMode;
  final bool isJumpAhead;
  /// Mốc ôn tập định kỳ (1-based); null khi là bài thường/ôn tập tự do.
  final int? checkpointIndex;
  /// Số bài 1-based cần mở khóa sau khi vượt qua bài thi.
  final int targetIndex;

  const LessonScreen({
    super.key,
    required this.appState,
    this.lessonIndex,
    this.trackType = 'Hán',
    this.trackLessonNumber,
    this.reviewMode = false,
    this.isJumpAhead = false,
    this.checkpointIndex,
    this.targetIndex = 1,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final List<HanCharacter> _characters;
  late final List<Question> _questions;
  late final bool _isActivePartLesson;
  late final int _lessonPart;

  bool get _isRegularHanLesson => widget.trackType == 'Hán' &&
      widget.trackLessonNumber != null &&
      !widget.reviewMode && !widget.isJumpAhead && widget.checkpointIndex == null;
  int _questionIndex = 0;
  String? _selectedOption;
  bool _checked = false;
  bool _isCorrect = false;
  bool _finishing = false;
  bool _outOfHeartsDialogOpen = false;
  bool _jumpAheadFailureDialogOpen = false;
  bool _writingStageOpened = false;
  bool _matchingMistakeCharged = false;
  int _jumpAheadHearts = 5;
  final Set<String> _correctCharacters = {};
  final TextEditingController _typingController = TextEditingController();

  Question get _question => _questions[_questionIndex];

  bool get _isWritingStage =>
      _isActivePartLesson && (_lessonPart == 2 || _lessonPart == 4);

  bool get _hasHeartsLeft =>
      widget.isJumpAhead ? _jumpAheadHearts > 0 : widget.appState.hearts > 0;

  List<HanCharacter> get _writingCharacters {
    final splitAt = (_characters.length ~/ 2).clamp(1, _characters.length).toInt();
    return _lessonPart == 2
        ? _characters.take(splitAt).toList()
        : _characters.skip(splitAt).toList();
  }

  @override
  void initState() {
    super.initState();
    _isActivePartLesson = _isRegularHanLesson && widget.trackLessonNumber == widget.appState.hanLessonsCompleted + 1;
    _lessonPart = _isActivePartLesson ? widget.appState.currentLessonPart : 1;
    if (widget.isJumpAhead) {
      _characters = randomJumpAheadCharacters(
        limit: 10,
        targetLessonNumber: widget.targetIndex,
      );
    } else if (widget.reviewMode && widget.checkpointIndex != null) {
      _characters = randomReviewCheckpointCharacters(checkpointNumber: widget.checkpointIndex!, limit: 20);
    } else if (widget.reviewMode) {
      final availableHanCount = widget.appState.hanLessonsCompleted > widget.appState.unlockedHanThroughLesson
          ? widget.appState.hanLessonsCompleted
          : widget.appState.unlockedHanThroughLesson;
      final availableUnits = widget.trackType == 'Nôm'
          ? nomLessonUnits.take(widget.appState.unlockedNomLessons)
          : hanLessonUnits.take(availableHanCount);
      final availableSymbols = availableUnits.expand((unit) => unit.characters).toSet();
      final availableCharacters = seedCharacters
          .where((character) => availableSymbols.contains(character.character))
          .toList();
      final masteryBuckets = <int, List<HanCharacter>>{};
      for (final character in availableCharacters) {
        masteryBuckets.putIfAbsent(widget.appState.masteryOf(character.character), () => <HanCharacter>[])
            .add(character);
      }
      final reviewPool = <HanCharacter>[];
      final reviewRandom = Random();
      for (final level in masteryBuckets.keys.toList()..sort()) {
        final bucket = masteryBuckets[level]!..shuffle(reviewRandom);
        reviewPool.addAll(bucket);
      }
      _characters = reviewPool.take(10).toList();
    } else if (widget.trackType == 'Nôm' && widget.trackLessonNumber != null) {
      final unitIndex = (widget.trackLessonNumber! - 1).clamp(0, nomLessonUnits.length - 1).toInt();
      final symbols = nomLessonUnits[unitIndex].characters;
      _characters = symbols.map(findCharacter).whereType<HanCharacter>().toList();
    } else if (widget.trackType == 'Hán' && widget.trackLessonNumber != null) {
      final unitIndex = (widget.trackLessonNumber! - 1).clamp(0, hanLessonUnits.length - 1).toInt();
      final symbols = hanLessonUnits[unitIndex].characters;
      _characters = symbols.map(findCharacter).whereType<HanCharacter>().toList();
    } else if (widget.lessonIndex != null) {
      final unitIndex = widget.lessonIndex!.clamp(0, hanLessonUnits.length - 1).toInt();
      final symbols = hanLessonUnits[unitIndex].characters;
      _characters = symbols.map(findCharacter).whereType<HanCharacter>().toList();
    } else {
      _characters = seedCharacters.take(4).toList();
    }

    if (_isWritingStage) {
      _questions = <Question>[];
      WidgetsBinding.instance.addPostFrameCallback((_) => _openWritingStage());
    } else {
      final knownChars = _knownCharactersForQuestionGeneration();
      final int questionPart;
      if (!_isActivePartLesson || _lessonPart == 5) {
        questionPart = 3;
      } else if (_lessonPart == 3) {
        questionPart = 2;
      } else {
        questionPart = 1;
      }
      if (widget.isJumpAhead) {
        _questions = generateAdvancedReviewQuestions(
          characters: _characters,
          knownCharacters: knownChars,
          mode: ReviewChallengeMode.jumpAhead,
          throughLessonNumber: widget.targetIndex - 1,
          encounteredContextualCharacters: _encounteredContextualCharactersForReview(),
        );
      } else if (widget.checkpointIndex != null) {
        _questions = generateAdvancedReviewQuestions(
          characters: _characters,
          knownCharacters: knownChars,
          mode: ReviewChallengeMode.checkpoint,
          throughLessonNumber: widget.checkpointIndex! * hanLessonsPerCycle,
          encounteredContextualCharacters: _encounteredContextualCharactersForReview(),
        );
      } else if (widget.reviewMode) {
        final availableThrough = widget.appState.hanLessonsCompleted > widget.appState.unlockedHanThroughLesson
            ? widget.appState.hanLessonsCompleted
            : widget.appState.unlockedHanThroughLesson;
        _questions = generateAdvancedReviewQuestions(
          characters: _characters,
          knownCharacters: knownChars,
          mode: ReviewChallengeMode.dailyReview,
          throughLessonNumber: availableThrough,
          encounteredContextualCharacters: _encounteredContextualCharactersForReview(),
        );
      } else {
        _questions = generateLessonPartQuestions(
          _characters,
          knownCharacters: knownChars,
          part: questionPart,
          sectionLabel: _isActivePartLesson ? 'Phần $_lessonPart/5' : null,
          lessonNumber: widget.trackLessonNumber,
          allowContextualNewCharacters: !widget.isJumpAhead,
        );
      }
    }
  }

  Future<void> _openWritingStage() async {
    if (!mounted || _writingStageOpened || !_isWritingStage) return;
    _writingStageOpened = true;
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WritingLessonScreen(
          appState: widget.appState,
          characters: _writingCharacters,
          trackType: widget.trackType,
          trackLessonNumber: widget.trackLessonNumber,
          level: WritingPracticeLevel.guided,
        ),
      ),
    );
    if (!mounted) return;
    if (completed == true) {
      _correctCharacters.addAll(_writingCharacters.map((item) => item.character));
      await _finishLesson();
    } else {
      Navigator.of(context).pop();
    }
  }

  List<HanCharacter> _encounteredContextualCharactersForReview() {
    return widget.appState.encounteredContextualCharacters
        .map(findCharacter)
        .whereType<HanCharacter>()
        .map((character) => character.copyWith(
              mastery: widget.appState.masteryOf(character.character),
            ))
        .toList();
  }

  List<HanCharacter> _knownCharactersForQuestionGeneration() {
    final knownBySymbol = <String, HanCharacter>{};

    void addSymbols(Iterable<String> symbols) {
      for (final symbol in symbols) {
        final character = findCharacter(symbol);
        if (character != null && character.isHan) {
          knownBySymbol[symbol] = character.copyWith(mastery: widget.appState.masteryOf(symbol));
        }
      }
    }

    if (!widget.isJumpAhead && widget.checkpointIndex == null && !widget.reviewMode &&
        widget.trackType == 'Hán' && widget.trackLessonNumber != null) {
      final currentUnitIndex = (widget.trackLessonNumber! - 1).clamp(0, hanLessonUnits.length).toInt();
      addSymbols(hanLessonUnits.take(currentUnitIndex).expand((unit) => unit.characters));
      final partBeingStudied = _isActivePartLesson ? _lessonPart : 3;
      if (partBeingStudied == 1) {
        final splitAt = (_characters.length ~/ 2).clamp(1, _characters.length).toInt();
        addSymbols(_characters.take(splitAt).map((character) => character.character));
      } else {
        addSymbols(_characters.map((character) => character.character));
      }
    } else if (widget.isJumpAhead) {
      addSymbols(hanLessonUnits
          .take((widget.targetIndex - 1).clamp(0, hanLessonUnits.length).toInt())
          .expand((unit) => unit.characters));
    } else if (widget.checkpointIndex != null) {
      addSymbols(hanLessonUnits
          .take((widget.checkpointIndex! * hanLessonsPerCycle).clamp(0, hanLessonUnits.length).toInt())
          .expand((unit) => unit.characters));
    } else if (widget.reviewMode) {
      final count = widget.appState.hanLessonsCompleted > widget.appState.unlockedHanThroughLesson
          ? widget.appState.hanLessonsCompleted
          : widget.appState.unlockedHanThroughLesson;
      addSymbols(hanLessonUnits.take(count).expand((unit) => unit.characters));
    } else if (widget.trackType == 'Hán' && widget.lessonIndex != null) {
      final currentUnitIndex = widget.lessonIndex!.clamp(0, hanLessonUnits.length - 1).toInt();
      addSymbols(hanLessonUnits.take(currentUnitIndex).expand((unit) => unit.characters));
      addSymbols(_characters.map((character) => character.character));
    } else {
      addSymbols(_characters.map((character) => character.character));
    }

    addSymbols(widget.appState.encounteredContextualCharacters);

    return knownBySymbol.values.toList();
  }

  String _normalizeAnswer(String input) => input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[。．！？!?.,;:，；：、…]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Future<void> _checkAnswer() async {
    if (!_hasHeartsLeft || _selectedOption == null || _selectedOption!.trim().isEmpty || _checked) return;

    final typed = _normalizeAnswer(_selectedOption!);
    final accepted = _question.acceptedAnswers?.map(_normalizeAnswer).toList() ?? const <String>[];
    final isTypingQuestion = _question.type == QuestionType.typing ||
        _question.type == QuestionType.typingSentenceMeaning ||
        _question.type == QuestionType.typingSentenceReading;
    final correct = isTypingQuestion
        ? accepted.contains(typed) || typed == _normalizeAnswer(_question.correctAnswer)
        : (_question.type == QuestionType.translateSentence ||
                _question.type == QuestionType.translateHanVietToCharacter)
            ? typed == _normalizeAnswer(_question.correctAnswer)
            : _selectedOption == _question.correctAnswer;

    setState(() {
      _checked = true;
      _isCorrect = correct;
      if (correct) {
        if (_question.type == QuestionType.translateSentence ||
            _question.type == QuestionType.translateHanVietToCharacter ||
            _question.type == QuestionType.typingSentenceMeaning ||
            _question.type == QuestionType.typingSentenceReading) {
          _correctCharacters.addAll(_question.sentenceTokens?.map((token) => token.text) ?? <String>[_question.character]);
        } else {
          _correctCharacters.add(_question.character);
        }
      }
    });
    FocusManager.instance.primaryFocus?.unfocus();

    if (!correct) await _registerWrongAnswer();
  }

  void _completeMatchingQuestion() {
    if (!mounted || _checked) return;
    setState(() {
      _selectedOption = _question.correctAnswer;
      _checked = true;
      _isCorrect = true;
      _correctCharacters.addAll(_question.matchingPairs?.keys ?? <String>[_question.character]);
    });
  }

  Future<void> _registerMatchingMistake() async {
    if (!mounted || _checked || _matchingMistakeCharged || !_hasHeartsLeft) return;
    _matchingMistakeCharged = true;
    await _registerWrongAnswer();
  }

  Future<void> _registerWrongAnswer() async {
    if (widget.isJumpAhead) {
      if (_jumpAheadHearts <= 0) return;
      setState(() => _jumpAheadHearts--);
      if (_jumpAheadHearts == 0) await _showJumpAheadFailureDialog();
      return;
    }

    await widget.appState.recordWrongAnswer();
    if (!mounted) return;
    setState(() {});
    if (widget.appState.hearts <= 0) await _showOutOfHeartsDialog();
  }

  Future<void> _showJumpAheadFailureDialog() async {
    if (!mounted || _jumpAheadFailureDialogOpen || _jumpAheadHearts > 0) return;
    _jumpAheadFailureDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: const Icon(Icons.heart_broken_rounded, color: Color(0xFFE8B52B), size: 50),
          title: const Text('Học vượt chưa thành công', textAlign: TextAlign.center),
          content: const Text(
            'Bạn đã sử dụng hết 5 tim vàng của lượt thi này. Hãy thử lại khi sẵn sàng nhé. Tim thường của bạn không bị trừ.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('Thoát bài thi'),
            ),
          ],
        ),
      ),
    );
    _jumpAheadFailureDialogOpen = false;
  }

  Future<void> _showOutOfHeartsDialog() async {
    if (!mounted || _outOfHeartsDialogOpen || widget.appState.hearts > 0) return;
    _outOfHeartsDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AnimatedBuilder(
        animation: widget.appState,
        builder: (dialogContext, _) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: const Icon(Icons.heart_broken_rounded, color: kRed, size: 48),
          title: const Text('Hết tim rồi!', textAlign: TextAlign.center, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tim tự hồi khi bạn nghỉ học. Cứ mỗi 30 phút bạn sẽ nhận thêm 1 tim, kể cả khi đóng ứng dụng.', textAlign: TextAlign.center),
              const SizedBox(height: 10),
              if (widget.appState.hearts == 0) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.schedule_rounded, color: kRed, size: 20),
                const SizedBox(width: 8),
                const Text('Tim tiếp theo sau ', style: TextStyle(color: Colors.black54)),
                HeartCountdownText(appState: widget.appState, style: const TextStyle(fontWeight: FontWeight.w900, color: kRed)),
              ]) else ...[
                Text('Bạn đã hồi được ${widget.appState.hearts} tim.', textAlign: TextAlign.center, style: const TextStyle(color: kGreen, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Tiếp tục học'),
                ),
              ],
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () async {
                  final success = await widget.appState.buyHearts(cost: 350, amount: 5);
                  if (!mounted) return;
                  if (success) {
                    Navigator.of(dialogContext).pop();
                    setState(() {});
                  } else {
                    showDialog<void>(
                      context: context,
                      builder: (messageContext) => AlertDialog(
                        title: const Text('Chưa đủ đá quý'),
                        content: const Text('Bạn cần 350 đá quý để nạp đầy 5 tim.'),
                        actions: [TextButton(onPressed: () => Navigator.of(messageContext).pop(), child: const Text('Đã hiểu'))],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.diamond_rounded),
                label: const Text('Nạp đầy 5 tim · 350 đá quý'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await AdService.instance.showRewardedAd(
                    context,
                    rewardDescription: '1 Tim ❤️',
                    onRewardGranted: () async {
                      await widget.appState.addHeart(1);
                      if (mounted) setState(() {});
                    },
                  );
                },
                icon: const Icon(Icons.ondemand_video_rounded),
                label: const Text('Xem quảng cáo để nhận +1 tim'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text('Thoát bài học', style: TextStyle(color: kRed, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
    _outOfHeartsDialogOpen = false;
  }

  Future<void> _nextQuestion() async {
    if (!_checked) return;
    if (_questionIndex < _questions.length - 1) {
      setState(() {
        _questionIndex++;
        _selectedOption = null;
        _checked = false;
        _isCorrect = false;
        _matchingMistakeCharged = false;
        _typingController.clear();
      });
      return;
    }
    await _finishLesson();
  }

  Future<void> _finishLesson() async {
    if (_finishing || (widget.isJumpAhead && _jumpAheadHearts <= 0)) return;
    _finishing = true;
    await widget.appState.finishLesson(
      lessonIndex: widget.trackLessonNumber != null || widget.reviewMode || widget.isJumpAhead
          ? null
          : widget.lessonIndex,
      trackType: widget.trackType,
      trackLessonNumber: widget.reviewMode || widget.isJumpAhead || widget.checkpointIndex != null
          ? null
          : widget.trackLessonNumber,
      masteredCharacters: _correctCharacters,
      xpReward: widget.isJumpAhead ? 50 : _isActivePartLesson ? 15 : 20,
      lessonPart: _isActivePartLesson ? _lessonPart : null,
      unlockTargetLessonNumber: widget.isJumpAhead ? widget.targetIndex : null,
      reviewCheckpointNumber: widget.checkpointIndex,
      awardHeart: !widget.isJumpAhead,
    );
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Icon(widget.isJumpAhead ? Icons.rocket_launch_rounded : widget.checkpointIndex != null ? Icons.workspace_premium_rounded : Icons.celebration_rounded, color: kOrange, size: 52),
        title: Text(
          widget.isJumpAhead ? 'Nhảy cóc thành công! 🚀'
              : widget.checkpointIndex != null ? 'Tổng Ôn tập hoàn thành! 🏆'
              : widget.reviewMode ? 'Ôn tập hoàn tất!'
              : _isActivePartLesson ? 'Hoàn thành Phần $_lessonPart/5! 🎉'
              : 'Hoàn thành bài học!',
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Bạn trả lời đúng ${_correctCharacters.length} chữ khác nhau.'),
          const SizedBox(height: 10),
          Text(
            widget.isJumpAhead
                ? 'Bạn đã mở khóa Bài ${widget.targetIndex}!\n+50 XP     +5 đá quý'
                : widget.checkpointIndex != null
                    ? 'Bạn đã hoàn thành Tổng Ôn tập ${widget.checkpointIndex} và mở cụm bài tiếp theo!\n+20 XP     +5 đá quý'
                    : _isActivePartLesson
                        ? (_lessonPart < 5
                            ? 'Phần ${_lessonPart + 1}/5 đã được mở khóa. Quay về lộ trình để tiếp tục bài học.\n+15 XP     +5 đá quý'
                            : ((widget.trackLessonNumber ?? 0) % hanLessonsPerCycle == 0
                                ? 'Bạn đã hoàn tất đủ 5 phần! Tổng Ôn tập đã mở khóa.\n+15 XP     +5 đá quý'
                                : 'Bạn đã hoàn tất đủ 5 phần và mở khóa bài tiếp theo!\n+15 XP     +5 đá quý'))
                        : '+20 XP     +5 đá quý',
            textAlign: TextAlign.center,
            style: const TextStyle(color: kGreen, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ]),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (mounted) Navigator.of(context).pop();
            },
            child: Text(_isActivePartLesson ? 'Về lộ trình' : 'Tiếp tục'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isWritingStage) {
      return Scaffold(
        backgroundColor: kPaper,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text('Đang mở phần luyện viết'),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chuẩn bị khu vực luyện viết chữ Hán…'),
            ],
          ),
        ),
      );
    }
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: kPaper,
        appBar: AppBar(backgroundColor: kPaper, title: const Text('Chưa có bài để ôn')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Hãy hoàn thành một bài học trước. Các câu dịch chỉ xuất hiện khi có cụm/câu phù hợp và toàn bộ chữ đã được học.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ),
      );
    }
    final question = _question;
    final character = findCharacter(question.character);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: widget.isJumpAhead ? 178 : null,
        leading: widget.isJumpAhead
            ? Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 42),
                  ),
                  ...List.generate(
                    5,
                    (index) => Icon(
                      Icons.favorite_rounded,
                      size: 20,
                      color: index < _jumpAheadHearts
                          ? const Color(0xFFFFC62E)
                          : const Color(0xFFD9D9D9),
                    ),
                  ),
                ],
              )
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(value: (_questionIndex + 1) / _questions.length, minHeight: 9, backgroundColor: const Color(0xFFE0E7DF), color: kGreen),
        ),
        actions: widget.isJumpAhead
            ? const []
            : [
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: HeartAppBarStatus(appState: widget.appState),
                ),
              ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                children: [
                  Text(
                    widget.isJumpAhead
                        ? 'BÀI THI HỌC VƯỢT · MỞ KHÓA BÀI ${widget.targetIndex}'
                        : widget.checkpointIndex != null
                            ? 'TỔNG ÔN TẬP ${widget.checkpointIndex}'
                            : widget.reviewMode
                                ? 'ÔN TẬP CÁ NHÂN'
                                : widget.trackLessonNumber != null
                                    ? '${widget.trackType == 'Nôm' ? 'CHỮ NÔM' : 'HÁN TỰ'} · BÀI ${widget.trackLessonNumber}${_isActivePartLesson ? ' · PHẦN $_lessonPart/5' : ''}'
                                    : 'BÀI ${(widget.lessonIndex ?? 0) + 1}',
                    style: const TextStyle(color: kGreen, letterSpacing: 1.2, fontWeight: FontWeight.w900, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 7),
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFFFF1D7), borderRadius: BorderRadius.circular(12)),
                    child: Text(question.sectionTitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF9A5A20), fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  const SizedBox(height: 10),
                  Center(child: TypeBadge(type: question.characterType, compact: true)),
                  const SizedBox(height: 14),
                  Text(question.prompt, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, height: 1.2, color: Color(0xFF20372C), fontFamilyFallback: ['NomNaTong', 'HanNomB']), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  if (question.type == QuestionType.introduceWord)
                    IntroduceWordWidget(
                      key: ValueKey('introduce-word-$_questionIndex'),
                      question: question,
                      selectedAnswer: _selectedOption,
                      enabled: !_checked && _hasHeartsLeft,
                      supplementaryLanguage: widget.appState.supplementaryLanguage,
                      cjkCharacters: widget.appState.cjkCharacters,
                      tapEnabled: !widget.isJumpAhead,
                      phraseMeaning: question.mnemonic,
                      onCharacterTapped: (character) => unawaited(widget.appState.markContextualCharacterEncountered(character)),
                      onSelected: (answer) {
                        if (!_checked) setState(() => _selectedOption = answer);
                      },
                    )
                  else if (question.type == QuestionType.fillInTheBlank && question.sentenceTokens != null)
                    FillInTheBlankWidget(
                      tokens: question.sentenceTokens!,
                      options: question.options,
                      selectedAnswer: _selectedOption,
                      correctAnswer: question.correctAnswer,
                      checked: _checked,
                      isCorrect: _isCorrect,
                      tapEnabled: !widget.isJumpAhead,
                      phraseMeaning: question.mnemonic,
                      onCharacterTapped: (character) => unawaited(widget.appState.markContextualCharacterEncountered(character)),
                      onSelected: (answer) { if (_hasHeartsLeft) setState(() => _selectedOption = answer); },
                    )
                  else if (question.type == QuestionType.matchingPairs)
                    MatchingPairsWidget(
                      key: ValueKey('matching-question-$_questionIndex'),
                      pairs: question.matchingPairs ?? const <String, String>{},
                      enabled: !_checked && _hasHeartsLeft,
                      onComplete: _completeMatchingQuestion,
                      onMistake: _registerMatchingMistake,
                    )
                  else if (question.type == QuestionType.translateSentence ||
                      question.type == QuestionType.translateHanVietToCharacter)
                    TranslateSentenceWidget(
                      key: ValueKey('translate-question-$_questionIndex'),
                      question: question,
                      reverseDirection: question.type == QuestionType.translateHanVietToCharacter,
                      tapEnabled: !widget.isJumpAhead,
                      phraseMeaning: question.mnemonic,
                      onCharacterTapped: (character) => unawaited(widget.appState.markContextualCharacterEncountered(character)),
                      enabled: !_checked && _hasHeartsLeft,
                      onAnswerChanged: (answer) {
                        if (!_checked && _hasHeartsLeft) setState(() => _selectedOption = answer);
                      },
                    )
                  else
                    Container(
                      constraints: const BoxConstraints(minHeight: 172),
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: question.characterType == 'Nôm' ? kNomLight : kGreenLight, borderRadius: BorderRadius.circular(24)),
                      alignment: Alignment.center,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        if (question.type == QuestionType.typingSentenceReading &&
                            question.sentenceTokens != null)
                          InteractiveSentence(
                            tokens: question.sentenceTokens!,
                            supplementaryLanguage: widget.appState.supplementaryLanguage,
                            cjkCharacters: widget.appState.cjkCharacters,
                            tapEnabled: !widget.isJumpAhead,
                            phraseMeaning: question.meaningExplanation,
                            onCharacterTapped: (character) => unawaited(widget.appState.markContextualCharacterEncountered(character)),
                            fontSize: 40,
                          )
                        else
                          Text(
                            question.type == QuestionType.character
                                ? (character?.meaning ?? '')
                                : question.type == QuestionType.typingSentenceMeaning
                                    ? (question.sourceText ?? question.character)
                                    : question.character,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: question.type == QuestionType.character
                                  ? 26
                                  : question.type == QuestionType.typingSentenceMeaning
                                      ? 38
                                      : 82,
                              height: question.type == QuestionType.typingSentenceMeaning ? 1.45 : null,
                              color: question.characterType == 'Nôm' ? kOrange : kGreen,
                              fontWeight: FontWeight.w700,
                              fontFamilyFallback: const ['NomNaTong', 'HanNomB'],
                            ),
                          ),
                        if (question.type == QuestionType.radical) ...[
                          const SizedBox(height: 8),
                          Text(question.characterType == 'Nôm' ? 'Cách đọc: ${character?.hanVietReading ?? ''}' : 'Âm Hán-Việt: ${character?.hanVietReading ?? ''}', style: const TextStyle(color: kOrange, fontWeight: FontWeight.w800)),
                        ],
                        if (question.type == QuestionType.typing ||
                            question.type == QuestionType.typingSentenceMeaning ||
                            question.type == QuestionType.typingSentenceReading) ...[
                          const SizedBox(height: 8),
                          Text(
                            question.type == QuestionType.typingSentenceReading
                                ? (widget.isJumpAhead
                                    ? 'Tự gõ âm Hán-Việt, không có gợi ý nghĩa'
                                    : 'Tự gõ âm Hán-Việt. Chạm vào từng chữ để xem nghĩa')
                                : question.type == QuestionType.typingSentenceMeaning
                                    ? 'Tự dịch cả câu, không có gợi ý đáp án'
                                    : 'Hãy tự nhớ âm đọc hoặc nghĩa',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: kGreen, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ]),
                    ),
                  const SizedBox(height: 18),
                  if (question.type == QuestionType.typing ||
                      question.type == QuestionType.typingSentenceMeaning ||
                      question.type == QuestionType.typingSentenceReading) ...[
                    TextField(
                      controller: _typingController,
                      enabled: !_checked && _hasHeartsLeft,
                      autofocus: false,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                      decoration: InputDecoration(
                        hintText: question.type == QuestionType.typingSentenceReading
                            ? 'Gõ âm Hán-Việt của cả câu…'
                            : question.type == QuestionType.typingSentenceMeaning
                                ? 'Gõ nghĩa tiếng Việt của cả câu…'
                                : question.characterType == 'Nôm'
                                    ? 'Nhập cách đọc tiếng Việt hoặc nghĩa…'
                                    : 'Nhập âm Hán-Việt hoặc nghĩa…',
                        filled: true,
                        fillColor: _checked ? (_isCorrect ? const Color(0xFFE4F5E8) : const Color(0xFFFFE9E7)) : Colors.white,
                      ),
                      onChanged: (value) => setState(() => _selectedOption = value),
                      onSubmitted: (_) { if (!_checked) _checkAnswer(); },
                    ),
                  ] else if (question.type != QuestionType.introduceWord &&
                      question.type != QuestionType.typingSentenceMeaning &&
                      question.type != QuestionType.typingSentenceReading &&
                      question.type != QuestionType.fillInTheBlank &&
                      question.type != QuestionType.matchingPairs &&
                      question.type != QuestionType.translateSentence &&
                      question.type != QuestionType.translateHanVietToCharacter) ...[
                    Text(
                      question.type == QuestionType.radical ? (question.characterType == 'Nôm' ? 'CHỌN THÀNH PHẦN GỢI NGHĨA' : 'CHỌN BỘ THỦ') : 'CHỌN MỘT ĐÁP ÁN',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: Colors.black45),
                    ),
                    const SizedBox(height: 10),
                    for (var index = 0; index < question.options.length; index++)
                      _AnswerOption(
                        label: question.options[index],
                        letter: String.fromCharCode(65 + index),
                        selected: _selectedOption == question.options[index],
                        checked: _checked,
                        correct: question.options[index] == question.correctAnswer,
                        onTap: _checked || !_hasHeartsLeft ? null : () => setState(() => _selectedOption = question.options[index]),
                      ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: BoxDecoration(
                color: _checked ? (_isCorrect ? const Color(0xFFEAF7ED) : const Color(0xFFFFF0EB)) : Colors.white,
                border: Border(top: BorderSide(color: _checked ? (_isCorrect ? const Color(0xFFBFE2C7) : const Color(0xFFFFC9BB)) : const Color(0xFFE8ECE7), width: 1.5)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                if (_checked) ...[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(_isCorrect ? Icons.check_circle_rounded : Icons.auto_awesome_rounded, color: _isCorrect ? kGreen : kOrange, size: 28),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      question.type == QuestionType.typingSentenceReading
                          ? (_isCorrect
                              ? 'Chính xác! Âm Hán-Việt đúng.'
                              : 'Chưa đúng. Âm Hán-Việt chính xác: ${question.correctAnswer}')
                          : _isCorrect
                              ? 'Chính xác! Xuất sắc.'
                              : (question.type == QuestionType.typing || question.type == QuestionType.typingSentenceMeaning)
                                  ? 'Đáp án đúng: ${(question.acceptedAnswers ?? [question.correctAnswer]).join(" / ")}'
                                  : 'Chưa đúng. Đáp án là: ${question.correctAnswer}',
                      style: TextStyle(fontSize: 17, height: 1.3, fontWeight: FontWeight.w900, color: _isCorrect ? kGreen : const Color(0xFF9E422E)),
                    )),
                  ]),
                  if (question.type == QuestionType.typingSentenceReading &&
                      (question.meaningExplanation ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD5E8DA)),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.translate_rounded, color: kGreen, size: 21),
                        const SizedBox(width: 9),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('NGHĨA TIẾNG VIỆT THAM KHẢO', style: TextStyle(fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w900, color: kGreen)),
                          const SizedBox(height: 4),
                          Text(question.meaningExplanation!, style: const TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w700, color: Color(0xFF263A2F))),
                          const SizedBox(height: 3),
                          const Text('Nghĩa có thể được diễn đạt theo nhiều cách; phần này dùng để tham khảo, không phải đáp án bạn cần gõ.', style: TextStyle(fontSize: 11, height: 1.35, color: Colors.black54)),
                        ])),
                      ]),
                    ),
                  ],
                  if (question.type != QuestionType.typingSentenceReading && !_isCorrect && question.mnemonic != null && question.mnemonic!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFF0DDA8))),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.lightbulb_rounded, color: Color(0xFFB98216), size: 21),
                        const SizedBox(width: 8),
                        Expanded(child: Text(question.mnemonic!, style: const TextStyle(fontSize: 13, height: 1.4, fontStyle: FontStyle.italic, color: Color(0xFF5E4A25)))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 13),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _checked ? (_isCorrect ? kGreen : kOrange) : kGreen, foregroundColor: Colors.white),
                    onPressed: _checked
                        ? _nextQuestion
                        : (_selectedOption == null || _selectedOption!.trim().isEmpty ? null : _checkAnswer),
                    child: Text(_checked
                      ? (_questionIndex == _questions.length - 1 ? 'Hoàn thành' : 'Tiếp tục')
                      : question.type == QuestionType.typingSentenceReading
                          ? 'Kiểm tra âm Hán-Việt'
                          : question.type == QuestionType.typingSentenceMeaning
                          ? 'Kiểm tra bản dịch'
                          : question.type == QuestionType.typing
                              ? 'Kiểm tra đáp án'
                              : question.type == QuestionType.matchingPairs
                                  ? 'Nối hết các cặp để tiếp tục'
                                  : question.type == QuestionType.translateHanVietToCharacter
                                      ? 'Kiểm tra chữ Hán'
                                      : question.type == QuestionType.translateSentence
                                          ? 'Kiểm tra âm Hán-Việt'
                                          : question.type == QuestionType.introduceWord
                                              ? 'Kiểm tra nghĩa'
                                              : 'Kiểm tra'),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final String label;
  final String letter;
  final bool selected;
  final bool checked;
  final bool correct;
  final VoidCallback? onTap;
  const _AnswerOption({required this.label, required this.letter, required this.selected, required this.checked, required this.correct, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color background = Colors.white;
    Color border = const Color(0xFFE1E7E0);
    Color textColor = const Color(0xFF263A2F);
    if (checked && correct) {
      background = const Color(0xFFE3F3E7);
      border = kGreen;
      textColor = kGreen;
    } else if (checked && selected && !correct) {
      background = const Color(0xFFFFE9E7);
      border = kRed;
      textColor = kRed;
    } else if (selected) {
      background = kGreenLight;
      border = kGreen;
      textColor = kGreen;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: border, width: selected || (checked && correct) ? 1.7 : 1)),
            child: Row(children: [
              Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? border.withOpacity(0.12) : const Color(0xFFF2F4F0), borderRadius: BorderRadius.circular(10)), child: Text(letter, style: TextStyle(fontWeight: FontWeight.w900, color: textColor))),
              const SizedBox(width: 9),
              Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: textColor, fontSize: 14.5, fontFamilyFallback: const ['NomNaTong', 'HanNomB']))),
              if (checked && correct) const Icon(Icons.check_circle_rounded, color: kGreen),
            ]),
          ),
        ),
      ),
    );
  }
}
