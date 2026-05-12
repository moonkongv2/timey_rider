import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  static final surface = [
    BoxShadow(
      color: AppColors.brown700.withValues(alpha: 0.045),
      blurRadius: 12,
      offset: const Offset(0, 5),
    ),
  ];

  static final hero = [
    BoxShadow(
      color: AppColors.orangeDeep.withValues(alpha: 0.11),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
    BoxShadow(
      color: AppColors.brown700.withValues(alpha: 0.045),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static final floating = [
    BoxShadow(
      color: AppColors.brown700.withValues(alpha: 0.10),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static final buttonPrimary = [
    BoxShadow(
      color: AppColors.orangeDeep.withValues(alpha: 0.18),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static final buttonSoft = [
    BoxShadow(
      color: AppColors.brown700.withValues(alpha: 0.055),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get soft => surface;
  static List<BoxShadow> get elevated => hero;
  static List<BoxShadow> get button => buttonPrimary;
}
