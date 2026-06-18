import 'package:flutter/material.dart';

import '../l10n/app_texts.dart';
import '../models/activity_progress_snapshot.dart';
import '../models/reward_item.dart';
import '../services/local_activity_progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/reward_sticker_image.dart';

class StickerCollectionScreen extends StatelessWidget {
  const StickerCollectionScreen({
    super.key,
    required this.activityProgressService,
  });

  final LocalActivityProgressService activityProgressService;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(texts.rewards.collectionTitle)),
      body: SafeArea(
        child: FutureBuilder<ActivityProgressSnapshot>(
          future: activityProgressService.loadSnapshot(),
          builder: (context, snapshot) {
            final inventory = snapshot.data?.inventory ?? const [];

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.88,
              ),
              itemCount: RewardCatalog.all.length,
              itemBuilder: (context, index) {
                final sticker = RewardCatalog.all[index];
                final item = _inventoryItemFor(inventory, sticker.id);

                return _StickerCard(sticker: sticker, count: item?.count ?? 0);
              },
            );
          },
        ),
      ),
    );
  }

  RewardInventoryItem? _inventoryItemFor(
    List<RewardInventoryItem> inventory,
    String rewardId,
  ) {
    for (final item in inventory) {
      if (item.rewardId == rewardId) {
        return item;
      }
    }
    return null;
  }
}

class _StickerCard extends StatelessWidget {
  const _StickerCard({required this.sticker, required this.count});

  final RewardDefinition sticker;
  final int count;

  bool get _isCollected => count > 0;

  Widget _buildStickerStack(String semanticLabel) {
    final stickerImage = RewardStickerImage(
      reward: sticker,
      semanticLabel: semanticLabel,
      size: 85,
      locked: !_isCollected,
    );

    if (count <= 1) {
      return stickerImage;
    }

    return SizedBox(
      width: 85,
      height: 85,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (count >= 5)
            Positioned(
              left: -12,
              top: 4,
              child: Transform.rotate(
                angle: -0.25,
                child: Opacity(
                  opacity: 0.6,
                  child: stickerImage,
                ),
              ),
            ),
          if (count >= 2)
            Positioned(
              right: -10,
              top: -6,
              child: Transform.rotate(
                angle: 0.18,
                child: Opacity(
                  opacity: 0.8,
                  child: stickerImage,
                ),
              ),
            ),
          stickerImage,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context);
    final stickerName = sticker.labelForLanguage(
      Localizations.localeOf(context).languageCode,
    );

    return Card(
      color: _isCollected ? AppColors.white : AppColors.cream,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStickerStack(
              _isCollected
                  ? stickerName
                  : texts.rewards.uncollectedSemanticLabel,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _isCollected ? stickerName : texts.rewards.lockedSticker,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: _isCollected
                    ? AppColors.textStrong
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: _isCollected
                    ? AppColors.surfaceYellow
                    : AppColors.borderSoft,
                borderRadius: AppRadius.pill,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  _isCollected
                      ? texts.rewards.stickerCount(count)
                      : texts.rewards.lockedStatus,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
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
