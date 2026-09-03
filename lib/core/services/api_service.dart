import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../constants/api_endpoints.dart';

class ApiService {
  // =========================================================
  // SENSOR DATA PROCESSING
  // =========================================================

  static List<Map<String, dynamic>> _processSensorData(String responseBody) {
    final decoded = jsonDecode(responseBody);
    List<dynamic> fullList = [];

    if (decoded is List) {
      fullList = decoded;
    } else if (decoded is Map<String, dynamic> &&
        decoded.containsKey('data')) {
      fullList = decoded['data'] as List<dynamic>;
    }

    if (fullList.isEmpty) return [];

    var latestRaw = fullList.last;
    double latestGas =
        double.tryParse(
          (latestRaw['amonia'] ?? latestRaw['gas_ppm']).toString(),
        ) ??
        0.0;
    double latestTemp =
        double.tryParse(latestRaw['temperature'].toString()) ?? 0.0;
    double latestHum =
        double.tryParse(latestRaw['humidity'].toString()) ?? 0.0;
    String latestDateStr = latestRaw['timestamp'] ?? latestRaw['created_at'];

    Map<String, List<double>> gasMap = {};
    Map<String, List<double>> tempMap = {};
    Map<String, List<double>> humMap = {};

    for (var item in fullList) {
      try {
        String? dateStr = item['timestamp'] ?? item['created_at'];
        if (dateStr == null) continue;
        DateTime date = DateTime.parse(dateStr).toLocal();
        String dayKey = DateFormat('yyyy-MM-dd').format(date);

        double? gas = double.tryParse(
          (item['amonia'] ?? item['gas_ppm']).toString(),
        );
        double? temp = double.tryParse(item['temperature'].toString());
        double? hum = double.tryParse(item['humidity'].toString());

        if (gas != null) {
          if (!gasMap.containsKey(dayKey)) gasMap[dayKey] = [];
          gasMap[dayKey]!.add(gas);
        }
        if (temp != null) {
          if (!tempMap.containsKey(dayKey)) tempMap[dayKey] = [];
          tempMap[dayKey]!.add(temp);
        }
        if (hum != null) {
          if (!humMap.containsKey(dayKey)) humMap[dayKey] = [];
          humMap[dayKey]!.add(hum);
        }
      } catch (e) {
        continue;
      }
    }

    List<Map<String, dynamic>> finalStats = [];
    var sortedKeys = gasMap.keys.toList()..sort();

    for (var key in sortedKeys) {
      var gList = gasMap[key]!;
      double avgGas = gList.reduce((a, b) => a + b) / gList.length;
      var tList = tempMap[key] ?? [];
      double avgTemp =
          tList.isNotEmpty ? tList.reduce((a, b) => a + b) / tList.length : 0;
      var hList = humMap[key] ?? [];
      double avgHum =
          hList.isNotEmpty ? hList.reduce((a, b) => a + b) / hList.length : 0;

      finalStats.add({
        'created_at': key,
        'timestamp': key,
        'amonia': avgGas,
        'temperature': avgTemp,
        'humidity': avgHum,
        'gas': avgGas,
        'temp': avgTemp,
        'hum': avgHum,
        'date': key,
      });
    }

    List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(
      finalStats.reversed,
    );

    if (result.isNotEmpty) {
      String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String dataKey = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.parse(latestDateStr));

      if (result[0]['date'] == dataKey) {
        result[0]['amonia'] = latestGas;
        result[0]['temperature'] = latestTemp;
        result[0]['humidity'] = latestHum;
        result[0]['gas'] = latestGas;
        result[0]['temp'] = latestTemp;
        result[0]['hum'] = latestHum;
      } else {
        result.insert(0, {
          'created_at': latestDateStr,
          'amonia': latestGas,
          'temperature': latestTemp,
          'humidity': latestHum,
          'gas': latestGas,
          'temp': latestTemp,
          'hum': latestHum,
          'date': todayKey,
        });
      }
    }

    return result;
  }

  static Map<String, dynamic> _parseJsonMap(String responseBody) {
    final result = jsonDecode(responseBody);
    return result is Map<String, dynamic> ? result : {};
  }

  // =========================================================
  // SENSOR DATA
  // =========================================================

  Future<dynamic> getSensorData(String deviceId) async {
    try {
      final url = Uri.parse(ApiEndpoints.getSensorData(deviceId));
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return await compute(_processSensorData, response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // =========================================================
  // AUTH
  // =========================================================

  Future<bool> requestOtp(String phone) async {
    final url = Uri.parse(ApiEndpoints.requestOtp);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      if (response.statusCode == 200) return true;
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Gagal request OTP');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String phone,
    required String otp,
  }) async {
    final url = Uri.parse(ApiEndpoints.registerUser);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'full_name': fullName, 'phone': phone, 'otp': otp}),
    );
    final result = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) return result;
    throw Exception(result['message'] ?? 'Gagal Registrasi');
  }

  Future<Map<String, dynamic>> loginUser(String phone) async {
    final url = Uri.parse(ApiEndpoints.loginUser);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    final result = jsonDecode(response.body);
    if (response.statusCode == 200) return result;
    if (response.statusCode == 404) throw Exception('Nomor belum terdaftar.');
    throw Exception(result['message'] ?? 'Gagal Login');
  }

  // =========================================================
  // DEVICES
  // =========================================================

  Future<List<dynamic>> getMyDevices(String userId) async {
    final url = Uri.parse(ApiEndpoints.getMyDevices(userId));
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Cek status online/offline perangkat berdasarkan data sensor terbaru.
  /// Mengembalikan Map<deviceId, isOnline> dimana online = data dalam 5 menit terakhir.
  Future<Map<String, bool>> getDeviceStatus(List<String> deviceIds) async {
    if (deviceIds.isEmpty) return {};
    try {
      final url = Uri.parse(ApiEndpoints.getDeviceStatus(deviceIds));
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final raw = json['data'] as Map<String, dynamic>? ?? {};
        return raw.map((k, v) => MapEntry(k, v == true));
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> claimDevice(
    String deviceId,
    String userId,
    String phone, {
    String? barnId,
  }) async {
    final url = Uri.parse(ApiEndpoints.claimDevice);
    final body = {
      'device_id': deviceId,
      'user_id': userId,
      'user_phone': phone,
    };
    if (barnId != null) body['barn_id'] = barnId;

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final result = jsonDecode(response.body);
    if (response.statusCode == 200) return result;
    throw Exception(result['message'] ?? 'Gagal klaim alat');
  }

  Future<void> releaseDevice(String deviceId, String userId) async {
    final url = Uri.parse(ApiEndpoints.releaseDevice);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_id': deviceId, 'user_id': userId}),
    );
    if (response.statusCode != 200) {
      final result = jsonDecode(response.body);
      throw Exception(result['message'] ?? 'Gagal menghapus perangkat');
    }
  }

  Future<bool> checkDeviceExists(String deviceId) async {
    final url = Uri.parse(ApiEndpoints.checkDevice(deviceId));
    final response = await http.get(url);
    return response.statusCode == 200;
  }

  // =========================================================
  // SCHEDULE
  // =========================================================

  Future<Map<String, dynamic>> getSchedule(String deviceId) async {
    try {
      final url = Uri.parse(ApiEndpoints.getSchedule(deviceId));
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        Map<String, dynamic> rawData =
            (decoded is Map && decoded.containsKey('data'))
            ? Map<String, dynamic>.from(decoded['data'])
            : Map<String, dynamic>.from(decoded);

        // Tangani times yang masih berupa JSON string (format lama)
        if (rawData.containsKey('times') && rawData['times'] is String) {
          try {
            final parsedTimes = jsonDecode(rawData['times']);
            if (parsedTimes is Map && parsedTimes.containsKey('times')) {
              rawData['times'] = parsedTimes['times'];
            } else {
              rawData['times'] = parsedTimes;
            }
          } catch (_) {}
        }

        // Normalisasi SEMUA format times ke List<String> "HH:mm|portion"
        rawData['times'] = _normalizeTimesToStrings(rawData['times']);
        return rawData;
      }
      return {'times': <String>[]};
    } catch (e) {
      debugPrint('API Error Fetch Schedule: $e');
      return {'times': <String>[]};
    }
  }

  /// Konversi times dari format apapun ke List<String> "HH:mm|portion"
  static List<String> _normalizeTimesToStrings(dynamic rawTimes) {
    if (rawTimes == null) return [];

    // Format baru: List of Map {time, portion, rotations}
    if (rawTimes is List) {
      final result = <String>[];
      for (final entry in rawTimes) {
        if (entry == null) continue;
        if (entry is Map) {
          final time    = (entry['time']    ?? '').toString().trim();
          final portion = (entry['portion'] ?? 'sedang').toString().trim();
          if (time.contains(':')) {
            result.add('$time|$portion');
          }
        } else {
          final s = entry.toString().trim();
          if (s.isEmpty) continue;
          if (s.contains('|')) {
            result.add(s);
          } else if (s.contains(':')) {
            result.add('$s|sedang');
          }
        }
      }
      return result;
    }

    // Format wrapper: {times: [...], portion: "..."}
    if (rawTimes is Map && rawTimes.containsKey('times')) {
      return _normalizeTimesToStrings(rawTimes['times']);
    }

    return [];
  }

  Future<void> updateSchedule(
    String deviceId,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse(ApiEndpoints.updateSchedule(deviceId));
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menyimpan jadwal di server');
    }
  }

  /// Kirim perintah pakan manual ke ESP32 via MQTT (melalui server)
  Future<void> triggerManualFeed(String deviceId, {String portion = 'sedang'}) async {
    final url = Uri.parse(ApiEndpoints.triggerFeed(deviceId));
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'portion': portion}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Gagal memicu pakan');
    }
  }

  // =========================================================
  // BARNS
  // =========================================================

  Future<List<dynamic>> getBarns(String userId) async {
    try {
      final url = Uri.parse(ApiEndpoints.getBarns(userId));
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getBarnDetail(String barnId) async {
    try {
      final url = Uri.parse(ApiEndpoints.getBarnDetail(barnId));
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? {};
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> createBarn(
    Map<String, dynamic> barnData,
  ) async {
    try {
      final url = Uri.parse(ApiEndpoints.createBarn);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(barnData),
      );
      final result = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return result['data'] ?? result;
      }
      throw Exception(result['message'] ?? 'Gagal membuat kandang');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateBarn(
    String barnId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final url = Uri.parse(ApiEndpoints.updateBarn(barnId));
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );
      final result = jsonDecode(response.body);
      if (response.statusCode == 200) return result['data'] ?? result;
      throw Exception(result['message'] ?? 'Gagal update kandang');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // =========================================================
  // BARN FINANCES
  // =========================================================

  Future<Map<String, dynamic>> getBarnFinances(String barnId) async {
    try {
      final url = Uri.parse(ApiEndpoints.getBarnFinances(barnId));
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> addBarnFinance(
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse(ApiEndpoints.addBarnFinance);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      
      try {
        final result = jsonDecode(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          return result['data'] ?? result;
        }
        throw Exception(result['message'] ?? 'Gagal mencatat keuangan');
      } catch (e) {
        throw Exception('Server mengembalikan error (Status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // =========================================================
  // BARN FEED LOGS
  // =========================================================

  Future<List<dynamic>> getBarnFeedLogs(String barnId) async {
    try {
      final url = Uri.parse(ApiEndpoints.getBarnFeedLogs(barnId));
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> addBarnFeedLog(
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse(ApiEndpoints.addBarnFeedLog);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      final result = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return result['data'] ?? result;
      }
      throw Exception(result['message'] ?? 'Gagal mencatat pakan');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // =========================================================
  // NOTIFICATIONS
  // =========================================================

  Future<List<dynamic>> getNotifications(String userId) async {
    try {
      final url = Uri.parse(ApiEndpoints.getNotifications(userId));
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> markNotificationRead(String notifId) async {
    try {
      final url = Uri.parse(ApiEndpoints.markNotificationRead(notifId));
      await http.patch(url, headers: {'Content-Type': 'application/json'});
    } catch (e) {
      // Ignore silently
    }
  }

  // =========================================================
  // SUBSCRIPTION
  // =========================================================

  Future<List<dynamic>> getMySubscription(String userId) async {
    try {
      final url = Uri.parse(ApiEndpoints.getMySubscription(userId));
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // =========================================================
  // GENERAL POST
  // =========================================================

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return await compute(_parseJsonMap, response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      throw Exception('Error API: $e');
    }
  }

  // =========================================================
  // WEATHER
  // =========================================================

  Future<Map<String, dynamic>> getWeatherForecast({
    required String latitude,
    required String longitude,
  }) async {
    final url = Uri.parse(
      ApiEndpoints.weatherForecast(latitude, longitude),
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return await compute(_parseJsonMap, response.body);
      }
      throw Exception('Gagal memuat cuaca dari server');
    } catch (e) {
      throw Exception('Weather Error: $e');
    }
  }

  Future<Map<String, dynamic>?> geocodeCity(String city) async {
    try {
      final url = Uri.parse(ApiEndpoints.geocodeCity(city));
      final response = await http.get(
        url,
        headers: {'User-Agent': 'IoTernak-App/1.0'},
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body);
        if (list is List && list.isNotEmpty) {
          return {
            'lat': list[0]['lat'],
            'lon': list[0]['lon'],
            'display_name': list[0]['display_name'],
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
