import 'package:flutter/material.dart';

import '../catalogs/activity_catalog.dart';
import '../catalogs/activity_marker_catalog.dart';
import '../l10n/app_texts.dart';
import '../models/activity_marker.dart';
import '../models/activity_history_entry.dart';
import '../models/activity_progress_snapshot.dart';
import '../models/reward_item.dart';
import '../services/local_activity_progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/duration_format.dart';
import '../widgets/reward_sticker_image.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({
    super.key,
    required this.activityProgressService,
  });

  final LocalActivityProgressService activityProgressService;

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  late Future<ActivityProgressSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = widget.activityProgressService.loadSnapshot();
  }

  void _reloadSnapshot() {
    setState(() {
      _snapshotFuture = widget.activityProgressService.loadSnapshot();
    });
  }

  Future<void> _confirmDeleteActivityHistoryEntry(
    ActivityHistoryEntry entry,
  ) async {
    final texts = AppTexts.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(texts.activityHistory.deleteRecordDialogTitle),
          content: Text(texts.activityHistory.deleteRecordDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(texts.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(texts.activityHistory.deleteRecordConfirmLabel),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true) {
      return;
    }

    final deleted = await widget.activityProgressService
        .deleteActivityHistoryEntry(entry.id);
    if (!mounted) {
      return;
    }
    if (deleted) {
      _reloadSnapshot();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(texts.activityHistory.deleteRecordSuccessMessage),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(texts.activityHistory.title)),
      body: SafeArea(
        child: FutureBuilder<ActivityProgressSnapshot>(
          future: _snapshotFuture,
          builder: (context, snapshot) {
            final history = snapshot.data?.history ?? const [];
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (history.isEmpty) {
              return const _ActivityHistoryEmptyState();
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
                  return const _ActivityHistoryHelpCard();
                }
                final entry = history[index - 1];
                return _ActivityHistoryCard(
                  entry: entry,
                  onDelete: () => _confirmDeleteActivityHistoryEntry(entry),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ActivityHistoryEmptyState extends StatelessWidget {
  const _ActivityHistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context).activityHistory;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.flag_rounded,
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

class _ActivityHistoryHelpCard extends StatelessWidget {
  const _ActivityHistoryHelpCard();

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context).activityHistory;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      key: const ValueKey('activityHistoryHelpCard'),
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
              _ActivityHistoryHelpBullet(text: item),
          ],
        ),
      ),
    );
  }
}

class _ActivityHistoryHelpBullet extends StatelessWidget {
  const _ActivityHistoryHelpBullet({required this.text});

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

class _ActivityHistoryCard extends StatelessWidget {
  const _ActivityHistoryCard({required this.entry, required this.onDelete});

  final ActivityHistoryEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context);
    final historyTexts = texts.activityHistory;
    final activity = ActivityCatalog.findById(entry.activityId);
    final activityLabel = activity.labelForLanguage(
      Localizations.localeOf(context).languageCode,
    );
    final cappedActualDuration = capDuration(
      entry.actualDuration,
      entry.targetDuration,
    );
    final overrun = overrunDuration(entry.actualDuration, entry.targetDuration);
    final selectedMarkers = entry.selectedMarkerIds
        .map(ActivityMarkerCatalog.findById)
        .whereType<ActivityMarkerDefinition>()
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
                    activityLabel,
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatusChip(
                  label: historyTexts.completedStatus(entry.completionStatus),
                  isIncomplete: !entry.activityCompleted,
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  key: ValueKey('deleteActivityHistoryEntry-${entry.id}'),
                  tooltip: historyTexts.deleteRecordLabel,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text(
                  activity.emoji,
                  style: const TextStyle(fontSize: 22, height: 1),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    historyTexts.dateLabel(entry.endedAt),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
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
                    value: formatDuration(cappedActualDuration),
                  ),
                ),
              ],
            ),
            if (!entry.activityCompleted && overrun > Duration.zero) ...[
              const SizedBox(height: AppSpacing.sm),
              _OverrunChip(
                label: historyTexts.overrunTime(formatDuration(overrun)),
              ),
            ],
            if (selectedMarkers.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                historyTexts.selectedMarkerLabel,
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SelectedMarkerRow(markers: selectedMarkers),
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

class _SelectedMarkerRow extends StatelessWidget {
  const _SelectedMarkerRow({required this.markers});

  final List<ActivityMarkerDefinition> markers;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final marker in markers)
          _SelectedMarkerPill(
            marker: marker,
            label: marker.labelForLanguage(languageCode),
          ),
      ],
    );
  }
}

class _SelectedMarkerPill extends StatelessWidget {
  const _SelectedMarkerPill({required this.marker, required this.label});

  final ActivityMarkerDefinition marker;
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
            _SelectedMarkerAvatar(marker: marker, semanticLabel: label),
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

class _SelectedMarkerAvatar extends StatelessWidget {
  const _SelectedMarkerAvatar({
    required this.marker,
    required this.semanticLabel,
  });

  final ActivityMarkerDefinition marker;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final assetPath = marker.assetPath;
    if (assetPath == null) {
      return Text(marker.emoji);
    }

    return Image.asset(
      assetPath,
      semanticLabel: semanticLabel,
      width: 28,
      height: 28,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Text(marker.emoji);
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
        texts.activityHistory.noRewardLabel,
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
