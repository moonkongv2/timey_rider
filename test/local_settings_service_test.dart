import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/services/local_settings_service.dart';

void main() {
  test('Local settings saves and loads onboarding completion', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalSettingsService();
    await service.saveHasSeenOnboarding(true);

    expect(await service.loadHasSeenOnboarding(), isTrue);
  });

  test(
    'Local settings treats existing child name as seen onboarding',
    () async {
      SharedPreferences.setMockInitialValues({});

      final service = LocalSettingsService();

      expect(await service.loadHasSeenOnboarding(childName: '지율'), isTrue);
    },
  );

  test(
    'Local settings treats missing child name as unseen onboarding',
    () async {
      SharedPreferences.setMockInitialValues({});

      final service = LocalSettingsService();

      expect(await service.loadHasSeenOnboarding(), isFalse);
    },
  );

  test('Local settings keeps explicit onboarding preference', () async {
    SharedPreferences.setMockInitialValues({'hasSeenOnboarding': false});

    final service = LocalSettingsService();

    expect(await service.loadHasSeenOnboarding(childName: '지율'), isFalse);
  });
}
