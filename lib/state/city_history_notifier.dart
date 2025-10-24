// lib/state/city_history_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CityHistoryNotifier extends StateNotifier<List<String>> {
  static const String _historyKey = 'cityHistory';

  CityHistoryNotifier() : super([]) {
    _loadCityHistory();
  }

  Future<void> _loadCityHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // Set the initial state to the loaded list
    state = prefs.getStringList(_historyKey) ?? [];
  }

  Future<void> saveCityToHistory(String cityName) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedCity = cityName.trim();

    // Create a mutable copy and handle the list logic
    List<String> updatedHistory = List.from(state);

    // Remove if already exists (to move it to the top)
    updatedHistory.remove(normalizedCity);

    // Add to the start of the list
    updatedHistory.insert(0, normalizedCity);

    // Keep a maximum of 10 cities
    if (updatedHistory.length > 10) {
      updatedHistory = updatedHistory.sublist(0, 10);
    }

    // Update the Riverpod state (triggers UI rebuild)
    state = updatedHistory;

    // Save the updated list permanently
    await prefs.setStringList(_historyKey, updatedHistory);
  }
}

final cityHistoryProvider =
    StateNotifierProvider<CityHistoryNotifier, List<String>>((ref) {
  return CityHistoryNotifier();
});
