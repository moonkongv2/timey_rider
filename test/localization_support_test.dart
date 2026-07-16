import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/catalogs/avatar_prompt_catalog.dart';
import 'package:timey_rider/catalogs/vehicle_catalog.dart';
import 'package:timey_rider/l10n/app_texts.dart';
import 'package:timey_rider/models/activity_completion_status.dart';

void main() {
  test(
    'supportedLocales includes Japanese, Spanish, and Brazilian Portuguese',
    () {
      expect(AppTexts.supportedLocales, contains(const Locale('ja')));
      expect(AppTexts.supportedLocales, contains(const Locale('es')));
      expect(AppTexts.supportedLocales, contains(const Locale('pt', 'BR')));
    },
  );

  test('AppTexts.forLocale routes supported and fallback locales', () {
    expect(AppTexts.forLocale(const Locale('ja')).common.apply, '適用');
    expect(AppTexts.forLocale(const Locale('es')).common.apply, 'Aplicar');
    expect(
      AppTexts.forLocale(const Locale('pt', 'BR')).common.apply,
      'Aplicar',
    );
    expect(AppTexts.forLocale(const Locale('pt')).common.cancel, 'Cancelar');
    expect(AppTexts.forLocale(const Locale('fr')).common.apply, 'Apply');
  });

  test('Spanish and Portuguese child name setup copy is localized', () {
    const englishCopy = [
      'Who is riding today?',
      "Enter your child's name first.",
      "Enter your child's name.",
    ];
    final localizedCopies = [
      AppTexts.forLocale(const Locale('es')).settings.childNameSetupTitle,
      AppTexts.forLocale(const Locale('es')).settings.childNameSetupSubtitle,
      AppTexts.forLocale(const Locale('es')).settings.childNameRequiredMessage,
      AppTexts.forLocale(const Locale('pt', 'BR')).settings.childNameSetupTitle,
      AppTexts.forLocale(
        const Locale('pt', 'BR'),
      ).settings.childNameSetupSubtitle,
      AppTexts.forLocale(
        const Locale('pt', 'BR'),
      ).settings.childNameRequiredMessage,
    ];

    for (final copy in localizedCopies) {
      expect(englishCopy, isNot(contains(copy)));
    }
    expect(
      AppTexts.forLocale(const Locale('es')).settings.childNameSetupTitle,
      '¿Quién va a montar hoy?',
    );
    expect(
      AppTexts.forLocale(const Locale('pt', 'BR')).settings.childNameSetupTitle,
      'Quem vai pilotar hoje?',
    );
  });

  test('Settings copy is localized for Spanish Portuguese and Japanese', () {
    const englishCopy = [
      'Show remaining time',
      'Use custom video interval',
      'Motivation video interval',
      'Motivation video guide',
      'They do not decide stickers or results.',
      'Short timers may skip some milestones so clips do not overlap.',
      'Turns sounds during the timer on or off.',
      'Applies while the timer is running.',
      'Auto previews and uses picture markers that fit the activity. Only manually chosen picture markers are saved to activity records.',
      'Rider image settings',
      'Using default image',
      'Using custom rider',
      'Open rider image settings',
      'Locked vehicles available',
      'Vehicle pack unlocked',
      'The vehicle pack unlocks all locked vehicles. Purchase and restore options open after a parent check.',
      'View vehicle pack',
    ];
    final localizedCopies = [
      for (final locale in const [
        Locale('es'),
        Locale('pt', 'BR'),
        Locale('ja'),
      ]) ...[
        AppTexts.forLocale(locale).settings.showRemainingTime,
        AppTexts.forLocale(locale).settings.motivationVideoCustomInterval,
        AppTexts.forLocale(locale).settings.motivationVideoInterval,
        AppTexts.forLocale(locale).settings.motivationVideoHelpTitle,
        ...AppTexts.forLocale(
          locale,
        ).settings.motivationVideoHelpBodyParagraphs,
        ...AppTexts.forLocale(locale).settings.motivationVideoHelpBulletItems,
        AppTexts.forLocale(locale).settings.savedOnlySubtitle,
        AppTexts.forLocale(locale).settings.keepScreenAwakeSubtitle,
        AppTexts.forLocale(locale).settings.markerModeDescription,
        AppTexts.forLocale(locale).settings.avatarSettingsTitle,
        AppTexts.forLocale(locale).settings.avatarDefaultState,
        AppTexts.forLocale(locale).settings.avatarCustomState,
        AppTexts.forLocale(locale).settings.avatarSettingsButton,
        AppTexts.forLocale(locale).settings.vehiclePackLockedState,
        AppTexts.forLocale(locale).settings.vehiclePackUnlockedState,
        AppTexts.forLocale(locale).settings.vehiclePackSettingsDescription,
        AppTexts.forLocale(locale).settings.vehiclePackManageButton,
      ],
    ];

    for (final copy in localizedCopies) {
      expect(englishCopy, isNot(contains(copy)));
    }
    expect(
      AppTexts.forLocale(const Locale('es')).settings.showRemainingTime,
      'Mostrar tiempo restante',
    );
    expect(
      AppTexts.forLocale(
        const Locale('es'),
      ).settings.motivationVideoCustomInterval,
      'Intervalo de video personalizado',
    );
    expect(
      AppTexts.forLocale(const Locale('pt', 'BR')).settings.showRemainingTime,
      'Mostrar tempo restante',
    );
    expect(
      AppTexts.forLocale(
        const Locale('pt', 'BR'),
      ).settings.motivationVideoCustomInterval,
      'Intervalo de vídeo personalizado',
    );
    expect(
      AppTexts.forLocale(const Locale('ja')).settings.showRemainingTime,
      '残り時間を表示',
    );
  });

  test('Marker and activity history help copy is localized', () {
    const englishCopy = [
      'They do not decide completion or sticker results.',
      'Auto: the app previews and uses picture markers that fit the selected activity.',
      'Choose: pick up to 5 picture markers before starting.',
      'Only manually chosen picture markers are saved to activity records.',
      '1/5 selected',
      'Activity history shows the mission, target time, actual time, completion status, and earned stickers.',
      'Manually chosen picture markers appear when they were saved with the activity.',
      'Auto-selected markers appear on the road only and are not saved in history.',
      'Records without a sticker show No sticker this time.',
      'Only the record will be removed. Earned stickers will stay.',
      'Over +5 min',
    ];
    final localizedCopies = [
      for (final locale in const [
        Locale('es'),
        Locale('pt', 'BR'),
        Locale('ja'),
      ]) ...[
        ...AppTexts.forLocale(locale).activityMarker.helpBodyParagraphs,
        ...AppTexts.forLocale(locale).activityMarker.helpBulletItems,
        AppTexts.forLocale(locale).activityMarker.selectedCount(1, 5),
        ...AppTexts.forLocale(locale).activityHistory.helpBulletItems,
        AppTexts.forLocale(locale).activityHistory.deleteRecordDialogBody,
        AppTexts.forLocale(locale).activityHistory.overrunTime('5 min'),
      ],
    ];

    for (final copy in localizedCopies) {
      expect(englishCopy, isNot(contains(copy)));
    }
    expect(
      AppTexts.forLocale(const Locale('es')).activityMarker.selectedCount(1, 5),
      '1/5 seleccionados',
    );
    expect(
      AppTexts.forLocale(
        const Locale('pt', 'BR'),
      ).activityHistory.deleteRecordDialogBody,
      'Apenas o registro será removido. Os adesivos ganhos serão mantidos.',
    );
    expect(
      AppTexts.forLocale(const Locale('ja')).activityHistory.overrunTime('5分'),
      '超過 +5分',
    );
  });

  test('Result help copy is localized for Spanish Portuguese and Japanese', () {
    const englishCopy = [
      'View parent tips for a completed activity',
      "What you check together is saved in today's activity record.",
      'After the timer ends, check the mission together and save the record.',
      'If the activity was not wrapped up, keep the record as guidance for the next try.',
      'If a reward goal is active, the sticker can fill one goal slot.',
      'A time-ended activity is still recorded as part of the routine.',
      'An incomplete result is a planning clue, not a punishment.',
      'The timer reached the end and the activity was recorded.',
      'This is a routine transition, not a pass-or-fail result.',
      'This activity needed a little more time today.',
      'Use the record to adjust the next try.',
      'I liked doing this activity with you today.',
      'Time is up. Let\'s decide the next step.',
      'Try to avoid',
      'Good job being fast.',
      'You failed.',
      'If the activity flow felt short, try adjusting the timer next time.',
      'Use the record to understand routine patterns, not to grade the child.',
    ];
    const statuses = [
      ActivityCompletionStatus.completedAtEnd,
      ActivityCompletionStatus.timeEnded,
      ActivityCompletionStatus.needsMoreTime,
    ];
    final localizedCopies = [
      for (final locale in const [
        Locale('es'),
        Locale('pt', 'BR'),
        Locale('ja'),
      ])
        for (final status in statuses) ...[
          AppTexts.forLocale(locale).result.parentTipSemanticLabel(status),
          ...AppTexts.forLocale(locale).result.helpBodyParagraphs(status),
          ...AppTexts.forLocale(locale).result.helpBulletItems(status),
          ...AppTexts.forLocale(locale).result.resultHelpMeaningItems(status),
          ...AppTexts.forLocale(locale).result.resultHelpSayItems(status),
          AppTexts.forLocale(locale).result.resultHelpAvoidTitle(status),
          ...AppTexts.forLocale(locale).result.resultHelpAvoidItems(status),
          ...AppTexts.forLocale(
            locale,
          ).result.resultHelpNextCourseItems(status),
          AppTexts.forLocale(
            locale,
          ).result.primaryMessage(status, vehicleId: VehicleCatalog.bus.id),
        ],
    ];

    for (final copy in localizedCopies) {
      expect(englishCopy, isNot(contains(copy)));
    }
    expect(
      AppTexts.forLocale(
        const Locale('es'),
      ).result.resultHelpAvoidTitle(ActivityCompletionStatus.completedAtEnd),
      'Intenta evitar',
    );
    expect(
      AppTexts.forLocale(const Locale('pt', 'BR')).result.primaryMessage(
        ActivityCompletionStatus.needsMoreTime,
        vehicleId: VehicleCatalog.bus.id,
      ),
      'Esta atividade precisou de um pouco mais de tempo hoje.',
    );
    expect(
      AppTexts.forLocale(
        const Locale('ja'),
      ).result.parentTipSemanticLabel(ActivityCompletionStatus.timeEnded),
      '時間終了した活動の保護者向けヒントを見る',
    );
  });

  test('VehicleDefinition.labelForLanguage returns new locale labels', () {
    final vehicle = VehicleCatalog.motorcycle;

    expect(vehicle.labelForLanguage('ko'), '오토바이');
    expect(vehicle.labelForLanguage('ja'), 'バイク');
    expect(vehicle.labelForLanguage('es'), 'Moto');
    expect(vehicle.labelForLanguage('pt'), 'Moto');
    expect(vehicle.labelForLanguage('fr'), 'Motorcycle');
  });

  test(
    'AvatarPromptCatalog returns localized prompts with vehicle concepts',
    () {
      final vehicle = VehicleCatalog.fireTruck;

      final jaPrompt = AvatarPromptCatalog.promptForVehicle(vehicle, 'ja');
      final esPrompt = AvatarPromptCatalog.promptForVehicle(vehicle, 'es');
      final ptPrompt = AvatarPromptCatalog.promptForVehicle(vehicle, 'pt');
      final fallbackPrompt = AvatarPromptCatalog.promptForVehicle(
        vehicle,
        'fr',
      );

      expect(jaPrompt, contains('消防士'));
      expect(jaPrompt, isNot(contains('Use the attached child photo')));
      expect(esPrompt, contains('bombero'));
      expect(esPrompt, isNot(contains('Use the attached child photo')));
      expect(ptPrompt, contains('bombeiro'));
      expect(ptPrompt, isNot(contains('Use the attached child photo')));
      expect(fallbackPrompt, contains('firefighter'));
      expect(fallbackPrompt, contains('Use the attached child photo'));
    },
  );
}
