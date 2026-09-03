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

  const WeatherLoaded({
    required this.current,
    required this.forecast,
    this.latitude = '',
    this.longitude = '',
  });

  @override
  List<Object?> get props => [current, forecast, latitude, longitude];
}

class WeatherError extends WeatherState {
  final String message;
  const WeatherError(this.message);
  @override
  List<Object?> get props => [message];
}
