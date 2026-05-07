import 'package:flutter/material.dart';

import '../l10n/app_texts.dart';
import '../models/meal_progress_snapshot.dart';
import '../models/reward_item.dart';
import '../services/local_meal_progress_service.dart';
import '../widgets/reward_sticker_image.dart';

class StickerCollectionScreen extends StatelessWidget {
  const StickerCollectionScreen({super.key, required this.mealProgressService});

  final LocalMealProgressService mealProgressService;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(texts.rewards.collectionTitle)),
      body: SafeArea(
        child: FutureBuilder<MealProgressSnapshot>(
          future: mealProgressService.loadSnapshot(),
          builder: (context, snapshot) {
            final inventory = snapshot.data?.inventory ?? const [];

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
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
      color: _isCollected ? Colors.white : const Color(0xFFFFF8EF),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
            const SizedBox(height: 12),
            Text(
              _isCollected ? stickerName : texts.rewards.lockedSticker,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: _isCollected
                    ? const Color(0xFF3D332B)
                    : const Color(0xFF8D7B6A),
              ),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: _isCollected
                    ? const Color(0xFFFFF1B8)
                    : const Color(0xFFEDE3D8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  _isCollected
                      ? texts.rewards.stickerCount(count)
                      : texts.rewards.lockedStatus,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF5B4636),
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
