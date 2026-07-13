// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EsOnboardingTexts implements OnboardingTextSet {
  const EsOnboardingTexts();

  String get skipButton => 'Omitir';

  String pageIndicatorLabel(int currentPage, int totalPages) {
    return 'Onboarding card $currentPage of $totalPages';
  }

  List<OnboardingCardText> get cards => const [
    OnboardingCardText(
      title: 'Los niños aún no pueden ver el tiempo',
      body:
          '“Cinco minutos más”, “Es hora de parar”,\n“Vamos a prepararnos”.\nLas rutinas diarias pueden parecer un pequeño tira y afloja.',
      note:
          'Puede que tu peque no intente retrasarse a propósito.\nTodavía está aprendiendo a sentir el tiempo.',
      ctaLabel: 'Empezar juntos',
    ),
    OnboardingCardText(
      title: 'Convierte las rutinas en pequeños paseos',
      body:
          'Cepillarse, leer, ordenar y jugar\npueden comenzar como divertidas misiones.',
      note:
          'En lugar de solo escuchar la hora, tu peque ve\ncómo avanza el vehículo elegido por la ruta.',
      ctaLabel: 'Siguiente',
    ),
    OnboardingCardText(
      title: '¿Qué vehículo elegimos hoy?',
      body:
          'Una moto, un tiburón, un T-rex y muchos más\npueden ser los compañeros de misión de hoy.',
      note: 'Añade la cara de tu peque para que sienta\nque el paseo es su propia historia.',
      ctaLabel: 'Elegir un vehículo',
    ),
    OnboardingCardText(
      title: 'Pequeñas marcas muestran cada paso',
      body:
          'Las imágenes que acompañan la misión\naparecen una a una a lo largo de la ruta.',
      note:
          'No son para evaluar. Son pistas visuales\nque ayudan a seguir la rutina.',
      ctaLabel: 'Me parece bien',
    ),
    OnboardingCardText(
      title: 'Lo más importante es intentarlo hoy',
      body:
          'Tanto si terminó rápido, como si necesitó más tiempo,\ncada resultado se guarda sin juzgar.',
      note:
          'Las pegatinas son pequeños regalos de ánimo.\nElogia su esfuerzo antes de darle la recompensa.',
      ctaLabel: 'Empezar Timey',
    ),
  ];
}
