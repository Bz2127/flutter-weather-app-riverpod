// lib/state/weather_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/weather_model.dart';
import '../models/forecast_model.dart';

class WeatherState {
  final WeatherModel? weather;
  final List<ForecastDay> forecast;
  final bool isLoading;
  final String? error;

  final Object? exception;

  WeatherState({
    this.weather,
    this.forecast = const [],
    this.isLoading = false,
    this.error,
    this.exception,
  });

  WeatherState copyWith({
    WeatherModel? weather,
    List<ForecastDay>? forecast,
    bool? isLoading,
    String? error,
    Object? exception,
  }) {
    return WeatherState(
      weather: weather ?? this.weather,
      forecast: forecast ?? this.forecast,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      exception: exception,
    );
  }
}
