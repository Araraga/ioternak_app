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

class SensorDetailView extends StatefulWidget {
  const SensorDetailView({super.key});

  @override
  State<SensorDetailView> createState() => _SensorDetailViewState();
}

class _SensorDetailViewState extends State<SensorDetailView> {
  String _formatValue(dynamic value, int decimalPlaces) {
    if (value == null) return '--';
    if (value.toString().toLowerCase() == 'null') return '--';
    final number = double.tryParse(value.toString());
    if (number != null) {
      return number.toStringAsFixed(decimalPlaces);
    }
    return '--';
  }

  void _deleteDevice(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Sensor?"),
        content: const Text("Alat akan dihapus dari akun Anda."),
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
                  Navigator.pop(context); // Tutup loading
                  Navigator.pop(context); // Keluar halaman
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal: ${e.toString()}"),
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
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: false,

      appBar: AppBar(
        title: const Text(
          'Detail Sensor',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // 1. TOMBOL REFRESH DIHAPUS (Sesuai Permintaan)

          // 2. TOMBOL DELETE
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.statusDanger,
            ),
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

            double gasVal = double.tryParse(ammoniaStr) ?? 0.0;
            bool isSafe = (gasVal < 20.0);

            String statusText = isSafe ? "Kondisi Aman" : "Kondisi Buruk";
            Color statusColor = isSafe
                ? AppColors.statusGood
                : AppColors.statusDanger;
            IconData statusIcon = isSafe
                ? Icons.sentiment_very_satisfied
                : Icons.sentiment_very_dissatisfied;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  // IMAGE
                  Center(
                    child: Container(
                      height: 130,
                      margin: const EdgeInsets.only(bottom: 24),
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

                  // SENSOR VALUES CARD (TANPA SHADOW)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      // Ganti Shadow dengan Border tipis
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

                  // STATUS CARD (TANPA SHADOW)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      // Ganti Shadow dengan Border tipis
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(statusIcon, size: 60, color: statusColor),
                        const SizedBox(height: 12),
                        Text(
                          statusText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Indikator real-time",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CHART SECTION
                  if (sensorDataList.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Grafik Riwayat",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AmmoniaChart(sensorData: sensorDataList),
                      ],
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
      ),
    );
  }
}
