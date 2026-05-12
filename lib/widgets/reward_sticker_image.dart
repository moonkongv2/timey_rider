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
    final image = Image.asset(
      reward.imageAssetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel ?? reward.id,
      errorBuilder: (_, _, _) =>
          _FallbackStickerIcon(reward: reward, size: size, locked: locked),
    );

    if (!locked) {
      return image;
    }

    return Opacity(
      opacity: 0.34,
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(
          AppColors.textSecondary,
          BlendMode.srcIn,
        ),
        child: image,
      ),
    );
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
