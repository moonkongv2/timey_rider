import 'package:flutter/material.dart';

import '../l10n/app_texts.dart';
import '../models/meal_progress_snapshot.dart';
import '../models/meal_timer_config.dart';
import '../models/reward_item.dart';
import '../services/local_meal_progress_service.dart';
import '../utils/duration_format.dart';
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
  late double _customMinutes = widget.config.duration.inMinutes.toDouble();

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.duration != widget.config.duration) {
      _customMinutes = widget.config.duration.inMinutes.toDouble();
    }
  }

  void _startTimer(int minutes) {
    final config = widget.config.copyWith(duration: Duration(minutes: minutes));
    widget.onConfigChanged(config);
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
        builder: (_) => SettingsScreen(
          config: widget.config,
          onConfigChanged: widget.onConfigChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTexts.common.appTitle,
                        style: textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF3D332B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppTexts.home.subtitle,
                        style: textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF7A6250),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings_rounded),
                  tooltip: AppTexts.common.settings,
                ),
              ],
            ),
            const SizedBox(height: 28),
            _PresetButton(
              label: AppTexts.home.morningCourse,
              emoji: '🌞',
              onPressed: () => _startTimer(15),
            ),
            const SizedBox(height: 12),
            _PresetButton(
              label: AppTexts.home.normalCourse,
              emoji: '🍚',
              onPressed: () => _startTimer(25),
            ),
            const SizedBox(height: 12),
            _PresetButton(
              label: AppTexts.home.slowCourse,
              emoji: '🌈',
              onPressed: () => _startTimer(35),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTexts.home.customSettingMinutes(
                        _customMinutes.round(),
                      ),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Slider(
                      value: _customMinutes,
                      min: 1,
                      max: 60,
                      label: AppTexts.home.minuteLabel(_customMinutes.round()),
                      onChanged: (value) {
                        setState(() => _customMinutes = value);
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _MinuteAdjustButton(
                            label: '-5',
                            onPressed: () => _adjustCustomMinutes(-5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MinuteAdjustButton(
                            label: '-1',
                            onPressed: () => _adjustCustomMinutes(-1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MinuteAdjustButton(
                            label: '+1',
                            onPressed: () => _adjustCustomMinutes(1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MinuteAdjustButton(
                            label: '+5',
                            onPressed: () => _adjustCustomMinutes(5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _startTimer(_customMinutes.round()),
                      icon: const Icon(Icons.two_wheeler_rounded),
                      label: Text(AppTexts.home.customStartButton),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FutureBuilder<MealProgressSnapshot>(
              future: widget.mealProgressService.loadSnapshot(),
              builder: (context, snapshot) {
                return _ProgressSummary(
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

class _MinuteAdjustButton extends StatelessWidget {
  const _MinuteAdjustButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.snapshot,
    required this.onOpenStickers,
  });

  final MealProgressSnapshot? snapshot;
  final VoidCallback onOpenStickers;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTexts.home.progressTitle(AppTexts.common.defaultChildName),
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.restaurant_rounded,
                    label: AppTexts.home.mealSummaryLabel,
                    value: AppTexts.home.mealCount(history.length),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.auto_awesome_rounded,
                    label: AppTexts.home.stickerKindSummaryLabel,
                    value: AppTexts.home.stickerKindCount(stickerKindCount),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.stars_rounded,
                    label: AppTexts.home.stickerSummaryLabel,
                    value: AppTexts.home.stickerCount(stickerCount),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              recent == null
                  ? AppTexts.home.noMealHistory
                  : AppTexts.home.recentMealSummary(
                      formatDuration(recent.actualDuration),
                      recent.completedBeforeArrival,
                    ),
              style: textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF7A6250),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onOpenStickers,
              icon: const Icon(Icons.collections_bookmark_rounded),
              label: Text(AppTexts.home.openStickerCollection),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF7A6250)),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF7A6250),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.emoji,
    required this.onPressed,
  });

  final String label;
  final String emoji;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}
