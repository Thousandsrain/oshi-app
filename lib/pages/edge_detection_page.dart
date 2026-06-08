import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:opencv_dart/opencv_dart.dart' as cv;
import '../app_language.dart';

class EdgeDetectionPage extends StatefulWidget {
  final String imagePath;
  const EdgeDetectionPage({super.key, required this.imagePath});

  @override
  State<EdgeDetectionPage> createState() => _EdgeDetectionPageState();
}

class _EdgeDetectionPageState extends State<EdgeDetectionPage> {
  static const double _chekiAspectRatio = 0.628;
  static const double _cornerTouchSize = 104;
  static const double _cornerVisualSize = 24;

  bool _loading = true;
  Size _imageSize = Size.zero;
  Size _displaySize = Size.zero;
  int _imageVersion = 0;

  List<Offset> _points = _defaultChekiPoints();

  int? _draggingIndex;
  bool _draggingWholeFrame = false;

  static List<Offset> _defaultChekiPoints() {
    return const [
      Offset(0.22, 0.06),
      Offset(0.78, 0.06),
      Offset(0.78, 0.94),
      Offset(0.22, 0.94),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadAndDetect();
  }

  Future<void> _loadAndDetect({bool resetPoints = false}) async {
    try {
      if (resetPoints) {
        _points = _defaultChekiPoints();
      }

      final bytes = await File(widget.imagePath).readAsBytes();
      final mat = cv.imdecode(Uint8List.fromList(bytes), cv.IMREAD_COLOR);
      if (mat.cols <= 0 || mat.rows <= 0) {
        final source = img.decodeImage(bytes);
        _imageSize = source == null
            ? const Size(1, 1)
            : Size(source.width.toDouble(), source.height.toDouble());
        return;
      }

      _imageSize = Size(mat.cols.toDouble(), mat.rows.toDouble());

      final detected = await _detectEdges(mat);
      if (detected != null) {
        _points = detected;
      }
    } catch (_) {
      // Keep the manual default frame available if detection cannot start.
      if (_imageSize == Size.zero) {
        _imageSize = const Size(1, 1);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _rotateImageClockwise() async {
    setState(() => _loading = true);

    try {
      final file = File(widget.imagePath);
      final source = img.decodeImage(await file.readAsBytes());
      if (source == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final rotated = img.copyRotate(img.bakeOrientation(source), angle: 90);
      await file.writeAsBytes(img.encodeJpg(rotated, quality: 95));
      await FileImage(file).evict();
      _imageVersion++;
      await _loadAndDetect(resetPoints: true);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<Offset>?> _detectEdges(cv.Mat mat) async {
    try {
      final gray = cv.cvtColor(mat, cv.COLOR_BGR2GRAY);
      final blurred = cv.gaussianBlur(gray, (5, 5), 0);
      final kernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));

      final candidates = <_DetectionCandidate>[];

      final binary = cv.adaptiveThreshold(
        blurred,
        255,
        cv.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv.THRESH_BINARY,
        21,
        8,
      );
      candidates.addAll(await _findRectCandidates(binary, 0.78));

      final binaryInv = cv.adaptiveThreshold(
        blurred,
        255,
        cv.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv.THRESH_BINARY_INV,
        21,
        8,
      );
      candidates.addAll(await _findRectCandidates(binaryInv, 0.82));

      final edgesLow = cv.canny(blurred, 20, 80);
      candidates.addAll(
        await _findRectCandidates(cv.dilate(edgesLow, kernel), 1.0),
      );

      final edgesMid = cv.canny(blurred, 40, 120);
      candidates.addAll(
        await _findRectCandidates(cv.dilate(edgesMid, kernel), 1.0),
      );

      final edgesHigh = cv.canny(blurred, 70, 180);
      candidates.addAll(
        await _findRectCandidates(cv.dilate(edgesHigh, kernel), 1.0),
      );

      final inverted = cv.bitwiseNOT(blurred);
      final invertedEdges = cv.canny(inverted, 30, 110);
      final invertedDilated = cv.dilate(invertedEdges, kernel);
      candidates.addAll(await _findRectCandidates(invertedDilated, 0.9));

      if (candidates.isEmpty) return null;

      final candidate = _pickBestCandidate(candidates);
      if (candidate == null) return null;

      return _expandTowardChekiOuterFrame(candidate.points);
    } catch (_) {
      return null;
    }
  }

  Future<List<_DetectionCandidate>> _findRectCandidates(
    cv.Mat edges,
    double sourceWeight,
  ) async {
    try {
      final (contours, _) = cv.findContours(
        edges,
        cv.RETR_LIST,
        cv.CHAIN_APPROX_SIMPLE,
      );

      final candidates = <_DetectionCandidate>[];
      final imageArea = _imageSize.width * _imageSize.height;

      for (final contour in contours) {
        final contourArea = cv.contourArea(contour);
        if (contourArea < imageArea * 0.035 ||
            contourArea > imageArea * 0.992) {
          continue;
        }

        final peri = cv.arcLength(contour, true);
        if (peri <= 0) continue;

        for (final epsilon in [0.01, 0.015, 0.02, 0.03, 0.045, 0.06]) {
          final approx = cv.approxPolyDP(contour, epsilon * peri, true);
          List<Offset>? points;
          const approxWeight = 1.0;

          if (approx.length == 4) {
            points = approx
                .map(
                  (pt) =>
                      Offset(pt.x / _imageSize.width, pt.y / _imageSize.height),
                )
                .toList();
          }

          if (points == null) continue;

          final sorted = _sortPoints(points);
          final areaRatio = _polygonArea(sorted);
          final aspectScore = _candidateAspectScore(sorted);
          final score = _scoreCandidate(
            sorted,
            sourceWeight * approxWeight,
            areaRatio,
            aspectScore,
          );
          if (score > 0) {
            candidates.add(
              _DetectionCandidate(sorted, score, areaRatio, aspectScore),
            );
          }

          if (approx.length == 4) break;
        }
      }

      return candidates;
    } catch (_) {
      return [];
    }
  }

  _DetectionCandidate? _pickBestCandidate(
    List<_DetectionCandidate> candidates,
  ) {
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.score.compareTo(a.score));

    final chekiCandidates =
        candidates
            .where(
              (candidate) =>
                  candidate.aspectScore >= 0.72 &&
                  candidate.areaRatio >= 0.045 &&
                  candidate.score >= 4.15,
            )
            .toList()
          ..sort((a, b) => b.chekiScore.compareTo(a.chekiScore));

    if (chekiCandidates.isNotEmpty) return chekiCandidates.first;

    final best = candidates.first;
    return best.score >= 5.05 ? best : null;
  }

  double _scoreCandidate(
    List<Offset> pts,
    double sourceWeight,
    double normalizedArea,
    double aspectScore,
  ) {
    if (pts.length != 4) return 0;

    final w = _imageSize.width;
    final h = _imageSize.height;
    final areaRatio = normalizedArea;
    if (areaRatio < 0.035 || areaRatio > 0.992) return 0;

    final top = _distance(pts[0], pts[1], w, h);
    final right = _distance(pts[1], pts[2], w, h);
    final bottom = _distance(pts[3], pts[2], w, h);
    final left = _distance(pts[0], pts[3], w, h);
    final avgWidth = (top + bottom) / 2;
    final avgHeight = (left + right) / 2;
    if (avgWidth <= 0 || avgHeight <= 0) return 0;

    if (aspectScore < 0.38) return 0;
    if (areaRatio > 0.62 && aspectScore < 0.74) return 0;

    final rectangularity = _clamp01(
      (areaRatio * w * h) / (avgWidth * avgHeight),
    );
    final edgeBalance = _clamp01(
      1 -
          (((top - bottom).abs() / max(top, bottom)) +
                  ((left - right).abs() / max(left, right))) /
              2,
    );

    final center = pts.reduce((a, b) => a + b) / 4;
    final centerDistance = sqrt(
      pow(center.dx - 0.5, 2) + pow(center.dy - 0.5, 2),
    );
    final centerScore = _clamp01(1 - centerDistance / 0.72);

    final marginScore =
        pts.every(
          (p) => p.dx > 0.01 && p.dx < 0.99 && p.dy > 0.01 && p.dy < 0.99,
        )
        ? 1.0
        : 0.7;

    final areaScore = areaRatio < 0.18
        ? _clamp01(areaRatio / 0.18)
        : _clamp01(1 - ((areaRatio - 0.42).abs() / 0.75));

    return sourceWeight *
        ((aspectScore * 3.0) +
            (rectangularity * 1.8) +
            (edgeBalance * 1.1) +
            (areaScore * 1.2) +
            (centerScore * 0.6) +
            (marginScore * 0.4));
  }

  double _candidateAspectScore(List<Offset> pts) {
    final w = _imageSize.width;
    final h = _imageSize.height;
    final top = _distance(pts[0], pts[1], w, h);
    final right = _distance(pts[1], pts[2], w, h);
    final bottom = _distance(pts[3], pts[2], w, h);
    final left = _distance(pts[0], pts[3], w, h);
    final avgWidth = (top + bottom) / 2;
    final avgHeight = (left + right) / 2;
    if (avgWidth <= 0 || avgHeight <= 0) return 0;

    final aspectRatio = min(avgWidth / avgHeight, avgHeight / avgWidth);
    return _clamp01(1 - ((aspectRatio - _chekiAspectRatio).abs() / 0.32));
  }

  double _polygonArea(List<Offset> pts) {
    var area = 0.0;
    for (var i = 0; i < pts.length; i++) {
      final j = (i + 1) % pts.length;
      area += pts[i].dx * pts[j].dy - pts[j].dx * pts[i].dy;
    }
    return area.abs() / 2;
  }

  double _clamp01(num value) => value.clamp(0.0, 1.0).toDouble();

  List<Offset> _sortPoints(List<Offset> pts) {
    final copy = [...pts];
    final tl = copy.reduce((a, b) => a.dx + a.dy < b.dx + b.dy ? a : b);
    final br = copy.reduce((a, b) => a.dx + a.dy > b.dx + b.dy ? a : b);
    final tr = copy.reduce((a, b) => a.dx - a.dy > b.dx - b.dy ? a : b);
    final bl = copy.reduce((a, b) => a.dx - a.dy < b.dx - b.dy ? a : b);
    return [tl, tr, br, bl];
  }

  List<Offset> _expandTowardChekiOuterFrame(List<Offset> pts) {
    final areaRatio = _polygonArea(pts);
    final horizontalPad = areaRatio > 0.78 ? 0.0036 : 0.0084;
    final topPad = areaRatio > 0.78 ? 0.003 : 0.0066;
    final bottomPad = areaRatio > 0.78 ? 0.0078 : 0.0195;

    return [
      _sampleQuad(pts, -horizontalPad, -topPad),
      _sampleQuad(pts, 1 + horizontalPad, -topPad),
      _sampleQuad(pts, 1 + horizontalPad, 1 + bottomPad),
      _sampleQuad(pts, -horizontalPad, 1 + bottomPad),
    ].map((p) {
      return Offset(
        p.dx.clamp(0.0, 1.0).toDouble(),
        p.dy.clamp(0.0, 1.0).toDouble(),
      );
    }).toList();
  }

  Offset _sampleQuad(List<Offset> pts, double u, double v) {
    final top = Offset.lerp(pts[0], pts[1], u)!;
    final bottom = Offset.lerp(pts[3], pts[2], u)!;
    return Offset.lerp(top, bottom, v)!;
  }

  Future<void> _crop() async {
    setState(() => _loading = true);
    try {
      final w = _imageSize.width;
      final h = _imageSize.height;

      final bytes = await File(widget.imagePath).readAsBytes();
      final mat = cv.imdecode(Uint8List.fromList(bytes), cv.IMREAD_COLOR);

      final detectedWidth =
          (_distance(_points[0], _points[1], w, h) +
              _distance(_points[3], _points[2], w, h)) /
          2;
      final detectedHeight =
          (_distance(_points[0], _points[3], w, h) +
              _distance(_points[1], _points[2], w, h)) /
          2;

      late final int width;
      late final int height;
      if (detectedWidth <= detectedHeight) {
        width = max(16, detectedWidth.round());
        height = max(16, (width / _chekiAspectRatio).round());
      } else {
        height = max(16, detectedHeight.round());
        width = max(16, (height / _chekiAspectRatio).round());
      }

      final srcPoints = cv.VecPoint.fromList([
        cv.Point((_points[0].dx * w).round(), (_points[0].dy * h).round()),
        cv.Point((_points[1].dx * w).round(), (_points[1].dy * h).round()),
        cv.Point((_points[2].dx * w).round(), (_points[2].dy * h).round()),
        cv.Point((_points[3].dx * w).round(), (_points[3].dy * h).round()),
      ]);

      final dstPoints = cv.VecPoint.fromList([
        cv.Point(0, 0),
        cv.Point(width, 0),
        cv.Point(width, height),
        cv.Point(0, height),
      ]);

      final transform = cv.getPerspectiveTransform(srcPoints, dstPoints);
      final warped = cv.warpPerspective(mat, transform, (width, height));

      final outBytes = cv.imencode('.jpg', warped).$2;
      final outPath = widget.imagePath
          .replaceAll('.jpeg', '_cropped.jpg')
          .replaceAll('.jpg', '_cropped.jpg');
      await File(outPath).writeAsBytes(outBytes);

      if (mounted) Navigator.pop(context, outPath);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _distance(Offset a, Offset b, double w, double h) {
    return sqrt(pow((a.dx - b.dx) * w, 2) + pow((a.dy - b.dy) * h, 2));
  }

  Offset _toDisplay(Offset normalized) {
    return Offset(
      normalized.dx * _displaySize.width,
      normalized.dy * _displaySize.height,
    );
  }

  Offset _toNormalized(Offset display) {
    return Offset(
      (display.dx / _displaySize.width).clamp(0.0, 1.0).toDouble(),
      (display.dy / _displaySize.height).clamp(0.0, 1.0).toDouble(),
    );
  }

  void _moveAllPoints(Offset displayDelta) {
    final dx = displayDelta.dx / _displaySize.width;
    final dy = displayDelta.dy / _displaySize.height;

    final minX = _points.map((p) => p.dx).reduce(min);
    final maxX = _points.map((p) => p.dx).reduce(max);
    final minY = _points.map((p) => p.dy).reduce(min);
    final maxY = _points.map((p) => p.dy).reduce(max);
    final clampedDx = dx.clamp(-minX, 1 - maxX).toDouble();
    final clampedDy = dy.clamp(-minY, 1 - maxY).toDouble();

    _points = _points
        .map((p) => Offset(p.dx + clampedDx, p.dy + clampedDy))
        .toList();
  }

  bool _isInsideFrame(Offset displayPoint) {
    final point = _toNormalized(displayPoint);
    var inside = false;

    for (var i = 0, j = _points.length - 1; i < _points.length; j = i++) {
      final pi = _points[i];
      final pj = _points[j];
      final intersects =
          ((pi.dy > point.dy) != (pj.dy > point.dy)) &&
          point.dx <
              (pj.dx - pi.dx) * (point.dy - pi.dy) / (pj.dy - pi.dy) + pi.dx;
      if (intersects) inside = !inside;
    }

    return inside;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4537E),
        foregroundColor: Colors.white,
        title: Text(t.adjustRange),
        actions: [
          IconButton(
            onPressed: _loading ? null : _rotateImageClockwise,
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
            tooltip: t.rotate90,
          ),
          TextButton(
            onPressed: _loading ? null : _crop,
            child: Text(
              t.confirm,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4537E)),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                const sideGestureInset = 24.0;
                final screenW = max(
                  1.0,
                  constraints.maxWidth - sideGestureInset * 2,
                );
                final screenH = constraints.maxHeight;
                final imgRatio = _imageSize.width / _imageSize.height;
                final screenRatio = screenW / screenH;

                double dispW, dispH, offsetX, offsetY;
                if (imgRatio > screenRatio) {
                  dispW = screenW;
                  dispH = screenW / imgRatio;
                  offsetX = sideGestureInset;
                  offsetY = (screenH - dispH) / 2;
                } else {
                  dispH = screenH;
                  dispW = screenH * imgRatio;
                  offsetX = sideGestureInset + (screenW - dispW) / 2;
                  offsetY = 0;
                }
                _displaySize = Size(dispW, dispH);

                return Stack(
                  children: [
                    Positioned(
                      left: offsetX,
                      top: offsetY,
                      width: dispW,
                      height: dispH,
                      child: Image.file(
                        File(widget.imagePath),
                        key: ValueKey(_imageVersion),
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      left: offsetX,
                      top: offsetY,
                      width: dispW,
                      height: dispH,
                      child: CustomPaint(
                        painter: _OverlayPainter(
                          points: _points.map((p) => _toDisplay(p)).toList(),
                        ),
                      ),
                    ),
                    Positioned(
                      left: offsetX,
                      top: offsetY,
                      width: dispW,
                      height: dispH,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanStart: (details) {
                          final local = details.localPosition;
                          if (_isInsideFrame(local)) {
                            setState(() => _draggingWholeFrame = true);
                          }
                        },
                        onPanUpdate: (details) {
                          if (!_draggingWholeFrame) return;
                          setState(() => _moveAllPoints(details.delta));
                        },
                        onPanEnd: (_) =>
                            setState(() => _draggingWholeFrame = false),
                        onPanCancel: () =>
                            setState(() => _draggingWholeFrame = false),
                      ),
                    ),
                    ..._points.asMap().entries.map((entry) {
                      final i = entry.key;
                      final dp = _toDisplay(entry.value);
                      return Positioned(
                        left: offsetX + dp.dx - _cornerTouchSize / 2,
                        top: offsetY + dp.dy - _cornerTouchSize / 2,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onPanStart: (_) => setState(() => _draggingIndex = i),
                          onPanUpdate: (details) {
                            setState(() {
                              final currentDisplay = _toDisplay(_points[i]);
                              final newDisplay = Offset(
                                currentDisplay.dx + details.delta.dx,
                                currentDisplay.dy + details.delta.dy,
                              );
                              _points[i] = _toNormalized(newDisplay);
                            });
                          },
                          onPanEnd: (_) =>
                              setState(() => _draggingIndex = null),
                          child: SizedBox(
                            width: _cornerTouchSize,
                            height: _cornerTouchSize,
                            child: Center(
                              child: Container(
                                width: _cornerVisualSize,
                                height: _cornerVisualSize,
                                decoration: BoxDecoration(
                                  color: _draggingIndex == i
                                      ? const Color(0xFFD4537E)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFD4537E),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: _draggingIndex == i
                                          ? Colors.white
                                          : const Color(0xFFD4537E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Text(
                        t.edgeHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _DetectionCandidate {
  final List<Offset> points;
  final double score;
  final double areaRatio;
  final double aspectScore;

  double get chekiScore {
    final usableArea = areaRatio < 0.08
        ? areaRatio / 0.08
        : 1 - ((areaRatio - 0.28).abs() / 0.95);
    return score * 0.65 +
        aspectScore * 4.2 +
        usableArea.clamp(0.0, 1.0).toDouble() * 0.7;
  }

  const _DetectionCandidate(
    this.points,
    this.score,
    this.areaRatio,
    this.aspectScore,
  );
}

class _OverlayPainter extends CustomPainter {
  final List<Offset> points;
  _OverlayPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length != 4) return;

    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addPath(path, Offset.zero)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD4537E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.points != points;
}
