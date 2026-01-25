import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../cubit/sensor_data_cubit.dart';
import '../cubit/sensor_data_state.dart';
import '../cubit/dashboard_cubit.dart';
import '../view/sensor_detail_page.dart';
import 'sensor_error.dart';

class SensorCard extends StatelessWidget {
  const SensorCard({super.key});

  String _formatValue(dynamic value, int decimalPlaces) {
    if (value == null) return '--';
    if (value is num) return value.toStringAsFixed(decimalPlaces);
    if (value is String) {
      final number = double.tryParse(value);
      if (number != null) return number.toStringAsFixed(decimalPlaces);
    }
    return '--';
  }

  Widget _buildSensorInfo({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SensorDataCubit(
        apiService: context.read<ApiService>(),
        storageService: context.read<StorageService>(),
      )..fetchSensorData(), // <--- PERBAIKAN 1: Panggil fetch data di sini!

      child: Card(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SensorDetailPage()),
            ).then((_) async {
              if (context.mounted) {
                context.read<DashboardCubit>().checkDevices();
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BlocBuilder<SensorDataCubit, SensorDataState>(
              builder: (context, state) {
                if (state is SensorDataLoading || state is SensorDataInitial) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }

                if (state is SensorDataError) {
                  return SensorErrorWidget(
                    message: "${state.message}\nCek ID perangkat Anda.",
                    onRetry: () =>
                        context.read<SensorDataCubit>().fetchSensorData(),
                  );
                }

                if (state is SensorDataLoaded) {
                  final List<dynamic> sensorDataList = state.sensorDataList;

                  // Ambil data pertama (Terbaru) karena API sort DESC
                  final Map<String, dynamic> latestData =
                      sensorDataList.isNotEmpty
                      ? sensorDataList.first as Map<String, dynamic>? ?? {}
                      : {};

                  // Handle 'amonia' dari backend atau 'gas_ppm'
                  final rawGas = latestData['amonia'] ?? latestData['gas_ppm'];
                  final ammonia = _formatValue(rawGas, 1);
                  final temperature = _formatValue(
                    latestData['temperature'],
                    1,
                  );
                  final humidity = _formatValue(latestData['humidity'], 0);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'IoTernak Smart Sensor',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSensorInfo(
                            icon: Icons.cloud_outlined,
                            label: 'Gas',
                            value: ammonia,
                            unit: ' PPM',
                            color: AppColors.statusDanger,
                          ),
                          Container(
                            height: 50,
                            width: 1,
                            color: AppColors.textSecondary.withOpacity(0.2),
                          ),
                          _buildSensorInfo(
                            icon: Icons.thermostat,
                            label: 'Suhu',
                            value: temperature,
                            unit: '°C',
                            color: AppColors.statusWarning,
                          ),
                          Container(
                            height: 50,
                            width: 1,
                            color: AppColors.textSecondary.withOpacity(0.2),
                          ),
                          _buildSensorInfo(
                            icon: Icons.opacity,
                            label: 'Lembap',
                            value: humidity,
                            unit: '%',
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}
