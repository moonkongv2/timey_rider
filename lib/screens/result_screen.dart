import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_texts.dart';
import '../models/meal_progress_snapshot.dart';
import '../models/meal_session_result.dart';
import '../models/meal_timer_config.dart';
import '../models/reward_item.dart';
import '../services/local_meal_progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/reward_sticker_image.dart';
import 'timer_screen.dart';

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
  static const _successVideoPath = 'assets/videos/result_success.mp4';
  static const _failureVideoPath = 'assets/videos/result_failure.mp4';
  static const _successImagePath = 'assets/images/result_success.png';
  static const _failureImagePath = 'assets/images/result_failure.png';

  late final VideoPlayerController _introController;
  late final Future<RecordedMealSession> _recordedSession = widget
      .mealProgressService
      .recordMealResult(widget.result);
  bool _introFinished = false;
  bool _introFallback = false;

  @override
  void initState() {
    super.initState();
    _introController = VideoPlayerController.asset(_introVideoPath);
    _introController.addListener(_handleIntroChanged);
    _initializeIntroVideo();
  }

  String get _introVideoPath =>
      widget.result.mealCompleted ? _successVideoPath : _failureVideoPath;

  String get _introFallbackImagePath =>
      widget.result.mealCompleted ? _successImagePath : _failureImagePath;

  void _handleIntroChanged() {
    final value = _introController.value;
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
    try {
      await _introController.initialize();
      await _introController.setLooping(false);
      await _introController.play();
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
    _introController.removeListener(_handleIntroChanged);
    _introController.dispose();
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

    if (!_introFinished) {
      return _ResultIntroScreen(
        controller: _introController,
        fallbackImageAssetPath: _introFallbackImagePath,
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
                                      return _RewardResultBox(
                                        rewards: snapshot.data?.awardedRewards,
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
      body: SizedBox.expand(
        child: showFallback
            ? Image.asset(
                fallbackImageAssetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              )
            : !controller.value.isInitialized
            ? const ColoredBox(color: AppColors.surfaceSoft)
            : FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
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
