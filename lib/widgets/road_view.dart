import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_texts.dart';
import '../models/activity_marker.dart';
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
    this.markers = const [],
    this.markerClearProgress,
    this.isRoadMotionActive = false,
    this.courseDuration = const Duration(minutes: 5),
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
  final List<ActivityMarkerDefinition> markers;
  final double? markerClearProgress;
  final bool isRoadMotionActive;
  final Duration courseDuration;
  static const double _portraitVehicleSize = 164;
  static const double _landscapeVehicleSize = 176;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        final geometry = createRoadCourseGeometry(
          viewportSize: viewportSize,
          duration: courseDuration,
        );
        final isLandscape = viewportSize.width > viewportSize.height;
        final vehicleSize = math
            .min(
              isLandscape ? _landscapeVehicleSize : _portraitVehicleSize,
              math.min(
                viewportSize.width * (isLandscape ? 0.24 : 0.38),
                viewportSize.height * (isLandscape ? 0.34 : 0.20),
              ),
            )
            .toDouble();
        const videoMargin = 16.0;
        final videoFrameWidth = isLandscape
            ? math
                  .min(viewportSize.width * 0.36, 460.0)
                  .clamp(320.0, viewportSize.width - (videoMargin * 2))
                  .toDouble()
            : math.max(0.0, viewportSize.width - (videoMargin * 2));
        final videoFrameHeight = isLandscape
            ? videoFrameWidth * 9 / 16
            : (videoFrameWidth * 0.62).clamp(
                132.0,
                math.max(140.0, viewportSize.height * 0.44),
              );
        final videoFrameLeft = isLandscape
            ? viewportSize.width - videoFrameWidth - videoMargin
            : videoMargin;
        final videoFrameTop = isLandscape
            ? viewportSize.height * 0.18
            : videoMargin;
        final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
        final cameraOffsetY = roadCameraOffsetForGeometryProgress(
          geometry: geometry,
          progress: clampedProgress,
        );
        final vehiclePlacement = _roadVehiclePlacementForGeometryProgress(
          geometry: geometry,
          progress: clampedProgress,
          vehicle: vehicle,
          vehicleSize: vehicleSize,
          cameraOffsetY: cameraOffsetY,
          isLandscape: isLandscape,
        );
        final clearProgress = (markerClearProgress ?? clampedProgress)
            .clamp(0.0, 1.0)
            .toDouble();
        final visualStyle = RoadCourseVisualStyle.forCourseKind(
          vehicle.courseKind,
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.hero,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: visualStyle.backgroundColors,
              stops: visualStyle.backgroundStops,
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
                Positioned(
                  left: 0,
                  top: -cameraOffsetY,
                  width: geometry.canvasSize.width,
                  height: geometry.canvasSize.height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _AnimatedRoadPaint(
                          progress: clampedProgress,
                          isMotionActive: isRoadMotionActive,
                          geometry: geometry,
                          courseKind: vehicle.courseKind,
                        ),
                      ),
                      if (markers.isNotEmpty)
                        _RoadMarkerLayer(
                          markers: markers,
                          clearProgress: clearProgress,
                          geometry: geometry,
                          markerSize: isLandscape ? 50 : 33,
                        ),
                      _RoadMarker(
                        position: roadPointForGeometryProgress(geometry, 0),
                        icon: Icons.home_rounded,
                        label: texts.common.start,
                        isActive: true,
                        size: isLandscape ? 42 : 36,
                      ),
                      _RoadMarker(
                        position: roadPointForGeometryProgress(geometry, 1),
                        icon: Icons.flag_rounded,
                        label: texts.common.complete,
                        isActive: clampedProgress >= 1,
                        size: isLandscape ? 42 : 36,
                      ),
                      if (showVehicle)
                        _PositionedRoadVehicle(
                          progress: clampedProgress,
                          vehicle: vehicle,
                          vehicleSize: vehicleSize,
                          vehicleLeft: vehiclePlacement.contentOffset.dx,
                          vehicleTop: vehiclePlacement.contentOffset.dy,
                          isVehicleFacingLeft:
                              vehiclePlacement.isVehicleFacingLeft,
                          avatar: avatar,
                          avatarImageBuilder: avatarImageBuilder,
                        ),
                    ],
                  ),
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

class _AnimatedRoadPaint extends StatefulWidget {
  const _AnimatedRoadPaint({
    required this.progress,
    required this.isMotionActive,
    required this.geometry,
    required this.courseKind,
  });

  final double progress;
  final bool isMotionActive;
  final RoadCourseGeometry geometry;
  final VehicleCourseKind courseKind;

  @override
  State<_AnimatedRoadPaint> createState() => _AnimatedRoadPaintState();
}

class _AnimatedRoadPaintState extends State<_AnimatedRoadPaint>
    with TickerProviderStateMixin {
  static const _fieldFootprintAssetPath =
      'assets/images/markers/footprints.png';

  late final AnimationController _flowController;
  late final AnimationController _skyPathCloudController;
  ui.Image? _fieldFootprintImage;
  var _fieldFootprintImageLoadId = 0;
  var _isLoadingFieldFootprintImage = false;

  bool get _disableAnimations =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  bool get _shouldAnimate => widget.isMotionActive && !_disableAnimations;

  bool get _shouldAnimateFlow =>
      _shouldAnimate && widget.courseKind != VehicleCourseKind.sky;

  bool get _shouldAnimateSkyPathClouds =>
      _shouldAnimate && widget.courseKind == VehicleCourseKind.sky;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: RoadPainter.flowAnimationDurationForCourseKind(
        widget.courseKind,
      ),
    );
    _skyPathCloudController = AnimationController(
      vsync: this,
      duration: RoadPainter.skyPathCloudAnimationDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveFieldFootprintImage();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant _AnimatedRoadPaint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseKind != widget.courseKind) {
      _flowController.duration = RoadPainter.flowAnimationDurationForCourseKind(
        widget.courseKind,
      );
      _resolveFieldFootprintImage();
    }
    if (oldWidget.isMotionActive != widget.isMotionActive ||
        oldWidget.courseKind != widget.courseKind) {
      _syncController();
    }
  }

  void _syncController() {
    if (_shouldAnimateFlow) {
      if (!_flowController.isAnimating) {
        _flowController.repeat();
      }
    } else {
      _flowController.stop();
    }

    if (_shouldAnimateSkyPathClouds) {
      if (!_skyPathCloudController.isAnimating) {
        _skyPathCloudController.repeat();
      }
    } else {
      _skyPathCloudController.stop();
    }
  }

  void _resolveFieldFootprintImage() {
    if (widget.courseKind != VehicleCourseKind.field) {
      _clearFieldFootprintImage();
      return;
    }

    if (_fieldFootprintImage != null || _isLoadingFieldFootprintImage) {
      return;
    }

    _loadFieldFootprintImage();
  }

  Future<void> _loadFieldFootprintImage() async {
    _isLoadingFieldFootprintImage = true;
    final loadId = _fieldFootprintImageLoadId + 1;
    _fieldFootprintImageLoadId = loadId;

    try {
      final data = await rootBundle.load(_fieldFootprintAssetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      codec.dispose();

      if (!mounted ||
          loadId != _fieldFootprintImageLoadId ||
          widget.courseKind != VehicleCourseKind.field) {
        frame.image.dispose();
        return;
      }

      setState(() {
        _fieldFootprintImage?.dispose();
        _fieldFootprintImage = frame.image;
      });
    } catch (_) {
      // Keep the vector footprint fallback if the optional image cannot load.
    } finally {
      if (mounted && loadId == _fieldFootprintImageLoadId) {
        _isLoadingFieldFootprintImage = false;
      }
    }
  }

  void _clearFieldFootprintImage() {
    _fieldFootprintImageLoadId += 1;
    _isLoadingFieldFootprintImage = false;
    _fieldFootprintImage?.dispose();
    _fieldFootprintImage = null;
  }

  @override
  void dispose() {
    _clearFieldFootprintImage();
    _flowController.dispose();
    _skyPathCloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldAnimate) {
      return CustomPaint(
        painter: RoadPainter(
          progress: widget.progress,
          geometry: widget.geometry,
          courseKind: widget.courseKind,
          fieldFootprintImage: _fieldFootprintImage,
        ),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_flowController, _skyPathCloudController]),
      builder: (context, child) {
        return CustomPaint(
          painter: RoadPainter(
            progress: widget.progress,
            laneDashPhase:
                _flowController.value *
                RoadPainter.flowPatternLengthForCourseKind(widget.courseKind),
            skyPathCloudPhase:
                _skyPathCloudController.value * RoadPainter.skyPathCloudGap,
            geometry: widget.geometry,
            courseKind: widget.courseKind,
            fieldFootprintImage: _fieldFootprintImage,
          ),
        );
      },
    );
  }
}

class _RoadMarkerLayer extends StatelessWidget {
  const _RoadMarkerLayer({
    required this.markers,
    required this.clearProgress,
    required this.geometry,
    required this.markerSize,
  });

  final List<ActivityMarkerDefinition> markers;
  final double clearProgress;
  final RoadCourseGeometry geometry;
  final double markerSize;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (var index = 0; index < markers.length; index += 1)
            _RoadActivityMarker(
              key: ValueKey('roadActivityMarkerSlot_$index'),
              marker: markers[index],
              index: index,
              markerSize: markerSize,
              progress: (index + 1) / (markers.length + 1),
              clearProgress: clearProgress,
              geometry: geometry,
            ),
        ],
      ),
    );
  }
}

class _RoadActivityMarker extends StatelessWidget {
  const _RoadActivityMarker({
    super.key,
    required this.marker,
    required this.index,
    required this.markerSize,
    required this.progress,
    required this.clearProgress,
    required this.geometry,
  });

  final ActivityMarkerDefinition marker;
  final int index;
  final double markerSize;
  final double progress;
  final double clearProgress;
  final RoadCourseGeometry geometry;

  @override
  Widget build(BuildContext context) {
    final position = roadPointForGeometryProgress(geometry, progress);
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
            ? SizedBox(key: ValueKey('roadActivityMarkerCleared_$index'))
            : _RoadMarkerChip(
                key: ValueKey('roadActivityMarker_$index'),
                marker: marker,
                size: markerSize,
              ),
      ),
    );
  }
}

class _RoadMarkerChip extends StatelessWidget {
  const _RoadMarkerChip({super.key, required this.marker, required this.size});

  final ActivityMarkerDefinition marker;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath = marker.assetPath;

    return SizedBox.expand(
      child: Center(
        child: assetPath == null
            ? _MarkerEmoji(marker: marker, size: size)
            : Image.asset(
                assetPath,
                width: size * 0.92,
                height: size * 0.92,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _MarkerEmoji(marker: marker, size: size);
                },
              ),
      ),
    );
  }
}

class _MarkerEmoji extends StatelessWidget {
  const _MarkerEmoji({required this.marker, required this.size});

  final ActivityMarkerDefinition marker;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      marker.emoji,
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
    this.reservedRightInset = 0,
    this.onFinished,
  });

  final String assetPath;
  final int milestone;
  final double reservedRightInset;
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
          final videoFrameRightInset = isLandscape
              ? videoMargin + reservedRightInset
              : videoMargin;
          final videoFrameLeft = isLandscape
              ? size.width - videoFrameWidth - videoFrameRightInset
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
    this.courseDuration = const Duration(minutes: 5),
  });

  final double progress;
  final VehicleDefinition vehicle;
  final VehicleAvatarPresentation avatar;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;
  final Duration courseDuration;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = Size(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final geometry = createRoadCourseGeometry(
            viewportSize: viewportSize,
            duration: courseDuration,
          );
          final isLandscape = viewportSize.width > viewportSize.height;
          final vehicleSize = math
              .min(
                isLandscape
                    ? RoadView._landscapeVehicleSize
                    : RoadView._portraitVehicleSize,
                math.min(
                  viewportSize.width * (isLandscape ? 0.24 : 0.38),
                  viewportSize.height * (isLandscape ? 0.34 : 0.20),
                ),
              )
              .toDouble();
          final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
          final cameraOffsetY = roadCameraOffsetForGeometryProgress(
            geometry: geometry,
            progress: clampedProgress,
          );
          final vehiclePlacement = _roadVehiclePlacementForGeometryProgress(
            geometry: geometry,
            progress: clampedProgress,
            vehicle: vehicle,
            vehicleSize: vehicleSize,
            cameraOffsetY: cameraOffsetY,
            isLandscape: isLandscape,
          );

          return Stack(
            children: [
              _PositionedRoadVehicle(
                progress: clampedProgress,
                vehicle: vehicle,
                vehicleSize: vehicleSize,
                vehicleLeft: vehiclePlacement.viewportOffset.dx,
                vehicleTop: vehiclePlacement.viewportOffset.dy,
                isVehicleFacingLeft: vehiclePlacement.isVehicleFacingLeft,
                avatar: avatar,
                avatarImageBuilder: avatarImageBuilder,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoadVehiclePlacement {
  const _RoadVehiclePlacement({
    required this.contentOffset,
    required this.viewportOffset,
    required this.isVehicleFacingLeft,
  });

  final Offset contentOffset;
  final Offset viewportOffset;
  final bool isVehicleFacingLeft;
}

_RoadVehiclePlacement _roadVehiclePlacementForGeometryProgress({
  required RoadCourseGeometry geometry,
  required double progress,
  required VehicleDefinition vehicle,
  required double vehicleSize,
  required double cameraOffsetY,
  required bool isLandscape,
}) {
  final isVehicleFacingLeft = roadIsFacingLeftForGeometryProgress(
    geometry,
    progress,
  );
  final roadPosition = roadPointForGeometryProgress(geometry, progress);
  final viewportRoadPosition = roadPosition - Offset(0, cameraOffsetY);
  final vehiclePosition =
      viewportRoadPosition +
      _vehicleRoadAnchorOffset(
        vehicle: vehicle,
        vehicleSize: vehicleSize,
        isLandscape: isLandscape,
        isFacingLeft: isVehicleFacingLeft,
      );
  final viewportOffset = _boundedVehicleOffset(
    size: geometry.viewportSize,
    position: vehiclePosition,
    vehicleSize: vehicleSize,
  );

  return _RoadVehiclePlacement(
    contentOffset: viewportOffset + Offset(0, cameraOffsetY),
    viewportOffset: viewportOffset,
    isVehicleFacingLeft: isVehicleFacingLeft,
  );
}

Offset _vehicleRoadAnchorOffset({
  required VehicleDefinition vehicle,
  required double vehicleSize,
  required bool isLandscape,
  required bool isFacingLeft,
}) {
  final anchorOffset = vehicle.roadAnchorOffset;
  final dxRatio = isLandscape
      ? anchorOffset.landscapeDxRatio
      : anchorOffset.portraitDxRatio;
  final dyRatio = isLandscape
      ? anchorOffset.landscapeDyRatio
      : anchorOffset.portraitDyRatio;
  final facingAdjustedDxRatio = isFacingLeft ? -dxRatio : dxRatio;

  return Offset(vehicleSize * facingAdjustedDxRatio, vehicleSize * dyRatio);
}

Offset _boundedVehicleOffset({
  required Size size,
  required Offset position,
  required double vehicleSize,
}) {
  return Offset(
    _boundedVehicleAxis(
      position.dx - (vehicleSize / 2),
      size.width,
      vehicleSize,
    ),
    _boundedVehicleAxis(
      position.dy - (vehicleSize / 2),
      size.height,
      vehicleSize,
    ),
  );
}

double _boundedVehicleAxis(double value, double extent, double vehicleSize) {
  const margin = 6.0;
  final minValue = math.min(margin, math.max(0.0, extent - vehicleSize));
  final maxValue = extent - vehicleSize - margin;
  if (maxValue < minValue) {
    return (extent - vehicleSize) / 2;
  }
  return value.clamp(minValue, maxValue).toDouble();
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

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: vehicleLeft,
      top: vehicleTop,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 260),
        opacity: progress >= 1 ? 0.78 : 1,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 260),
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
