import 'package:bloc/bloc.dart';
import 'schedule_state.dart'; // Import state yang sudah kita buat
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

  /// Fungsi untuk mengambil data jadwal yang ada dari server
  Future<void> fetchSchedule() async {
    try {
      emit(ScheduleLoading());
      final pakanId = _storageService.getPakanId();

      if (pakanId == null || pakanId.isEmpty) {
        emit(const ScheduleError('ID Perangkat Pakan tidak ditemukan.'));
        return;
      }

      // Panggil API untuk GET data
      final data = await _apiService.getSchedule(pakanId);
      final List<String> schedules = (data['times'] as List<dynamic>)
          .map((time) => time.toString())
          .toList();

      emit(ScheduleLoaded(schedules));
    } catch (e) {
      emit(ScheduleError(e.toString()));
    }
  }

  /// Fungsi untuk mengirim jadwal baru ke server
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

      // Siapkan data untuk dikirim sebagai JSON (Map)
      final Map<String, dynamic> scheduleData = {
        'times': newSchedules,
      };

      // Panggil API untuk POST data baru
      await _apiService.updateSchedule(pakanId, scheduleData);

      // Jika berhasil, emit state Success
      emit(ScheduleUpdateSuccess(newSchedules));
    } catch (e) {
      emit(ScheduleError(e.toString()));
    }
  }
}