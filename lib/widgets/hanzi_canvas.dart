import 'dart:math';
import 'package:flutter/material.dart';

import '../services/hanzi_stroke_service.dart';

enum WritingPracticeLevel { guided, faint, recall, review }

class HanziCanvas extends StatefulWidget {
  final String character;
  final double size;
  final WritingPracticeLevel level;
  final Function(int strokeCount)? onStrokeCountChanged;
  final ValueChanged<StrokeEvaluation>? onStrokeEvaluated;
  final VoidCallback? onComplete;

  const HanziCanvas({
    super.key,
    required this.character,
    this.size = 280,
    this.level = WritingPracticeLevel.guided,
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
  int _currentStrokeIndex = 0;
  bool _loadingStrokeData = true;
  bool _strokeDataUnavailable = false;
  StrokeEvaluation? _lastEvaluation;

  late final AnimationController _animController;
  bool _isDemonstrating = false;

  bool get isDemonstrating => _isDemonstrating;
  int get strokeCount => _strokes.length;
  int get totalStrokeCount => _strokeData?.strokeCount ?? 0;
  int get currentStrokeNumber => _currentStrokeIndex + 1;
  bool get isComplete => _strokeData != null && _currentStrokeIndex >= _strokeData!.strokeCount;
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
    _currentStrokeIndex = 0;
    _lastEvaluation = null;
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  void playStrokeAnimation() { setState(() => _isDemonstrating = true); _animController.forward(from: 0.0); }
  void stopStrokeAnimation() { _animController.stop(); if (mounted) setState(() => _isDemonstrating = false); }

  void clear() {
    setState(() { _strokes.clear(); _currentStroke = null; _currentStrokeIndex = 0; _lastEvaluation = null; });
    widget.onStrokeCountChanged?.call(0);
  }

  void undo() {
    if (_strokes.isEmpty) return;
    setState(() { _strokes.removeLast(); _currentStrokeIndex = max(0, _currentStrokeIndex - 1); _lastEvaluation = null; });
    widget.onStrokeCountChanged?.call(_strokes.length);
  }

  Future<void> _finishCurrentStroke() async {
    final points = _currentStroke;
    _currentStroke = null;
    if (points == null || points.length < 2 || _strokeData == null || isComplete) return;

    final expected = HanziStrokeService.instance.medianFor(_strokeData!, _currentStrokeIndex, widget.size);
    final userPoints = points.map((p) => StrokePoint(p.dx, p.dy)).toList(growable: false);
    final result = HanziStrokeService.instance.evaluate(
      userPoints: userPoints,
      expectedPoints: expected,
      tolerance: widget.level == WritingPracticeLevel.review ? 0.24 : 0.28,
    );

    if (!mounted) return;
    setState(() {
      _lastEvaluation = result;
      if (!result.correct && _strokes.isNotEmpty) _strokes.removeLast();
      if (result.correct) _currentStrokeIndex++;
    });
    widget.onStrokeEvaluated?.call(result);
    widget.onStrokeCountChanged?.call(_strokes.length);
    if (result.correct && isComplete) widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC7D8C6), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: Size(widget.size, widget.size), painter: _CalligraphyGridPainter()),
            if (_templateOpacity > 0 && !_isDemonstrating)
              IgnorePointer(child: Opacity(
                opacity: _templateOpacity,
                child: Text(widget.character, textAlign: TextAlign.center, style: TextStyle(
                  fontSize: widget.size * 0.72, height: 1.15, fontWeight: FontWeight.w400,
                  color: const Color(0xFF28664F), fontFamilyFallback: const ['NomNaTong', 'HanNomB'],
                )),
              )),
            if (_isDemonstrating)
              IgnorePointer(child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _StrokeDemoPainter(progress: _animController.value, character: widget.character, size: widget.size),
              )),
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
              const DecoratedBox(
                decoration: BoxDecoration(color: Color(0xCCFFFFFF)),
                child: Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
              ),
            if (_strokeDataUnavailable)
              Positioned(left: 18, right: 18, bottom: 14, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFFFF1D7), borderRadius: BorderRadius.circular(12)),
                child: const Text('Chưa có dữ liệu nét cho chữ này. Hãy thử lại khi có mạng.', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF9A5A20), fontWeight: FontWeight.w700)),
              )),
            if (!_loadingStrokeData && !_strokeDataUnavailable && !isComplete)
              Positioned(top: 10, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFEAF4ED), borderRadius: BorderRadius.circular(12)),
                child: Text('Nét $currentStrokeNumber/$totalStrokeCount', style: const TextStyle(fontSize: 11, color: Color(0xFF28664F), fontWeight: FontWeight.w900)),
              )),
            if (isComplete)
              Positioned(bottom: 12, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF28664F), borderRadius: BorderRadius.circular(14)),
                child: const Text('✓ Hoàn thành chữ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
              )),
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
    final textPainter = TextPainter(
      text: TextSpan(text: character, style: TextStyle(fontSize: this.size * 0.72, height: 1.15, fontWeight: FontWeight.w400, color: const Color(0xFF28664F).withOpacity(0.2), fontFamilyFallback: const ['NomNaTong', 'HanNomB'])),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2);
    textPainter.paint(canvas, offset);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height * progress));
    final solid = TextPainter(
      text: TextSpan(text: character, style: TextStyle(fontSize: this.size * 0.72, height: 1.15, fontWeight: FontWeight.w500, color: const Color(0xFFCC6B3D), fontFamilyFallback: const ['NomNaTong', 'HanNomB'])),
      textDirection: TextDirection.ltr,
    )..layout();
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
