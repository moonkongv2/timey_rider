import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_texts.dart';
import 'motorcycle_widget.dart';
import 'road_painter.dart';

class RoadView extends StatelessWidget {
  const RoadView({
    super.key,
    required this.progress,
    this.motivationVideoAssetPath,
    this.motivationVideoMilestone,
    this.onMotivationVideoFinished,
  });

  final double progress;
  final String? motivationVideoAssetPath;
  final int? motivationVideoMilestone;
  final VoidCallback? onMotivationVideoFinished;
  static const double _motorcycleSize = 180;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final roadBounds = createRoadBounds(size);
        final motorcycleSize = math
            .min(
              _motorcycleSize,
              math.min(size.width * 0.46, size.height * 0.54),
            )
            .toDouble();
        final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
        final hasPassed = progress >= 1;
        final travelInset = math.min(
          motorcycleSize * 0.48,
          roadBounds.width * 0.18,
        );
        final roadX = ui.lerpDouble(
          roadBounds.left + travelInset,
          roadBounds.right - travelInset,
          clampedProgress,
        )!;
        final motorcycleLeft = hasPassed
            ? size.width + (motorcycleSize * 0.12)
            : roadX - (motorcycleSize / 2);
        final motorcycleTop = roadBounds.center.dy - (motorcycleSize * 0.8);
        const videoMargin = 16.0;
        final videoFrameTop = videoMargin;
        final videoFrameLeft = videoMargin;
        final videoFrameWidth = math.max(0.0, size.width - (videoMargin * 2));
        final videoFrameHeight = (roadBounds.top - (videoMargin * 2)).clamp(
          104.0,
          math.max(104.0, size.height - (videoMargin * 2)),
        );

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
                _SceneryLayer(
                  roadBounds: roadBounds,
                  motorcycleSize: motorcycleSize,
                  size: size,
                ),
                _Marker(
                  label: texts.common.start,
                  icon: Icons.home_rounded,
                  alignment: Alignment.bottomLeft,
                  margin: const EdgeInsets.only(left: 18, bottom: 16),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 850),
                  curve: Curves.easeInOutCubic,
                  left: motorcycleLeft,
                  top: motorcycleTop,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 850),
                    opacity: hasPassed ? 0 : 1,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 850),
                      curve: Curves.easeInOutCubic,
                      scale: hasPassed ? 0.78 : 1,
                      child: MotorcycleWidget(
                        size: motorcycleSize,
                        isArrived: progress >= 1,
                      ),
                    ),
                  ),
                ),
                if (motivationVideoAssetPath != null &&
                    motivationVideoMilestone != null)
                  Positioned(
                    left: videoFrameLeft,
                    top: videoFrameTop,
                    width: videoFrameWidth,
                    height: videoFrameHeight.toDouble(),
                    child: _MotivationVideoBubble(
                      key: ValueKey(motivationVideoMilestone),
                      assetPath: motivationVideoAssetPath!,
                      onFinished: onMotivationVideoFinished,
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

class _SceneryLayer extends StatefulWidget {
  const _SceneryLayer({
    required this.roadBounds,
    required this.motorcycleSize,
    required this.size,
  });

  final Rect roadBounds;
  final double motorcycleSize;
  final Size size;

  static const List<_SceneryEmoji> _items = [
    _SceneryEmoji('🏠', 0.00, -0.12),
    _SceneryEmoji('🌳', 0.18, 0.18),
    _SceneryEmoji('🚗', 0.36, 0.08),
    _SceneryEmoji('🌲', 0.54, -0.18),
    _SceneryEmoji('🏡', 0.72, 0.12),
    _SceneryEmoji('🌼', 0.90, -0.04),
  ];

  @override
  State<_SceneryLayer> createState() => _SceneryLayerState();
}

class _SceneryLayerState extends State<_SceneryLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emojiSize = (widget.motorcycleSize * 0.38)
        .clamp(44.0, 72.0)
        .toDouble();
    final laneTop = (widget.roadBounds.top - emojiSize - 20).clamp(
      12.0,
      widget.size.height - emojiSize - 12,
    );
    final travelWidth = widget.size.width + (emojiSize * 3);

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final scroll = _controller.value * travelWidth;

            return Stack(
              children: [
                for (final item in _SceneryLayer._items)
                  Positioned(
                    left: _loopedX(
                      (item.offset * travelWidth) - scroll,
                      travelWidth,
                      emojiSize,
                    ),
                    top: laneTop + (item.verticalOffset * emojiSize),
                    child: Opacity(
                      opacity: 0.9,
                      child: Text(
                        item.emoji,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontSize: emojiSize,
                          height: 1,
                          shadows: [
                            Shadow(
                              color: const Color(
                                0xFF5B4636,
                              ).withValues(alpha: 0.14),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _loopedX(double value, double width, double emojiSize) {
    return ((value % width) + width) % width - emojiSize;
  }
}

class _SceneryEmoji {
  const _SceneryEmoji(this.emoji, this.offset, this.verticalOffset);

  final String emoji;
  final double offset;
  final double verticalOffset;
}

class _MotivationVideoBubble extends StatefulWidget {
  const _MotivationVideoBubble({
    super.key,
    required this.assetPath,
    this.onFinished,
  });

  final String assetPath;
  final VoidCallback? onFinished;

  @override
  State<_MotivationVideoBubble> createState() => _MotivationVideoBubbleState();
}

class _MotivationVideoBubbleState extends State<_MotivationVideoBubble> {
  late final VideoPlayerController _controller;
  bool _isReady = false;
  bool _didFinish = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath);
    _controller.addListener(_handleVideoChanged);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(false);
      await _controller.play();
      if (mounted) {
        setState(() => _isReady = true);
      }
    } catch (_) {
      _finish();
    }
  }

  void _handleVideoChanged() {
    final value = _controller.value;
    if (_didFinish || !value.isInitialized || value.duration == Duration.zero) {
      return;
    }

    if (value.position >= value.duration) {
      _finish();
    }
  }

  void _finish() {
    if (_didFinish) {
      return;
    }
    _didFinish = true;
    if (mounted) {
      widget.onFinished?.call();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleVideoChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B4636).withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.label,
    required this.icon,
    required this.alignment,
    required this.margin,
  });

  final String label;
  final IconData icon;
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
            padding: const EdgeInsets.all(9),
            child: Semantics(
              label: label,
              child: Icon(icon, color: const Color(0xFF5B4636), size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
