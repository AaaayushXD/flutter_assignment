class AppConfig {
  // API Configuration
  static const String openWeatherApiKey = '5e580e6b2a504dd74a5069fc1a18637f';
  static const String openWeatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  // Timeout Configuration
  static const int apiTimeoutSeconds = 10;
  static const int locationTimeoutSeconds = 15;

  // Debug Configuration
  static const bool enableDebugLogging = true;

  // App Configuration
  static const String appName = 'Weather App';
  static const String appVersion = '1.0.0';
}
