import 'dart:math';
import 'package:flutter/material.dart';

class HanziCanvas extends StatefulWidget {
  final String character;
  final double size;
  final double templateOpacity;
  final Function(int strokeCount)? onStrokeCountChanged;

  const HanziCanvas({
    super.key,
    required this.character,
    this.size = 280,
    this.templateOpacity = 0.25,
    this.onStrokeCountChanged,
  });

  @override
  State<HanziCanvas> createState() => HanziCanvasState();
}

class HanziCanvasState extends State<HanziCanvas> with SingleTickerProviderStateMixin {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;

  late final AnimationController _animController;
  bool _isDemonstrating = false;

  bool get isDemonstrating => _isDemonstrating;
  int get strokeCount => _strokes.length;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addListener(() {
        if (mounted) setState(() {});
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isDemonstrating = false;
          });
        }
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void playStrokeAnimation() {
    setState(() {
      _isDemonstrating = true;
    });
    _animController.forward(from: 0.0);
  }

  void stopStrokeAnimation() {
    _animController.stop();
    setState(() {
      _isDemonstrating = false;
    });
  }

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
    widget.onStrokeCountChanged?.call(0);
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
      widget.onStrokeCountChanged?.call(_strokes.length);
    }
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
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Lưới luyện chữ (Ô Mễ 米字格)
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _CalligraphyGridPainter(),
            ),

            // Chữ mẫu mờ làm điểm tựa để đồ nét
            if (widget.templateOpacity > 0 && !_isDemonstrating)
              IgnorePointer(
                child: Opacity(
                  opacity: widget.templateOpacity,
                  child: Text(
                    widget.character,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: widget.size * 0.72,
                      height: 1.15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF28664F),
                      fontFamilyFallback: const ['NomNaTong', 'HanNomB'],
                    ),
                  ),
                ),
              ),

            // Hoạt họa mô phỏng thứ tự nét bút khi nhấn "Xem cách viết"
            if (_isDemonstrating)
              IgnorePointer(
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _StrokeDemoPainter(
                    progress: _animController.value,
                    character: widget.character,
                    size: widget.size,
                  ),
                ),
              ),

            // Vùng cảm ứng vẽ nét tay của người học
            GestureDetector(
              onPanStart: (details) {
                if (_isDemonstrating) stopStrokeAnimation();
                final localPos = details.localPosition;
                setState(() {
                  _currentStroke = [localPos];
                  _strokes.add(_currentStroke!);
                });
                widget.onStrokeCountChanged?.call(_strokes.length);
              },
              onPanUpdate: (details) {
                final localPos = details.localPosition;
                setState(() {
                  _currentStroke?.add(localPos);
                });
              },
              onPanEnd: (_) {
                _currentStroke = null;
              },
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _InkPainter(strokes: _strokes),
              ),
            ),

            // Huy hiệu trạng thái khi đang diễn họa nét bút
            if (_isDemonstrating)
              Positioned(
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCC6B3D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.brush_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Đang mô phỏng bút thuận (${(_animController.value * 100).toInt()}%)',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Painter vẽ ô Mễ (米字格) cổ truyền
class _CalligraphyGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFD5DFD4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = const Color(0xFFE8EFE7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Đường chéo chính
    _drawDashedLine(canvas, Offset.zero, Offset(size.width, size.height), dashPaint);
    _drawDashedLine(canvas, Offset(size.width, 0), Offset(0, size.height), dashPaint);

    // Đường chữ thập (giữa)
    final midX = size.width / 2;
    final midY = size.height / 2;
    _drawDashedLine(canvas, Offset(midX, 0), Offset(midX, size.height), borderPaint);
    _drawDashedLine(canvas, Offset(0, midY), Offset(size.width, midY), borderPaint);

    // Khung viền ô vuông bên trong (Ô Cửu cung / Nội ô)
    final innerPadding = size.width * 0.16;
    final innerRect = Rect.fromLTRB(
      innerPadding,
      innerPadding,
      size.width - innerPadding,
      size.height - innerPadding,
    );
    canvas.drawRect(innerRect, dashPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final count = (distance / (dashWidth + dashSpace)).floor();
    final unitVector = Offset(dx / distance, dy / distance);

    for (var i = 0; i < count; i++) {
      final start = p1 + unitVector * (i * (dashWidth + dashSpace));
      final end = start + unitVector * dashWidth;
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter vẽ nét cọ mực thư pháp theo thao tác vẽ tay
class _InkPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _InkPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final inkPaint = Paint()
      ..color = const Color(0xFF1E2621) // Màu mực tàu đậm
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        // Nét chấm đơn
        canvas.drawCircle(stroke.first, 5.0, Paint()..color = const Color(0xFF1E2621));
        continue;
      }

      final path = Path();
      path.moveTo(stroke[0].dx, stroke[0].dy);

      for (var i = 1; i < stroke.length - 1; i++) {
        final p0 = stroke[i];
        final p1 = stroke[i + 1];
        // Làm mượt nét vẽ bằng đường cong Bezier
        path.quadraticBezierTo(p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      }
      path.lineTo(stroke.last.dx, stroke.last.dy);

      canvas.drawPath(path, inkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) => true;
}

/// Painter biểu diễn hoạt họa thứ tự nét bút
class _StrokeDemoPainter extends CustomPainter {
  final double progress;
  final String character;
  final double size;

  _StrokeDemoPainter({
    required this.progress,
    required this.character,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Vẽ nền chữ mờ màu xanh nhạt
    final textPainter = TextPainter(
      text: TextSpan(
        text: character,
        style: TextStyle(
          fontSize: this.size * 0.72,
          height: 1.15,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF28664F).withOpacity(0.2),
          fontFamilyFallback: const ['NomNaTong', 'HanNomB'],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, textOffset);

    // 2. Dùng ClipRect reveal dần dần chữ từ trên xuống dưới theo tiến trình
    canvas.save();
    final revealHeight = size.height * progress;
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, revealHeight));

    final solidPainter = TextPainter(
      text: TextSpan(
        text: character,
        style: TextStyle(
          fontSize: this.size * 0.72,
          height: 1.15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFCC6B3D), // Màu chu sa nổi bật
          fontFamilyFallback: const ['NomNaTong', 'HanNomB'],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    solidPainter.paint(canvas, textOffset);
    canvas.restore();

    // 3. Vẽ đầu ngọn bút lông di chuyển sinh động
    final brushY = textOffset.dy + (solidPainter.height * progress);
    final brushX = size.width / 2 + sin(progress * pi * 4) * 35;
    final brushPos = Offset(brushX, brushY);

    // Quầng sáng quanh ngọn bút
    canvas.drawCircle(brushPos, 14, Paint()..color = const Color(0xFFCC6B3D).withOpacity(0.25));
    // Ngọn bút
    canvas.drawCircle(brushPos, 6, Paint()..color = const Color(0xFFCC6B3D));
    canvas.drawCircle(brushPos, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _StrokeDemoPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
