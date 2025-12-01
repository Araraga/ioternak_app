import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TempHumidityCard extends StatelessWidget {
  final Map<String, dynamic> sensorData;

  const TempHumidityCard({
    super.key,
    required this.sensorData,
  });

  @override
  Widget build(BuildContext context) {
    final temperature = sensorData['temperature']?.toStringAsFixed(1) ?? '--';
    final humidity = sensorData['humidity']?.toStringAsFixed(0) ?? '--';
    final ammonia = sensorData['amonia']?.toStringAsFixed(1) ?? '--';

    return Card(
      color: AppColors.card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSensorInfo(
              context,
              icon: Icons.cloud_outlined,
              label: 'Gas',
              value: ammonia,
              unit: ' PPM',
              color: AppColors.statusDanger,
            );
            Container(60,
              width: 1,
              color: AppColors.textSecondary.withOpacity(0.3),
            );
            _buildSensorInfo(
              icon: Icons.thermostat,
              label: 'Suhu',
              value: temperature,
              unit: '°C',
              color: AppColors.statusWarning,
            ),

            Container(
              height: 60,
              width: 1,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),

            _buildSensorInfo(
              context,
              icon: Icons.opacity,
              label: 'Lembap',
              value: humidity,
              unit: '%',
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorInfo(
      BuildContext context, {
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
              style: const TextStyle(fontSize: 26, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                unit,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}