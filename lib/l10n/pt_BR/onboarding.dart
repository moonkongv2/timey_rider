// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class PtBrOnboardingTexts implements OnboardingTextSet {
  const PtBrOnboardingTexts();

  String get skipButton => 'Pular';

  String pageIndicatorLabel(int currentPage, int totalPages) {
    return 'Onboarding card $currentPage of $totalPages';
  }

  List<OnboardingCardText> get cards => const [
    OnboardingCardText(
      title: 'As crianças ainda não conseguem ver o tempo',
      body:
          '“Só mais cinco minutinhos”, “Hora de parar”,\n“Vamos nos arrumar”.\nAs rotinas diárias podem parecer um pequeno cabo de guerra.',
      note:
          'Pode ser que seu filho(a) não esteja enrolando de propósito.\nEle ainda está aprendendo como o tempo funciona.',
      ctaLabel: 'Começar juntos',
    ),
    OnboardingCardText(
      title: 'Transforme rotinas em pequenos passeios',
      body:
          'Escovar os dentes, ler, arrumar e brincar\npodem virar missões divertidas com o Timey Rider.',
      note:
          'Em vez de apenas ouvir a hora, seu filho(a) vê\num veículo escolhido se movendo pelo caminho.',
      ctaLabel: 'Próximo',
    ),
    OnboardingCardText(
      title: 'Qual veículo vamos usar hoje?',
      body:
          'Uma moto, um tubarão, um T-rex e muito mais\npodem ser os parceiros de missão de hoje.',
      note: 'Adicione o rostinho do seu filho(a) para que ele sinta\nque o passeio é sua própria historinha.',
      ctaLabel: 'Escolher um veículo',
    ),
    OnboardingCardText(
      title: 'Pequenas marcas mostram cada passo',
      body:
          'Pequenas imagens que combinam com a missão\naparecem uma a uma pelo caminho.',
      note:
          'As marcas não são notas. Elas são dicas visuais\nque ajudam a seguir a rotina.',
      ctaLabel: 'Tudo bem',
    ),
    OnboardingCardText(
      title: 'O mais importante hoje é tentar',
      body:
          'Terminou rápido ou precisou de mais tempo?\nCada resultado é salvo sem julgamentos.',
      note:
          'Os adesivos são pequenos presentes de incentivo.\nElogie o esforço antes da recompensa.',
      ctaLabel: 'Começar Timey',
    ),
  ];
}
