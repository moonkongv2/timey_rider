import 'package:flutter/material.dart';

import '../config/app_feature_flags.dart';
import '../l10n/app_texts.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({
    super.key,
    this.motivationMediaAvailable = AppFeatureFlags.motivationMediaAvailable,
  });

  final bool motivationMediaAvailable;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context).userGuide;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(texts.title)),
      body: ListView(
        key: const ValueKey('userGuideListView'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: [
          Card(
            color: AppColors.surfaceWarm,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: AppRadius.pill,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    texts.introTitle,
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    texts.subtitle,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    texts.introBody,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _GuideSectionCard(
            icon: Icons.directions_car_filled_rounded,
            title: texts.whatIsTimeyRiderTitle,
            items: texts.whatIsTimeyRiderItems,
            accentColor: AppColors.surfaceBlue,
          ),
          _GuideSectionCard(
            icon: Icons.route_rounded,
            title: texts.startMissionTitle,
            items: texts.startMissionItems,
            accentColor: AppColors.surfaceMint,
          ),
          _GuideSectionCard(
            icon: Icons.assistant_photo_rounded,
            title: texts.courseMarkersTitle,
            items: texts.courseMarkersItems,
            accentColor: AppColors.surfaceYellow,
          ),
          if (motivationMediaAvailable)
            _GuideSectionCard(
              icon: Icons.ondemand_video_rounded,
              title: texts.motivationTitle,
              items: texts.motivationItems,
              accentColor: AppColors.surfacePink,
            ),
          _GuideSectionCard(
            icon: Icons.emoji_events_rounded,
            title: texts.completionTitle,
            items: texts.completionItems,
            accentColor: AppColors.primarySoft,
          ),
          _GuideSectionCard(
            icon: Icons.history_rounded,
            title: texts.historyRewardsTitle,
            items: texts.historyRewardsItems,
            accentColor: AppColors.surfaceBlue,
          ),
          _GuideSectionCard(
            icon: Icons.exit_to_app_rounded,
            title: texts.exitResumeTitle,
            items: texts.exitResumeItems,
            accentColor: AppColors.surfaceMint,
          ),
          _GuideSectionCard(
            icon: Icons.volunteer_activism_rounded,
            title: texts.guardianTipsTitle,
            items: texts.guardianTipsItems,
            accentColor: AppColors.surfaceYellow,
          ),
        ],
      ),
    );
  }
}

class _GuideSectionCard extends StatelessWidget {
  const _GuideSectionCard({
    required this.icon,
    required this.title,
    required this.items,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final List<String> items;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        color: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: accentColor,
                    foregroundColor: AppColors.brown700,
                    child: Icon(icon),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textStrong,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              for (final item in items) _GuideBulletRow(text: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideBulletRow extends StatelessWidget {
  const _GuideBulletRow({required this.text});

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
