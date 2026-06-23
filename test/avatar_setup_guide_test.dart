import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/screens/avatar_setup_screen.dart';

void main() {
  testWidgets('Avatar setup guide can be reopened from visible help actions', (
    tester,
  ) async {
    await _pumpAvatarSetup(tester, ActivityTimerConfig.defaults());

    expect(find.text('우리 아이 라이더 만들기 안내'), findsOneWidget);

    _closeGuide(tester);
    await tester.pumpAndSettle();

    expect(find.byTooltip('안내 다시 보기'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('avatarGuideReplayButton')));
    await tester.pumpAndSettle();

    expect(find.text('우리 아이 라이더 만들기 안내'), findsOneWidget);

    final customConfig = ActivityTimerConfig.defaults().copyWith(
      avatarMode: AvatarImageMode.custom,
      customAvatarImagePath: 'assets/images/jy_the_rider.png',
      customAvatarVehicleId: 'motorcycle',
    );
    await _pumpAvatarSetup(tester, customConfig);
    _closeGuide(tester);
    await tester.pumpAndSettle();

    await _scrollUploadGuideButtonIntoView(tester);
    expect(
      find.byKey(const ValueKey('avatarUploadGuideButton')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('avatarUploadGuideButton')));
    await tester.pumpAndSettle();

    expect(find.text('우리 아이 라이더 만들기 안내'), findsOneWidget);
  });
}

Future<void> _pumpAvatarSetup(
  WidgetTester tester,
  ActivityTimerConfig config,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: AvatarSetupScreen(config: config, onConfigChanged: (_) {}),
    ),
  );
  await tester.pumpAndSettle();
}

void _closeGuide(WidgetTester tester) {
  Navigator.of(tester.element(find.text('우리 아이 라이더 만들기 안내'))).pop();
}

Future<void> _scrollUploadGuideButtonIntoView(WidgetTester tester) async {
  final uploadGuideButton = find.byKey(
    const ValueKey('avatarUploadGuideButton'),
  );
  for (var index = 0; index < 4; index += 1) {
    if (uploadGuideButton.evaluate().isNotEmpty) {
      await tester.ensureVisible(uploadGuideButton);
      await tester.pumpAndSettle();
      return;
    }
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
  }
}
