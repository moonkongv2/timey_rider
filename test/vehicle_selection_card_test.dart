import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/catalogs/vehicle_catalog.dart';
import 'package:timey_rider/theme/app_spacing.dart';
import 'package:timey_rider/widgets/vehicle_selection_card.dart';

void main() {
  for (final width in [
    200.0,
    240.0,
    280.0,
    295.0,
    296.0,
    320.0,
    375.0,
    430.0,
    480.0,
    768.0,
    812.0,
    1024.0,
  ]) {
    testWidgets('Vehicle choices fill available width at ${width.toInt()}pt', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(_testScreen());
      final rows = _expectRowsFillAndCenter(tester);
      if (width == 240) {
        expect(rows.map((row) => row.length), [2, 2, 2, 2, 2, 2]);
        expect(rows.first.first.width, 84);
      } else if (width == 375) {
        expect(rows.map((row) => row.length), [3, 3, 3, 3]);
        expect(rows.first.first.width, closeTo(98.333, 0.01));
      } else if (width == 768) {
        expect(rows.map((row) => row.length), [5, 5, 2]);
        expect(rows.first.first.width, closeTo(134.4, 0.01));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Vehicle choices adapt when the same screen rotates', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(_testScreen());
    expect(_expectRowsFillAndCenter(tester).first, hasLength(3));
    tester.view.physicalSize = const Size(812, 375);
    await tester.pump();
    expect(_expectRowsFillAndCenter(tester).first, hasLength(5));
    tester.view.physicalSize = const Size(375, 812);
    await tester.pump();
    expect(_expectRowsFillAndCenter(tester).first, hasLength(3));
    expect(tester.takeException(), isNull);
  });
}

Widget _testScreen() => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: VehicleSelectionCard(
          key: const ValueKey('vehicleCardBounds'),
          title: 'Vehicle',
          selectedVehicleId: 'motorcycle',
          lockedVehicleLabel: 'Locked',
          onVehicleSelected: (_) {},
        ),
      ),
    ),
  ),
);

List<List<Rect>> _expectRowsFillAndCenter(WidgetTester tester) {
  final content = tester
      .getRect(find.byKey(const ValueKey('vehicleCardBounds')))
      .deflate(AppSpacing.md);
  final rows = <List<Rect>>[];
  for (final vehicle in VehicleCatalog.all) {
    final rect = tester.getRect(
      find.byKey(ValueKey('vehicleChoice.${vehicle.id}')),
    );
    expect(rect.left, greaterThanOrEqualTo(content.left - 0.5));
    expect(rect.right, lessThanOrEqualTo(content.right + 0.5));
    expect(rect.top, greaterThanOrEqualTo(content.top - 0.5));
    expect(rect.bottom, lessThanOrEqualTo(content.bottom + 0.5));
    if (rows.isEmpty || (rect.top - rows.last.first.top).abs() > 0.5) {
      rows.add([]);
    }
    rows.last.add(rect);
  }
  for (final row in rows) {
    expect(
      (row.first.left + row.last.right) / 2,
      closeTo(content.center.dx, 0.5),
    );
    if (row.length == rows.first.length) {
      expect(row.first.left, closeTo(content.left, 0.5));
      expect(row.last.right, closeTo(content.right, 0.5));
    }
  }
  return rows;
}
