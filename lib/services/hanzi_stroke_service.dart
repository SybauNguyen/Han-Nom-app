import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

class StrokePoint {
  final double x;
  final double y;

  const StrokePoint(this.x, this.y);
}

class HanziStrokeData {
  final String character;
  final List<List<StrokePoint>> medians;

  const HanziStrokeData({
    required this.character,
    required this.medians,
  });

  int get strokeCount => medians.length;
}

class StrokeEvaluation {
  final bool correct;
  final double score;
  final String feedback;

  const StrokeEvaluation({
    required this.correct,
    required this.score,
    required this.feedback,
  });
}

class HanziStrokeService {
  HanziStrokeService._();
  static final HanziStrokeService instance = HanziStrokeService._();

  static const _baseUrl = 'https://cdn.jsdelivr.net/npm/hanzi-writer-data@2.0.1';
  final Map<String, HanziStrokeData?> _cache = <String, HanziStrokeData?>{};

  Future<HanziStrokeData?> load(String character) async {
    if (_cache.containsKey(character)) return _cache[character];

    try {
      final uri = Uri.parse('$_baseUrl/${Uri.encodeComponent(character)}.json');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        _cache[character] = null;
        return null;
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rawMedians = decoded['medians'];
      if (rawMedians is! List) {
        _cache[character] = null;
        return null;
      }

      final medians = <List<StrokePoint>>[];
      for (final rawStroke in rawMedians) {
        if (rawStroke is! List) continue;
        final points = <StrokePoint>[];
        for (final rawPoint in rawStroke) {
          if (rawPoint is! List || rawPoint.length < 2) continue;
          points.add(StrokePoint(
            (rawPoint[0] as num).toDouble(),
            (rawPoint[1] as num).toDouble(),
          ));
        }
        if (points.length >= 2) medians.add(points);
      }

      final data = medians.isEmpty ? null : HanziStrokeData(character: character, medians: medians);
      _cache[character] = data;
      return data;
    } catch (_) {
      _cache[character] = null;
      return null;
    }
  }

  StrokeEvaluation evaluate({
    required List<StrokePoint> userPoints,
    required List<StrokePoint> expectedPoints,
    double tolerance = 0.28,
  }) {
    if (userPoints.length < 2 || expectedPoints.length < 2) {
      return const StrokeEvaluation(correct: false, score: 0, feedback: 'Hãy viết đủ một nét rồi thả tay.');
    }

    final user = _normalize(userPoints);
    final expected = _normalize(expectedPoints);
    final startDistance = _distance(user.first, expected.first);
    final endDistance = _distance(user.last, expected.last);
    final directionError = _directionError(user, expected);
    final shapeError = _averageDistanceToPolyline(user, expected);
    final lengthRatio = _pathLength(user) / math.max(_pathLength(expected), 0.0001);
    final lengthError = math.log(lengthRatio).abs();

    final score = (1 - (
      startDistance * 0.24 +
      endDistance * 0.20 +
      directionError * 0.18 +
      shapeError * 0.30 +
      math.min(lengthError, 1.0) * 0.08
    )).clamp(0.0, 1.0);

    final correct =
        startDistance <= tolerance &&
        endDistance <= tolerance * 1.25 &&
        directionError <= 0.42 &&
        shapeError <= tolerance * 0.95 &&
        lengthRatio >= 0.45 &&
        lengthRatio <= 1.8;

    final feedback = correct
        ? 'Chính xác! Sang nét tiếp theo.'
        : startDistance > tolerance
            ? 'Hãy bắt đầu gần đúng điểm đầu của nét.'
            : directionError > 0.42
                ? 'Hướng đi của nét chưa đúng. Thử lại nhé.'
                : shapeError > tolerance * 0.95
                    ? 'Đường nét hơi lệch. Hãy bám theo nét mẫu hơn.'
                    : lengthRatio < 0.45 || lengthRatio > 1.8
                        ? 'Độ dài nét chưa phù hợp. Hãy thử lại.'
                        : 'Nét này chưa đạt. Thử lại nhé.';

    return StrokeEvaluation(correct: correct, score: score, feedback: feedback);
  }

  List<StrokePoint> medianFor(HanziStrokeData data, int index, double canvasSize) {
    return data.medians[index]
        .map((point) => StrokePoint(point.x / 1024 * canvasSize, point.y / 1024 * canvasSize))
        .toList(growable: false);
  }

  List<StrokePoint> _normalize(List<StrokePoint> points) {
    final minX = points.map((p) => p.x).reduce(math.min);
    final maxX = points.map((p) => p.x).reduce(math.max);
    final minY = points.map((p) => p.y).reduce(math.min);
    final maxY = points.map((p) => p.y).reduce(math.max);
    final scale = math.max(maxX - minX, maxY - minY).clamp(1.0, double.infinity);
    return points
        .map((p) => StrokePoint((p.x - minX) / scale, (p.y - minY) / scale))
        .toList(growable: false);
  }

  double _directionError(List<StrokePoint> a, List<StrokePoint> b) {
    final aDx = a.last.x - a.first.x;
    final aDy = a.last.y - a.first.y;
    final bDx = b.last.x - b.first.x;
    final bDy = b.last.y - b.first.y;
    final aLen = math.sqrt(aDx * aDx + aDy * aDy);
    final bLen = math.sqrt(bDx * bDx + bDy * bDy);
    if (aLen < 0.001 || bLen < 0.001) return 1;
    final cosine = ((aDx * bDx + aDy * bDy) / (aLen * bLen)).clamp(-1.0, 1.0);
    return (1 - cosine) / 2;
  }

  double _averageDistanceToPolyline(List<StrokePoint> points, List<StrokePoint> polyline) {
    if (points.isEmpty || polyline.length < 2) return 1;
    var total = 0.0;
    for (final point in points) {
      var best = double.infinity;
      for (var i = 0; i < polyline.length - 1; i++) {
        best = math.min(best, _distanceToSegment(point, polyline[i], polyline[i + 1]));
      }
      total += best;
    }
    return total / points.length;
  }

  double _distanceToSegment(StrokePoint p, StrokePoint a, StrokePoint b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared == 0) return _distance(p, a);
    final t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared;
    final clamped = t.clamp(0.0, 1.0);
    return _distance(p, StrokePoint(a.x + clamped * dx, a.y + clamped * dy));
  }

  double _pathLength(List<StrokePoint> points) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) total += _distance(points[i - 1], points[i]);
    return total;
  }

  double _distance(StrokePoint a, StrokePoint b) => math.sqrt(
        math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2),
      );
}
