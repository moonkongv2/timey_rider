import 'package:flutter/material.dart';

import '../l10n/app_texts.dart';
import '../theme/app_spacing.dart';
import 'app/app_bouncy_button.dart';

class TimerControlBar extends StatelessWidget {
  const TimerControlBar({
    super.key,
    required this.isPaused,
    required this.onPauseResume,
    required this.onComplete,
  });

  final bool isPaused;
  final VoidCallback onPauseResume;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);

    return Row(
      children: [
        Flexible(
          flex: 9,
          child: AppBouncyButton(
            label: isPaused
                ? texts.common.restartRide
                : texts.timer.pauseButton,
            icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            onPressed: onPauseResume,
            variant: AppButtonVariant.outline,
            size: AppButtonSize.large,
            minHeight: 58,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          flex: 11,
          child: AppBouncyButton(
            label: texts.timer.completeMealButton,
            icon: Icons.check_circle_rounded,
            onPressed: onComplete,
            variant: AppButtonVariant.primary,
            size: AppButtonSize.large,
            minHeight: 58,
          ),
        ),
      ],
    );
  }
}
