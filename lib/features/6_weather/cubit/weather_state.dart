import 'package:equatable/equatable.dart';

abstract class WeatherState extends Equatable {
  const WeatherState();
  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherState {}

class WeatherLoading extends WeatherState {}

class WeatherLoaded extends WeatherState {
  final Map<String, dynamic> current;
  final List<Map<String, dynamic>> forecast;
  final String latitude;
  final String longitude;
  final String locationName;
  final bool isGps;
  final double? humidity;
  final double? windSpeed;
  final String? livestockAdvisory;

  const WeatherLoaded({
    required this.current,
    required this.forecast,
    this.latitude = '',
    this.longitude = '',
    this.locationName = '',
    this.isGps = false,
    this.humidity,
    this.windSpeed,
    this.livestockAdvisory,
  });

  @override
  List<Object?> get props => [
        current,
        forecast,
        latitude,
        longitude,
        locationName,
        isGps,
        humidity,
        windSpeed,
        livestockAdvisory,
      ];
}

class WeatherError extends WeatherState {
  final String message;
  const WeatherError(this.message);
  @override
  List<Object?> get props => [message];
}

