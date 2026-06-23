import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/screens/avatar_setup_screen.dart';

void main() {
  testWidgets(
    'Custom avatar guide explains phone and AI methods before prompt',
    (tester) async {
      final customConfig = ActivityTimerConfig.defaults().copyWith(
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: 'assets/images/jy_the_rider.png',
        customAvatarVehicleId: 'motorcycle',
      );

      await _pumpAvatarSetup(tester, customConfig);
      _closeGuide(tester);
      await tester.pumpAndSettle();

      await _scrollToText(tester, '라이더 이미지 만들기 가이드');
      expect(find.text('라이더 이미지 만들기 가이드'), findsOneWidget);

      await _scrollToText(tester, '1. 스마트폰 기본 사진 앱 활용하기');

      expect(find.text('1. 스마트폰 기본 사진 앱 활용하기'), findsOneWidget);
      expect(find.textContaining('갤럭시나 아이폰의 기본 사진 앱'), findsOneWidget);
      expect(find.text('2. AI 서비스 활용하기'), findsOneWidget);
      expect(find.textContaining('외부 AI 서비스에서 만든 정사각형'), findsOneWidget);

      await _scrollToPromptCard(tester);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('avatarPromptToggle')),
          matching: find.text(
            'AI 서비스로 만들 때는 선택한 차량에 맞춘 아래 프롬프트를 복사해 붙여넣어 주세요.',
          ),
        ),
        findsOneWidget,
      );
    },
  );

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

Future<void> _scrollToText(WidgetTester tester, String text) async {
  final target = find.text(text);
  for (var index = 0; index < 4; index += 1) {
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      return;
    }
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
  }
}

Future<void> _scrollToPromptCard(WidgetTester tester) async {
  final promptCard = find.byKey(const ValueKey('avatarPromptToggle'));
  for (var index = 0; index < 4; index += 1) {
    if (promptCard.evaluate().isNotEmpty) {
      await tester.ensureVisible(promptCard);
      await tester.pumpAndSettle();
      return;
    }
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
  }
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
