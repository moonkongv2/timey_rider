import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

Future<void> showAppHelpSheet({
  required BuildContext context,
  required String title,
  List<String> bodyParagraphs = const [],
  List<String> bulletItems = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (context) => AppHelpSheet(
      title: title,
      bodyParagraphs: bodyParagraphs,
      bulletItems: bulletItems,
    ),
  );
}

class AppHelpSheet extends StatelessWidget {
  const AppHelpSheet({
    super.key,
    required this.title,
    this.bodyParagraphs = const [],
    this.bulletItems = const [],
  });

  final String title;
  final List<String> bodyParagraphs;
  final List<String> bulletItems;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textTheme = Theme.of(context).textTheme;
    final maxSheetHeight = mediaQuery.size.height * 0.9;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: AppShadows.hero,
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xl + mediaQuery.padding.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  key: const ValueKey('appHelpSheet'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.borderSoft,
                          borderRadius: AppRadius.pill,
                        ),
                        child: const SizedBox(width: 44, height: 5),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: textTheme.titleLarge?.copyWith(
                              color: AppColors.textStrong,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton.filledTonal(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.white.withValues(
                              alpha: 0.72,
                            ),
                            foregroundColor: AppColors.brown700,
                            fixedSize: const Size(44, 44),
                            shape: const CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                    if (bodyParagraphs.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      for (final paragraph in bodyParagraphs) ...[
                        Text(
                          paragraph,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.38,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                    if (bulletItems.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      for (final item in bulletItems)
                        _AppHelpBulletRow(text: item),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppHelpBulletRow extends StatelessWidget {
  const _AppHelpBulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
