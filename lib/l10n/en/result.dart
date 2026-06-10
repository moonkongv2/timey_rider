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

  String helpButtonLabel(bool mealCompleted) =>
      mealCompleted ? 'Success and sticker guide' : 'Incomplete record guide';

  String helpTitle(bool mealCompleted) =>
      mealCompleted ? 'Success and stickers' : 'Incomplete records';

  List<String> helpBodyParagraphs(bool mealCompleted) => mealCompleted
      ? const [
          'When the guardian confirms the meal is finished, it is saved as a success.',
        ]
      : const [
          'If the timer arrives first and the meal is not finished, it is saved as incomplete.',
        ];

  List<String> helpBulletItems(bool mealCompleted) => mealCompleted
      ? const [
          'A successful meal earns 1 random success sticker.',
          'If reward goals are active, the success sticker can fill a goal slot.',
        ]
      : const [
          'Incomplete meals stay in meal history, but no sticker is awarded.',
          'An incomplete result is a record for the next try, not a punishment.',
        ];
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
