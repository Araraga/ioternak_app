import 'package:equatable/equatable.dart';

abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object> get props => [];
}

/// State awal, belum ada aksi
class ScheduleInitial extends ScheduleState {}

/// State saat jadwal sedang diambil dari API (GET)
class ScheduleLoading extends ScheduleState {}

/// State saat data jadwal berhasil dimuat
class ScheduleLoaded extends ScheduleState {
  final List<String> schedules;

  const ScheduleLoaded(this.schedules);

  @override
  List<Object> get props => [schedules];
}

/// State saat jadwal baru sedang dikirim ke API (POST/UPDATE)
class ScheduleUpdating extends ScheduleState {
  final List<String> schedules;

  const ScheduleUpdating(this.schedules);

  @override
  List<Object> get props => [schedules];
}

/// State saat jadwal berhasil diperbarui
class ScheduleUpdateSuccess extends ScheduleState {
  final List<String> newSchedules;

  const ScheduleUpdateSuccess(this.newSchedules);

  @override
  List<Object> get props => [newSchedules];
}

/// State saat terjadi kegagalan (bisa saat GET atau POST)
class ScheduleError extends ScheduleState {
  final String message;

  const ScheduleError(this.message);

  @override
  List<Object> get props => [message];
}