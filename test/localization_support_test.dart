import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/catalogs/avatar_prompt_catalog.dart';
import 'package:timey_rider/catalogs/vehicle_catalog.dart';
import 'package:timey_rider/l10n/app_texts.dart';

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
