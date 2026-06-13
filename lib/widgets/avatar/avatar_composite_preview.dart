import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/activity_timer_config.dart';
import '../../models/vehicle.dart';
import '../../models/vehicle_avatar_presentation.dart';

class AvatarCompositePreview extends StatelessWidget {
  const AvatarCompositePreview({
    super.key,
    required this.vehicle,
    required this.avatar,
    required this.size,
    this.isFacingLeft = false,
    this.avatarImageBuilder,
    this.vehicleFallbackBuilder,
  });

  final VehicleDefinition vehicle;
  final VehicleAvatarPresentation avatar;
  final double size;
  final bool isFacingLeft;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;
  final Widget Function(
    BuildContext context,
    VehicleDefinition vehicle,
    double size,
  )?
  vehicleFallbackBuilder;

  AvatarImageMode get avatarMode => avatar.mode;

  String? get customAvatarImagePath => avatar.imagePath;

  double get avatarScale => avatar.scale;

  double get avatarOffsetX => avatar.offsetX;

  double get avatarOffsetY => avatar.offsetY;

  double get avatarRotationDegrees => avatar.rotationDegrees;

  @override
  Widget build(BuildContext context) {
    final avatarSlot = vehicle.avatarSlot;
    final avatarPath = avatar.imagePath;
    final shouldShowAvatar =
        avatar.mode == AvatarImageMode.custom &&
        avatarSlot != null &&
        avatarPath != null &&
        avatarPath.trim().isNotEmpty &&
        File(avatarPath).existsSync();

    return SizedBox(
      width: size,
      height: size,
      child: Transform.flip(
        flipX: isFacingLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Image.asset(
                vehicle.assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return vehicleFallbackBuilder?.call(context, vehicle, size) ??
                      Center(
                        child: Text(
                          vehicle.emoji,
                          textScaler: TextScaler.noScaling,
                          semanticsLabel: vehicle.labelKo,
                          style: TextStyle(fontSize: size * 0.48, height: 1),
                        ),
                      );
                },
              ),
            ),
            if (shouldShowAvatar)
              _AvatarOverlay(
                imagePath: avatarPath,
                size: size,
                slot: avatarSlot,
                avatarScale: avatar.scale,
                avatarOffsetX: avatar.offsetX,
                avatarOffsetY: avatar.offsetY,
                avatarRotationDegrees: avatar.rotationDegrees,
                avatarImageBuilder: avatarImageBuilder,
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarOverlay extends StatelessWidget {
  const _AvatarOverlay({
    required this.imagePath,
    required this.size,
    required this.slot,
    required this.avatarScale,
    required this.avatarOffsetX,
    required this.avatarOffsetY,
    required this.avatarRotationDegrees,
    this.avatarImageBuilder,
  });

  final String imagePath;
  final double size;
  final VehicleAvatarSlot slot;
  final double avatarScale;
  final double avatarOffsetX;
  final double avatarOffsetY;
  final double avatarRotationDegrees;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;

  @override
  Widget build(BuildContext context) {
    final avatarSize = size * slot.sizeRatio * avatarScale;
    final centerX = size * slot.centerX + avatarOffsetX * size;
    final centerY = size * slot.centerY + avatarOffsetY * size;
    final rotation =
        (slot.rotationDegrees + avatarRotationDegrees) * math.pi / 180;

    return Positioned(
      left: centerX - (avatarSize / 2),
      top: centerY - (avatarSize / 2),
      width: avatarSize,
      height: avatarSize,
      child: Transform.rotate(
        angle: rotation,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: size * 0.018,
                offset: Offset(0, size * 0.006),
              ),
            ],
          ),
          child: ClipOval(
            child:
                avatarImageBuilder?.call(context, imagePath) ??
                Image.file(
                  File(imagePath),
                  key: const ValueKey('avatarCompositeOverlayImage'),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
          ),
        ),
      ),
    );
  }
}
