import 'package:flutter/material.dart';

import 'motorcycle_widget.dart';
import 'road_painter.dart';

class RoadView extends StatelessWidget {
  const RoadView({super.key, required this.progress});

  final double progress;
  static const double _motorcycleSize = 180;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final path = createRoadPath(size);
        final metric = path.computeMetrics().first;
        final tangent = metric.getTangentForOffset(
          metric.length * progress.clamp(0.0, 1.0),
        );
        final position = tangent?.position ?? Offset.zero;
        final angle = tangent?.angle ?? 0;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFE8CC),
            borderRadius: BorderRadius.circular(28),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: RoadPainter(progress: progress)),
                ),
                _Marker(
                  label: '출발',
                  alignment: Alignment.bottomLeft,
                  margin: const EdgeInsets.only(left: 18, bottom: 16),
                ),
                _Marker(
                  label: '도착',
                  alignment: Alignment.topRight,
                  margin: const EdgeInsets.only(top: 16, right: 18),
                ),
                Positioned(
                  left: position.dx - (_motorcycleSize / 2),
                  top: position.dy - (_motorcycleSize / 2),
                  child: MotorcycleWidget(
                    size: _motorcycleSize,
                    angle: angle,
                    isArrived: progress >= 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.label,
    required this.alignment,
    required this.margin,
  });

  final String label;
  final Alignment alignment;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: margin,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF5B4636),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
