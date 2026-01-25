import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../constants/api_endpoints.dart';

class ApiService {
  // ===============================================================
  // 1. LOGIKA PROSES DATA (HYBRID: REALTIME + AVERAGE)
  // ===============================================================
  static List<Map<String, dynamic>> _processSensorData(String responseBody) {
    final decoded = jsonDecode(responseBody);
    List<dynamic> fullList = [];

    // A. Normalisasi Struktur JSON
    if (decoded is List) {
      fullList = decoded;
    } else if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      fullList = decoded['data'] as List<dynamic>;
    }

    if (fullList.isEmpty) return [];

    // B. AMBIL DATA REALTIME TERAKHIR (Data Paling Ujung)
    // Asumsi: Server mengirim data urut ASC (Lama -> Baru), jadi .last adalah terbaru
    var latestRaw = fullList.last;

    // Parsing Nilai Realtime (Untuk ditampilkan di Gauge/Teks Utama)
    double latestGas =
        double.tryParse(
          (latestRaw['amonia'] ?? latestRaw['gas_ppm']).toString(),
        ) ??
        0.0;
    double latestTemp =
        double.tryParse(latestRaw['temperature'].toString()) ?? 0.0;
    double latestHum = double.tryParse(latestRaw['humidity'].toString()) ?? 0.0;
    String latestDateStr = latestRaw['timestamp'] ?? latestRaw['created_at'];

    // C. HITUNG RATA-RATA HARIAN (Untuk Grafik History)
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

    // D. SUSUN HASIL RATA-RATA
    List<Map<String, dynamic>> finalStats = [];
    var sortedKeys = gasMap.keys.toList()..sort();

    for (var key in sortedKeys) {
      var gList = gasMap[key]!;
      double avgGas = gList.reduce((a, b) => a + b) / gList.length;

      var tList = tempMap[key] ?? [];
      double avgTemp = tList.isNotEmpty
          ? tList.reduce((a, b) => a + b) / tList.length
          : 0.0;

      var hList = humMap[key] ?? [];
      double avgHum = hList.isNotEmpty
          ? hList.reduce((a, b) => a + b) / hList.length
          : 0.0;

      finalStats.add({
        'created_at': key,
        'timestamp': key,
        'amonia': avgGas, // Key standard UI
        'temperature': avgTemp, // Key standard UI
        'humidity': avgHum, // Key standard UI
        'gas': avgGas, // Key chart
        'temp': avgTemp, // Key chart
        'hum': avgHum, // Key chart
        'date': key,
      });
    }

    // E. BALIK URUTAN & INJECT REALTIME DATA
    // Kita balik (.reversed) agar Index 0 adalah Hari Ini (Terbaru)
    List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(
      finalStats.reversed,
    );

    if (result.isNotEmpty) {
      String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String dataKey = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.parse(latestDateStr));

      // Jika data terakhir di list adalah hari ini, TIMPA rata-ratanya dengan DATA REALTIME
      // Ini agar dashboard menampilkan angka saat ini, bukan rata-rata seharian
      if (result[0]['date'] == dataKey) {
        result[0]['amonia'] = latestGas;
        result[0]['temperature'] = latestTemp;
        result[0]['humidity'] = latestHum;
        // Update data chart juga agar titik terakhir akurat
        result[0]['gas'] = latestGas;
        result[0]['temp'] = latestTemp;
        result[0]['hum'] = latestHum;
      } else {
        // Jika list hari ini belum ada (misal data server hari kemarin semua),
        // Sisipkan data realtime di paling atas sebagai data baru
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

  // Parser helper sederhana
  static Map<String, dynamic> _parseJsonMap(String responseBody) {
    final result = jsonDecode(responseBody);
    return result is Map<String, dynamic> ? result : {};
  }

  // ===============================================================
  // 2. HTTP REQUEST METHODS
  // ===============================================================

  // GET SENSOR DATA (Memanggil fungsi Hybrid di atas)
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

  // POST DATA (Generic)
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

  // --- AUTH & USER MANAGEMENT ---

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
      throw Exception(body['message'] ?? "Gagal request OTP");
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
    if (response.statusCode == 404) throw Exception("Nomor belum terdaftar.");
    throw Exception(result['message'] ?? 'Gagal Login');
  }

  // --- DEVICE MANAGEMENT ---

  Future<List<dynamic>> getMyDevices(String userId) async {
    final url = Uri.parse(ApiEndpoints.getMyDevices(userId));
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<dynamic> getSchedule(String deviceId) async {
    final url = Uri.parse(ApiEndpoints.getSchedule(deviceId));
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {"times": []};
  }

  Future<void> updateSchedule(
    String deviceId,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse(ApiEndpoints.updateSchedule(deviceId));
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }

  Future<Map<String, dynamic>> claimDevice(
    String deviceId,
    String userId,
    String phone,
  ) async {
    final url = Uri.parse(ApiEndpoints.claimDevice);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'device_id': deviceId,
        'user_id': userId,
        'user_phone': phone,
      }),
    );
    final result = jsonDecode(response.body);
    if (response.statusCode == 200) return result;
    throw Exception(result['message'] ?? "Gagal klaim alat");
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
    if (response.statusCode == 200) return true;
    return false;
  }
}
