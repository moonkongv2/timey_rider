import 'package:flutter/material.dart';

import '../l10n/app_texts.dart';
import '../l10n/text_sets.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/app/app_bouncy_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final Future<void> Function() onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  var _currentPage = 0;
  var _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_isFinishing) {
      return;
    }
    setState(() => _isFinishing = true);
    await widget.onFinished();
    if (mounted) {
      setState(() => _isFinishing = false);
    }
  }

  void _goToNextPage(int totalPages) {
    if (_currentPage >= totalPages - 1) {
      _finish();
      return;
    }
    _pageController.animateToPage(
      _currentPage + 1,
      duration: AppMotion.normal,
      curve: AppMotion.curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingTexts = AppTexts.of(context).onboarding;
    final cards = onboardingTexts.cards;
    final totalPages = cards.length;
    final isLastPage = _currentPage == totalPages - 1;

    return Scaffold(
      key: const ValueKey('onboardingScreen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: isLastPage
                      ? const SizedBox.shrink()
                      : TextButton(
                          key: const ValueKey('onboardingSkipButton'),
                          onPressed: _isFinishing ? null : _finish,
                          child: Text(onboardingTexts.skipButton),
                        ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  key: const ValueKey('onboardingPageView'),
                  controller: _pageController,
                  itemCount: totalPages,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemBuilder: (context, index) {
                    return _OnboardingPage(
                      card: cards[index],
                      pageIndex: index,
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                label: onboardingTexts.pageIndicatorLabel(
                  _currentPage + 1,
                  totalPages,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < totalPages; index++) ...[
                      if (index > 0) const SizedBox(width: AppSpacing.sm),
                      _PageIndicatorDot(
                        key: ValueKey('onboardingPageIndicator_$index'),
                        isSelected: index == _currentPage,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppBouncyButton(
                key: const ValueKey('onboardingNextButton'),
                label: cards[_currentPage].ctaLabel,
                icon: isLastPage
                    ? Icons.flag_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: _isFinishing
                    ? null
                    : () => _goToNextPage(totalPages),
                variant: AppButtonVariant.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.card, required this.pageIndex});

  final OnboardingCardText card;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: pageIndex.isEven
                      ? AppColors.surfaceWarm
                      : AppColors.white,
                  borderRadius: AppRadius.hero,
                  border: Border.all(color: AppColors.borderWarm, width: 1.2),
                  boxShadow: AppShadows.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _OnboardingIllustration(pageIndex: pageIndex),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        card.title,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.textStrong,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        card.body,
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          height: 1.38,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: AppRadius.card,
                          border: Border.all(color: AppColors.borderSoft),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            card.note,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.pageIndex});

  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final spec = _OnboardingIllustrationSpec.forPage(pageIndex);

    return AspectRatio(
      aspectRatio: 1.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: spec.backgroundColor,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.card,
          child: _OnboardingIllustrationAsset(
            assetPath: spec.assetPath,
            fallback: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: spec.fallback,
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingIllustrationSpec {
  const _OnboardingIllustrationSpec({
    required this.assetPath,
    required this.backgroundColor,
    required this.fallback,
  });

  final String? assetPath;
  final Color backgroundColor;
  final Widget fallback;

  static _OnboardingIllustrationSpec forPage(int pageIndex) {
    return switch (pageIndex) {
      0 => const _OnboardingIllustrationSpec(
        assetPath: 'assets/images/onboarding/onboarding_01_time.png',
        backgroundColor: AppColors.surfaceBlue,
        fallback: _SoftTimeIllustration(),
      ),
      1 => const _OnboardingIllustrationSpec(
        assetPath: 'assets/images/onboarding/onboarding_02_routine_ride.png',
        backgroundColor: AppColors.surfaceMint,
        fallback: _RideCourseIllustration(),
      ),
      2 => const _OnboardingIllustrationSpec(
        assetPath: null,
        backgroundColor: AppColors.surfaceYellow,
        fallback: _VehicleChoiceIllustration(),
      ),
      3 => const _OnboardingIllustrationSpec(
        assetPath: 'assets/images/onboarding/onboarding_04_course_markers.png',
        backgroundColor: AppColors.surfacePink,
        fallback: _MarkerCourseIllustration(),
      ),
      _ => const _OnboardingIllustrationSpec(
        assetPath:
            'assets/images/onboarding/onboarding_05_result_encouragement.png',
        backgroundColor: AppColors.primarySoft,
        fallback: _GentleResultIllustration(),
      ),
    };
  }
}

class _OnboardingIllustrationAsset extends StatelessWidget {
  const _OnboardingIllustrationAsset({
    required this.assetPath,
    required this.fallback,
  });

  final String? assetPath;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final assetPath = this.assetPath;
    if (assetPath == null) {
      return fallback;
    }

    return Image.asset(
      assetPath,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

class _SoftTimeIllustration extends StatelessWidget {
  const _SoftTimeIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(top: 8, left: 10, child: _DecorativeDot(size: 10)),
        const Positioned(top: 28, right: 30, child: _DecorativeDot(size: 8)),
        const Positioned(bottom: 18, right: 6, child: _DecorativeDot(size: 12)),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.82),
              borderRadius: AppRadius.hero,
              border: Border.all(color: AppColors.borderSoft, width: 1.4),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              size: 58,
              color: AppColors.primary,
            ),
          ),
        ),
        const Align(
          alignment: Alignment(-0.9, 0.75),
          child: _EmojiChip(emoji: '🪥'),
        ),
        const Align(
          alignment: Alignment(0.9, 0.72),
          child: _EmojiChip(emoji: '📚'),
        ),
        const Align(
          alignment: Alignment(-0.72, -0.58),
          child: _EmojiChip(emoji: '🧸'),
        ),
      ],
    );
  }
}

class _RideCourseIllustration extends StatelessWidget {
  const _RideCourseIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: const [
        _RoadPath(),
        Align(
          alignment: Alignment(-0.62, 0.28),
          child: _EmojiChip(emoji: '🏍️'),
        ),
        Align(alignment: Alignment(0.62, -0.28), child: _MarkerIcon()),
      ],
    );
  }
}

class _VehicleChoiceIllustration extends StatelessWidget {
  const _VehicleChoiceIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        Positioned(top: 4, left: 18, child: _DecorativeDot(size: 9)),
        Positioned(top: 12, right: 32, child: _DecorativeDot(size: 12)),
        Positioned(bottom: 10, left: 74, child: _DecorativeDot(size: 7)),
        Positioned(bottom: 18, right: 12, child: _DecorativeDot(size: 10)),
        Align(
          alignment: Alignment(-0.86, -0.72),
          child: _VehicleImageChip(
            assetPath: 'assets/images/vehicle_motorcycle_chip.png',
            size: 64,
          ),
        ),
        Align(
          alignment: Alignment(0.0, -0.78),
          child: _VehicleImageChip(
            assetPath: 'assets/images/vehicle_shark_chip.png',
            size: 64,
          ),
        ),
        Align(
          alignment: Alignment(0.86, -0.72),
          child: _VehicleImageChip(
            assetPath: 'assets/images/vehicle_t_rex_chip.png',
            size: 64,
          ),
        ),
        Align(
          alignment: Alignment(-0.86, 0.76),
          child: _VehicleImageChip(
            assetPath: 'assets/images/vehicle_police_car_chip.png',
            size: 64,
          ),
        ),
        Align(
          alignment: Alignment(0.0, 0.82),
          child: _VehicleImageChip(
            assetPath: 'assets/images/vehicle_excavator_chip.png',
            size: 64,
          ),
        ),
        Align(
          alignment: Alignment(0.86, 0.76),
          child: _VehicleImageChip(
            assetPath: 'assets/images/vehicle_airplane_chip.png',
            size: 64,
          ),
        ),
      ],
    );
  }
}

class _VehicleImageChip extends StatelessWidget {
  const _VehicleImageChip({required this.assetPath, required this.size});

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.surface,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.pill,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.directions_car_filled_rounded,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _MarkerCourseIllustration extends StatelessWidget {
  const _MarkerCourseIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: const [
        _RoadPath(),
        Align(alignment: Alignment(-0.65, -0.26), child: _MarkerIcon()),
        Align(alignment: Alignment(0.0, 0.24), child: _MarkerIcon()),
        Align(alignment: Alignment(0.66, -0.12), child: _MarkerIcon()),
        Align(
          alignment: Alignment(-0.2, -0.52),
          child: _EmojiChip(emoji: '🪥'),
        ),
      ],
    );
  }
}

class _GentleResultIllustration extends StatelessWidget {
  const _GentleResultIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: const [
        Align(
          alignment: Alignment(-0.55, 0.25),
          child: _EmojiChip(emoji: '⭐', large: true),
        ),
        Align(
          alignment: Alignment(0.52, 0.18),
          child: _EmojiChip(emoji: '🎁', large: true),
        ),
        Align(
          alignment: Alignment(0.0, -0.48),
          child: Icon(
            Icons.favorite_rounded,
            color: AppColors.primary,
            size: 46,
          ),
        ),
      ],
    );
  }
}

class _RoadPath extends StatelessWidget {
  const _RoadPath();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RoadPathPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _RoadPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;
    final dashPaint = Paint()
      ..color = AppColors.brown300.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.72)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.38,
        size.width * 0.58,
        size.height * 0.86,
        size.width * 0.88,
        size.height * 0.28,
      );
    canvas.drawPath(path, paint);

    for (var i = 0; i < 5; i++) {
      final dx = size.width * (0.22 + i * 0.14);
      final dy = size.height * (i.isEven ? 0.60 : 0.50);
      canvas.drawLine(Offset(dx, dy), Offset(dx + 14, dy - 4), dashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPathPainter oldDelegate) => false;
}

class _EmojiChip extends StatelessWidget {
  const _EmojiChip({required this.emoji, this.large = false});

  final String emoji;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 62.0 : 46.0;
    final fontSize = large ? 30.0 : 23.0;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.surface,
      ),
      child: Text(
        emoji,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: fontSize, height: 1, letterSpacing: 0),
      ),
    );
  }
}

class _MarkerIcon extends StatelessWidget {
  const _MarkerIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.surface,
      ),
      child: const Icon(
        Icons.assistant_photo_rounded,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }
}

class _DecorativeDot extends StatelessWidget {
  const _DecorativeDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.78),
        borderRadius: AppRadius.pill,
      ),
      child: SizedBox.square(dimension: size),
    );
  }
}

class _PageIndicatorDot extends StatelessWidget {
  const _PageIndicatorDot({super.key, required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.normal,
      curve: AppMotion.curve,
      width: isSelected ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.brown300,
        borderRadius: AppRadius.pill,
      ),
    );
  }
}
