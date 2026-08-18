import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

void setTestPreferences([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
}

void setInitializedTimerPresetPreferences([
  Map<String, Object> values = const {},
]) {
  setTestPreferences({'savedActivityTimerPresetsInitialized': true, ...values});
}

void setInitializedEmptySavedTimerPresets() {
  setTestPreferences({
    'savedActivityTimerPresets': jsonEncode([]),
    'savedActivityTimerPresetsInitialized': true,
  });
}
