import 'package:flutter/material.dart';

import '../models/meal_timer_config.dart';
import 'settings_screen.dart';
import 'timer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

  final MealTimerConfig config;
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
          onConfigChanged: widget.onConfigChanged,
        ),
      ),
    );
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
                        '냠냠 라이더',
                        style: textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF3D332B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '오늘도 밥길을 달려볼까?',
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
                  tooltip: '설정',
                ),
              ],
            ),
            const SizedBox(height: 28),
            _PresetButton(
              label: '15분 아침 코스',
              emoji: '🌞',
              onPressed: () => _startTimer(15),
            ),
            const SizedBox(height: 12),
            _PresetButton(
              label: '25분 보통 코스',
              emoji: '🍚',
              onPressed: () => _startTimer(25),
            ),
            const SizedBox(height: 12),
            _PresetButton(
              label: '35분 천천히 코스',
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
                      '직접 설정: ${_customMinutes.round()}분',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Slider(
                      value: _customMinutes,
                      min: 5,
                      max: 60,
                      divisions: 11,
                      label: '${_customMinutes.round()}분',
                      onChanged: (value) {
                        setState(() => _customMinutes = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _startTimer(_customMinutes.round()),
                      icon: const Icon(Icons.two_wheeler_rounded),
                      label: const Text('직접 설정으로 출발'),
                    ),
                  ],
                ),
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
