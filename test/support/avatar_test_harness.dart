import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/models/purchase_entitlement.dart';
import 'package:timey_rider/screens/avatar_setup_screen.dart';
import 'package:timey_rider/services/avatar_image_picker.dart';
import 'package:timey_rider/services/iap_purchase_client.dart';
import 'package:timey_rider/services/local_avatar_image_service.dart';
import 'package:timey_rider/services/local_purchase_entitlement_store.dart';
import 'package:timey_rider/services/vehicle_pack_purchase_controller.dart';
import 'package:timey_rider/widgets/avatar/rider_guide_bottom_sheet.dart';
import 'package:timey_rider/widgets/purchase/parent_gate_sheet.dart';
import 'package:timey_rider/widgets/purchase/vehicle_pack_info_sheet.dart';
import 'package:timey_rider/widgets/purchase/vehicle_pack_purchase_sheet.dart';

Future<void> pumpAvatarSetupScreen(
  WidgetTester tester,
  ActivityTimerConfig config, {
  Locale locale = const Locale('ko'),
  ValueChanged<ActivityTimerConfig>? onConfigChanged,
  AvatarImagePicker? imagePicker,
  LocalAvatarImageService? avatarImageService,
  VehiclePackPurchaseController? purchaseController,
  VehiclePackPurchaseState purchaseState =
      const VehiclePackPurchaseState.initial(),
  VehiclePackInfoPresenter? vehiclePackInfoPresenter,
  ParentGatePresenter? parentGatePresenter,
  VehiclePackPurchasePresenter? vehiclePackPurchasePresenter,
  bool dismissInitialGuide = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: AvatarSetupScreen(
        config: config,
        onConfigChanged: onConfigChanged ?? (_) {},
        imagePicker: imagePicker,
        avatarImageService: avatarImageService,
        purchaseController: purchaseController,
        purchaseState: purchaseState,
        vehiclePackInfoPresenter: vehiclePackInfoPresenter,
        parentGatePresenter: parentGatePresenter,
        vehiclePackPurchasePresenter: vehiclePackPurchasePresenter,
      ),
    ),
  );
  for (int i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  if (dismissInitialGuide) {
    await dismissAvatarGuideIfVisible(tester);
  }
}

Future<void> scrollAvatarPromptToggleIntoView(WidgetTester tester) async {
  final promptToggle = find.byKey(const ValueKey('avatarPromptToggle'));
  for (var index = 0; index < 4; index += 1) {
    if (promptToggle.evaluate().isNotEmpty) {
      await tester.ensureVisible(promptToggle);
      await tester.pumpAndSettle();
      return;
    }
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
  }
  fail('Avatar prompt toggle was not found.');
}

Future<void> expandAvatarPrompt(WidgetTester tester) async {
  await scrollAvatarPromptToggleIntoView(tester);
  await tester.tap(find.byKey(const ValueKey('avatarPromptToggle')));
  await tester.pumpAndSettle();
}

Future<void> selectCustomAvatarMode(WidgetTester tester) async {
  tester
      .widget<SegmentedButton<AvatarImageMode>>(
        find.byType(SegmentedButton<AvatarImageMode>),
      )
      .onSelectionChanged!({AvatarImageMode.custom});
  await tester.pump();
}

Future<void> dismissAvatarGuideIfVisible(WidgetTester tester) async {
  await tester.pumpAndSettle();
  if (find.byType(RiderGuideBottomSheet).evaluate().isNotEmpty) {
    Navigator.of(tester.element(find.byType(RiderGuideBottomSheet))).pop();
    await tester.pumpAndSettle();
  }
}

Future<void> pumpPurchaseControllerUnlock(
  VehiclePackPurchaseController controller,
) async {
  if (controller.state.vehiclePackUnlocked) {
    return;
  }

  final completer = Completer<void>();
  void listener() {
    if (controller.state.vehiclePackUnlocked && !completer.isCompleted) {
      completer.complete();
    }
  }

  controller.addListener(listener);
  try {
    await completer.future.timeout(const Duration(seconds: 1));
  } finally {
    controller.removeListener(listener);
  }
}

Future<void> scrollAvatarVehicleSelectionIntoView(WidgetTester tester) async {
  try {
    await tester.dragUntilVisible(
      find.text('라이더를 태울 차량'),
      find.byType(Scrollable).first,
      const Offset(0, 100),
      maxIteration: 20,
    );
  } catch (_) {}
}

Future<void> scrollAvatarCompositeIntoView(WidgetTester tester) async {
  for (var index = 0; index < 4; index += 1) {
    if (find.text('합성 미리보기').evaluate().isNotEmpty) {
      return;
    }
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
  }
}

Future<void> scrollAvatarAdjustmentIntoView(WidgetTester tester) async {
  try {
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('avatarScaleSlider')),
      find.byType(Scrollable).first,
      const Offset(0, -100),
      maxIteration: 20,
    );
  } catch (_) {}
}

Future<void> scrollAvatarSetupToBottom(WidgetTester tester) async {
  for (var index = 0; index < 6; index += 1) {
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
  }
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Future<void> pumpHomeAvatarFileCheck(WidgetTester tester) async {
  for (var index = 0; index < 5; index += 1) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
  }
}

Slider avatarSlider(WidgetTester tester, String keyValue) {
  return tester.widget<Slider>(find.byKey(ValueKey(keyValue)));
}

double avatarSliderValue(WidgetTester tester, String keyValue) {
  return avatarSlider(tester, keyValue).value;
}

File createTemporaryAvatarImage() {
  final temporaryDirectory = Directory.systemTemp.createTempSync(
    'road_avatar_test_',
  );
  final avatarFile = File('${temporaryDirectory.path}/avatar.png');
  avatarFile.writeAsBytesSync(_transparentPngBytes);
  addTearDown(() {
    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });
  return avatarFile;
}

final _transparentPngBytes = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

Material vehicleChoiceMaterial(WidgetTester tester, String vehicleId) {
  return tester.widget<Material>(vehicleChoiceFinder(vehicleId));
}

Finder vehicleChoiceFinder(String vehicleId) {
  return find.byKey(ValueKey('vehicleChoice.$vehicleId'));
}

Finder assetImage(String assetName) {
  return find.byWidgetPredicate((widget) {
    return widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == assetName;
  });
}

String avatarPromptText(WidgetTester tester) {
  return tester
      .widget<SelectableText>(find.byKey(const ValueKey('avatarPromptText')))
      .data!;
}

class TestAvatarImagePicker implements AvatarImagePicker {
  const TestAvatarImagePicker([this.pickedFile]);

  final XFile? pickedFile;

  @override
  Future<XFile?> pickAvatarImage() async {
    return pickedFile;
  }
}

class TestLocalAvatarImageService extends LocalAvatarImageService {
  const TestLocalAvatarImageService(this.savedPath);

  final String savedPath;

  @override
  Future<String> savePickedAvatarImage(XFile pickedFile) async {
    return savedPath;
  }
}

class TestPurchaseEntitlementStore implements PurchaseEntitlementStore {
  TestPurchaseEntitlementStore([
    this.entitlement = const PurchaseEntitlement.locked(),
  ]);

  PurchaseEntitlement entitlement;

  @override
  Future<PurchaseEntitlement> load() async {
    return entitlement;
  }

  @override
  Future<void> save(PurchaseEntitlement entitlement) async {
    this.entitlement = entitlement;
  }
}

class TestIapPurchaseClient implements IapPurchaseClient {
  final _purchaseStreamController =
      StreamController<List<IapPurchaseUpdate>>.broadcast();
  var restoreCallCount = 0;

  @override
  Stream<List<IapPurchaseUpdate>> get purchaseStream {
    return _purchaseStreamController.stream;
  }

  @override
  Future<bool> buyNonConsumable(IapProductDetails product) async {
    return true;
  }

  @override
  Future<void> completePurchase(IapPurchaseUpdate purchase) async {}

  @override
  Future<bool> isAvailable() async {
    return true;
  }

  @override
  Future<IapProductQueryResult> queryProducts(Set<String> productIds) async {
    return const IapProductQueryResult(products: []);
  }

  @override
  Future<void> restorePurchases() async {
    restoreCallCount += 1;
  }

  void emitPurchase(IapPurchaseUpdate purchase) {
    _purchaseStreamController.add([purchase]);
  }

  Future<void> close() => _purchaseStreamController.close();
}
