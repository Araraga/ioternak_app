import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  SharedPreferences? _prefs;

  static const String _kSensorIdKey = 'sensor_id';
  static const String _kPakanIdKey = 'pakan_id';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _checkInit() {
    if (_prefs == null) {
      throw Exception('StorageService belum diinisialisasi.');
    }
  }

  // --- FUNGSI BARU ---
  /// Menyimpan ID Sensor.
  Future<void> saveSensorId(String sensorId) async {
    _checkInit();
    await _prefs!.setString(_kSensorIdKey, sensorId);
  }

  // --- FUNGSI BARU ---
  /// Menyimpan ID Pakan.
  Future<void> savePakanId(String pakanId) async {
    _checkInit();
    await _prefs!.setString(_kPakanIdKey, pakanId);
  }

  // --- FUNGSI LAMA (Tetap Sama) ---
  String? getSensorId() {
    _checkInit();
    return _prefs!.getString(_kSensorIdKey);
  }

  String? getPakanId() {
    _checkInit();
    return _prefs!.getString(_kPakanIdKey);
  }

  Future<void> clearDeviceIds() async {
    _checkInit();
    await _prefs!.remove(_kSensorIdKey);
    await _prefs!.remove(_kPakanIdKey);
  }
}