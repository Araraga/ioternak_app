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
  }) : _apiService = apiService,
       _storageService = storageService,
       super(ScheduleInitial());

  Future<void> fetchSchedule() async {
    // Cek 1: Jangan jalan jika cubit sudah ditutup
    if (isClosed) return;

    try {
      emit(ScheduleLoading());

      final pakanId = _storageService.getPakanId();

      if (pakanId == null || pakanId.isEmpty) {
        if (!isClosed)
          emit(const ScheduleError('ID Perangkat Pakan tidak ditemukan.'));
        return;
      }

      final data = await _apiService.getSchedule(pakanId);

      // KONVERSI DATA
      // Pastikan handling error jika format data tidak sesuai
      final List<String> schedules = (data['times'] as List<dynamic>)
          .map((time) => time.toString())
          .toList();

      // Cek 2: Cek lagi setelah proses async (await) selesai
      if (!isClosed) {
        emit(ScheduleLoaded(schedules));
      }
    } catch (e) {
      // Cek 3: Cek sebelum emit error
      if (!isClosed) {
        emit(ScheduleError(e.toString()));
      }
    }
  }

  Future<void> updateSchedule(List<String> newSchedules) async {
    if (isClosed) return;

    final currentState = state;
    List<String> currentData = [];

    // Ambil data lama buat backup/optimistic UI
    if (currentState is ScheduleLoaded) {
      currentData = currentState.schedules;
    } else if (currentState is ScheduleUpdateSuccess) {
      currentData = currentState.newSchedules;
    }

    try {
      emit(ScheduleUpdating(currentData));

      final pakanId = _storageService.getPakanId();
      if (pakanId == null || pakanId.isEmpty) {
        if (!isClosed)
          emit(const ScheduleError('ID Perangkat Pakan tidak ditemukan.'));
        return;
      }

      final Map<String, dynamic> scheduleData = {'times': newSchedules};

      await _apiService.updateSchedule(pakanId, scheduleData);

      // Cek 4: Cek setelah await update selesai
      if (!isClosed) {
        emit(ScheduleUpdateSuccess(newSchedules));
      }
    } catch (e) {
      // Cek 5: Cek error
      if (!isClosed) {
        emit(ScheduleError(e.toString()));
      }
    }
  }
}
