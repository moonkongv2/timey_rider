import 'package:flutter/material.dart';

import 'models/meal_timer_config.dart';
import 'screens/home_screen.dart';
import 'services/local_meal_progress_service.dart';
import 'services/local_settings_service.dart';

class YamyamRiderApp extends StatefulWidget {
  const YamyamRiderApp({
    super.key,
    required this.settingsService,
    required this.mealProgressService,
    required this.initialConfig,
  });

  final LocalSettingsService settingsService;
  final LocalMealProgressService mealProgressService;
  final MealTimerConfig initialConfig;

  @override
  State<YamyamRiderApp> createState() => _YamyamRiderAppState();
}

class _YamyamRiderAppState extends State<YamyamRiderApp> {
  late MealTimerConfig _config = widget.initialConfig;

  Future<void> _saveConfig(MealTimerConfig config) async {
    setState(() => _config = config);
    await widget.settingsService.saveConfig(config);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF9F68),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '냠냠 라이더',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFFFF8EF),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFFFFF8EF),
          foregroundColor: Color(0xFF3D332B),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      home: HomeScreen(
        config: _config,
        mealProgressService: widget.mealProgressService,
        onConfigChanged: _saveConfig,
      ),
    );
  }
}
