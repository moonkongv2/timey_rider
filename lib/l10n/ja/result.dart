// ignore_for_file: annotate_overrides

import '../../models/activity_completion_status.dart';
import '../text_sets.dart';

class JaResultTexts implements ResultTextSet {
  const JaResultTexts();

  String get rewardLoading => '記録を保存中...';
  String get recordSaved => "今日の記録を保存しました。";
  String get stickerChoiceTitle => 'この活動を確認しましたか？';
  String get stickerChoiceMessage => "今日の活動を一緒に振り返ってから選んでください。";
  String get getStickerButton => 'ステッカーをもらう';
  String get skipStickerButton => '今回はステッカーなし';

  String stickerChoiceTitleForStatus(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.timeEnded => '予定の時間が終わりました',
      _ => stickerChoiceTitle,
    };
  }

  String stickerChoiceMessageForStatus(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.timeEnded => '一緒に確認して、ステッカーをもらうか選んでください。',
      _ => stickerChoiceMessage,
    };
  }

  String title(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => "今日の活動を記録しました！",
      ActivityCompletionStatus.timeEnded => '予定の時間が終わりました',
      ActivityCompletionStatus.needsMoreTime => 'もう少し時間が必要でした',
      ActivityCompletionStatus.canceled => "今日はここまで",
    };
  }

  String primaryMessage(ActivityCompletionStatus status, {String? vehicleId}) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => "今日の活動を確認して保存しました。",
      ActivityCompletionStatus.timeEnded => 'タイマーがゴールしました。',
      ActivityCompletionStatus.needsMoreTime =>
        _needsMoreTimeMessagesByVehicle[vehicleId] ?? 'もう少し時間があるとよさそうです。',
      ActivityCompletionStatus.canceled => "今日はここでひと休みしましょう。",
    };
  }

  String secondaryMessage(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => 'がんばった過程も一緒に覚えておきます。',
      ActivityCompletionStatus.timeEnded => "次にどうするか、落ち着いて決めましょう。",
      ActivityCompletionStatus.needsMoreTime => "大丈夫。次は少し時間を増やしてみましょう。",
      ActivityCompletionStatus.canceled => 'また次に試せます。',
    };
  }

  String get parentTipLabel => '保護者向けヒント';

  String parentTipTitle(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => 'こんな声かけを試す',
      ActivityCompletionStatus.timeEnded => '次の流れを落ち着いて伝える',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => '次の挑戦をやさしく応援',
    };
  }

  String parentTipSubtitle(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        '結果より先に、参加したことと努力を見てあげてください。',
      ActivityCompletionStatus.timeEnded => 'タイマーが終わることも、いつもの流れの一部です。',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => '罰ではなく、次に調整するための手がかりです。',
    };
  }

  String parentTipSemanticLabel(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => '完了した活動の保護者向けヒントを見る',
      ActivityCompletionStatus.timeEnded => '時間終了した活動の保護者向けヒントを見る',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => '未完了の活動の保護者向けヒントを見る',
    };
  }

  String helpButtonLabel(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => '活動記録と声かけのヒント',
      ActivityCompletionStatus.timeEnded => '時間終了後の次のヒント',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => '次の挑戦のヒント',
    };
  }

  String helpTitle(ActivityCompletionStatus status) => helpButtonLabel(status);

  List<String> helpBodyParagraphs(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        '一緒に確認した内容は、今日の活動記録に保存されます。',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'タイマーが終わったら、ミッションを一緒に確認して記録を保存します。',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        '活動を最後まで終えられなかった場合も、次の挑戦の手がかりとして記録を残します。',
      ],
    };
  }

  List<String> helpBulletItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        '「ステッカーをもらう」を選ぶと、選択中ののりもののステッカーを1枚受け取れます。',
        '有効なごほうび目標がある場合、ステッカーで目標の枠を1つ埋められます。',
      ],
      ActivityCompletionStatus.timeEnded => const [
        '時間で終わった活動も、いつもの流れの一部として記録されます。',
        '一緒に確認してから、ステッカーをもらうか選んでください。',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        '「今回はステッカーなし」を選ぶと、ステッカーなしで記録を保存します。',
        '未完了の結果は次の計画の手がかりであり、罰ではありません。',
      ],
    };
  }

  String resultHelpMeaningTitle(ActivityCompletionStatus status) => 'この結果の意味';

  List<String> resultHelpMeaningItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        '一緒に確認した内容は、今日の活動記録に保存されます。',
        '「ステッカーをもらう」を選ぶと、選択中ののりもののステッカーを1枚受け取れます。',
        '有効なごほうび目標がある場合、ステッカーで目標の枠を1つ埋められます。',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'タイマーが最後まで進み、活動が記録されました。',
        'これは合否ではなく、ルーティンの切り替わりです。',
        '一緒に確認してから、ステッカーをもらうか選んでください。',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        '今日の活動には、もう少し時間が必要でした。',
        '「今回はステッカーなし」を選ぶと、ステッカーなしで記録を保存します。',
        '記録を使って、次の挑戦を調整しましょう。',
      ],
    };
  }

  String resultHelpSayTitle(ActivityCompletionStatus status) => 'こんな声かけを試す';

  List<String> resultHelpSayItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        '今日は一緒にこの活動ができてうれしかったよ。',
        'タイマーが動いている間、がんばっていたのを見ていたよ。',
        'ステッカーも楽しいけれど、いちばん大切なのはがんばったことだよ。',
      ],
      ActivityCompletionStatus.timeEnded => const [
        '時間になったね。次にどうするか決めよう。',
        'タイマーが動いている間、がんばっていたのを見ていたよ。',
        '次はどの活動を試してみようか？',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        '今日はもう少し時間が必要だったね。大丈夫だよ。',
        'どこまでできたか一緒に見てみよう。',
        '次はもう少し時間を増やせるよ。',
      ],
    };
  }

  String resultHelpAvoidTitle(ActivityCompletionStatus status) => '避けたい声かけ';

  List<String> resultHelpAvoidItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        '早くできてえらいね。',
        '毎回成功しないといけないよ。',
        'ステッカーをもらうには、もっと上手にやらないとね。',
      ],
      ActivityCompletionStatus.timeEnded => const [
        '時間切れだから、もうやめないといけないよ。',
        'どうしてもっとできなかったの？',
        '急いで次に行こう。',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        '失敗したね。',
        'どうしてこれだけしかできなかったの？',
        'うまくできなかったからステッカーはなしだよ。',
      ],
    };
  }

  String resultHelpNextCourseTitle(ActivityCompletionStatus status) =>
      '次の活動に向けて';

  List<String> resultHelpNextCourseItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        '活動の流れが短く感じた場合は、次回タイマーを調整してみてください。',
        'お子さまが落ち着いて取り組めていたら、同じ長さを繰り返して自信につなげます。',
        'ステッカーよりも、ルーティンの流れと努力をほめてください。',
      ],
      ActivityCompletionStatus.timeEnded => const [
        '時間で終える活動では、同じ長さを保つだけで十分な場合があります。',
        'お子さまがもっと時間をほしがった場合は、次回少し長めのタイマーを試してください。',
        '次の活動へ移る前に、短い合図を出してください。',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        '未完了がよく起きる場合は、標準の時間を少し長くしてみてください。',
        '活動が難しそうな場合は、見える小さなステップに分けてください。',
        '記録はお子さまを評価するためではなく、ルーティンの傾向を知るために使います。',
      ],
    };
  }
}

const _needsMoreTimeMessagesByVehicle = {
  'motorcycle': '今日の活動には、もう少し時間が必要でした。',
  'fire_truck': '今日の活動には、もう少し時間が必要でした。',
  'police_car': '今日の活動には、もう少し時間が必要でした。',
  'excavator': '今日の活動には、もう少し時間が必要でした。',
  'airplane': '今日の活動には、もう少し時間が必要でした。',
  'bus': '今日の活動には、もう少し時間が必要でした。',
  'supercar': '今日の活動には、もう少し時間が必要でした。',
  'train': '今日の活動には、もう少し時間が必要でした。',
  't_rex': '今日の活動には、もう少し時間が必要でした。',
  'shark': '今日の活動には、もう少し時間が必要でした。',
  'brachio': '今日の活動には、もう少し時間が必要でした。',
  'pteranodon': '今日の活動には、もう少し時間が必要でした。',
};
