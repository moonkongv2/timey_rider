import 'dart:async';

import 'package:flutter/material.dart';

import '../catalogs/vehicle_catalog.dart';
import '../controllers/meal_timer_controller.dart';
import '../l10n/app_texts.dart';
import '../l10n/text_sets.dart';
import '../models/meal_session_result.dart';
import '../models/meal_timer_config.dart';
import '../services/local_meal_progress_service.dart';
import '../services/screen_awake_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../utils/duration_format.dart';
import '../widgets/road_painter.dart';
import '../widgets/road_view.dart';
import '../widgets/timer_control_bar.dart';
import 'result_screen.dart';

const _fallbackMotivationVideoPath = 'assets/videos/motivation_10.mp4';
const _landscapeCourseCanvasSize = Size(1200, 520);

const _motivationVideoVehicleIds = {
  'motorcycle',
  'fire_truck',
  'police_car',
  'excavator',
};

String? motivationVideoAssetPathForVehicle({
  required String vehicleId,
  required int milestone,
}) {
  if (milestone < 10 || milestone > 90 || milestone % 10 != 0) {
    return null;
  }

  final videoNumber = milestone ~/ 10;
  if (!_motivationVideoVehicleIds.contains(vehicleId)) {
    return _fallbackMotivationVideoPath;
  }

  return 'assets/videos/motivation_${vehicleId}_$videoNumber.mp4';
}

int? nextMotivationMilestoneForProgress(
  double progress,
  Set<int> shownMilestones,
) {
  if (progress <= 0 || progress >= 1) {
    return null;
  }

  final reachedPercent = (progress * 100).floor();
  for (var milestone = 10; milestone <= 90; milestone += 10) {
    if (reachedPercent >= milestone && !shownMilestones.contains(milestone)) {
      return milestone;
    }
  }

  return null;
}

String timerArrivalDialogMessage({
  required TimerTextSet texts,
  required String vehicleId,
  required String languageCode,
}) {
  final vehicle = VehicleCatalog.findById(vehicleId);
  final vehicleLabel = vehicle.labelForLanguage(languageCode);
  return texts.arrivalDialogMessage(vehicleLabel);
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({
    super.key,
    required this.config,
    required this.mealProgressService,
    required this.onConfigChanged,
    this.screenAwakeService = const WakelockScreenAwakeService(),
  });

  final MealTimerConfig config;
  final LocalMealProgressService mealProgressService;
  final ValueChanged<MealTimerConfig> onConfigChanged;
  final ScreenAwakeService screenAwakeService;

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
  bool _screenAwakeEnabled = false;
  bool _exitPromptShown = false;
  bool _allowExit = false;
  int? _activeMotivationMilestone;
  String? _activeMotivationVideoPath;

  @override
  void initState() {
    super.initState();
    _controller = MealTimerController(config: widget.config);
    _controller.addListener(_handleTimerChanged);
    _controller.start();
    _applyScreenAwakeSetting();
  }

  @override
  void didUpdateWidget(covariant TimerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenAwakeService != widget.screenAwakeService &&
        _screenAwakeEnabled) {
      unawaited(oldWidget.screenAwakeService.setEnabled(false));
      _screenAwakeEnabled = false;
    }
    _applyScreenAwakeSetting();
  }

  @override
  void dispose() {
    if (_screenAwakeEnabled) {
      unawaited(widget.screenAwakeService.setEnabled(false));
    }
    _controller.dispose();
    super.dispose();
  }

  void _applyScreenAwakeSetting() {
    final shouldKeepAwake = widget.config.keepScreenAwake;
    if (_screenAwakeEnabled == shouldKeepAwake) {
      return;
    }
    _screenAwakeEnabled = shouldKeepAwake;
    unawaited(widget.screenAwakeService.setEnabled(shouldKeepAwake));
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
    if (!mounted || _activeMotivationMilestone != null) {
      return;
    }

    final milestone = nextMotivationMilestoneForProgress(
      _controller.progress,
      _shownMotivationMilestones,
    );
    if (milestone == null) {
      return;
    }

    final videoPath = motivationVideoAssetPathForVehicle(
      vehicleId: widget.config.motorcycleId,
      milestone: milestone,
    );
    if (videoPath == null) {
      return;
    }

    _shownMotivationMilestones.add(milestone);
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

  Future<void> _confirmExit() async {
    if (_exitPromptShown || _allowExit || !mounted) {
      return;
    }

    _exitPromptShown = true;
    final shouldResumeAfterPrompt =
        _controller.state == MealTimerState.running ||
        _controller.state == MealTimerState.arrived;
    if (shouldResumeAfterPrompt) {
      _controller.pause();
    }

    final route = ModalRoute.of(context);
    final texts = AppTexts.of(context);
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(texts.timer.exitDialogTitle),
          content: Text(texts.timer.exitDialogMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(texts.timer.exitDialogCancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(texts.timer.exitDialogConfirmButton),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    _exitPromptShown = false;
    if (shouldExit == true) {
      _allowExit = true;
      final navigator = Navigator.of(context);
      if (route != null && navigator.canPop()) {
        navigator.removeRoute(route);
      }
      return;
    }

    if (shouldResumeAfterPrompt && _controller.isPaused) {
      _controller.resume();
    }
  }

  Future<void> _confirmComplete({bool showFailureOnDecline = false}) async {
    final texts = AppTexts.of(context);
    final arrivalDialogMessage = timerArrivalDialogMessage(
      texts: texts.timer,
      vehicleId: widget.config.motorcycleId,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !showFailureOnDecline,
      builder: (context) {
        return AlertDialog(
          title: Text(texts.timer.completeDialogTitle),
          content: Text(
            showFailureOnDecline
                ? arrivalDialogMessage
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
        final vehicleAvatarMode = widget.config.avatarModeForVehicle(
          vehicle.id,
        );
        final vehicleAvatarImagePath = widget.config
            .customAvatarImagePathForVehicle(vehicle.id);
        final vehicleAvatarConfig = widget.config.customAvatarConfigForVehicle(
          vehicle.id,
        );
        final progress = _controller.progress.clamp(0.0, 1.0).toDouble();
        final statusCopy = _timerStatusCopy(
          texts.timer,
          _controller.state,
          progress,
        );
        void handlePauseResume() {
          if (_controller.isPaused) {
            _controller.resume();
          } else {
            _controller.pause();
          }
        }

        final isScreenLandscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;

        return PopScope(
          canPop: _allowExit,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _confirmExit();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.cream,
            appBar: isScreenLandscape
                ? null
                : AppBar(
                    title: Text(texts.timer.courseTitle),
                    backgroundColor: AppColors.cream,
                    foregroundColor: AppColors.brown900,
                    elevation: 0,
                  ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape =
                      constraints.maxWidth > constraints.maxHeight;
                  final roadView = RoadView(
                    progress: progress,
                    vehicle: vehicle,
                    avatarMode: vehicleAvatarMode,
                    customAvatarImagePath: vehicleAvatarImagePath,
                    avatarScale: vehicleAvatarConfig?.scale ?? 1.0,
                    avatarOffsetX: vehicleAvatarConfig?.offsetX ?? 0.0,
                    avatarOffsetY: vehicleAvatarConfig?.offsetY ?? 0.0,
                    avatarRotationDegrees:
                        vehicleAvatarConfig?.rotationDegrees ?? 0.0,
                    motivationVideoAssetPath: _activeMotivationVideoPath,
                    motivationVideoMilestone: _activeMotivationMilestone,
                    onMotivationVideoFinished: _handleMotivationVideoFinished,
                    showVehicle: !isLandscape,
                    showMotivationVideo: !isLandscape,
                  );
                  final landscapeVehicleLayer = isLandscape
                      ? RoadVehicleLayer(
                          progress: progress,
                          vehicle: vehicle,
                          avatarMode: vehicleAvatarMode,
                          customAvatarImagePath: vehicleAvatarImagePath,
                          avatarScale: vehicleAvatarConfig?.scale ?? 1.0,
                          avatarOffsetX: vehicleAvatarConfig?.offsetX ?? 0.0,
                          avatarOffsetY: vehicleAvatarConfig?.offsetY ?? 0.0,
                          avatarRotationDegrees:
                              vehicleAvatarConfig?.rotationDegrees ?? 0.0,
                        )
                      : null;
                  final landscapeMotivationVideoLayer =
                      isLandscape &&
                          _activeMotivationVideoPath != null &&
                          _activeMotivationMilestone != null
                      ? RoadMotivationVideoLayer(
                          assetPath: _activeMotivationVideoPath!,
                          milestone: _activeMotivationMilestone!,
                          onFinished: _handleMotivationVideoFinished,
                        )
                      : null;
                  final remainingTimeCard = widget.config.showRemainingTime
                      ? _RemainingTimeCard(
                          label: statusCopy.timeLabel,
                          remaining: _controller.remaining,
                          icon: statusCopy.icon,
                          iconBackgroundColor: statusCopy.iconBackgroundColor,
                          semanticLabel: texts.timer.remainingTimeSemanticLabel(
                            statusCopy.timeLabel,
                            formatDuration(_controller.remaining),
                          ),
                          isCompact: isLandscape,
                        )
                      : null;

                  if (isLandscape) {
                    return _LandscapeTimerLayout(
                      progressCard: _ProgressMessageCard(
                        message: statusCopy.progressMessage,
                        progress: progress,
                        isCompact: true,
                      ),
                      remainingTimeBadge: widget.config.showRemainingTime
                          ? _RemainingTimeBadge(
                              label: statusCopy.timeLabel,
                              remaining: _controller.remaining,
                              icon: statusCopy.icon,
                              iconBackgroundColor:
                                  statusCopy.iconBackgroundColor,
                              semanticLabel: texts.timer
                                  .remainingTimeSemanticLabel(
                                    statusCopy.timeLabel,
                                    formatDuration(_controller.remaining),
                                  ),
                            )
                          : null,
                      roadView: roadView,
                      vehicleLayer: landscapeVehicleLayer,
                      motivationVideoLayer: landscapeMotivationVideoLayer,
                      onBack: _confirmExit,
                      controls: TimerControlBar(
                        isPaused: _controller.isPaused,
                        onPauseResume: handlePauseResume,
                        onComplete: _confirmComplete,
                      ),
                    );
                  }

                  return Padding(
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
                        Expanded(child: roadView),
                        if (remainingTimeCard != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          remainingTimeCard,
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        TimerControlBar(
                          isPaused: _controller.isPaused,
                          onPauseResume: handlePauseResume,
                          onComplete: _confirmComplete,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LandscapeTimerLayout extends StatelessWidget {
  const _LandscapeTimerLayout({
    required this.progressCard,
    required this.remainingTimeBadge,
    required this.roadView,
    required this.vehicleLayer,
    required this.motivationVideoLayer,
    required this.onBack,
    required this.controls,
  });

  final Widget progressCard;
  final Widget? remainingTimeBadge;
  final Widget roadView;
  final Widget? vehicleLayer;
  final Widget? motivationVideoLayer;
  final VoidCallback onBack;
  final Widget controls;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final courseViewportHeight = (constraints.maxHeight - AppSpacing.xl)
              .clamp(360.0, 620.0)
              .toDouble();

          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: courseViewportHeight,
                  child: Center(
                    child: _LandscapeCourseCanvas(
                      progressCard: progressCard,
                      remainingTimeBadge: remainingTimeBadge,
                      roadView: roadView,
                      vehicleLayer: vehicleLayer,
                      motivationVideoLayer: motivationVideoLayer,
                      onBack: onBack,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                controls,
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LandscapeCourseCanvas extends StatelessWidget {
  const _LandscapeCourseCanvas({
    required this.progressCard,
    required this.remainingTimeBadge,
    required this.roadView,
    required this.vehicleLayer,
    required this.motivationVideoLayer,
    required this.onBack,
  });

  final Widget progressCard;
  final Widget? remainingTimeBadge;
  final Widget roadView;
  final Widget? vehicleLayer;
  final Widget? motivationVideoLayer;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final roadBounds = createRoadBounds(_landscapeCourseCanvasSize);

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: _landscapeCourseCanvasSize.width,
        height: _landscapeCourseCanvasSize.height,
        child: Stack(
          children: [
            Positioned.fill(child: roadView),
            if (remainingTimeBadge == null)
              Positioned(
                left: roadBounds.left,
                top: AppSpacing.md,
                right: _landscapeCourseCanvasSize.width - roadBounds.right,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 588),
                    child: progressCard,
                  ),
                ),
              )
            else
              Positioned(
                left: roadBounds.left,
                right:
                    _landscapeCourseCanvasSize.width -
                    roadBounds.right +
                    360 +
                    AppSpacing.md,
                top: AppSpacing.md,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 588),
                    child: progressCard,
                  ),
                ),
              ),
            if (vehicleLayer != null) Positioned.fill(child: vehicleLayer!),
            if (motivationVideoLayer != null)
              Positioned.fill(child: motivationVideoLayer!),
            Positioned(
              left: AppSpacing.md,
              top: AppSpacing.md,
              child: _LandscapeBackButton(onPressed: onBack),
            ),
            if (remainingTimeBadge != null)
              Positioned(
                right: _landscapeCourseCanvasSize.width - roadBounds.right,
                top: AppSpacing.md,
                child: remainingTimeBadge!,
              ),
          ],
        ),
      ),
    );
  }
}

class _LandscapeBackButton extends StatelessWidget {
  const _LandscapeBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm.withValues(alpha: 0.92),
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.surface,
      ),
      child: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: const Icon(Icons.arrow_back_rounded),
        color: AppColors.brown700,
        iconSize: 24,
        onPressed: onPressed,
      ),
    );
  }
}

class _ProgressMessageCard extends StatelessWidget {
  const _ProgressMessageCard({
    required this.message,
    required this.progress,
    this.isCompact = false,
  });

  final String message;
  final double progress;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final iconSize = isCompact ? 40.0 : 36.0;
    final messageStyle = textTheme.titleMedium?.copyWith(
      color: AppColors.brown900,
      fontSize: isCompact ? 23 : null,
      fontWeight: FontWeight.w800,
    );

    if (isCompact) {
      return DecoratedBox(
        key: const ValueKey('timerProgressMessageCard'),
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
                child: SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: const Center(
                    child: Text(
                      '🏁',
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(fontSize: 26, height: 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: messageStyle,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.pill,
                  child: LinearProgressIndicator(
                    key: const ValueKey('timerProgressIndicator'),
                    value: progress,
                    minHeight: 7,
                    backgroundColor: AppColors.borderSoft,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: AppShadows.surface,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? AppSpacing.md : AppSpacing.md,
          vertical: isCompact ? AppSpacing.md : AppSpacing.sm,
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceYellow.withValues(alpha: 0.78),
                borderRadius: AppRadius.pill,
                border: Border.all(color: AppColors.white),
              ),
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: Center(
                  child: Text(
                    '🏁',
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(fontSize: isCompact ? 26 : 20, height: 1),
                  ),
                ),
              ),
            ),
            SizedBox(width: isCompact ? AppSpacing.sm : AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, style: messageStyle),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: AppRadius.pill,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: isCompact ? 7 : 6,
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

class _RemainingTimeBadge extends StatelessWidget {
  const _RemainingTimeBadge({
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
      child: SizedBox(
        key: const ValueKey('remainingTimeBadge'),
        width: 360,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm.withValues(alpha: 0.68),
            borderRadius: AppRadius.pill,
            border: Border.all(color: AppColors.white.withValues(alpha: 0.72)),
            boxShadow: AppShadows.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: AppRadius.pill,
                  ),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(icon, color: AppColors.brown700, size: 26),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textStrong,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  formattedRemaining,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textStrong,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
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

class _RemainingTimeCard extends StatelessWidget {
  const _RemainingTimeCard({
    required this.label,
    required this.remaining,
    required this.icon,
    required this.iconBackgroundColor,
    required this.semanticLabel,
    this.isCompact = false,
  });

  final String label;
  final Duration remaining;
  final IconData icon;
  final Color iconBackgroundColor;
  final String semanticLabel;
  final bool isCompact;

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
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? AppSpacing.md : AppSpacing.lg,
            vertical: isCompact ? AppSpacing.sm : AppSpacing.md,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: isCompact ? 48 : 58),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      isCompact ? AppSpacing.xs : AppSpacing.sm,
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.brown700,
                      size: isCompact ? 22 : 24,
                    ),
                  ),
                ),
                SizedBox(width: isCompact ? AppSpacing.sm : AppSpacing.md),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style:
                              (isCompact
                                      ? textTheme.titleMedium
                                      : textTheme.headlineSmall)
                                  ?.copyWith(
                                    color: AppColors.textStrong,
                                    fontWeight: FontWeight.w900,
                                    height: 1.04,
                                  ),
                        ),
                      ),
                      SizedBox(
                        width: isCompact ? AppSpacing.xs : AppSpacing.sm,
                      ),
                      Text(
                        formattedRemaining,
                        style:
                            (isCompact
                                    ? textTheme.titleMedium
                                    : textTheme.headlineSmall)
                                ?.copyWith(
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
