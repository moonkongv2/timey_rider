import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal_timer_config.dart';

class LocalSettingsService {
  static const _durationMinutesKey = 'durationMinutes';
  static const _showRemainingTimeKey = 'showRemainingTime';
  static const _soundEnabledKey = 'soundEnabled';
  static const _keepScreenAwakeKey = 'keepScreenAwake';

  Future<MealTimerConfig> loadConfig() async {
    final preferences = await SharedPreferences.getInstance();
    final defaults = MealTimerConfig.defaults();

    return defaults.copyWith(
      duration: Duration(
        minutes:
            preferences.getInt(_durationMinutesKey) ??
            defaults.duration.inMinutes,
      ),
      showRemainingTime:
          preferences.getBool(_showRemainingTimeKey) ??
          defaults.showRemainingTime,
      soundEnabled:
          preferences.getBool(_soundEnabledKey) ?? defaults.soundEnabled,
      keepScreenAwake:
          preferences.getBool(_keepScreenAwakeKey) ?? defaults.keepScreenAwake,
    );
  }

  Future<void> saveConfig(MealTimerConfig config) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_durationMinutesKey, config.duration.inMinutes);
    await preferences.setBool(_showRemainingTimeKey, config.showRemainingTime);
    await preferences.setBool(_soundEnabledKey, config.soundEnabled);
    await preferences.setBool(_keepScreenAwakeKey, config.keepScreenAwake);
  }
}
