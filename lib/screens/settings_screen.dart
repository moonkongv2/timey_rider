import 'package:flutter/material.dart';

import '../catalogs/meal_course_catalog.dart';
import '../l10n/app_texts.dart';
import '../l10n/text_sets.dart';
import '../models/meal_timer_config.dart';
import '../theme/app_colors.dart';
import 'user_guide_screen.dart';

const _motivationVideoIntervalOptions = [
  Duration(minutes: 3),
  Duration(minutes: 5),
  Duration(minutes: 10),
];

int _normalizedMotivationVideoIntervalMinutes(Duration interval) {
  if (_motivationVideoIntervalOptions.contains(interval)) {
    return interval.inMinutes;
  }

  return _motivationVideoIntervalOptions.first.inMinutes;
}

String _courseIngredientModeLabel(
  SettingsTextSet texts,
  CourseIngredientMode mode,
) {
  return switch (mode) {
    CourseIngredientMode.off => texts.courseIngredientModeOff,
    CourseIngredientMode.manual => texts.courseIngredientModeManual,
    CourseIngredientMode.random => texts.courseIngredientModeRandom,
  };
}

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

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final motivationVideoIntervalMinutes =
        _normalizedMotivationVideoIntervalMinutes(
          _config.motivationVideoInterval,
        );
    final sectionTitleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      appBar: AppBar(title: Text(texts.settings.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              key: const ValueKey('userGuideSettingsTile'),
              leading: const Icon(Icons.menu_book_rounded),
              title: Text(
                texts.userGuide.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(texts.userGuide.subtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UserGuideScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(texts.settings.childNameTitle, style: sectionTitleStyle),
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texts.settings.defaultMealDuration,
                    style: sectionTitleStyle,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texts.settings.courseIngredientModeTitle,
                    style: sectionTitleStyle,
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        width: constraints.maxWidth,
                        child: SegmentedButton<CourseIngredientMode>(
                          key: const ValueKey(
                            'courseIngredientModeSegmentedButton',
                          ),
                          showSelectedIcon: false,
                          style: const ButtonStyle(
                            padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 2),
                            ),
                            textStyle: WidgetStatePropertyAll(
                              TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          segments: [
                            for (final mode in CourseIngredientMode.values)
                              ButtonSegment(
                                value: mode,
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _courseIngredientModeLabel(
                                      texts.settings,
                                      mode,
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                              ),
                          ],
                          selected: {_config.courseIngredientMode},
                          onSelectionChanged: (selected) {
                            if (selected.isEmpty) {
                              return;
                            }
                            _update(
                              _config.copyWith(
                                courseIngredientMode: selected.first,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    texts.settings.courseIngredientModeDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
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
            child: Column(
              children: [
                SwitchListTile(
                  key: const ValueKey('motivationVideoEnabledSwitch'),
                  title: Text(texts.settings.motivationVideoEnabled),
                  value: _config.motivationVideoEnabled,
                  onChanged: (value) {
                    _update(_config.copyWith(motivationVideoEnabled: value));
                  },
                ),
                SwitchListTile(
                  key: const ValueKey('motivationVideoCustomIntervalSwitch'),
                  title: Text(texts.settings.motivationVideoCustomInterval),
                  value: _config.motivationVideoUseCustomInterval,
                  onChanged: _config.motivationVideoEnabled
                      ? (value) {
                          _update(
                            _config.copyWith(
                              motivationVideoUseCustomInterval: value,
                            ),
                          );
                        }
                      : null,
                ),
                if (_config.motivationVideoEnabled &&
                    _config.motivationVideoUseCustomInterval)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          texts.settings.motivationVideoInterval,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<int>(
                            key: const ValueKey(
                              'motivationVideoIntervalSegmentedButton',
                            ),
                            segments: [
                              for (final interval
                                  in _motivationVideoIntervalOptions)
                                ButtonSegment(
                                  value: interval.inMinutes,
                                  label: Text(
                                    texts.settings
                                        .motivationVideoIntervalSegmentLabel(
                                          interval.inMinutes,
                                        ),
                                  ),
                                ),
                            ],
                            selected: {motivationVideoIntervalMinutes},
                            onSelectionChanged: (selected) {
                              if (selected.isEmpty) {
                                return;
                              }
                              _update(
                                _config.copyWith(
                                  motivationVideoInterval: Duration(
                                    minutes: selected.first,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
