// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnResultTexts implements ResultTextSet {
  const EnResultTexts();

  String get rewardLoading => 'Getting your reward ready...';
  String get recordSaved => "Today's record is saved.";

  String title(bool mealCompleted) =>
      mealCompleted ? 'Ride complete!' : 'Almost there!';

  String primaryMessage(bool mealCompleted, {String? vehicleId}) =>
      mealCompleted
      ? 'You finished today\'s mealtime ride.'
      : _failedPrimaryMessagesByVehicle[vehicleId] ??
            'The motorcycle passed by...';

  String secondaryMessage(bool mealCompleted) => mealCompleted
      ? 'You finished before the rider passed by and earned a reward!'
      : "Let's try again on the next ride.";
}

const _failedPrimaryMessagesByVehicle = {
  'motorcycle': 'The motorcycle passed by...',
  'fire_truck': 'The fire truck headed out...',
  'police_car': 'The police car passed by...',
  'excavator': 'The excavator moved on...',
  'airplane': 'The airplane flew away...',
  'bus': 'The bus pulled away...',
  'supercar': 'The supercar sped ahead...',
  'train': 'The train left first...',
  't_rex': 'The T-rex stomped by...',
  'shark': 'The shark swam away...',
  'brachio': 'The brachio walked on...',
  'pteranodon': 'The pteranodon flew away...',
};
