import 'package:bloc/bloc.dart';
import 'dashboard_state.dart';
import '../../../core/services/storage_service.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final StorageService _storageService;
  DashboardCubit({required StorageService storageService})
    : _storageService = storageService,
      super(DashboardInitial());

  Future<void> checkDevices() async {
    try {
      emit(DashboardLoading());
      final sensorId = _storageService.getSensorId();
      final pakanId = _storageService.getPakanId();
      final name = _storageService.getUserName() ?? "Peternak";

      emit(
        DashboardLoaded(
          hasSensorDevice: sensorId != null && sensorId.isNotEmpty,
          hasPakanDevice: pakanId != null && pakanId.isNotEmpty,
          userName: name,
        ),
      );
    } catch (e) {
      emit(
        const DashboardLoaded(
          hasSensorDevice: false,
          hasPakanDevice: false,
          userName: "Peternak",
        ),
      );
    }
  }

  Future<void> clearAllDevices() async {
    try {
      emit(DashboardLoading());
      await _storageService.clearDeviceIds();

      final name = _storageService.getUserName() ?? "Peternak";

      emit(
        DashboardLoaded(
          hasSensorDevice: false,
          hasPakanDevice: false,
          userName: name,
        ),
      );
    } catch (e) {
      emit(
        const DashboardLoaded(
          hasSensorDevice: false,
          hasPakanDevice: false,
          userName: "Peternak",
        ),
      );
    }
  }
}
