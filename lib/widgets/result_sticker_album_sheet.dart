import 'package:flutter/material.dart';

import '../catalogs/vehicle_catalog.dart';
import '../l10n/app_texts.dart';
import '../models/reward_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'reward_sticker_image.dart';
import 'sticker_fountain_animation.dart';

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
        return LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final maxContentWidth = isLandscape
                ? (constraints.maxWidth >= 1000 ? 840.0 : 720.0)
                : constraints.maxWidth;
            final contentWidth = constraints.maxWidth
                .clamp(0.0, maxContentWidth)
                .toDouble();
            final crossAxisCount = isLandscape ? 3 : 2;
            final childAspectRatio = isLandscape ? 0.92 : 0.78;

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
                SizedBox(
                  width: contentWidth,
                  child: Text(
                    texts.rewards.collectionTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.md,
                          AppSpacing.xl,
                          AppSpacing.xxl,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: VehicleCatalog.all.length,
                        itemBuilder: (context, index) {
                          final vehicle = VehicleCatalog.all[index];
                          final sticker =
                              RewardCatalog.findVehicleStickerByVehicleId(
                                vehicle.id,
                              )!;
                          final item = _inventoryItemFor(sticker.id);

                          return _AlbumStickerCard(
                            sticker: sticker,
                            count: item?.count ?? 0,
                            compact: isLandscape,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AlbumStickerCard extends StatelessWidget {
  const _AlbumStickerCard({
    required this.sticker,
    required this.count,
    required this.compact,
  });

  final RewardDefinition sticker;
  final int count;
  final bool compact;

  bool get _isCollected => count > 0;

  double _compactStickerSizeFor(
    BoxConstraints constraints,
    double cardPadding,
  ) {
    final widthSpace = constraints.maxWidth.isFinite
        ? constraints.maxWidth - cardPadding * 2
        : 85.0;
    final heightSpace = constraints.maxHeight.isFinite
        ? constraints.maxHeight -
              cardPadding * 2 -
              AppSpacing.sm -
              AppSpacing.xs -
              64
        : 85.0;
    final targetByWidth = widthSpace * 0.56;
    final target = targetByWidth < heightSpace ? targetByWidth : heightSpace;
    return target.clamp(72.0, 96.0).toDouble();
  }

  Widget _buildStickerStack(String semanticLabel, double size) {
    final stickerImage = RewardStickerImage(
      reward: sticker,
      semanticLabel: semanticLabel,
      size: size,
      locked: !_isCollected,
    );

    if (count <= 1) {
      return stickerImage;
    }

    final offsetScale = size / 85;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (count >= 5)
            Positioned(
              left: -12 * offsetScale,
              top: 4 * offsetScale,
              child: Transform.rotate(
                angle: -0.25,
                child: Opacity(opacity: 0.6, child: stickerImage),
              ),
            ),
          if (count >= 2)
            Positioned(
              right: -10 * offsetScale,
              top: -6 * offsetScale,
              child: Transform.rotate(
                angle: 0.18,
                child: Opacity(opacity: 0.8, child: stickerImage),
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

    return GestureDetector(
      onTapUp: _isCollected
          ? (details) {
              showStickerFountain(
                context: context,
                reward: sticker,
                count: count,
                position: details.globalPosition,
              );
            }
          : null,
      child: Card(
        color: _isCollected ? AppColors.white : AppColors.cream,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardPadding = compact ? AppSpacing.md : AppSpacing.lg;
            final stickerSize = compact
                ? _compactStickerSizeFor(constraints, cardPadding)
                : 85.0;
            final stickerGap = compact ? AppSpacing.sm : AppSpacing.md;
            final statusGap = compact ? AppSpacing.xs : AppSpacing.sm;

            return Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStickerStack(
                    _isCollected
                        ? stickerName
                        : texts.rewards.uncollectedSemanticLabel,
                    stickerSize,
                  ),
                  SizedBox(height: stickerGap),
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
                  SizedBox(height: statusGap),
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
            );
          },
        ),
      ),
    );
  }
}
