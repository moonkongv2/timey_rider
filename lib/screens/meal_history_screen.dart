import 'package:flutter/material.dart';

import '../l10n/app_texts.dart';
import '../models/meal_history_entry.dart';
import '../models/meal_progress_snapshot.dart';
import '../models/reward_item.dart';
import '../services/local_meal_progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/duration_format.dart';
import '../widgets/reward_sticker_image.dart';

class MealHistoryScreen extends StatelessWidget {
  const MealHistoryScreen({super.key, required this.mealProgressService});

  final LocalMealProgressService mealProgressService;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(texts.mealHistory.title)),
      body: SafeArea(
        child: FutureBuilder<MealProgressSnapshot>(
          future: mealProgressService.loadSnapshot(),
          builder: (context, snapshot) {
            final history = snapshot.data?.history ?? const [];
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (history.isEmpty) {
              return const _MealHistoryEmptyState();
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                return _MealHistoryCard(entry: history[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _MealHistoryEmptyState extends StatelessWidget {
  const _MealHistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context).mealHistory;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.restaurant_menu_rounded,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              texts.emptyTitle,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.textStrong,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              texts.emptyBody,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.34,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealHistoryCard extends StatelessWidget {
  const _MealHistoryCard({required this.entry});

  final MealHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context);
    final historyTexts = texts.mealHistory;

    return Card(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    historyTexts.dateLabel(entry.endedAt),
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatusChip(
                  label: historyTexts.completedStatus(
                    entry.completedBeforeArrival,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _DurationTile(
                    label: historyTexts.targetTimeLabel,
                    value: formatDuration(entry.targetDuration),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _DurationTile(
                    label: historyTexts.actualTimeLabel,
                    value: formatDuration(entry.actualDuration),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              historyTexts.rewardLabel,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _RewardRow(rewardIds: entry.rewardIds),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceYellow,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textStrong,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  const _DurationTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: AppRadius.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.textStrong,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.rewardIds});

  final List<String> rewardIds;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final rewards = rewardIds
        .map(RewardCatalog.findById)
        .whereType<RewardDefinition>()
        .toList(growable: false);

    if (rewards.isEmpty) {
      return Text(
        texts.mealHistory.noRewardLabel,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final reward in rewards)
          _RewardPill(reward: reward, label: texts.rewards.name(reward.id)),
      ],
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.reward, required this.label});

  final RewardDefinition reward;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RewardStickerImage(reward: reward, semanticLabel: label, size: 28),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textStrong,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
