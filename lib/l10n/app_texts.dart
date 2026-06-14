import 'package:flutter/widgets.dart';

import 'en/common.dart';
import 'en/avatar_setup.dart';
import 'en/home.dart';
import 'en/activity_marker.dart';
import 'en/activity_history.dart';
import 'en/onboarding.dart';
import 'en/result.dart';
import 'en/rewards.dart';
import 'en/settings.dart';
import 'en/timer.dart';
import 'en/user_guide.dart';
import 'ko/common.dart';
import 'ko/avatar_setup.dart';
import 'ko/home.dart';
import 'ko/activity_marker.dart';
import 'ko/activity_history.dart';
import 'ko/onboarding.dart';
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
    required this.activityMarker,
    required this.activityHistory,
    required this.onboarding,
    required this.result,
    required this.rewards,
    required this.settings,
    required this.timer,
    required this.userGuide,
  });

  final AvatarSetupTextSet avatarSetup;
  final CommonTextSet common;
  final HomeTextSet home;
  final ActivityMarkerTextSet activityMarker;
  final ActivityHistoryTextSet activityHistory;
  final OnboardingTextSet onboarding;
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
    activityMarker: ActivityMarkerTexts(),
    activityHistory: ActivityHistoryTexts(),
    onboarding: OnboardingTexts(),
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
    activityMarker: EnActivityMarkerTexts(),
    activityHistory: EnActivityHistoryTexts(),
    onboarding: EnOnboardingTexts(),
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
