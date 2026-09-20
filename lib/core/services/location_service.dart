import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationDataResult {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String? city;
  final String? province;
  final double? accuracy;

  const LocationDataResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.city,
    this.province,
    this.accuracy,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Periksa dan minta izin GPS pada smartphone
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return false;
    }

    return true;
  }

  /// Ambil posisi GPS saat ini dengan akurasi tinggi dan fallback
  Future<Position?> getCurrentPosition({Duration timeout = const Duration(seconds: 12)}) async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: timeout,
      );
    } catch (e) {
      debugPrint('Error getting current position: $e. Falling back to last known.');
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Reverse geocode koordinat lat & lon menjadi alamat yang manusiawi
  Future<Map<String, String>> reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=id',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'IoTernak-App/1.0 (ioternak@poultry.local)'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final addr = data['address'] as Map<String, dynamic>? ?? {};
          
          final suburb = addr['suburb'] ?? addr['village'] ?? addr['neighbourhood'] ?? addr['quarter'] ?? '';
          final city = addr['city'] ?? addr['municipality'] ?? addr['regency'] ?? addr['county'] ?? addr['town'] ?? '';
          final state = addr['state'] ?? addr['province'] ?? '';

          List<String> parts = [];
          if (suburb.isNotEmpty) parts.add(suburb.toString());
          if (city.isNotEmpty) parts.add(city.toString());
          if (state.isNotEmpty && !parts.contains(state.toString())) parts.add(state.toString());

          final formatted = parts.isNotEmpty
              ? parts.join(', ')
              : (data['display_name'] ?? '$lat, $lon').toString();

          return {
            'formatted': formatted,
            'city': city.toString(),
            'province': state.toString(),
          };
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }

    return {
      'formatted': '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}',
      'city': '',
      'province': '',
    };
  }

  /// Ambil lokasi perangkat saat ini beserta alamat terbaca lengkap
  Future<LocationDataResult?> getDeviceLiveLocation() async {
    final pos = await getCurrentPosition();
    if (pos == null) return null;

    final geo = await reverseGeocode(pos.latitude, pos.longitude);

    return LocationDataResult(
      latitude: pos.latitude,
      longitude: pos.longitude,
      formattedAddress: geo['formatted'] ?? '${pos.latitude}, ${pos.longitude}',
      city: geo['city'],
      province: geo['province'],
      accuracy: pos.accuracy,
    );
  }
}
