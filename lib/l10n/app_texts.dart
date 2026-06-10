import 'package:flutter/widgets.dart';

import 'en/common.dart';
import 'en/avatar_setup.dart';
import 'en/home.dart';
import 'en/meal_ingredient.dart';
import 'en/meal_history.dart';
import 'en/result.dart';
import 'en/rewards.dart';
import 'en/settings.dart';
import 'en/timer.dart';
import 'en/user_guide.dart';
import 'ko/common.dart';
import 'ko/avatar_setup.dart';
import 'ko/home.dart';
import 'ko/meal_ingredient.dart';
import 'ko/meal_history.dart';
import 'ko/result.dart';
import 'ko/rewards.dart';
import 'ko/settings.dart';
import 'ko/timer.dart';
import 'ko/user_guide.dart';
import 'text_sets.dart';

class AppTextBundle {
  const AppTextBundle({
    required this.avatarSetup,
    required this.common,
    required this.home,
    required this.mealIngredient,
    required this.mealHistory,
    required this.result,
    required this.rewards,
    required this.settings,
    required this.timer,
    required this.userGuide,
  });

  final AvatarSetupTextSet avatarSetup;
  final CommonTextSet common;
  final HomeTextSet home;
  final MealIngredientTextSet mealIngredient;
  final MealHistoryTextSet mealHistory;
  final ResultTextSet result;
  final RewardTextSet rewards;
  final SettingsTextSet settings;
  final TimerTextSet timer;
  final UserGuideTextSet userGuide;
}

abstract final class AppTexts {
  static const supportedLocales = [Locale('en'), Locale('ko')];

  static const ko = AppTextBundle(
    avatarSetup: AvatarSetupTexts(),
    common: CommonTexts(),
    home: HomeTexts(),
    mealIngredient: MealIngredientTexts(),
    mealHistory: MealHistoryTexts(),
    result: ResultTexts(),
    rewards: RewardTexts(),
    settings: SettingsTexts(),
    timer: TimerTexts(),
    userGuide: UserGuideTexts(),
  );

  static const en = AppTextBundle(
    avatarSetup: EnAvatarSetupTexts(),
    common: EnCommonTexts(),
    home: EnHomeTexts(),
    mealIngredient: EnMealIngredientTexts(),
    mealHistory: EnMealHistoryTexts(),
    result: EnResultTexts(),
    rewards: EnRewardTexts(),
    settings: EnSettingsTexts(),
    timer: EnTimerTexts(),
    userGuide: EnUserGuideTexts(),
  );

  static AppTextBundle of(BuildContext context) {
    return forLocale(Localizations.localeOf(context));
  }

  static AppTextBundle forLocale(Locale locale) {
    return locale.languageCode == 'ko' ? ko : en;
  }
}
