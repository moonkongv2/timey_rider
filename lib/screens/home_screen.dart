import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../catalogs/activity_marker_catalog.dart';
import '../catalogs/meal_course_catalog.dart';
import '../catalogs/vehicle_catalog.dart';
import '../l10n/app_texts.dart';
import '../models/active_activity_timer_session.dart';
import '../models/activity_progress_snapshot.dart';
import '../models/activity_timer_config.dart';
import '../models/vehicle_avatar_presentation.dart';
import '../navigation/app_route_observer.dart';
import '../models/reward_goal.dart';
import '../models/reward_item.dart';
import '../models/vehicle.dart';
import '../services/active_activity_timer_session_store.dart';
import '../services/local_activity_progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../utils/duration_format.dart';
import '../widgets/app/app_bouncy_button.dart';
import '../widgets/app/app_metric_tile.dart';
import '../widgets/avatar/avatar_composite_preview.dart';
import '../widgets/activity_marker_picker_sheet.dart';
import '../widgets/reward_sticker_image.dart';
import '../widgets/vehicle_selection_card.dart';
import 'avatar_setup_screen.dart';
import 'activity_history_screen.dart';
import 'reward_goal_screen.dart';
import 'settings_screen.dart';
import 'sticker_collection_screen.dart';
import 'timer_screen.dart';

const _homeLogoAssetPath = 'assets/images/logo_eng.png';
const _settingsIconAssetPath = 'assets/images/icon_setting_rgba.png';
const _activeSessionMaxAge = Duration(hours: 24);

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.config,
    required this.activityProgressService,
    required this.onConfigChanged,
    this.activeSessionStore = const ActiveActivityTimerSessionStore(),
    this.avatarImageBuilder,
    this.now,
  });

  final ActivityTimerConfig config;
  final LocalActivityProgressService activityProgressService;
  final ValueChanged<ActivityTimerConfig> onConfigChanged;
  final ActiveActivityTimerSessionStore activeSessionStore;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;
  final DateTime Function()? now;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  late ActivityTimerConfig _config = widget.config;
  late double _customMinutes = _config.duration.inMinutes.toDouble();
  late Future<ActiveActivityTimerSession?> _activeSessionFuture;
  ActiveActivityTimerSession? _activeSession;
  Timer? _activeSessionTicker;

  @override
  void initState() {
    super.initState();
    _activeSessionFuture = _loadActiveSession();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _config = widget.config;
    }
    if (oldWidget.config.duration != _config.duration) {
      _customMinutes = _config.duration.inMinutes.toDouble();
    }
    if (oldWidget.activeSessionStore != widget.activeSessionStore) {
      _refreshProgressSnapshot();
    }
  }

  void _refreshProgressSnapshot() {
    setState(() {
      _activeSessionFuture = _loadActiveSession();
    });
  }

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  Future<ActiveActivityTimerSession?> _loadActiveSession() async {
    var session = await widget.activeSessionStore.load();
    if (session != null && _isStaleActiveSession(session, now: _now())) {
      await widget.activeSessionStore.clear();
      session = null;
    }
    if (mounted) {
      _activeSession = session;
      _updateActiveSessionTicker(session);
    }
    return session;
  }

  void _updateActiveSessionTicker(ActiveActivityTimerSession? session) {
    if (session?.state == ActiveActivityTimerSessionState.running &&
        _remainingForActiveSession(session!, now: _now()) > Duration.zero) {
      _activeSessionTicker ??= Timer.periodic(
        const Duration(seconds: 1),
        _handleActiveSessionTick,
      );
      return;
    }

    _stopActiveSessionTicker();
  }

  void _handleActiveSessionTick(Timer timer) {
    final session = _activeSession;
    if (!mounted || session == null) {
      timer.cancel();
      if (identical(_activeSessionTicker, timer)) {
        _activeSessionTicker = null;
      }
      return;
    }

    if (session.state != ActiveActivityTimerSessionState.running ||
        _remainingForActiveSession(session, now: _now()) <= Duration.zero) {
      _stopActiveSessionTicker();
    }

    setState(() {});
  }

  void _stopActiveSessionTicker() {
    _activeSessionTicker?.cancel();
    _activeSessionTicker = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _stopActiveSessionTicker();
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    _stopActiveSessionTicker();
  }

  @override
  void didPopNext() {
    _refreshProgressSnapshot();
  }

  void _updateConfig(ActivityTimerConfig config) {
    setState(() {
      if (_config.duration != config.duration) {
        _customMinutes = config.duration.inMinutes.toDouble();
      }
      _config = config;
    });
    widget.onConfigChanged(config);
  }

  void _updateTimerRuntimeConfig(ActivityTimerConfig config) {
    _updateConfig(
      _config.copyWith(
        motivationVideoEnabled: config.motivationVideoEnabled,
        motivationVideoUseCustomInterval:
            config.motivationVideoUseCustomInterval,
        motivationVideoInterval: config.motivationVideoInterval,
      ),
    );
  }

  Future<void> _startTimer(int minutes) async {
    final shouldStartNewTimer = await _resolveActiveSessionBeforeNewTimer();
    if (!mounted || !shouldStartNewTimer) {
      return;
    }

    final activityMarkerSelection = await _activityMarkerSelectionForStart();
    if (!mounted || activityMarkerSelection == null) {
      return;
    }

    final config = _config.copyWith(
      duration: Duration(minutes: minutes),
      markerIds: activityMarkerSelection.markerIds,
      selectedMarkerIds: activityMarkerSelection.selectedMarkerIds,
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          config: config,
          activityProgressService: widget.activityProgressService,
          activeSessionStore: widget.activeSessionStore,
          onConfigChanged: _updateTimerRuntimeConfig,
        ),
      ),
    );
    if (mounted) {
      _refreshProgressSnapshot();
    }
  }

  Future<bool> _resolveActiveSessionBeforeNewTimer() async {
    final activeSession = await _loadActiveSession();
    if (!mounted) {
      return false;
    }
    if (activeSession == null) {
      _refreshProgressSnapshot();
      return true;
    }

    final texts = AppTexts.of(context);
    final choice = await showDialog<_ActiveTimerStartChoice>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(texts.home.activeTimerNewTimerDialogTitle),
          content: Text(texts.home.activeTimerNewTimerDialogMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_ActiveTimerStartChoice.cancel);
              },
              child: Text(texts.common.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(_ActiveTimerStartChoice.startNew);
              },
              child: Text(texts.home.activeTimerStartNewButton),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return false;
    }

    switch (choice) {
      case _ActiveTimerStartChoice.startNew:
        await widget.activeSessionStore.clear();
        if (mounted) {
          _refreshProgressSnapshot();
        }
        return mounted;
      case _ActiveTimerStartChoice.cancel:
      case null:
        return false;
    }
  }

  Future<void> _resumeActiveTimer(ActiveActivityTimerSession session) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          config: session.config,
          restoredSession: session,
          activityProgressService: widget.activityProgressService,
          activeSessionStore: widget.activeSessionStore,
          onConfigChanged: _updateTimerRuntimeConfig,
        ),
      ),
    );
    if (mounted) {
      _refreshProgressSnapshot();
    }
  }

  Future<void> _cancelActiveTimer() async {
    final texts = AppTexts.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(texts.home.activeTimerCancelDialogTitle),
          content: Text(texts.home.activeTimerCancelDialogMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(texts.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(texts.home.activeTimerCancelButton),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await widget.activeSessionStore.clear();
    if (mounted) {
      _refreshProgressSnapshot();
    }
  }

  Future<_ActivityMarkerSelection?> _activityMarkerSelectionForStart() async {
    switch (_config.markerMode) {
      case ActivityMarkerMode.off:
        return const _ActivityMarkerSelection(
          markerIds: [],
          selectedMarkerIds: [],
        );
      case ActivityMarkerMode.random:
        return _ActivityMarkerSelection(
          markerIds: ActivityMarkerCatalog.randomSelectionIds(
            activityId: _config.activityId,
          ),
          selectedMarkerIds: const [],
        );
      case ActivityMarkerMode.activityDefault:
        return _ActivityMarkerSelection(
          markerIds: ActivityMarkerCatalog.defaultSelectionIdsForActivity(
            _config.activityId,
          ),
          selectedMarkerIds: const [],
        );
      case ActivityMarkerMode.manual:
        final markerResult =
            await showModalBottomSheet<ActivityMarkerPickerResult>(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.transparent,
              builder: (_) => ActivityMarkerPickerSheet(
                activityId: _config.activityId,
                initialSelectedIds: _config.selectedMarkerIds,
              ),
            );
        if (markerResult == null) {
          return null;
        }
        return switch (markerResult) {
          RandomActivityMarkers() => _ActivityMarkerSelection(
            markerIds: ActivityMarkerCatalog.randomSelectionIds(
              activityId: _config.activityId,
            ),
            selectedMarkerIds: const [],
          ),
          SelectedActivityMarkers(:final markerIds) => _ActivityMarkerSelection(
            markerIds: markerIds,
            selectedMarkerIds: markerIds,
          ),
        };
    }
  }

  Future<void> _openCustomMinutesSheet() async {
    final texts = AppTexts.of(context);
    var sheetMinutes = _customMinutes;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void updateSheetMinutes(double value) {
              final minutes = value.clamp(
                MealCourseCatalog.minCustomMinutes.toDouble(),
                MealCourseCatalog.maxCustomMinutes.toDouble(),
              );
              setState(() => _customMinutes = minutes);
              setSheetState(() => sheetMinutes = minutes);
            }

            void adjustSheetMinutes(int delta) {
              updateSheetMinutes((sheetMinutes.round() + delta).toDouble());
            }

            return SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.56,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarm,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.xxl),
                      ),
                      border: Border.all(color: AppColors.borderWarm),
                      boxShadow: AppShadows.hero,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.sm,
                        AppSpacing.xl,
                        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.borderSoft,
                                borderRadius: AppRadius.pill,
                              ),
                              child: const SizedBox(width: 44, height: 5),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        texts.home.customSheetTitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppColors.textStrong,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        texts.home.minuteLabel(
                                          sheetMinutes.round(),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: AppColors.textStrong,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton.filledTonal(
                                  onPressed: () =>
                                      Navigator.of(sheetContext).pop(),
                                  icon: const Icon(Icons.close_rounded),
                                  tooltip: MaterialLocalizations.of(
                                    context,
                                  ).closeButtonTooltip,
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.white.withValues(
                                      alpha: 0.72,
                                    ),
                                    foregroundColor: AppColors.brown700,
                                    fixedSize: const Size(44, 44),
                                    shape: const CircleBorder(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _CustomMinutesSheetContent(
                              sliderLabel: texts.home.minuteLabel(
                                sheetMinutes.round(),
                              ),
                              minutes: sheetMinutes,
                              startLabel: texts.home.customStartButton,
                              onChanged: updateSheetMinutes,
                              onAdjust: adjustSheetMinutes,
                              onStart: () {
                                final selectedMinutes = sheetMinutes.round();
                                Navigator.of(sheetContext).pop();
                                _startTimer(selectedMinutes);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SettingsScreen(config: _config, onConfigChanged: _updateConfig),
      ),
    );
  }

  Future<void> _openAvatarSetup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AvatarSetupScreen(config: _config, onConfigChanged: _updateConfig),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final childName = _config.childName.trim().isEmpty
        ? texts.common.defaultChildName
        : _config.childName.trim();
    final selectedVehicle = VehicleCatalog.findById(_config.vehicleId);
    final selectedVehicleAvatar = _config.avatarPresentationForVehicle(
      selectedVehicle.id,
    );
    final selectedVehicleAvatarImagePath = selectedVehicleAvatar.imagePath;
    final isUsingCustomAvatar =
        selectedVehicleAvatar.isCustom &&
        selectedVehicleAvatarImagePath != null &&
        File(selectedVehicleAvatarImagePath).existsSync();
    final avatarStateText = isUsingCustomAvatar
        ? texts.home.avatarInlineCustomState
        : texts.home.avatarInlineDefaultState;
    final defaultMealMinutes = _config.duration.inMinutes;
    final alternateCourseMinutes = MealCourseCatalog.presetMinutes
        .where((minutes) => minutes != defaultMealMinutes)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(1200),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_HomeLogo(semanticLabel: texts.common.appTitle)],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _openSettings,
                  icon: SizedBox(
                    width: 34,
                    height: 34,
                    child: Transform.scale(
                      scale: 1.42,
                      child: Image.asset(
                        _settingsIconAssetPath,
                        fit: BoxFit.contain,
                        cacheWidth: 96,
                      ),
                    ),
                  ),
                  tooltip: texts.common.settings,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.brown700,
                    fixedSize: const Size(48, 48),
                    shape: const CircleBorder(),
                    shadowColor: AppColors.brown700.withValues(alpha: 0.14),
                    elevation: 5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final vehicleCard = VehicleSelectionCard(
                  title: texts.home.todayVehicleTitle,
                  selectedVehicleId: _config.vehicleId,
                  onVehicleSelected: (vehicleId) {
                    _updateConfig(_config.copyWith(vehicleId: vehicleId));
                  },
                  avatar: selectedVehicleAvatar,
                  avatarForVehicle: _config.avatarPresentationForVehicle,
                  avatarImageBuilder: widget.avatarImageBuilder,
                  showSelectedPreview: true,
                  footer: _AvatarInlineCta(
                    stateText: avatarStateText,
                    description: texts.home.avatarCtaSubtitle,
                    buttonLabel: isUsingCustomAvatar
                        ? texts.home.avatarCtaEditButton
                        : texts.home.avatarCtaButton,
                    semanticLabel: isUsingCustomAvatar
                        ? texts.home.avatarCtaEditSemantics
                        : texts.home.avatarCtaCreateSemantics,
                    onPressed: _openAvatarSetup,
                  ),
                );
                final heroCard = _HeroMissionCard(
                  ctaLabel:
                      '${texts.home.normalCourse(defaultMealMinutes)} ${texts.common.start}',
                  vehicle: selectedVehicle,
                  avatar: selectedVehicleAvatar,
                  avatarImageBuilder: widget.avatarImageBuilder,
                  onStart: () => _startTimer(defaultMealMinutes),
                );
                final quickCourses = _QuickCourseSection(
                  title: texts.home.quickCourseTitle,
                  children: [
                    for (final minutes in alternateCourseMinutes)
                      _QuickCourseButton(
                        label: texts.home.alternateCourse(minutes),
                        subtitle: texts.home.alternateCourseSubtitle(minutes),
                        emoji: _quickCourseEmoji(minutes),
                        onPressed: () => _startTimer(minutes),
                      ),
                    _QuickCourseButton(
                      label: texts.home.customSheetTitle,
                      subtitle: texts.home.recentCustomMinutes(
                        _customMinutes.round(),
                      ),
                      icon: Icons.tune_rounded,
                      isFullWidthOnNarrow: true,
                      onPressed: _openCustomMinutesSheet,
                    ),
                  ],
                );
                final activeSessionCard =
                    FutureBuilder<ActiveActivityTimerSession?>(
                      future: _activeSessionFuture,
                      builder: (context, snapshot) {
                        final activeSession = snapshot.data;
                        if (activeSession == null) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: _ActiveTimerResumeCard(
                            remaining: _remainingForActiveSession(
                              activeSession,
                              now: _now(),
                            ),
                            hasArrived: _hasActiveSessionArrived(
                              activeSession,
                              now: _now(),
                            ),
                            onPressed: () => _resumeActiveTimer(activeSession),
                            onCancel: _cancelActiveTimer,
                          ),
                        );
                      },
                    );

                if (constraints.maxWidth >= 700) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(children: [activeSessionCard, heroCard]),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(
                        child: Column(
                          children: [
                            quickCourses,
                            const SizedBox(height: AppSpacing.md),
                            vehicleCard,
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    activeSessionCard,
                    heroCard,
                    const SizedBox(height: AppSpacing.xl),
                    quickCourses,
                    const SizedBox(height: AppSpacing.xl),
                    vehicleCard,
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            FutureBuilder<ActivityProgressSnapshot>(
              future: widget.activityProgressService.loadSnapshot(),
              builder: (context, snapshot) {
                return _ProgressSummary(
                  childName: childName,
                  snapshot: snapshot.data,
                  onOpenMealHistory: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ActivityHistoryScreen(
                          activityProgressService:
                              widget.activityProgressService,
                        ),
                      ),
                    );
                  },
                  onOpenRewardGoal: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RewardGoalScreen(
                          activityProgressService:
                              widget.activityProgressService,
                        ),
                      ),
                    );
                    if (context.mounted) {
                      _refreshProgressSnapshot();
                    }
                  },
                  onOpenStickers: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StickerCollectionScreen(
                          activityProgressService:
                              widget.activityProgressService,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityMarkerSelection {
  const _ActivityMarkerSelection({
    required this.markerIds,
    required this.selectedMarkerIds,
  });

  final List<String> markerIds;
  final List<String> selectedMarkerIds;
}

enum _ActiveTimerStartChoice { cancel, startNew }

bool _isStaleActiveSession(
  ActiveActivityTimerSession session, {
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  return currentTime.difference(session.startedAt) > _activeSessionMaxAge;
}

bool _hasActiveSessionArrived(
  ActiveActivityTimerSession session, {
  DateTime? now,
}) {
  return session.state == ActiveActivityTimerSessionState.arrived ||
      _remainingForActiveSession(session, now: now) <= Duration.zero;
}

Duration _remainingForActiveSession(
  ActiveActivityTimerSession session, {
  DateTime? now,
}) {
  if (session.state == ActiveActivityTimerSessionState.arrived) {
    return Duration.zero;
  }

  final currentTime = now ?? DateTime.now();
  final referenceTime = session.state == ActiveActivityTimerSessionState.paused
      ? session.pausedAt ?? currentTime
      : currentTime;
  final elapsed =
      referenceTime.difference(session.startedAt) - session.totalPausedDuration;
  final remaining =
      session.duration - (elapsed.isNegative ? Duration.zero : elapsed);
  return remaining.isNegative ? Duration.zero : remaining;
}

String? _quickCourseEmoji(int minutes) {
  return switch (minutes) {
    15 => '🌞',
    25 => '⭐',
    35 => '🌈',
    _ => null,
  };
}

class _ActiveTimerResumeCard extends StatelessWidget {
  const _ActiveTimerResumeCard({
    required this.remaining,
    required this.hasArrived,
    required this.onPressed,
    required this.onCancel,
  });

  final Duration remaining;
  final bool hasArrived;
  final VoidCallback onPressed;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context);
    final formattedRemaining = formatDuration(remaining);

    return DecoratedBox(
      key: const ValueKey('activeTimerResumeCard'),
      decoration: BoxDecoration(
        color: AppColors.surfaceMint,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.88)),
        boxShadow: AppShadows.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.7),
                    borderRadius: AppRadius.pill,
                  ),
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(
                      Icons.timer_rounded,
                      color: AppColors.brown700,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        texts.home.activeTimerTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.textStrong,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasArrived
                            ? texts.home.activeTimerArrivedSubtitle
                            : texts.home.activeTimerSubtitle(
                                formattedRemaining,
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('activeTimerCancelButton'),
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderSoft),
                      shape: const StadiumBorder(),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: Text(
                      texts.home.activeTimerCancelButton,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppBouncyButton(
                    label: texts.home.activeTimerResumeButton,
                    icon: Icons.play_arrow_rounded,
                    onPressed: onPressed,
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.compact,
                    fullWidth: true,
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

class _HomeLogo extends StatelessWidget {
  const _HomeLogo({required this.semanticLabel});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: 260,
          height: 88,
          child: Transform.translate(
            offset: const Offset(-18, 0),
            child: Transform.scale(
              scale: 1.42,
              alignment: Alignment.centerLeft,
              child: Image.asset(
                _homeLogoAssetPath,
                key: const ValueKey('homeLogo'),
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                cacheWidth: 740,
                errorBuilder: (context, error, stackTrace) {
                  return ColoredBox(
                    color: AppColors.transparent,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        semanticLabel,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.brown900,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarInlineCta extends StatelessWidget {
  const _AvatarInlineCta({
    required this.stateText,
    required this.description,
    required this.buttonLabel,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String stateText;
  final String description;
  final String buttonLabel;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Material(
          color: AppColors.transparent,
          borderRadius: AppRadius.compactCard,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppRadius.compactCard,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfacePink.withValues(alpha: 0.64),
                        borderRadius: AppRadius.pill,
                      ),
                      child: const SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(
                          Icons.face_retouching_natural_rounded,
                          color: AppColors.brown700,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            stateText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textStrong,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.7),
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
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 56),
                              child: Text(
                                buttonLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.brown700,
                              size: 16,
                            ),
                          ],
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

class _MinuteAdjustButton extends StatelessWidget {
  const _MinuteAdjustButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surfaceWarm,
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.borderSoft, width: 1.1),
        shape: const StadiumBorder(),
        minimumSize: const Size.fromHeight(38),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _HeroMissionCard extends StatelessWidget {
  const _HeroMissionCard({
    required this.ctaLabel,
    required this.vehicle,
    required this.avatar,
    this.avatarImageBuilder,
    required this.onStart,
  });

  final String ctaLabel;
  final VehicleDefinition vehicle;
  final VehicleAvatarPresentation avatar;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.hero,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceWarm,
            AppColors.surfaceSoft,
            AppColors.surfaceYellow.withValues(alpha: 0.88),
            AppColors.primarySoft.withValues(alpha: 0.62),
          ],
          stops: const [0, 0.48, 0.78, 1],
        ),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.9)),
        boxShadow: AppShadows.hero,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        texts.home.heroMissionTitle,
                        style: textTheme.titleLarge?.copyWith(
                          color: AppColors.textStrong,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        texts.home.subtitle,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        texts.home.heroMissionSubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.38,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.48),
                    borderRadius: AppRadius.pill,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.68),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: SizedBox(
                      width: 78,
                      height: 78,
                      child: AvatarCompositePreview(
                        vehicle: vehicle,
                        avatar: avatar,
                        size: 78,
                        avatarImageBuilder: avatarImageBuilder,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppBouncyButton(
              label: ctaLabel,
              icon: Icons.play_arrow_rounded,
              onPressed: onStart,
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCourseSection extends StatelessWidget {
  const _QuickCourseSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textStrong,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = AppSpacing.sm;
                final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                final useSingleColumn =
                    constraints.maxWidth < 300 || textScale >= 1.25;
                final columns = useSingleColumn
                    ? 1
                    : constraints.maxWidth >= 520
                    ? 3
                    : 2;
                final itemWidth =
                    (constraints.maxWidth - (spacing * (columns - 1))) /
                    columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final child in children) ...[
                      SizedBox(
                        width: !_fillsNarrowWidth(child) || columns == 3
                            ? itemWidth
                            : constraints.maxWidth,
                        child: child,
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _fillsNarrowWidth(Widget child) {
    return child is _QuickCourseButton && child.isFullWidthOnNarrow;
  }
}

class _QuickCourseButton extends StatelessWidget {
  const _QuickCourseButton({
    required this.label,
    required this.subtitle,
    required this.onPressed,
    this.emoji,
    this.icon,
    this.isFullWidthOnNarrow = false,
  });

  final String label;
  final String subtitle;
  final VoidCallback onPressed;
  final String? emoji;
  final IconData? icon;
  final bool isFullWidthOnNarrow;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: AppRadius.compactCard,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadius.compactCard,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.compactCard,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: AppRadius.pill,
                    ),
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: Center(
                        child: emoji != null
                            ? Text(
                                emoji!,
                                textScaler: TextScaler.noScaling,
                                style: const TextStyle(fontSize: 21, height: 1),
                              )
                            : Icon(
                                icon ?? Icons.arrow_forward_rounded,
                                color: AppColors.brown700,
                                size: 21,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isFullWidthOnNarrow)
                          Text(
                            '$label · $subtitle',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.textStrong,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          )
                        else ...[
                          Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.textStrong,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isFullWidthOnNarrow) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.brown700,
                      size: 22,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomMinutesSheetContent extends StatelessWidget {
  const _CustomMinutesSheetContent({
    required this.sliderLabel,
    required this.minutes,
    required this.startLabel,
    required this.onChanged,
    required this.onAdjust,
    required this.onStart,
  });

  final String sliderLabel;
  final double minutes;
  final String startLabel;
  final ValueChanged<double> onChanged;
  final ValueChanged<int> onAdjust;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.borderSoft,
              thumbColor: AppColors.primarySoft,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              valueIndicatorColor: AppColors.brown900,
              valueIndicatorTextStyle: textTheme.labelMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
              trackHeight: 6,
            ),
            child: Slider(
              value: minutes,
              min: MealCourseCatalog.minCustomMinutes.toDouble(),
              max: MealCourseCatalog.maxCustomMinutes.toDouble(),
              label: sliderLabel,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MinuteAdjustButton(
                  label: '-5',
                  onPressed: () => onAdjust(-5),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MinuteAdjustButton(
                  label: '-1',
                  onPressed: () => onAdjust(-1),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MinuteAdjustButton(
                  label: '+1',
                  onPressed: () => onAdjust(1),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MinuteAdjustButton(
                  label: '+5',
                  onPressed: () => onAdjust(5),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: AppBouncyButton(
              label: startLabel,
              icon: Icons.flag_rounded,
              onPressed: onStart,
              variant: AppButtonVariant.soft,
              size: AppButtonSize.medium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.childName,
    required this.snapshot,
    required this.onOpenMealHistory,
    required this.onOpenRewardGoal,
    required this.onOpenStickers,
  });

  final String childName;
  final ActivityProgressSnapshot? snapshot;
  final VoidCallback onOpenMealHistory;
  final VoidCallback onOpenRewardGoal;
  final VoidCallback onOpenStickers;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final history = snapshot?.history ?? const [];
    final inventory = snapshot?.inventory ?? const [];
    final activeRewardGoals = snapshot?.activeRewardGoals ?? const [];
    final earnedRewardCount = snapshot?.earnedRewardGoals.length ?? 0;
    final recent = history.isEmpty ? null : history.first;
    final recentDisplayDuration = recent == null
        ? Duration.zero
        : capDuration(recent.actualDuration, recent.targetDuration);
    final recentOverrun = recent == null
        ? Duration.zero
        : overrunDuration(recent.actualDuration, recent.targetDuration);
    final knownStickers = inventory.where(
      (item) =>
          RewardCatalog.findById(item.rewardId)?.type == RewardType.sticker,
    );
    final stickerCount = knownStickers.fold<int>(
      0,
      (total, item) => total + item.count,
    );
    final stickerKindCount = knownStickers.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MealHistorySummaryButton(
          title: texts.home.progressTitle(childName),
          mealValue: texts.home.mealCount(history.length),
          stickerKindValue: texts.home.stickerKindCount(stickerKindCount),
          stickerValue: texts.home.stickerCount(stickerCount),
          recentSummary: recent == null
              ? texts.home.noMealHistory
              : [
                  texts.home.recentMealSummary(
                    formatDuration(recentDisplayDuration),
                    recent.completionStatus,
                  ),
                  if (!recent.activityCompleted)
                    texts.mealHistory.noRewardLabel,
                  if (!recent.activityCompleted &&
                      recentOverrun > Duration.zero)
                    texts.mealHistory.overrunTime(
                      formatDuration(recentOverrun),
                    ),
                ].join(' · '),
          onPressed: onOpenMealHistory,
        ),
        const SizedBox(height: AppSpacing.md),
        _RewardGoalCta(
          goals: activeRewardGoals,
          earnedRewardCount: earnedRewardCount,
          onPressed: onOpenRewardGoal,
        ),
        const SizedBox(height: AppSpacing.md),
        _StickerCollectionCta(
          label: texts.home.openStickerCollection,
          onPressed: onOpenStickers,
        ),
      ],
    );
  }
}

class _MealHistorySummaryButton extends StatelessWidget {
  const _MealHistorySummaryButton({
    required this.title,
    required this.mealValue,
    required this.stickerKindValue,
    required this.stickerValue,
    required this.recentSummary,
    required this.onPressed,
  });

  final String title;
  final String mealValue;
  final String stickerKindValue;
  final String stickerValue;
  final String recentSummary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context);

    return Material(
      color: AppColors.transparent,
      borderRadius: AppRadius.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textStrong,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppMetricTile(
                      icon: Icons.restaurant_rounded,
                      label: texts.home.mealSummaryLabel,
                      value: mealValue,
                      backgroundColor: AppColors.surfaceMint,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppMetricTile(
                      icon: Icons.auto_awesome_rounded,
                      label: texts.home.stickerKindSummaryLabel,
                      value: stickerKindValue,
                      backgroundColor: AppColors.surfaceBlue,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppMetricTile(
                      icon: Icons.stars_rounded,
                      label: texts.home.stickerSummaryLabel,
                      value: stickerValue,
                      backgroundColor: AppColors.surfacePink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.borderWarm),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          recentSummary,
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            height: 1.34,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
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

class _RewardGoalCta extends StatelessWidget {
  const _RewardGoalCta({
    required this.goals,
    required this.earnedRewardCount,
    required this.onPressed,
  });

  final List<RewardGoal> goals;
  final int earnedRewardCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final hasEarnedRewards = earnedRewardCount > 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: hasEarnedRewards ? AppColors.surfaceYellow : AppColors.white,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: AppShadows.surface,
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadius.card,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: goals.isEmpty
                ? _EmptyRewardGoalCta(
                    label: hasEarnedRewards
                        ? texts.rewards.earnedRewardGoalsTitle
                        : texts.rewards.createRewardGoal,
                    subtitle: hasEarnedRewards
                        ? texts.rewards.stickerCount(earnedRewardCount)
                        : null,
                  )
                : _ActiveRewardGoalsCta(
                    goals: goals,
                    earnedRewardCount: earnedRewardCount,
                  ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRewardGoalCta extends StatelessWidget {
  const _EmptyRewardGoalCta({required this.label, this.subtitle});

  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceYellow,
            borderRadius: AppRadius.pill,
          ),
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textStrong,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_rounded, color: AppColors.textPrimary),
      ],
    );
  }
}

class _ActiveRewardGoalsCta extends StatelessWidget {
  const _ActiveRewardGoalsCta({
    required this.goals,
    required this.earnedRewardCount,
  });

  final List<RewardGoal> goals;
  final int earnedRewardCount;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                texts.rewards.activeRewardGoalsTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final goal in goals.take(2)) ...[
                Text(
                  '${goal.rewardText} · ${texts.rewards.rewardGoalProgress(goal.filledCount, goal.requiredStickerCount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textStrong,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (earnedRewardCount > 0)
                Text(
                  '${texts.rewards.earnedRewardGoalsTitle} $earnedRewardCount',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _MiniRewardGoalBoard(goal: goals.first),
        const SizedBox(width: AppSpacing.sm),
        const Icon(Icons.arrow_forward_rounded, color: AppColors.textPrimary),
      ],
    );
  }
}

class _MiniRewardGoalBoard extends StatelessWidget {
  const _MiniRewardGoalBoard({required this.goal});

  final RewardGoal goal;

  @override
  Widget build(BuildContext context) {
    final visibleCount = goal.requiredStickerCount.clamp(1, 5);

    return SizedBox(
      width: 112,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (var index = 0; index < visibleCount; index += 1)
            _MiniRewardGoalSlot(
              slot: index < goal.filledSlots.length
                  ? goal.filledSlots[index]
                  : null,
            ),
        ],
      ),
    );
  }
}

class _MiniRewardGoalSlot extends StatelessWidget {
  const _MiniRewardGoalSlot({required this.slot});

  final RewardGoalSlot? slot;

  @override
  Widget build(BuildContext context) {
    final reward = slot == null ? null : RewardCatalog.findById(slot!.rewardId);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: reward == null ? AppColors.surfaceSoft : AppColors.white,
        borderRadius: AppRadius.compactCard,
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: SizedBox.square(
        dimension: 32,
        child: Center(
          child: reward == null
              ? const Icon(
                  Icons.circle_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                )
              : RewardStickerImage(reward: reward, size: 24),
        ),
      ),
    );
  }
}

class _StickerCollectionCta extends StatelessWidget {
  const _StickerCollectionCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white,
            AppColors.surfaceWarm,
            AppColors.primarySoft.withValues(alpha: 0.36),
          ],
        ),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: AppShadows.surface,
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadius.card,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft.withValues(alpha: 0.46),
                    borderRadius: AppRadius.pill,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Icon(
                      Icons.collections_bookmark_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
