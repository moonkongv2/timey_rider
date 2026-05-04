import 'package:flutter/material.dart';

import 'app.dart';
import 'services/local_settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = LocalSettingsService();
  final initialConfig = await settingsService.loadConfig();

  runApp(
    YamyamRiderApp(
      settingsService: settingsService,
      initialConfig: initialConfig,
    ),
  );
}
