import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/reward_item.dart';
import 'reward_sticker_image.dart';

/// Shows a fountain/explosion of stickers as an overlay on screen.
///
/// Call [showStickerFountain] to trigger the animation from anywhere.
void showStickerFountain({
  required BuildContext context,
  required RewardDefinition reward,
  required int count,
  Offset? position,
}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _StickerFountainOverlay(
      reward: reward,
      count: count,
      position: position,
      onFinished: () => entry.remove(),
    ),
  );

  HapticFeedback.mediumImpact();
  overlay.insert(entry);
}

class _StickerFountainOverlay extends StatefulWidget {
  const _StickerFountainOverlay({
    required this.reward,
    required this.count,
    this.position,
    required this.onFinished,
  });

  final RewardDefinition reward;
  final int count;
  final Offset? position;
  final VoidCallback onFinished;

  @override
  State<_StickerFountainOverlay> createState() =>
      _StickerFountainOverlayState();
}

class _StickerFountainOverlayState extends State<_StickerFountainOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ParticleData> _particles;

  static const _maxParticles = 40;
  static const _duration = Duration(milliseconds: 2200);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _particles = _generateParticles();
    _controller.forward().then((_) {
      if (mounted) widget.onFinished();
    });
  }

  List<_ParticleData> _generateParticles() {
    final rng = Random();
    final particleCount = widget.count.clamp(1, _maxParticles);

    return List.generate(particleCount, (_) {
      // Random angle from center (full circle)
      final angle = rng.nextDouble() * 2 * pi;
      // Random distance – how far the sticker flies (Reduced distance)
      final distance = 80.0 + rng.nextDouble() * 120.0;
      // Random size for visual variety (Even larger size)
      final size = 70.0 + rng.nextDouble() * 40.0;
      // Random rotation
      final rotation = (rng.nextDouble() - 0.5) * 1.6;
      // Slight delay so particles don't all start at same time
      final delayFraction = rng.nextDouble() * 0.15;

      return _ParticleData(
        angle: angle,
        distance: distance,
        size: size,
        rotation: rotation,
        delayFraction: delayFraction,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final screenSize = MediaQuery.of(context).size;
        final center = widget.position ?? Offset(screenSize.width / 2, screenSize.height / 2);

        return Stack(
          children: [
            for (final particle in _particles)
              _buildParticle(particle, center),
          ],
        );
      },
    );
  }

  Widget _buildParticle(_ParticleData p, Offset center) {
    // Adjust progress accounting for individual delay
    final rawProgress =
        ((_controller.value - p.delayFraction) / (1.0 - p.delayFraction))
            .clamp(0.0, 1.0);

    if (rawProgress == 0.0) return const SizedBox.shrink();

    // Burst out phase (0 → 0.4): fast explosion outward
    // Float phase (0.4 → 0.7): slow drift + slight gravity
    // Fade phase (0.7 → 1.0): fade out while falling

    final burstProgress = Curves.easeOutCubic.transform(
      (rawProgress / 0.5).clamp(0.0, 1.0),
    );

    // Gravity: increases over time
    final gravityOffset = rawProgress * rawProgress * 180.0;

    final dx = cos(p.angle) * p.distance * burstProgress;
    final dy = sin(p.angle) * p.distance * burstProgress + gravityOffset;

    // Opacity: fully visible during burst, fades from 0.6 onward
    final opacity = rawProgress < 0.6
        ? 1.0
        : (1.0 - ((rawProgress - 0.6) / 0.4)).clamp(0.0, 1.0);

    // Scale: pops in, then shrinks slightly
    final scale = rawProgress < 0.15
        ? Curves.elasticOut
            .transform((rawProgress / 0.15).clamp(0.0, 1.0))
        : 1.0 - (rawProgress - 0.15) * 0.3;

    return Positioned(
      left: center.dx - p.size / 2 + dx,
      top: center.dy - p.size / 2 + dy,
      child: Transform.rotate(
        angle: p.rotation * rawProgress,
        child: Transform.scale(
          scale: scale.clamp(0.0, 1.5),
          child: Opacity(
            opacity: opacity,
            child: RewardStickerImage(
              reward: widget.reward,
              size: p.size,
              locked: false,
              framed: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _ParticleData {
  const _ParticleData({
    required this.angle,
    required this.distance,
    required this.size,
    required this.rotation,
    required this.delayFraction,
  });

  final double angle;
  final double distance;
  final double size;
  final double rotation;
  final double delayFraction;
}
