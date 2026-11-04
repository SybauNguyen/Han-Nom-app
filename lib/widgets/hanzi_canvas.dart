import 'dart:math';
import 'package:flutter/material.dart';

import '../services/hanzi_stroke_service.dart';

enum WritingPracticeLevel { guided, faint, recall, review }

const Color _greenOrderHint = Color(0xFF28664F);

class HanziCanvas extends StatefulWidget {
  final String character;
  final double size;
  final WritingPracticeLevel level;
  final bool showStrokeOrderHints;
  final Function(int strokeCount)? onStrokeCountChanged;
  final ValueChanged<StrokeEvaluation>? onStrokeEvaluated;
  final VoidCallback? onComplete;

  const HanziCanvas({
    super.key,
    required this.character,
    this.size = 280,
    this.level = WritingPracticeLevel.guided,
    this.showStrokeOrderHints = false,
    this.onStrokeCountChanged,
    this.onStrokeEvaluated,
    this.onComplete,
  });

  @override
  State<HanziCanvas> createState() => HanziCanvasState();
}

class HanziCanvasState extends State<HanziCanvas> with SingleTickerProviderStateMixin {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;
  HanziStrokeData? _strokeData;
  bool _completed = false;
  bool _loadingStrokeData = true;
  bool _strokeDataUnavailable = false;
  StrokeEvaluation? _lastEvaluation;

  late final AnimationController _animController;
  bool _isDemonstrating = false;

  bool get isDemonstrating => _isDemonstrating;
  int get strokeCount => _strokes.length;
  int get totalStrokeCount => _strokeData?.strokeCount ?? 0;
  int get currentStrokeNumber => _strokes.length.clamp(0, totalStrokeCount).toInt();
  bool get isComplete => _completed;
  bool get isLoadingStrokeData => _loadingStrokeData;
  bool get strokeDataUnavailable => _strokeDataUnavailable;
  StrokeEvaluation? get lastEvaluation => _lastEvaluation;

  double get _templateOpacity {
    switch (widget.level) {
      case WritingPracticeLevel.guided:
        return 0.20;
      case WritingPracticeLevel.faint:
        return 0.08;
      case WritingPracticeLevel.recall:
      case WritingPracticeLevel.review:
        return 0.0;
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..addListener(() { if (mounted) setState(() {}); })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) setState(() => _isDemonstrating = false);
      });
    _loadStrokeData();
  }

  @override
  void didUpdateWidget(covariant HanziCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character != widget.character) {
      _resetForNewCharacter();
      _loadStrokeData();
    }
  }

  Future<void> _loadStrokeData() async {
    setState(() { _loadingStrokeData = true; _strokeDataUnavailable = false; });
    final data = await HanziStrokeService.instance.load(widget.character);
    if (!mounted) return;
    setState(() {
      _strokeData = data;
      _loadingStrokeData = false;
      _strokeDataUnavailable = data == null;
    });
    widget.onStrokeCountChanged?.call(_strokes.length);
  }

  void _resetForNewCharacter() {
    _strokes.clear();
    _currentStroke = null;
    _completed = false;
    _lastEvaluation = null;
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  void playStrokeAnimation() { setState(() => _isDemonstrating = true); _animController.forward(from: 0.0); }
  void stopStrokeAnimation() { _animController.stop(); if (mounted) setState(() => _isDemonstrating = false); }

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
      _completed = false;
      _lastEvaluation = null;
    });
    widget.onStrokeCountChanged?.call(0);
  }

  void undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.removeLast();
      _completed = false;
      _lastEvaluation = null;
    });
    widget.onStrokeCountChanged?.call(_strokes.length);
  }

  void _finishCurrentStroke() {
    final points = _currentStroke;
    _currentStroke = null;
    if (points == null) return;
    if (points.length < 2 && _strokes.isNotEmpty) {
      setState(() => _strokes.removeLast());
    }
    widget.onStrokeCountChanged?.call(_strokes.length);
  }

  /// Chỉ chấm khi người học chủ động bấm nút Kiểm tra.
  /// Từng nét được ghép với nét mẫu phù hợp nhất, không phụ thuộc thứ tự vẽ.
  StrokeEvaluation checkWrittenCharacter() {
    final data = _strokeData;
    if (_loadingStrokeData || data == null || _strokeDataUnavailable) {
      const result = StrokeEvaluation(
        correct: false,
        score: 0,
        feedback: 'Chưa tải được dữ liệu nét của chữ này. Hãy thử tải lại khi có mạng.',
      );
      _lastEvaluation = result;
      widget.onStrokeEvaluated?.call(result);
      return result;
    }

    final expectedCount = data.strokeCount;
    if (_strokes.length != expectedCount) {
      final result = StrokeEvaluation(
        correct: false,
        score: 0,
        feedback: _strokes.length < expectedCount
            ? 'Bạn đã viết ${_strokes.length}/$expectedCount nét. Hãy viết đủ rồi bấm kiểm tra.'
            : 'Bạn đang có ${_strokes.length} nét, nhiều hơn số nét chuẩn ($expectedCount). Hãy xóa hoặc gộp nét thừa.',
      );
      setState(() => _lastEvaluation = result);
      widget.onStrokeEvaluated?.call(result);
      return result;
    }

    final evaluations = List<List<StrokeEvaluation>>.generate(
      expectedCount,
      (userIndex) => List<StrokeEvaluation>.generate(expectedCount, (expectedIndex) {
        final userPoints = _strokes[userIndex]
            .map((point) => StrokePoint(point.dx, point.dy))
            .toList(growable: false);
        final expectedPoints = HanziStrokeService.instance.medianFor(
          data,
          expectedIndex,
          widget.size,
        );
        return HanziStrokeService.instance.evaluate(
          userPoints: userPoints,
          expectedPoints: expectedPoints,
          canvasSize: widget.size,
          tolerance: widget.level == WritingPracticeLevel.review ? 0.38 : 0.40,
        );
      }),
    );

    // Maximum bipartite matching: each user stroke must match one different
    // reference stroke. The DFS reassignment avoids false failures caused by
    // a greedy match choosing the wrong expected stroke first.
    final expectedToUser = List<int>.filled(expectedCount, -1);
    bool assignStroke(int userIndex, Set<int> visitedExpected) {
      final choices = List<int>.generate(expectedCount, (index) => index)
        ..sort((a, b) => evaluations[userIndex][b].score.compareTo(evaluations[userIndex][a].score));
      for (final expectedIndex in choices) {
        if (!evaluations[userIndex][expectedIndex].correct ||
            !visitedExpected.add(expectedIndex)) {
          continue;
        }
        final previousUser = expectedToUser[expectedIndex];
        if (previousUser == -1 || assignStroke(previousUser, visitedExpected)) {
          expectedToUser[expectedIndex] = userIndex;
          return true;
        }
      }
      return false;
    }

    final userOrder = List<int>.generate(expectedCount, (index) => index)
      ..sort((a, b) {
        final aOptions = evaluations[a].where((result) => result.correct).length;
        final bOptions = evaluations[b].where((result) => result.correct).length;
        return aOptions.compareTo(bOptions);
      });

    var matched = 0;
    for (final userIndex in userOrder) {
      if (assignStroke(userIndex, <int>{})) matched++;
    }

    final correct = matched == expectedCount;
    final matchedEvaluations = <StrokeEvaluation>[];
    if (correct) {
      for (var expectedIndex = 0; expectedIndex < expectedCount; expectedIndex++) {
        final userIndex = expectedToUser[expectedIndex];
        matchedEvaluations.add(evaluations[userIndex][expectedIndex]);
      }
    }
    final averageScore = correct
        ? matchedEvaluations.map((result) => result.score).reduce((a, b) => a + b) / expectedCount
        : 0.0;
    final result = StrokeEvaluation(
      correct: correct,
      score: averageScore,
      feedback: correct
          ? 'Chính xác! Các nét đã khớp với chữ mẫu.'
          : 'Hình dạng hoặc hướng của một vài nét chưa khớp. Bạn có thể sửa nét rồi bấm Kiểm tra lại.',
    );

    setState(() {
      _lastEvaluation = result;
      _completed = correct;
    });
    widget.onStrokeEvaluated?.call(result);
    widget.onStrokeCountChanged?.call(_strokes.length);
    if (correct) widget.onComplete?.call();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFC7D8C6), width: 2), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: Size(widget.size, widget.size), painter: _CalligraphyGridPainter()),
            if (_templateOpacity > 0 && !_isDemonstrating)
              IgnorePointer(child: Opacity(opacity: _templateOpacity, child: Text(widget.character, textAlign: TextAlign.center, style: TextStyle(fontSize: widget.size * 0.72, height: 1.15, fontWeight: FontWeight.w400, color: const Color(0xFF28664F), fontFamilyFallback: const ['NomNaTong', 'HanNomB'])))),
            if (_isDemonstrating)
              IgnorePointer(child: CustomPaint(size: Size(widget.size, widget.size), painter: _StrokeDemoPainter(progress: _animController.value, character: widget.character, size: widget.size))),
            if (widget.showStrokeOrderHints && _strokeData != null)
              for (var strokeIndex = 0; strokeIndex < _strokeData!.medians.length; strokeIndex++)
                if (_strokeData!.medians[strokeIndex].isNotEmpty)
                  Positioned(
                    left: (_strokeData!.medians[strokeIndex].first.x / 1024 * widget.size - 11)
                        .clamp(2.0, widget.size - 24),
                    top: (_strokeData!.medians[strokeIndex].first.y / 1024 * widget.size - 11)
                        .clamp(2.0, widget.size - 24),
                    child: IgnorePointer(
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _greenOrderHint,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '${strokeIndex + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
            GestureDetector(
              onPanStart: (details) {
                if (_isDemonstrating) stopStrokeAnimation();
                if (_loadingStrokeData || _strokeDataUnavailable || isComplete) return;
                setState(() { _lastEvaluation = null; _currentStroke = [details.localPosition]; _strokes.add(_currentStroke!); });
                widget.onStrokeCountChanged?.call(_strokes.length);
              },
              onPanUpdate: (details) { if (_currentStroke != null) setState(() => _currentStroke!.add(details.localPosition)); },
              onPanEnd: (_) { _finishCurrentStroke(); },
              child: CustomPaint(size: Size(widget.size, widget.size), painter: _InkPainter(strokes: _strokes)),
            ),
            if (_loadingStrokeData)
              const DecoratedBox(decoration: BoxDecoration(color: Color(0xCCFFFFFF)), child: Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)))),
            if (_strokeDataUnavailable)
              Positioned(left: 18, right: 18, bottom: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFFFF1D7), borderRadius: BorderRadius.circular(12)), child: const Text('Chưa có dữ liệu nét cho chữ này. Hãy thử lại khi có mạng.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFF9A5A20), fontWeight: FontWeight.w700)))),
            if (!_loadingStrokeData && !_strokeDataUnavailable && !isComplete)
              Positioned(top: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFEAF4ED), borderRadius: BorderRadius.circular(12)), child: Text('Đã vẽ $currentStrokeNumber/$totalStrokeCount nét', style: const TextStyle(fontSize: 11, color: Color(0xFF28664F), fontWeight: FontWeight.w900)))),
            if (isComplete)
              Positioned(bottom: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF28664F), borderRadius: BorderRadius.circular(14)), child: const Text('✓ Hoàn thành chữ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)))),
          ],
        ),
      ),
    );
  }
}

class _CalligraphyGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()..color = const Color(0xFFD5DFD4)..strokeWidth = 1.0..style = PaintingStyle.stroke;
    final dashPaint = Paint()..color = const Color(0xFFE8EFE7)..strokeWidth = 1.0..style = PaintingStyle.stroke;
    _drawDashedLine(canvas, Offset.zero, Offset(size.width, size.height), dashPaint);
    _drawDashedLine(canvas, Offset(size.width, 0), Offset(0, size.height), dashPaint);
    final midX = size.width / 2; final midY = size.height / 2;
    _drawDashedLine(canvas, Offset(midX, 0), Offset(midX, size.height), borderPaint);
    _drawDashedLine(canvas, Offset(0, midY), Offset(size.width, midY), borderPaint);
    final p = size.width * 0.16;
    canvas.drawRect(Rect.fromLTRB(p, p, size.width - p, size.height - p), dashPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0, dashSpace = 4.0;
    final dx = p2.dx - p1.dx, dy = p2.dy - p1.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final count = (distance / (dashWidth + dashSpace)).floor();
    final unit = Offset(dx / distance, dy / distance);
    for (var i = 0; i < count; i++) {
      final start = p1 + unit * (i * (dashWidth + dashSpace));
      canvas.drawLine(start, start + unit * dashWidth, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InkPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _InkPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final inkPaint = Paint()..color = const Color(0xFF1E2621)..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke..strokeWidth = 9.0;
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) { canvas.drawCircle(stroke.first, 5.0, Paint()..color = const Color(0xFF1E2621)); continue; }
      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (var i = 1; i < stroke.length - 1; i++) {
        final p0 = stroke[i], p1 = stroke[i + 1];
        path.quadraticBezierTo(p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      }
      path.lineTo(stroke.last.dx, stroke.last.dy);
      canvas.drawPath(path, inkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) => true;
}

class _StrokeDemoPainter extends CustomPainter {
  final double progress; final String character; final double size;
  _StrokeDemoPainter({required this.progress, required this.character, required this.size});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(text: TextSpan(text: character, style: TextStyle(fontSize: this.size * 0.72, height: 1.15, fontWeight: FontWeight.w400, color: const Color(0xFF28664F).withOpacity(0.2), fontFamilyFallback: const ['NomNaTong', 'HanNomB'])), textDirection: TextDirection.ltr)..layout();
    final offset = Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2);
    textPainter.paint(canvas, offset);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height * progress));
    final solid = TextPainter(text: TextSpan(text: character, style: TextStyle(fontSize: this.size * 0.72, height: 1.15, fontWeight: FontWeight.w500, color: const Color(0xFFCC6B3D), fontFamilyFallback: const ['NomNaTong', 'HanNomB'])), textDirection: TextDirection.ltr)..layout();
    solid.paint(canvas, offset);
    canvas.restore();
    final brushPos = Offset(size.width / 2 + sin(progress * pi * 4) * 35, offset.dy + solid.height * progress);
    canvas.drawCircle(brushPos, 14, Paint()..color = const Color(0xFFCC6B3D).withOpacity(0.25));
    canvas.drawCircle(brushPos, 6, Paint()..color = const Color(0xFFCC6B3D));
    canvas.drawCircle(brushPos, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _StrokeDemoPainter oldDelegate) => oldDelegate.progress != progress;
}
