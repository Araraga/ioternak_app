import 'package:bloc/bloc.dart';
import 'weather_state.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class WeatherCubit extends Cubit<WeatherState> {
  final ApiService _apiService;
  final StorageService? _storage;

  WeatherCubit({required ApiService apiService, StorageService? storage})
    : _apiService = apiService,
      _storage = storage,
      super(WeatherInitial());

  Future<void> fetchWeather({
    String? latitude,
    String? longitude,
  }) async {
    try {
      emit(WeatherLoading());

      String lat = latitude ?? '';
      String lon = longitude ?? '';

      final storage = _storage; // local non-null alias

      // 1. Coba ambil koordinat tersimpan
      if (lat.isEmpty && storage != null) {
        lat = storage.getWeatherLat() ?? '';
        lon = storage.getWeatherLon() ?? '';
      }

      // 2. Fallback geocode dari kota user
      if (lat.isEmpty && storage != null) {
        final city = storage.getUserCity() ?? storage.getUserProvince();
        if (city != null && city.isNotEmpty) {
          final geo = await _apiService.geocodeCity(city);
          if (geo != null) {
            lat = geo['lat'].toString();
            lon = geo['lon'].toString();
            await storage.saveWeatherLocation(lat, lon);
          }
        }
      }

      // 3. Fallback ke Jawa Tengah (tengah Indonesia)
      if (lat.isEmpty) {
        lat = '-7.2575';
        lon = '110.4275';
      }

      final response = await _apiService.getWeatherForecast(
        latitude: lat,
        longitude: lon,
      );

      final current = response['current_weather'] ?? {};
      final forecast = <Map<String, dynamic>>[];

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

      emit(
        WeatherLoaded(
          current: Map<String, dynamic>.from(current),
          forecast: forecast,
          latitude: lat,
          longitude: lon,
        ),
      );
    } catch (e) {
      emit(WeatherError('Tidak dapat memuat cuaca: $e'));
    }
  }
}
