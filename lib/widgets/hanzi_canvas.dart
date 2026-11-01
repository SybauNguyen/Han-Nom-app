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

class HanziCanvasState extends State<HanziCanvas> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;

  int get strokeCount => _strokes.length;

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
            if (widget.templateOpacity > 0)
              IgnorePointer(
                child: Opacity(
                  opacity: widget.templateOpacity,
                  child: Text(
                    widget.character,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: widget.size * 0.74,
                      height: 1.15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF1E3A2F),
                      fontFamilyFallback: const ['NomNaTong', 'HanNomB'],
                    ),
                  ),
                ),
              ),

            // Vùng cảm ứng vẽ nét
            GestureDetector(
              onPanStart: (details) {
                final RenderBox box = context.findRenderBox();
                final localPos = box.globalToLocal(details.globalPosition);
                setState(() {
                  _currentStroke = [localPos];
                  _strokes.add(_currentStroke!);
                });
                widget.onStrokeCountChanged?.call(_strokes.length);
              },
              onPanUpdate: (details) {
                final RenderBox box = context.findRenderBox();
                final localPos = box.globalToLocal(details.globalPosition);
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
          ],
        ),
      ),
    );
  }
}

/// Vẽ lưới ô Mễ (米字格) truyền thống để định vị tỉ lệ chữ Hán
class _CalligraphyGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFD6E2D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dashPaint = Paint()
      ..color = const Color(0xFFE2EBE0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final w = size.width;
    final h = size.height;

    // Đường chéo chính
    _drawDashedLine(canvas, Offset.zero, Offset(w, h), dashPaint);
    _drawDashedLine(canvas, Offset(0, h), Offset(w, 0), dashPaint);

    // Đường phân đôi ngang & dọc
    _drawDashedLine(canvas, Offset(w / 2, 0), Offset(w / 2, h), dashPaint);
    _drawDashedLine(canvas, Offset(0, h / 2), Offset(w, h / 2), dashPaint);

    // Khung viền trong
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), borderPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final distance = (p2 - p1).distance;
    final normalized = (p2 - p1) / distance;

    double currentDistance = 0.0;
    while (currentDistance < distance) {
      final start = p1 + normalized * currentDistance;
      final endDistance = (currentDistance + dashWidth).clamp(0.0, distance);
      final end = p1 + normalized * endDistance;
      canvas.drawLine(start, end, paint);
      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Vẽ các nét mực thư pháp do người dùng thao tác
class _InkPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _InkPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final inkPaint = Paint()
      ..color = const Color(0xFF1C2D24)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 8.5
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 4.25, Paint()..color = const Color(0xFF1C2D24));
        continue;
      }

      final path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);

      for (int i = 1; i < stroke.length; i++) {
        final p0 = stroke[i - 1];
        final p1 = stroke[i];
        final midPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        path.quadraticBezierTo(p0.dx, p0.dy, midPoint.dx, midPoint.dy);
      }
      path.lineTo(stroke.last.dx, stroke.last.dy);

      canvas.drawPath(path, inkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) => true;
}
