import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/l10n/app_texts.dart';
import 'package:timey_rider/models/activity_progress_snapshot.dart';
import 'package:timey_rider/models/activity_session_result.dart';
import 'package:timey_rider/screens/activity_history_screen.dart';
import 'package:timey_rider/screens/result_screen.dart';
import 'package:timey_rider/screens/home_screen.dart';
import 'package:timey_rider/navigation/app_route_observer.dart';
import 'package:timey_rider/screens/reward_goal_screen.dart';
import 'package:timey_rider/screens/sticker_collection_screen.dart';
import 'package:timey_rider/services/active_activity_timer_session_store.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';

import 'support/pending_activity_result_test_data.dart';
import 'support/result_test_fakes.dart';

Widget app(
  Widget home, {
  Locale locale = const Locale('en'),
  double scale = 1,
}) => MaterialApp(
  locale: locale,
  supportedLocales: const [
    Locale('ko'),
    Locale('en'),
    Locale('ja'),
    Locale('es'),
    Locale('pt', 'BR'),
  ],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home,
);

class CleanupFailingStore extends ActiveActivityTimerSessionStore {
  int clears = 0;
  @override
  Future<void> clearPendingResult(String sessionId) async {
    clears++;
    if (clears == 1) throw StateError('Disk unavailable');
    await super.clearPendingResult(sessionId);
  }
}

class PausedProgressService extends LocalActivityProgressService {
  final entered = Completer<void>();
  final release = Completer<void>();
  int records = 0;
  @override
  Future<RecordedActivitySession> recordActivityResult(
    ActivitySessionResult result, {
    required String vehicleId,
  }) async {
    records++;
    if (records == 1) {
      entered.complete();
      await release.future;
    }
    return super.recordActivityResult(result, vehicleId: vehicleId);
  }
}

class CountingProgressService extends LocalActivityProgressService {
  int records = 0;
  @override
  Future<RecordedActivitySession> recordActivityResult(
    ActivitySessionResult result, {
    required String vehicleId,
  }) {
    records++;
    return super.recordActivityResult(result, vehicleId: vehicleId);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final choice in [null, false, true]) {
    testWidgets(
      'deleted pending choice=$choice has no selection or media and clears matching residual timer',
      (tester) async {
        final pending = pendingResult(receiveSticker: choice);
        final service = LocalActivityProgressService();
        await service.recordActivityResult(
          pending.result,
          vehicleId: 'motorcycle',
        );
        await service.deleteActivityHistoryEntry(
          pending.session.sessionId,
          deleteLinkedRewards: true,
        );
        const store = ActiveActivityTimerSessionStore();
        await store.savePendingResult(pending);
        // Simulate a crash after pending persisted, before active cleanup.
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(
          'activeActivityTimerSession',
          jsonEncode(pending.session.toJson()),
        );
        final audio = TestResultAudioService();
        var videoCount = 0;
        await tester.pumpWidget(
          app(
            ResultScreen(
              result: pending.result,
              config: pending.session.config,
              activityProgressService: service,
              activeSessionStore: store,
              resultAudioService: audio,
              orientationService: TestOrientationService(),
              introControllerFactory: (_) {
                videoCount++;
                throw StateError('Must not create media');
              },
              onConfigChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final texts = AppTexts.of(tester.element(find.byType(ResultScreen)));
        expect(
          find.text(texts.activityHistory.deletedActivityMessage),
          findsOneWidget,
        );
        expect(find.text(texts.result.getStickerButton), findsNothing);
        expect(videoCount, 0);
        expect(audio.calls.where((call) => call.startsWith('play')), isEmpty);
        expect(await store.loadPendingResult(), isNull);
        expect(await store.load(), isNull);
        expect((await service.loadSnapshot()).inventory, isEmpty);
      },
    );
  }

  testWidgets(
    'deletion after preflight wins at final record and suppresses media',
    (tester) async {
      final pending = pendingResult();
      const store = ActiveActivityTimerSessionStore();
      await store.savePendingResult(pending);
      final service = PausedProgressService();
      final realService = LocalActivityProgressService();
      var media = 0;
      await tester.pumpWidget(
        app(
          ResultScreen(
            result: pending.result,
            config: pending.session.config,
            activityProgressService: service,
            activeSessionStore: store,
            orientationService: TestOrientationService(),
            resultAudioService: TestResultAudioService(),
            introControllerFactory: (_) {
              media++;
              throw StateError('Must not create media');
            },
            onConfigChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final texts = AppTexts.of(tester.element(find.byType(ResultScreen)));
      await tester.tap(find.text(texts.result.getStickerButton));
      await tester.pump();
      await service.entered.future;
      await realService.recordActivityResult(
        pending.result.copyWith(receiveSticker: true),
        vehicleId: 'motorcycle',
      );
      await realService.deleteActivityHistoryEntry(
        pending.session.sessionId,
        deleteLinkedRewards: true,
      );
      service.release.complete();
      await tester.pumpAndSettle();
      expect(
        find.text(texts.activityHistory.deletedActivityMessage),
        findsOneWidget,
      );
      expect(media, 0);
      expect((await service.loadSnapshot()).inventory, isEmpty);
    },
  );

  for (final deleteBetween in [false, true]) {
    testWidgets(
      'cleanup retry deleteBetween=$deleteBetween never records progress twice',
      (tester) async {
        final pending = pendingResult(receiveSticker: false);
        final store = CleanupFailingStore();
        await store.savePendingResult(pending);
        final service = CountingProgressService();
        await tester.pumpWidget(
          app(
            ResultScreen(
              result: pending.result,
              config: pending.session.config,
              activityProgressService: service,
              activeSessionStore: store,
              orientationService: TestOrientationService(),
              resultAudioService: TestResultAudioService(),
              onConfigChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final texts = AppTexts.of(tester.element(find.byType(ResultScreen)));
        expect(find.text(texts.common.retry), findsOneWidget);
        expect(service.records, 1);
        if (deleteBetween) {
          await LocalActivityProgressService().deleteActivityHistoryEntry(
            pending.session.sessionId,
          );
        }
        await tester.tap(find.text(texts.common.retry));
        await tester.pumpAndSettle();
        expect(service.records, 1);
        expect(await store.loadPendingResult(), isNull);
        if (deleteBetween) {
          expect(
            find.text(texts.activityHistory.deletedActivityMessage),
            findsOneWidget,
          );
        } else {
          expect(find.text(texts.common.retry), findsNothing);
        }
      },
    );
  }

  for (final locale in [
    const Locale('ko'),
    const Locale('en'),
    const Locale('ja'),
    const Locale('es'),
    const Locale('pt', 'BR'),
  ]) {
    for (final size in [const Size(320, 568), const Size(568, 320)]) {
      testWidgets(
        'dialog linked policy fits ${locale.toLanguageTag()} $size enlarged text and cancel is unchanged',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final service = LocalActivityProgressService();
          final pending = pendingResult(receiveSticker: true);
          await service.recordActivityResult(
            pending.result,
            vehicleId: 'motorcycle',
          );
          await tester.pumpWidget(
            app(
              ActivityHistoryScreen(activityProgressService: service),
              locale: locale,
              scale: 1.7,
            ),
          );
          await tester.pumpAndSettle();
          final delete = find.byKey(
            ValueKey('deleteActivityHistoryEntry-${pending.session.sessionId}'),
          );
          await tester.scrollUntilVisible(
            delete,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(delete);
          await tester.pumpAndSettle();
          await tester.tap(delete);
          await tester.pumpAndSettle();
          final texts = AppTexts.of(
            tester.element(find.byType(ActivityHistoryScreen)),
          );
          final checkbox = find.byType(CheckboxListTile);
          expect(tester.widget<CheckboxListTile>(checkbox).value, isFalse);
          await tester.ensureVisible(checkbox);
          await tester.tap(checkbox);
          await tester.pumpAndSettle();
          expect(tester.widget<CheckboxListTile>(checkbox).value, isTrue);
          final confirm = find.text(
            texts.activityHistory.deleteWithRewardsLabel,
          );
          await tester.ensureVisible(confirm);
          expect(confirm, findsOneWidget);
          final cancel = find.widgetWithText(TextButton, texts.common.cancel);
          await tester.ensureVisible(cancel);
          await tester.tap(cancel);
          await tester.pumpAndSettle();
          expect((await service.loadSnapshot()).inventory.single.count, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('linked confirmation removes awarded inventory', (tester) async {
    final service = LocalActivityProgressService();
    final pending = pendingResult(receiveSticker: true);
    await service.recordActivityResult(pending.result, vehicleId: 'motorcycle');
    await tester.pumpWidget(
      app(ActivityHistoryScreen(activityProgressService: service)),
    );
    await tester.pumpAndSettle();
    final texts = AppTexts.of(
      tester.element(find.byType(ActivityHistoryScreen)),
    );
    await tester.tap(
      find.byKey(
        ValueKey('deleteActivityHistoryEntry-${pending.session.sessionId}'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text(texts.activityHistory.deleteWithRewardsLabel));
    await tester.pumpAndSettle();
    expect((await service.loadSnapshot()).inventory, isEmpty);
  });

  testWidgets('option hidden for record without stickers or unused slots', (
    tester,
  ) async {
    final service = LocalActivityProgressService();
    final pending = pendingResult(receiveSticker: false);
    await service.recordActivityResult(pending.result, vehicleId: 'motorcycle');
    await tester.pumpWidget(
      app(ActivityHistoryScreen(activityProgressService: service)),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        ValueKey('deleteActivityHistoryEntry-${pending.session.sessionId}'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNothing);
  });

  testWidgets('corrupt journal exposes retry on every progress screen', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('activityRecordTransaction', '{bad');
    final service = LocalActivityProgressService();
    for (final screen in [
      ActivityHistoryScreen(activityProgressService: service),
      RewardGoalScreen(activityProgressService: service),
      StickerCollectionScreen(activityProgressService: service),
    ]) {
      await tester.pumpWidget(app(screen));
      await tester.pumpAndSettle();
      final retry = AppTexts.of(
        tester.element(find.byType(screen.runtimeType)),
      ).common.retry;
      expect(find.text(retry), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('saved data'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'dialog resets choice on reopen; dismiss and double tap do not delete',
    (tester) async {
      final service = LocalActivityProgressService();
      final pending = pendingResult(receiveSticker: true);
      await service.recordActivityResult(
        pending.result,
        vehicleId: 'motorcycle',
      );
      await tester.pumpWidget(
        app(ActivityHistoryScreen(activityProgressService: service)),
      );
      await tester.pumpAndSettle();
      final delete = find.byKey(
        ValueKey('deleteActivityHistoryEntry-${pending.session.sessionId}'),
      );
      final requestDelete = tester.widget<IconButton>(delete).onPressed!;
      requestDelete();
      requestDelete();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(AlertDialog))).pop();
      await tester.pumpAndSettle();
      expect((await service.loadSnapshot()).inventory.single.count, 1);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect((await service.loadSnapshot()).history, hasLength(1));
    },
  );

  testWidgets(
    'real route observer refreshes home history stickers and returned goal after linked delete',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = LocalActivityProgressService();
      final pending = pendingResult(receiveSticker: true);
      await service.createRewardGoal(
        requiredStickerCount: 1,
        rewardText: 'Park',
      );
      await service.recordActivityResult(
        pending.result,
        vehicleId: 'motorcycle',
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          navigatorObservers: [appRouteObserver],
          home: HomeScreen(
            config: pending.session.config.copyWith(childName: 'Riley'),
            activityProgressService: service,
            onConfigChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final openHistory = find.text("Riley's activity history");
      await tester.scrollUntilVisible(
        openHistory,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(openHistory);
      await tester.pumpAndSettle();
      final delete = find.byKey(
        ValueKey('deleteActivityHistoryEntry-${pending.session.sessionId}'),
      );
      await tester.scrollUntilVisible(
        delete,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      final texts = AppTexts.of(
        tester.element(find.byType(ActivityHistoryScreen)),
      );
      await tester.tap(find.text(texts.activityHistory.deleteWithRewardsLabel));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('No activity history yet.'), findsOneWidget);
      expect(find.textContaining('Park · 0/1'), findsOneWidget);
      final snapshot = await service.loadSnapshot();
      expect(snapshot.inventory, isEmpty);
      expect(snapshot.earnedRewardGoals, isEmpty);
    },
  );
  testWidgets(
    'disposed result cannot start media after delayed recording completes',
    (tester) async {
      final pending = pendingResult(receiveSticker: true);
      final service = PausedProgressService();
      final audio = TestResultAudioService();
      var media = 0;
      await tester.pumpWidget(
        app(
          ResultScreen(
            result: pending.result,
            config: pending.session.config,
            activityProgressService: service,
            orientationService: TestOrientationService(),
            resultAudioService: audio,
            introControllerFactory: (_) {
              media++;
              throw StateError('Disposed screen created media');
            },
            onConfigChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      await service.entered.future;
      await tester.pumpWidget(const SizedBox.shrink());
      service.release.complete();
      await tester.pumpAndSettle();
      expect(media, 0);
      expect(audio.calls.where((call) => call.startsWith('play')), isEmpty);
      expect(tester.takeException(), isNull);
      expect((await service.loadSnapshot()).history, hasLength(1));
    },
  );
}
