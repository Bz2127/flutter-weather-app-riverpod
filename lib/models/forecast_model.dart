// lib/models/forecast_model.dart

class ForecastDay {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final String mainCondition;

  ForecastDay({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.mainCondition,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    final mainData = json['main'] as Map<String, dynamic>;
    final weatherArray = json['weather'] as List<dynamic>;

    return ForecastDay(
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      tempMax: (mainData['temp_max'] as num).toDouble(),
      tempMin: (mainData['temp_min'] as num).toDouble(),
      mainCondition: (weatherArray[0]['main'] as String),
    );
  }
}
