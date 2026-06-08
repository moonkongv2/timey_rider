import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../catalogs/meal_ingredient_catalog.dart';
import '../catalogs/motivation_asset_catalog.dart';
import '../catalogs/vehicle_catalog.dart';
import '../controllers/meal_timer_controller.dart';
import '../l10n/app_texts.dart';
import '../l10n/text_sets.dart';
import '../models/meal_completion_status.dart';
import '../models/meal_session_result.dart';
import '../models/meal_timer_config.dart';
import '../models/vehicle_avatar_presentation.dart';
import '../services/local_meal_progress_service.dart';
import '../services/motivation_audio_service.dart';
import '../services/orientation_service.dart';
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

const _landscapeCourseCanvasSize = Size(1200, 520);
const _compactLandscapeControlsWidth = 72.0;
const _compactLandscapeControlsRightInset =
    _compactLandscapeControlsWidth + AppSpacing.xl;
const motivationMinimumVideoInterval = Duration(seconds: 10);
const motivationVoiceStartDelay = Duration(milliseconds: 350);

Duration finishDriveDurationForProgress(double startProgress) {
  final remainingProgress = 1 - startProgress.clamp(0.0, 1.0).toDouble();
  final milliseconds = 800 + (3200 * remainingProgress);
  return Duration(milliseconds: milliseconds.round());
}

String? motivationVideoAssetPathForVehicle({
  required String vehicleId,
  required int milestone,
  int Function(int max)? nextInt,
}) {
  if (milestone < 10 || milestone > 90 || milestone % 10 != 0) {
    return null;
  }

  return MotivationAssetCatalog.videoPathForVehicle(
    vehicleId,
    nextInt: nextInt,
  );
}

bool canShowMotivationVideoAt({
  required Duration elapsed,
  required Duration? lastShownAt,
  Duration minimumInterval = motivationMinimumVideoInterval,
}) {
  if (lastShownAt == null) {
    return elapsed >= minimumInterval;
  }

  return elapsed - lastShownAt >= minimumInterval;
}

String? motivationVoiceAssetPathForVehicle({
  required bool soundEnabled,
  required String vehicleId,
  required String languageCode,
  int Function(int max)? nextInt,
}) {
  if (!soundEnabled) {
    return null;
  }

  return MotivationAssetCatalog.voicePathForVehicle(
    vehicleId: vehicleId,
    languageCode: languageCode,
    nextInt: nextInt,
  );
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
    this.orientationService = const SystemOrientationService(),
    this.motivationAudioService,
    this.now,
  });

  final MealTimerConfig config;
  final LocalMealProgressService mealProgressService;
  final ValueChanged<MealTimerConfig> onConfigChanged;
  final ScreenAwakeService screenAwakeService;
  final OrientationService orientationService;
  final MotivationAudioService? motivationAudioService;
  final DateTime Function()? now;

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

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  late final MealTimerController _controller;
  late final AnimationController _finishDriveController;
  late final MotivationAudioService _motivationAudioService;
  late final bool _ownsMotivationAudioService;
  final math.Random _motivationRandom = math.Random();
  final Set<int> _shownMotivationMilestones = {};
  bool _arrivalPromptShown = false;
  bool _screenAwakeEnabled = false;
  bool _exitPromptShown = false;
  bool _allowExit = false;
  int? _activeMotivationMilestone;
  String? _activeMotivationVideoPath;
  Duration? _lastMotivationVideoShownAt;
  Timer? _motivationVoiceTimer;
  Timer? _arrivalPromptTimer;
  bool _isFinishDriving = false;
  Animation<double>? _finishDriveAnimation;
  MealSessionResult? _pendingFinishDriveResult;
  double _finishDriveStartProgress = 0;
  bool _handoffOrientation = false;

  @override
  void initState() {
    super.initState();
    _motivationAudioService =
        widget.motivationAudioService ?? AudioplayersMotivationAudioService();
    _ownsMotivationAudioService = widget.motivationAudioService == null;
    _controller = MealTimerController(config: widget.config, now: widget.now);
    _controller.addListener(_handleTimerChanged);
    _finishDriveController = AnimationController(vsync: this)
      ..addStatusListener(_handleFinishDriveStatusChanged);
    _controller.start();
    unawaited(widget.orientationService.allowMealFlowOrientations());
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
    _motivationVoiceTimer?.cancel();
    _arrivalPromptTimer?.cancel();
    unawaited(_disposeMotivationAudioService());
    if (!_handoffOrientation) {
      unawaited(widget.orientationService.lockPortrait());
    }
    if (_screenAwakeEnabled) {
      unawaited(widget.screenAwakeService.setEnabled(false));
    }
    _finishDriveController
      ..removeStatusListener(_handleFinishDriveStatusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _disposeMotivationAudioService() async {
    await _motivationAudioService.stop();
    if (_ownsMotivationAudioService) {
      await _motivationAudioService.dispose();
    }
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
    if (_isFinishDriving) {
      return;
    }

    _maybeShowMotivationVideo();

    if (_arrivalPromptShown ||
        _controller.state != MealTimerState.arrived ||
        !mounted) {
      return;
    }

    _arrivalPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _arrivalPromptTimer?.cancel();
      _arrivalPromptTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted ||
            _isFinishDriving ||
            _controller.state != MealTimerState.arrived) {
          return;
        }
        _confirmComplete(showFailureOnDecline: true);
      });
    });
  }

  void _maybeShowMotivationVideo() {
    if (!mounted || _isFinishDriving || _activeMotivationMilestone != null) {
      return;
    }

    final milestone = nextMotivationMilestoneForProgress(
      _controller.progress,
      _shownMotivationMilestones,
    );
    if (milestone == null) {
      return;
    }
    if (!canShowMotivationVideoAt(
      elapsed: _controller.elapsed,
      lastShownAt: _lastMotivationVideoShownAt,
    )) {
      return;
    }

    final videoPath = motivationVideoAssetPathForVehicle(
      vehicleId: widget.config.vehicleId,
      milestone: milestone,
      nextInt: _motivationRandom.nextInt,
    );
    if (videoPath == null) {
      return;
    }

    _shownMotivationMilestones.add(milestone);
    _lastMotivationVideoShownAt = _controller.elapsed;
    setState(() {
      _activeMotivationMilestone = milestone;
      _activeMotivationVideoPath = videoPath;
    });
    _scheduleMotivationVoice();
  }

  void _scheduleMotivationVoice() {
    _motivationVoiceTimer?.cancel();
    _motivationVoiceTimer = Timer(motivationVoiceStartDelay, () {
      if (!mounted) {
        return;
      }
      _maybePlayMotivationVoice();
    });
  }

  void _maybePlayMotivationVoice() {
    if (!widget.config.soundEnabled) {
      return;
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    final voicePath = motivationVoiceAssetPathForVehicle(
      soundEnabled: widget.config.soundEnabled,
      vehicleId: widget.config.vehicleId,
      languageCode: languageCode,
      nextInt: _motivationRandom.nextInt,
    );
    if (voicePath == null) {
      return;
    }
    unawaited(_playMotivationVoice(voicePath));
  }

  Future<void> _playMotivationVoice(String voicePath) async {
    try {
      await _motivationAudioService.playAsset(voicePath);
    } catch (error, stackTrace) {
      debugPrint('Unable to play motivation voice $voicePath: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
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
    if (_exitPromptShown || _allowExit || _isFinishDriving || !mounted) {
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
    if (_isFinishDriving) {
      return;
    }
    _arrivalPromptTimer?.cancel();

    final texts = AppTexts.of(context);
    final arrivalDialogMessage = timerArrivalDialogMessage(
      texts: texts.timer,
      vehicleId: widget.config.vehicleId,
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
        final result = _controller.complete(
          mealCompleted: false,
          completionStatus: MealCompletionStatus.notCompleted,
        );
        _openResult(result);
      }
      return;
    }

    final result = _controller.complete(
      completionStatus: showFailureOnDecline
          ? MealCompletionStatus.completedAtArrival
          : null,
    );
    if (result.completedBeforeArrival) {
      _startFinishDrive(result);
      return;
    }
    _openResult(result);
  }

  void _startFinishDrive(MealSessionResult result) {
    _motivationVoiceTimer?.cancel();
    unawaited(_motivationAudioService.stop());

    _finishDriveStartProgress = _controller.progress.clamp(0.0, 1.0).toDouble();
    _pendingFinishDriveResult = result;
    _finishDriveController
      ..stop()
      ..duration = finishDriveDurationForProgress(_finishDriveStartProgress)
      ..reset();
    _finishDriveAnimation =
        Tween<double>(begin: _finishDriveStartProgress, end: 1).animate(
          CurvedAnimation(
            parent: _finishDriveController,
            curve: Curves.easeInOutCubic,
          ),
        );

    setState(() {
      _isFinishDriving = true;
      _activeMotivationMilestone = null;
      _activeMotivationVideoPath = null;
    });
    _finishDriveController.forward();
  }

  void _handleFinishDriveStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_isFinishDriving) {
      return;
    }

    final result = _pendingFinishDriveResult;
    _pendingFinishDriveResult = null;
    if (result != null && mounted) {
      _openResult(result);
    }
  }

  void _openResult(MealSessionResult result) {
    _handoffOrientation = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          result: result,
          config: widget.config,
          mealProgressService: widget.mealProgressService,
          onConfigChanged: widget.onConfigChanged,
          orientationService: widget.orientationService,
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
    if (_isFinishDriving) {
      return _TimerStatusCopy(
        progressMessage: texts.finishDriveProgressMessage,
        timeLabel: texts.finishDriveTimeLabel,
        icon: Icons.flag_rounded,
        iconBackgroundColor: AppColors.primarySoft,
      );
    }

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
      animation: Listenable.merge([_controller, _finishDriveController]),
      builder: (context, _) {
        final vehicle = VehicleCatalog.findById(widget.config.vehicleId);
        final vehicleAvatar = widget.config.avatarPresentationForVehicle(
          vehicle.id,
        );
        final courseIngredients = MealIngredientCatalog.courseSlotsFor(
          widget.config.courseIngredientIds,
          slotCount: MealIngredientCatalog.courseSlotCountForDuration(
            widget.config.duration,
          ),
        );
        final timerProgress = _controller.progress.clamp(0.0, 1.0).toDouble();
        final displayProgress = _isFinishDriving
            ? (_finishDriveAnimation?.value ?? _finishDriveStartProgress)
                  .clamp(0.0, 1.0)
                  .toDouble()
            : timerProgress;
        final statusCopy = _timerStatusCopy(
          texts.timer,
          _controller.state,
          displayProgress,
        );
        void handlePauseResume() {
          if (_isFinishDriving) {
            return;
          }
          if (_controller.isPaused) {
            _controller.resume();
          } else {
            _controller.pause();
          }
        }

        final isScreenLandscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final displayedRemaining = _isFinishDriving
            ? Duration.zero
            : _controller.remaining;

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
                  final reservesCompactControlsSpace =
                      isLandscape &&
                      constraints.maxHeight - AppSpacing.xs - AppSpacing.md <
                          430;
                  final roadView = RoadView(
                    progress: displayProgress,
                    vehicle: vehicle,
                    avatar: vehicleAvatar,
                    motivationVideoAssetPath: _isFinishDriving
                        ? null
                        : _activeMotivationVideoPath,
                    motivationVideoMilestone: _isFinishDriving
                        ? null
                        : _activeMotivationMilestone,
                    onMotivationVideoFinished: _handleMotivationVideoFinished,
                    showVehicle: !isLandscape,
                    showMotivationVideo: !isLandscape,
                    ingredients: courseIngredients,
                    ingredientClearProgress: displayProgress,
                    isRoadMotionActive:
                        _isFinishDriving ||
                        _controller.state == MealTimerState.running,
                    courseDuration: widget.config.duration,
                  );
                  final landscapeVehicleLayer = isLandscape
                      ? RoadVehicleLayer(
                          progress: displayProgress,
                          vehicle: vehicle,
                          avatar: vehicleAvatar,
                          courseDuration: widget.config.duration,
                        )
                      : null;
                  final landscapeMotivationVideoLayer =
                      !_isFinishDriving &&
                          isLandscape &&
                          _activeMotivationVideoPath != null &&
                          _activeMotivationMilestone != null
                      ? RoadMotivationVideoLayer(
                          assetPath: _activeMotivationVideoPath!,
                          milestone: _activeMotivationMilestone!,
                          reservedRightInset: reservesCompactControlsSpace
                              ? _compactLandscapeControlsRightInset
                              : 0,
                          onFinished: _handleMotivationVideoFinished,
                        )
                      : null;
                  final remainingTimeCard = widget.config.showRemainingTime
                      ? _RemainingTimeCard(
                          label: statusCopy.timeLabel,
                          remaining: displayedRemaining,
                          icon: statusCopy.icon,
                          iconBackgroundColor: statusCopy.iconBackgroundColor,
                          semanticLabel: texts.timer.remainingTimeSemanticLabel(
                            statusCopy.timeLabel,
                            formatDuration(displayedRemaining),
                          ),
                          isCompact: isLandscape,
                        )
                      : null;

                  if (isLandscape) {
                    return _LandscapeTimerLayout(
                      progressCard: _ProgressMessageCard(
                        message: statusCopy.progressMessage,
                        progress: displayProgress,
                        isCompact: true,
                      ),
                      remainingTimeBadge: widget.config.showRemainingTime
                          ? _RemainingTimeBadge(
                              label: statusCopy.timeLabel,
                              remaining: displayedRemaining,
                              icon: statusCopy.icon,
                              iconBackgroundColor:
                                  statusCopy.iconBackgroundColor,
                              semanticLabel: texts.timer
                                  .remainingTimeSemanticLabel(
                                    statusCopy.timeLabel,
                                    formatDuration(displayedRemaining),
                                  ),
                            )
                          : null,
                      roadView: roadView,
                      vehicleLayer: landscapeVehicleLayer,
                      motivationVideoLayer: landscapeMotivationVideoLayer,
                      onBack: _confirmExit,
                      controls: TimerControlBar(
                        isPaused: _controller.isPaused,
                        onPauseResume: _isFinishDriving
                            ? null
                            : handlePauseResume,
                        onComplete: _isFinishDriving ? null : _confirmComplete,
                      ),
                      compactControls: _CompactLandscapeControls(
                        isPaused: _controller.isPaused,
                        onPauseResume: _isFinishDriving
                            ? null
                            : handlePauseResume,
                        onComplete: _isFinishDriving ? null : _confirmComplete,
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
                          progress: displayProgress,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Expanded(child: roadView),
                        if (remainingTimeCard != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          remainingTimeCard,
                        ],
                        const SizedBox(height: AppSpacing.md),
                        TimerControlBar(
                          isPaused: _controller.isPaused,
                          onPauseResume: _isFinishDriving
                              ? null
                              : handlePauseResume,
                          onComplete: _isFinishDriving
                              ? null
                              : _confirmComplete,
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
    required this.compactControls,
  });

  final Widget progressCard;
  final Widget? remainingTimeBadge;
  final Widget roadView;
  final Widget? vehicleLayer;
  final Widget? motivationVideoLayer;
  final VoidCallback onBack;
  final Widget controls;
  final Widget compactControls;

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
          final isCompactLandscape = constraints.maxHeight < 430;
          final courseViewportHeight = (constraints.maxHeight - AppSpacing.xl)
              .clamp(360.0, 620.0)
              .toDouble();
          final courseCanvas = _LandscapeCourseCanvas(
            progressCard: progressCard,
            remainingTimeBadge: remainingTimeBadge,
            roadView: roadView,
            vehicleLayer: vehicleLayer,
            motivationVideoLayer: motivationVideoLayer,
            onBack: onBack,
            compactControls: isCompactLandscape ? compactControls : null,
          );

          if (isCompactLandscape) {
            return Center(child: courseCanvas);
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: courseViewportHeight,
                  child: Center(child: courseCanvas),
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

class _CompactLandscapeControls extends StatelessWidget {
  const _CompactLandscapeControls({
    required this.isPaused,
    required this.onPauseResume,
    required this.onComplete,
  });

  final bool isPaused;
  final VoidCallback? onPauseResume;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return Column(
      key: const ValueKey('compactLandscapeControls'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _CompactLandscapeButton(
          label: isPaused ? texts.common.restartRide : texts.timer.pauseButton,
          icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          onPressed: onPauseResume,
          variant: _CompactLandscapeButtonVariant.outline,
        ),
        const SizedBox(height: AppSpacing.sm),
        _CompactLandscapeButton(
          label: texts.timer.completeMealButton,
          icon: Icons.check_circle_rounded,
          onPressed: onComplete,
          variant: _CompactLandscapeButtonVariant.primary,
        ),
      ],
    );
  }
}

enum _CompactLandscapeButtonVariant { primary, outline }

class _CompactLandscapeButton extends StatelessWidget {
  const _CompactLandscapeButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.variant,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final _CompactLandscapeButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final isPrimary = variant == _CompactLandscapeButtonVariant.primary;
    final backgroundColor = isEnabled
        ? isPrimary
              ? AppColors.primary
              : AppColors.white.withValues(alpha: 0.94)
        : AppColors.brown300.withValues(alpha: 0.30);
    final foregroundColor = isEnabled
        ? isPrimary
              ? AppColors.white
              : AppColors.brown700
        : AppColors.brown500.withValues(alpha: 0.56);
    final border = isPrimary
        ? null
        : Border.all(color: AppColors.borderSoft, width: 1.4);
    return Semantics(
      label: label,
      button: true,
      child: Tooltip(
        message: label,
        child: SizedBox(
          height: 62,
          width: 62,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppRadius.card,
              border: border,
              boxShadow: isEnabled ? AppShadows.buttonSoft : null,
            ),
            child: Material(
              color: AppColors.transparent,
              borderRadius: AppRadius.card,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: Icon(icon, color: foregroundColor, size: 28),
              ),
            ),
          ),
        ),
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
    this.compactControls,
  });

  final Widget progressCard;
  final Widget? remainingTimeBadge;
  final Widget roadView;
  final Widget? vehicleLayer;
  final Widget? motivationVideoLayer;
  final VoidCallback onBack;
  final Widget? compactControls;

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
            if (vehicleLayer != null) Positioned.fill(child: vehicleLayer!),
            if (motivationVideoLayer != null)
              Positioned.fill(child: motivationVideoLayer!),
            if (compactControls != null)
              Positioned(
                right: AppSpacing.xl,
                top: 0,
                bottom: 0,
                child: Center(
                  child: SizedBox(
                    width: _compactLandscapeControlsWidth,
                    child: compactControls!,
                  ),
                ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: isCompact ? 48 : 52),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Icon(icon, color: AppColors.brown700, size: 22),
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
                                      : textTheme.titleLarge)
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
                                    : textTheme.titleLarge)
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
