import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  SharedPreferences? _prefs;

  static const String _kSensorIdKey = 'sensor_id';
  static const String _kPakanIdKey = 'pakan_id';
  static const String _kUserName = 'user_name';
  static const String _kUserPhone = 'user_phone';
  static const String _kUserIdDB = 'user_id_db';
  static const String _kOnboardingDone = 'onboarding_done';
  static const String _kChatHistory = 'chat_history';
  static const String _kUserCity = 'user_city';
  static const String _kUserProvince = 'user_province';
  static const String _kLastWeatherLat = 'last_weather_lat';
  static const String _kLastWeatherLon = 'last_weather_lon';
  static const String _kActiveBarnId = 'active_barn_id';
  static const String _kNotificationCount = 'notification_count';
  static const String _kUserAddress = 'user_address';
  static const String _kLivestockType = 'livestock_type';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _checkInit() {
    if (_prefs == null) {
      throw Exception('StorageService belum diinisialisasi.');
    }
  }

  // =====================
  // DEVICE IDs
  // =====================

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

  // =====================
  // USER PROFILE
  // =====================

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

  Future<void> saveUserAddress({
    String? address,
    String? city,
    String? province,
    String? livestockType,
  }) async {
    _checkInit();
    if (address != null) await _prefs!.setString(_kUserAddress, address);
    if (city != null) await _prefs!.setString(_kUserCity, city);
    if (province != null) await _prefs!.setString(_kUserProvince, province);
    if (livestockType != null) {
      await _prefs!.setString(_kLivestockType, livestockType);
    }
  }

  String? getUserCity() {
    _checkInit();
    return _prefs!.getString(_kUserCity);
  }

  String? getUserProvince() {
    _checkInit();
    return _prefs!.getString(_kUserProvince);
  }

  String? getLivestockType() {
    _checkInit();
    return _prefs!.getString(_kLivestockType);
  }

  String? getUserAddress() {
    _checkInit();
    return _prefs!.getString(_kUserAddress);
  }

  // =====================
  // ONBOARDING
  // =====================

  Future<void> setOnboardingComplete() async {
    _checkInit();
    await _prefs!.setBool(_kOnboardingDone, true);
  }

  bool isOnboardingComplete() {
    _checkInit();
    return _prefs!.getBool(_kOnboardingDone) ?? false;
  }

  // =====================
  // CHAT HISTORY
  // =====================

  Future<void> saveChatHistory(List<Map<String, String>> messages) async {
    _checkInit();
    final String encoded = jsonEncode(messages);
    await _prefs!.setString(_kChatHistory, encoded);
  }

  List<Map<String, String>> getChatHistory() {
    _checkInit();
    final String? jsonString = _prefs!.getString(_kChatHistory);
    if (jsonString == null) return [];
    List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((item) => Map<String, String>.from(item)).toList();
  }

  Future<void> clearChatHistory() async {
    _checkInit();
    await _prefs!.remove(_kChatHistory);
  }

  // =====================
  // WEATHER LOCATION
  // =====================

  Future<void> saveWeatherLocation(String lat, String lon) async {
    _checkInit();
    await _prefs!.setString(_kLastWeatherLat, lat);
    await _prefs!.setString(_kLastWeatherLon, lon);
  }

  String? getWeatherLat() {
    _checkInit();
    return _prefs!.getString(_kLastWeatherLat);
  }

  String? getWeatherLon() {
    _checkInit();
    return _prefs!.getString(_kLastWeatherLon);
  }

  // =====================
  // ACTIVE BARN
  // =====================

  Future<void> saveActiveBarnId(String barnId) async {
    _checkInit();
    await _prefs!.setString(_kActiveBarnId, barnId);
  }

  String? getActiveBarnId() {
    _checkInit();
    return _prefs!.getString(_kActiveBarnId);
  }

  // =====================
  // NOTIFICATIONS
  // =====================

  Future<void> saveNotificationCount(int count) async {
    _checkInit();
    await _prefs!.setInt(_kNotificationCount, count);
  }

  int getNotificationCount() {
    _checkInit();
    return _prefs!.getInt(_kNotificationCount) ?? 0;
  }

  Future<void> clearNotificationCount() async {
    _checkInit();
    await _prefs!.remove(_kNotificationCount);
  }

  // =====================
  // FEED STOCK
  // =====================

  Future<void> saveFeedStockGudang(String barnId, double amountKg) async {
    _checkInit();
    await _prefs!.setDouble('feed_stock_gudang_$barnId', amountKg);
  }

  double getFeedStockGudang(String barnId) {
    _checkInit();
    return _prefs!.getDouble('feed_stock_gudang_$barnId') ?? 0.0;
  }

  Future<void> saveFeedStockAlat(String barnId, double amountKg) async {
    _checkInit();
    await _prefs!.setDouble('feed_stock_alat_$barnId', amountKg);
  }

  double getFeedStockAlat(String barnId) {
    _checkInit();
    return _prefs!.getDouble('feed_stock_alat_$barnId') ?? 0.0;
  }

  // =====================
  // CLEAR ALL
  // =====================

  Future<void> clearAllData() async {
    _checkInit();
    await _prefs!.clear();
  }
}
