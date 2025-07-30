import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/weather_model.dart';
import '../../services/weather_service.dart';

// Events
abstract class WeatherEvent extends Equatable {
  const WeatherEvent();

  @override
  List<Object?> get props => [];
}

class FetchWeatherByCity extends WeatherEvent {
  final String cityName;

  const FetchWeatherByCity(this.cityName);

  @override
  List<Object?> get props => [cityName];
}

class FetchWeatherByLocation extends WeatherEvent {
  const FetchWeatherByLocation();
}

class RefreshWeather extends WeatherEvent {
  final String? cityName;

  const RefreshWeather([this.cityName]);

  @override
  List<Object?> get props => [cityName];
}

// States
abstract class WeatherState extends Equatable {
  const WeatherState();

  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherState {}

class WeatherLoading extends WeatherState {}

class WeatherLoaded extends WeatherState {
  final WeatherModel weather;

  const WeatherLoaded(this.weather);

  @override
  List<Object?> get props => [weather];
}

class WeatherError extends WeatherState {
  final String message;

  const WeatherError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final WeatherService _weatherService;

  WeatherBloc({WeatherService? weatherService})
    : _weatherService = weatherService ?? WeatherService(),
      super(WeatherInitial()) {
    on<FetchWeatherByCity>(_onFetchWeatherByCity);
    on<FetchWeatherByLocation>(_onFetchWeatherByLocation);
    on<RefreshWeather>(_onRefreshWeather);
  }

  Future<void> _onFetchWeatherByCity(
    FetchWeatherByCity event,
    Emitter<WeatherState> emit,
  ) async {
    emit(WeatherLoading());
    try {
      final weather = await _weatherService.getWeatherByCity(event.cityName);
      emit(WeatherLoaded(weather));
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceAll('Exception: ', '');
      }
      emit(WeatherError(errorMessage));
    }
  }

  Future<void> _onFetchWeatherByLocation(
    FetchWeatherByLocation event,
    Emitter<WeatherState> emit,
  ) async {
    emit(WeatherLoading());
    try {
      final position = await _weatherService.getCurrentLocation();
      final weather = await _weatherService.getWeatherByLocation(
        position.latitude,
        position.longitude,
      );
      emit(WeatherLoaded(weather));
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceAll('Exception: ', '');
      }
      emit(WeatherError(errorMessage));
    }
  }

  Future<void> _onRefreshWeather(
    RefreshWeather event,
    Emitter<WeatherState> emit,
  ) async {
    if (event.cityName != null) {
      add(FetchWeatherByCity(event.cityName!));
    } else {
      add(const FetchWeatherByLocation());
    }
  }
}
