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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context);
    final stickerName = texts.rewards.name(sticker.id);

    return Card(
      color: _isCollected ? AppColors.white : AppColors.cream,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RewardStickerImage(
              reward: sticker,
              semanticLabel: _isCollected
                  ? stickerName
                  : texts.rewards.uncollectedSemanticLabel,
              size: 72,
              locked: !_isCollected,
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
