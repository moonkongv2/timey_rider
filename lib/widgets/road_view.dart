import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_texts.dart';
import '../models/meal_timer_config.dart';
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
    this.avatarMode = AvatarImageMode.defaultImage,
    this.customAvatarImagePath,
    this.avatarScale = 1.0,
    this.avatarOffsetX = 0.0,
    this.avatarOffsetY = 0.0,
    this.avatarRotationDegrees = 0.0,
    this.avatarImageBuilder,
    this.motivationVideoAssetPath,
    this.motivationVideoMilestone,
    this.onMotivationVideoFinished,
    this.showVehicle = true,
    this.showMotivationVideo = true,
  });

  final double progress;
  final VehicleDefinition vehicle;
  final AvatarImageMode avatarMode;
  final String? customAvatarImagePath;
  final double avatarScale;
  final double avatarOffsetX;
  final double avatarOffsetY;
  final double avatarRotationDegrees;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;
  final String? motivationVideoAssetPath;
  final int? motivationVideoMilestone;
  final VoidCallback? onMotivationVideoFinished;
  final bool showVehicle;
  final bool showMotivationVideo;
  static const double _vehicleSize = 138;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final isLandscape = size.width > size.height;
        final vehicleSize = math
            .min(
              isLandscape ? 124.0 : _vehicleSize,
              math.min(
                size.width * (isLandscape ? 0.16 : 0.30),
                size.height * (isLandscape ? 0.23 : 0.20),
              ),
            )
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
        final videoFrameWidth = isLandscape
            ? math
                  .min(size.width * 0.36, 460.0)
                  .clamp(320.0, size.width - (videoMargin * 2))
                  .toDouble()
            : math.max(0.0, size.width - (videoMargin * 2));
        final videoFrameHeight = isLandscape
            ? videoFrameWidth * 9 / 16
            : (videoFrameWidth * 0.62).clamp(
                132.0,
                math.max(140.0, size.height * 0.44),
              );
        final videoFrameLeft = isLandscape
            ? size.width - videoFrameWidth - videoMargin
            : videoMargin;
        final videoFrameTop = isLandscape ? size.height * 0.18 : videoMargin;

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
                Positioned.fill(
                  child: CustomPaint(painter: RoadPainter(progress: progress)),
                ),
                _RoadMarker(
                  position: roadPointForProgress(size, 0),
                  icon: Icons.home_rounded,
                  label: texts.common.start,
                  isActive: true,
                  size: isLandscape ? 42 : 36,
                ),
                _RoadMarker(
                  position: roadPointForProgress(size, 1),
                  icon: Icons.flag_rounded,
                  label: texts.common.complete,
                  isActive: clampedProgress >= 1,
                  size: isLandscape ? 42 : 36,
                ),
                if (showVehicle)
                  _PositionedRoadVehicle(
                    progress: progress,
                    vehicle: vehicle,
                    vehicleSize: vehicleSize,
                    vehicleLeft: vehicleLeft,
                    vehicleTop: vehicleTop,
                    isVehicleFacingLeft: isVehicleFacingLeft,
                    avatarMode: avatarMode,
                    customAvatarImagePath: customAvatarImagePath,
                    avatarScale: avatarScale,
                    avatarOffsetX: avatarOffsetX,
                    avatarOffsetY: avatarOffsetY,
                    avatarRotationDegrees: avatarRotationDegrees,
                    avatarImageBuilder: avatarImageBuilder,
                  ),
                if (showMotivationVideo &&
                    motivationVideoAssetPath != null &&
                    motivationVideoMilestone != null)
                  Positioned(
                    left: videoFrameLeft,
                    top: videoFrameTop,
                    width: videoFrameWidth,
                    height: videoFrameHeight.toDouble(),
                    child: _MotivationVideoBubble(
                      key: ValueKey(
                        'motivationVideoBubble_$motivationVideoMilestone',
                      ),
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

class RoadMotivationVideoLayer extends StatelessWidget {
  const RoadMotivationVideoLayer({
    super.key,
    required this.assetPath,
    required this.milestone,
    this.onFinished,
  });

  final String assetPath;
  final int milestone;
  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final isLandscape = size.width > size.height;
          const videoMargin = 16.0;
          final videoFrameWidth = isLandscape
              ? math
                    .min(size.width * 0.36, 460.0)
                    .clamp(320.0, size.width - (videoMargin * 2))
                    .toDouble()
              : math.max(0.0, size.width - (videoMargin * 2));
          final videoFrameHeight = isLandscape
              ? videoFrameWidth * 9 / 16
              : (videoFrameWidth * 0.62).clamp(
                  132.0,
                  math.max(140.0, size.height * 0.44),
                );
          final videoFrameLeft = isLandscape
              ? size.width - videoFrameWidth - videoMargin
              : videoMargin;
          final videoFrameTop = isLandscape ? size.height * 0.18 : videoMargin;

          return Stack(
            children: [
              Positioned(
                left: videoFrameLeft,
                top: videoFrameTop,
                width: videoFrameWidth,
                height: videoFrameHeight.toDouble(),
                child: _MotivationVideoBubble(
                  key: ValueKey('motivationVideoBubble_$milestone'),
                  assetPath: assetPath,
                  onFinished: onFinished,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RoadVehicleLayer extends StatelessWidget {
  const RoadVehicleLayer({
    super.key,
    required this.progress,
    required this.vehicle,
    this.avatarMode = AvatarImageMode.defaultImage,
    this.customAvatarImagePath,
    this.avatarScale = 1.0,
    this.avatarOffsetX = 0.0,
    this.avatarOffsetY = 0.0,
    this.avatarRotationDegrees = 0.0,
    this.avatarImageBuilder,
  });

  final double progress;
  final VehicleDefinition vehicle;
  final AvatarImageMode avatarMode;
  final String? customAvatarImagePath;
  final double avatarScale;
  final double avatarOffsetX;
  final double avatarOffsetY;
  final double avatarRotationDegrees;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final isLandscape = size.width > size.height;
          final vehicleSize = math
              .min(
                isLandscape ? 124.0 : RoadView._vehicleSize,
                math.min(
                  size.width * (isLandscape ? 0.16 : 0.30),
                  size.height * (isLandscape ? 0.23 : 0.20),
                ),
              )
              .toDouble();
          final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
          final vehiclePosition = roadPointForProgress(size, clampedProgress);
          final isVehicleFacingLeft = roadIsFacingLeftForProgress(
            size,
            clampedProgress,
          );
          final vehicleLeft = vehiclePosition.dx - (vehicleSize / 2);
          final vehicleTop = vehiclePosition.dy - (vehicleSize / 2);

          return Stack(
            children: [
              _PositionedRoadVehicle(
                progress: progress,
                vehicle: vehicle,
                vehicleSize: vehicleSize,
                vehicleLeft: vehicleLeft,
                vehicleTop: vehicleTop,
                isVehicleFacingLeft: isVehicleFacingLeft,
                avatarMode: avatarMode,
                customAvatarImagePath: customAvatarImagePath,
                avatarScale: avatarScale,
                avatarOffsetX: avatarOffsetX,
                avatarOffsetY: avatarOffsetY,
                avatarRotationDegrees: avatarRotationDegrees,
                avatarImageBuilder: avatarImageBuilder,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PositionedRoadVehicle extends StatelessWidget {
  const _PositionedRoadVehicle({
    required this.progress,
    required this.vehicle,
    required this.vehicleSize,
    required this.vehicleLeft,
    required this.vehicleTop,
    required this.isVehicleFacingLeft,
    required this.avatarMode,
    required this.avatarScale,
    required this.avatarOffsetX,
    required this.avatarOffsetY,
    required this.avatarRotationDegrees,
    required this.avatarImageBuilder,
    this.customAvatarImagePath,
  });

  final double progress;
  final VehicleDefinition vehicle;
  final double vehicleSize;
  final double vehicleLeft;
  final double vehicleTop;
  final bool isVehicleFacingLeft;
  final AvatarImageMode avatarMode;
  final String? customAvatarImagePath;
  final double avatarScale;
  final double avatarOffsetX;
  final double avatarOffsetY;
  final double avatarRotationDegrees;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
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
            avatarMode: avatarMode,
            customAvatarImagePath: customAvatarImagePath,
            avatarScale: avatarScale,
            avatarOffsetX: avatarOffsetX,
            avatarOffsetY: avatarOffsetY,
            avatarRotationDegrees: avatarRotationDegrees,
            avatarImageBuilder: avatarImageBuilder,
          ),
        ),
      ),
    );
  }
}

class _RoadMarker extends StatelessWidget {
  const _RoadMarker({
    required this.position,
    required this.icon,
    required this.isActive,
    required this.size,
    this.label,
  });

  final Offset position;
  final IconData icon;
  final bool isActive;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final markerColor = isActive
        ? AppColors.surfaceYellow.withValues(alpha: 0.92)
        : AppColors.white.withValues(alpha: 0.82);
    final iconColor = isActive ? AppColors.textStrong : AppColors.textPrimary;

    return Positioned(
      left: position.dx - (size / 2),
      top: position.dy - (size / 2),
      width: size,
      height: size,
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
            child: Icon(icon, color: iconColor, size: size * 0.56),
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
        padding: const EdgeInsets.all(AppSpacing.xs),
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
