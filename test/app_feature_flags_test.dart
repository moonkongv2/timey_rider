import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/config/app_feature_flags.dart';

void main() {
  test('Motivation media availability defaults to false for launch builds', () {
    expect(AppFeatureFlags.motivationMediaAvailable, isFalse);
  });
}
