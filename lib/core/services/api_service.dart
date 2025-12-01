import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/api_endpoints.dart';

class ApiService {
  Future<dynamic> getSensorData(String deviceId) async {
    try {
      final url = Uri.parse(ApiEndpoints.getSensorData(deviceId));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal memuat data sensor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error Jaringan: $e');
    }
  }

  Future<dynamic> getSchedule(String deviceId) async {
    try {
      final url = Uri.parse(ApiEndpoints.getSchedule(deviceId));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal memuat jadwal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error Jaringan: $e');
    }
  }

  Future<void> updateSchedule(String deviceId, Map<String, dynamic> scheduleData) async {
    try {
      final url = Uri.parse(ApiEndpoints.updateSchedule(deviceId));

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(scheduleData),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal memperbarui jadwal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error Jaringan: $e');
    }
  }

  Future<bool> checkDeviceExists(String deviceId) async {
    try {
      final url = Uri.parse(ApiEndpoints.checkDevice(deviceId));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        return false;
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error Jaringan: $e');
    }
  }
}