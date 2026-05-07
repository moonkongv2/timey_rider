// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnResultTexts implements ResultTextSet {
  const EnResultTexts();

  String get rewardLoading => 'Getting your reward ready...';
  String get recordSaved => "Today's record is saved.";

  String title(bool mealCompleted) =>
      mealCompleted ? 'Ride complete!' : 'Almost there!';

  String primaryMessage(bool mealCompleted) => mealCompleted
      ? 'You finished today\'s mealtime ride.'
      : 'The rider passed by...';

  String secondaryMessage(bool mealCompleted) => mealCompleted
      ? 'You finished before the rider passed by and earned a reward!'
      : "Let's try again on the next ride.";
}
