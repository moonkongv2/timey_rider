import 'package:flutter/material.dart';

import '../models/reward_item.dart';
import '../theme/app_colors.dart';

class RewardStickerImage extends StatelessWidget {
  const RewardStickerImage({
    super.key,
    required this.reward,
    this.semanticLabel,
    this.size = 88,
    this.locked = false,
  });

  final RewardDefinition reward;
  final String? semanticLabel;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final padding = (size * 0.12).clamp(2.0, 10.0).toDouble();
    final radius = (size * 0.22).clamp(6.0, 18.0).toDouble();
    final borderWidth = size < 36 ? 0.8 : 1.2;
    final shadowBlur = (size * 0.10).clamp(0.0, 8.0).toDouble();
    final shadowOffset = size < 36 ? 1.0 : 2.0;
    final imageSize = (size - padding * 2).clamp(0.0, size).toDouble();

    final stickerContent = Image.asset(
      reward.imageAssetPath,
      width: imageSize,
      height: imageSize,
      fit: BoxFit.contain,
      color: locked ? AppColors.textMuted.withValues(alpha: 0.82) : null,
      colorBlendMode: locked ? BlendMode.srcIn : null,
      semanticLabel: semanticLabel ?? reward.id,
      errorBuilder: (_, _, _) =>
          _FallbackStickerIcon(reward: reward, size: imageSize, locked: locked),
    );

    final framedSticker = SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: locked ? AppColors.cream : AppColors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: locked
                ? AppColors.borderWarm.withValues(alpha: 0.56)
                : AppColors.borderWarm,
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textStrong.withValues(
                alpha: locked ? 0.04 : 0.10,
              ),
              blurRadius: shadowBlur,
              offset: Offset(0, shadowOffset),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Center(child: stickerContent),
        ),
      ),
    );

    if (!locked) {
      return framedSticker;
    }

    return Opacity(opacity: 0.72, child: framedSticker);
  }
}

class _FallbackStickerIcon extends StatelessWidget {
  const _FallbackStickerIcon({
    required this.reward,
    required this.size,
    required this.locked,
  });

  final RewardDefinition reward;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: Text(
          locked ? '?' : reward.emoji,
          style: TextStyle(
            fontSize: size * 0.56,
            color: locked ? AppColors.textMuted : null,
          ),
        ),
      ),
    );
  }
}
