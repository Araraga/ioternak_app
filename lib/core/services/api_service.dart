import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';

class ApiService {
  /// --- 1. REQUEST OTP (Langkah Awal Register) ---
  /// Mengirim request ke backend. Backend akan cek:
  /// - Jika nomor sudah ada -> Error 400 (Kita tangkap exceptionnya)
  /// - Jika nomor baru -> Kirim WA & Return 200 (Kita return true)
  Future<bool> requestOtp(String phone) async {
    final url = Uri.parse(ApiEndpoints.requestOtp);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'phone': phone}),
      );

      final body = jsonDecode(response.body);

      // Backend mengembalikan 200 jika sukses kirim WA
      if (response.statusCode == 200) {
        return true;
      } else {
        // [PENTING] Jika error (misal: "Nomor sudah terdaftar"),
        // kita lempar Exception agar bisa ditangkap di UI (RegisterPage)
        throw Exception(body['message'] ?? "Gagal memproses permintaan.");
      }
    } catch (e) {
      // Rethrow agar UI tahu ada error dan bisa menampilkan SnackBar
      rethrow;
    }
  }

  /// --- 2. REGISTER USER (Langkah Akhir dengan OTP) ---
  /// Verifikasi OTP dan Simpan User Baru (Tanpa Password)
  Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String phone,
    required String otp,
  }) async {
    final url = Uri.parse(ApiEndpoints.registerUser);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'full_name': fullName,
          'phone': phone,
          'otp': otp, // Backend butuh ini untuk validasi akhir
        }),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return result; // Mengembalikan data user (termasuk user_id)
      } else {
        throw Exception(
          result['message'] ?? 'Gagal Registrasi: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error Koneksi Register: $e');
    }
  }

  /// --- LOGIN USER ---
  Future<Map<String, dynamic>> loginUser(String phone) async {
    final url = Uri.parse(ApiEndpoints.loginUser);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return result;
      } else if (response.statusCode == 404) {
        throw Exception("Nomor belum terdaftar. Silakan daftar akun baru.");
      } else {
        throw Exception(result['message'] ?? 'Gagal Login');
      }
    } catch (e) {
      throw Exception('Error Koneksi Login: $e');
    }
  }

  /// --- FITUR AI CHAT (POST Generik) ---
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
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Gagal memuat data AI');
      }
    } catch (e) {
      throw Exception('Error AI: $e');
    }
  }

  /// --- DEVICE MANAGEMENT & SENSORS ---

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
    // Jika jadwal belum ada, return default daripada error
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
    if (response.statusCode == 200) {
      return result;
    } else {
      throw Exception(result['message'] ?? "Gagal klaim alat");
    }
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
