import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../catalogs/activity_catalog.dart';
import '../catalogs/activity_marker_catalog.dart';
import '../catalogs/vehicle_catalog.dart';
import '../l10n/app_texts.dart';
import '../models/active_activity_timer_session.dart';
import '../models/activity.dart';
import '../models/activity_marker.dart';
import '../models/activity_progress_snapshot.dart';
import '../models/activity_timer_config.dart';
import '../models/activity_timer_preset.dart';
import '../models/vehicle_avatar_presentation.dart';
import '../navigation/app_route_observer.dart';
import '../models/reward_goal.dart';
import '../models/reward_item.dart';
import '../services/active_activity_timer_session_store.dart';
import '../services/local_activity_progress_service.dart';
import '../services/local_recent_timer_service.dart';
import '../services/local_saved_timer_preset_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../utils/duration_format.dart';
import '../widgets/app/app_bouncy_button.dart';
import '../widgets/app/app_metric_tile.dart';
import '../widgets/reward_sticker_image.dart';
import '../widgets/vehicle_selection_card.dart';
import 'avatar_setup_screen.dart';
import 'activity_history_screen.dart';
import 'reward_goal_screen.dart';
import 'settings_screen.dart';
import 'sticker_collection_screen.dart';
import 'timer_screen.dart';

const _settingsIconAssetPath = 'assets/images/icon_setting_rgba.png';
const _homeLogoAssetPath = 'assets/images/timey_rider_logo.png';
const _activeSessionMaxAge = Duration(hours: 24);
const _minCustomActivityMinutes = 1;
const _maxCustomActivityMinutes = 60;

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.config,
    required this.activityProgressService,
    required this.onConfigChanged,
    this.activeSessionStore = const ActiveActivityTimerSessionStore(),
    this.recentTimerService = const LocalRecentTimerService(),
    this.savedTimerPresetService = const LocalSavedTimerPresetService(),
    this.avatarImageBuilder,
    this.now,
  });

  final ActivityTimerConfig config;
  final LocalActivityProgressService activityProgressService;
  final ValueChanged<ActivityTimerConfig> onConfigChanged;
  final ActiveActivityTimerSessionStore activeSessionStore;
  final LocalRecentTimerService recentTimerService;
  final LocalSavedTimerPresetService savedTimerPresetService;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;
  final DateTime Function()? now;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  late ActivityTimerConfig _config = widget.config;
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

  Future<void> _startActivityTimer({
    required ActivityDefinition activity,
    required Duration duration,
    required ActivityMarkerMode markerMode,
    required _ActivityMarkerSelection activityMarkerSelection,
  }) async {
    final shouldStartNewTimer = await _resolveActiveSessionBeforeNewTimer();
    if (!mounted || !shouldStartNewTimer) {
      return;
    }

    final config = _config.copyWith(
      activityId: activity.id,
      duration: duration,
      markerMode: markerMode,
      markerIds: activityMarkerSelection.markerIds,
      selectedMarkerIds: activityMarkerSelection.selectedMarkerIds,
    );
    await widget.recentTimerService.save(
      ActivityTimerPreset(
        activityId: activity.id,
        duration: duration,
        markerMode: markerMode,
        markerIds: activityMarkerSelection.markerIds,
        selectedMarkerIds: activityMarkerSelection.selectedMarkerIds,
        updatedAt: _now(),
      ),
    );
    if (!mounted) {
      return;
    }

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

  Future<void> _openTimerBuilder() async {
    final recentPreset = await widget.recentTimerService.load();
    final savedPresets = await widget.savedTimerPresetService.load();
    if (!mounted) {
      return;
    }

    final result = await showModalBottomSheet<_TimerBuilderResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => _TimerBuilderSheet(
        recentPreset: recentPreset,
        savedPresets: savedPresets,
        savedTimerPresetService: widget.savedTimerPresetService,
        now: _now,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    await _startActivityTimer(
      activity: result.activity,
      duration: result.duration,
      markerMode: result.markerMode,
      activityMarkerSelection: result.activityMarkerSelection,
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
                final timerBuilder = _TimerBuilderSection(
                  title: texts.home.activityQuickStartTitle,
                  subtitle: texts.home.timerBuilderSubtitle,
                  buttonLabel: texts.home.timerBuilderButton,
                  onPressed: _openTimerBuilder,
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
                        child: Column(
                          children: [activeSessionCard, timerBuilder],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(child: Column(children: [vehicleCard])),
                    ],
                  );
                }

                return Column(
                  children: [
                    activeSessionCard,
                    timerBuilder,
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
                  onOpenActivityHistory: () {
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

class _TimerBuilderResult {
  const _TimerBuilderResult({
    required this.activity,
    required this.duration,
    required this.markerMode,
    required this.activityMarkerSelection,
  });

  final ActivityDefinition activity;
  final Duration duration;
  final ActivityMarkerMode markerMode;
  final _ActivityMarkerSelection activityMarkerSelection;
}

class _CustomPresetNameResult {
  const _CustomPresetNameResult(this.customName);

  final String? customName;
}

class _CustomPresetNameDialog extends StatefulWidget {
  const _CustomPresetNameDialog({
    required this.title,
    required this.fieldLabel,
    required this.cancelLabel,
    required this.useOtherLabel,
    required this.saveLabel,
  });

  final String title;
  final String fieldLabel;
  final String cancelLabel;
  final String useOtherLabel;
  final String saveLabel;

  @override
  State<_CustomPresetNameDialog> createState() =>
      _CustomPresetNameDialogState();
}

class _CustomPresetNameDialogState extends State<_CustomPresetNameDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    Navigator.of(context).pop(_CustomPresetNameResult(value));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const ValueKey('timerBuilderCustomNameField'),
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(labelText: widget.fieldLabel),
        onSubmitted: _submit,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        TextButton(
          key: const ValueKey('timerBuilderUseOtherNameButton'),
          onPressed: () {
            Navigator.of(context).pop(const _CustomPresetNameResult(null));
          },
          child: Text(widget.useOtherLabel),
        ),
        FilledButton(
          key: const ValueKey('timerBuilderSaveCustomNameButton'),
          onPressed: () => _submit(_controller.text),
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
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
    final fallbackLogo = Align(
      alignment: Alignment.centerLeft,
      child: Text(
        semanticLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: AppColors.brown900,
          letterSpacing: 0,
        ),
      ),
    );

    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: SizedBox(
            key: const ValueKey('homeLogo'),
            width: 126,
            height: 89,
            child: Image.asset(
              _homeLogoAssetPath,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              cacheWidth: 360,
              errorBuilder: (context, error, stackTrace) => fallbackLogo,
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

class _TimerBuilderSection extends StatelessWidget {
  const _TimerBuilderSection({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

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
            Material(
              key: const ValueKey('createTimerCard'),
              color: AppColors.white.withValues(alpha: 0.82),
              borderRadius: AppRadius.compactCard,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                borderRadius: AppRadius.compactCard,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.compactCard,
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: AppRadius.pill,
                          ),
                          child: const SizedBox(
                            width: 46,
                            height: 46,
                            child: Icon(
                              Icons.timer_rounded,
                              color: AppColors.brown700,
                              size: 25,
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
                                buttonLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(
                                  color: AppColors.textStrong,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppBouncyButton(
                          key: const ValueKey('createTimerButton'),
                          label: buttonLabel,
                          icon: Icons.add_rounded,
                          onPressed: onPressed,
                          variant: AppButtonVariant.soft,
                          size: AppButtonSize.compact,
                          fullWidth: false,
                          minHeight: 42,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerBuilderSheet extends StatefulWidget {
  const _TimerBuilderSheet({
    this.recentPreset,
    required this.savedPresets,
    required this.savedTimerPresetService,
    required this.now,
  });

  final ActivityTimerPreset? recentPreset;
  final List<ActivityTimerPreset> savedPresets;
  final LocalSavedTimerPresetService savedTimerPresetService;
  final DateTime Function() now;

  @override
  State<_TimerBuilderSheet> createState() => _TimerBuilderSheetState();
}

class _TimerBuilderSheetState extends State<_TimerBuilderSheet> {
  late ActivityDefinition _selectedActivity = ActivityCatalog.defaultActivity;
  late double _minutes = _selectedActivity.defaultDuration.inMinutes.toDouble();
  ActivityMarkerMode _markerMode = ActivityMarkerMode.random;
  final Set<String> _selectedMarkerIds = {};
  late List<ActivityTimerPreset> _savedPresets;

  @override
  void initState() {
    super.initState();
    _savedPresets = List.unmodifiable(widget.savedPresets);
  }

  List<ActivityMarkerDefinition> get _availableMarkers {
    final candidateIds = ActivityMarkerCatalog.defaultSelectionIdsForActivity(
      _selectedActivity.id,
    );
    return List.unmodifiable(
      candidateIds.map(ActivityMarkerCatalog.findById).nonNulls,
    );
  }

  void _selectActivity(ActivityDefinition activity) {
    setState(() {
      _selectedActivity = activity;
      _minutes = activity.defaultDuration.inMinutes.toDouble();
      _selectedMarkerIds.clear();
    });
  }

  void _applyPreset(ActivityTimerPreset preset) {
    final activity = ActivityCatalog.findById(preset.activityId);
    final candidateMarkerIds =
        ActivityMarkerCatalog.defaultSelectionIdsForActivity(
          activity.id,
        ).toSet();
    final savedMarkerIds =
        preset.selectedMarkerIds.isEmpty &&
            preset.markerMode == ActivityMarkerMode.manual
        ? preset.markerIds
        : preset.selectedMarkerIds;
    final selectedMarkerIds = savedMarkerIds
        .where(candidateMarkerIds.contains)
        .take(ActivityMarkerCatalog.maxSelectableMarkerCount)
        .toList(growable: false);
    final markerMode =
        preset.markerMode == ActivityMarkerMode.manual &&
            selectedMarkerIds.isNotEmpty
        ? ActivityMarkerMode.manual
        : ActivityMarkerMode.random;

    setState(() {
      _selectedActivity = activity;
      _minutes = preset.duration.inMinutes
          .clamp(_minCustomActivityMinutes, _maxCustomActivityMinutes)
          .toDouble();
      _markerMode = markerMode;
      _selectedMarkerIds
        ..clear()
        ..addAll(
          markerMode == ActivityMarkerMode.manual
              ? selectedMarkerIds
              : const [],
        );
    });
  }

  void _selectMarkerMode(ActivityMarkerMode mode) {
    setState(() {
      _markerMode = mode;
    });
  }

  void _toggleMarker(ActivityMarkerDefinition marker) {
    setState(() {
      if (_selectedMarkerIds.contains(marker.id)) {
        _selectedMarkerIds.remove(marker.id);
        return;
      }
      if (_selectedMarkerIds.length <
          ActivityMarkerCatalog.maxSelectableMarkerCount) {
        _selectedMarkerIds.add(marker.id);
      }
    });
  }

  void _updateMinutes(double value) {
    setState(() {
      _minutes = value.clamp(
        _minCustomActivityMinutes.toDouble(),
        _maxCustomActivityMinutes.toDouble(),
      );
    });
  }

  void _adjustMinutes(int delta) {
    _updateMinutes((_minutes.round() + delta).toDouble());
  }

  ActivityTimerPreset _currentPreset({String? customName}) {
    final markerIds = _markerMode == ActivityMarkerMode.manual
        ? _selectedMarkerIds.toList(growable: false)
        : const <String>[];
    return ActivityTimerPreset(
      activityId: _selectedActivity.id,
      duration: Duration(minutes: _minutes.round()),
      markerMode: _markerMode,
      markerIds: markerIds,
      selectedMarkerIds: markerIds,
      updatedAt: widget.now(),
      customName: customName,
    );
  }

  Future<void> _savePreset() async {
    if (_markerMode == ActivityMarkerMode.manual &&
        _selectedMarkerIds.isEmpty) {
      return;
    }

    final customNameResult = _selectedActivity.id == ActivityCatalog.custom.id
        ? await _requestCustomPresetName()
        : const _CustomPresetNameResult(null);
    if (!mounted || customNameResult == null) {
      return;
    }

    final savedPresets = await widget.savedTimerPresetService.save(
      _currentPreset(customName: customNameResult.customName),
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _savedPresets = savedPresets;
    });
    final savedPresetMessage =
        savedPresets.length >= LocalSavedTimerPresetService.maxSavedPresets
        ? AppTexts.of(context).home.timerBuilderSavedPresetFullMessage
        : AppTexts.of(context).home.timerBuilderSavedPresetMessage;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(SnackBar(content: Text(savedPresetMessage)));
  }

  Future<_CustomPresetNameResult?> _requestCustomPresetName() async {
    final texts = AppTexts.of(context);
    return showDialog<_CustomPresetNameResult>(
      context: context,
      builder: (context) {
        return _CustomPresetNameDialog(
          title: texts.home.timerBuilderCustomNameDialogTitle,
          fieldLabel: texts.home.timerBuilderCustomNameFieldLabel,
          cancelLabel: texts.common.cancel,
          useOtherLabel: texts.home.timerBuilderUseOtherNameButton,
          saveLabel: texts.home.timerBuilderSavePresetButton,
        );
      },
    );
  }

  Future<void> _deleteSavedPreset(int index) async {
    final savedPresets = await widget.savedTimerPresetService.removeAt(index);
    if (!mounted) {
      return;
    }

    setState(() {
      _savedPresets = savedPresets;
    });
  }

  Future<void> _toggleSavedPresetFavorite(int index) async {
    final result = await widget.savedTimerPresetService.toggleFavoriteAt(index);
    if (!mounted) {
      return;
    }

    setState(() {
      _savedPresets = result.presets;
    });

    if (result.isLimitReached) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            AppTexts.of(context).home.timerBuilderFavoritePresetLimitMessage,
          ),
        ),
      );
    }
  }

  void _start() {
    if (_markerMode == ActivityMarkerMode.manual &&
        _selectedMarkerIds.isEmpty) {
      return;
    }

    final markerSelection = switch (_markerMode) {
      ActivityMarkerMode.manual => _ActivityMarkerSelection(
        markerIds: _selectedMarkerIds.toList(growable: false),
        selectedMarkerIds: _selectedMarkerIds.toList(growable: false),
      ),
      _ => _ActivityMarkerSelection(
        markerIds: ActivityMarkerCatalog.randomSelectionIds(
          activityId: _selectedActivity.id,
        ),
        selectedMarkerIds: const [],
      ),
    };

    Navigator.of(context).pop(
      _TimerBuilderResult(
        activity: _selectedActivity,
        duration: Duration(minutes: _minutes.round()),
        markerMode: _markerMode,
        activityMarkerSelection: markerSelection,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final homeTexts = texts.home;
    final textTheme = Theme.of(context).textTheme;
    final mediaQuery = MediaQuery.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final selectedMinuteLabel = homeTexts.minuteLabel(_minutes.round());
    final recentPreset = widget.recentPreset;
    final recentActivity = recentPreset == null
        ? null
        : ActivityCatalog.findById(recentPreset.activityId);
    final recentMarkerModeLabel =
        recentPreset?.markerMode == ActivityMarkerMode.manual
        ? homeTexts.timerBuilderManualMarkerOption
        : homeTexts.timerBuilderRandomMarkerOption;
    final savedPresetCountLabel = homeTexts.timerBuilderSavedPresetCount(
      _savedPresets.length,
      LocalSavedTimerPresetService.maxSavedPresets,
    );
    final isSavedPresetListFull =
        _savedPresets.length >= LocalSavedTimerPresetService.maxSavedPresets;
    final savedPresetCards = _savedPresets.indexed
        .map((entry) {
          final index = entry.$1;
          final preset = entry.$2;
          final activity = ActivityCatalog.findById(preset.activityId);
          final markerModeLabel = preset.markerMode == ActivityMarkerMode.manual
              ? homeTexts.timerBuilderManualMarkerOption
              : homeTexts.timerBuilderRandomMarkerOption;
          return _TimerBuilderPresetCard(
            key: ValueKey('timerBuilderSavedPresetCard_$index'),
            applyButtonKey: ValueKey(
              'timerBuilderSavedPresetApplyButton_$index',
            ),
            deleteButtonKey: ValueKey(
              'timerBuilderSavedPresetDeleteButton_$index',
            ),
            favoriteButtonKey: ValueKey(
              'timerBuilderSavedPresetFavoriteButton_$index',
            ),
            applyLabel: homeTexts.timerBuilderRecentPresetApplyButton,
            deleteTooltip: homeTexts.timerBuilderDeletePresetTooltip,
            favoriteTooltip: preset.isFavorite
                ? homeTexts.timerBuilderUnfavoritePresetTooltip
                : homeTexts.timerBuilderFavoritePresetTooltip,
            isFavorite: preset.isFavorite,
            activityEmoji: activity.emoji,
            activityLabel: _presetActivityLabel(preset, activity, languageCode),
            durationLabel: homeTexts.minuteLabel(preset.duration.inMinutes),
            markerModeLabel: markerModeLabel,
            onApply: () => _applyPreset(preset),
            onDelete: () => _deleteSavedPreset(index),
            onFavoriteToggle: () => _toggleSavedPresetFavorite(index),
          );
        })
        .toList(growable: false);
    final canStart =
        _markerMode != ActivityMarkerMode.manual ||
        _selectedMarkerIds.isNotEmpty;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.92),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: AppShadows.hero,
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xl +
                    mediaQuery.padding.bottom +
                    mediaQuery.viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  key: const ValueKey('timerBuilderSheet'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.borderSoft,
                          borderRadius: AppRadius.pill,
                        ),
                        child: const SizedBox(width: 44, height: 5),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            homeTexts.timerBuilderSheetTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleLarge?.copyWith(
                              color: AppColors.textStrong,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton.filledTonal(
                          onPressed: () => Navigator.of(context).pop(),
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
                    const SizedBox(height: AppSpacing.lg),
                    if (savedPresetCards.isNotEmpty) ...[
                      _TimerBuilderSavedPresetHeader(
                        title: homeTexts.timerBuilderSavedPresetTitle,
                        countLabel: savedPresetCountLabel,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final card in savedPresetCards) ...[
                              SizedBox(width: 252, child: card),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (recentPreset != null && recentActivity != null) ...[
                      _TimerBuilderPresetCard(
                        key: const ValueKey('timerBuilderRecentPresetCard'),
                        applyButtonKey: const ValueKey(
                          'timerBuilderRecentPresetApplyButton',
                        ),
                        title: homeTexts.timerBuilderRecentPresetTitle,
                        applyLabel:
                            homeTexts.timerBuilderRecentPresetApplyButton,
                        activityEmoji: recentActivity.emoji,
                        activityLabel: _presetActivityLabel(
                          recentPreset,
                          recentActivity,
                          languageCode,
                        ),
                        durationLabel: homeTexts.minuteLabel(
                          recentPreset.duration.inMinutes,
                        ),
                        markerModeLabel: recentMarkerModeLabel,
                        onApply: () => _applyPreset(recentPreset),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    _TimerBuilderStepTitle(
                      title: homeTexts.timerBuilderActivityStepTitle,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final activity in ActivityCatalog.all)
                          _TimerBuilderActivityChip(
                            activity: activity,
                            label: activity.labelForLanguage(languageCode),
                            isSelected: activity.id == _selectedActivity.id,
                            onSelected: () => _selectActivity(activity),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _TimerBuilderStepTitle(
                      title: homeTexts.timerBuilderMarkerStepTitle,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _TimerBuilderModeButton(
                            key: const ValueKey('timerBuilderMarkerRandom'),
                            label: homeTexts.timerBuilderRandomMarkerOption,
                            icon: Icons.shuffle_rounded,
                            isSelected:
                                _markerMode == ActivityMarkerMode.random,
                            onPressed: () =>
                                _selectMarkerMode(ActivityMarkerMode.random),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _TimerBuilderModeButton(
                            key: const ValueKey('timerBuilderMarkerManual'),
                            label: homeTexts.timerBuilderManualMarkerOption,
                            icon: Icons.touch_app_rounded,
                            isSelected:
                                _markerMode == ActivityMarkerMode.manual,
                            onPressed: () =>
                                _selectMarkerMode(ActivityMarkerMode.manual),
                          ),
                        ),
                      ],
                    ),
                    if (_markerMode == ActivityMarkerMode.manual) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        homeTexts.timerBuilderSelectedMarkerEmpty,
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final marker in _availableMarkers)
                            _TimerBuilderMarkerChip(
                              marker: marker,
                              isSelected: _selectedMarkerIds.contains(
                                marker.id,
                              ),
                              isEnabled:
                                  _selectedMarkerIds.contains(marker.id) ||
                                  _selectedMarkerIds.length <
                                      ActivityMarkerCatalog
                                          .maxSelectableMarkerCount,
                              onSelected: () => _toggleMarker(marker),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _TimerBuilderStepTitle(
                            title: homeTexts.timerBuilderTimeStepTitle,
                          ),
                        ),
                        Text(
                          selectedMinuteLabel,
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.textStrong,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.borderSoft,
                        thumbColor: AppColors.primarySoft,
                        overlayColor: AppColors.primary.withValues(alpha: 0.12),
                        valueIndicatorColor: AppColors.brown900,
                        valueIndicatorTextStyle: textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w900,
                            ),
                        trackHeight: 6,
                      ),
                      child: Slider(
                        key: const ValueKey('timerBuilderMinuteSlider'),
                        value: _minutes,
                        min: _minCustomActivityMinutes.toDouble(),
                        max: _maxCustomActivityMinutes.toDouble(),
                        label: selectedMinuteLabel,
                        onChanged: _updateMinutes,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _MinuteAdjustButton(
                            label: '-5',
                            onPressed: () => _adjustMinutes(-5),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _MinuteAdjustButton(
                            label: '-1',
                            onPressed: () => _adjustMinutes(-1),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _MinuteAdjustButton(
                            label: '+1',
                            onPressed: () => _adjustMinutes(1),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _MinuteAdjustButton(
                            label: '+5',
                            onPressed: () => _adjustMinutes(5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (isSavedPresetListFull) ...[
                      _TimerBuilderSavedPresetLimitHint(
                        title:
                            '${homeTexts.timerBuilderSavedPresetTitle} $savedPresetCountLabel',
                        text: homeTexts.timerBuilderSavedPresetLimitHint,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey('timerBuilderSavePresetButton'),
                            onPressed: canStart ? _savePreset : null,
                            icon: const Icon(Icons.bookmark_add_rounded),
                            label: Text(
                              homeTexts.timerBuilderSavePresetButton,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(
                                color: AppColors.borderWarm,
                              ),
                              shape: const StadiumBorder(),
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppBouncyButton(
                            key: const ValueKey('timerBuilderStartButton'),
                            label: homeTexts.timerBuilderStartButton,
                            icon: Icons.flag_rounded,
                            onPressed: canStart ? _start : null,
                            variant: AppButtonVariant.soft,
                            size: AppButtonSize.medium,
                          ),
                        ),
                      ],
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

class _TimerBuilderPresetCard extends StatelessWidget {
  const _TimerBuilderPresetCard({
    super.key,
    required this.applyButtonKey,
    required this.applyLabel,
    required this.activityEmoji,
    required this.activityLabel,
    required this.durationLabel,
    required this.markerModeLabel,
    required this.onApply,
    this.title,
    this.deleteButtonKey,
    this.deleteTooltip,
    this.onDelete,
    this.favoriteButtonKey,
    this.favoriteTooltip,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final Key applyButtonKey;
  final String? title;
  final String applyLabel;
  final String activityEmoji;
  final String activityLabel;
  final String durationLabel;
  final String markerModeLabel;
  final VoidCallback onApply;
  final Key? deleteButtonKey;
  final String? deleteTooltip;
  final VoidCallback? onDelete;
  final Key? favoriteButtonKey;
  final String? favoriteTooltip;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.82),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceYellow,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Text(
                      activityEmoji,
                      textScaler: TextScaler.noScaling,
                      style: textTheme.titleLarge,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null) ...[
                        Text(
                          title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                      Text(
                        '$activityLabel · $durationLabel · $markerModeLabel',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.textStrong,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onFavoriteToggle != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    key: favoriteButtonKey,
                    onPressed: onFavoriteToggle,
                    tooltip: favoriteTooltip,
                    icon: Icon(
                      isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                    ),
                    color: isFavorite
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    style: IconButton.styleFrom(
                      fixedSize: const Size(36, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
                if (onDelete != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    key: deleteButtonKey,
                    onPressed: onDelete,
                    tooltip: deleteTooltip,
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                    style: IconButton.styleFrom(
                      fixedSize: const Size(36, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: applyButtonKey,
                onPressed: onApply,
                style: TextButton.styleFrom(
                  minimumSize: const Size(72, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(applyLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _presetActivityLabel(
  ActivityTimerPreset preset,
  ActivityDefinition activity,
  String languageCode,
) {
  return preset.customName ?? activity.labelForLanguage(languageCode);
}

class _TimerBuilderStepTitle extends StatelessWidget {
  const _TimerBuilderStepTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.textStrong,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _TimerBuilderSavedPresetHeader extends StatelessWidget {
  const _TimerBuilderSavedPresetHeader({
    required this.title,
    required this.countLabel,
  });

  final String title;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(child: _TimerBuilderStepTitle(title: title)),
        const SizedBox(width: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.74),
            borderRadius: AppRadius.pill,
            border: Border.all(color: AppColors.borderWarm),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              countLabel,
              key: const ValueKey('timerBuilderSavedPresetCount'),
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimerBuilderSavedPresetLimitHint extends StatelessWidget {
  const _TimerBuilderSavedPresetLimitHint({
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      key: const ValueKey('timerBuilderSavedPresetLimitHint'),
      decoration: BoxDecoration(
        color: AppColors.surfaceYellow.withValues(alpha: 0.76),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.brown700,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
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

class _TimerBuilderActivityChip extends StatelessWidget {
  const _TimerBuilderActivityChip({
    required this.activity,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final ActivityDefinition activity;
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      key: ValueKey('timerBuilderActivity_${activity.id}'),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      avatar: Text(activity.emoji, textScaler: TextScaler.noScaling),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: isSelected ? AppColors.textStrong : AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      selectedColor: AppColors.surfaceYellow,
      backgroundColor: AppColors.white.withValues(alpha: 0.82),
      side: BorderSide(
        color: isSelected ? AppColors.primarySoft : AppColors.borderSoft,
      ),
      showCheckmark: false,
    );
  }
}

class _TimerBuilderModeButton extends StatelessWidget {
  const _TimerBuilderModeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? AppColors.surfaceYellow
            : AppColors.white.withValues(alpha: 0.78),
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(
          color: isSelected ? AppColors.primarySoft : AppColors.borderSoft,
          width: isSelected ? 1.4 : 1,
        ),
        shape: const StadiumBorder(),
        minimumSize: const Size.fromHeight(44),
      ),
    );
  }
}

class _TimerBuilderMarkerChip extends StatelessWidget {
  const _TimerBuilderMarkerChip({
    required this.marker,
    required this.isSelected,
    required this.isEnabled,
    required this.onSelected,
  });

  final ActivityMarkerDefinition marker;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final label = marker.labelForLanguage(
      Localizations.localeOf(context).languageCode,
    );

    return ChoiceChip(
      key: ValueKey('timerBuilderMarker_${marker.id}'),
      selected: isSelected,
      onSelected: isEnabled ? (_) => onSelected() : null,
      avatar: Text(marker.emoji, textScaler: TextScaler.noScaling),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: isSelected ? AppColors.textStrong : AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      selectedColor: AppColors.surfaceYellow,
      backgroundColor: AppColors.white.withValues(alpha: 0.82),
      disabledColor: AppColors.white.withValues(alpha: 0.44),
      side: BorderSide(
        color: isSelected ? AppColors.primarySoft : AppColors.borderSoft,
      ),
      showCheckmark: false,
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.childName,
    required this.snapshot,
    required this.onOpenActivityHistory,
    required this.onOpenRewardGoal,
    required this.onOpenStickers,
  });

  final String childName;
  final ActivityProgressSnapshot? snapshot;
  final VoidCallback onOpenActivityHistory;
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
        _ActivityHistorySummaryButton(
          title: texts.home.progressTitle(childName),
          activityValue: texts.home.activityCount(history.length),
          stickerKindValue: texts.home.stickerKindCount(stickerKindCount),
          stickerValue: texts.home.stickerCount(stickerCount),
          recentSummary: recent == null
              ? texts.home.noActivityHistory
              : [
                  texts.home.recentActivitySummary(
                    formatDuration(recentDisplayDuration),
                    recent.completionStatus,
                  ),
                  if (!recent.activityCompleted)
                    texts.activityHistory.noRewardLabel,
                  if (!recent.activityCompleted &&
                      recentOverrun > Duration.zero)
                    texts.activityHistory.overrunTime(
                      formatDuration(recentOverrun),
                    ),
                ].join(' · '),
          onPressed: onOpenActivityHistory,
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

class _ActivityHistorySummaryButton extends StatelessWidget {
  const _ActivityHistorySummaryButton({
    required this.title,
    required this.activityValue,
    required this.stickerKindValue,
    required this.stickerValue,
    required this.recentSummary,
    required this.onPressed,
  });

  final String title;
  final String activityValue;
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
                      icon: Icons.flag_rounded,
                      label: texts.home.activitySummaryLabel,
                      value: activityValue,
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
