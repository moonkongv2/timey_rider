import 'package:flutter/material.dart';

import '../models/meal_timer_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

  final MealTimerConfig config;
  final ValueChanged<MealTimerConfig> onConfigChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late MealTimerConfig _config = widget.config;

  void _update(MealTimerConfig config) {
    setState(() => _config = config);
    widget.onConfigChanged(config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('남은 시간 보여주기'),
                  value: _config.showRemainingTime,
                  onChanged: (value) {
                    _update(_config.copyWith(showRemainingTime: value));
                  },
                ),
                SwitchListTile(
                  title: const Text('효과음 사용'),
                  subtitle: const Text('MVP에서는 설정만 저장해요'),
                  value: _config.soundEnabled,
                  onChanged: (value) {
                    _update(_config.copyWith(soundEnabled: value));
                  },
                ),
                SwitchListTile(
                  title: const Text('화면 계속 켜두기'),
                  subtitle: const Text('MVP에서는 설정만 저장해요'),
                  value: _config.keepScreenAwake,
                  onChanged: (value) {
                    _update(_config.copyWith(keepScreenAwake: value));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '기본 식사 시간',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 15, label: Text('15분')),
                      ButtonSegment(value: 25, label: Text('25분')),
                      ButtonSegment(value: 35, label: Text('35분')),
                    ],
                    selected: {
                      if ({15, 25, 35}.contains(_config.duration.inMinutes))
                        _config.duration.inMinutes,
                    },
                    emptySelectionAllowed: true,
                    onSelectionChanged: (selected) {
                      if (selected.isEmpty) {
                        return;
                      }
                      _update(
                        _config.copyWith(
                          duration: Duration(minutes: selected.first),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
