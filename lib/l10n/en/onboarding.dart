// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnOnboardingTexts implements OnboardingTextSet {
  const EnOnboardingTexts();

  String get skipButton => 'Skip';

  String pageIndicatorLabel(int currentPage, int totalPages) {
    return 'Onboarding card $currentPage of $totalPages';
  }

  List<OnboardingCardText> get cards => const [
    OnboardingCardText(
      title: "Kids can't see time yet",
      body:
          '“Five more minutes,” “Time to stop,”\n“Let’s get ready.”\nDaily routines can start to feel like\ntiny tug-of-wars.',
      note:
          'Your child may not be trying to delay on purpose.\nThey may still be learning what time feels like.',
      ctaLabel: 'Start together',
    ),
    OnboardingCardText(
      title: 'Turn routines into little rides',
      body:
          'Brushing, reading, cleanup, and play\ncan start as playful Timey Rider missions.',
      note:
          'Instead of only hearing the time, your child sees a chosen ride move along the course.',
      ctaLabel: 'Next',
    ),
    OnboardingCardText(
      title: 'Which vehicle today?',
      body:
          'A motorcycle, shark, T-rex, and more\ncan become today’s mission buddy.',
      note: 'Add your child’s face to make the ride feel like their own story.',
      ctaLabel: 'Choose a ride',
    ),
    OnboardingCardText(
      title: 'Small markers show each step',
      body:
          'Picture markers that fit the mission\nappear one by one along the course.',
      note:
          'Markers are not scorecards. They are visual cues that help the routine flow.',
      ctaLabel: 'Sounds good',
    ),
    OnboardingCardText(
      title: 'Trying matters most today',
      body:
          'Finished, time ended,\nor needed a little more time - each result is saved without judgment.',
      note:
          'Stickers are small encouragement gifts. Praise the effort before the reward.',
      ctaLabel: 'Start Timey',
    ),
  ];
}
