import 'package:flutter/material.dart';

import '../catalogs/meal_ingredient_catalog.dart';
import '../l10n/app_texts.dart';
import '../models/meal_ingredient.dart';
import '../models/meal_history_entry.dart';
import '../models/meal_progress_snapshot.dart';
import '../models/reward_item.dart';
import '../services/local_meal_progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/duration_format.dart';
import '../widgets/reward_sticker_image.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key, required this.mealProgressService});

  final LocalMealProgressService mealProgressService;

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  late Future<MealProgressSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = widget.mealProgressService.loadSnapshot();
  }

  void _reloadSnapshot() {
    setState(() {
      _snapshotFuture = widget.mealProgressService.loadSnapshot();
    });
  }

  Future<void> _confirmDeleteMealHistoryEntry(MealHistoryEntry entry) async {
    final texts = AppTexts.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(texts.mealHistory.deleteRecordDialogTitle),
          content: Text(texts.mealHistory.deleteRecordDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(texts.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(texts.mealHistory.deleteRecordConfirmLabel),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true) {
      return;
    }

    final deleted = await widget.mealProgressService.deleteMealHistoryEntry(
      entry.id,
    );
    if (!mounted) {
      return;
    }
    if (deleted) {
      _reloadSnapshot();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texts.mealHistory.deleteRecordSuccessMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(texts.mealHistory.title)),
      body: SafeArea(
        child: FutureBuilder<MealProgressSnapshot>(
          future: _snapshotFuture,
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
              itemCount: history.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const _MealHistoryHelpCard();
                }
                final entry = history[index - 1];
                return _MealHistoryCard(
                  entry: entry,
                  onDelete: () => _confirmDeleteMealHistoryEntry(entry),
                );
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

class _MealHistoryHelpCard extends StatelessWidget {
  const _MealHistoryHelpCard();

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context).mealHistory;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      key: const ValueKey('mealHistoryHelpCard'),
      color: AppColors.surfaceWarm,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.brown700,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    texts.helpTitle,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final item in texts.helpBulletItems)
              _MealHistoryHelpBullet(text: item),
          ],
        ),
      ),
    );
  }
}

class _MealHistoryHelpBullet extends StatelessWidget {
  const _MealHistoryHelpBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealHistoryCard extends StatelessWidget {
  const _MealHistoryCard({required this.entry, required this.onDelete});

  final MealHistoryEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context);
    final historyTexts = texts.mealHistory;
    final cappedActualDuration = capDuration(
      entry.actualDuration,
      entry.targetDuration,
    );
    final overrun = overrunDuration(entry.actualDuration, entry.targetDuration);
    final selectedIngredients = entry.selectedIngredientIds
        .map(MealIngredientCatalog.findById)
        .whereType<MealIngredientDefinition>()
        .toList(growable: false);

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
                  label: historyTexts.completedStatus(entry.completionStatus),
                  isIncomplete: !entry.mealCompleted,
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  key: ValueKey('deleteMealHistoryEntry-${entry.id}'),
                  tooltip: historyTexts.deleteRecordLabel,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.textSecondary,
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
                    value: formatDuration(cappedActualDuration),
                  ),
                ),
              ],
            ),
            if (!entry.mealCompleted && overrun > Duration.zero) ...[
              const SizedBox(height: AppSpacing.sm),
              _OverrunChip(
                label: historyTexts.overrunTime(formatDuration(overrun)),
              ),
            ],
            if (selectedIngredients.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                historyTexts.selectedIngredientLabel,
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SelectedIngredientRow(ingredients: selectedIngredients),
            ],
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

class _OverrunChip extends StatelessWidget {
  const _OverrunChip({required this.label});

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
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer_outlined,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.isIncomplete});

  final String label;
  final bool isIncomplete;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isIncomplete
        ? AppColors.errorContainer
        : AppColors.surfaceYellow;
    final borderColor = isIncomplete ? AppColors.error : AppColors.borderWarm;
    final textColor = isIncomplete
        ? AppColors.onErrorContainer
        : AppColors.textStrong;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.pill,
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: textColor,
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

class _SelectedIngredientRow extends StatelessWidget {
  const _SelectedIngredientRow({required this.ingredients});

  final List<MealIngredientDefinition> ingredients;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final ingredient in ingredients)
          _SelectedIngredientPill(
            ingredient: ingredient,
            label: ingredient.labelForLanguage(languageCode),
          ),
      ],
    );
  }
}

class _SelectedIngredientPill extends StatelessWidget {
  const _SelectedIngredientPill({
    required this.ingredient,
    required this.label,
  });

  final MealIngredientDefinition ingredient;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SelectedIngredientAvatar(
              ingredient: ingredient,
              semanticLabel: label,
            ),
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

class _SelectedIngredientAvatar extends StatelessWidget {
  const _SelectedIngredientAvatar({
    required this.ingredient,
    required this.semanticLabel,
  });

  final MealIngredientDefinition ingredient;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final assetPath = ingredient.assetPath;
    if (assetPath == null) {
      return Text(ingredient.emoji);
    }

    return Image.asset(
      assetPath,
      semanticLabel: semanticLabel,
      width: 28,
      height: 28,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Text(ingredient.emoji);
      },
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
