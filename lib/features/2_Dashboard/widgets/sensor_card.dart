import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/glass_container.dart';
import '../cubit/sensor_data_cubit.dart';
import '../cubit/sensor_data_state.dart';
import '../view/sensor_detail_page.dart';

class SensorCard extends StatelessWidget {
  const SensorCard({super.key});

  String _fmt(dynamic value, int dec) {
    if (value == null) return '--';
    if (value is num) return value.toStringAsFixed(dec);
    final n = double.tryParse(value.toString());
    return n != null ? n.toStringAsFixed(dec) : '--';
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Color _tempColor(double? t) {
    if (t == null) return AppColors.statusWarning;
    if (t > 35) return AppColors.statusDanger;
    if (t > 32) return AppColors.statusWarning;
    return AppColors.statusGood;
  }

  Color _humColor(double? h) {
    if (h == null) return AppColors.statusInfo;
    if (h > 80) return AppColors.statusDanger;
    if (h < 40) return AppColors.statusWarning;
    return AppColors.statusInfo;
  }

  Color _gasColor(double? g) {
    if (g == null) return AppColors.statusGood;
    if (g > 25) return AppColors.statusDanger;
    if (g > 15) return AppColors.statusWarning;
    return AppColors.statusGood;
  }

  String _tempStatus(double? t) {
    if (t == null) return 'N/A';
    if (t > 35) return 'Panas!';
    if (t > 32) return 'Hangat';
    return 'Normal';
  }

  String _gasStatus(double? g) {
    if (g == null) return 'N/A';
    if (g > 25) return 'Bahaya';
    if (g > 15) return 'Waspada';
    return 'Aman';
  }

  @override
  Widget build(BuildContext context) {
    // SensorCard gets SensorDataCubit from ancestor (HomePage provides it)
    // but we wrap with a fresh one here for the card's own lifecycle
    return BlocProvider(
      create: (context) => SensorDataCubit(
        apiService: context.read<ApiService>(),
        storageService: context.read<StorageService>(),
      )..fetchSensorData(),
      child: BlocBuilder<SensorDataCubit, SensorDataState>(
        builder: (context, state) {
          Map<String, dynamic> data = {};
          bool isLoading = false;

          if (state is SensorDataLoading || state is SensorDataInitial) {
            isLoading = true;
          } else if (state is SensorDataLoaded && state.sensorDataList.isNotEmpty) {
            data = state.sensorDataList.first as Map<String, dynamic>? ?? {};
          }

          final rawGas = data['amonia'] ?? data['gas_ppm'];
          final temp = _toDouble(data['temperature']);
          final hum = _toDouble(data['humidity']);
          final gas = _toDouble(rawGas);

          final tempVal = _fmt(data['temperature'], 1);
          final humVal = _fmt(data['humidity'], 0);
          final gasVal = _fmt(rawGas, 1);

          final isError = state is SensorDataError;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SensorDetailPage()),
              );
            },
            child: GlassContainer(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.sensors_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IoPeka',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Sensor Lingkungan Kandang',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isError
                              ? AppColors.statusDanger.withAlpha(20)
                              : AppColors.statusGood.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isError
                                ? AppColors.statusDanger.withAlpha(60)
                                : AppColors.statusGood.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isError
                                    ? AppColors.statusDanger
                                    : AppColors.statusGood,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isError ? 'Offline' : 'Live',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isError
                                    ? AppColors.statusDanger
                                    : AppColors.statusGood,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                      ),
                    )
                  else if (isError)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: AppColors.statusWarning, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (state as SensorDataError).message,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricTile(
                          icon: Icons.thermostat_rounded,
                          label: 'Suhu',
                          value: tempVal,
                          unit: '°C',
                          color: _tempColor(temp),
                          status: _tempStatus(temp),
                        ),
                        _divider(),
                        _metricTile(
                          icon: Icons.water_drop_rounded,
                          label: 'Kelembapan',
                          value: humVal,
                          unit: '%',
                          color: _humColor(hum),
                          status: hum != null
                              ? (hum > 80
                                  ? 'Lembab!'
                                  : hum < 40 ? 'Kering' : 'Normal')
                              : 'N/A',
                        ),
                        _divider(),
                        _metricTile(
                          icon: Icons.cloud_rounded,
                          label: 'Amonia',
                          value: gasVal,
                          unit: 'PPM',
                          color: _gasColor(gas),
                          status: _gasStatus(gas),
                        ),
                      ],
                    ),

                  const SizedBox(height: 14),

                  // Tap for detail hint
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Lihat detail →',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _divider() => Container(
    height: 56,
    width: 1,
    color: AppColors.textSecondary.withAlpha(25),
  );

  Widget _metricTile({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    required String status,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: '\n$unit',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
