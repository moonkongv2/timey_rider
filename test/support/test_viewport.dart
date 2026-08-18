import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const testPortraitSize = Size(390, 844);
const testCompactLandscapeSize = Size(852, 393);
const testWideLandscapeSize = Size(1200, 600);

void setTestViewport(
  WidgetTester tester, {
  Size size = testPortraitSize,
  double devicePixelRatio = 1,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
