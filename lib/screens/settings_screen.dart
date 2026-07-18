import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_texts.dart';
import '../l10n/text_sets.dart';
import '../models/activity_timer_config.dart';
import '../services/vehicle_pack_purchase_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/app/app_help_sheet.dart';
import '../widgets/purchase/parent_gate_sheet.dart';
import '../widgets/purchase/vehicle_pack_purchase_sheet.dart';
import 'user_guide_screen.dart';

typedef SettingsUrlLauncher = Future<bool> Function(Uri uri);
typedef SettingsAppVersionLoader = Future<String> Function();

const _courseMarkerGuideImageAssetPath =
    'assets/images/onboarding/onboarding_04_course_markers.png';
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

String _markerModeLabel(SettingsTextSet texts, ActivityMarkerMode mode) {
  return switch (mode) {
    ActivityMarkerMode.off => texts.markerModeOff,
    ActivityMarkerMode.manual => texts.markerModeManual,
    ActivityMarkerMode.activityDefault => texts.markerModeActivityDefault,
  };
}

const _markerModes = [
  ActivityMarkerMode.off,
  ActivityMarkerMode.manual,
  ActivityMarkerMode.activityDefault,
];

Future<bool> _launchSettingsExternalUri(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<String> _loadSettingsAppVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  if (packageInfo.buildNumber.isEmpty) {
    return packageInfo.version;
  }

  return '${packageInfo.version} (${packageInfo.buildNumber})';
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.config,
    required this.onConfigChanged,
    this.purchaseController,
    this.purchaseState = const VehiclePackPurchaseState.initial(),
    this.parentGatePresenter,
    this.vehiclePackPurchasePresenter,
    this.urlLauncher = _launchSettingsExternalUri,
    this.appVersionLoader = _loadSettingsAppVersion,
  });

  static final Uri privacyPolicyUri = Uri.parse(
    'https://florencejyrider.github.io/app-legal-pages/privacy/timey-rider/',
  );
  static final Uri supportUri = Uri.parse(
    'https://florencejyrider.github.io/app-legal-pages/support/timey-rider/',
  );

  final ActivityTimerConfig config;
  final ValueChanged<ActivityTimerConfig> onConfigChanged;
  final VehiclePackPurchaseController? purchaseController;
  final VehiclePackPurchaseState purchaseState;
  final ParentGatePresenter? parentGatePresenter;
  final VehiclePackPurchasePresenter? vehiclePackPurchasePresenter;
  final SettingsUrlLauncher urlLauncher;
  final SettingsAppVersionLoader appVersionLoader;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ActivityTimerConfig _config = widget.config;
  late final TextEditingController _childNameController = TextEditingController(
    text: widget.config.childName,
  );

  @override
  void initState() {
    super.initState();
    widget.purchaseController?.addListener(_handlePurchaseStateChanged);
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.purchaseController != widget.purchaseController) {
      oldWidget.purchaseController?.removeListener(_handlePurchaseStateChanged);
      widget.purchaseController?.addListener(_handlePurchaseStateChanged);
    }
    if (oldWidget.config.childName != widget.config.childName &&
        _childNameController.text != widget.config.childName) {
      _childNameController.text = widget.config.childName;
    }
  }

  @override
  void dispose() {
    widget.purchaseController?.removeListener(_handlePurchaseStateChanged);
    _childNameController.dispose();
    super.dispose();
  }

  void _handlePurchaseStateChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _update(ActivityTimerConfig config) {
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

  void _showMarkerHelp() {
    final texts = AppTexts.of(context).activityMarker;
    showAppHelpSheet(
      context: context,
      title: texts.helpTitle,
      imageAssetPath: _courseMarkerGuideImageAssetPath,
      bodyParagraphs: texts.helpBodyParagraphs,
      bulletItems: texts.helpBulletItems,
    );
  }

  void _showMotivationVideoHelp() {
    final texts = AppTexts.of(context).settings;
    showAppHelpSheet(
      context: context,
      title: texts.motivationVideoHelpTitle,
      bodyParagraphs: texts.motivationVideoHelpBodyParagraphs,
      bulletItems: texts.motivationVideoHelpBulletItems,
    );
  }

  Future<void> _openVehiclePackPurchase() async {
    final purchaseController = widget.purchaseController;
    if (purchaseController == null) {
      return;
    }

    final parentGatePresenter =
        widget.parentGatePresenter ?? showParentGateSheet;
    final didPassGate = await parentGatePresenter(context);
    if (!mounted || !didPassGate) {
      return;
    }

    final vehiclePackPurchasePresenter =
        widget.vehiclePackPurchasePresenter ?? showVehiclePackPurchaseSheet;
    await vehiclePackPurchasePresenter(
      context,
      controller: purchaseController,
      vehicleId: _config.vehicleId,
    );
  }

  Future<void> _restoreVehiclePackPurchase() async {
    final purchaseController = widget.purchaseController;
    if (purchaseController == null) {
      return;
    }

    final parentGatePresenter =
        widget.parentGatePresenter ?? showParentGateSheet;
    final didPassGate = await parentGatePresenter(context);
    if (!mounted || !didPassGate) {
      return;
    }

    await purchaseController.restoreVehiclePack();
    if (!mounted) {
      return;
    }

    final message = _vehiclePackRestoreMessage(
      AppTexts.of(context).purchase,
      purchaseController.state,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _vehiclePackRestoreMessage(
    PurchaseTextSet texts,
    VehiclePackPurchaseState state,
  ) {
    if (state.vehiclePackUnlocked) {
      return state.status == VehiclePackPurchaseStatus.restored
          ? texts.vehiclePackRestoredMessage
          : texts.vehiclePackPurchasedMessage;
    }

    return switch (state.status) {
      VehiclePackPurchaseStatus.restoreNotFound =>
        texts.vehiclePackRestoreNotFoundMessage,
      VehiclePackPurchaseStatus.productUnavailable =>
        texts.vehiclePackPurchaseUnavailableMessage,
      VehiclePackPurchaseStatus.error => texts.vehiclePackErrorMessage,
      _ => texts.vehiclePackRestoringMessage,
    };
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
    final purchaseState =
        widget.purchaseController?.state ?? widget.purchaseState;

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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          texts.settings.markerModeTitle,
                          style: sectionTitleStyle,
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('markerModeHelpButton'),
                        tooltip: texts.activityMarker.helpLinkLabel,
                        onPressed: _showMarkerHelp,
                        icon: const Icon(Icons.help_outline_rounded),
                        color: AppColors.brown700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        width: constraints.maxWidth,
                        child: SegmentedButton<ActivityMarkerMode>(
                          key: const ValueKey('markerModeSegmentedButton'),
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
                            for (final mode in _markerModes)
                              ButtonSegment(
                                value: mode,
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _markerModeLabel(texts.settings, mode),
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                              ),
                          ],
                          selected: {_config.markerMode},
                          onSelectionChanged: (selected) {
                            if (selected.isEmpty) {
                              return;
                            }
                            _update(
                              _config.copyWith(markerMode: selected.first),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    texts.settings.markerModeDescription,
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
          if (widget.purchaseController != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_taxi_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            texts.settings.vehiclePackSettingsTitle,
                            style: sectionTitleStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      purchaseState.vehiclePackUnlocked
                          ? texts.settings.vehiclePackUnlockedState
                          : texts.settings.vehiclePackLockedState,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      texts.settings.vehiclePackSettingsDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    if (!purchaseState.vehiclePackUnlocked) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const ValueKey('vehiclePackSettingsManageButton'),
                        onPressed: _openVehiclePackPurchase,
                        icon: const Icon(Icons.lock_open_rounded),
                        label: Text(texts.settings.vehiclePackManageButton),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        key: const ValueKey('vehiclePackSettingsRestoreButton'),
                        onPressed: _restoreVehiclePackPurchase,
                        icon: const Icon(Icons.restore_rounded),
                        label: Text(texts.settings.vehiclePackRestoreButton),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          texts.settings.motivationVideoHelpTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('motivationVideoHelpButton'),
                        tooltip: texts.settings.motivationVideoHelpTitle,
                        onPressed: _showMotivationVideoHelp,
                        icon: const Icon(Icons.help_outline_rounded),
                        color: AppColors.brown700,
                      ),
                    ],
                  ),
                ),
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
