import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/services/local_settings_service.dart';

void main() {
  test('no onboarding pref and empty childName returns false', () async {
    SharedPreferences.setMockInitialValues({});

    final hasSeenOnboarding = await LocalSettingsService()
        .loadHasSeenOnboarding(childName: '');

    expect(hasSeenOnboarding, isFalse);
  });

  test('no onboarding pref and non-empty childName returns true', () async {
    SharedPreferences.setMockInitialValues({});

    final hasSeenOnboarding = await LocalSettingsService()
        .loadHasSeenOnboarding(childName: '하루');

    expect(hasSeenOnboarding, isTrue);
  });

  test('explicit false pref and non-empty childName returns false', () async {
    SharedPreferences.setMockInitialValues({'hasSeenOnboarding': false});

    final hasSeenOnboarding = await LocalSettingsService()
        .loadHasSeenOnboarding(childName: '하루');

    expect(hasSeenOnboarding, isFalse);
  });

  test('saveHasSeenOnboarding true persists true', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalSettingsService();
    await service.saveHasSeenOnboarding(true);

    expect(await service.loadHasSeenOnboarding(childName: ''), isTrue);
  });
}
