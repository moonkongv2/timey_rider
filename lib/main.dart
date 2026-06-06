import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/local_meal_progress_service.dart';
import 'services/local_settings_service.dart';
import 'services/orientation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(const SystemOrientationService().lockPortrait());

  final settingsService = LocalSettingsService();
  final mealProgressService = LocalMealProgressService();
  final initialConfig = await settingsService.loadConfig();

  runApp(
    YamyamRiderApp(
      settingsService: settingsService,
      mealProgressService: mealProgressService,
      initialConfig: initialConfig,
    ),
  );
}
