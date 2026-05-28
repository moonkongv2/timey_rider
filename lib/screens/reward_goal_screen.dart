import 'package:flutter/material.dart';

import '../l10n/app_texts.dart';
import '../models/meal_progress_snapshot.dart';
import '../models/reward_goal.dart';
import '../models/reward_item.dart';
import '../services/local_meal_progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/reward_sticker_image.dart';

class RewardGoalScreen extends StatefulWidget {
  const RewardGoalScreen({super.key, required this.mealProgressService});

  final LocalMealProgressService mealProgressService;

  @override
  State<RewardGoalScreen> createState() => _RewardGoalScreenState();
}

class _RewardGoalScreenState extends State<RewardGoalScreen> {
  late Future<MealProgressSnapshot> _snapshotFuture;
  final TextEditingController _rewardTextController = TextEditingController();
  int _requiredStickerCount = 5;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = widget.mealProgressService.loadSnapshot();
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
      _snapshotFuture = widget.mealProgressService.loadSnapshot();
    });
  }

  void _adjustRequiredStickerCount(int delta) {
    setState(() {
      _requiredStickerCount = (_requiredStickerCount + delta).clamp(1, 20);
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
      await widget.mealProgressService.createRewardGoal(
        requiredStickerCount: _requiredStickerCount,
        rewardText: rewardText,
      );
      _rewardTextController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(texts.rewards.rewardGoalCreatedMessage)),
        );
        _refresh();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _redeemGoal() async {
    if (_isSaving) {
      return;
    }

    final texts = AppTexts.of(context);
    setState(() => _isSaving = true);
    try {
      final redeemedGoal = await widget.mealProgressService
          .redeemActiveRewardGoal();
      if (mounted && redeemedGoal != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(texts.rewards.rewardGoalRedeemedMessage)),
        );
        _refresh();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(texts.rewards.rewardGoalTitle)),
      body: SafeArea(
        child: FutureBuilder<MealProgressSnapshot>(
          future: _snapshotFuture,
          builder: (context, snapshot) {
            final activeGoal = snapshot.data?.activeRewardGoal;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                if (activeGoal == null)
                  _RewardGoalCreationForm(
                    rewardTextController: _rewardTextController,
                    requiredStickerCount: _requiredStickerCount,
                    isSaving: _isSaving,
                    onAdjustRequiredStickerCount: _adjustRequiredStickerCount,
                    onSave: _createGoal,
                  )
                else
                  _ActiveRewardGoalView(
                    goal: activeGoal,
                    isSaving: _isSaving,
                    onRedeem: _redeemGoal,
                  ),
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
    required this.rewardTextController,
    required this.requiredStickerCount,
    required this.isSaving,
    required this.onAdjustRequiredStickerCount,
    required this.onSave,
  });

  final TextEditingController rewardTextController;
  final int requiredStickerCount;
  final bool isSaving;
  final ValueChanged<int> onAdjustRequiredStickerCount;
  final VoidCallback onSave;

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
              texts.rewards.rewardGoalEmptyTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              texts.rewards.rewardGoalEmptyBody,
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
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: canSave ? onSave : null,
              icon: const Icon(Icons.flag_rounded),
              label: Text(texts.rewards.rewardGoalSaveButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickerCountSelector extends StatelessWidget {
  const _StickerCountSelector({required this.count, required this.onAdjust});

  final int count;
  final ValueChanged<int> onAdjust;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return DecoratedBox(
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
    );
  }
}

class _ActiveRewardGoalView extends StatelessWidget {
  const _ActiveRewardGoalView({
    required this.goal,
    required this.isSaving,
    required this.onRedeem,
  });

  final RewardGoal goal;
  final bool isSaving;
  final VoidCallback onRedeem;

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
            if (goal.isReady) ...[
              const SizedBox(height: AppSpacing.xl),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceYellow,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.borderWarm),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    texts.rewards.rewardGoalReadyMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: isSaving ? null : onRedeem,
                icon: const Icon(Icons.card_giftcard_rounded),
                label: Text(texts.rewards.rewardGoalGivenButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
