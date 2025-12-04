import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';

class ApiService {
  Future<dynamic> getSensorData(String deviceId) async {
    final url = Uri.parse(ApiEndpoints.getSensorData(deviceId));
    final response = await http.get(url);

    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Gagal memuat data sensor');
  }

  Future<dynamic> getSchedule(String deviceId) async {
    final url = Uri.parse(ApiEndpoints.getSchedule(deviceId));
    final response = await http.get(url);

    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Gagal memuat jadwal');
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

  Future<Map<String, dynamic>> registerUser(String name, String phone) async {
    final url = Uri.parse(ApiEndpoints.registerUser);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'phone': phone}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal Registrasi: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> loginUser(String phone) async {
    final url = Uri.parse(ApiEndpoints.loginUser);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );

    final result = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return result;
    } else if (response.statusCode == 404) {
      throw Exception("Nomor belum terdaftar. Silakan registrasi akun baru.");
    } else {
      throw Exception('Gagal Login: ${response.statusCode}');
    }
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

    if (response.statusCode == 200) {
      return result;
    } else if (response.statusCode == 403) {
      throw Exception("ALAT SUDAH DIMILIKI ORANG LAIN!");
    } else if (response.statusCode == 404) {
      throw Exception("ID Alat tidak ditemukan. Pastikan alat sudah menyala.");
    } else {
      throw Exception('Server Error: ${response.statusCode}');
    }
  }

  Future<void> releaseDevice(String deviceId, String userId) async {
    final url = Uri.parse(ApiEndpoints.releaseDevice);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_id': deviceId, 'user_id': userId}),
    );

    final result = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(result['message'] ?? 'Gagal menghapus perangkat');
    }
  }

  Future<bool> checkDeviceExists(String deviceId) async {
    final url = Uri.parse(ApiEndpoints.checkDevice(deviceId));
    final response = await http.get(url);

    if (response.statusCode == 200) return true;
    if (response.statusCode == 404) return false;
    throw Exception('Server Error: ${response.statusCode}');
  }
}
