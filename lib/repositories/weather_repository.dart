import 'dart:convert';
import 'dart:io'; // Import for SocketException to handle network loss
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import '../models/weather_model.dart';
import '../models/forecast_model.dart';

// ---------------------------------------------
// --- START: Custom Exception Classes for robust error handling ---
// ---------------------------------------------

/// Base class for all Weather-related exceptions.
abstract class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);

  // Override toString for better logging and display in the UI
  @override
  String toString() => message;
}

/// Thrown when the user's network connection is unavailable (catches SocketException).
class NetworkException extends WeatherException {
  NetworkException(super.message);
}

/// Thrown when the API returns a 404 error (e.g., city not found).
class CityNotFoundException extends WeatherException {
  CityNotFoundException(super.message);
}

/// Thrown for any other HTTP or API-related errors (e.g., 401, 500).
class ApiException extends WeatherException {
  ApiException(super.message);
}

/// Thrown when location permissions or services are an issue (GPS related).
class LocationPermissionException extends WeatherException {
  LocationPermissionException(super.message);
}

// ---------------------------------------------
// --- END: Custom Exception Classes ---
// ---------------------------------------------

class ApiConstants {
  // NOTE: Use your real API key here
  static const String apiKey = '15435ecf7a6a8c94eab288ca13eaf0c3';
  static const String baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String forecastBaseUrl =
      'https://api.openweathermap.org/data/2.5/forecast';
}

/// Repository class responsible for all data fetching (API and Location).
class WeatherRepository {
  // Use a generic HTTP client for easier testing later and resource management
  final http.Client _client = http.Client();

  // --- Start Utility Method to handle API calls with try/catch/status codes ---
  /// Makes an API request and handles common HTTP status codes and network errors.
  Future<Map<String, dynamic>> _makeApiRequest(Uri uri) async {
    try {
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        // Success
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // City Not Found
        throw CityNotFoundException(
            'The requested location could not be found.');
      } else {
        // General API Error (401, 500, etc.)
        throw ApiException('API failed with status: ${response.statusCode}');
      }
    } on SocketException {
      // Catches network-level errors like no internet connection
      throw NetworkException(
          'No internet connection. Please check your network.');
    } catch (e) {
      // Re-throw any exceptions, including our custom ones
      rethrow;
    }
  }
  // --- End Utility Method ---

  /// Fetches the current weather for a given geographical coordinate.
  Future<WeatherModel> fetchWeatherByCoords(
      double latitude, double longitude) async {
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}?lat=$latitude&lon=$longitude&appid=${ApiConstants.apiKey}&units=metric');

    final json = await _makeApiRequest(uri);
    return WeatherModel.fromJson(json);
  }

  /// Fetches the current weather for a given city name.
  Future<WeatherModel> fetchWeatherByCity(String cityName) async {
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}?q=$cityName&appid=${ApiConstants.apiKey}&units=metric');

    final json = await _makeApiRequest(uri);
    return WeatherModel.fromJson(json);
  }

  /// Fetches the 5-day/3-hour forecast for a given geographical coordinate.
  Future<List<ForecastDay>> fetchForecastByCoords(
      double latitude, double longitude) async {
    final uri = Uri.parse(
        '${ApiConstants.forecastBaseUrl}?lat=$latitude&lon=$longitude&appid=${ApiConstants.apiKey}&units=metric');

    final json = await _makeApiRequest(uri);

    final List<dynamic> forecastList = json['list'];

    // Filter the 3-hour forecast list to get roughly one forecast per day (noon forecast)
    final finalForecast = forecastList
        .map((item) => ForecastDay.fromJson(item))
        .where((forecast) => forecast.date.hour == 12)
        .toList();

    return finalForecast;
  }

  /// Retrieves the current geographical position of the device.
  Future<Position> getCurrentPosition() async {
    // Check if location services are enabled
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Note: This message is used in the UI to guide the user
      throw LocationPermissionException('Location services are disabled.');
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission if denied
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permission denied after request
        throw LocationPermissionException('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permission permanently denied
      throw LocationPermissionException(
          'Location permissions are permanently denied.');
    }

    // Permissions granted, get the current position
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
}
