// lib/state/weather_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/weather_repository.dart';
import 'weather_state.dart';

class WeatherNotifier extends StateNotifier<WeatherState> {
  final WeatherRepository _repository;
  // State for Unit Preference (separate from main weather state)
  bool _isCelsius = true;
  static const String _unitKey = 'isCelsiusUnit';

  WeatherNotifier(this._repository) : super(WeatherState()) {
    _loadUnitPreference();
    fetchCurrentLocationWeather();
  }

  bool get isCelsius => _isCelsius;

  Future<void> _loadUnitPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isCelsius = prefs.getBool(_unitKey) ?? true;
  }

  Future<void> toggleUnit() async {
    final prefs = await SharedPreferences.getInstance();
    _isCelsius = !_isCelsius;
    await prefs.setBool(_unitKey, _isCelsius);

    // Force a state update to trigger UI rebuild and refresh temperatures
    state = state.copyWith(
      weather: state.weather,
      forecast: state.forecast,
      isLoading: state.isLoading,
    );
  }

  Future<void> _fetchWeatherAndForecast(double lat, double lon) async {
    try {
      // Clear all errors/exceptions on starting a new fetch
      state = state.copyWith(isLoading: true, error: null, exception: null);

      final weather = await _repository.fetchWeatherByCoords(lat, lon);
      final forecast = await _repository.fetchForecastByCoords(lat, lon);

      state = state.copyWith(
        weather: weather,
        forecast: forecast,
        isLoading: false,
        error: null,
        exception: null, // Clear exception on success
      );
    } catch (e) {
      // CRITICAL: Store the exception object for detailed UI error handling
      String message = 'An unexpected error occurred.';
      if (e is WeatherException) {
        message = e.message;
      }

      state = state.copyWith(
        error: "Weather Fetch Failed: $message",
        exception: e, // IMPORTANT: Pass the exception object
        isLoading: false,
      );
    }
  }

  Future<void> fetchCurrentLocationWeather() async {
    try {
      state = state.copyWith(isLoading: true, error: null, exception: null);

      final position = await _repository.getCurrentPosition();
      // Delegate to the unified fetch method
      await _fetchWeatherAndForecast(position.latitude, position.longitude);
    } catch (e) {
      // Catch LocationPermissionException from repository
      String message = 'Failed to get current location.';
      if (e is LocationPermissionException) {
        message = e.message;
      }

      state = state.copyWith(
        error: message,
        exception: e, // IMPORTANT: Pass the exception object
        isLoading: false,
      );
    }
  }

  Future<void> fetchWeatherByCity(String cityName) async {
    try {
      state = state.copyWith(isLoading: true, error: null, exception: null);

      // Fetch the main weather data (this can throw CityNotFoundException)
      final weather = await _repository.fetchWeatherByCity(cityName);

      // Use coordinates to get the forecast
      await _fetchWeatherAndForecast(weather.latitude, weather.longitude);
    } catch (e) {
      // Catch exceptions from fetchWeatherByCity (e.g., CityNotFoundException)
      String message = "Could not fetch weather for '$cityName'.";
      if (e is WeatherException) {
        message = e.message;
      }

      state = state.copyWith(
        error: message,
        exception: e, // IMPORTANT: Pass the exception object
        isLoading: false,
      );
    }
  }
}

final weatherNotifierProvider =
    StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  return WeatherNotifier(ref.read(weatherRepositoryProvider));
});

final weatherRepositoryProvider = Provider((ref) => WeatherRepository());
