import 'dart:async';
import 'package:bloc/bloc.dart';
import 'sensor_data_state.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class SensorDataCubit extends Cubit<SensorDataState> {
  final ApiService _apiService;
  final StorageService _storageService;
  Timer? _timer;

  SensorDataCubit({
    required ApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService,
       _storageService = storageService,
       super(SensorDataInitial()) {
    fetchSensorData();

    // Timer berjalan setiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Pastikan cubit belum ditutup sebelum memanggil fungsi
      if (!isClosed && state is! SensorDataLoading) {
        fetchSensorData();
      }
    });
  }

  // --- PERBAIKAN UTAMA: Override emit agar aman ---
  @override
  void emit(SensorDataState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }
  // ------------------------------------------------

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  Future<void> fetchSensorData() async {
    // Cek di awal fungsi
    if (isClosed) return;

    try {
      if (state is SensorDataInitial) {
        emit(SensorDataLoading());
      }

      final sensorId = _storageService.getSensorId();
      if (sensorId == null || sensorId.isEmpty) {
        if (!isClosed) {
          emit(
            const SensorDataError(
              'ID Perangkat Sensor tidak ditemukan di Storage.',
            ),
          );
        }
        return;
      }

      // Proses Asynchronous (menunggu server)
      final data = await _apiService.getSensorData(sensorId);

      // Cek lagi apakah cubit ditutup saat menunggu data
      if (isClosed) return;

      if (data is List && data.isNotEmpty) {
        emit(SensorDataLoaded(data));
      } else {
        emit(const SensorDataError('Belum ada data terekam untuk ID ini.'));
      }
    } catch (e) {
      if (!isClosed) {
        emit(SensorDataError(e.toString()));
      }
    }
  }
}
