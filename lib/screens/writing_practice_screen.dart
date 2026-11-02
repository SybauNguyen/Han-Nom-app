import 'package:flutter/material.dart';

import '../data/han_character.dart';
import '../services/hanzi_stroke_service.dart';
import '../widgets/hanzi_canvas.dart';

const Color _kGreen = Color(0xFF28664F);
const Color _kGreenLight = Color(0xFFE4F1E8);
const Color _kOrange = Color(0xFFCC6B3D);
const Color _kRed = Color(0xFFD94343);

class WritingPracticeScreen extends StatefulWidget {
  final HanCharacter character;
  final WritingPracticeLevel initialLevel;

  const WritingPracticeScreen({
    super.key,
    required this.character,
    this.initialLevel = WritingPracticeLevel.guided,
  });

  @override
  State<WritingPracticeScreen> createState() => _WritingPracticeScreenState();
}

class _WritingPracticeScreenState extends State<WritingPracticeScreen> {
  final GlobalKey<HanziCanvasState> _canvasKey = GlobalKey<HanziCanvasState>();
  late WritingPracticeLevel _level;
  StrokeEvaluation? _lastEvaluation;
  double _scoreTotal = 0;
  int _evaluatedStrokes = 0;
  int _retryCount = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
  }

  String get _levelTitle {
    switch (_level) {
      case WritingPracticeLevel.guided:
        return 'Mức 1 · Viết theo mẫu';
      case WritingPracticeLevel.faint:
        return 'Mức 2 · Mẫu mờ';
      case WritingPracticeLevel.recall:
        return 'Mức 3 · Tự nhớ';
      case WritingPracticeLevel.review:
        return 'Mức 4 · Kiểm tra Review';
    }
  }

  String get _levelDescription {
    switch (_level) {
      case WritingPracticeLevel.guided:
        return 'Chữ mẫu hiện rõ để bạn bám theo từng nét.';
      case WritingPracticeLevel.faint:
        return 'Chữ mẫu chỉ còn rất mờ, giúp bạn tự căn nét.';
      case WritingPracticeLevel.recall:
        return 'Không hiện chữ mẫu. Hãy tự nhớ thứ tự và hình dạng nét.';
      case WritingPracticeLevel.review:
        return 'Không có mẫu và tiêu chí chấm nghiêm hơn để kiểm tra trí nhớ.';
    }
  }

  void _changeLevel(WritingPracticeLevel level) {
    if (_level == level) return;
    setState(() {
      _level = level;
      _lastEvaluation = null;
      _scoreTotal = 0;
      _evaluatedStrokes = 0;
      _retryCount = 0;
      _completed = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _canvasKey.currentState?.clear());
  }

  void _handleEvaluation(StrokeEvaluation result) {
    setState(() {
      _lastEvaluation = result;
      if (result.correct) {
        _scoreTotal += result.score;
        _evaluatedStrokes++;
      } else {
        _retryCount++;
      }
    });
  }

  void _handleComplete() {
    setState(() => _completed = true);
  }

  int get _score {
    if (_evaluatedStrokes == 0) return 0;
    return ((_scoreTotal / _evaluatedStrokes) * 100).round().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final char = widget.character;
    final screenWidth = MediaQuery.of(context).size.width;
    final canvasSize = (screenWidth - 44).clamp(260.0, 360.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(char.isNom ? 'Luyện viết chữ Nôm' : 'Luyện viết Hán tự', style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: char.isNom ? const Color(0xFFFFEBDD) : _kGreenLight, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: Text(char.character, style: TextStyle(fontSize: 32, color: char.isNom ? _kOrange : _kGreen, fontWeight: FontWeight.bold, fontFamilyFallback: const ['NomNaTong', 'HanNomB'])),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(char.hanVietReading.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _kOrange)),
                        const SizedBox(height: 2),
                        Text('${char.meaning} • Bộ: ${char.radical.isEmpty ? '—' : char.radical}', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF334A3C))),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _LevelSelector(level: _level, onChanged: _changeLevel),
              const SizedBox(height: 8),
              Text(_levelDescription, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.35)),
              const SizedBox(height: 14),
              HanziCanvas(
                key: _canvasKey,
                character: char.character,
                size: canvasSize,
                level: _level,
                onStrokeEvaluated: _handleEvaluation,
                onComplete: _handleComplete,
              ),
              const SizedBox(height: 10),
              if (_lastEvaluation != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _lastEvaluation!.correct ? const Color(0xFFE4F5E8) : const Color(0xFFFFE9E7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(_lastEvaluation!.correct ? Icons.check_circle_rounded : Icons.refresh_rounded,
                        color: _lastEvaluation!.correct ? _kGreen : _kRed),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_lastEvaluation!.feedback,
                        style: TextStyle(fontWeight: FontWeight.w800, color: _lastEvaluation!.correct ? _kGreen : _kRed))),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _kOrange, foregroundColor: Colors.white, minimumSize: const Size(220, 42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  final state = _canvasKey.currentState;
                  if (state == null) return;
                  if (state.isDemonstrating) state.stopStrokeAnimation(); else state.playStrokeAnimation();
                  setState(() {});
                },
                icon: Icon(_canvasKey.currentState?.isDemonstrating == true ? Icons.pause_rounded : Icons.play_circle_filled_rounded, size: 20),
                label: const Text('Xem cách viết (Bút thuận)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                OutlinedButton.icon(onPressed: () => _canvasKey.currentState?.undo(), icon: const Icon(Icons.undo_rounded, size: 19), label: const Text('Nét trước', style: TextStyle(fontSize: 13))),
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: () => _canvasKey.currentState?.clear(), icon: const Icon(Icons.delete_outline_rounded, size: 19, color: _kRed), label: const Text('Làm lại', style: TextStyle(fontSize: 13, color: _kRed))),
              ]),
              const SizedBox(height: 12),
              Text(_completed ? 'Hoàn thành chữ · $_score/100' : 'Mức: $_levelTitle', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 13)),
              if (_evaluatedStrokes > 0) ...[
                const SizedBox(height: 6),
                Text('Đúng $_evaluatedStrokes nét · Viết lại $_retryCount lần', style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _completed ? () => Navigator.of(context).pop() : null,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(_completed ? 'Hoàn tất luyện viết' : 'Viết đủ các nét để hoàn tất'),
                ),
              ),
              if (_completed) ...[
                const SizedBox(height: 8),
                Text('Mức $_levelTitle đã hoàn thành. Ở Review, hệ thống sẽ dùng Mức 4 để kiểm tra lại.',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelSelector extends StatelessWidget {
  final WritingPracticeLevel level;
  final ValueChanged<WritingPracticeLevel> onChanged;

  const _LevelSelector({required this.level, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<WritingPracticeLevel>(
      segments: const [
        ButtonSegment(value: WritingPracticeLevel.guided, label: Text('M1'), icon: Icon(Icons.edit_rounded, size: 15)),
        ButtonSegment(value: WritingPracticeLevel.faint, label: Text('M2'), icon: Icon(Icons.blur_on_rounded, size: 15)),
        ButtonSegment(value: WritingPracticeLevel.recall, label: Text('M3'), icon: Icon(Icons.visibility_off_rounded, size: 15)),
        ButtonSegment(value: WritingPracticeLevel.review, label: Text('M4'), icon: Icon(Icons.fact_check_rounded, size: 15)),
      ],
      selected: {level},
      onSelectionChanged: (selected) => onChanged(selected.first),
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
    );
  }
}
