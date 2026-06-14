// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class OnboardingTexts implements OnboardingTextSet {
  const OnboardingTexts();

  String get skipButton => '건너뛰기';

  String pageIndicatorLabel(int currentPage, int totalPages) {
    return '$currentPage/$totalPages번째 온보딩 카드';
  }

  List<OnboardingCardText> get cards => const [
    OnboardingCardText(
      title: '아이들에게 시간은\n아직 눈에 잘 보이지 않아요',
      body: '“5분만 더”, “이제 그만”, “빨리 준비하자”\n매일의 일상이 씨름처럼 느껴질 때가 있죠.',
      note: '아이가 일부러 미루는 게 아니라,\n아직 시간의 흐름을 몸으로 익히는 중 입니다.',
      ctaLabel: '괜찮아요, 같이 시작해요',
    ),
    OnboardingCardText(
      title: '오늘의 루틴을\n신나는 라이딩으로 바꿔요',
      body: '양치도, 책 읽기도, 정리도\nTimey Rider와 함께 미션처럼 시작해요.',
      note: '시계를 보는 대신, 아이가 고른 빠방이\n코스를 따라 달려요.',
      ctaLabel: '다음 코스로',
    ),
    OnboardingCardText(
      title: '오늘은 어떤 빠방을 탈까?',
      body: '오토바이도, 상어도, 티렉스도\n오늘의 미션 친구가 될 수 있어요.',
      note: '아이 얼굴을 빠방에 태우면 루틴이\n더 내 이야기처럼 느껴져요.',
      ctaLabel: '빠방 고르기',
    ),
    OnboardingCardText(
      title: '단기 목표가 코스 위에 나타나요',
      body: '미션에 어울리는 작은 그림 마커가\n코스 위에 차례로 나타나요.',
      note: '마커는 아이가 시간의 흐름을\n따라가게 해주는 시각적 표지예요.',
      ctaLabel: '좋아, 다음!',
    ),
    OnboardingCardText(
      title: '오늘 시도 해본 것만으로\n충분해요',
      body: '먼저 끝낼 수 있던 날도,\n시간이 더 필요했던 날도 있는 그대로 기록해요.',
      note: '스티커는 칭찬을 돕는 작은 선물이에요.\n루틴을 시도한 마음을 먼저 응원해주세요.',
      ctaLabel: 'Timey 시작하기',
    ),
  ];
}
