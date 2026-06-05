import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_texts.dart';
import '../models/meal_progress_snapshot.dart';
import '../models/meal_session_result.dart';
import '../models/meal_timer_config.dart';
import '../models/reward_goal.dart';
import '../models/reward_item.dart';
import '../services/local_meal_progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/reward_sticker_image.dart';
import 'reward_goal_screen.dart';
import 'timer_screen.dart';

const _fallbackSuccessVideoPath = 'assets/videos/result_motorcycle_success.mp4';
const _resultVideoPathsByVehicle = {
  'motorcycle': 'assets/videos/result_motorcycle_success.mp4',
  'fire_truck': 'assets/videos/result_fire_truck_success.mp4',
  'police_car': 'assets/videos/result_police_car_success.mp4',
  'excavator': 'assets/videos/result_excavator_success.mp4',
  'airplane': 'assets/videos/result_airplane_success.mp4',
  'bus': 'assets/videos/result_bus_success.mp4',
  'supercar': 'assets/videos/result_supercar_success.mp4',
  'train': 'assets/videos/result_train_success.mp4',
  't_rex': 'assets/videos/result_t_rex_success.mp4',
  'shark': 'assets/videos/result_shark_success.mp4',
  'brachio': 'assets/videos/result_brachio_success.mp4',
  'pteranodon': 'assets/videos/result_pteranodon_success.mp4',
};

String resultVideoAssetPathForVehicle({required String vehicleId}) {
  return _resultVideoPathsByVehicle[vehicleId] ?? _fallbackSuccessVideoPath;
}

BoxFit resultIntroMediaFitForSize(Size size) {
  return size.width > size.height ? BoxFit.contain : BoxFit.cover;
}

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.config,
    required this.mealProgressService,
    required this.onConfigChanged,
  });

  final MealSessionResult result;
  final MealTimerConfig config;
  final LocalMealProgressService mealProgressService;
  final ValueChanged<MealTimerConfig> onConfigChanged;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const _successImagePath = 'assets/images/result_success.png';

  VideoPlayerController? _introController;
  late final Future<RecordedMealSession> _recordedSession;
  bool _introFinished = false;
  bool _introFallback = false;

  @override
  void initState() {
    super.initState();
    _recordedSession = widget.mealProgressService.recordMealResult(
      widget.result,
    );
    if (!widget.result.mealCompleted) {
      _introFinished = true;
      return;
    }

    final introController = VideoPlayerController.asset(_introVideoPath);
    _introController = introController;
    introController.addListener(_handleIntroChanged);
    _initializeIntroVideo();
  }

  String get _introVideoPath =>
      resultVideoAssetPathForVehicle(vehicleId: widget.config.vehicleId);

  void _handleIntroChanged() {
    final controller = _introController;
    if (controller == null) {
      return;
    }

    final value = controller.value;
    if (_introFinished ||
        !value.isInitialized ||
        value.duration == Duration.zero) {
      return;
    }

    if (value.position >= value.duration) {
      setState(() => _introFinished = true);
    }
  }

  Future<void> _initializeIntroVideo() async {
    final controller = _introController;
    if (controller == null) {
      return;
    }

    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.play();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _introFallback = true;
          _introFinished = true;
        });
      }
    }
  }

  @override
  void dispose() {
    final controller = _introController;
    if (controller != null) {
      controller.removeListener(_handleIntroChanged);
      controller.dispose();
    }
    super.dispose();
  }

  void _restart(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          config: widget.config,
          mealProgressService: widget.mealProgressService,
          onConfigChanged: widget.onConfigChanged,
        ),
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final mealCompleted = widget.result.mealCompleted;
    final texts = AppTexts.of(context);

    final introController = _introController;
    if (!_introFinished && introController != null) {
      return _ResultIntroScreen(
        controller: introController,
        fallbackImageAssetPath: _successImagePath,
        showFallback: _introFallback,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: Column(
                              children: [
                                Text(
                                  texts.result.title(mealCompleted),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                if (mealCompleted) ...[
                                  const SizedBox(height: AppSpacing.xl),
                                  FutureBuilder<RecordedMealSession>(
                                    future: _recordedSession,
                                    builder: (context, snapshot) {
                                      final recordedSession = snapshot.data;

                                      return Column(
                                        children: [
                                          _RewardResultBox(
                                            rewards:
                                                recordedSession?.awardedRewards,
                                          ),
                                          if (recordedSession != null &&
                                              (recordedSession
                                                      .updatedRewardGoals
                                                      .isNotEmpty ||
                                                  recordedSession
                                                      .earnedRewardGoals
                                                      .isNotEmpty)) ...[
                                            const SizedBox(
                                              height: AppSpacing.md,
                                            ),
                                            _RewardGoalResultBox(
                                              updatedGoals: recordedSession
                                                  .updatedRewardGoals,
                                              earnedGoals: recordedSession
                                                  .earnedRewardGoals,
                                              mealProgressService:
                                                  widget.mealProgressService,
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                ] else
                                  const SizedBox(height: AppSpacing.lg),
                                Text(
                                  texts.result.primaryMessage(mealCompleted),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(height: 1.4),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  texts.result.secondaryMessage(mealCompleted),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () => _restart(context),
                          icon: const Icon(Icons.two_wheeler_rounded),
                          label: Text(texts.common.restartRide),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: () => _goHome(context),
                          icon: const Icon(Icons.home_rounded),
                          label: Text(texts.common.home),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RewardGoalResultBox extends StatelessWidget {
  const _RewardGoalResultBox({
    required this.updatedGoals,
    required this.earnedGoals,
    required this.mealProgressService,
  });

  final List<RewardGoal> updatedGoals;
  final List<RewardGoal> earnedGoals;
  final LocalMealProgressService mealProgressService;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final justEarned = earnedGoals.isNotEmpty;
    final goals = [...earnedGoals, ...updatedGoals];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: justEarned ? AppColors.surfaceYellow : AppColors.surfaceWarm,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              justEarned
                  ? texts.rewards.rewardGoalReadyMessage
                  : texts.rewards.rewardGoalProgressTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final goal in goals) ...[
              _RewardGoalProgressRow(goal: goal),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (justEarned) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RewardGoalScreen(
                        mealProgressService: mealProgressService,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.card_giftcard_rounded),
                label: Text(texts.rewards.openRewardGoal),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RewardGoalProgressRow extends StatelessWidget {
  const _RewardGoalProgressRow({required this.goal});

  final RewardGoal goal;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: AppRadius.compactCard,
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                goal.rewardText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textStrong,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              texts.rewards.rewardGoalProgress(
                goal.filledCount,
                goal.requiredStickerCount,
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultIntroScreen extends StatelessWidget {
  const _ResultIntroScreen({
    required this.controller,
    required this.fallbackImageAssetPath,
    required this.showFallback,
  });

  final VideoPlayerController controller;
  final String fallbackImageAssetPath;
  final bool showFallback;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final fit = resultIntroMediaFitForSize(
            Size(constraints.maxWidth, constraints.maxHeight),
          );

          return SizedBox.expand(
            child: ColoredBox(
              color: AppColors.surfaceSoft,
              child: showFallback
                  ? Image.asset(
                      fallbackImageAssetPath,
                      fit: fit,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    )
                  : !controller.value.isInitialized
                  ? const SizedBox.shrink()
                  : FittedBox(
                      fit: fit,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _RewardResultBox extends StatelessWidget {
  const _RewardResultBox({required this.rewards});

  final List<RewardDefinition>? rewards;

  @override
  Widget build(BuildContext context) {
    final rewards = this.rewards;
    final texts = AppTexts.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceYellow,
        borderRadius: AppRadius.card,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: rewards == null
            ? Text(
                texts.result.rewardLoading,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              )
            : rewards.isEmpty
            ? Text(
                texts.result.recordSaved,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              )
            : Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                children: [
                  for (final reward in rewards) _RewardBadge(reward: reward),
                ],
              ),
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({required this.reward});

  final RewardDefinition reward;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final rewardName = texts.rewards.name(reward.id);

    return SizedBox(
      width: 116,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RewardStickerImage(
            reward: reward,
            semanticLabel: rewardName,
            size: 64,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            rewardName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
