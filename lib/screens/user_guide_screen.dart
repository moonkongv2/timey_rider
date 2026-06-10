import 'package:flutter/material.dart';

import '../l10n/app_texts.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

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
            icon: Icons.route_rounded,
            title: texts.basicFlowTitle,
          ),
          _GuideSectionCard(
            icon: Icons.restaurant_menu_rounded,
            title: texts.ingredientsTitle,
          ),
          _GuideSectionCard(
            icon: Icons.ondemand_video_rounded,
            title: texts.motivationTitle,
          ),
          _GuideSectionCard(
            icon: Icons.emoji_events_rounded,
            title: texts.resultRewardsTitle,
          ),
          _GuideSectionCard(
            icon: Icons.history_rounded,
            title: texts.historyTitle,
          ),
          _GuideSectionCard(
            icon: Icons.volunteer_activism_rounded,
            title: texts.guardianTipsTitle,
          ),
        ],
      ),
    );
  }
}

class _GuideSectionCard extends StatelessWidget {
  const _GuideSectionCard({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        color: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.surfaceYellow,
            foregroundColor: AppColors.brown700,
            child: Icon(icon),
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textStrong,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
