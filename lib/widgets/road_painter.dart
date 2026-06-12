import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/vehicle.dart';
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

class RoadCourseVisualStyle {
  const RoadCourseVisualStyle({
    required this.backgroundColors,
    required this.backgroundStops,
    required this.softShadowColor,
    required this.rimColor,
    required this.pathColor,
    required this.progressColor,
    required this.progressGlowColor,
    required this.laneColor,
  });

  final List<Color> backgroundColors;
  final List<double> backgroundStops;
  final Color softShadowColor;
  final Color rimColor;
  final Color pathColor;
  final Color progressColor;
  final Color progressGlowColor;
  final Color laneColor;

  static RoadCourseVisualStyle forCourseKind(VehicleCourseKind courseKind) {
    switch (courseKind) {
      case VehicleCourseKind.sky:
        return RoadCourseVisualStyle(
          backgroundColors: [
            AppColors.white.withValues(alpha: 0.96),
            const Color(0xFFEAF7FF),
            AppColors.skyBlue.withValues(alpha: 0.34),
            const Color(0xFFFFF9E8).withValues(alpha: 0.92),
          ],
          backgroundStops: const [0, 0.5, 0.78, 1],
          softShadowColor: AppColors.blueDeep.withValues(alpha: 0.10),
          rimColor: AppColors.white.withValues(alpha: 0.88),
          pathColor: const Color(0xFFD9F0FF),
          progressColor: const Color(0xFFFFD36E).withValues(alpha: 0.94),
          progressGlowColor: const Color(0xFFFFC857).withValues(alpha: 0.18),
          laneColor: AppColors.white.withValues(alpha: 0.82),
        );
      case VehicleCourseKind.water:
        return RoadCourseVisualStyle(
          backgroundColors: [
            AppColors.white.withValues(alpha: 0.96),
            const Color(0xFFE8FBFF),
            const Color(0xFFC7F2EA).withValues(alpha: 0.55),
            const Color(0xFFEFFAF7).withValues(alpha: 0.92),
          ],
          backgroundStops: const [0, 0.5, 0.78, 1],
          softShadowColor: AppColors.blueDeep.withValues(alpha: 0.10),
          rimColor: AppColors.white.withValues(alpha: 0.88),
          pathColor: const Color(0xFFBFEFEA),
          progressColor: const Color(0xFF72D8E8).withValues(alpha: 0.92),
          progressGlowColor: AppColors.blueDeep.withValues(alpha: 0.16),
          laneColor: AppColors.white.withValues(alpha: 0.75),
        );
      case VehicleCourseKind.rail:
        return RoadCourseVisualStyle(
          backgroundColors: [
            AppColors.white.withValues(alpha: 0.96),
            const Color(0xFFF4FBED),
            const Color(0xFFDDECC9).withValues(alpha: 0.52),
            AppColors.cream.withValues(alpha: 0.92),
          ],
          backgroundStops: const [0, 0.5, 0.78, 1],
          softShadowColor: AppColors.brown700.withValues(alpha: 0.08),
          rimColor: AppColors.brown700.withValues(alpha: 0.30),
          pathColor: const Color(0xFFC9D7B8),
          progressColor: const Color(0xFFE5BC73).withValues(alpha: 0.95),
          progressGlowColor: const Color(0xFFC58A3B).withValues(alpha: 0.14),
          laneColor: AppColors.surfaceSoft.withValues(alpha: 0.78),
        );
      case VehicleCourseKind.road:
      case VehicleCourseKind.field:
        return RoadCourseVisualStyle(
          backgroundColors: [
            AppColors.white.withValues(alpha: 0.96),
            AppColors.surfaceWarm,
            AppColors.surfaceBlue.withValues(alpha: 0.18),
            AppColors.cream.withValues(alpha: 0.92),
          ],
          backgroundStops: const [0, 0.5, 0.78, 1],
          softShadowColor: AppColors.brown700.withValues(alpha: 0.075),
          rimColor: AppColors.white.withValues(alpha: 0.90),
          pathColor: const Color(0xFFBCEFD0),
          progressColor: const Color(0xFFFFC38B).withValues(alpha: 0.92),
          progressGlowColor: AppColors.orange.withValues(alpha: 0.14),
          laneColor: AppColors.white.withValues(
            alpha: RoadPainter.laneDashOpacity,
          ),
        );
    }
  }
}

class RoadPainter extends CustomPainter {
  const RoadPainter({
    required this.progress,
    this.laneDashPhase = 0,
    this.skyPathCloudPhase = 0,
    this.geometry,
    this.courseKind = VehicleCourseKind.road,
  });

  static const laneDashWidth = 15.0;
  static const laneDashGap = 22.0;
  static const laneDashPatternLength = laneDashWidth + laneDashGap;
  static const laneDashInset = 18.0;
  static const laneDashStrokeWidth = 3.4;
  static const laneDashOpacity = 0.72;
  static const laneDashAnimationDuration = Duration(milliseconds: 1200);
  static const skyCloudVerticalGap = 142.0;
  static const skyCloudMinWidth = 72.0;
  static const skyCloudMaxWidth = 118.0;
  static const skyPathCloudGap = 154.0;
  static const skyPathCloudWidth = 38.0;
  static const skyFlowPatternLength = skyPathCloudGap;
  static const skyPathCloudAnimationDuration = Duration(milliseconds: 4800);
  static const waterRippleVerticalGap = 92.0;
  static const waterRippleMarkWidth = 42.0;
  static const waterWaveWidth = 24.0;
  static const waterWaveGap = 34.0;
  static const waterWavePatternLength = waterWaveWidth + waterWaveGap;
  static const waterWaveStrokeWidth = 2.5;
  static const waterWaveAnimationDuration = Duration(milliseconds: 3000);
  static const railSleeperGap = 38.0;
  static const railSleeperPatternLength = railSleeperGap;
  static const railSleeperStrokeWidth = 3.8;
  static const railAnimationDuration = Duration(milliseconds: 2200);

  final double progress;
  final double laneDashPhase;
  final double skyPathCloudPhase;
  final RoadCourseGeometry? geometry;
  final VehicleCourseKind courseKind;

  static double flowPatternLengthForCourseKind(VehicleCourseKind courseKind) {
    return switch (courseKind) {
      VehicleCourseKind.sky => skyFlowPatternLength,
      VehicleCourseKind.water => waterWavePatternLength,
      VehicleCourseKind.rail => railSleeperPatternLength,
      VehicleCourseKind.road ||
      VehicleCourseKind.field => laneDashPatternLength,
    };
  }

  static Duration flowAnimationDurationForCourseKind(
    VehicleCourseKind courseKind,
  ) {
    return switch (courseKind) {
      VehicleCourseKind.water => waterWaveAnimationDuration,
      VehicleCourseKind.rail => railAnimationDuration,
      VehicleCourseKind.field ||
      VehicleCourseKind.road ||
      VehicleCourseKind.sky => laneDashAnimationDuration,
    };
  }

  static double effectiveRoadStrokeWidthForCourseKind(
    VehicleCourseKind courseKind,
    double roadWidth,
  ) {
    return switch (courseKind) {
      VehicleCourseKind.rail => (roadWidth * 0.52).clamp(14.0, 26.0).toDouble(),
      VehicleCourseKind.road ||
      VehicleCourseKind.field ||
      VehicleCourseKind.sky ||
      VehicleCourseKind.water => roadWidth,
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final visualStyle = RoadCourseVisualStyle.forCourseKind(courseKind);
    final roadPath = geometry == null
        ? createRoadPath(size)
        : createRoadPathForGeometry(geometry!);
    final baseRoadWidth = roadStrokeWidthForSize(
      geometry?.viewportSize ?? size,
    );
    final roadWidth = effectiveRoadStrokeWidthForCourseKind(
      courseKind,
      baseRoadWidth,
    );
    final roadMetric = roadPath.computeMetrics().first;
    final progressDistance =
        roadMetric.length * progress.clamp(0.0, 1.0).toDouble();
    final progressPath = roadMetric.extractPath(0, progressDistance);

    if (courseKind == VehicleCourseKind.sky) {
      _drawSkyClouds(canvas, size);
    } else if (courseKind == VehicleCourseKind.water) {
      _drawWaterRipples(canvas, size);
    }

    final rimStrokeWidth = switch (courseKind) {
      VehicleCourseKind.rail => roadWidth + 8,
      VehicleCourseKind.road ||
      VehicleCourseKind.field ||
      VehicleCourseKind.sky ||
      VehicleCourseKind.water => roadWidth + 5,
    };
    final softShadowPaint = Paint()
      ..color = visualStyle.softShadowColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = roadWidth + 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final rimPaint = Paint()
      ..color = visualStyle.rimColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = rimStrokeWidth;
    final roadPaint = Paint()
      ..color = visualStyle.pathColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = roadWidth;
    final progressPaint = Paint()
      ..color = visualStyle.progressColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = roadWidth;
    final progressGlowPaint = Paint()
      ..color = visualStyle.progressGlowColor
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
      ..color = visualStyle.laneColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = laneDashStrokeWidth;

    if (courseKind == VehicleCourseKind.sky) {
      _drawSkyPathClouds(canvas, roadPath, skyPathCloudPhase);
    } else if (courseKind == VehicleCourseKind.water) {
      _drawWaterFlow(canvas, roadPath, visualStyle.laneColor, laneDashPhase);
    } else if (courseKind == VehicleCourseKind.rail) {
      _drawRailTrack(canvas, roadPath, laneDashPhase, roadWidth);
    } else {
      _drawDashedPath(canvas, roadPath, lanePaint, laneDashPhase);
    }
  }

  void _drawWaterRipples(Canvas canvas, Size size) {
    final ripplePaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;
    final rowCount = (size.height / waterRippleVerticalGap).ceil() + 1;

    for (var row = 0; row < rowCount; row += 1) {
      final y = (row * waterRippleVerticalGap) + 42;
      if (y > size.height + waterRippleVerticalGap) {
        break;
      }

      final startRatio = switch (row % 4) {
        0 => 0.12,
        1 => 0.58,
        2 => 0.30,
        _ => 0.72,
      };
      final start = Offset(size.width * startRatio, y);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          start.dx + (waterRippleMarkWidth * 0.25),
          start.dy - 5,
          start.dx + (waterRippleMarkWidth * 0.5),
          start.dy,
        )
        ..quadraticBezierTo(
          start.dx + (waterRippleMarkWidth * 0.75),
          start.dy + 5,
          start.dx + waterRippleMarkWidth,
          start.dy,
        );
      canvas.drawPath(path, ripplePaint);
    }
  }

  void _drawSkyClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.78)
      ..style = PaintingStyle.fill;
    final shadePaint = Paint()
      ..color = AppColors.skyBlue.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final rowCount = (size.height / skyCloudVerticalGap).ceil() + 1;

    for (var row = 0; row < rowCount; row += 1) {
      final y = (row * skyCloudVerticalGap) + 38;
      if (y > size.height + skyCloudMaxWidth) {
        break;
      }

      final xRatio = switch (row % 4) {
        0 => 0.18,
        1 => 0.78,
        2 => 0.34,
        _ => 0.66,
      };
      final cloudWidth =
          skyCloudMinWidth +
          ((row % 3) * ((skyCloudMaxWidth - skyCloudMinWidth) / 2));
      final cloudHeight = cloudWidth * 0.42;
      final center = Offset(size.width * xRatio, y);
      _drawSkyCloud(
        canvas: canvas,
        center: center,
        width: cloudWidth,
        height: cloudHeight,
        cloudPaint: cloudPaint,
        shadePaint: shadePaint,
      );
    }
  }

  void _drawSkyCloud({
    required Canvas canvas,
    required Offset center,
    required double width,
    required double height,
    required Paint cloudPaint,
    required Paint shadePaint,
  }) {
    final baseRect = Rect.fromCenter(
      center: center + Offset(width * 0.04, height * 0.14),
      width: width,
      height: height * 0.58,
    );
    canvas.drawOval(baseRect.shift(Offset(0, height * 0.08)), shadePaint);
    canvas.drawOval(baseRect, cloudPaint);
    canvas.drawCircle(
      center + Offset(width * -0.28, height * -0.02),
      height * 0.28,
      cloudPaint,
    );
    canvas.drawCircle(
      center + Offset(width * -0.05, height * -0.22),
      height * 0.38,
      cloudPaint,
    );
    canvas.drawCircle(
      center + Offset(width * 0.25, height * -0.08),
      height * 0.32,
      cloudPaint,
    );
  }

  void _drawSkyPathClouds(Canvas canvas, Path path, double phase) {
    final cloudPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.42)
      ..style = PaintingStyle.fill;
    final shadePaint = Paint()
      ..color = AppColors.skyBlue.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final normalizedPhase = phase % skyPathCloudGap;

    for (final metric in path.computeMetrics()) {
      final startLimit = laneDashInset;
      final endLimit = metric.length - laneDashInset;
      if (endLimit <= startLimit) {
        continue;
      }

      var distance = startLimit - normalizedPhase;
      while (distance < endLimit) {
        if (distance >= startLimit && distance <= endLimit) {
          final tangent = metric.getTangentForOffset(distance);
          if (tangent != null && tangent.vector.distance > 0) {
            final direction = tangent.vector / tangent.vector.distance;
            final center =
                tangent.position - (direction * (skyPathCloudWidth * 0.16));
            _drawSkyCloud(
              canvas: canvas,
              center: center,
              width: skyPathCloudWidth,
              height: skyPathCloudWidth * 0.38,
              cloudPaint: cloudPaint,
              shadePaint: shadePaint,
            );
          }
        }

        distance += skyPathCloudGap;
      }
    }
  }

  void _drawWaterFlow(Canvas canvas, Path path, Color color, double phase) {
    final wavePaint = Paint()
      ..color = color.withValues(alpha: 0.68)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = waterWaveStrokeWidth;
    final normalizedPhase = phase % waterWavePatternLength;

    for (final metric in path.computeMetrics()) {
      final startLimit = laneDashInset;
      final endLimit = metric.length - laneDashInset;
      if (endLimit <= startLimit) {
        continue;
      }

      var distance = startLimit - normalizedPhase;
      while (distance < endLimit) {
        final centerDistance = distance + (waterWaveWidth / 2);
        if (centerDistance >= startLimit && centerDistance <= endLimit) {
          final tangent = metric.getTangentForOffset(centerDistance);
          if (tangent != null && tangent.vector.distance > 0) {
            final direction = tangent.vector / tangent.vector.distance;
            final normal = Offset(-direction.dy, direction.dx);
            const amplitude = 4.8;
            final center = tangent.position;
            final start = center - (direction * (waterWaveWidth * 0.5));
            final end = center + (direction * (waterWaveWidth * 0.5));
            final firstControl =
                center -
                (direction * (waterWaveWidth * 0.24)) +
                (normal * amplitude);
            final secondControl =
                center +
                (direction * (waterWaveWidth * 0.24)) -
                (normal * amplitude);
            final wavePath = Path()
              ..moveTo(start.dx, start.dy)
              ..quadraticBezierTo(
                firstControl.dx,
                firstControl.dy,
                center.dx,
                center.dy,
              )
              ..quadraticBezierTo(
                secondControl.dx,
                secondControl.dy,
                end.dx,
                end.dy,
              );

            canvas.drawPath(wavePath, wavePaint);
          }
        }

        distance += waterWavePatternLength;
      }
    }
  }

  static double railSleeperHalfLengthForRoadWidth(double roadWidth) {
    return (roadWidth * 0.85).clamp(11.0, 18.0).toDouble();
  }

  void _drawRailTrack(
    Canvas canvas,
    Path path,
    double phase,
    double roadWidth,
  ) {
    final sleeperHalfLength = railSleeperHalfLengthForRoadWidth(roadWidth);
    final sleeperPaint = Paint()
      ..color = AppColors.brown700.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = railSleeperStrokeWidth;
    final normalizedPhase = phase % railSleeperPatternLength;

    for (final metric in path.computeMetrics()) {
      final startLimit = laneDashInset;
      final endLimit = metric.length - laneDashInset;
      if (endLimit <= startLimit) {
        continue;
      }

      var distance = startLimit - normalizedPhase;
      while (distance < endLimit) {
        if (distance >= startLimit && distance <= endLimit) {
          final tangent = metric.getTangentForOffset(distance);
          if (tangent != null && tangent.vector.distance > 0) {
            final direction = tangent.vector / tangent.vector.distance;
            final normal = Offset(-direction.dy, direction.dx);
            final center = tangent.position;
            canvas.drawLine(
              center - (normal * sleeperHalfLength),
              center + (normal * sleeperHalfLength),
              sleeperPaint,
            );
          }
        }

        distance += railSleeperPatternLength;
      }
    }
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
        oldDelegate.skyPathCloudPhase != skyPathCloudPhase ||
        oldDelegate.geometry != geometry ||
        oldDelegate.courseKind != courseKind;
  }
}
