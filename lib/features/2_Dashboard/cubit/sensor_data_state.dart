import 'package:equatable/equatable.dart';

abstract class SensorDataState extends Equatable {
  const SensorDataState();

  @override
  List<Object> get props => [];
}

class SensorDataInitial extends SensorDataState {}

class SensorDataLoading extends SensorDataState {}

class SensorDataLoaded extends SensorDataState {
  final List<dynamic> sensorDataList;

  const SensorDataLoaded(this.sensorDataList);

  @override
  List<Object> get props => [sensorDataList];
}

class SensorDataError extends SensorDataState {
  final String message;

  const SensorDataError(this.message);

  @override
  List<Object> get props => [message];
}