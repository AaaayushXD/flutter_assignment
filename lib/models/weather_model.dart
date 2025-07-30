import 'package:equatable/equatable.dart';

class WeatherModel extends Equatable {
  final String cityName;
  final double temperature;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final int pressure;
  final double feelsLike;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String timezone;

  const WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.feelsLike,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    try {
      return WeatherModel(
        cityName: json['name'] ?? '',
        temperature: (json['main']?['temp'] as num?)?.toDouble() ?? 0.0,
        description: json['weather']?[0]?['description'] ?? '',
        icon: json['weather']?[0]?['icon'] ?? '',
        humidity: json['main']?['humidity'] ?? 0,
        windSpeed: (json['wind']?['speed'] as num?)?.toDouble() ?? 0.0,
        pressure: json['main']?['pressure'] ?? 0,
        feelsLike: (json['main']?['feels_like'] as num?)?.toDouble() ?? 0.0,
        timestamp: DateTime.now(),
        latitude: (json['coord']?['lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['coord']?['lon'] as num?)?.toDouble() ?? 0.0,
        timezone: json['timezone']?.toString() ?? 'UTC',
      );
    } catch (e) {
      throw Exception('Error parsing weather data: $e');
    }
  }

  @override
  List<Object?> get props => [
    cityName,
    temperature,
    description,
    icon,
    humidity,
    windSpeed,
    pressure,
    feelsLike,
    timestamp,
    latitude,
    longitude,
    timezone,
  ];
}

class LocationModel extends Equatable {
  final double latitude;
  final double longitude;
  final String? cityName;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.cityName,
  });

  @override
  List<Object?> get props => [latitude, longitude, cityName];
}
