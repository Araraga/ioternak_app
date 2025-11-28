import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart';

class ProvisionPage extends StatefulWidget {
  const ProvisionPage({super.key});

  @override
  State<ProvisionPage> createState() => _ProvisionPageState();
}

class _ProvisionPageState extends State<ProvisionPage> {
  final _formKey = GlobalKey<FormState>();
  final _kodeUnikController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _kodeUnikController.dispose();
    super.dispose();
  }

  Future<void> _tambahPerangkat() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final String kode = _kodeUnikController.text.trim().toUpperCase();
    String? errorMessage;
    bool isSuccess = false;

    try {
      final apiService = context.read<ApiService>();
      final storageService = context.read<StorageService>();
      final bool deviceExists = await apiService.checkDeviceExists(kode);

      if (deviceExists) {
        if (kode.startsWith('SENSOR-')) {
          await storageService.saveSensorId(kode);
        } else if (kode.startsWith('PAKAN-')) {
          await storageService.savePakanId(kode);
        }
        isSuccess = true;
      } else {
        errorMessage = 'Perangkat dengan ID "$kode" tidak ditemukan di server.';
      }
    } catch (e) {
      errorMessage = 'Gagal terhubung ke server: $e';
    }

    if (!mounted) return;

    if (isSuccess) {
      _showSuccessDialog();
    } else {
      _showErrorDialog(errorMessage ?? 'Terjadi kesalahan tidak diketahui.');
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
            'Berhasil!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.primary)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 60),
            const SizedBox(height: 16),
            Text(
                'Perangkat berhasil ditambahkan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary)
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
            'Gagal',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.statusDanger)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.statusDanger, size: 60),
            const SizedBox(height: 16),
            Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary)
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah Perangkat Baru',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.primary,
        ),
        backgroundColor: AppColors.card,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.devices_other_outlined,
                  size: 80,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Masukkan Kode Unik',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Masukkan kode yang tertera pada stiker perangkat Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _kodeUnikController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Kode Unik Perangkat',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    hintText: 'Cth: SENSOR-A1B2C3',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.qr_code_scanner, color: AppColors.textSecondary),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kode tidak boleh kosong';
                    }
                    if (!value.startsWith('SENSOR-') && !value.startsWith('PAKAN-')) {
                      return 'Format salah (Harus SENSOR- atau PAKAN-)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _tambahPerangkat,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Tambahkan Perangkat', style: TextStyle(color: AppColors.card, fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}