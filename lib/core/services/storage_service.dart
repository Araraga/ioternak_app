import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  SharedPreferences? _prefs;

  static const String _kSensorIdKey = 'sensor_id';
  static const String _kPakanIdKey = 'pakan_id';
  static const String _kUserName = 'user_name';
  static const String _kUserPhone = 'user_phone';
  static const String _kUserIdDB = 'user_id_db';
  static const String _kOnboardingDone = 'onboarding_done';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _checkInit() {
    if (_prefs == null) {
      throw Exception('StorageService belum diinisialisasi.');
    }
  }

  Future<void> saveSensorId(String id) async {
    _checkInit();
    await _prefs!.setString(_kSensorIdKey, id);
  }

  String? getSensorId() {
    _checkInit();
    return _prefs!.getString(_kSensorIdKey);
  }

  Future<void> clearSensorId() async {
    _checkInit();
    await _prefs!.remove(_kSensorIdKey);
  }

  Future<void> savePakanId(String id) async {
    _checkInit();
    await _prefs!.setString(_kPakanIdKey, id);
  }

  String? getPakanId() {
    _checkInit();
    return _prefs!.getString(_kPakanIdKey);
  }

  Future<void> clearPakanId() async {
    _checkInit();
    await _prefs!.remove(_kPakanIdKey);
  }

  Future<void> clearDeviceIds() async {
    _checkInit();
    await _prefs!.remove(_kSensorIdKey);
    await _prefs!.remove(_kPakanIdKey);
  }

  Future<void> saveUserProfile(String name, String phone) async {
    _checkInit();
    await _prefs!.setString(_kUserName, name);
    await _prefs!.setString(_kUserPhone, phone);
  }

  Future<void> saveUserIdFromDB(String userId) async {
    _checkInit();
    await _prefs!.setString(_kUserIdDB, userId);
  }

  String? getUserName() {
    _checkInit();
    return _prefs!.getString(_kUserName);
  }

  String? getUserPhone() {
    _checkInit();
    return _prefs!.getString(_kUserPhone);
  }

  String? getUserIdFromDB() {
    _checkInit();
    return _prefs!.getString(_kUserIdDB);
  }

  Future<void> setOnboardingComplete() async {
    _checkInit();
    await _prefs!.setBool(_kOnboardingDone, true);
  }

  bool isOnboardingComplete() {
    _checkInit();
    return _prefs!.getBool(_kOnboardingDone) ?? false;
  }

  Future<void> clearAllData() async {
    _checkInit();
    await _prefs!.clear();
  }
}
