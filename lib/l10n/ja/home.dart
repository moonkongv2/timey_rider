// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/activity_completion_status.dart';

class JaHomeTexts implements HomeTextSet {
  const JaHomeTexts();

  String get subtitle => '今日のルーティンライドを始める？';
  String get heroMissionTitle => '今日のミッション';
  String get heroMissionSubtitle => 'ライダーが楽しいゴールを待っています';
  String get todayVehicleTitle => '今日ののりもの';
  String get vehiclePickerTitle => 'のりものを選ぶ';
  String get vehicleChangeButton => '変更';
  String get morningCourse => '15分ライド';
  String get morningCourseSubtitle => '軽くウォームアップ';
  String get slowCourse => '35分ライド';
  String get slowCourseSubtitle => 'ゴールまでゆっくり進もう';
  String get quickCourseTitle => 'ほかの活動';
  String get activityQuickStartTitle => '今日のミッション';
  String get customStartButton => '自由ライドを始める';
  String get customSheetTitle => '自由な時間';
  String get customTimerTitle => 'その他';
  String get timerBuilderButton => 'タイマーを作る';
  String get timerBuilderSubtitle => '始める前にミッション、マーカー、時間を選びます。';
  String get timerBuilderSheetTitle => 'タイマーを作る';
  String get timerBuilderActivityStepTitle => '1. ミッション';
  String get timerBuilderMarkerStepTitle => '2. マーカー';
  String get timerBuilderAutomaticMarkerOption => '自動';
  String get timerBuilderManualMarkerOption => '選ぶ';
  String get timerBuilderRecentPresetTitle => '最近の設定';
  String get timerBuilderRecentPresetApplyButton => '適用';
  String get timerBuilderSavedPresetTitle => '保存したタイマー';
  String get timerBuilderSavePresetButton => '保存';
  String get timerBuilderSavedPresetMessage => '保存しました。';
  String get timerBuilderSavedPresetFullMessage => '保存しました。古いタイマーは自動で整理されます。';
  String get timerBuilderSavedPresetLimitHint => '新しく保存すると一番古いタイマーが入れ替わります。';
  String get timerBuilderDeletePresetTooltip => '削除';
  String get timerBuilderFavoritePresetTooltip => 'ホームに表示';
  String get timerBuilderUnfavoritePresetTooltip => 'ホームで非表示';
  String get timerBuilderFavoritePresetLimitMessage => 'ホームに表示できるタイマーは3つまでです。';
  String get timerBuilderCustomNameDialogTitle => 'タイマー名';
  String get timerBuilderCustomNameFieldLabel => '名前';
  String get timerBuilderUseOtherNameButton => 'その他として保存';
  String get timerBuilderTimeStepTitle => '3. 時間';
  String get timerBuilderStartButton => 'スタート';
  String get timerBuilderSelectedMarkerEmpty => 'マーカーを1〜5個選んでください。';
  String get activitySummaryLabel => 'ミッション';
  String get stickerKindSummaryLabel => 'のりものの種類';
  String get stickerSummaryLabel => 'ステッカー';
  String get noActivityHistory => '活動記録はまだありません。';
  String get openStickerCollection => 'ステッカーを見る';
  String get avatarCtaSubtitle => 'お子さまの顔をライドに追加できます。';
  String get avatarCtaButton => '作成';
  String get avatarCtaEditButton => '編集';
  String get avatarCtaCreateSemantics => 'ライダー画像を作成';
  String get avatarCtaEditSemantics => 'ライダー画像を編集';
  String get avatarInlineDefaultState => '標準の顔を使用中';
  String get avatarInlineCustomState => 'カスタムライダー準備完了';
  String get activeTimerTitle => '活動タイマーが進行中';
  String get activeTimerResumeButton => '再開';
  String get activeTimerCancelButton => 'タイマーをキャンセル';
  String get activeTimerCancelDialogTitle => '進行中のタイマーをキャンセルしますか？';
  String get activeTimerCancelDialogMessage => 'この活動タイマーは履歴に保存されません。';
  String get activeTimerNewTimerDialogTitle => 'タイマーがすでに進行中です';
  String get activeTimerNewTimerDialogMessage =>
      '新しいタイマーを始めると、現在のタイマーはキャンセルされます。';
  String get activeTimerStartNewButton => '新しく始める';
  String get activeTimerArrivedSubtitle => '活動時間が終わりました';

  String recentCustomMinutes(int minutes) => '最近の$minutes分';
  String minuteLabel(int minutes) => '$minutes分';
  String timerBuilderSavedPresetCount(int count, int maxCount) {
    return '$count/$maxCount';
  }

  String activeTimerSubtitle(String remainingTime) => '残り $remainingTime';
  String normalCourse(int minutes) => '$minutes分 標準ライド';
  String alternateCourse(int minutes) => '$minutes分 ライド';
  String alternateCourseSubtitle(int minutes) {
    return switch (minutes) {
      15 => '軽くウォームアップ',
      25 => '毎日にちょうどいいペース',
      35 => 'ゴールまでゆっくり進もう',
      _ => '$minutes分走ろう',
    };
  }

  String progressTitle(String childName) => '$childNameの活動履歴';
  String activityCount(int count) => '$count';
  String stickerKindCount(int count) => '$count';
  String stickerCount(int count) => '$count';
  String recentActivitySummary(
    String actualDuration,
    ActivityCompletionStatus completionStatus,
  ) {
    final status = switch (completionStatus) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => '完了',
      ActivityCompletionStatus.timeEnded => '時間終了',
      ActivityCompletionStatus.needsMoreTime => 'もう少し時間が必要',
      ActivityCompletionStatus.canceled => 'キャンセル',
    };
    return '最近の活動 $actualDuration · $status';
  }
}
