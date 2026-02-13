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
      final storage = context.read<StorageService>();
      final api = context.read<ApiService>();

      final userId = storage.getUserIdFromDB();
      final userPhone = storage.getUserPhone();

      if (userId == null || userPhone == null) {
        throw Exception("Sesi login kadaluarsa. Silakan logout & login ulang.");
      }

      final result = await api.claimDevice(kode, userId, userPhone);

      final String type = result['type'] ?? 'unknown';

      if (type == 'sensor') {
        await storage.saveSensorId(kode);
      } else if (type == 'feeder') {
        await storage.savePakanId(kode);
      } else {
        if (kode.startsWith('SENSOR')) await storage.saveSensorId(kode);
        if (kode.startsWith('PAKAN')) await storage.savePakanId(kode);
      }

      isSuccess = true;
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception:", "").trim();
    }

    if (!mounted) return;

    if (isSuccess) {
      _showSuccessDialog();
    } else {
      _showErrorDialog(errorMessage ?? 'Gagal menambahkan perangkat.');
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
          style: TextStyle(color: AppColors.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.primary,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Perangkat berhasil diklaim & ditambahkan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
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
          style: TextStyle(color: AppColors.statusDanger),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.statusDanger,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
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
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tambah Perangkat',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24.0,
            MediaQuery.of(context).padding.top + kToolbarHeight + 20,
            24.0,
            24.0,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code,
                  size: 80,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Klaim Perangkat',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Masukkan ID perangkat yang terdapat pada kertas dalam paket pembelian.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _kodeUnikController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'ID Perangkat',
                    hintText: 'Cth: SENSOR-A1B2C3',
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.vpn_key,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'ID tidak boleh kosong' : null,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 32,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _tambahPerangkat,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Tambahkan Perangkat',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
