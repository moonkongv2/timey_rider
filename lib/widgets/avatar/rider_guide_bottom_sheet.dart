import 'package:flutter/material.dart';

import '../../l10n/app_texts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class RiderGuideBottomSheet extends StatelessWidget {
  const RiderGuideBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context).avatarSetup;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texts.guidePopupTitle,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            ClipRRect(
              borderRadius: AppRadius.card,
              child: Image.asset('assets/images/rider_sample.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              texts.guidePopupMethodTitle,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(texts.guidePopupMethodIntro, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            Text(
              texts.guidePopupMethod1Title,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(texts.guidePopupMethod1Body, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            Text(
              texts.guidePopupMethod2Title,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(texts.guidePopupMethod2Body, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xxl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: AppRadius.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    texts.guidePopupPrivacyTitle,
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(texts.guidePopupPrivacyBody, style: textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    texts.guidePopupSafetyTitle,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(texts.guidePopupSafetyBody, style: textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(texts.guidePopupConfirmButton),
            ),
          ],
        ),
      ),
    );
  }
}
