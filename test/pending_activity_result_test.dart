import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/models/pending_activity_result.dart';
import 'package:timey_rider/screens/home_screen.dart';
import 'package:timey_rider/screens/result_screen.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/widgets/timer_control_bar.dart';
import 'package:timey_rider/services/active_activity_timer_session_store.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';

import 'support/pending_activity_result_test_data.dart';

void main() {
  testWidgets(
    'failed completion persistence keeps active session and can retry',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pending = pendingResult();
      final store = _FailingPendingStore();
      await tester.pumpWidget(
        MaterialApp(
          home: TimerScreen(
            config: pending.session.config,
            activeSessionStore: store,
            activityProgressService: LocalActivityProgressService(),
            onConfigChanged: (_) {},
          ),
        ),
      );
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      tester
          .widget<TimerControlBar>(find.byType(TimerControlBar))
          .onComplete!();
      await tester.pump();
      await tester.tap(find.byType(FilledButton).last);
      await tester.pump();
      expect(await store.load(), isNotNull);
      expect(await store.loadPendingResult(), isNull);
      expect(find.byType(ResultScreen), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Try again'));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(await store.loadPendingResult(), isNotNull);
      expect(await store.load(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'failed pending cleanup retries without awarding another record',
    (tester) async {
      final pending = pendingResult(receiveSticker: false);
      final store = _FailingClearStore();
      await store.savePendingResult(pending);
      final progress = LocalActivityProgressService();
      await tester.pumpWidget(
        MaterialApp(
          home: ResultScreen(
            result: pending.result,
            config: pending.session.config,
            activeSessionStore: store,
            activityProgressService: progress,
            onConfigChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect((await progress.loadSnapshot()).history, hasLength(1));
      expect(await store.loadPendingResult(), isNotNull);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect((await progress.loadSnapshot()).history, hasLength(1));
      expect(await store.loadPendingResult(), isNull);
    },
  );

  testWidgets(
    'home restores unresolved sticker choice and clears only after recording',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pending = pendingResult();
      const store = ActiveActivityTimerSessionStore();
      await store.savePendingResult(pending);
      final progress = LocalActivityProgressService();
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            config: pending.session.config,
            activeSessionStore: store,
            activityProgressService: progress,
            onConfigChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsOneWidget);
      expect((await progress.loadSnapshot()).history, isEmpty);
      // Backing out keeps the result recoverable when the next timer is requested.
      final resultScreen = tester.widget<ResultScreen>(
        find.byType(ResultScreen),
      );
      expect(resultScreen.result.sessionId, 'finished-session');
      expect(await store.loadPendingResult(), isNotNull);
      await tester.tap(find.text('No Sticker This Time'));
      await tester.pumpAndSettle();
      expect((await progress.loadSnapshot()).history, hasLength(1));
      expect((await progress.loadSnapshot()).inventory, isEmpty);
      expect(await store.loadPendingResult(), isNull);
    },
  );
}

class _FailingPendingStore extends ActiveActivityTimerSessionStore {
  bool failNextSave = true;
  @override
  Future<void> savePendingResult(PendingActivityResult result) async {
    if (failNextSave) {
      failNextSave = false;
      throw StateError('storage unavailable');
    }
    await super.savePendingResult(result);
  }
}

class _FailingClearStore extends ActiveActivityTimerSessionStore {
  bool failNextClear = true;

  @override
  Future<void> clearPendingResult(String sessionId) async {
    if (failNextClear) {
      failNextClear = false;
      throw StateError('storage unavailable');
    }
    await super.clearPendingResult(sessionId);
  }
}
