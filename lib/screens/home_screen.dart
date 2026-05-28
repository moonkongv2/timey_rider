import 'dart:io';

import 'package:flutter/material.dart';

import '../catalogs/vehicle_catalog.dart';
import '../l10n/app_texts.dart';
import '../models/meal_progress_snapshot.dart';
import '../models/meal_timer_config.dart';
import '../navigation/app_route_observer.dart';
import '../models/reward_goal.dart';
import '../models/reward_item.dart';
import '../models/vehicle.dart';
import '../services/local_meal_progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../utils/duration_format.dart';
import '../widgets/app/app_bouncy_button.dart';
import '../widgets/app/app_metric_tile.dart';
import '../widgets/avatar/avatar_composite_preview.dart';
import '../widgets/reward_sticker_image.dart';
import '../widgets/vehicle_selection_card.dart';
import 'avatar_setup_screen.dart';
import 'reward_goal_screen.dart';
import 'settings_screen.dart';
import 'sticker_collection_screen.dart';
import 'timer_screen.dart';

const _homeLogoAssetPath = 'assets/images/logo_eng.png';
const _settingsIconAssetPath = 'assets/images/icon_setting_rgba.png';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.config,
    required this.mealProgressService,
    required this.onConfigChanged,
    this.avatarImageBuilder,
  });

  final MealTimerConfig config;
  final LocalMealProgressService mealProgressService;
  final ValueChanged<MealTimerConfig> onConfigChanged;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  late MealTimerConfig _config = widget.config;
  late double _customMinutes = _config.duration.inMinutes.toDouble();

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _config = widget.config;
    }
    if (oldWidget.config.duration != _config.duration) {
      _customMinutes = _config.duration.inMinutes.toDouble();
    }
  }

  void _refreshProgressSnapshot() {
    setState(() {});
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
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshProgressSnapshot();
  }

  void _updateConfig(MealTimerConfig config) {
    setState(() => _config = config);
    widget.onConfigChanged(config);
  }

  Future<void> _startTimer(int minutes) async {
    final config = _config.copyWith(duration: Duration(minutes: minutes));
    _updateConfig(config);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          config: config,
          mealProgressService: widget.mealProgressService,
          onConfigChanged: widget.onConfigChanged,
        ),
      ),
    );
    if (mounted) {
      _refreshProgressSnapshot();
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
              final minutes = value.clamp(1.0, 60.0);
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
    final selectedVehicle = VehicleCatalog.findById(_config.motorcycleId);
    final selectedVehicleAvatarMode = _config.avatarModeForVehicle(
      selectedVehicle.id,
    );
    final selectedVehicleAvatarImagePath = _config
        .customAvatarImagePathForVehicle(selectedVehicle.id);
    final isUsingCustomAvatar =
        selectedVehicleAvatarMode == AvatarImageMode.custom &&
        selectedVehicleAvatarImagePath != null &&
        File(selectedVehicleAvatarImagePath).existsSync();
    final avatarStateText = isUsingCustomAvatar
        ? texts.home.avatarInlineCustomState
        : texts.home.avatarInlineDefaultState;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          cacheExtent: 1200,
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
                  selectedVehicleId: _config.motorcycleId,
                  onVehicleSelected: (vehicleId) {
                    _updateConfig(_config.copyWith(motorcycleId: vehicleId));
                  },
                  avatarMode: selectedVehicleAvatarMode,
                  customAvatarImagePath: selectedVehicleAvatarImagePath,
                  avatarScale: _config.avatarScale,
                  avatarOffsetX: _config.avatarOffsetX,
                  avatarOffsetY: _config.avatarOffsetY,
                  avatarRotationDegrees: _config.avatarRotationDegrees,
                  avatarImageBuilder: widget.avatarImageBuilder,
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
                  ctaLabel: '${texts.home.normalCourse} ${texts.common.start}',
                  vehicle: selectedVehicle,
                  avatarMode: selectedVehicleAvatarMode,
                  customAvatarImagePath: selectedVehicleAvatarImagePath,
                  avatarScale: _config.avatarScale,
                  avatarOffsetX: _config.avatarOffsetX,
                  avatarOffsetY: _config.avatarOffsetY,
                  avatarRotationDegrees: _config.avatarRotationDegrees,
                  avatarImageBuilder: widget.avatarImageBuilder,
                  onStart: () => _startTimer(25),
                );
                final quickCourses = _QuickCourseSection(
                  title: texts.home.quickCourseTitle,
                  children: [
                    _QuickCourseButton(
                      label: texts.home.morningCourse,
                      subtitle: texts.home.morningCourseSubtitle,
                      emoji: '🌞',
                      onPressed: () => _startTimer(15),
                    ),
                    _QuickCourseButton(
                      label: texts.home.slowCourse,
                      subtitle: texts.home.slowCourseSubtitle,
                      emoji: '🌈',
                      onPressed: () => _startTimer(35),
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

                if (constraints.maxWidth >= 700) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: heroCard),
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
            FutureBuilder<MealProgressSnapshot>(
              future: widget.mealProgressService.loadSnapshot(),
              builder: (context, snapshot) {
                return _ProgressSummary(
                  childName: childName,
                  snapshot: snapshot.data,
                  onOpenRewardGoal: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RewardGoalScreen(
                          mealProgressService: widget.mealProgressService,
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
                          mealProgressService: widget.mealProgressService,
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
    required this.avatarMode,
    required this.customAvatarImagePath,
    required this.avatarScale,
    required this.avatarOffsetX,
    required this.avatarOffsetY,
    required this.avatarRotationDegrees,
    this.avatarImageBuilder,
    required this.onStart,
  });

  final String ctaLabel;
  final VehicleDefinition vehicle;
  final AvatarImageMode avatarMode;
  final String? customAvatarImagePath;
  final double avatarScale;
  final double avatarOffsetX;
  final double avatarOffsetY;
  final double avatarRotationDegrees;
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
                        avatarMode: avatarMode,
                        customAvatarImagePath: customAvatarImagePath,
                        avatarScale: avatarScale,
                        avatarOffsetX: avatarOffsetX,
                        avatarOffsetY: avatarOffsetY,
                        avatarRotationDegrees: avatarRotationDegrees,
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
                final columns = constraints.maxWidth >= 520 ? 3 : 2;
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
              min: 1,
              max: 60,
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
    required this.onOpenRewardGoal,
    required this.onOpenStickers,
  });

  final String childName;
  final MealProgressSnapshot? snapshot;
  final VoidCallback onOpenRewardGoal;
  final VoidCallback onOpenStickers;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context);
    final history = snapshot?.history ?? const [];
    final inventory = snapshot?.inventory ?? const [];
    final activeRewardGoal = snapshot?.activeRewardGoal;
    final recent = history.isEmpty ? null : history.first;
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
        Text(
          texts.home.progressTitle(childName),
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.textStrong,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppMetricTile(
                icon: Icons.restaurant_rounded,
                label: texts.home.mealSummaryLabel,
                value: texts.home.mealCount(history.length),
                backgroundColor: AppColors.surfaceMint,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppMetricTile(
                icon: Icons.auto_awesome_rounded,
                label: texts.home.stickerKindSummaryLabel,
                value: texts.home.stickerKindCount(stickerKindCount),
                backgroundColor: AppColors.surfaceBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppMetricTile(
                icon: Icons.stars_rounded,
                label: texts.home.stickerSummaryLabel,
                value: texts.home.stickerCount(stickerCount),
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
            child: Text(
              recent == null
                  ? texts.home.noMealHistory
                  : texts.home.recentMealSummary(
                      formatDuration(recent.actualDuration),
                      recent.completedBeforeArrival,
                    ),
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1.34,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _RewardGoalCta(goal: activeRewardGoal, onPressed: onOpenRewardGoal),
        const SizedBox(height: AppSpacing.md),
        _StickerCollectionCta(
          label: texts.home.openStickerCollection,
          onPressed: onOpenStickers,
        ),
      ],
    );
  }
}

class _RewardGoalCta extends StatelessWidget {
  const _RewardGoalCta({required this.goal, required this.onPressed});

  final RewardGoal? goal;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final goal = this.goal;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: goal?.isReady == true
            ? AppColors.surfaceYellow
            : AppColors.white,
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
            child: goal == null
                ? _EmptyRewardGoalCta(label: texts.rewards.createRewardGoal)
                : _ActiveRewardGoalCta(goal: goal),
          ),
        ),
      ),
    );
  }
}

class _EmptyRewardGoalCta extends StatelessWidget {
  const _EmptyRewardGoalCta({required this.label});

  final String label;

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
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textStrong,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Icon(Icons.arrow_forward_rounded, color: AppColors.textPrimary),
      ],
    );
  }
}

class _ActiveRewardGoalCta extends StatelessWidget {
  const _ActiveRewardGoalCta({required this.goal});

  final RewardGoal goal;

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
                goal.isReady
                    ? texts.rewards.rewardGoalReadyMessage
                    : texts.rewards.rewardGoalPromiseTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                goal.rewardText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textStrong,
                  fontWeight: FontWeight.w900,
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
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _MiniRewardGoalBoard(goal: goal),
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
