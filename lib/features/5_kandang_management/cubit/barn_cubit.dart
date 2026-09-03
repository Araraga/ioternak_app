import 'package:bloc/bloc.dart';
import 'barn_state.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class BarnCubit extends Cubit<BarnState> {
  final ApiService _api;
  final StorageService _storage;

  BarnCubit({required ApiService api, required StorageService storage})
    : _api = api,
      _storage = storage,
      super(BarnInitial());

  Future<void> fetchBarns() async {
    try {
      emit(BarnLoading());
      final userId = _storage.getUserIdFromDB();
      if (userId == null) {
        emit(const BarnLoaded(barns: []));
        return;
      }
      final barns = await _api.getBarns(userId);
      emit(BarnLoaded(barns: barns));
    } catch (e) {
      emit(BarnError('Gagal memuat kandang: $e'));
    }
  }

  Future<void> createBarn({
    required String barnName,
    required String animalType,
    int? capacity,
    String? location,
    String? description,
    double prefTempMin = 29.0,
    double prefTempMax = 33.0,
    double prefHumMin = 50.0,
    double prefHumMax = 70.0,
    double prefGasMax = 20.0,
  }) async {
    try {
      emit(BarnLoading());
      final userId = _storage.getUserIdFromDB();
      if (userId == null) {
        emit(const BarnError('Sesi login tidak valid'));
        return;
      }

      final result = await _api.createBarn({
        'barn_name': barnName,
        'owner_id': int.parse(userId),
        'animal_type': animalType,
        'capacity': capacity,
        'location': location,
        'description': description,
        'preferred_temp_min': prefTempMin,
        'preferred_temp_max': prefTempMax,
        'preferred_humidity_min': prefHumMin,
        'preferred_humidity_max': prefHumMax,
        'preferred_gas_max': prefGasMax,
      });

      emit(BarnCreated(result));
      await fetchBarns();
    } catch (e) {
      emit(BarnError('Gagal membuat kandang: $e'));
    }
  }

  Future<void> updateBarn({
    required String barnId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      emit(BarnLoading());
      final result = await _api.updateBarn(barnId, updates);
      emit(BarnCreated(result));
      await fetchBarns();
    } catch (e) {
      emit(BarnError('Gagal mengupdate kandang: $e'));
    }
  }

  // === FEED STOCK MANAGEMENT ===
  double getFeedStockGudang(String barnId) {
    return _storage.getFeedStockGudang(barnId);
  }

  double getFeedStockAlat(String barnId) {
    return _storage.getFeedStockAlat(barnId);
  }

  Future<void> addFeedStockGudang(String barnId, double amountKg) async {
    final current = getFeedStockGudang(barnId);
    await _storage.saveFeedStockGudang(barnId, current + amountKg);
  }

  Future<bool> transferFeedStockToAlat(String barnId, double amountKg) async {
    final currentGudang = getFeedStockGudang(barnId);
    if (currentGudang < amountKg) return false; // Insufficient stock
    
    await _storage.saveFeedStockGudang(barnId, currentGudang - amountKg);
    final currentAlat = getFeedStockAlat(barnId);
    await _storage.saveFeedStockAlat(barnId, currentAlat + amountKg);
    return true;
  }

  Future<void> deductFeedStockAlat(String barnId, double amountKg) async {
    final currentAlat = getFeedStockAlat(barnId);
    final newAmount = (currentAlat - amountKg) > 0 ? (currentAlat - amountKg) : 0.0;
    await _storage.saveFeedStockAlat(barnId, newAmount);
  }
}
