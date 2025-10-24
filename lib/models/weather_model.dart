// lib/models/weather_model.dart

class WeatherModel {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final double windSpeed;
  final int humidity;
  final double latitude;
  final double longitude;

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.windSpeed,
    required this.humidity,
    required this.latitude,
    required this.longitude,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final mainData = json['main'] as Map<String, dynamic>;
    final weatherArray = json['weather'] as List<dynamic>;
    final windData = json['wind'] as Map<String, dynamic>;
    final coordData = json['coord'] as Map<String, dynamic>;

    return WeatherModel(
      cityName: json['name'] as String,
      temperature: (mainData['temp'] as num).toDouble(),
      mainCondition: (weatherArray[0]['main'] as String),
      windSpeed: (windData['speed'] as num).toDouble(),
      humidity: mainData['humidity'] as int,
      latitude: (coordData['lat'] as num).toDouble(),
      longitude: (coordData['lon'] as num).toDouble(),
    );
  }
}
