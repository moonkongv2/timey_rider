// ignore_for_file: annotate_overrides

import '../../models/activity_completion_status.dart';
import '../text_sets.dart';

class ResultTexts implements ResultTextSet {
  const ResultTexts();

  String get rewardLoading => '기록 정리 중...';
  String get recordSaved => '오늘의 기록을 저장했어';
  String get stickerChoiceTitle => '이번 활동을 확인했나요?';
  String get stickerChoiceMessage => '아이와 함께 오늘 활동을 돌아본 뒤 선택해 주세요.';
  String get getStickerButton => '차량 스티커 받기';
  String get skipStickerButton => '이번엔 차량 스티커 받지 않기';

  String stickerChoiceTitleForStatus(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.timeEnded => '정해둔 시간이 끝났어요',
      _ => stickerChoiceTitle,
    };
  }

  String stickerChoiceMessageForStatus(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.timeEnded => '아이와 함께 돌아본 뒤 차량 스티커를 받을지 선택해 주세요.',
      _ => stickerChoiceMessage,
    };
  }

  String title(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => '오늘 활동을 기록했어!',
      ActivityCompletionStatus.timeEnded => '정해둔 시간이 끝났어',
      ActivityCompletionStatus.needsMoreTime => '조금 더 시간이 필요했어',
      ActivityCompletionStatus.canceled => '오늘 활동을 여기까지 했어',
    };
  }

  String primaryMessage(ActivityCompletionStatus status, {String? vehicleId}) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => '오늘 활동을 확인하고 기록했어.',
      ActivityCompletionStatus.timeEnded => '정해둔 시간이 끝났어.',
      ActivityCompletionStatus.needsMoreTime =>
        _needsMoreTimeMessagesByVehicle[vehicleId] ?? '조금 더 시간이 필요했어.',
      ActivityCompletionStatus.canceled => '오늘은 여기까지 쉬어가자.',
    };
  }

  String secondaryMessage(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => '시도한 과정도 함께 기억할게.',
      ActivityCompletionStatus.timeEnded => '이제 다음 흐름을 차분히 정해보자.',
      ActivityCompletionStatus.needsMoreTime => '괜찮아. 다음에는 시간을 살짝 바꿔보자.',
      ActivityCompletionStatus.canceled => '다음에 다시 이어가도 괜찮아.',
    };
  }

  String get parentTipLabel => '부모님 응원 팁';

  String parentTipTitle(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => '아이에게 이렇게 말해보세요',
      ActivityCompletionStatus.timeEnded => '차분하게 다음 흐름을 알려주세요',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => '다음 도전을 부드럽게 응원해요',
    };
  }

  String parentTipSubtitle(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        '결과보다 활동에 참여한 과정과 노력을 먼저 봐주세요.',
      ActivityCompletionStatus.timeEnded => '시간이 끝난 것도 자연스러운 루틴의 일부예요.',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => '아쉬운 결과도 다음 조절을 위한 기록이에요.',
    };
  }

  String parentTipSemanticLabel(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => '완료 결과 부모님 응원 팁 보기',
      ActivityCompletionStatus.timeEnded => '시간 종료 결과 부모님 응원 팁 보기',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => '미완료 결과 부모님 응원 팁 보기',
    };
  }

  String helpButtonLabel(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => '활동 기록과 격려 안내',
      ActivityCompletionStatus.timeEnded => '시간 종료와 다음 흐름 안내',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => '다음 시도를 위한 안내',
    };
  }

  String helpTitle(ActivityCompletionStatus status) => helpButtonLabel(status);

  List<String> helpBodyParagraphs(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        '아이와 함께 확인한 내용이 오늘 활동 기록으로 남아요.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        '시간이 끝난 뒤 아이와 함께 확인하고 기록돼요.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        '활동이 마무리되지 않았으면 다음 시도를 위한 기록으로 남겨요.',
      ],
    };
  }

  List<String> helpBulletItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        '차량 스티커 받기를 선택하면 선택한 차량 스티커 1장을 받아요.',
        '보상 목표가 있으면 받은 차량 스티커가 목표 칸을 채울 수 있어요.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        '시간 종료 활동은 완료된 흐름으로 기록돼요.',
        '아이와 함께 확인한 뒤 차량 스티커를 받을지 선택해요.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        '이번엔 차량 스티커 받지 않기를 선택하면 기록만 남아요.',
        '미완료는 벌이 아니라 다음 조절을 위한 기록이에요.',
      ],
    };
  }

  String resultHelpMeaningTitle(ActivityCompletionStatus status) =>
      '이번 결과는 어떤 의미인가요?';

  List<String> resultHelpMeaningItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        '아이와 함께 확인한 내용이 오늘 활동 기록으로 남아요.',
        '차량 스티커 받기를 선택하면 선택한 차량 스티커 1장을 받아요.',
        '보상 목표가 있으면 받은 차량 스티커가 목표 칸을 채울 수 있어요.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        '정해둔 시간이 끝나 활동이 마무리된 기록이에요.',
        '성공이나 실패를 가르는 결과가 아니라 루틴 흐름을 지키는 기록이에요.',
        '아이와 함께 확인한 뒤 차량 스티커를 받을지 선택해요.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        '이번 활동에는 시간이 조금 더 필요했다는 기록이에요.',
        '이번엔 차량 스티커 받지 않기를 선택하면 기록만 남아요.',
        '미완료는 벌이 아니라 다음 조절을 위한 기록이에요.',
      ],
    };
  }

  String resultHelpSayTitle(ActivityCompletionStatus status) =>
      '아이에게 이렇게 말해보세요';

  List<String> resultHelpSayItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        '오늘 활동을 같이 해본 게 좋았어.',
        '정해둔 시간 동안 해본 걸 기억할게.',
        '차량 스티커보다 네가 해본 과정이 더 중요해.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        '시간이 끝났네. 이제 다음 흐름을 정해보자.',
        '정해둔 시간 동안 해본 걸 기억할게.',
        '다음에는 어떤 활동을 해볼까?',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        '오늘은 시간이 조금 더 필요했네. 괜찮아.',
        '어디까지 했는지 같이 봐볼까?',
        '다음에는 시간을 조금 늘려볼게.',
      ],
    };
  }

  String resultHelpAvoidTitle(ActivityCompletionStatus status) => '이런 말은 피해주세요';

  List<String> resultHelpAvoidItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        '빨리 해서 잘했어.',
        '다음에도 무조건 성공해야 해.',
        '차량 스티커 받으려면 더 잘해야지.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        '시간 끝났으니까 무조건 그만해.',
        '왜 더 못 했어?',
        '빨리 다음 거 해야 해.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        '실패했네.',
        '왜 이것밖에 못 했어?',
        '차량 스티커 못 받았으니까 속상하지?',
      ],
    };
  }

  String resultHelpNextCourseTitle(ActivityCompletionStatus status) =>
      '다음 활동은 이렇게 조절해보세요';

  List<String> resultHelpNextCourseItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        '활동 흐름이 짧게 느껴졌다면 다음에는 시간을 조금 조절해도 좋아요.',
        '여유 있게 완료했다면 같은 시간을 반복해 안정감을 만들어 주세요.',
        '차량 스티커보다 활동 흐름과 시도를 먼저 칭찬해 주세요.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        '시간 종료가 자연스러운 활동은 같은 시간을 유지해도 좋아요.',
        '아이가 아쉬워했다면 다음에는 시간을 조금 늘려보세요.',
        '다음 활동으로 넘어갈 때 짧게 예고해 주세요.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        '미완료가 자주 나온다면 기본 시간을 조금 늘려보세요.',
        '활동이 어렵다면 작은 단계로 나누어 표시해 주세요.',
        '기록은 아이를 평가하기보다 루틴 흐름을 이해하는 데 사용해 주세요.',
      ],
    };
  }
}

const _needsMoreTimeMessagesByVehicle = {
  'motorcycle': '이번 활동에는 시간이 조금 더 필요했어.',
  'fire_truck': '이번 활동에는 시간이 조금 더 필요했어.',
  'police_car': '이번 활동에는 시간이 조금 더 필요했어.',
  'excavator': '이번 활동에는 시간이 조금 더 필요했어.',
  'airplane': '이번 활동에는 시간이 조금 더 필요했어.',
  'bus': '이번 활동에는 시간이 조금 더 필요했어.',
  'supercar': '이번 활동에는 시간이 조금 더 필요했어.',
  'train': '이번 활동에는 시간이 조금 더 필요했어.',
  't_rex': '이번 활동에는 시간이 조금 더 필요했어.',
  'shark': '이번 활동에는 시간이 조금 더 필요했어.',
  'brachio': '이번 활동에는 시간이 조금 더 필요했어.',
  'pteranodon': '이번 활동에는 시간이 조금 더 필요했어.',
};
