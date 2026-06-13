import 'package:flutter/material.dart';

import '../l10n/app_texts.dart';
import '../models/activity_progress_snapshot.dart';
import '../models/reward_goal.dart';
import '../models/reward_item.dart';
import '../services/local_activity_progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/reward_sticker_image.dart';

class RewardGoalScreen extends StatefulWidget {
  const RewardGoalScreen({super.key, required this.activityProgressService});

  final LocalActivityProgressService activityProgressService;

  @override
  State<RewardGoalScreen> createState() => _RewardGoalScreenState();
}

class _RewardGoalScreenState extends State<RewardGoalScreen> {
  late Future<ActivityProgressSnapshot> _snapshotFuture;
  final TextEditingController _rewardTextController = TextEditingController();
  int _requiredStickerCount = 5;
  bool _isSaving = false;
  RewardGoal? _editingGoal;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = widget.activityProgressService.loadSnapshot();
    _rewardTextController.addListener(_handleRewardTextChanged);
  }

  @override
  void dispose() {
    _rewardTextController.removeListener(_handleRewardTextChanged);
    _rewardTextController.dispose();
    super.dispose();
  }

  void _handleRewardTextChanged() {
    setState(() {});
  }

  void _refresh() {
    setState(() {
      _snapshotFuture = widget.activityProgressService.loadSnapshot();
    });
  }

  void _adjustRequiredStickerCount(int delta) {
    setState(() {
      _requiredStickerCount = (_requiredStickerCount + delta)
          .clamp(1, 20)
          .toInt();
    });
  }

  void _setRequiredStickerCount(int count) {
    setState(() {
      _requiredStickerCount = count.clamp(1, 20).toInt();
    });
  }

  void _startEditingGoal(RewardGoal goal) {
    setState(() {
      _editingGoal = goal;
      _rewardTextController.text = goal.rewardText;
      _requiredStickerCount = goal.requiredStickerCount;
    });
  }

  void _stopEditingGoal() {
    setState(() {
      _editingGoal = null;
      _rewardTextController.clear();
      _requiredStickerCount = 5;
    });
  }

  Future<void> _createGoal() async {
    final rewardText = _rewardTextController.text.trim();
    if (rewardText.isEmpty || _isSaving) {
      return;
    }

    final texts = AppTexts.of(context);
    setState(() => _isSaving = true);
    try {
      await widget.activityProgressService.createRewardGoal(
        requiredStickerCount: _requiredStickerCount,
        rewardText: rewardText,
      );
      _rewardTextController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(texts.rewards.rewardGoalCreatedMessage)),
        );
        _stopEditingGoal();
        _refresh();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updateGoal() async {
    final editingGoal = _editingGoal;
    final rewardText = _rewardTextController.text.trim();
    if (editingGoal == null || rewardText.isEmpty || _isSaving) {
      return;
    }

    final texts = AppTexts.of(context);
    setState(() => _isSaving = true);
    try {
      await widget.activityProgressService.updateActiveRewardGoal(
        goalId: editingGoal.id,
        requiredStickerCount: _requiredStickerCount,
        rewardText: rewardText,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(texts.rewards.rewardGoalUpdatedMessage)),
        );
        _stopEditingGoal();
        _refresh();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _useEarnedGoal(RewardGoal goal) async {
    if (_isSaving) {
      return;
    }

    final confirmed = await _confirmRewardGoalAction(
      title: AppTexts.of(context).rewards.confirmUseRewardGoalTitle,
      message: AppTexts.of(context).rewards.confirmUseRewardGoalMessage,
      confirmLabel: AppTexts.of(context).rewards.confirmUseRewardGoal,
    );
    if (!confirmed) {
      return;
    }
    if (!mounted) {
      return;
    }

    final texts = AppTexts.of(context);
    setState(() => _isSaving = true);
    try {
      final usedGoal = await widget.activityProgressService.useEarnedRewardGoal(
        goalId: goal.id,
      );
      if (mounted && usedGoal != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(texts.rewards.rewardGoalUsedMessage)),
        );
        _stopEditingGoal();
        _refresh();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _cancelGoal(RewardGoal goal) async {
    if (_isSaving) {
      return;
    }

    final texts = AppTexts.of(context);
    final confirmed = await _confirmRewardGoalAction(
      title: texts.rewards.confirmCancelRewardGoalTitle,
      message: texts.rewards.confirmCancelRewardGoalMessage,
      confirmLabel: texts.rewards.confirmCancelGoal,
      isDestructive: true,
    );
    if (!confirmed) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final canceledGoal = await widget.activityProgressService
          .cancelActiveRewardGoal(goalId: goal.id);
      if (mounted && canceledGoal != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(texts.rewards.rewardGoalCanceledMessage)),
        );
        _stopEditingGoal();
        _refresh();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _confirmRewardGoalAction({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) async {
    final texts = AppTexts.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(texts.rewards.keepRewardGoal),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: isDestructive
                  ? FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                    )
                  : null,
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(texts.rewards.rewardGoalTitle)),
      body: SafeArea(
        child: FutureBuilder<ActivityProgressSnapshot>(
          future: _snapshotFuture,
          builder: (context, snapshot) {
            final activeGoals =
                snapshot.data?.activeRewardGoals ?? const <RewardGoal>[];
            final earnedRewardGoals =
                snapshot.data?.earnedRewardGoals ?? const <RewardGoal>[];
            final usedRewardGoals =
                snapshot.data?.usedRewardGoals ?? const <RewardGoal>[];
            final editingGoal = _editingGoal;
            final canCreate =
                activeGoals.length <
                    LocalActivityProgressService.maxActiveRewardGoals &&
                editingGoal == null;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                if (canCreate) ...[
                  _RewardGoalCreationForm(
                    title: texts.rewards.rewardGoalEmptyTitle,
                    body: texts.rewards.rewardGoalEmptyBody,
                    saveLabel: texts.rewards.rewardGoalSaveButton,
                    rewardTextController: _rewardTextController,
                    requiredStickerCount: _requiredStickerCount,
                    isSaving: _isSaving,
                    onAdjustRequiredStickerCount: _adjustRequiredStickerCount,
                    onSelectRequiredStickerCount: _setRequiredStickerCount,
                    onSave: _createGoal,
                  ),
                ] else if (editingGoal != null) ...[
                  _RewardGoalCreationForm(
                    title: texts.rewards.editRewardGoal,
                    body: texts.rewards.rewardGoalEmptyBody,
                    saveLabel: texts.rewards.editRewardGoal,
                    rewardTextController: _rewardTextController,
                    requiredStickerCount: _requiredStickerCount,
                    isSaving: _isSaving,
                    onAdjustRequiredStickerCount: _adjustRequiredStickerCount,
                    onSelectRequiredStickerCount: _setRequiredStickerCount,
                    onSave: _updateGoal,
                    onCancel: _stopEditingGoal,
                  ),
                ] else ...[
                  _MaxActiveRewardGoalsNotice(
                    message: texts.rewards.maxActiveRewardGoalsMessage,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                _ActiveRewardGoalsSection(
                  goals: activeGoals,
                  isSaving: _isSaving,
                  onEdit: _startEditingGoal,
                  onCancel: _cancelGoal,
                ),
                const SizedBox(height: AppSpacing.xl),
                _EarnedRewardGoalsSection(
                  goals: earnedRewardGoals,
                  isSaving: _isSaving,
                  onUse: _useEarnedGoal,
                ),
                const SizedBox(height: AppSpacing.xl),
                _RewardGoalHistorySection(goals: usedRewardGoals),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RewardGoalCreationForm extends StatelessWidget {
  const _RewardGoalCreationForm({
    required this.title,
    required this.body,
    required this.saveLabel,
    required this.rewardTextController,
    required this.requiredStickerCount,
    required this.isSaving,
    required this.onAdjustRequiredStickerCount,
    required this.onSelectRequiredStickerCount,
    required this.onSave,
    this.onCancel,
  });

  final String title;
  final String body;
  final String saveLabel;
  final TextEditingController rewardTextController;
  final int requiredStickerCount;
  final bool isSaving;
  final ValueChanged<int> onAdjustRequiredStickerCount;
  final ValueChanged<int> onSelectRequiredStickerCount;
  final VoidCallback onSave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final canSave = rewardTextController.text.trim().isNotEmpty && !isSaving;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: rewardTextController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: texts.rewards.rewardGoalRewardFieldLabel,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                if (canSave) {
                  onSave();
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _StickerCountSelector(
              count: requiredStickerCount,
              onAdjust: onAdjustRequiredStickerCount,
              onSelect: onSelectRequiredStickerCount,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: canSave ? onSave : null,
              icon: const Icon(Icons.flag_rounded),
              label: Text(saveLabel),
            ),
            if (onCancel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: isSaving ? null : onCancel,
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StickerCountSelector extends StatelessWidget {
  const _StickerCountSelector({
    required this.count,
    required this.onAdjust,
    required this.onSelect,
  });

  final int count;
  final ValueChanged<int> onAdjust;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.borderWarm),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    texts.rewards.rewardGoalRequiredStickerCountLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: count <= 1 ? null : () => onAdjust(-1),
                  icon: const Icon(Icons.remove_rounded),
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: count >= 20 ? null : () => onAdjust(1),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final value in const [3, 5, 7, 10])
              ChoiceChip(
                label: Text('$value'),
                selected: count == value,
                onSelected: (_) => onSelect(value),
              ),
          ],
        ),
      ],
    );
  }
}

class _MaxActiveRewardGoalsNotice extends StatelessWidget {
  const _MaxActiveRewardGoalsNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.34,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveRewardGoalsSection extends StatelessWidget {
  const _ActiveRewardGoalsSection({
    required this.goals,
    required this.isSaving,
    required this.onEdit,
    required this.onCancel,
  });

  final List<RewardGoal> goals;
  final bool isSaving;
  final ValueChanged<RewardGoal> onEdit;
  final ValueChanged<RewardGoal> onCancel;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          texts.rewards.activeRewardGoalsTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (goals.isEmpty)
          _RewardGoalEmptyMessage(message: texts.rewards.rewardGoalEmptyBody)
        else
          for (final goal in goals) ...[
            _ActiveRewardGoalView(
              goal: goal,
              isSaving: isSaving,
              onEdit: () => onEdit(goal),
              onCancel: () => onCancel(goal),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

class _ActiveRewardGoalView extends StatelessWidget {
  const _ActiveRewardGoalView({
    required this.goal,
    required this.isSaving,
    required this.onEdit,
    required this.onCancel,
  });

  final RewardGoal goal;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              texts.rewards.rewardGoalPromiseTitle,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              goal.rewardText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              texts.rewards.rewardGoalProgress(
                goal.filledCount,
                goal.requiredStickerCount,
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            if (!goal.isReady) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                texts.rewards.rewardGoalRemaining(goal.remainingCount),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            _RewardGoalBoard(goal: goal),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSaving ? null : onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: Text(texts.rewards.editRewardGoal),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSaving ? null : onCancel,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(texts.rewards.cancelRewardGoal),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardGoalHistorySection extends StatelessWidget {
  const _RewardGoalHistorySection({required this.goals});

  final List<RewardGoal> goals;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          texts.rewards.usedRewardGoalsTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (goals.isEmpty)
          _RewardGoalEmptyMessage(message: texts.rewards.rewardGoalNoHistory)
        else
          for (final goal in goals) ...[
            _RewardGoalHistoryTile(goal: goal),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _EarnedRewardGoalsSection extends StatelessWidget {
  const _EarnedRewardGoalsSection({
    required this.goals,
    required this.isSaving,
    required this.onUse,
  });

  final List<RewardGoal> goals;
  final bool isSaving;
  final ValueChanged<RewardGoal> onUse;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          texts.rewards.earnedRewardGoalsTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (goals.isEmpty)
          _RewardGoalEmptyMessage(message: texts.rewards.rewardGoalNoHistory)
        else
          for (final goal in goals) ...[
            _EarnedRewardGoalTile(
              goal: goal,
              isSaving: isSaving,
              onUse: () => onUse(goal),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _EarnedRewardGoalTile extends StatelessWidget {
  const _EarnedRewardGoalTile({
    required this.goal,
    required this.isSaving,
    required this.onUse,
  });

  final RewardGoal goal;
  final bool isSaving;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceYellow,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              goal.rewardText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              texts.rewards.rewardGoalReadyAt(
                _formatDateLabel(goal.earnedAt ?? goal.readyAt),
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: isSaving ? null : onUse,
              icon: const Icon(Icons.redeem_rounded),
              label: Text(texts.rewards.rewardGoalGivenButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardGoalEmptyMessage extends StatelessWidget {
  const _RewardGoalEmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RewardGoalHistoryTile extends StatelessWidget {
  const _RewardGoalHistoryTile({required this.goal});

  final RewardGoal goal;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.rewardText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              texts.rewards.rewardGoalProgress(
                goal.filledCount,
                goal.requiredStickerCount,
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (goal.earnedAt != null || goal.readyAt != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                texts.rewards.rewardGoalReadyAt(
                  _formatDateLabel(goal.earnedAt ?? goal.readyAt),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (goal.usedAt != null || goal.redeemedAt != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                texts.rewards.rewardGoalRedeemedAt(
                  _formatDateLabel(goal.usedAt ?? goal.redeemedAt),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatDateLabel(DateTime? dateTime) {
  if (dateTime == null) {
    return '';
  }

  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '${dateTime.year}.$month.$day';
}

class _RewardGoalBoard extends StatelessWidget {
  const _RewardGoalBoard({required this.goal});

  final RewardGoal goal;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (var index = 0; index < goal.requiredStickerCount; index += 1)
          _RewardGoalSlotTile(
            slot: index < goal.filledSlots.length
                ? goal.filledSlots[index]
                : null,
            slotNumber: index + 1,
            emptySemanticLabel: texts.rewards.rewardGoalEmptySlotSemanticLabel,
          ),
      ],
    );
  }
}

class _RewardGoalSlotTile extends StatelessWidget {
  const _RewardGoalSlotTile({
    required this.slot,
    required this.slotNumber,
    required this.emptySemanticLabel,
  });

  final RewardGoalSlot? slot;
  final int slotNumber;
  final String emptySemanticLabel;

  @override
  Widget build(BuildContext context) {
    final slot = this.slot;
    final reward = slot == null ? null : RewardCatalog.findById(slot.rewardId);
    final texts = AppTexts.of(context);
    final rewardName = reward == null ? null : texts.rewards.name(reward.id);

    return Semantics(
      label: rewardName == null
          ? emptySemanticLabel
          : texts.rewards.rewardGoalSlotSemanticLabel(slotNumber, rewardName),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: reward == null ? AppColors.surfaceSoft : AppColors.white,
          borderRadius: AppRadius.compactCard,
          border: Border.all(color: AppColors.borderWarm),
        ),
        child: SizedBox.square(
          dimension: 64,
          child: Center(
            child: reward == null
                ? Icon(
                    Icons.add_rounded,
                    color: AppColors.textMuted.withValues(alpha: 0.72),
                  )
                : RewardStickerImage(
                    reward: reward,
                    semanticLabel: rewardName,
                    size: 48,
                  ),
          ),
        ),
      ),
    );
  }
}
