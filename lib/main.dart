import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/active_activity_timer_session_store.dart';
import 'services/local_activity_progress_service.dart';
import 'services/local_settings_service.dart';
import 'services/orientation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(const SystemOrientationService().lockPortrait());

  final settingsService = LocalSettingsService();
  final activityProgressService = LocalActivityProgressService();
  const activeSessionStore = ActiveActivityTimerSessionStore();
  final initialConfig = await settingsService.loadConfig();

  runApp(
    TickyRiderApp(
      settingsService: settingsService,
      activityProgressService: activityProgressService,
      activeSessionStore: activeSessionStore,
      initialConfig: initialConfig,
    ),
  );
}
