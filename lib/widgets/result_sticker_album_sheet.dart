import 'package:flutter/material.dart';

import '../catalogs/vehicle_catalog.dart';
import '../l10n/app_texts.dart';
import '../models/reward_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'reward_sticker_image.dart';

void showResultStickerAlbumSheet(
  BuildContext context, {
  required List<RewardInventoryItem> inventory,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _ResultStickerAlbumSheet(inventory: inventory),
  );
}

class _ResultStickerAlbumSheet extends StatelessWidget {
  const _ResultStickerAlbumSheet({required this.inventory});

  final List<RewardInventoryItem> inventory;

  RewardInventoryItem? _inventoryItemFor(String rewardId) {
    for (final item in inventory) {
      if (item.rewardId == rewardId) {
        return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: AppRadius.pill,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              texts.rewards.collectionTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
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
                itemCount: VehicleCatalog.all.length,
                itemBuilder: (context, index) {
                  final vehicle = VehicleCatalog.all[index];
                  final sticker = RewardCatalog.findVehicleStickerByVehicleId(
                    vehicle.id,
                  )!;
                  final item = _inventoryItemFor(sticker.id);

                  return _AlbumStickerCard(
                    sticker: sticker,
                    count: item?.count ?? 0,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AlbumStickerCard extends StatelessWidget {
  const _AlbumStickerCard({required this.sticker, required this.count});

  final RewardDefinition sticker;
  final int count;

  bool get _isCollected => count > 0;

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
            RewardStickerImage(
              reward: sticker,
              semanticLabel: _isCollected
                  ? stickerName
                  : texts.rewards.uncollectedSemanticLabel,
              size: 85,
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
