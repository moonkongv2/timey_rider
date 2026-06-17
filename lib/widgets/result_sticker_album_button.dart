import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class ResultStickerAlbumButton extends StatelessWidget {
  const ResultStickerAlbumButton({
    super.key,
    required this.collectedCount,
    required this.totalCount,
    required this.onPressed,
    this.buttonKey,
  });

  final int collectedCount;
  final int totalCount;
  final VoidCallback onPressed;
  final GlobalKey? buttonKey;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            key: buttonKey,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.collections_bookmark_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceYellow,
                borderRadius: AppRadius.pill,
                border: Border.all(color: AppColors.white, width: 2),
              ),
              child: Text(
                '$collectedCount/$totalCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textStrong,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
