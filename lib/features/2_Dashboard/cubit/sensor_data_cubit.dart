import 'dart:async';
import 'package:flutter/foundation.dart';
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
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!isClosed && state is! SensorDataLoading) {
        fetchSensorData();
      }
    });
  }

  @override
  void emit(SensorDataState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  Future<void> fetchSensorData() async {
    if (isClosed) return;

    try {
      if (state is SensorDataInitial) {
        emit(SensorDataLoading());
      }

      final sensorId = _storageService.getSensorId();
      if (sensorId == null || sensorId.isEmpty) {
        if (!isClosed)
          emit(const SensorDataError('ID Sensor tidak ditemukan.'));
        return;
      }

      final processedData = await _apiService.getSensorData(sensorId);

      if (isClosed) return;

      if (processedData is List && processedData.isNotEmpty) {
        emit(SensorDataLoaded(processedData));
      } else {
        emit(const SensorDataLoaded([]));
      }
    } catch (e) {
      if (!isClosed) {
        if (state is SensorDataInitial || state is SensorDataLoading) {
          emit(SensorDataError("Gagal memuat data: $e"));
        } else {
          debugPrint("Background fetch error: $e");
        }
      }
    }
  }
}
