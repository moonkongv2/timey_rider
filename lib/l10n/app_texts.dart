import 'package:flutter/widgets.dart';

import 'en/common.dart';
import 'en/avatar_setup.dart';
import 'en/home.dart';
import 'en/activity_marker.dart';
import 'en/activity_history.dart';
import 'en/onboarding.dart';
import 'en/purchase.dart';
import 'en/result.dart';
import 'en/rewards.dart';
import 'en/settings.dart';
import 'en/timer.dart';
import 'en/user_guide.dart';
import 'es/common.dart';
import 'es/avatar_setup.dart';
import 'es/home.dart';
import 'es/activity_marker.dart';
import 'es/activity_history.dart';
import 'es/onboarding.dart';
import 'es/purchase.dart';
import 'es/result.dart';
import 'es/rewards.dart';
import 'es/settings.dart';
import 'es/timer.dart';
import 'es/user_guide.dart';
import 'ja/common.dart';
import 'ja/avatar_setup.dart';
import 'ja/home.dart';
import 'ja/activity_marker.dart';
import 'ja/activity_history.dart';
import 'ja/onboarding.dart';
import 'ja/purchase.dart';
import 'ja/result.dart';
import 'ja/rewards.dart';
import 'ja/settings.dart';
import 'ja/timer.dart';
import 'ja/user_guide.dart';
import 'ko/common.dart';
import 'ko/avatar_setup.dart';
import 'ko/home.dart';
import 'ko/activity_marker.dart';
import 'ko/activity_history.dart';
import 'ko/onboarding.dart';
import 'ko/purchase.dart';
import 'ko/result.dart';
import 'ko/rewards.dart';
import 'ko/settings.dart';
import 'ko/timer.dart';
import 'ko/user_guide.dart';
import 'pt_BR/common.dart';
import 'pt_BR/avatar_setup.dart';
import 'pt_BR/home.dart';
import 'pt_BR/activity_marker.dart';
import 'pt_BR/activity_history.dart';
import 'pt_BR/onboarding.dart';
import 'pt_BR/purchase.dart';
import 'pt_BR/result.dart';
import 'pt_BR/rewards.dart';
import 'pt_BR/settings.dart';
import 'pt_BR/timer.dart';
import 'pt_BR/user_guide.dart';
import 'text_sets.dart';

class AppTextBundle {
  const AppTextBundle({
    required this.avatarSetup,
    required this.common,
    required this.home,
    required this.activityMarker,
    required this.activityHistory,
    required this.onboarding,
    required this.purchase,
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
  final PurchaseTextSet purchase;
  final ResultTextSet result;
  final RewardTextSet rewards;
  final SettingsTextSet settings;
  final TimerTextSet timer;
  final UserGuideTextSet userGuide;
}

abstract final class AppTexts {
  static const supportedLocales = [
    Locale('en'),
    Locale('ko'),
    Locale('ja'),
    Locale('es'),
    Locale('pt', 'BR'),
  ];

  static const ko = AppTextBundle(
    avatarSetup: AvatarSetupTexts(),
    common: CommonTexts(),
    home: HomeTexts(),
    activityMarker: ActivityMarkerTexts(),
    activityHistory: ActivityHistoryTexts(),
    onboarding: OnboardingTexts(),
    purchase: PurchaseTexts(),
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
    purchase: EnPurchaseTexts(),
    result: EnResultTexts(),
    rewards: EnRewardTexts(),
    settings: EnSettingsTexts(),
    timer: EnTimerTexts(),
    userGuide: EnUserGuideTexts(),
  );

  static const ja = AppTextBundle(
    avatarSetup: JaAvatarSetupTexts(),
    common: JaCommonTexts(),
    home: JaHomeTexts(),
    activityMarker: JaActivityMarkerTexts(),
    activityHistory: JaActivityHistoryTexts(),
    onboarding: JaOnboardingTexts(),
    purchase: JaPurchaseTexts(),
    result: JaResultTexts(),
    rewards: JaRewardTexts(),
    settings: JaSettingsTexts(),
    timer: JaTimerTexts(),
    userGuide: JaUserGuideTexts(),
  );

  static const es = AppTextBundle(
    avatarSetup: EsAvatarSetupTexts(),
    common: EsCommonTexts(),
    home: EsHomeTexts(),
    activityMarker: EsActivityMarkerTexts(),
    activityHistory: EsActivityHistoryTexts(),
    onboarding: EsOnboardingTexts(),
    purchase: EsPurchaseTexts(),
    result: EsResultTexts(),
    rewards: EsRewardTexts(),
    settings: EsSettingsTexts(),
    timer: EsTimerTexts(),
    userGuide: EsUserGuideTexts(),
  );

  static const ptBr = AppTextBundle(
    avatarSetup: PtBrAvatarSetupTexts(),
    common: PtBrCommonTexts(),
    home: PtBrHomeTexts(),
    activityMarker: PtBrActivityMarkerTexts(),
    activityHistory: PtBrActivityHistoryTexts(),
    onboarding: PtBrOnboardingTexts(),
    purchase: PtBrPurchaseTexts(),
    result: PtBrResultTexts(),
    rewards: PtBrRewardTexts(),
    settings: PtBrSettingsTexts(),
    timer: PtBrTimerTexts(),
    userGuide: PtBrUserGuideTexts(),
  );

  static AppTextBundle of(BuildContext context) {
    return forLocale(Localizations.localeOf(context));
  }

  static AppTextBundle forLocale(Locale locale) {
    return switch (locale.languageCode) {
      'ko' => ko,
      'ja' => ja,
      'es' => es,
      'pt' => ptBr,
      _ => en,
    };
  }
}
