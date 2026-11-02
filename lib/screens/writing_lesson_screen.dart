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
  int _index = 0;
  int _completedCharacters = 0;
  int _retryCount = 0;
  String? _feedback;
  bool _lastCorrect = false;

  HanCharacter get _character => widget.characters[_index];

  Future<void> _onCompleteCharacter() async {
    if (!mounted) return;
    setState(() {
      _completedCharacters++;
      _lastCorrect = true;
      _feedback = 'Chính xác! Chữ ${_character.character} đã hoàn thành.';
    });
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    if (_index < widget.characters.length - 1) {
      setState(() {
        _index++;
        _feedback = null;
        _lastCorrect = false;
      });
    } else {
      Navigator.of(context).pop(true);
    }
  }

  void _onEvaluation(StrokeEvaluation result) {
    if (!mounted) return;
    setState(() {
      _lastCorrect = result.correct;
      _feedback = result.feedback;
      if (!result.correct) _retryCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final char = _character;
    final canvasSize = (MediaQuery.of(context).size.width - 44).clamp(260.0, 360.0);
    final progress = (_index + 1) / widget.characters.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).maybePop()),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(value: progress, minHeight: 9, backgroundColor: const Color(0xFFE0E7DF), color: _green),
        ),
        actions: [Padding(padding: const EdgeInsets.only(right: 15), child: Text('${_index + 1}/${widget.characters.length}', style: const TextStyle(fontWeight: FontWeight.w900)))],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            children: [
              Text(widget.reviewMode ? 'REVIEW · KIỂM TRA VIẾT' : 'PHẦN 4 · LUYỆN VIẾT', style: const TextStyle(color: _green, letterSpacing: 1.2, fontWeight: FontWeight.w900, fontSize: 12)),
              const SizedBox(height: 8),
              Text(widget.level == WritingPracticeLevel.review ? 'Tự nhớ và viết đúng từng nét' : 'Viết từng nét · đúng mới sang nét sau', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF20372C)), textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: char.isNom ? const Color(0xFFFFEBDD) : const Color(0xFFE4F1E8), borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  Text(char.character, style: TextStyle(fontSize: 42, color: char.isNom ? _orange : _green, fontWeight: FontWeight.bold, fontFamilyFallback: const ['NomNaTong', 'HanNomB'])),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(char.hanVietReading.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _orange)),
                    Text(char.meaning, style: const TextStyle(fontSize: 13, color: Color(0xFF334A3C))),
                  ])),
                ]),
              ),
              const SizedBox(height: 14),
              HanziCanvas(
                key: _canvasKey,
                character: char.character,
                size: canvasSize,
                level: widget.level,
                onStrokeEvaluated: _onEvaluation,
                onComplete: _onCompleteCharacter,
              ),
              const SizedBox(height: 10),
              if (_feedback != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: _lastCorrect ? const Color(0xFFE4F5E8) : const Color(0xFFFFE9E7), borderRadius: BorderRadius.circular(14)),
                  child: Text(_feedback!, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: _lastCorrect ? _green : const Color(0xFFD94343))),
                ),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                OutlinedButton.icon(onPressed: () => _canvasKey.currentState?.undo(), icon: const Icon(Icons.undo_rounded, size: 18), label: const Text('Nét trước')),
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: () => _canvasKey.currentState?.clear(), icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Viết lại')),
              ]),
              const SizedBox(height: 8),
              Text('Đã hoàn thành $_completedCharacters/${widget.characters.length} chữ · Viết lại $_retryCount lần', style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ],
          ),
        ),
      ),
    );
  }
}
