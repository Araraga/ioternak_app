import 'package:equatable/equatable.dart';

abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object> get props => [];
}

class ScheduleInitial extends ScheduleState {}

class ScheduleLoading extends ScheduleState {}

class ScheduleLoaded extends ScheduleState {
  final List<String> schedules;

  const ScheduleLoaded(this.schedules);

  @override
  List<Object> get props => [schedules];
}

class ScheduleUpdating extends ScheduleState {
  final List<String> schedules;

  const ScheduleUpdating(this.schedules);

  @override
  List<Object> get props => [schedules];
}

class ScheduleUpdateSuccess extends ScheduleState {
  final List<String> newSchedules;

  const ScheduleUpdateSuccess(this.newSchedules);

  @override
  List<Object> get props => [newSchedules];
}

class ScheduleError extends ScheduleState {
  final String message;

  const ScheduleError(this.message);

  @override
  List<Object> get props => [message];
}