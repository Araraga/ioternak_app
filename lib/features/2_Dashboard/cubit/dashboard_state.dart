import 'package:equatable/equatable.dart';

// Induk abstract class
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final bool hasSensorDevice;
  final bool hasPakanDevice;

  const DashboardLoaded({
    required this.hasSensorDevice,
    required this.hasPakanDevice,
  });

  @override
  List<Object> get props => [hasSensorDevice, hasPakanDevice];
}