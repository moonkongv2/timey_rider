import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jy_yamyam/catalogs/vehicle_catalog.dart';
import 'package:jy_yamyam/models/meal_timer_config.dart';
import 'package:jy_yamyam/models/vehicle_avatar_presentation.dart';
import 'package:jy_yamyam/widgets/avatar/avatar_composite_preview.dart';

void main() {
  testWidgets('Composite preview renders vehicle image in default mode', (
    tester,
  ) async {
    await _pumpCompositePreview(
      tester,
      avatarMode: AvatarImageMode.defaultImage,
      customAvatarImagePath: null,
    );

    expect(_assetImage(VehicleCatalog.motorcycle.assetPath), findsOneWidget);
    expect(
      find.byKey(const ValueKey('avatarCompositeOverlayImage')),
      findsNothing,
    );
  });

  testWidgets(
    'Composite preview ignores missing custom path without crashing',
    (tester) async {
      await _pumpCompositePreview(
        tester,
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: '/missing/avatar.png',
      );

      expect(_assetImage(VehicleCatalog.motorcycle.assetPath), findsOneWidget);
      expect(
        find.byKey(const ValueKey('avatarCompositeOverlayImage')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Composite preview renders custom avatar image when file exists',
    (tester) async {
      await _pumpCompositePreview(
        tester,
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: 'assets/images/jy_the_rider.png',
      );

      expect(_assetImage(VehicleCatalog.motorcycle.assetPath), findsOneWidget);
      expect(
        find.byKey(const ValueKey('avatarCompositeOverlayImage')),
        findsOneWidget,
      );
    },
  );
}

Future<void> _pumpCompositePreview(
  WidgetTester tester, {
  required AvatarImageMode avatarMode,
  required String? customAvatarImagePath,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: AvatarCompositePreview(
            vehicle: VehicleCatalog.motorcycle,
            avatar: VehicleAvatarPresentation(
              mode: avatarMode,
              imagePath: customAvatarImagePath,
            ),
            size: 180,
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
}

Finder _assetImage(String assetName) {
  return find.byWidgetPredicate((widget) {
    return widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == assetName;
  });
}
