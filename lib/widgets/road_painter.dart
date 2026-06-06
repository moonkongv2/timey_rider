import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

Rect createRoadBounds(Size size) {
  final isLandscape = size.width > size.height;
  final horizontalPadding =
      (isLandscape ? size.width * 0.10 : size.width * 0.13)
          .clamp(isLandscape ? 84.0 : 46.0, isLandscape ? 118.0 : 62.0)
          .toDouble();
  final verticalPadding = isLandscape ? size.height * 0.18 : size.height * 0.06;

  return Rect.fromLTWH(
    horizontalPadding,
    verticalPadding,
    size.width - (horizontalPadding * 2),
    size.height - (verticalPadding * 2),
  );
}

Path createRoadPath(Size size) {
  final bounds = createRoadBounds(size);
  final left = bounds.left;
  final right = bounds.right;
  final top = bounds.top;
  final bottom = bounds.bottom;
  final height = bounds.height;
  final rowCount = size.width > size.height ? 5 : 10;
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

class RoadPainter extends CustomPainter {
  const RoadPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final roadPath = createRoadPath(size);
    final roadWidth = roadStrokeWidthForSize(size);
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
      ..color = const Color(0xFFD0F5DA)
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
      ..color = AppColors.white.withValues(alpha: 0.68)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.1;

    _drawDashedPath(canvas, roadPath, lanePaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 9.0;
    const gap = 22.0;

    for (final metric in path.computeMetrics()) {
      var distance = 18.0;
      while (distance < metric.length - 18) {
        final nextDistance = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, nextDistance), paint);
        distance += dashWidth + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant RoadPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
