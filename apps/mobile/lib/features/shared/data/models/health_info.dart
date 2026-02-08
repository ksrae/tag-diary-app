
class HealthInfo {
  final int steps;
  final int activeMinutes;
  final double calories;

  const HealthInfo({
    this.steps = 0, 
    this.activeMinutes = 0,
    this.calories = 0.0,
  });

  /// Returns true if no health data was fetched (all values are 0)
  bool get isEmpty => steps == 0 && activeMinutes == 0 && calories == 0.0;

  String get summary => '$steps걸음, ${activeMinutes}분 활동, ${calories.toInt()}kcal';
}
