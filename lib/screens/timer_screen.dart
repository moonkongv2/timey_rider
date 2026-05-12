import 'package:flutter/material.dart';

import '../catalogs/vehicle_catalog.dart';
import '../controllers/meal_timer_controller.dart';
import '../l10n/app_texts.dart';
import '../l10n/text_sets.dart';
import '../models/meal_session_result.dart';
import '../models/meal_timer_config.dart';
import '../services/local_meal_progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../utils/duration_format.dart';
import '../widgets/road_view.dart';
import '../widgets/timer_control_bar.dart';
import 'result_screen.dart';

const _motivationVideoByMilestone = {
  10: 'assets/videos/motivation_10.mp4',
  20: 'assets/videos/motivation_10.mp4',
  30: 'assets/videos/motivation_10.mp4',
  40: 'assets/videos/motivation_10.mp4',
  50: 'assets/videos/motivation_10.mp4',
  60: 'assets/videos/motivation_10.mp4',
  70: 'assets/videos/motivation_10.mp4',
  80: 'assets/videos/motivation_10.mp4',
  90: 'assets/videos/motivation_10.mp4',
  // 20: 'assets/videos/motivation_20.mp4',
  // 30: 'assets/videos/motivation_30.mp4',
  // 40: 'assets/videos/motivation_40.mp4',
  // 50: 'assets/videos/motivation_50.mp4',
  // 60: 'assets/videos/motivation_60.mp4',
  // 70: 'assets/videos/motivation_70.mp4',
  // 80: 'assets/videos/motivation_80.mp4',
  // 90: 'assets/videos/motivation_90.mp4',
};

class TimerScreen extends StatefulWidget {
  const TimerScreen({
    super.key,
    required this.config,
    required this.mealProgressService,
    required this.onConfigChanged,
  });

  final MealTimerConfig config;
  final LocalMealProgressService mealProgressService;
  final ValueChanged<MealTimerConfig> onConfigChanged;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerStatusCopy {
  const _TimerStatusCopy({
    required this.progressMessage,
    required this.timeLabel,
    required this.icon,
    required this.iconBackgroundColor,
  });

  final String progressMessage;
  final String timeLabel;
  final IconData icon;
  final Color iconBackgroundColor;
}

class _TimerScreenState extends State<TimerScreen> {
  late final MealTimerController _controller;
  final Set<int> _shownMotivationMilestones = {};
  bool _arrivalPromptShown = false;
  int? _activeMotivationMilestone;
  String? _activeMotivationVideoPath;

  @override
  void initState() {
    super.initState();
    _controller = MealTimerController(config: widget.config);
    _controller.addListener(_handleTimerChanged);
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTimerChanged() {
    _maybeShowMotivationVideo();

    if (_arrivalPromptShown ||
        _controller.state != MealTimerState.arrived ||
        !mounted) {
      return;
    }

    _arrivalPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) {
        return;
      }
      _confirmComplete(showFailureOnDecline: true);
    });
  }

  void _maybeShowMotivationVideo() {
    if (!mounted || _controller.progress >= 1) {
      return;
    }

    final milestone = (_controller.progress * 10).floor() * 10;
    if (milestone < 10 || milestone > 90) {
      return;
    }

    if (!_shownMotivationMilestones.add(milestone)) {
      return;
    }

    if (_activeMotivationMilestone != null) {
      return;
    }

    final videoPath = _motivationVideoByMilestone[milestone];
    if (videoPath == null) {
      return;
    }

    setState(() {
      _activeMotivationMilestone = milestone;
      _activeMotivationVideoPath = videoPath;
    });
  }

  void _handleMotivationVideoFinished() {
    if (!mounted || _activeMotivationMilestone == null) {
      return;
    }

    setState(() {
      _activeMotivationMilestone = null;
      _activeMotivationVideoPath = null;
    });
  }

  Future<void> _confirmComplete({bool showFailureOnDecline = false}) async {
    final texts = AppTexts.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !showFailureOnDecline,
      builder: (context) {
        return AlertDialog(
          title: Text(texts.timer.completeDialogTitle),
          content: Text(
            showFailureOnDecline
                ? texts.timer.arrivalDialogMessage
                : texts.timer.completeDialogMessage,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(texts.common.notYet),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(texts.common.complete),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (confirmed != true) {
      if (showFailureOnDecline) {
        final result = _controller.complete(mealCompleted: false);
        _openResult(result);
      }
      return;
    }

    final result = _controller.complete();
    _openResult(result);
  }

  void _openResult(MealSessionResult result) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          result: result,
          config: widget.config,
          mealProgressService: widget.mealProgressService,
          onConfigChanged: widget.onConfigChanged,
        ),
      ),
    );
  }

  String _runningProgressMessage(TimerTextSet texts, double progress) {
    if (progress < 0.25) {
      return texts.progressJustStarted;
    }
    if (progress < 0.5) {
      return texts.progressGoingWell;
    }
    if (progress < 0.8) {
      return texts.progressPastHalfway;
    }
    if (progress < 1.0) {
      return texts.progressAlmostThere;
    }
    return texts.progressArrived;
  }

  _TimerStatusCopy _timerStatusCopy(
    TimerTextSet texts,
    MealTimerState state,
    double progress,
  ) {
    return switch (state) {
      MealTimerState.running => _TimerStatusCopy(
        progressMessage: _runningProgressMessage(texts, progress),
        timeLabel: texts.runningArrivalLabel,
        icon: Icons.directions_rounded,
        iconBackgroundColor: AppColors.surfaceMint,
      ),
      MealTimerState.paused => _TimerStatusCopy(
        progressMessage: texts.pausedProgressMessage,
        timeLabel: texts.pausedTimeLabel,
        icon: Icons.local_cafe_rounded,
        iconBackgroundColor: AppColors.surfaceYellow,
      ),
      MealTimerState.arrived || MealTimerState.completed => _TimerStatusCopy(
        progressMessage: texts.arrivedProgressMessage,
        timeLabel: texts.arrivedTimeLabel,
        icon: Icons.flag_rounded,
        iconBackgroundColor: AppColors.primarySoft,
      ),
      MealTimerState.idle => _TimerStatusCopy(
        progressMessage: texts.idleProgressMessage,
        timeLabel: texts.idleTimeLabel,
        icon: Icons.timer_rounded,
        iconBackgroundColor: AppColors.surfaceWarm,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final vehicle = VehicleCatalog.findById(widget.config.motorcycleId);
        final progress = _controller.progress.clamp(0.0, 1.0).toDouble();
        final statusCopy = _timerStatusCopy(
          texts.timer,
          _controller.state,
          progress,
        );

        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            title: Text(texts.timer.courseTitle),
            backgroundColor: AppColors.cream,
            foregroundColor: AppColors.brown900,
            elevation: 0,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xs,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                children: [
                  _ProgressMessageCard(
                    message: statusCopy.progressMessage,
                    progress: progress,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: RoadView(
                      progress: progress,
                      vehicle: vehicle,
                      motivationVideoAssetPath: _activeMotivationVideoPath,
                      motivationVideoMilestone: _activeMotivationMilestone,
                      onMotivationVideoFinished: _handleMotivationVideoFinished,
                    ),
                  ),
                  if (widget.config.showRemainingTime) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _RemainingTimeCard(
                      label: statusCopy.timeLabel,
                      remaining: _controller.remaining,
                      icon: statusCopy.icon,
                      iconBackgroundColor: statusCopy.iconBackgroundColor,
                      semanticLabel: texts.timer.remainingTimeSemanticLabel(
                        statusCopy.timeLabel,
                        formatDuration(_controller.remaining),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  TimerControlBar(
                    isPaused: _controller.isPaused,
                    onPauseResume: () {
                      if (_controller.isPaused) {
                        _controller.resume();
                      } else {
                        _controller.pause();
                      }
                    },
                    onComplete: _confirmComplete,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressMessageCard extends StatelessWidget {
  const _ProgressMessageCard({required this.message, required this.progress});

  final String message;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: AppShadows.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceYellow.withValues(alpha: 0.78),
                borderRadius: AppRadius.pill,
                border: Border.all(color: AppColors.white),
              ),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Text(
                    '🏁',
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(fontSize: 20, height: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.brown900,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: AppRadius.pill,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.borderSoft,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemainingTimeCard extends StatelessWidget {
  const _RemainingTimeCard({
    required this.label,
    required this.remaining,
    required this.icon,
    required this.iconBackgroundColor,
    required this.semanticLabel,
  });

  final String label;
  final Duration remaining;
  final IconData icon;
  final Color iconBackgroundColor;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final formattedRemaining = formatDuration(remaining);

    return Semantics(
      label: semanticLabel,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: AppShadows.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 58),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Icon(icon, color: AppColors.brown700),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.headlineSmall?.copyWith(
                            color: AppColors.textStrong,
                            fontWeight: FontWeight.w900,
                            height: 1.04,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        formattedRemaining,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.textStrong,
                          fontWeight: FontWeight.w900,
                          height: 1.04,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
