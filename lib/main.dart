import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/active_meal_timer_session_store.dart';
import 'services/local_meal_progress_service.dart';
import 'services/local_settings_service.dart';
import 'services/orientation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(const SystemOrientationService().lockPortrait());

  final settingsService = LocalSettingsService();
  final mealProgressService = LocalMealProgressService();
  const activeSessionStore = ActiveMealTimerSessionStore();
  final initialConfig = await settingsService.loadConfig();

  runApp(
    TickyRiderApp(
      settingsService: settingsService,
      mealProgressService: mealProgressService,
      activeSessionStore: activeSessionStore,
      initialConfig: initialConfig,
    ),
  );
}
