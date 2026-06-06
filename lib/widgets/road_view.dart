import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_texts.dart';
import '../models/meal_ingredient.dart';
import '../models/vehicle.dart';
import '../models/vehicle_avatar_presentation.dart';
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
    this.avatar = VehicleAvatarPresentation.defaultImage,
    this.avatarImageBuilder,
    this.motivationVideoAssetPath,
    this.motivationVideoMilestone,
    this.onMotivationVideoFinished,
    this.showVehicle = true,
    this.showMotivationVideo = true,
    this.ingredients = const [],
    this.ingredientClearProgress,
    this.vehicleMoveDuration = const Duration(milliseconds: 850),
  });

  final double progress;
  final VehicleDefinition vehicle;
  final VehicleAvatarPresentation avatar;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;
  final String? motivationVideoAssetPath;
  final int? motivationVideoMilestone;
  final VoidCallback? onMotivationVideoFinished;
  final bool showVehicle;
  final bool showMotivationVideo;
  final List<MealIngredientDefinition> ingredients;
  final double? ingredientClearProgress;
  final Duration vehicleMoveDuration;
  static const double _portraitVehicleSize = 164;
  static const double _landscapeVehicleSize = 176;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final isLandscape = size.width > size.height;
        final vehicleSize = math
            .min(
              isLandscape ? _landscapeVehicleSize : _portraitVehicleSize,
              math.min(
                size.width * (isLandscape ? 0.24 : 0.38),
                size.height * (isLandscape ? 0.34 : 0.24),
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
        final clearProgress = (ingredientClearProgress ?? progress)
            .clamp(0.0, 1.0)
            .toDouble();
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
                AppColors.white.withValues(alpha: 0.96),
                AppColors.surfaceWarm,
                AppColors.surfaceBlue.withValues(alpha: 0.18),
                AppColors.cream.withValues(alpha: 0.92),
              ],
              stops: const [0, 0.5, 0.78, 1],
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
                if (ingredients.isNotEmpty)
                  _RoadIngredientLayer(
                    ingredients: ingredients,
                    clearProgress: clearProgress,
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
                    avatar: avatar,
                    avatarImageBuilder: avatarImageBuilder,
                    moveDuration: vehicleMoveDuration,
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

class _RoadIngredientLayer extends StatelessWidget {
  const _RoadIngredientLayer({
    required this.ingredients,
    required this.clearProgress,
  });

  final List<MealIngredientDefinition> ingredients;
  final double clearProgress;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final isLandscape = size.width > size.height;
          final markerSize = isLandscape ? 36.0 : 34.0;

          return Stack(
            children: [
              for (var index = 0; index < ingredients.length; index += 1)
                _RoadIngredientMarker(
                  key: ValueKey('roadIngredientSlot_$index'),
                  ingredient: ingredients[index],
                  index: index,
                  markerSize: markerSize,
                  progress: (index + 1) / (ingredients.length + 1),
                  clearProgress: clearProgress,
                  roadSize: size,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RoadIngredientMarker extends StatelessWidget {
  const _RoadIngredientMarker({
    super.key,
    required this.ingredient,
    required this.index,
    required this.markerSize,
    required this.progress,
    required this.clearProgress,
    required this.roadSize,
  });

  final MealIngredientDefinition ingredient;
  final int index;
  final double markerSize;
  final double progress;
  final double clearProgress;
  final Size roadSize;

  @override
  Widget build(BuildContext context) {
    final position = roadPointForProgress(roadSize, progress);
    final isCleared = clearProgress >= progress;

    return Positioned(
      left: position.dx - (markerSize / 2),
      top: position.dy - (markerSize / 2),
      width: markerSize,
      height: markerSize,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 380),
        reverseDuration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: isCleared
            ? SizedBox(key: ValueKey('roadIngredientCleared_$index'))
            : _RoadIngredientChip(
                key: ValueKey('roadIngredientMarker_$index'),
                ingredient: ingredient,
                size: markerSize,
              ),
      ),
    );
  }
}

class _RoadIngredientChip extends StatelessWidget {
  const _RoadIngredientChip({
    super.key,
    required this.ingredient,
    required this.size,
  });

  final MealIngredientDefinition ingredient;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath = ingredient.assetPath;

    return SizedBox.expand(
      child: Center(
        child: assetPath == null
            ? _IngredientEmoji(ingredient: ingredient, size: size)
            : Image.asset(
                assetPath,
                width: size * 0.92,
                height: size * 0.92,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _IngredientEmoji(ingredient: ingredient, size: size);
                },
              ),
      ),
    );
  }
}

class _IngredientEmoji extends StatelessWidget {
  const _IngredientEmoji({required this.ingredient, required this.size});

  final MealIngredientDefinition ingredient;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      ingredient.emoji,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: size * 0.86, height: 1),
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
    this.avatar = VehicleAvatarPresentation.defaultImage,
    this.avatarImageBuilder,
    this.vehicleMoveDuration = const Duration(milliseconds: 850),
  });

  final double progress;
  final VehicleDefinition vehicle;
  final VehicleAvatarPresentation avatar;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;
  final Duration vehicleMoveDuration;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final isLandscape = size.width > size.height;
          final vehicleSize = math
              .min(
                isLandscape
                    ? RoadView._landscapeVehicleSize
                    : RoadView._portraitVehicleSize,
                math.min(
                  size.width * (isLandscape ? 0.24 : 0.38),
                  size.height * (isLandscape ? 0.34 : 0.24),
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
                avatar: avatar,
                avatarImageBuilder: avatarImageBuilder,
                moveDuration: vehicleMoveDuration,
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
    required this.avatar,
    required this.avatarImageBuilder,
    required this.moveDuration,
  });

  final double progress;
  final VehicleDefinition vehicle;
  final double vehicleSize;
  final double vehicleLeft;
  final double vehicleTop;
  final bool isVehicleFacingLeft;
  final VehicleAvatarPresentation avatar;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;
  final Duration moveDuration;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: moveDuration,
      curve: Curves.easeInOutCubic,
      left: vehicleLeft,
      top: vehicleTop,
      child: AnimatedOpacity(
        duration: moveDuration,
        opacity: progress >= 1 ? 0.78 : 1,
        child: AnimatedScale(
          duration: moveDuration,
          curve: Curves.easeInOutCubic,
          scale: progress >= 1 ? 0.92 : 1,
          child: VehicleWidget(
            vehicle: vehicle,
            size: vehicleSize,
            isFacingLeft: isVehicleFacingLeft,
            isArrived: progress >= 1,
            avatar: avatar,
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
  static const _initialFallbackDuration = Duration(seconds: 6);

  late final VideoPlayerController _controller;
  Timer? _fallbackTimer;
  Timer? _completionPollTimer;
  bool _isReady = false;
  bool _didFinish = false;

  @override
  void initState() {
    super.initState();
    _fallbackTimer = Timer(_initialFallbackDuration, _finish);
    _controller = VideoPlayerController.asset(
      widget.assetPath,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller.addListener(_handleVideoChanged);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(false);
      await _controller.setVolume(0);
      if (_didFinish) {
        return;
      }
      await _controller.play();
      _fallbackTimer?.cancel();
      _fallbackTimer = Timer(
        _controller.value.duration + const Duration(milliseconds: 900),
        _finish,
      );
      _completionPollTimer = Timer.periodic(
        const Duration(milliseconds: 200),
        (_) => _handleVideoChanged(),
      );
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

    final remaining = value.duration - value.position;
    final isNearEnd = remaining <= const Duration(milliseconds: 250);
    final isStoppedNearEnd =
        !value.isPlaying &&
        value.position > Duration.zero &&
        remaining <= const Duration(milliseconds: 600);

    if (value.isCompleted ||
        value.position >= value.duration ||
        isNearEnd ||
        isStoppedNearEnd) {
      _finish();
    }
  }

  void _finish() {
    if (_didFinish || !mounted) {
      return;
    }
    _didFinish = true;
    _fallbackTimer?.cancel();
    _completionPollTimer?.cancel();
    Future<void>.microtask(() {
      if (mounted) {
        widget.onFinished?.call();
      }
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _completionPollTimer?.cancel();
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
