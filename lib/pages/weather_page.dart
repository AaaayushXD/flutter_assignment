import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../blocs/weather/weather.dart';
import '../models/weather_model.dart';
import '../providers/theme_provider.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WeatherBloc(),
      child: const WeatherView(),
    );
  }
}

class WeatherView extends StatefulWidget {
  const WeatherView({super.key});

  @override
  State<WeatherView> createState() => _WeatherViewState();
}

class _WeatherViewState extends State<WeatherView> {
  final TextEditingController _cityController = TextEditingController();

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF1A1A2E)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Weather'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Animated Theme Switcher
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.indigo.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.indigo.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                  key: ValueKey(isDarkMode),
                  color: isDarkMode ? Colors.orange : Colors.indigo,
                ),
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ]
                : [
                    const Color(0xFFF5F5F5),
                    const Color(0xFFE8F4FD),
                    const Color(0xFFD4F1F4),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(isDarkMode),
              Expanded(
                child: BlocBuilder<WeatherBloc, WeatherState>(
                  builder: (context, state) {
                    if (state is WeatherInitial) {
                      return _buildInitialState(isDarkMode);
                    } else if (state is WeatherLoading) {
                      return _buildLoadingState(isDarkMode);
                    } else if (state is WeatherLoaded) {
                      return _buildWeatherContent(state.weather, isDarkMode);
                    } else if (state is WeatherError) {
                      return _buildErrorState(state.message, isDarkMode);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _cityController,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter city name...',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDarkMode ? Colors.white70 : Colors.grey,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                onSubmitted: (cityName) {
                  if (cityName.trim().isNotEmpty) {
                    context.read<WeatherBloc>().add(
                      FetchWeatherByCity(cityName.trim()),
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 15),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.my_location,
                color: isDarkMode ? Colors.white : Colors.blue,
              ),
              onPressed: () {
                context.read<WeatherBloc>().add(const FetchWeatherByLocation());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud,
            size: 100,
            color: isDarkMode ? Colors.white70 : Colors.grey,
          ),
          const SizedBox(height: 20),
          Text(
            'Search for a city to get weather information',
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white70 : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDarkMode ? Colors.white : Colors.blue,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading weather data...',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 100, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            'Error: $message',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<WeatherBloc>().add(const FetchWeatherByLocation());
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(WeatherModel weather, bool isDarkMode) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<WeatherBloc>().add(RefreshWeather(weather.cityName));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildMainWeatherCard(weather, isDarkMode),
            const SizedBox(height: 20),
            _buildWeatherDetailsCard(weather, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildMainWeatherCard(WeatherModel weather, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Colors.blue.withOpacity(0.3), Colors.purple.withOpacity(0.3)]
              : [Colors.blue.withOpacity(0.1), Colors.purple.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: isDarkMode ? Colors.white70 : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        weather.cityName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat('EEEE, MMMM d').format(weather.timestamp),
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
              Icon(
                _getWeatherIcon(weather.description),
                size: 60,
                color: isDarkMode ? Colors.white : Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${weather.temperature.round()}°',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            weather.description.toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Feels like ${weather.feelsLike.round()}°',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailsCard(WeatherModel weather, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            'Humidity',
            '${weather.humidity}%',
            Icons.water_drop,
            isDarkMode,
          ),
          const SizedBox(height: 15),
          _buildDetailRow(
            'Wind Speed',
            '${weather.windSpeed} m/s',
            Icons.air,
            isDarkMode,
          ),
          const SizedBox(height: 15),
          _buildDetailRow(
            'Pressure',
            '${weather.pressure} hPa',
            Icons.speed,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.grey,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(String description) {
    if (description.toLowerCase().contains('sun') ||
        description.toLowerCase().contains('clear') ||
        description.toLowerCase().contains('bright')) {
      return Icons.wb_sunny;
    } else if (description.toLowerCase().contains('cloud')) {
      return Icons.cloud;
    } else if (description.toLowerCase().contains('rain')) {
      return Icons.grain;
    } else if (description.toLowerCase().contains('snow')) {
      return Icons.ac_unit;
    } else if (description.toLowerCase().contains('thunder')) {
      return Icons.flash_on;
    } else {
      return Icons.cloud;
    }
  }
}
