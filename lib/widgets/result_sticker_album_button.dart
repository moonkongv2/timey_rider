import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class ResultStickerAlbumButton extends StatefulWidget {
  const ResultStickerAlbumButton({
    super.key,
    required this.collectedCount,
    required this.totalCount,
    required this.onPressed,
    this.badgeJustUpdated = false,
    this.buttonKey,
  });

  final int collectedCount;
  final int totalCount;
  final VoidCallback onPressed;
  final bool badgeJustUpdated;
  final GlobalKey? buttonKey;

  @override
  State<ResultStickerAlbumButton> createState() =>
      _ResultStickerAlbumButtonState();
}

class _ResultStickerAlbumButtonState extends State<ResultStickerAlbumButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 3),
    ]).animate(_bounceController);

    if (widget.badgeJustUpdated) {
      _bounceController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant ResultStickerAlbumButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.badgeJustUpdated && !oldWidget.badgeJustUpdated) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              key: widget.buttonKey,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.1),
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
                  '${widget.collectedCount}/${widget.totalCount}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textStrong,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
