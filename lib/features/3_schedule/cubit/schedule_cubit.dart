import 'package:bloc/bloc.dart';
import 'schedule_state.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final ApiService _apiService;
  final StorageService _storageService;

  ScheduleCubit({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService,
        super(ScheduleInitial());

  Future<void> fetchSchedule() async {
    try {
      emit(ScheduleLoading());
      final pakanId = _storageService.getPakanId();

      if (pakanId == null || pakanId.isEmpty) {
        emit(const ScheduleError('ID Perangkat Pakan tidak ditemukan.'));
        return;
      }

      final data = await _apiService.getSchedule(pakanId);
      final List<String> schedules = (data['times'] as List<dynamic>)
          .map((time) => time.toString())
          .toList();

      emit(ScheduleLoaded(schedules));
    } catch (e) {
      emit(ScheduleError(e.toString()));
    }
  }

  Future<void> updateSchedule(List<String> newSchedules) async {
    final currentState = state;
    List<String> currentData = [];
    if (currentState is ScheduleLoaded) {
      currentData = currentState.schedules;
    } else if (currentState is ScheduleUpdateSuccess) {
      currentData = currentState.newSchedules;
    }

    try {
      emit(ScheduleUpdating(currentData));

      final pakanId = _storageService.getPakanId();
      if (pakanId == null || pakanId.isEmpty) {
        emit(const ScheduleError('ID Perangkat Pakan tidak ditemukan.'));
        return;
      }

      final Map<String, dynamic> scheduleData = {
        'times': newSchedules,
      };

      await _apiService.updateSchedule(pakanId, scheduleData);

      emit(ScheduleUpdateSuccess(newSchedules));
    } catch (e) {
      emit(ScheduleError(e.toString()));
    }
  }
}