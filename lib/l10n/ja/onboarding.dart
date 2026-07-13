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
      title: '子どもはまだ時間が見えにくいものです',
      body:
          '「あと5分」「もうおしまい」「早く準備して」\n毎日の習慣がまるで綱引きのように\n感じられることがあります。',
      note:
          'お子様はわざと先延ばしにしているわけではなく、\nまだ時間の流れを体で学んでいる途中なのです。',
      ctaLabel: '一緒に始める',
    ),
    OnboardingCardText(
      title: 'いつものルーティンを\n楽しいドライブに',
      body:
          '歯磨き、読書、お片付けも\nTimey Riderと一緒にミッションのように楽しめます。',
      note:
          '時計を見る代わりに、自分で選んだ乗り物が\nコースを走るのを見守ります。',
      ctaLabel: '次へ',
    ),
    OnboardingCardText(
      title: '今日はどののりもの？',
      body:
          'バイク、サメ、ティラノサウルスなど\nたくさんのお友達が今日のミッションの仲間になります。',
      note: 'お子様の顔を乗せれば、ドライブが\n自分の物語のように感じられます。',
      ctaLabel: 'のりものを選ぶ',
    ),
    OnboardingCardText(
      title: '小さなマーカーが一歩ずつ知らせます',
      body:
          'ミッションに合わせたかわいい絵のマーカーが\nコースの上に順番に現れます。',
      note:
          'マーカーは成績表ではありません。\nルーティンをスムーズに進めるための目印です。',
      ctaLabel: 'いいですね',
    ),
    OnboardingCardText(
      title: '今日やってみたことが\n一番大切です',
      body:
          '早く終わった日も、少し時間が必要だった日も、\nありのままの結果を記録します。',
      note:
          'シールは小さな応援のプレゼントです。\nまずはルーティンに挑戦した気持ちを褒めてあげてください。',
      ctaLabel: 'Timeyを始める',
    ),
  ];
}
