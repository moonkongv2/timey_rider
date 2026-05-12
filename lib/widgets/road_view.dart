import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_texts.dart';
import '../models/vehicle.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'road_painter.dart';
import 'vehicle_widget.dart';

class RoadView extends StatelessWidget {
  const RoadView({
    super.key,
    required this.progress,
    required this.vehicle,
    this.motivationVideoAssetPath,
    this.motivationVideoMilestone,
    this.onMotivationVideoFinished,
  });

  final double progress;
  final VehicleDefinition vehicle;
  final String? motivationVideoAssetPath;
  final int? motivationVideoMilestone;
  final VoidCallback? onMotivationVideoFinished;
  static const double _vehicleSize = 138;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final vehicleSize = math
            .min(_vehicleSize, math.min(size.width * 0.30, size.height * 0.20))
            .toDouble();
        final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
        final vehiclePosition = roadPointForProgress(size, clampedProgress);
        final isVehicleFacingLeft = roadIsFacingLeftForProgress(
          size,
          clampedProgress,
        );
        final vehicleLeft = vehiclePosition.dx - (vehicleSize / 2);
        final vehicleTop = vehiclePosition.dy - (vehicleSize / 2);
        const videoMargin = 16.0;
        final videoFrameTop = videoMargin;
        final videoFrameLeft = videoMargin;
        final videoFrameWidth = math.max(0.0, size.width - (videoMargin * 2));
        final videoFrameHeight = (size.height * 0.34).clamp(104.0, 220.0);

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.hero,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surfaceWarm,
                AppColors.surfaceBlue.withValues(alpha: 0.44),
                AppColors.surfacePink.withValues(alpha: 0.34),
                AppColors.cream,
              ],
              stops: const [0, 0.48, 0.78, 1],
            ),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.72),
              width: 1.2,
            ),
            boxShadow: AppShadows.hero,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.hero,
            child: Stack(
              children: [
                const Positioned.fill(child: _RoadScenery()),
                Positioned.fill(
                  child: CustomPaint(painter: RoadPainter(progress: progress)),
                ),
                _RoadMarker(
                  position: roadPointForProgress(size, 0),
                  icon: Icons.home_rounded,
                  label: texts.common.start,
                  isActive: true,
                ),
                _RoadMarker(
                  position: roadPointForProgress(size, 1),
                  icon: Icons.flag_rounded,
                  label: texts.common.complete,
                  isActive: clampedProgress >= 1,
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 850),
                  curve: Curves.easeInOutCubic,
                  left: vehicleLeft,
                  top: vehicleTop,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 850),
                    opacity: progress >= 1 ? 0.78 : 1,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 850),
                      curve: Curves.easeInOutCubic,
                      scale: progress >= 1 ? 0.92 : 1,
                      child: VehicleWidget(
                        vehicle: vehicle,
                        size: vehicleSize,
                        isFacingLeft: isVehicleFacingLeft,
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

class _RoadMarker extends StatelessWidget {
  const _RoadMarker({
    required this.position,
    required this.icon,
    required this.isActive,
    this.label,
  });

  final Offset position;
  final IconData icon;
  final bool isActive;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final markerColor = isActive
        ? AppColors.surfaceYellow.withValues(alpha: 0.92)
        : AppColors.white.withValues(alpha: 0.82);
    final iconColor = isActive ? AppColors.textStrong : AppColors.textPrimary;

    return Positioned(
      left: position.dx - 18,
      top: position.dy - 18,
      width: 36,
      height: 36,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        scale: isActive ? 1 : 0.86,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: markerColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primarySoft : AppColors.borderSoft,
              width: 1.4,
            ),
            boxShadow: AppShadows.surface,
          ),
          child: Semantics(
            label: label ?? 'milestone',
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }
}

class _RoadScenery extends StatelessWidget {
  const _RoadScenery();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        _SceneryEmoji(emoji: '☁️', alignment: Alignment(-0.76, -0.86)),
        _SceneryEmoji(emoji: '🌤️', alignment: Alignment(0.78, -0.78)),
        _SceneryEmoji(emoji: '🌷', alignment: Alignment(-0.82, 0.34)),
        _SceneryEmoji(emoji: '🌿', alignment: Alignment(0.84, 0.42)),
      ],
    );
  }
}

class _SceneryEmoji extends StatelessWidget {
  const _SceneryEmoji({required this.emoji, required this.alignment});

  final String emoji;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Opacity(
        opacity: 0.46,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.34),
            borderRadius: AppRadius.pill,
            border: Border.all(color: AppColors.white.withValues(alpha: 0.36)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Text(
              emoji,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(fontSize: 19, height: 1),
            ),
          ),
        ),
      ),
    );
  }
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
        color: AppColors.white,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.72)),
        boxShadow: AppShadows.hero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: ClipRRect(
          borderRadius: AppRadius.compactCard,
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
