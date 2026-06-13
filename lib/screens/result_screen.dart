import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_texts.dart';
import '../l10n/text_sets.dart';
import '../models/activity_completion_status.dart';
import '../models/activity_progress_snapshot.dart';
import '../models/activity_session_result.dart';
import '../models/activity_timer_config.dart';
import '../models/reward_goal.dart';
import '../models/reward_item.dart';
import '../services/local_activity_progress_service.dart';
import '../services/orientation_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/app/app_help_sheet.dart';
import '../widgets/reward_sticker_image.dart';
import 'reward_goal_screen.dart';
import 'timer_screen.dart';

const _fallbackSuccessVideoPath = 'assets/videos/result_motorcycle_success.mp4';
const _failedResultBackgroundLandscapePath =
    'assets/images/result_failed_bg_landscape.png';
const _failedResultBackgroundPortraitPath =
    'assets/images/result_failed_bg_portrait.png';
const _successResultBackgroundLandscapePath =
    'assets/images/result_success_bg_landscape.png';
const _successResultBackgroundPortraitPath =
    'assets/images/result_success_bg_portrait.png';
const _failureRiderImageBasePath = 'assets/images/riders';
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

bool isPositiveResult(ActivityCompletionStatus status) {
  return switch (status) {
    ActivityCompletionStatus.completedBeforeEnd ||
    ActivityCompletionStatus.completedAtEnd ||
    ActivityCompletionStatus.completedAfterEnd ||
    ActivityCompletionStatus.timeEnded => true,
    ActivityCompletionStatus.needsMoreTime ||
    ActivityCompletionStatus.canceled => false,
  };
}

bool isRewardableResult(ActivityCompletionStatus status) {
  return switch (status) {
    ActivityCompletionStatus.completedBeforeEnd ||
    ActivityCompletionStatus.completedAtEnd ||
    ActivityCompletionStatus.completedAfterEnd => true,
    ActivityCompletionStatus.timeEnded ||
    ActivityCompletionStatus.needsMoreTime ||
    ActivityCompletionStatus.canceled => false,
  };
}

List<AppHelpSection> _resultHelpSections(
  ResultTextSet texts,
  ActivityCompletionStatus status,
) {
  return [
    AppHelpSection(
      title: texts.resultHelpMeaningTitle(status),
      bulletItems: texts.resultHelpMeaningItems(status),
    ),
    AppHelpSection(
      title: texts.resultHelpSayTitle(status),
      bulletItems: texts.resultHelpSayItems(status),
    ),
    AppHelpSection(
      title: texts.resultHelpAvoidTitle(status),
      bulletItems: texts.resultHelpAvoidItems(status),
    ),
    AppHelpSection(
      title: texts.resultHelpNextCourseTitle(status),
      bulletItems: texts.resultHelpNextCourseItems(status),
    ),
  ];
}

Future<void> _showResultHelpSheet(
  BuildContext context, {
  required ActivityCompletionStatus status,
}) {
  final texts = AppTexts.of(context).result;
  return showAppHelpSheet(
    context: context,
    title: texts.helpTitle(status),
    sections: _resultHelpSections(texts, status),
  );
}

String resultVideoAssetPathForVehicle({required String vehicleId}) {
  return _resultVideoPathsByVehicle[vehicleId] ?? _fallbackSuccessVideoPath;
}

String failureRiderAssetPathForVehicle({required String vehicleId}) {
  return '$_failureRiderImageBasePath/rider_$vehicleId.png';
}

BoxFit resultIntroMediaFitForSize(Size size) {
  return size.width > size.height ? BoxFit.contain : BoxFit.cover;
}

typedef ResultIntroControllerFactory =
    VideoPlayerController Function(String assetPath);

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.config,
    required this.activityProgressService,
    required this.onConfigChanged,
    this.introControllerFactory,
    this.orientationService = const SystemOrientationService(),
  });

  final ActivitySessionResult result;
  final ActivityTimerConfig config;
  final LocalActivityProgressService activityProgressService;
  final ValueChanged<ActivityTimerConfig> onConfigChanged;
  final ResultIntroControllerFactory? introControllerFactory;
  final OrientationService orientationService;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const _successImagePath = 'assets/images/result_success.png';

  VideoPlayerController? _introController;
  late final Future<RecordedActivitySession> _recordedSession;
  bool _introFinished = false;
  bool _introFallback = false;
  bool _handoffOrientation = false;

  @override
  void initState() {
    super.initState();
    unawaited(widget.orientationService.allowMealFlowOrientations());
    _recordedSession = widget.activityProgressService.recordActivityResult(
      widget.result,
    );
    if (!isRewardableResult(widget.result.completionStatus)) {
      _introFinished = true;
      return;
    }

    final introControllerFactory =
        widget.introControllerFactory ?? VideoPlayerController.asset;
    final introController = introControllerFactory(_introVideoPath);
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
    if (!_handoffOrientation) {
      unawaited(widget.orientationService.lockPortrait());
    }
    super.dispose();
  }

  void _restart(BuildContext context) {
    _handoffOrientation = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          config: widget.config,
          activityProgressService: widget.activityProgressService,
          onConfigChanged: widget.onConfigChanged,
          orientationService: widget.orientationService,
        ),
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showResultHelp(ActivityCompletionStatus status) {
    _showResultHelpSheet(context, status: status);
  }

  @override
  Widget build(BuildContext context) {
    final completionStatus = widget.result.completionStatus;
    final isPositive = isPositiveResult(completionStatus);
    final isRewardable = isRewardableResult(completionStatus);
    final texts = AppTexts.of(context);
    final failureRiderAssetPath = failureRiderAssetPathForVehicle(
      vehicleId: widget.config.vehicleId,
    );

    final introController = _introController;
    if (!_introFinished && introController != null) {
      return _ResultIntroScreen(
        controller: introController,
        fallbackImageAssetPath: _successImagePath,
        showFallback: _introFallback,
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _ResultBackground(isPositive: isPositive),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompactLandscape =
                      constraints.maxWidth > constraints.maxHeight &&
                      constraints.maxHeight < 430;
                  final isPortraitSuccess =
                      isRewardable &&
                      constraints.maxHeight >= constraints.maxWidth;
                  if (isCompactLandscape) {
                    return _CompactLandscapeResultLayout(
                      completionStatus: completionStatus,
                      recordedSession: _recordedSession,
                      activityProgressService: widget.activityProgressService,
                      orientationService: widget.orientationService,
                      failureRiderAssetPath: failureRiderAssetPath,
                      vehicleId: widget.config.vehicleId,
                      onRestart: () => _restart(context),
                      onHome: () => _goHome(context),
                    );
                  }

                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Spacer(),
                            Card(
                              color: AppColors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.card,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xxl),
                                child: Column(
                                  children: [
                                    if (!isPositive) ...[
                                      _FailureRiderImage(
                                        assetPath: failureRiderAssetPath,
                                        maxSize: 240,
                                        fallbackIconSize: 96,
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                    ] else if (!isRewardable) ...[
                                      const _NeutralResultIcon(),
                                      const SizedBox(height: AppSpacing.lg),
                                    ],
                                    Text(
                                      texts.result.title(completionStatus),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    if (isRewardable) ...[
                                      SizedBox(
                                        height: isPortraitSuccess
                                            ? AppSpacing.lg
                                            : AppSpacing.xl,
                                      ),
                                      FutureBuilder<RecordedActivitySession>(
                                        future: _recordedSession,
                                        builder: (context, snapshot) {
                                          final recordedSession = snapshot.data;

                                          return Column(
                                            children: [
                                              _RewardResultBox(
                                                rewards: recordedSession
                                                    ?.awardedRewards,
                                                isCondensed: isPortraitSuccess,
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
                                                  activityProgressService: widget
                                                      .activityProgressService,
                                                  orientationService:
                                                      widget.orientationService,
                                                ),
                                              ],
                                            ],
                                          );
                                        },
                                      ),
                                      SizedBox(
                                        height: isPortraitSuccess
                                            ? AppSpacing.lg
                                            : AppSpacing.xl,
                                      ),
                                    ] else
                                      const SizedBox(height: AppSpacing.lg),
                                    Text(
                                      texts.result.primaryMessage(
                                        completionStatus,
                                        vehicleId: widget.config.vehicleId,
                                      ),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(height: 1.4),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      texts.result.secondaryMessage(
                                        completionStatus,
                                      ),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _ResultGuardianTipCard(
                              completionStatus: completionStatus,
                              onPressed: () =>
                                  _showResultHelp(completionStatus),
                            ),
                            Spacer(flex: isPortraitSuccess ? 2 : 1),
                            FilledButton.icon(
                              onPressed: () => _restart(context),
                              icon: const Icon(Icons.two_wheeler_rounded),
                              label: Text(texts.common.restartRide),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            OutlinedButton.icon(
                              onPressed: () => _goHome(context),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                side: BorderSide.none,
                              ),
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
        ],
      ),
    );
  }
}

class _ResultGuardianTipCard extends StatelessWidget {
  const _ResultGuardianTipCard({
    required this.completionStatus,
    required this.onPressed,
  });

  final ActivityCompletionStatus completionStatus;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context).result;
    final textTheme = Theme.of(context).textTheme;
    final isPositive = isPositiveResult(completionStatus);
    final icon = isPositive ? Icons.favorite_rounded : Icons.spa_rounded;
    final key = ValueKey(
      isPositive
          ? 'completedResultGuardianTipCard'
          : 'incompleteResultGuardianTipCard',
    );

    return Semantics(
      button: true,
      label: texts.parentTipSemanticLabel(completionStatus),
      child: ExcludeSemantics(
        child: Material(
          key: key,
          color: AppColors.surfaceWarm.withValues(alpha: 0.92),
          borderRadius: AppRadius.compactCard,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppRadius.compactCard,
            child: Container(
              constraints: const BoxConstraints(minHeight: 88),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: AppRadius.compactCard,
                border: Border.all(color: AppColors.borderWarm),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          texts.parentTipLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          texts.parentTipTitle(completionStatus),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.textStrong,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          texts.parentTipSubtitle(completionStatus),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.brown500,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultGuardianTipButton extends StatelessWidget {
  const _ResultGuardianTipButton({
    required this.completionStatus,
    required this.onPressed,
  });

  final ActivityCompletionStatus completionStatus;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context).result;
    final isPositive = isPositiveResult(completionStatus);
    final key = ValueKey(
      isPositive
          ? 'completedResultGuardianTipButton'
          : 'incompleteResultGuardianTipButton',
    );

    return Semantics(
      button: true,
      label: texts.parentTipSemanticLabel(completionStatus),
      child: ExcludeSemantics(
        child: Tooltip(
          message: texts.parentTipSemanticLabel(completionStatus),
          child: Material(
            key: key,
            color: AppColors.white.withValues(alpha: 0.78),
            borderRadius: AppRadius.pill,
            child: InkWell(
              onTap: onPressed,
              borderRadius: AppRadius.pill,
              child: Container(
                height: 40,
                constraints: const BoxConstraints(maxWidth: 142),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.favorite_rounded : Icons.spa_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        texts.parentTipLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.brown700,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultBackground extends StatelessWidget {
  const _ResultBackground({required this.isPositive});

  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          final assetPath = isPositive
              ? (isLandscape
                    ? _successResultBackgroundLandscapePath
                    : _successResultBackgroundPortraitPath)
              : (isLandscape
                    ? _failedResultBackgroundLandscapePath
                    : _failedResultBackgroundPortraitPath);

          return Opacity(
            opacity: 0.60,
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }
}

class _CompactLandscapeResultLayout extends StatelessWidget {
  const _CompactLandscapeResultLayout({
    required this.completionStatus,
    required this.recordedSession,
    required this.activityProgressService,
    required this.orientationService,
    required this.failureRiderAssetPath,
    required this.vehicleId,
    required this.onRestart,
    required this.onHome,
  });

  final ActivityCompletionStatus completionStatus;
  final Future<RecordedActivitySession> recordedSession;
  final LocalActivityProgressService activityProgressService;
  final OrientationService orientationService;
  final String failureRiderAssetPath;
  final String vehicleId;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final theme = Theme.of(context);
    final isPositive = isPositiveResult(completionStatus);
    final isRewardable = isRewardableResult(completionStatus);

    return SizedBox.expand(
      child: Card(
        key: const ValueKey('compactLandscapeResultCard'),
        margin: EdgeInsets.zero,
        color: AppColors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: isRewardable
                    ? FutureBuilder<RecordedActivitySession>(
                        future: recordedSession,
                        builder: (context, snapshot) {
                          final recordedSession = snapshot.data;

                          return Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _RewardResultBox(
                                    rewards: recordedSession?.awardedRewards,
                                    isCompact: true,
                                  ),
                                  if (recordedSession != null &&
                                      (recordedSession
                                              .updatedRewardGoals
                                              .isNotEmpty ||
                                          recordedSession
                                              .earnedRewardGoals
                                              .isNotEmpty)) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    _RewardGoalResultBox(
                                      updatedGoals:
                                          recordedSession.updatedRewardGoals,
                                      earnedGoals:
                                          recordedSession.earnedRewardGoals,
                                      activityProgressService:
                                          activityProgressService,
                                      orientationService: orientationService,
                                      isCompact: true,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : !isPositive
                    ? Center(
                        child: _FailureRiderImage(
                          assetPath: failureRiderAssetPath,
                          maxSize: 220,
                          fallbackIconSize: 88,
                        ),
                      )
                    : const Center(child: _NeutralResultIcon()),
              ),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                flex: 6,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                texts.result.title(completionStatus),
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textStrong,
                                ),
                              ),
                            ),
                            _ResultGuardianTipButton(
                              completionStatus: completionStatus,
                              onPressed: () => _showResultHelpSheet(
                                context,
                                status: completionStatus,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          texts.result.primaryMessage(
                            completionStatus,
                            vehicleId: vehicleId,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          texts.result.secondaryMessage(completionStatus),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 54,
                                child: FilledButton.icon(
                                  onPressed: onRestart,
                                  icon: const Icon(Icons.two_wheeler_rounded),
                                  label: Text(texts.common.restartRide),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: SizedBox(
                                height: 54,
                                child: OutlinedButton.icon(
                                  onPressed: onHome,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.white,
                                    side: BorderSide.none,
                                  ),
                                  icon: const Icon(Icons.home_rounded),
                                  label: Text(texts.common.home),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FailureRiderImage extends StatelessWidget {
  const _FailureRiderImage({
    required this.assetPath,
    required this.maxSize,
    required this.fallbackIconSize,
  });

  final String assetPath;
  final double maxSize;
  final double fallbackIconSize;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxSize, maxHeight: maxSize),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.sentiment_satisfied_alt_rounded,
            color: AppColors.primary,
            size: fallbackIconSize,
          );
        },
      ),
    );
  }
}

class _NeutralResultIcon extends StatelessWidget {
  const _NeutralResultIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 132,
        height: 132,
        child: Icon(Icons.timer_rounded, color: AppColors.primary, size: 72),
      ),
    );
  }
}

class _RewardGoalResultBox extends StatelessWidget {
  const _RewardGoalResultBox({
    required this.updatedGoals,
    required this.earnedGoals,
    required this.activityProgressService,
    required this.orientationService,
    this.isCompact = false,
  });

  final List<RewardGoal> updatedGoals;
  final List<RewardGoal> earnedGoals;
  final LocalActivityProgressService activityProgressService;
  final OrientationService orientationService;
  final bool isCompact;

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
              SizedBox(height: isCompact ? AppSpacing.xs : AppSpacing.sm),
            ],
            if (justEarned && !isCompact) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () async {
                  await orientationService.lockPortrait();
                  if (!context.mounted) {
                    return;
                  }
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RewardGoalScreen(
                        activityProgressService: activityProgressService,
                      ),
                    ),
                  );
                  if (context.mounted) {
                    unawaited(orientationService.allowMealFlowOrientations());
                  }
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
      key: const ValueKey('resultIntroScreen'),
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
  const _RewardResultBox({
    required this.rewards,
    this.isCompact = false,
    this.isCondensed = false,
  });

  final List<RewardDefinition>? rewards;
  final bool isCompact;
  final bool isCondensed;

  @override
  Widget build(BuildContext context) {
    final rewards = this.rewards;
    final texts = AppTexts.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isCompact
            ? AppColors.surfaceYellow.withValues(alpha: 0.72)
            : AppColors.surfaceYellow,
        borderRadius: AppRadius.card,
        border: isCompact ? Border.all(color: AppColors.borderWarm) : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact
              ? AppSpacing.lg
              : isCondensed
              ? AppSpacing.lg
              : AppSpacing.xl,
          vertical: isCompact
              ? AppSpacing.md
              : isCondensed
              ? AppSpacing.md
              : AppSpacing.lg,
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
                spacing: isCompact
                    ? AppSpacing.md
                    : isCondensed
                    ? AppSpacing.md
                    : AppSpacing.lg,
                runSpacing: isCompact
                    ? AppSpacing.sm
                    : isCondensed
                    ? AppSpacing.md
                    : AppSpacing.lg,
                children: [
                  for (final reward in rewards)
                    _RewardBadge(
                      reward: reward,
                      isCompact: isCompact,
                      isCondensed: isCondensed,
                    ),
                ],
              ),
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({
    required this.reward,
    this.isCompact = false,
    this.isCondensed = false,
  });

  final RewardDefinition reward;
  final bool isCompact;
  final bool isCondensed;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final rewardName = texts.rewards.name(reward.id);

    if (isCompact) {
      return SizedBox(
        width: 196,
        height: 196,
        child: Stack(
          children: [
            const _RewardConfettiDot(
              alignment: Alignment(-0.74, -0.42),
              size: 8,
              color: AppColors.primarySoft,
            ),
            const _RewardConfettiDot(
              alignment: Alignment(0.74, -0.58),
              size: 10,
              color: AppColors.accentBlueSoft,
            ),
            const _RewardConfettiDot(
              alignment: Alignment(-0.56, 0.30),
              size: 7,
              color: AppColors.surfacePink,
            ),
            const _RewardConfettiSparkle(
              alignment: Alignment(0.60, 0.22),
              color: AppColors.orange,
            ),
            Positioned(
              left: 0,
              top: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.86),
                  borderRadius: AppRadius.pill,
                  border: Border.all(color: AppColors.borderWarm),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    '+1',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.74),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: RewardStickerImage(
                        reward: reward,
                        semanticLabel: rewardName,
                        size: 78,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    rewardName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final stickerSize = isCondensed ? 58.0 : 64.0;
    return SizedBox(
      width: isCondensed ? 104 : 116,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RewardStickerImage(
            reward: reward,
            semanticLabel: rewardName,
            size: stickerSize,
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

class _RewardConfettiDot extends StatelessWidget {
  const _RewardConfettiDot({
    required this.alignment,
    required this.size,
    required this.color,
  });

  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.68),
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(dimension: size),
      ),
    );
  }
}

class _RewardConfettiSparkle extends StatelessWidget {
  const _RewardConfettiSparkle({required this.alignment, required this.color});

  final Alignment alignment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Icon(
        Icons.auto_awesome_rounded,
        color: color.withValues(alpha: 0.32),
        size: 24,
      ),
    );
  }
}
