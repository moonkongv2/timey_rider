import 'package:flutter/widgets.dart';

import 'en/common.dart';
import 'en/avatar_setup.dart';
import 'en/home.dart';
import 'en/meal_history.dart';
import 'en/result.dart';
import 'en/rewards.dart';
import 'en/settings.dart';
import 'en/timer.dart';
import 'ko/common.dart';
import 'ko/avatar_setup.dart';
import 'ko/home.dart';
import 'ko/meal_history.dart';
import 'ko/result.dart';
import 'ko/rewards.dart';
import 'ko/settings.dart';
import 'ko/timer.dart';
import 'text_sets.dart';

class AppTextBundle {
  const AppTextBundle({
    required this.avatarSetup,
    required this.common,
    required this.home,
    required this.mealHistory,
    required this.result,
    required this.rewards,
    required this.settings,
    required this.timer,
  });

  final AvatarSetupTextSet avatarSetup;
  final CommonTextSet common;
  final HomeTextSet home;
  final MealHistoryTextSet mealHistory;
  final ResultTextSet result;
  final RewardTextSet rewards;
  final SettingsTextSet settings;
  final TimerTextSet timer;
}

abstract final class AppTexts {
  static const supportedLocales = [Locale('en'), Locale('ko')];

  static const ko = AppTextBundle(
    avatarSetup: AvatarSetupTexts(),
    common: CommonTexts(),
    home: HomeTexts(),
    mealHistory: MealHistoryTexts(),
    result: ResultTexts(),
    rewards: RewardTexts(),
    settings: SettingsTexts(),
    timer: TimerTexts(),
  );

  static const en = AppTextBundle(
    avatarSetup: EnAvatarSetupTexts(),
    common: EnCommonTexts(),
    home: EnHomeTexts(),
    mealHistory: EnMealHistoryTexts(),
    result: EnResultTexts(),
    rewards: EnRewardTexts(),
    settings: EnSettingsTexts(),
    timer: EnTimerTexts(),
  );

  static AppTextBundle of(BuildContext context) {
    return forLocale(Localizations.localeOf(context));
  }

  static AppTextBundle forLocale(Locale locale) {
    return locale.languageCode == 'ko' ? ko : en;
  }
}
