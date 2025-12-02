import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart'; // Warna kustom

class SensorErrorWidget extends StatelessWidget {
  /// Pesan error yang akan ditampilkan
  final String message;

  /// Fungsi yang akan dipanggil saat tombol 'Coba Lagi' ditekan
  final VoidCallback onRetry;

  const SensorErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ikon Error
            Icon(Icons.error_outline, color: AppColors.statusDanger, size: 64),
            const SizedBox(height: 24),

            // Judul Error
            const Text(
              'Gagal Memuat Data',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Pesan Error Detail
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Tombol Coba Lagi
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
