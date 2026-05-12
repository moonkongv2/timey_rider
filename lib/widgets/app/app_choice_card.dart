import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

class AppChoiceCard extends StatelessWidget {
  const AppChoiceCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.semanticLabel,
    this.backgroundColor = AppColors.white,
    this.selectedColor = AppColors.primarySoft,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticLabel;
  final Color backgroundColor;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final borderColor = selected ? AppColors.primarySoft : AppColors.creamDark;
    final contentColor = selected ? AppColors.brown900 : AppColors.brown700;

    return Semantics(
      label: semanticLabel ?? title,
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: AppMotion.normal,
        curve: AppMotion.curve,
        decoration: BoxDecoration(
          color: selected ? selectedColor : backgroundColor,
          borderRadius: AppRadius.card,
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
          boxShadow: selected ? AppShadows.buttonSoft : AppShadows.surface,
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: AppRadius.card,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            color: contentColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            subtitle!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.brown500,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
