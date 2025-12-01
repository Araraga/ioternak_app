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
  })  : _apiService = apiService,
        _storageService = storageService,
        super(SensorDataInitial()) {

    fetchSensorData();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (state is! SensorDataLoading) {
        fetchSensorData();
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  Future<void> fetchSensorData() async {
    try {
      if (state is SensorDataInitial) {
        emit(SensorDataLoading());
      }

      final sensorId = _storageService.getSensorId();
      if (sensorId == null || sensorId.isEmpty) {
        emit(const SensorDataError(
            'ID Perangkat Sensor tidak ditemukan di Storage.'));
        return;
      }

      final data = await _apiService.getSensorData(sensorId);

      if (data is List && data.isNotEmpty) {
        emit(SensorDataLoaded(data));
      } else {
        emit(const SensorDataError('Belum ada data terekam untuk ID ini.'));
      }

    } catch (e) {
      emit(SensorDataError(e.toString()));
    }
  }
}