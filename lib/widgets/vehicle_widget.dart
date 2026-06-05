import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../models/vehicle_avatar_presentation.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'avatar/avatar_composite_preview.dart';

class VehicleWidget extends StatefulWidget {
  const VehicleWidget({
    super.key,
    required this.vehicle,
    this.size = 180,
    this.angle = 0,
    this.isFacingLeft = false,
    this.isArrived = false,
    this.avatar = VehicleAvatarPresentation.defaultImage,
    this.avatarImageBuilder,
  });

  final VehicleDefinition vehicle;
  final double size;
  final double angle;
  final bool isFacingLeft;
  final bool isArrived;
  final VehicleAvatarPresentation avatar;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;

  @override
  State<VehicleWidget> createState() => _VehicleWidgetState();
}

class _VehicleWidgetState extends State<VehicleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    if (!widget.isArrived) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VehicleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isArrived == oldWidget.isArrived) {
      return;
    }
    if (widget.isArrived) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
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
      builder: (context, child) {
        final bouncePhase = widget.isArrived
            ? 0.0
            : (math.sin(_controller.value * math.pi * 2) + 1) / 2;
        final bounceOffset = -bouncePhase * 5;
        final shadowScale = 1 - (bouncePhase * 0.14);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: widget.size * 0.11,
                child: Transform.scale(
                  scaleX: shadowScale,
                  child: Container(
                    width: widget.size * 0.56,
                    height: widget.size * 0.13,
                    decoration: BoxDecoration(
                      color: AppColors.brown700.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(widget.size),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brown700.withValues(alpha: 0.10),
                          blurRadius: widget.size * 0.08,
                          spreadRadius: widget.size * 0.01,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, bounceOffset),
                child: _VehicleImage(
                  vehicle: widget.vehicle,
                  size: widget.size,
                  isFacingLeft: widget.isFacingLeft,
                  avatar: widget.avatar,
                  avatarImageBuilder: widget.avatarImageBuilder,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VehicleImage extends StatelessWidget {
  const _VehicleImage({
    required this.vehicle,
    required this.size,
    required this.isFacingLeft,
    required this.avatar,
    this.avatarImageBuilder,
  });

  final VehicleDefinition vehicle;
  final double size;
  final bool isFacingLeft;
  final VehicleAvatarPresentation avatar;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;

  @override
  Widget build(BuildContext context) {
    if (avatar.isCustom) {
      return AvatarCompositePreview(
        vehicle: vehicle,
        avatar: avatar,
        size: size,
        isFacingLeft: isFacingLeft,
        avatarImageBuilder: avatarImageBuilder,
        vehicleFallbackBuilder: (context, vehicle, size) {
          return _VehicleFallback(vehicle: vehicle, size: size);
        },
      );
    }

    return Transform.flip(
      flipX: isFacingLeft,
      child: Image.asset(
        vehicle.assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _VehicleFallback(vehicle: vehicle, size: size);
        },
      ),
    );
  }
}

class _VehicleFallback extends StatelessWidget {
  const _VehicleFallback({required this.vehicle, required this.size});

  final VehicleDefinition vehicle;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Phase 3: normalize source vehicle asset canvas and visual scale.
    final padding = (size * 0.08)
        .clamp(AppSpacing.xs, AppSpacing.md)
        .toDouble();

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.78),
          borderRadius: AppRadius.pill,
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: AppShadows.surface,
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Text(
            vehicle.emoji,
            textScaler: TextScaler.noScaling,
            semanticsLabel: vehicle.labelKo,
            style: TextStyle(fontSize: size * 0.48, height: 1),
          ),
        ),
      ),
    );
  }
}
