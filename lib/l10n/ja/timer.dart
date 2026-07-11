// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class JaTimerTexts implements TimerTextSet {
  const JaTimerTexts();

  String get missionTitle => '今日のミッション';
  String get progressJustStarted => '出発！';
  String get progressGoingWell => 'いい調子！';
  String get progressPastHalfway => 'ここまでよく来たね！';
  String get progressAlmostThere => 'もうすぐ！';
  String get progressArrived => '到着！';
  String completeDialogTitle(String activityLabel) => '$activityLabelは終わりましたか？';
  String completeDialogMessage(String activityLabel) =>
      '$activityLabelミッションを完了しますか？';
  String get exitDialogTitle => 'このライドを離れますか？';
  String get exitDialogMessage => '今離れると、このミッションは保存されません。';
  String get exitDialogCancelButton => '続ける';
  String get exitDialogConfirmButton => '離れる';
  String get pauseButton => '一時停止';
  String completeActivityButton(String activityId) {
    return switch (activityId) {
      'brushing' => '歯みがき完了',
      'reading' => '読書完了',
      'cleanup' => 'お片づけ完了',
      'play' => '遊び完了',
      _ => 'ミッション完了',
    };
  }

  String get remainingTimeLabel => '残り時間';
  String get pausedTimeLabel => 'ひと休み中';
  String get arrivedTimeLabel => '到着';
  String get idleTimeLabel => '準備中';
  String get pausedProgressMessage => '少し休憩中';
  String get arrivedProgressMessage => '到着！';
  String get idleProgressMessage => '準備中';
  String get finishDriveProgressMessage => 'ゴールへ向かっています！';
  String get finishDriveTimeLabel => '仕上げ中';
  String get previewReady => 'よーい… 🚦';
  String get previewGo => 'スタート！ 🌟';
  String get arrivalConfirmButton => '到着を見る';
  String get arrivalResultButton => '結果を見る';

  String arrivalDialogMessage(String vehicleLabel, String activityLabel) {
    return '$vehicleLabelが到着しました。ミッションは終わりましたか？';
  }

  String arrivalReachedMessage(String vehicleLabel) {
    return '$vehicleLabelが到着しました。';
  }

  String remainingTime(String remaining) => '残り時間 $remaining';
  String remainingTimeSemanticLabel(String label, String remaining) {
    return '$label、残り $remaining';
  }
}
