import 'package:flutter/material.dart';

import '../catalogs/vehicle_catalog.dart';
import '../l10n/app_texts.dart';
import '../models/meal_progress_snapshot.dart';
import '../models/meal_timer_config.dart';
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
import '../widgets/vehicle_selection_card.dart';
import 'avatar_setup_screen.dart';
import 'settings_screen.dart';
import 'sticker_collection_screen.dart';
import 'timer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.config,
    required this.mealProgressService,
    required this.onConfigChanged,
  });

  final MealTimerConfig config;
  final LocalMealProgressService mealProgressService;
  final ValueChanged<MealTimerConfig> onConfigChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  void _updateConfig(MealTimerConfig config) {
    setState(() => _config = config);
    widget.onConfigChanged(config);
  }

  void _startTimer(int minutes) {
    final config = _config.copyWith(duration: Duration(minutes: minutes));
    _updateConfig(config);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          config: config,
          mealProgressService: widget.mealProgressService,
          onConfigChanged: widget.onConfigChanged,
        ),
      ),
    );
  }

  void _adjustCustomMinutes(int delta) {
    final minutes = (_customMinutes.round() + delta).clamp(1, 60);
    setState(() => _customMinutes = minutes.toDouble());
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
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context);
    final childName = _config.childName.trim().isEmpty
        ? texts.common.defaultChildName
        : _config.childName.trim();
    final selectedVehicle = VehicleCatalog.findById(_config.motorcycleId);

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
                    children: [
                      Text(
                        texts.common.appTitle,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.brown900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        texts.home.subtitle,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.brown500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings_rounded),
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
            const SizedBox(height: AppSpacing.xl),
            LayoutBuilder(
              builder: (context, constraints) {
                final vehicleCard = VehicleSelectionCard(
                  title: texts.home.todayVehicleTitle,
                  subtitle: texts.settings.vehicleSelection,
                  selectedVehicleId: _config.motorcycleId,
                  onVehicleSelected: (vehicleId) {
                    _updateConfig(_config.copyWith(motorcycleId: vehicleId));
                  },
                );
                final avatarCard = _AvatarCtaCard(
                  title: texts.home.avatarCtaTitle,
                  subtitle: texts.home.avatarCtaSubtitle,
                  buttonLabel: texts.home.avatarCtaButton,
                  onPressed: _openAvatarSetup,
                );
                final heroCard = _HeroMissionCard(
                  ctaLabel: '${texts.home.normalCourse} ${texts.common.start}',
                  vehicle: selectedVehicle,
                  onStart: () => _startTimer(25),
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
                            vehicleCard,
                            const SizedBox(height: AppSpacing.md),
                            avatarCard,
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
                    vehicleCard,
                    const SizedBox(height: AppSpacing.md),
                    avatarCard,
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            LayoutBuilder(
              builder: (context, constraints) {
                final presetCards = [
                  _PresetMissionCard(
                    label: texts.home.morningCourse,
                    emoji: '🌞',
                    subtitle: texts.home.morningCourseSubtitle,
                    backgroundColor: AppColors.surfaceYellow,
                    onPressed: () => _startTimer(15),
                  ),
                  _PresetMissionCard(
                    label: texts.home.normalCourse,
                    emoji: '🍚',
                    subtitle: texts.home.normalCourseSubtitle,
                    backgroundColor: AppColors.primarySoft,
                    badge: texts.home.recommendedBadge,
                    onPressed: () => _startTimer(25),
                  ),
                  _PresetMissionCard(
                    label: texts.home.slowCourse,
                    emoji: '🌈',
                    subtitle: texts.home.slowCourseSubtitle,
                    backgroundColor: AppColors.surfacePink,
                    onPressed: () => _startTimer(35),
                  ),
                ];

                if (constraints.maxWidth >= 700) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (
                        var index = 0;
                        index < presetCards.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(width: AppSpacing.md),
                        Expanded(child: presetCards[index]),
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    for (
                      var index = 0;
                      index < presetCards.length;
                      index++
                    ) ...[
                      if (index > 0) const SizedBox(height: AppSpacing.md),
                      presetCards[index],
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            _CustomMinutesCard(
              title: texts.home.customSettingMinutes(_customMinutes.round()),
              sliderLabel: texts.home.minuteLabel(_customMinutes.round()),
              minutes: _customMinutes,
              startLabel: texts.home.customStartButton,
              onChanged: (value) {
                setState(() => _customMinutes = value);
              },
              onAdjust: _adjustCustomMinutes,
              onStart: () => _startTimer(_customMinutes.round()),
            ),
            const SizedBox(height: AppSpacing.xxl),
            FutureBuilder<MealProgressSnapshot>(
              future: widget.mealProgressService.loadSnapshot(),
              builder: (context, snapshot) {
                return _ProgressSummary(
                  childName: childName,
                  snapshot: snapshot.data,
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

class _AvatarCtaCard extends StatelessWidget {
  const _AvatarCtaCard({
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
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfacePink.withValues(alpha: 0.72),
                    borderRadius: AppRadius.pill,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Icon(
                      Icons.face_retouching_natural_rounded,
                      color: AppColors.brown700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.36,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(buttonLabel),
              ),
            ),
          ],
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
    required this.onStart,
  });

  final String ctaLabel;
  final VehicleDefinition vehicle;
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
                      child: Image.asset(
                        vehicle.assetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              vehicle.emoji,
                              textScaler: TextScaler.noScaling,
                              style: const TextStyle(fontSize: 50, height: 1),
                            ),
                          );
                        },
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

class _PresetMissionCard extends StatelessWidget {
  const _PresetMissionCard({
    required this.label,
    required this.emoji,
    required this.subtitle,
    required this.backgroundColor,
    required this.onPressed,
    this.badge,
  });

  final String label;
  final String emoji;
  final String subtitle;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor.withValues(alpha: 0.48),
            AppColors.surfaceWarm.withValues(alpha: 0.72),
            AppColors.white.withValues(alpha: 0.92),
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
                    color: AppColors.white.withValues(alpha: 0.64),
                    borderRadius: AppRadius.compactCard,
                  ),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Text(
                        emoji,
                        textScaler: TextScaler.noScaling,
                        style: const TextStyle(fontSize: 27, height: 1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            label,
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.textStrong,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (badge != null) _RecommendedBadge(label: badge!),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          height: 1.34,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.72),
                    borderRadius: AppRadius.pill,
                    border: Border.all(
                      color: AppColors.borderSoft.withValues(alpha: 0.68),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.xs),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.brown700,
                    ),
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

class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.62),
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.54)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.brown700,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CustomMinutesCard extends StatelessWidget {
  const _CustomMinutesCard({
    required this.title,
    required this.sliderLabel,
    required this.minutes,
    required this.startLabel,
    required this.onChanged,
    required this.onAdjust,
    required this.onStart,
  });

  final String title;
  final String sliderLabel;
  final double minutes;
  final String startLabel;
  final ValueChanged<double> onChanged;
  final ValueChanged<int> onAdjust;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: AppRadius.panel,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: AppShadows.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textStrong,
                fontWeight: FontWeight.w800,
                height: 1.28,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.childName,
    required this.snapshot,
    required this.onOpenStickers,
  });

  final String childName;
  final MealProgressSnapshot? snapshot;
  final VoidCallback onOpenStickers;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context);
    final history = snapshot?.history ?? const [];
    final inventory = snapshot?.inventory ?? const [];
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
        _StickerCollectionCta(
          label: texts.home.openStickerCollection,
          onPressed: onOpenStickers,
        ),
      ],
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
