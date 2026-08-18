import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/catalogs/activity_marker_catalog.dart';
import 'package:timey_rider/catalogs/motivation_asset_catalog.dart';
import 'package:timey_rider/catalogs/vehicle_catalog.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/models/vehicle.dart';
import 'package:timey_rider/models/vehicle_avatar_presentation.dart';
import 'package:timey_rider/widgets/goal_star_pulse.dart';
import 'package:timey_rider/widgets/road_painter.dart';
import 'package:timey_rider/widgets/road_view.dart';
import 'package:timey_rider/widgets/vehicle_widget.dart';

import 'support/road_test_fixtures.dart';

void main() {
  testWidgets('Road view shows winding route markers and vehicle', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(progress: 0.5, vehicle: VehicleCatalog.fireTruck),
          ),
        ),
      ),
    );

    expect(find.byType(VehicleWidget), findsOneWidget);
    expect(tester.widget<VehicleWidget>(find.byType(VehicleWidget)).angle, 0);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.byIcon(Icons.restaurant_rounded), findsNothing);
    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
    expect(find.byIcon(Icons.flag_rounded), findsNothing);
    expect(find.byType(GoalStarPulse), findsOneWidget);

    const roadSize = Size(420, 640);
    final roadBounds = createRoadBounds(roadSize);
    final roadSides = [
      for (var index = 0; index <= 20; index += 1)
        roadPointForProgress(roadSize, index / 20).dx < roadBounds.center.dx,
    ];
    var sideChanges = 0;
    for (var index = 1; index < roadSides.length; index += 1) {
      if (roadSides[index] != roadSides[index - 1]) {
        sideChanges += 1;
      }
    }
    expect(sideChanges, greaterThanOrEqualTo(7));
    expect(
      roadPointForProgress(roadSize, 1).dx,
      lessThan(roadBounds.center.dx),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(progress: 0.15, vehicle: VehicleCatalog.fireTruck),
          ),
        ),
      ),
    );
    expect(
      tester.widget<VehicleWidget>(find.byType(VehicleWidget)).isFacingLeft,
      isTrue,
    );
  });

  testWidgets('Road view anchors finish star near the route endpoint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> expectStarNearEndpoint({
      required Size roadSize,
      required Duration courseDuration,
      required double cameraProgress,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: roadSize.width,
              height: roadSize.height,
              child: RoadView(
                cameraProgress: cameraProgress,
                vehicleProgress: 0.35,
                vehicle: VehicleCatalog.fireTruck,
                showVehicle: false,
                courseDuration: courseDuration,
              ),
            ),
          ),
        ),
      );

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      final roadRect = tester.getRect(find.byType(RoadView));
      final geometry = createRoadCourseGeometry(
        viewportSize: roadRect.size,
        duration: courseDuration,
      );
      final cameraOffsetY = roadCameraOffsetForGeometryProgress(
        geometry: geometry,
        progress: cameraProgress,
      );
      final starCenter =
          tester.getCenter(find.byType(GoalStarPulse)) -
          roadRect.topLeft +
          Offset(0, cameraOffsetY);
      final starRect = tester.getRect(find.byType(GoalStarPulse));
      final endpoint = roadPointForGeometryProgress(geometry, 1);
      final endpointInViewport =
          roadRect.topLeft + endpoint - Offset(0, cameraOffsetY);
      final starSize = roadRect.width > roadRect.height ? 68.0 : 56.0;
      final expectedStarCenter = endpoint - Offset(0, starSize * 0.08);

      expect((starCenter - expectedStarCenter).distance, lessThan(1));
      expect(starRect.inflate(2).contains(endpointInViewport), isTrue);
    }

    await expectStarNearEndpoint(
      roadSize: const Size(420, 640),
      courseDuration: const Duration(minutes: 5),
      cameraProgress: 0,
    );
    await expectStarNearEndpoint(
      roadSize: const Size(800, 400),
      courseDuration: const Duration(minutes: 5),
      cameraProgress: 0,
    );
    await expectStarNearEndpoint(
      roadSize: const Size(420, 640),
      courseDuration: const Duration(minutes: 60),
      cameraProgress: 1,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets(
    'GoalStarPulse has a stronger pulse and respects reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      double maxTransformScale() {
        var maxScale = 0.0;
        final transforms = tester.widgetList<Transform>(
          find.descendant(
            of: find.byType(GoalStarPulse),
            matching: find.byType(Transform),
          ),
        );

        for (final transform in transforms) {
          final scale = transform.transform.storage[0];
          if (scale > maxScale) {
            maxScale = scale;
          }
        }

        return maxScale;
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: GoalStarPulse(size: 100))),
        ),
      );

      for (int i = 0; i < 48; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      expect(maxTransformScale(), closeTo(1, 0.001));

      await tester.pump(const Duration(milliseconds: 1200));
      expect(maxTransformScale(), greaterThan(1.55));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: Center(child: GoalStarPulse(size: 100)),
            ),
          ),
        ),
      );

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      await tester.pump(const Duration(milliseconds: 1200));
      expect(maxTransformScale(), closeTo(1, 0.001));
    },
  );

  testWidgets('Road view passes each vehicle course kind to the road painter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<RoadPainter> pumpRoadPainterForVehicle(
      VehicleDefinition vehicle,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 640,
              child: RoadView(progress: 0.5, vehicle: vehicle),
            ),
          ),
        ),
      );

      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((widget) => widget.painter)
          .whereType<RoadPainter>();
      expect(painters, isNotEmpty, reason: vehicle.id);
      return painters.single;
    }

    final roadPainter = await pumpRoadPainterForVehicle(
      VehicleCatalog.fireTruck,
    );
    expect(roadPainter.courseKind, VehicleCourseKind.road);

    final skyPainter = await pumpRoadPainterForVehicle(VehicleCatalog.airplane);
    expect(skyPainter.courseKind, VehicleCourseKind.sky);

    final waterPainter = await pumpRoadPainterForVehicle(VehicleCatalog.shark);
    expect(waterPainter.courseKind, VehicleCourseKind.water);

    final railPainter = await pumpRoadPainterForVehicle(VehicleCatalog.train);
    expect(railPainter.courseKind, VehicleCourseKind.rail);

    final fieldPainter = await pumpRoadPainterForVehicle(VehicleCatalog.tRex);
    expect(fieldPainter.courseKind, VehicleCourseKind.field);
  });

  testWidgets('Road view keeps vehicle inside portrait bounds at route ends', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> pumpRoad(double progress) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 640,
              child: RoadView(
                progress: progress,
                vehicle: VehicleCatalog.fireTruck,
              ),
            ),
          ),
        ),
      );

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    await pumpRoad(0);
    var roadRect = tester.getRect(find.byType(RoadView));
    var vehicleRect = tester.getRect(find.byType(VehicleWidget));
    expect(vehicleRect.left, greaterThanOrEqualTo(roadRect.left));
    expect(vehicleRect.top, greaterThanOrEqualTo(roadRect.top));
    expect(vehicleRect.right, lessThanOrEqualTo(roadRect.right));
    expect(vehicleRect.bottom, lessThanOrEqualTo(roadRect.bottom));

    await pumpRoad(1);
    roadRect = tester.getRect(find.byType(RoadView));
    vehicleRect = tester.getRect(find.byType(VehicleWidget));
    expect(vehicleRect.left, greaterThanOrEqualTo(roadRect.left));
    expect(vehicleRect.top, greaterThanOrEqualTo(roadRect.top));
    expect(vehicleRect.right, lessThanOrEqualTo(roadRect.right));
    expect(vehicleRect.bottom, lessThanOrEqualTo(roadRect.bottom));
  });

  testWidgets(
    'Road view applies portrait road anchor offset for long vehicles',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const progress = 0.5;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 640,
              child: RoadView(progress: progress, vehicle: VehicleCatalog.tRex),
            ),
          ),
        ),
      );

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      final roadSize = tester.getSize(find.byType(RoadView));
      final vehicleSize = tester.getSize(find.byType(VehicleWidget)).height;
      final rawRoadPoint = roadPointForProgress(roadSize, progress);
      final expectedVehicleCenterY =
          rawRoadPoint.dy +
          (vehicleSize * VehicleCatalog.tRex.roadAnchorOffset.portraitDyRatio);

      expect(vehicleSize, closeTo(128, 0.1));
      expect(
        tester.getCenter(find.byType(VehicleWidget)).dy,
        closeTo(expectedVehicleCenterY, 1),
      );
    },
  );

  testWidgets('RoadView with 30 markers renders 30 activity markers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final markers = ActivityMarkerCatalog.courseSlotsFor([
      'top_teeth',
      'bottom_teeth',
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(
              progress: 0,
              vehicle: VehicleCatalog.fireTruck,
              markers: markers,
            ),
          ),
        ),
      ),
    );

    for (var index = 0; index < markers.length; index += 1) {
      expect(find.byKey(ValueKey('roadActivityMarker_$index')), findsOneWidget);
    }
  });

  testWidgets('RoadView marker callback ignores initially cleared markers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final markers = ActivityMarkerCatalog.courseSlotsFor([
      'top_teeth',
      'bottom_teeth',
    ]);
    final passedMarkers = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(
              progress: 1,
              vehicle: VehicleCatalog.fireTruck,
              markers: markers,
              onCourseMarkerPassed: passedMarkers.add,
            ),
          ),
        ),
      ),
    );

    expect(passedMarkers, isEmpty);
  });

  testWidgets('RoadView marker callback emits highest marker on large jump', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final markers = ActivityMarkerCatalog.courseSlotsFor([
      'top_teeth',
      'bottom_teeth',
    ]);
    final passedMarkers = <int>[];

    Widget roadAt(double progress) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(
              progress: progress,
              vehicle: VehicleCatalog.fireTruck,
              markers: markers,
              onCourseMarkerPassed: passedMarkers.add,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(roadAt(0));
    await tester.pumpWidget(roadAt(1));
    await tester.pumpWidget(roadAt(1));

    expect(passedMarkers, [markers.length - 1]);
  });

  testWidgets('RoadView marker callback does not replay after remount', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final markers = ActivityMarkerCatalog.courseSlotsFor([
      'top_teeth',
      'bottom_teeth',
    ]);
    final passedMarkers = <int>[];

    Widget roadAt(double progress, Key key) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(
              key: key,
              progress: progress,
              vehicle: VehicleCatalog.fireTruck,
              markers: markers,
              onCourseMarkerPassed: passedMarkers.add,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(roadAt(0, const ValueKey('first-road')));
    await tester.pumpWidget(roadAt(1, const ValueKey('first-road')));
    await tester.pumpWidget(roadAt(1, const ValueKey('second-road')));

    expect(passedMarkers, [markers.length - 1]);
  });

  testWidgets('RoadView keeps dense activity markers clear of finish star', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final markers = ActivityMarkerCatalog.courseSlotsFor([
      'top_teeth',
      'bottom_teeth',
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(
              progress: 0,
              vehicle: VehicleCatalog.fireTruck,
              showVehicle: false,
              markers: markers,
              markerClearProgress: 0,
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    final starRect = tester.getRect(find.byType(GoalStarPulse));
    for (var index = 0; index < markers.length; index += 1) {
      final markerRect = tester.getRect(
        find.byKey(ValueKey('roadActivityMarker_$index')),
      );
      expect(markerRect.overlaps(starRect), isFalse);
    }
  });

  testWidgets('RoadView at progress 1 hides activity markers', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final markers = ActivityMarkerCatalog.courseSlotsFor([
      'top_teeth',
      'bottom_teeth',
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(
              progress: 0,
              vehicle: VehicleCatalog.fireTruck,
              markers: markers,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('roadActivityMarker_0')), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(
              progress: 1,
              vehicle: VehicleCatalog.fireTruck,
              markers: markers,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < markers.length; index += 1) {
      expect(find.byKey(ValueKey('roadActivityMarker_$index')), findsNothing);
    }
  });

  testWidgets('RoadView keeps long-course vehicle inside viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> pumpLongRoad(double progress) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 640,
              child: RoadView(
                progress: progress,
                vehicle: VehicleCatalog.fireTruck,
                courseDuration: const Duration(minutes: 60),
              ),
            ),
          ),
        ),
      );

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    for (final progress in const [0.0, 0.5, 1.0]) {
      await pumpLongRoad(progress);

      final roadRect = tester.getRect(find.byType(RoadView));
      final vehicleRect = tester.getRect(find.byType(VehicleWidget));
      expect(vehicleRect.left, greaterThanOrEqualTo(roadRect.left));
      expect(vehicleRect.top, greaterThanOrEqualTo(roadRect.top));
      expect(vehicleRect.right, lessThanOrEqualTo(roadRect.right));
      expect(vehicleRect.bottom, lessThanOrEqualTo(roadRect.bottom));
    }

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('RoadView keeps long-course activity markers in the road layer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final markers = ActivityMarkerCatalog.courseSlotsFor([
      'top_teeth',
      'bottom_teeth',
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(
              progress: 0.5,
              vehicle: VehicleCatalog.fireTruck,
              markers: markers,
              markerClearProgress: 0,
              courseDuration: const Duration(minutes: 60),
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    for (var index = 0; index < markers.length; index += 1) {
      expect(find.byKey(ValueKey('roadActivityMarker_$index')), findsOneWidget);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });
  testWidgets('Road view renders custom avatar overlay from local file', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final avatarFile = createTemporaryAvatarImage();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(
              progress: 0.5,
              vehicle: VehicleCatalog.fireTruck,
              avatar: VehicleAvatarPresentation(
                mode: AvatarImageMode.custom,
                imagePath: avatarFile.path,
                scale: 1.2,
                offsetX: 0.05,
                offsetY: -0.04,
                rotationDegrees: 6,
              ),
              avatarImageBuilder: (context, imagePath) {
                return const ColoredBox(
                  key: ValueKey('avatarCompositeOverlayImage'),
                  color: Colors.pink,
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(VehicleWidget), findsOneWidget);
    expect(
      find.byKey(const ValueKey('avatarCompositeOverlayImage')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('Road view ignores missing custom avatar file safely', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(
              progress: 0.5,
              vehicle: VehicleCatalog.fireTruck,
              avatar: const VehicleAvatarPresentation(
                mode: AvatarImageMode.custom,
                imagePath: '/missing/avatar.png',
                scale: 1.2,
                offsetX: 0.05,
                offsetY: -0.04,
                rotationDegrees: 6,
              ),
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.byType(VehicleWidget), findsOneWidget);
    expect(
      find.byKey(const ValueKey('avatarCompositeOverlayImage')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('Road view limits motivation video to 16:9 in landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 520);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 520,
            child: RoadView(
              progress: 0.5,
              vehicle: VehicleCatalog.fireTruck,
              motivationVideoAssetPath:
                  MotivationAssetCatalog.fallbackVideoPath,
              motivationVideoMilestone: 10,
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    final videoSize = tester.getSize(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
    );
    expect(videoSize.width, lessThanOrEqualTo(460));
    expect(videoSize.width / videoSize.height, closeTo(16 / 9, 0.01));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 520,
            child: RoadMotivationVideoLayer(
              assetPath: MotivationAssetCatalog.fallbackVideoPath,
              milestone: 10,
              reservedRightInset: 92,
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    final insetVideoRect = tester.getRect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
    );
    expect(insetVideoRect.right, lessThanOrEqualTo(1200 - 16 - 92));

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('RoadView keeps motivation video fixed while long road scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> pumpLongRoadWithVideo(double progress) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 640,
              child: RoadView(
                progress: progress,
                vehicle: VehicleCatalog.fireTruck,
                motivationVideoAssetPath:
                    MotivationAssetCatalog.fallbackVideoPath,
                motivationVideoMilestone: 10,
                courseDuration: const Duration(minutes: 60),
              ),
            ),
          ),
        ),
      );

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    await pumpLongRoadWithVideo(0);
    final startRect = tester.getRect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
    );

    await pumpLongRoadWithVideo(0.5);
    final middleRect = tester.getRect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
    );

    expect(middleRect.left, closeTo(startRect.left, 0.1));
    expect(middleRect.top, closeTo(startRect.top, 0.1));

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('RoadVehicleLayer keeps long-course vehicle inside viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 520,
            child: RoadVehicleLayer(
              progress: 0.5,
              vehicle: VehicleCatalog.fireTruck,
              courseDuration: const Duration(minutes: 60),
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    final layerRect = tester.getRect(find.byType(RoadVehicleLayer));
    final vehicleRect = tester.getRect(find.byType(VehicleWidget));
    expect(vehicleRect.left, greaterThanOrEqualTo(layerRect.left));
    expect(vehicleRect.top, greaterThanOrEqualTo(layerRect.top));
    expect(vehicleRect.right, lessThanOrEqualTo(layerRect.right));
    expect(vehicleRect.bottom, lessThanOrEqualTo(layerRect.bottom));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('Motivation video can render as a separate road layer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 520);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 520,
            child: RoadView(
              progress: 0.5,
              vehicle: VehicleCatalog.fireTruck,
              motivationVideoAssetPath:
                  MotivationAssetCatalog.fallbackVideoPath,
              motivationVideoMilestone: 10,
              showMotivationVideo: false,
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
      findsNothing,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 520,
            child: RoadMotivationVideoLayer(
              assetPath: MotivationAssetCatalog.fallbackVideoPath,
              milestone: 10,
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    final videoSize = tester.getSize(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
    );
    expect(videoSize.width, lessThanOrEqualTo(460));
    expect(videoSize.width / videoSize.height, closeTo(16 / 9, 0.01));

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });
}
