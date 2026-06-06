import 'dart:io';

import 'package:flutter/material.dart';

import '../catalogs/meal_course_catalog.dart';
import '../l10n/app_texts.dart';
import '../models/meal_timer_config.dart';
import '../models/vehicle_avatar_presentation.dart';
import 'avatar_setup_screen.dart';

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
  late final TextEditingController _childNameController = TextEditingController(
    text: widget.config.childName,
  );

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.childName != widget.config.childName &&
        _childNameController.text != widget.config.childName) {
      _childNameController.text = widget.config.childName;
    }
  }

  @override
  void dispose() {
    _childNameController.dispose();
    super.dispose();
  }

  void _update(MealTimerConfig config) {
    setState(() => _config = config);
    widget.onConfigChanged(config);
  }

  void _saveChildName() {
    final texts = AppTexts.of(context);
    final childName = _childNameController.text.trim();
    if (childName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texts.settings.childNameRequiredMessage)),
      );
      return;
    }
    _update(_config.copyWith(childName: childName));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texts.settings.childNameSavedMessage)),
    );
  }

  Future<void> _openAvatarSetup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AvatarSetupScreen(config: _config, onConfigChanged: _update),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final vehicleAvatar = _config.avatarPresentationForVehicle(
      _config.vehicleId,
    );
    final isUsingCustomAvatar =
        vehicleAvatar.isCustom &&
        vehicleAvatar.imagePath != null &&
        File(vehicleAvatar.imagePath!).existsSync();
    final avatarStateText = isUsingCustomAvatar
        ? texts.settings.avatarCustomState
        : texts.settings.avatarDefaultState;

    return Scaffold(
      appBar: AppBar(title: Text(texts.settings.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    texts.settings.childNameTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _childNameController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: texts.settings.childNameFieldLabel,
                      hintText: texts.common.defaultChildName,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _saveChildName(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saveChildName,
                    child: Text(texts.settings.saveChildName),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                  subtitle: Text(texts.settings.keepScreenAwakeSubtitle),
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
                      for (final minutes in MealCourseCatalog.presetMinutes)
                        ButtonSegment(
                          value: minutes,
                          label: Text(
                            texts.settings.durationSegmentLabel(minutes),
                          ),
                        ),
                    ],
                    selected: {
                      if (MealCourseCatalog.isPresetMinutes(
                        _config.duration.inMinutes,
                      ))
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    texts.settings.avatarSettingsTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(avatarStateText),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _openAvatarSetup,
                    child: Text(texts.settings.avatarSettingsButton),
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
