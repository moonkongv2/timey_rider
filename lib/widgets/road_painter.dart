import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RoadCourseGeometry {
  const RoadCourseGeometry({
    required this.viewportSize,
    required this.canvasSize,
    required this.roadBounds,
    required this.rowCount,
  });

  final Size viewportSize;
  final Size canvasSize;
  final Rect roadBounds;
  final int rowCount;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RoadCourseGeometry &&
            other.viewportSize == viewportSize &&
            other.canvasSize == canvasSize &&
            other.roadBounds == roadBounds &&
            other.rowCount == rowCount;
  }

  @override
  int get hashCode {
    return Object.hash(viewportSize, canvasSize, roadBounds, rowCount);
  }
}

Rect createRoadBounds(Size size) {
  final isLandscape = size.width > size.height;
  final horizontalPadding =
      (isLandscape ? size.width * 0.10 : size.width * 0.13)
          .clamp(isLandscape ? 84.0 : 46.0, isLandscape ? 118.0 : 62.0)
          .toDouble();
  final topPadding = isLandscape ? size.height * 0.31 : size.height * 0.14;
  final bottomPadding = isLandscape ? size.height * 0.11 : size.height * 0.085;

  return Rect.fromLTWH(
    horizontalPadding,
    topPadding,
    size.width - (horizontalPadding * 2),
    size.height - topPadding - bottomPadding,
  );
}

Path createRoadPath(Size size) {
  final bounds = createRoadBounds(size);
  final left = bounds.left;
  final right = bounds.right;
  final top = bounds.top;
  final bottom = bounds.bottom;
  final height = bounds.height;
  final isLandscape = size.width > size.height;
  final rowCount = isLandscape ? 5 : 9;
  final rowHeight = height / rowCount;
  final path = Path()..moveTo(left, bottom);

  for (var row = 0; row < rowCount; row += 1) {
    final currentY = bottom - (rowHeight * row);
    final nextY = bottom - (rowHeight * (row + 1));
    if (row.isEven) {
      path
        ..lineTo(right, currentY)
        ..lineTo(right, nextY);
    } else {
      path
        ..lineTo(left, currentY)
        ..lineTo(left, nextY);
    }
  }

  return path..lineTo(rowCount.isEven ? right : left, top);
}

RoadCourseGeometry createRoadCourseGeometry({
  required Size viewportSize,
  required Duration duration,
  Duration referenceDuration = const Duration(minutes: 5),
}) {
  final baselineBounds = createRoadBounds(viewportSize);
  final baselineRowCount = _baselineRoadRowCount(viewportSize);
  final baselineRowHeight = baselineBounds.height / baselineRowCount;
  final factor = _roadDurationFactor(duration, referenceDuration);
  final rowCount = _scaledRoadRowCount(
    baselineBounds: baselineBounds,
    baselineRowCount: baselineRowCount,
    baselineRowHeight: baselineRowHeight,
    factor: factor,
  );
  final roadHeight = baselineRowHeight * rowCount;
  final bottomPadding = viewportSize.height - baselineBounds.bottom;
  final canvasHeight = baselineBounds.top + roadHeight + bottomPadding;

  return RoadCourseGeometry(
    viewportSize: viewportSize,
    canvasSize: Size(viewportSize.width, canvasHeight),
    roadBounds: Rect.fromLTWH(
      baselineBounds.left,
      baselineBounds.top,
      baselineBounds.width,
      roadHeight,
    ),
    rowCount: rowCount,
  );
}

Path createRoadPathForGeometry(RoadCourseGeometry geometry) {
  final bounds = geometry.roadBounds;
  final left = bounds.left;
  final right = bounds.right;
  final top = bounds.top;
  final bottom = bounds.bottom;
  final rowHeight = bounds.height / geometry.rowCount;
  final path = Path()..moveTo(left, bottom);

  for (var row = 0; row < geometry.rowCount; row += 1) {
    final currentY = bottom - (rowHeight * row);
    final nextY = bottom - (rowHeight * (row + 1));
    if (row.isEven) {
      path
        ..lineTo(right, currentY)
        ..lineTo(right, nextY);
    } else {
      path
        ..lineTo(left, currentY)
        ..lineTo(left, nextY);
    }
  }

  return path..lineTo(geometry.rowCount.isEven ? right : left, top);
}

PathMetric roadMetricForGeometry(RoadCourseGeometry geometry) {
  return createRoadPathForGeometry(geometry).computeMetrics().first;
}

Tangent roadTangentForGeometryProgress(
  RoadCourseGeometry geometry,
  double progress,
) {
  final metric = roadMetricForGeometry(geometry);
  final distance = metric.length * progress.clamp(0.0, 1.0).toDouble();
  return metric.getTangentForOffset(distance)!;
}

Offset roadPointForGeometryProgress(
  RoadCourseGeometry geometry,
  double progress,
) {
  return roadTangentForGeometryProgress(geometry, progress).position;
}

bool roadIsFacingLeftForGeometryProgress(
  RoadCourseGeometry geometry,
  double progress,
) {
  final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
  final tangent = roadTangentForGeometryProgress(geometry, clampedProgress);
  if (tangent.vector.dx.abs() > 0.01) {
    return tangent.vector.dx < 0;
  }

  final probeProgress = (clampedProgress + 0.015).clamp(0.0, 1.0).toDouble();
  final probeTangent = roadTangentForGeometryProgress(geometry, probeProgress);
  if (probeTangent.vector.dx.abs() > 0.01) {
    return probeTangent.vector.dx < 0;
  }

  final previousProgress = (clampedProgress - 0.015).clamp(0.0, 1.0).toDouble();
  final previousTangent = roadTangentForGeometryProgress(
    geometry,
    previousProgress,
  );
  return previousTangent.vector.dx < 0;
}

double roadCameraOffsetForGeometryProgress({
  required RoadCourseGeometry geometry,
  required double progress,
}) {
  const viewportAnchorY = 0.65;
  final maxOffset = geometry.canvasSize.height - geometry.viewportSize.height;
  if (maxOffset <= 0) {
    return 0;
  }

  final roadPoint = roadPointForGeometryProgress(geometry, progress);
  final targetOffset =
      roadPoint.dy - (geometry.viewportSize.height * viewportAnchorY);
  return targetOffset.clamp(0.0, maxOffset).toDouble();
}

PathMetric _roadMetric(Size size) {
  return createRoadPath(size).computeMetrics().first;
}

Tangent roadTangentForProgress(Size size, double progress) {
  final metric = _roadMetric(size);
  final distance = metric.length * progress.clamp(0.0, 1.0).toDouble();
  return metric.getTangentForOffset(distance)!;
}

Offset roadPointForProgress(Size size, double progress) {
  return roadTangentForProgress(size, progress).position;
}

double roadStrokeWidthForSize(Size size) {
  final isLandscape = size.width > size.height;
  return (isLandscape ? size.height * 0.085 : size.shortestSide * 0.058)
      .clamp(isLandscape ? 30.0 : 22.0, isLandscape ? 44.0 : 32.0)
      .toDouble();
}

bool roadIsFacingLeftForProgress(Size size, double progress) {
  final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
  final tangent = roadTangentForProgress(size, clampedProgress);
  if (tangent.vector.dx.abs() > 0.01) {
    return tangent.vector.dx < 0;
  }

  final probeProgress = (clampedProgress + 0.015).clamp(0.0, 1.0).toDouble();
  final probeTangent = roadTangentForProgress(size, probeProgress);
  if (probeTangent.vector.dx.abs() > 0.01) {
    return probeTangent.vector.dx < 0;
  }

  final previousProgress = (clampedProgress - 0.015).clamp(0.0, 1.0).toDouble();
  final previousTangent = roadTangentForProgress(size, previousProgress);
  return previousTangent.vector.dx < 0;
}

int _baselineRoadRowCount(Size size) {
  return size.width > size.height ? 5 : 9;
}

double _roadDurationFactor(Duration duration, Duration referenceDuration) {
  if (referenceDuration <= Duration.zero || duration <= Duration.zero) {
    return 1;
  }

  final factor = duration.inMilliseconds / referenceDuration.inMilliseconds;
  return factor < 1 ? 1 : factor;
}

int _scaledRoadRowCount({
  required Rect baselineBounds,
  required int baselineRowCount,
  required double baselineRowHeight,
  required double factor,
}) {
  if (factor <= 1) {
    return baselineRowCount;
  }

  final targetLength =
      _roadPathLengthForRows(
        width: baselineBounds.width,
        rowHeight: baselineRowHeight,
        rowCount: baselineRowCount,
      ) *
      factor;
  final estimatedRowCount =
      ((targetLength - baselineBounds.width) /
              (baselineBounds.width + baselineRowHeight))
          .ceil();
  var maxCandidate = estimatedRowCount + baselineRowCount + 8;
  if (maxCandidate < baselineRowCount) {
    maxCandidate = baselineRowCount;
  }

  var bestRowCount = baselineRowCount;
  var bestDelta = double.infinity;
  for (
    var candidate = baselineRowCount;
    candidate <= maxCandidate;
    candidate += 1
  ) {
    if (candidate.isEven != baselineRowCount.isEven) {
      continue;
    }

    final length = _roadPathLengthForRows(
      width: baselineBounds.width,
      rowHeight: baselineRowHeight,
      rowCount: candidate,
    );
    final delta = (length - targetLength).abs();
    if (delta < bestDelta) {
      bestDelta = delta;
      bestRowCount = candidate;
    }
  }

  return bestRowCount;
}

double _roadPathLengthForRows({
  required double width,
  required double rowHeight,
  required int rowCount,
}) {
  return (width * (rowCount + 1)) + (rowHeight * rowCount);
}

class RoadPainter extends CustomPainter {
  const RoadPainter({
    required this.progress,
    this.laneDashPhase = 0,
    this.geometry,
  });

  static const laneDashWidth = 15.0;
  static const laneDashGap = 22.0;
  static const laneDashPatternLength = laneDashWidth + laneDashGap;
  static const laneDashInset = 18.0;
  static const laneDashStrokeWidth = 3.4;
  static const laneDashOpacity = 0.72;
  static const laneDashAnimationDuration = Duration(milliseconds: 1200);

  final double progress;
  final double laneDashPhase;
  final RoadCourseGeometry? geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final roadPath = geometry == null
        ? createRoadPath(size)
        : createRoadPathForGeometry(geometry!);
    final roadWidth = roadStrokeWidthForSize(geometry?.viewportSize ?? size);
    final roadMetric = roadPath.computeMetrics().first;
    final progressDistance =
        roadMetric.length * progress.clamp(0.0, 1.0).toDouble();
    final progressPath = roadMetric.extractPath(0, progressDistance);

    final softShadowPaint = Paint()
      ..color = AppColors.brown700.withValues(alpha: 0.075)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = roadWidth + 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final rimPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = roadWidth + 5;
    final roadPaint = Paint()
      ..color = const Color(0xFFBCEFD0)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = roadWidth;
    final progressPaint = Paint()
      ..color = const Color(0xFFFFC38B).withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = roadWidth;
    final progressGlowPaint = Paint()
      ..color = AppColors.orange.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = roadWidth + 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(roadPath.shift(const Offset(0, 10)), softShadowPaint);
    canvas.drawPath(roadPath, rimPaint);
    canvas.drawPath(roadPath, roadPaint);
    if (progressDistance > 0) {
      canvas.drawPath(progressPath, progressGlowPaint);
      canvas.drawPath(progressPath, progressPaint);
    }

    final lanePaint = Paint()
      ..color = AppColors.white.withValues(alpha: laneDashOpacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = laneDashStrokeWidth;

    _drawDashedPath(canvas, roadPath, lanePaint, laneDashPhase);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double phase) {
    final normalizedPhase = phase % laneDashPatternLength;
    for (final metric in path.computeMetrics()) {
      final startLimit = laneDashInset;
      final endLimit = metric.length - laneDashInset;
      if (endLimit <= startLimit) {
        continue;
      }

      // Reversing the sign of laneDashPhase reverses the visual flow direction.
      var distance = startLimit - normalizedPhase;
      while (distance < endLimit) {
        final dashStart = distance.clamp(startLimit, endLimit).toDouble();
        final dashEnd = (distance + laneDashWidth)
            .clamp(startLimit, endLimit)
            .toDouble();
        if (dashEnd > dashStart) {
          canvas.drawPath(metric.extractPath(dashStart, dashEnd), paint);
        }
        distance += laneDashPatternLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant RoadPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.laneDashPhase != laneDashPhase ||
        oldDelegate.geometry != geometry;
  }
}
