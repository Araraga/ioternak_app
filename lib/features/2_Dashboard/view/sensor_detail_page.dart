import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../2_dashboard/widgets/sensor_error.dart';
import '../../2_dashboard/widgets/amonia_chart.dart';
import '../cubit/sensor_data_cubit.dart';
import '../cubit/sensor_data_state.dart';

class SensorDetailPage extends StatelessWidget {
  const SensorDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SensorDataCubit(
        apiService: context.read<ApiService>(),
        storageService: context.read<StorageService>(),
      )..fetchSensorData(),
      child: const SensorDetailView(),
    );
  }
}

class SensorDetailView extends StatelessWidget {
  const SensorDetailView({super.key});

  void _deleteDevice(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Sensor?"),
        content: const Text(
          "Alat akan dihapus dari akun Anda. Anda harus mengklaim ulang jika ingin menggunakannya lagi.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final storage = context.read<StorageService>();
                final api = context.read<ApiService>();

                final deviceId = storage.getSensorId();
                final userId = storage.getUserIdFromDB();

                if (deviceId != null && userId != null) {
                  await api.releaseDevice(deviceId, userId);
                }

                await storage.clearSensorId();

                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Sensor berhasil dihapus."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Gagal: ${e.toString().replaceAll('Exception:', '')}",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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
                fontSize: 24,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Ioternak Smart Sensor',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.statusDanger,
            ),
            tooltip: "Hapus Alat",
            onPressed: () => _deleteDevice(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<SensorDataCubit, SensorDataState>(
        builder: (context, state) {
          if (state is SensorDataLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is SensorDataError) {
            return Center(
              child: SensorErrorWidget(
                message: state.message,
                onRetry: () =>
                    context.read<SensorDataCubit>().fetchSensorData(),
              ),
            );
          }

          if (state is SensorDataLoaded) {
            final sensorDataList = state.sensorDataList;
            final latestData = sensorDataList.isNotEmpty
                ? sensorDataList.first as Map<String, dynamic>? ?? {}
                : {};

            final rawGas = latestData['amonia'] ?? latestData['gas_ppm'];
            final ammoniaStr = _formatValue(rawGas, 1);
            final tempStr = _formatValue(latestData['temperature'], 1);
            final humStr = _formatValue(latestData['humidity'], 0);

            double gasVal = double.tryParse(ammoniaStr) ?? 0;
            double tempVal = double.tryParse(tempStr) ?? 0;

            bool isSafe = (gasVal < 20.0) && (tempVal < 33.0);
            String statusText = isSafe
                ? "Kondisi Kandang BAIK"
                : "Kondisi Kandang BURUK";
            Color statusColor = isSafe
                ? AppColors.statusGood
                : AppColors.statusDanger;
            IconData statusIcon = isSafe
                ? Icons.sentiment_very_satisfied
                : Icons.sentiment_very_dissatisfied;

            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).padding.top + kToolbarHeight,
                  ),

                  Center(
                    child: Container(
                      height: 130,
                      margin: const EdgeInsets.only(bottom: 16, top: 10),
                      child: Image.asset(
                        'assets/images/alatsensor.png',
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.sensors,
                          size: 80,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSensorInfo(
                          icon: Icons.cloud_outlined,
                          label: 'Gas',
                          value: ammoniaStr,
                          unit: ' PPM',
                          color: AppColors.statusDanger,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey.withOpacity(0.2),
                        ),
                        _buildSensorInfo(
                          icon: Icons.thermostat,
                          label: 'Suhu',
                          value: tempStr,
                          unit: '°C',
                          color: AppColors.statusWarning,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey.withOpacity(0.2),
                        ),
                        _buildSensorInfo(
                          icon: Icons.opacity,
                          label: 'Lembap',
                          value: humStr,
                          unit: '%',
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(statusIcon, size: 80, color: statusColor),
                        const SizedBox(height: 16),
                        Text(
                          statusText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Berdasarkan parameter suhu, kelembapan, & gas",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
