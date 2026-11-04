import 'dart:math';

import 'package:flutter/material.dart';

import '../data/han_character.dart';
import '../services/hanzi_stroke_service.dart';
import '../state/app_state.dart';
import '../widgets/hanzi_canvas.dart';

const Color _green = Color(0xFF28664F);
const Color _orange = Color(0xFFCC6B3D);

class WritingLessonScreen extends StatefulWidget {
  final AppState appState;
  final List<HanCharacter> characters;
  final String trackType;
  final int? trackLessonNumber;
  final WritingPracticeLevel level;
  final bool reviewMode;

  const WritingLessonScreen({
    super.key,
    required this.appState,
    required this.characters,
    required this.trackType,
    this.trackLessonNumber,
    this.level = WritingPracticeLevel.guided,
    this.reviewMode = false,
  });

  @override
  State<WritingLessonScreen> createState() => _WritingLessonScreenState();
}

class _WritingLessonScreenState extends State<WritingLessonScreen> {
  final GlobalKey<HanziCanvasState> _canvasKey = GlobalKey<HanziCanvasState>();
  late List<HanCharacter> _roundCharacters;
  int _index = 0;
  int _round = 0;
  int _completedCharacters = 0;
  int _retryCount = 0;
  int _failedAttemptsForCurrentCharacter = 0;
  String? _feedback;
  bool _lastCorrect = false;
  bool _showFaintTemplate = false;
  bool _advancingCharacter = false;

  HanCharacter get _character => _roundCharacters[_index];
  int get _roundCount => widget.reviewMode ? 1 : 2;
  bool get _isRecallRound => _round == 1 && !widget.reviewMode;

  @override
  void initState() {
    super.initState();
    _roundCharacters = List<HanCharacter>.from(widget.characters);
  }

  void _onEvaluation(StrokeEvaluation result) {
    if (!mounted) return;
    setState(() {
      _lastCorrect = result.correct;
      _feedback = result.feedback;
      if (!result.correct) {
        _retryCount++;
        if (_isRecallRound) {
          _failedAttemptsForCurrentCharacter++;
          if (_failedAttemptsForCurrentCharacter > 2) {
            _showFaintTemplate = true;
          }
        }
      }
    });
  }

  Future<void> _onCompleteCharacter() async {
    if (!mounted || _advancingCharacter) return;
    _advancingCharacter = true;
    final completedCharacter = _character;
    setState(() {
      _completedCharacters++;
      _lastCorrect = true;
      _feedback = 'Chính xác! Chữ ${completedCharacter.character} đã hoàn thành.';
    });

    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;

    if (_index < _roundCharacters.length - 1) {
      _canvasKey.currentState?.clear();
      setState(() {
        _index++;
        _failedAttemptsForCurrentCharacter = 0;
        _showFaintTemplate = false;
        _feedback = null;
        _lastCorrect = false;
        _advancingCharacter = false;
      });
      return;
    }

    if (_round == 0 && _roundCount == 2) {
      final shuffled = List<HanCharacter>.from(widget.characters)..shuffle(Random());
      _canvasKey.currentState?.clear();
      setState(() {
        _round = 1;
        _roundCharacters = shuffled;
        _index = 0;
        _failedAttemptsForCurrentCharacter = 0;
        _showFaintTemplate = false;
        _feedback = 'Lượt viết có mẫu đã hoàn tất. Hãy tự nhớ và viết lại các chữ theo thứ tự ngẫu nhiên.';
        _lastCorrect = true;
        _advancingCharacter = false;
      });
      return;
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  void _checkCharacter() {
    if (_advancingCharacter) return;
    _canvasKey.currentState?.checkWrittenCharacter();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.characters.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Luyện viết chữ')),
        body: const Center(child: Text('Chưa có chữ để luyện viết.')),
      );
    }

    final char = _character;
    final progress = ((_round * widget.characters.length) + _index + 1) /
        (widget.characters.length * _roundCount);
    final canvasLevel = widget.reviewMode
        ? widget.level
        : _round == 0
            ? WritingPracticeLevel.guided
            : (_showFaintTemplate ? WritingPracticeLevel.faint : WritingPracticeLevel.recall);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 9,
            backgroundColor: const Color(0xFFE0E7DF),
            color: _green,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Text(
              '${_index + 1}/${widget.characters.length}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      // The writing surface intentionally has no scrollable parent. Vertical
      // drags therefore stay on the canvas instead of scrolling the page.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth - 36;
            final availableHeight = constraints.maxHeight;
            final canvasSize = min(
              340.0,
              min(availableWidth, availableHeight * 0.36),
            ).clamp(176.0, 320.0).toDouble();

            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 7, 18, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    widget.reviewMode ? 'REVIEW · KIỂM TRA VIẾT' : 'PHẦN LUYỆN VIẾT',
                    style: const TextStyle(
                      color: _green,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.reviewMode
                        ? 'Tự nhớ và viết chữ'
                        : _isRecallRound
                            ? 'Lượt 2/2 · Tự viết không có gợi ý'
                            : 'Lượt 1/2 · Viết theo mẫu',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF20372C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_isRecallRound) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Mẫu mờ chỉ xuất hiện sau 3 lần kiểm tra sai.',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: char.isNom ? const Color(0xFFFFEBDD) : const Color(0xFFE4F1E8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        if (!_isRecallRound)
                          Text(
                            char.character,
                            style: TextStyle(
                              fontSize: 38,
                              color: char.isNom ? _orange : _green,
                              fontWeight: FontWeight.bold,
                              fontFamilyFallback: const ['NomNaTong', 'HanNomB'],
                            ),
                          )
                        else
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.edit_rounded, color: _green, size: 25),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                char.hanVietReading.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: _orange,
                                ),
                              ),
                              Text(
                                char.meaning,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF334A3C)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: HanziCanvas(
                      key: _canvasKey,
                      character: char.character,
                      size: canvasSize,
                      level: canvasLevel,
                      showStrokeOrderHints: !_isRecallRound && !widget.reviewMode,
                      onStrokeEvaluated: _onEvaluation,
                      onComplete: _onCompleteCharacter,
                    ),
                  ),
                  if (_feedback != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: _lastCorrect ? const Color(0xFFE4F5E8) : const Color(0xFFFFE9E7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _feedback!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _lastCorrect ? _green : const Color(0xFFD94343),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          minimumSize: const Size(0, 34),
                        ),
                        onPressed: _advancingCharacter ? null : () => _canvasKey.currentState?.undo(),
                        icon: const Icon(Icons.undo_rounded, size: 16),
                        label: const Text('Nét trước', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          minimumSize: const Size(0, 34),
                        ),
                        onPressed: _advancingCharacter ? null : () => _canvasKey.currentState?.clear(),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Viết lại', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _advancingCharacter ? null : _checkCharacter,
                      icon: const Icon(Icons.fact_check_rounded, size: 18),
                      label: const Text('Kiểm tra chữ'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(42),
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Đã viết $_completedCharacters/${widget.characters.length * _roundCount} lượt chữ · Kiểm tra lại $_retryCount lần',
                    style: const TextStyle(fontSize: 10, color: Colors.black45),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
