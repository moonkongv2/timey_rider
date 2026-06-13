import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_texts.dart';
import 'models/activity_timer_config.dart';
import 'navigation/app_route_observer.dart';
import 'screens/child_name_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/active_activity_timer_session_store.dart';
import 'services/local_activity_progress_service.dart';
import 'services/local_settings_service.dart';
import 'theme/app_theme.dart';

class TimeyRiderApp extends StatefulWidget {
  const TimeyRiderApp({
    super.key,
    required this.settingsService,
    required this.activityProgressService,
    required this.initialConfig,
    this.activeSessionStore = const ActiveActivityTimerSessionStore(),
  });

  final LocalSettingsService settingsService;
  final LocalActivityProgressService activityProgressService;
  final ActivityTimerConfig initialConfig;
  final ActiveActivityTimerSessionStore activeSessionStore;

  @override
  State<TimeyRiderApp> createState() => _TimeyRiderAppState();
}

class _TimeyRiderAppState extends State<TimeyRiderApp> {
  late ActivityTimerConfig _config = widget.initialConfig;
  bool _showSplash = true;

  Future<void> _saveConfig(ActivityTimerConfig config) async {
    setState(() => _config = config);
    await widget.settingsService.saveConfig(config);
  }

  void _finishSplash() {
    if (!_showSplash) {
      return;
    }
    setState(() => _showSplash = false);
  }

  bool get _hasChildName => _config.childName.trim().isNotEmpty;

  Future<void> _saveChildName(String name) {
    return _saveConfig(_config.copyWith(childName: name.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppTexts.of(context).common.appTitle,
      supportedLocales: AppTexts.supportedLocales,
      navigatorObservers: [appRouteObserver],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      home: _showSplash
          ? SplashScreen(onFinished: _finishSplash)
          : _hasChildName
          ? HomeScreen(
              config: _config,
              activityProgressService: widget.activityProgressService,
              activeSessionStore: widget.activeSessionStore,
              onConfigChanged: _saveConfig,
            )
          : ChildNameSetupScreen(onNameSaved: _saveChildName),
    );
  }
}
