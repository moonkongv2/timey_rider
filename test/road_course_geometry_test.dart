import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/widgets/road_painter.dart';

void main() {
  test('RoadCourseGeometry keeps five minutes as the current route', () {
    const viewportSize = Size(420, 640);
    final baselinePathLength = createRoadPath(
      viewportSize,
    ).computeMetrics().first.length;
    final geometry = createRoadCourseGeometry(
      viewportSize: viewportSize,
      duration: const Duration(minutes: 5),
    );
    final shortGeometry = createRoadCourseGeometry(
      viewportSize: viewportSize,
      duration: const Duration(minutes: 1),
    );

    expect(geometry.viewportSize, viewportSize);
    expect(geometry.canvasSize.width, viewportSize.width);
    expect(geometry.canvasSize.height, closeTo(viewportSize.height, 0.01));
    expect(geometry.rowCount, 9);
    expect(geometry.roadBounds, createRoadBounds(viewportSize));
    expect(
      roadMetricForGeometry(geometry).length,
      closeTo(baselinePathLength, 0.01),
    );
    expect(shortGeometry.canvasSize.height, closeTo(viewportSize.height, 0.01));
    expect(shortGeometry.rowCount, geometry.rowCount);
  });

  test('RoadCourseGeometry keeps landscape baseline at five rows', () {
    const viewportSize = Size(1200, 520);
    final geometry = createRoadCourseGeometry(
      viewportSize: viewportSize,
      duration: const Duration(minutes: 5),
    );

    expect(geometry.canvasSize.height, closeTo(viewportSize.height, 0.01));
    expect(geometry.rowCount, 5);
    expect(
      roadMetricForGeometry(geometry).length,
      closeTo(createRoadPath(viewportSize).computeMetrics().first.length, 0.01),
    );
  });

  test('RoadCourseGeometry scales long route path metrics by duration', () {
    const viewportSize = Size(420, 640);
    final baselineGeometry = createRoadCourseGeometry(
      viewportSize: viewportSize,
      duration: const Duration(minutes: 5),
    );
    final baselineLength = roadMetricForGeometry(baselineGeometry).length;
    var previousRowCount = baselineGeometry.rowCount;
    var previousCanvasHeight = baselineGeometry.canvasSize.height;

    for (final expectation in const [
      (minutes: 15, factor: 3.0),
      (minutes: 25, factor: 5.0),
      (minutes: 35, factor: 7.0),
      (minutes: 60, factor: 12.0),
    ]) {
      final geometry = createRoadCourseGeometry(
        viewportSize: viewportSize,
        duration: Duration(minutes: expectation.minutes),
      );
      final lengthRatio =
          roadMetricForGeometry(geometry).length / baselineLength;

      expect(geometry.rowCount, greaterThan(previousRowCount));
      expect(geometry.canvasSize.height, greaterThan(previousCanvasHeight));
      expect(lengthRatio, closeTo(expectation.factor, 0.12));
      expect(
        roadStrokeWidthForSize(geometry.viewportSize),
        closeTo(24.36, 0.01),
      );

      previousRowCount = geometry.rowCount;
      previousCanvasHeight = geometry.canvasSize.height;
    }
  });

  test('RoadCourseGeometry camera follows long courses toward the finish', () {
    final geometry = createRoadCourseGeometry(
      viewportSize: const Size(420, 640),
      duration: const Duration(minutes: 60),
    );
    final startOffset = roadCameraOffsetForGeometryProgress(
      geometry: geometry,
      progress: 0,
    );
    final middleOffset = roadCameraOffsetForGeometryProgress(
      geometry: geometry,
      progress: 0.5,
    );
    final finishOffset = roadCameraOffsetForGeometryProgress(
      geometry: geometry,
      progress: 1,
    );

    expect(startOffset, greaterThan(middleOffset));
    expect(middleOffset, greaterThan(finishOffset));
    expect(finishOffset, closeTo(0, 0.01));
    expect(
      startOffset,
      lessThanOrEqualTo(
        geometry.canvasSize.height - geometry.viewportSize.height,
      ),
    );
  });
}
