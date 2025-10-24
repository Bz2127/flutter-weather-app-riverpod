import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

// --- Imports for Models, State, and Repositories ---
import 'models/weather_model.dart';
import 'models/forecast_model.dart';
import 'state/weather_notifier.dart';
import 'state/city_history_notifier.dart';
import 'state/weather_state.dart';
// Import custom exceptions to use in the error handling logic
import 'repositories/weather_repository.dart';

// The main screen is a ConsumerWidget to listen to Riverpod state
class WeatherHomePage extends ConsumerWidget {
  const WeatherHomePage({super.key});

  // Dynamically determines the background gradient based on the weather condition
  List<Color> _getBackgroundGradient(String? mainCondition) {
    if (mainCondition == null) {
      // Default clear sky blue
      return const [Color(0xFF4A90E2), Color(0xFF50C6D8)];
    }

    switch (mainCondition.toLowerCase()) {
      case 'clear':
        return const [
          Color(0xFFFFCC33),
          Color(0xFFFF6600)
        ]; // Sunny/Yellow-Orange
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return const [Color(0xFF6E7E8E), Color(0xFF9EAAB6)]; // Gray/Cloudy
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return const [Color(0xFF004C8C), Color(0xFF41729F)]; // Dark Blue/Rainy
      case 'thunderstorm':
        return const [Color(0xFF330033), Color(0xFF4C004C)]; // Purple/Stormy
      case 'snow':
        return const [Color(0xFFADD8E6), Color(0xFFE0FFFF)]; // Light Blue/Snowy
      default:
        return const [Color(0xFF4A90E2), Color(0xFF50C6D8)]; // Default
    }
  }

  // Maps OpenWeatherMap conditions to Font Awesome icons
  IconData _getWeatherIcon(String? mainCondition) {
    if (mainCondition == null) return FontAwesomeIcons.sun;

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return FontAwesomeIcons.cloud;
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return FontAwesomeIcons.cloudShowersHeavy;
      case 'thunderstorm':
        return FontAwesomeIcons.cloudBolt;
      case 'clear':
        return FontAwesomeIcons.sun;
      case 'snow':
        return FontAwesomeIcons.snowflake;
      default:
        return FontAwesomeIcons.sun;
    }
  }

  // Shows the search dialog to get city name input
  void _showCitySearchDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    // Read notifiers to access methods without rebuilding the widget (read)
    final weatherController = ref.read(weatherNotifierProvider.notifier);
    final historyController = ref.read(cityHistoryProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Search City"),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter city name (e.g., Addis Ababa)",
            hintStyle: TextStyle(color: Colors.grey),
            prefixIcon: Icon(Icons.location_city, color: Colors.grey),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            if (value.trim().isNotEmpty) {
              weatherController.fetchWeatherByCity(value.trim());
              historyController.saveCityToHistory(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.trim().isNotEmpty) {
                weatherController.fetchWeatherByCity(controller.text.trim());
                historyController.saveCityToHistory(controller.text.trim());
              }
            },
            child: const Text("Search"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  // Builds an error state widget with user-friendly messages based on the exception type
  Widget _buildErrorState(
    BuildContext context,
    WeatherState state,
    WeatherNotifier weatherController,
  ) {
    // Map the specific custom exception to a user-friendly message and icon
    String title;
    IconData icon;
    // Fallback message, typically for unknown errors
    String message = state.error ?? "An unknown error occurred.";

    if (state.exception is CityNotFoundException) {
      title = "City Not Found 🌎";
      icon = Icons.location_off;
      message =
          "We couldn't find the requested city. Please check the spelling and try again.";
    } else if (state.exception is NetworkException) {
      title = "No Internet Connection 🔌";
      icon = Icons.wifi_off;
      message =
          "Failed to connect to the weather service. Check your network connection.";
    } else if (state.exception is LocationPermissionException) {
      title = "Location Access Denied 🚫";
      icon = Icons.gps_off;

      // Determine the specific location permission issue
      final exceptionMessage = state.exception.toString().toLowerCase();
      if (exceptionMessage.contains("permanently denied")) {
        message =
            "Location permissions permanently denied. Go to settings to grant permission.";
      } else if (exceptionMessage.contains("disabled")) {
        message = "Location services are required. Please enable them.";
      } else {
        message =
            "Location permissions are required for GPS-based refresh. Please grant permission.";
      }
    } else {
      // Generic Error fallback
      title = "Oops! Something Went Wrong";
      icon = Icons.error_outline;
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          // Always allow refreshing to try current location again
          ElevatedButton.icon(
            onPressed: weatherController.fetchCurrentLocationWeather,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh (Current Location)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch state and read notifiers for separation of concerns (UI watches, UI reads methods)
    final weatherState = ref.watch(weatherNotifierProvider);
    final weatherController = ref.read(weatherNotifierProvider.notifier);
    final cityHistory = ref.watch(cityHistoryProvider);
    final historyController = ref.read(cityHistoryProvider.notifier);
    final isCelsius = weatherController.isCelsius;

    final WeatherModel? weather = weatherState.weather;
    final bool isLoading = weatherState.isLoading;
    final List<ForecastDay> forecast = weatherState.forecast;

    final currentGradient = _getBackgroundGradient(weather?.mainCondition);

    // Determine which widget to show based on the weather state
    Widget contentWidget;

    if (isLoading) {
      contentWidget = const Center(
        key: ValueKey('loading'), // Key for AnimatedSwitcher
        child: CircularProgressIndicator(color: Colors.white),
      );
    } else if (weatherState.error != null) {
      contentWidget = Center(
        key: const ValueKey('error'), // Key for AnimatedSwitcher
        child: _buildErrorState(context, weatherState, weatherController),
      );
    } else if (weather != null) {
      contentWidget = WeatherDisplay(
        key: const ValueKey('data'), // Key for AnimatedSwitcher
        weather: weather,
        getWeatherIcon: _getWeatherIcon,
        forecast: forecast,
        isCelsius: isCelsius,
      );
    } else {
      // Initial empty state
      contentWidget = const Center(
        key: ValueKey('initial'), // Key for AnimatedSwitcher
        child: Text(
            "No weather data available. Try refreshing or searching a city.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16)),
      );
    }

    return Scaffold(
      // Search History Drawer
      drawer: Drawer(
        backgroundColor: Colors.grey[900],
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueGrey),
              child: ListTile(
                title: Text('Search History',
                    style: TextStyle(color: Colors.white, fontSize: 24)),
                trailing: Icon(Icons.history, color: Colors.white),
              ),
            ),
            Expanded(
              child: cityHistory.isEmpty
                  ? const Center(
                      // Show a message if no history is saved
                      child: Text("No search history.",
                          style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                      itemCount: cityHistory.length,
                      itemBuilder: (context, index) {
                        final cityName = cityHistory[index];
                        return ListTile(
                          leading: const Icon(Icons.location_city,
                              color: Colors.white54),
                          title: Text(cityName,
                              style: const TextStyle(color: Colors.white)),
                          // On tap, fetch weather for the selected city
                          onTap: () {
                            Navigator.pop(context);
                            weatherController.fetchWeatherByCity(cityName);
                            // Save the city again to move it to the top of the history list
                            historyController.saveCityToHistory(cityName);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      body: Container(
        // Dynamic background based on current weather condition
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: currentGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Custom AppBar section (fully transparent)
            AppBar(
              title: const Text('Local Weather Forecast'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Search History',
                ),
              ),
              actions: [
                // Unit Toggle Button (uses FontAwesomeIcons for clear visual change)
                IconButton(
                  icon: Icon(isCelsius
                      ? FontAwesomeIcons.temperatureLow
                      : FontAwesomeIcons.temperatureHigh),
                  onPressed: weatherController.toggleUnit,
                  tooltip:
                      isCelsius ? 'Switch to Fahrenheit' : 'Switch to Celsius',
                ),
                // Search Dialog Button
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _showCitySearchDialog(context, ref),
                  tooltip: 'Search City',
                ),
                // Refresh (Current Location) Button
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: weatherController.fetchCurrentLocationWeather,
                  tooltip: 'Refresh Weather (Current Location)',
                ),
              ],
            ),
            Expanded(
              // AnimatedSwitcher provides a smooth transition between states (Loading/Data/Error)
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: contentWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Display widget for weather data and forecast
class WeatherDisplay extends StatelessWidget {
  final WeatherModel weather;
  final IconData Function(String?) getWeatherIcon;
  final List<ForecastDay> forecast;
  final bool isCelsius;

  const WeatherDisplay({
    super.key,
    required this.weather,
    required this.getWeatherIcon,
    required this.forecast,
    required this.isCelsius,
  });

  // Conversion helper
  double _toFahrenheit(double celsius) {
    return (celsius * 9 / 5) + 32;
  }

  // Formats the temperature with the correct unit based on state
  String _getDisplayTemperature(double tempCelsius) {
    final temp = isCelsius ? tempCelsius : _toFahrenheit(tempCelsius);
    final unit = isCelsius ? '°C' : '°F';
    return '${temp.round()}$unit';
  }

  // Formats the day (e.g., 'Today', 'Mon', 'Tue')
  String _getFormattedDay(DateTime date) {
    final now = DateTime.now();
    // Check if the date is the current day
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return 'Today';
    }
    return DateFormat('EEE').format(date); // e.g., Mon, Tue
  }

  // Helper widget for humidity and wind speed display
  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        FaIcon(icon, size: 28, color: Colors.white54),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weather.cityName,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          // Main Weather Icon
          FaIcon(
            getWeatherIcon(weather.mainCondition),
            size: 120,
            color: Colors.white,
          ),
          const SizedBox(height: 10),
          Text(
            weather.mainCondition,
            style: const TextStyle(
              fontSize: 24,
              fontStyle: FontStyle.italic,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 40),
          // Current Temperature
          Text(
            _getDisplayTemperature(weather.temperature),
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w200,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          // Humidity and Wind Speed Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailCard(
                icon: FontAwesomeIcons.droplet,
                label: 'Humidity',
                value: '${weather.humidity.round()}%',
              ),
              _buildDetailCard(
                icon: FontAwesomeIcons.wind,
                label: 'Wind Speed',
                value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
              ),
            ],
          ),
          const SizedBox(height: 60),
          // 5-Day Forecast section
          if (forecast.isNotEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '5-Day Forecast',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 15),
          if (forecast.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                // Show max 5 days
                itemCount: forecast.length > 5 ? 5 : forecast.length,
                separatorBuilder: (context, index) => const SizedBox(width: 15),
                itemBuilder: (context, index) {
                  final day = forecast[index];
                  return Container(
                    width: 85,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getFormattedDay(day.date),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        FaIcon(
                          getWeatherIcon(day.mainCondition),
                          size: 30,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 5),
                        // Display max/min temperatures
                        Text(
                          '${_getDisplayTemperature(day.tempMax)} / ${_getDisplayTemperature(day.tempMin)}'
                              .replaceAll(' ', ''),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
