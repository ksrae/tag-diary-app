
class HealthInfo {
  final int steps;
  final int activeMinutes;
  final double calories;

  const HealthInfo({
    this.steps = 0, 
    this.activeMinutes = 0,
    this.calories = 0.0,
  });

  String get summary => '$steps걸음, ${activeMinutes}분 활동, ${calories.toInt()}kcal';
}
