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

  // ── Rotations mapping ───────────────────────────────────────────────────────
  static int rotationsFor(String portion) {
    switch (portion) {
      case 'sedikit':
        return 3;
      case 'banyak':
        return 10;
      default:
        return 6; // sedang
    }
  }

  // ── Fetch ───────────────────────────────────────────────────────────────────
  Future<void> fetchSchedule() async {
    if (isClosed) return;
    try {
      emit(ScheduleLoading());
      final pakanId = _storageService.getPakanId();

      if (pakanId == null || pakanId.isEmpty) {
        emit(const ScheduleError('ID Perangkat Pakan tidak ditemukan.'));
        return;
      }

      final data = await _apiService.getSchedule(pakanId);

      // Parse new per-schedule format — backward-compatible with old format
      final List<String> schedules = _parseTimes(data['times']);

      if (!isClosed) {
        emit(ScheduleLoaded(schedules));
      }
    } catch (e) {
      if (!isClosed) {
        emit(ScheduleError("Gagal mengambil data dari server: $e"));
      }
    }
  }

  /// Parse `times` dari API.
  /// api_service.getSchedule() sudah menormalisasi ke format "HH:mm|portion".
  /// Fungsi ini sebagai fallback untuk keamanan.
  List<String> _parseTimes(dynamic rawTimes) {
    if (rawTimes == null || rawTimes is! List) return [];

    final result = <String>[];
    for (final entry in rawTimes) {
      if (entry == null) continue;
      if (entry is Map) {
        // Fallback: api_service belum normalisasi (seharusnya tidak terjadi)
        final time    = (entry['time']    ?? '').toString().trim();
        final portion = (entry['portion'] ?? 'sedang').toString().trim();
        if (time.contains(':')) result.add('$time|$portion');
      } else {
        final s = entry.toString().trim();
        if (s.isEmpty) continue;
        if (s.contains('|')) {
          result.add(s);
        } else if (s.contains(':')) {
          result.add('$s|sedang');
        }
        // Abaikan format lain (mis. Map.toString() yang salah)
      }
    }
    return result;
  }

  // ── Update ──────────────────────────────────────────────────────────────────
  /// [newSchedules] — list of "HH:mm|portion" strings
  Future<void> updateSchedule(List<String> newSchedules) async {
    if (isClosed) return;

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
        if (!isClosed) emit(const ScheduleError('ID Perangkat Pakan tidak ditemukan.'));
        return;
      }

      // Build per-schedule payload for server & MQTT
      final timesPayload = newSchedules.map((s) {
        final parts = s.split('|');
        final time = parts[0];
        final portion = parts.length > 1 ? parts[1] : 'sedang';
        return {
          'time': time,
          'portion': portion,
          'rotations': rotationsFor(portion),
        };
      }).toList();

      await _apiService.updateSchedule(pakanId, {'times': timesPayload});

      if (!isClosed) {
        emit(ScheduleUpdateSuccess(newSchedules));
      }
    } catch (e) {
      if (!isClosed) {
        emit(ScheduleError(e.toString()));
      }
    }
  }
}
