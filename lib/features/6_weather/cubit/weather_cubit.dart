import 'package:bloc/bloc.dart';
import 'weather_state.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/location_service.dart';

class WeatherCubit extends Cubit<WeatherState> {
  final ApiService _apiService;
  final StorageService? _storage;
  final LocationService _locationService;

  WeatherCubit({
    required ApiService apiService,
    StorageService? storage,
    LocationService? locationService,
  })  : _apiService = apiService,
        _storage = storage,
        _locationService = locationService ?? LocationService(),
        super(WeatherInitial());

  Future<void> fetchWeather({
    String? latitude,
    String? longitude,
    String? locationName,
    bool useGps = true,
  }) async {
    try {
      emit(WeatherLoading());

      String lat = latitude ?? '';
      String lon = longitude ?? '';
      String resolvedName = locationName ?? '';
      bool isGpsActive = false;
      final storage = _storage;

      // 1. Coba ambil GPS HP jika diizinkan & koordinat kosong
      if (lat.isEmpty && useGps) {
        final liveLoc = await _locationService.getDeviceLiveLocation();
        if (liveLoc != null) {
          lat = liveLoc.latitude.toString();
          lon = liveLoc.longitude.toString();
          resolvedName = liveLoc.formattedAddress;
          isGpsActive = true;
          if (storage != null) {
            await storage.saveWeatherLocation(lat, lon, resolvedName);
          }
        }
      }

      // 2. Coba ambil koordinat tersimpan
      if (lat.isEmpty && storage != null) {
        lat = storage.getWeatherLat() ?? '';
        lon = storage.getWeatherLon() ?? '';
        resolvedName = storage.getWeatherLocationName() ?? '';
      }

      // 3. Fallback geocode dari kota profil user
      if (lat.isEmpty && storage != null) {
        final city = storage.getUserCity() ?? storage.getUserProvince();
        if (city != null && city.isNotEmpty) {
          final geo = await _apiService.geocodeCity(city);
          if (geo != null) {
            lat = geo['lat'].toString();
            lon = geo['lon'].toString();
            resolvedName = geo['display_name'] ?? city;
            await storage.saveWeatherLocation(lat, lon, resolvedName);
          }
        }
      }

      // 4. Default fallback ke Sleman / Jateng
      if (lat.isEmpty) {
        lat = '-7.7156';
        lon = '110.3556';
        resolvedName = 'Sleman, D.I. Yogyakarta';
      }

      final response = await _apiService.getWeatherForecast(
        latitude: lat,
        longitude: lon,
      );

      final current = response['current_weather'] ?? {};
      final forecast = <Map<String, dynamic>>[];

      double? humidity;
      if (response['hourly'] != null &&
          response['hourly']['relativehumidity_2m'] is List) {
        final humList = response['hourly']['relativehumidity_2m'] as List;
        if (humList.isNotEmpty) {
          humidity = double.tryParse(humList[0].toString());
        }
      }

      double? windSpeed;
      if (current['windspeed'] != null) {
        windSpeed = double.tryParse(current['windspeed'].toString());
      }

      if (response['daily'] != null && response['daily']['time'] != null) {
        final days = response['daily']['time'] as List<dynamic>;
        final tempsMax =
            response['daily']['temperature_2m_max'] as List<dynamic>;
        final tempsMin =
            response['daily']['temperature_2m_min'] as List<dynamic>;
        final codes = response['daily']['weathercode'] as List<dynamic>;
        final precipitation =
            response['daily']['precipitation_sum'] as List<dynamic>? ?? [];
        final windMax =
            response['daily']['windspeed_10m_max'] as List<dynamic>? ?? [];

        for (var i = 0; i < days.length && i < 7; i++) {
          forecast.add({
            'date': days[i],
            'max': tempsMax[i],
            'min': tempsMin[i],
            'code': codes[i],
            'precipitation': precipitation.length > i ? precipitation[i] : 0,
            'windMax': windMax.length > i ? windMax[i] : 0,
          });
        }
      }

      final currentTemp = double.tryParse(current['temperature']?.toString() ?? '0') ?? 0.0;
      final advisory = _livestockAdvisory(currentTemp, humidity ?? 65.0);

      emit(
        WeatherLoaded(
          current: Map<String, dynamic>.from(current),
          forecast: forecast,
          latitude: lat,
          longitude: lon,
          locationName: resolvedName,
          isGps: isGpsActive,
          humidity: humidity,
          windSpeed: windSpeed,
          livestockAdvisory: advisory,
        ),
      );
    } catch (e) {
      emit(WeatherError('Tidak dapat memuat cuaca: $e'));
    }
  }

  Future<void> refreshWithGps() async => fetchWeather(useGps: true);

  Future<void> fetchWeatherForBarn({
    required double latitude,
    required double longitude,
    required String barnName,
  }) async =>
      fetchWeather(
        latitude: latitude.toString(),
        longitude: longitude.toString(),
        locationName: barnName,
        useGps: false,
      );

  String _livestockAdvisory(double temp, double hum) {
    if (temp >= 33.0) return '⚠️ Waspada Heat Stress! Suhu $temp°C tinggi. Hidupkan exhaust fan & sprayer air.';
    if (temp >= 30.0) return '⚡ Suhu hangat ($temp°C). Pastikan sirkulasi kipas aktif & air minum segar tercukupi.';
    if (temp < 20.0) return '❄️ Suhu dingin ($temp°C). Pastikan tirai tertutup rapat & pemanas aktif.';
    if (hum > 80.0) return '💧 Kelembaban tinggi (${hum.toInt()}%). Jaga sekam kering untuk cegah gas amonia.';
    return '🟢 Lingkungan kandang ideal ($temp°C, ${hum.toInt()}% RH). Pertumbuhan ternak prima.';
  }
}

