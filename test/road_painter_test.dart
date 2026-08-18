import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/models/vehicle.dart';
import 'package:timey_rider/widgets/road_painter.dart';

import 'support/road_test_fixtures.dart';

void main() {
  test('RoadPainter roadStrokeWidthForSize stays within expected clamps', () {
    expect(roadStrokeWidthForSize(const Size(100, 640)), 22);
    expect(roadStrokeWidthForSize(const Size(1000, 1200)), 32);
    expect(roadStrokeWidthForSize(const Size(1200, 100)), 30);
    expect(roadStrokeWidthForSize(const Size(1200, 900)), 44);
    expect(roadStrokeWidthForSize(const Size(420, 640)), closeTo(24.36, 0.01));
  });

  test('RoadCourseVisualStyle maps course kinds to distinct palettes', () {
    final roadStyle = RoadCourseVisualStyle.forCourseKind(
      VehicleCourseKind.road,
    );
    final skyStyle = RoadCourseVisualStyle.forCourseKind(VehicleCourseKind.sky);
    final waterStyle = RoadCourseVisualStyle.forCourseKind(
      VehicleCourseKind.water,
    );
    final railStyle = RoadCourseVisualStyle.forCourseKind(
      VehicleCourseKind.rail,
    );
    final fieldStyle = RoadCourseVisualStyle.forCourseKind(
      VehicleCourseKind.field,
    );

    expect(roadStyle.pathColor, const Color(0xFFBCEFD0));
    expect(roadStyle.backgroundColors, hasLength(4));
    expect(roadStyle.backgroundStops, const [0, 0.5, 0.78, 1]);
    expect(skyStyle.pathColor, isNot(roadStyle.pathColor));
    expect(waterStyle.pathColor, isNot(roadStyle.pathColor));
    expect(railStyle.pathColor, isNot(roadStyle.pathColor));
    expect(fieldStyle.pathColor, isNot(roadStyle.pathColor));
    expect(fieldStyle.backgroundColors, hasLength(4));
    expect(fieldStyle.backgroundStops, const [0, 0.48, 0.80, 1]);
  });

  test('RoadPainter uses course-specific flow patterns', () {
    expect(
      RoadPainter.flowPatternLengthForCourseKind(VehicleCourseKind.road),
      RoadPainter.laneDashPatternLength,
    );
    expect(
      RoadPainter.flowPatternLengthForCourseKind(VehicleCourseKind.sky),
      RoadPainter.skyFlowPatternLength,
    );
    expect(
      RoadPainter.flowPatternLengthForCourseKind(VehicleCourseKind.water),
      RoadPainter.waterWavePatternLength,
    );
    expect(
      RoadPainter.flowPatternLengthForCourseKind(VehicleCourseKind.rail),
      RoadPainter.railSleeperPatternLength,
    );
    expect(
      RoadPainter.flowPatternLengthForCourseKind(VehicleCourseKind.field),
      RoadPainter.fieldFlowPatternLength,
    );
    expect(
      RoadPainter.skyPathCloudAnimationDuration,
      greaterThan(RoadPainter.laneDashAnimationDuration),
    );
    expect(
      RoadPainter.waterWaveAnimationDuration,
      greaterThan(RoadPainter.laneDashAnimationDuration),
    );
    expect(
      RoadPainter.railAnimationDuration,
      greaterThan(RoadPainter.laneDashAnimationDuration),
    );
    expect(
      RoadPainter.fieldAnimationDuration,
      greaterThan(RoadPainter.laneDashAnimationDuration),
    );
  });

  test('RoadPainter rail track scales with road width', () {
    final portraitBaseRoadWidth = roadStrokeWidthForSize(const Size(420, 640));
    final landscapeBaseRoadWidth = roadStrokeWidthForSize(
      const Size(1200, 520),
    );
    final portraitRailWidth = RoadPainter.effectiveRoadStrokeWidthForCourseKind(
      VehicleCourseKind.rail,
      portraitBaseRoadWidth,
    );
    final landscapeRailWidth =
        RoadPainter.effectiveRoadStrokeWidthForCourseKind(
          VehicleCourseKind.rail,
          landscapeBaseRoadWidth,
        );

    expect(portraitRailWidth, lessThan(portraitBaseRoadWidth));
    expect(landscapeRailWidth, lessThan(landscapeBaseRoadWidth));
    expect(portraitRailWidth, 14);
    expect(landscapeRailWidth, closeTo(landscapeBaseRoadWidth * 0.52, 0.01));
    expect(
      RoadPainter.effectiveRoadStrokeWidthForCourseKind(
        VehicleCourseKind.road,
        landscapeBaseRoadWidth,
      ),
      landscapeBaseRoadWidth,
    );
    expect(
      RoadPainter.railSleeperHalfLengthForRoadWidth(landscapeRailWidth) * 2,
      greaterThan(landscapeRailWidth),
    );
  });

  testWidgets('RoadPainter renders the sky course clouds safely', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const CustomPaint(
        size: Size(420, 640),
        painter: RoadPainter(
          progress: 0.5,
          laneDashPhase: 12,
          courseKind: VehicleCourseKind.sky,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('RoadPainter renders the water course waves safely', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const CustomPaint(
        size: Size(420, 640),
        painter: RoadPainter(
          progress: 0.5,
          laneDashPhase: 12,
          courseKind: VehicleCourseKind.water,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('RoadPainter renders the rail course track safely', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const CustomPaint(
        size: Size(420, 640),
        painter: RoadPainter(
          progress: 0.5,
          laneDashPhase: 12,
          courseKind: VehicleCourseKind.rail,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('RoadPainter renders the field course details safely', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final footprintImage = await createTestFootprintImage();
    addTearDown(footprintImage.dispose);

    await tester.pumpWidget(
      CustomPaint(
        size: const Size(420, 640),
        painter: RoadPainter(
          progress: 0.5,
          laneDashPhase: 12,
          courseKind: VehicleCourseKind.field,
          fieldFootprintImage: footprintImage,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
  test('RoadPainter repaints for progress or lane dash phase changes', () {
    const basePainter = RoadPainter(progress: 0.3, laneDashPhase: 0);
    final geometry = createRoadCourseGeometry(
      viewportSize: const Size(420, 640),
      duration: const Duration(minutes: 15),
    );

    expect(
      basePainter.shouldRepaint(
        const RoadPainter(progress: 0.3, laneDashPhase: 10),
      ),
      isTrue,
    );
    expect(
      basePainter.shouldRepaint(
        const RoadPainter(progress: 0.4, laneDashPhase: 0),
      ),
      isTrue,
    );
    expect(
      basePainter.shouldRepaint(
        const RoadPainter(progress: 0.3, laneDashPhase: 0),
      ),
      isFalse,
    );
    expect(
      basePainter.shouldRepaint(
        RoadPainter(progress: 0.3, laneDashPhase: 0, geometry: geometry),
      ),
      isTrue,
    );
    expect(
      basePainter.shouldRepaint(
        const RoadPainter(
          progress: 0.3,
          laneDashPhase: 0,
          courseKind: VehicleCourseKind.sky,
        ),
      ),
      isTrue,
    );
    expect(
      basePainter.shouldRepaint(
        const RoadPainter(
          progress: 0.3,
          laneDashPhase: 0,
          courseKind: VehicleCourseKind.water,
        ),
      ),
      isTrue,
    );
    expect(
      basePainter.shouldRepaint(
        const RoadPainter(
          progress: 0.3,
          laneDashPhase: 0,
          courseKind: VehicleCourseKind.rail,
        ),
      ),
      isTrue,
    );
    expect(
      const RoadPainter(
        progress: 0.3,
        laneDashPhase: 0,
        courseKind: VehicleCourseKind.sky,
      ).shouldRepaint(
        const RoadPainter(
          progress: 0.3,
          laneDashPhase: 0,
          skyPathCloudPhase: 8,
          courseKind: VehicleCourseKind.sky,
        ),
      ),
      isTrue,
    );
  });
}
