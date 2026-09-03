import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/glass_container.dart';

class ProvisionPage extends StatefulWidget {
  const ProvisionPage({super.key});

  @override
  State<ProvisionPage> createState() => _ProvisionPageState();
}

class _ProvisionPageState extends State<ProvisionPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _kodeUnikController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _kodeUnikController.dispose();
    _animController.dispose();
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
        throw Exception('Sesi login kadaluarsa. Silakan logout & login ulang.');
      }

      final result = await api.claimDevice(kode, userId, userPhone);

      final String type = (result['type'] ?? 'unknown').toString().toLowerCase();

      if (type == 'sensor' || type == 'iopeka' || kode.startsWith('IOPEKA') || kode.startsWith('SENSOR')) {
        await storage.saveSensorId(kode);
      } else if (type == 'feeder' || type == 'iopakan' || kode.startsWith('PAKAN')) {
        await storage.savePakanId(kode);
      }

      isSuccess = true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception:', '').trim();
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (isSuccess) {
      _showSuccessDialog();
    } else {
      _showErrorDialog(errorMessage ?? 'Gagal menambahkan perangkat.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF1ABC9C)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Berhasil! 🎉',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Perangkat berhasil diklaim\ndan ditambahkan ke akun Anda.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop(true); // Return true to trigger refresh
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF1ABC9C)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        'Selesai',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.statusDanger.withOpacity(0.1),
                    ),
                    child: const Icon(Icons.error_outline_rounded,
                        color: AppColors.statusDanger, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal Menambahkan',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 28),
                      decoration: BoxDecoration(
                        color: AppColors.statusDanger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.statusDanger.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Coba Lagi',
                        style: GoogleFonts.inter(
                          color: AppColors.statusDanger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary, size: 16),
          ),
        ),
        title: Text(
          'Tambah Perangkat',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.homeBackground),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, topPad + kToolbarHeight + 16, 24, 40),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Hero illustration
                ScaleTransition(
                  scale: _scaleAnim,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(28),
                    borderRadius: BorderRadius.circular(28),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.15),
                                AppColors.liquidBlue.withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.sensors_rounded,
                            size: 52,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Klaim Perangkat',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Masukkan ID perangkat yang terdapat pada\nkartu dalam paket pembelian Anda.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Input form
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID Perangkat',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _kodeUnikController,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'cth: IOPEKA-A1B2C3',
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.textSecondary.withOpacity(0.4),
                            letterSpacing: 0,
                            fontWeight: FontWeight.normal,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.7),
                          prefixIcon: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: AppColors.primary,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'ID tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 12),
                      // Tips
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Format ID: IOPEKA-XXXXX atau PAKAN-XXXXX',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Submit button
                GestureDetector(
                  onTap: _isLoading ? null : _tambahPerangkat,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: _isLoading
                          ? LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.5),
                                Colors.grey.shade400,
                              ],
                            )
                          : const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF1ABC9C)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _isLoading
                          ? []
                          : [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_circle_outline,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'Tambahkan Perangkat',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
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
