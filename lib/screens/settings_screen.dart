import 'package:flutter/material.dart';

import '../l10n/app_texts.dart';
import '../models/meal_timer_config.dart';
import '../widgets/vehicle_selection_card.dart';

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
    final texts = AppTexts.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(texts.settings.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(texts.settings.showRemainingTime),
                  value: _config.showRemainingTime,
                  onChanged: (value) {
                    _update(_config.copyWith(showRemainingTime: value));
                  },
                ),
                SwitchListTile(
                  title: Text(texts.settings.soundEnabled),
                  subtitle: Text(texts.settings.savedOnlySubtitle),
                  value: _config.soundEnabled,
                  onChanged: (value) {
                    _update(_config.copyWith(soundEnabled: value));
                  },
                ),
                SwitchListTile(
                  title: Text(texts.settings.keepScreenAwake),
                  subtitle: Text(texts.settings.savedOnlySubtitle),
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
                    texts.settings.defaultMealDuration,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment(
                        value: 15,
                        label: Text(texts.settings.durationSegmentLabel(15)),
                      ),
                      ButtonSegment(
                        value: 25,
                        label: Text(texts.settings.durationSegmentLabel(25)),
                      ),
                      ButtonSegment(
                        value: 35,
                        label: Text(texts.settings.durationSegmentLabel(35)),
                      ),
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
          const SizedBox(height: 20),
          VehicleSelectionCard(
            title: texts.settings.vehicleSelection,
            selectedVehicleId: _config.motorcycleId,
            onVehicleSelected: (vehicleId) {
              _update(_config.copyWith(motorcycleId: vehicleId));
            },
          ),
        ],
      ),
    );
  }
}
