import 'package:flutter/material.dart';

Path createRoadPath(Size size) {
  final horizontalPadding = size.width * 0.12;
  final verticalPadding = size.height * 0.16;

  return Path()
    ..moveTo(horizontalPadding, size.height - verticalPadding)
    ..cubicTo(
      size.width * 0.26,
      size.height * 0.62,
      size.width * 0.45,
      size.height * 0.88,
      size.width * 0.58,
      size.height * 0.50,
    )
    ..cubicTo(
      size.width * 0.70,
      size.height * 0.18,
      size.width * 0.84,
      size.height * 0.30,
      size.width - horizontalPadding,
      verticalPadding,
    );
}

class RoadPainter extends CustomPainter {
  const RoadPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = createRoadPath(size);

    final shadowPaint = Paint()
      ..color = const Color(0xFFE9C8A6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34
      ..strokeCap = StrokeCap.round;

    final roadPaint = Paint()
      ..color = const Color(0xFF8EC5A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;

    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = const Color(0xFFFFC857)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, roadPaint);
    canvas.drawPath(path, centerPaint);

    final metric = path.computeMetrics().first;
    final progressPath = metric.extractPath(
      0,
      metric.length * progress.clamp(0.0, 1.0),
    );
    canvas.drawPath(progressPath, progressPaint);
  }

  @override
  bool shouldRepaint(covariant RoadPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
