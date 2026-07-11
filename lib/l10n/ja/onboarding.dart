// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class JaOnboardingTexts implements OnboardingTextSet {
  const JaOnboardingTexts();

  String get skipButton => 'スキップ';

  String pageIndicatorLabel(int currentPage, int totalPages) {
    return 'Onboarding card $currentPage of $totalPages';
  }

  List<OnboardingCardText> get cards => const [
    OnboardingCardText(
      title: '子どもはまだ時間を見えにくいものです',
      body:
          '“Five more minutes,” “Time to stop,”\n“Let’s get ready.”\nDaily routines can start to feel like\ntiny tug-of-wars.',
      note:
          'Your child may not be trying to delay on purpose.\nThey may still be learning what time feels like.',
      ctaLabel: '一緒に始める',
    ),
    OnboardingCardText(
      title: 'いつもの流れを小さなライドに',
      body:
          'Brushing, reading, cleanup, and play\ncan start as playful Timey Rider missions.',
      note:
          'Instead of only hearing the time, your child sees a chosen ride move along the course.',
      ctaLabel: '次へ',
    ),
    OnboardingCardText(
      title: '今日はどののりもの？',
      body:
          'A motorcycle, shark, T-rex, and more\ncan become today’s mission buddy.',
      note: 'Add your child’s face to make the ride feel like their own story.',
      ctaLabel: 'ライドを選ぶ',
    ),
    OnboardingCardText(
      title: '小さなマーカーが一歩ずつ知らせます',
      body:
          'Picture markers that fit the mission\nappear one by one along the course.',
      note:
          'Markers are not scorecards. They are visual cues that help the routine flow.',
      ctaLabel: 'いいですね',
    ),
    OnboardingCardText(
      title: '今日いちばん大切なのはやってみること',
      body:
          'Finished, time ended,\nor needed a little more time - each result is saved without judgment.',
      note:
          'Stickers are small encouragement gifts. Praise the effort before the reward.',
      ctaLabel: 'Timeyを始める',
    ),
  ];
}
