☁️ Flutter Local Weather Forecast App
A Clean, State-Managed Weather Application Built with Flutter and Riverpod

This project provides real-time and 5-day weather forecasts for selected cities.
It demonstrates skills in Flutter, Dart, and modern Riverpod state management, with a focus on a clean and organized architecture.

🚀 Key Features
Icon Feature Description
🌦️ Current Weather Displays temperature, condition, humidity, and wind speed.
🔍 City Search Search for weather information using a dialog box.
🗓️ 5-Day Forecast Shows weather trends for the upcoming days.
🔄 Unit Toggle Switch between Celsius (°C) and Fahrenheit (°F).
📜 Search History Keeps track of recently searched cities in a sidebar.
🛑 Error Handling Displays friendly messages (e.g., “City Not Found”) when necessary.
🛠️ Tech Stack & Architecture

This application highlights clean structure and separation of logic.

Framework: Flutter

Language: Dart

State Management: Riverpod (StateNotifierProvider)

Architecture: Repository Pattern for separating API logic from UI

API Provider: OpenWeatherMap

⚙️ Local Setup Instructions
Prerequisites

Flutter SDK installed

VS Code or Android Studio with Flutter & Dart extensions

A valid OpenWeatherMap API key

Steps to Run

Clone the Repository

git clone https://github.com/Bz2127/flutter-weather-app-riverpod.git
cd flutter-weather-app-riverpod

Install Dependencies

flutter pub get

Add Your API Key

Open lib/repository/weather_repository.dart

Replace the placeholder key with your actual key:

static const String apiKey = 'YOUR_API_KEY_HERE';

Run the App

For web:

flutter run -d chrome

For mobile (if connected):

flutter run

🤝 Contact

GitHub: https://github.com/Bz2127
