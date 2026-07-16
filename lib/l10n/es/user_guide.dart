// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EsUserGuideTexts implements UserGuideTextSet {
  const EsUserGuideTexts();

  String get title => 'Guía para adultos';
  String get subtitle =>
      'Revisa misiones, videos de ánimo y reglas de pegatinas.';
  String get introTitle => 'Guía para adultos';
  String get introBody =>
      'Usa esta guía para entender las misiones y reglas de Timey Rider antes de empezar. Está pensada para adultos que acompañan las rutinas diarias.';
  String get basicFlowTitle => startMissionTitle;
  String get markersTitle => courseMarkersTitle;
  String get motivationTitle => 'Videos de ánimo';
  String get resultRewardsTitle => completionTitle;
  String get historyTitle => historyRewardsTitle;
  String get guardianTipsTitle => 'Consejos para adultos';

  String get whatIsTimeyRiderTitle => '¿Qué es Timey Rider?';
  List<String> get whatIsTimeyRiderItems => const [
    'Timey Rider convierte rutinas como lavarse los dientes, leer, ordenar y jugar en pequeñas misiones de conducción.',
    'Los niños eligen un vehículo y siguen la ruta durante el tiempo configurado.',
    'Al final, cada actividad se registra según su modo de finalización: confirmar que terminó, tiempo terminado o revisión de un adulto.',
  ];

  String get startMissionTitle => 'Iniciar una misión';
  List<String> get startMissionItems => const [
    'Después de configurar el nombre del niño, elige un vehículo en la pantalla de inicio.',
    'Toca Crear temporizador en Inicio y elige misión, marcadores y duración.',
    'Usa Otro en el mismo flujo cuando la rutina no coincida con una misión predefinida.',
    'Pausar durante el temporizador no es un fracaso; la misión puede continuar cuando sea necesario.',
  ];

  String get courseMarkersTitle => 'Marcadores de ruta';
  List<String> get courseMarkersItems => const [
    'Los marcadores de ruta son pequeñas metas visuales durante una actividad.',
    'No: no se muestran marcadores en la ruta.',
    'Auto: la app muestra una vista previa y usa marcadores con imágenes que encajan con la actividad elegida.',
    'Elegir: selecciona hasta 5 marcadores con imágenes antes de empezar.',
    'Solo los marcadores elegidos manualmente se guardan en los registros de actividad.',
    'Los marcadores no determinan si la actividad se completa ni las pegatinas obtenidas.',
  ];

  List<String> get motivationItems => const [
    'Los videos de ánimo son clips breves de apoyo durante el temporizador.',
    'No determinan las pegatinas ni los resultados.',
    'En temporizadores cortos, algunos hitos pueden omitirse para evitar superposiciones.',
    'Los temporizadores más largos o el modo de intervalo personalizado pueden usar una programación por tiempo.',
    'Puedes elegir intervalos de 3, 5 o 10 minutos.',
    'Si el sonido está desactivado, el video puede aparecer sin reproducción de voz.',
  ];

  String get completionTitle => 'Finalización y pegatinas';
  List<String> get completionItems => const [
    'Cuando confirmas que la actividad terminó, se registra como completada.',
    'Cuando termine el temporizador, revisen juntos y elijan si reciben una pegatina.',
    'Elige Obtener pegatina para recibir la pegatina seleccionada.',
    'Elige Sin pegatina esta vez para guardar el registro y orientar la próxima elección de temporizador.',
    'El resultado que ve el niño mantiene un tono de próximo intento, sin palabras duras de fracaso.',
  ];

  String get historyRewardsTitle => 'Historial y metas de recompensa';
  List<String> get historyRewardsItems => const [
    'El historial muestra el nombre de la actividad, el tiempo objetivo, el tiempo real y el estado de finalización.',
    'Las pegatinas ganadas y los marcadores con imágenes elegidos manualmente pueden aparecer con el registro.',
    'Las pegatinas ganadas se reúnen en la pantalla de colección de pegatinas.',
    'Si hay metas de recompensa activas, las pegatinas recibidas pueden llenar espacios de la meta.',
  ];

  String get exitResumeTitle => 'Salir y continuar durante un temporizador';
  List<String> get exitResumeItems => const [
    'Usar atrás durante un temporizador pide confirmación primero.',
    'Pausar no es un fracaso; la misión puede continuar después de una pausa breve.',
    'Cuando se guarda un temporizador activo, la pantalla de inicio puede mostrar una tarjeta en progreso. Usa esa tarjeta para reanudar o cancelar cuando aparezca.',
  ];

  List<String> get guardianTipsItems => const [
    'Elogia primero el intento de rutina, no solo la pegatina.',
    'Configura la duración predeterminada a un ritmo que encaje con el niño, en vez de hacer que la meta sea demasiado corta.',
    'Trata los resultados que necesitan más tiempo como notas para el próximo intento, no como castigo.',
  ];
}
