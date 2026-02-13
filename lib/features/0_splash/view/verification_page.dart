import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart'; // Import Pinput dari Tornike
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../2_dashboard/view/home_page.dart';

class VerificationPage extends StatefulWidget {
  final String fullName;
  final String phone;

  const VerificationPage({
    super.key,
    required this.fullName,
    required this.phone,
  });

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _verifyOtp(String otpCode) async {
    if (otpCode.length < 6) return;

    setState(() => _isLoading = true);

    try {
      final api = context.read<ApiService>();
      final storage = context.read<StorageService>();

      final result = await api.registerUser(
        fullName: widget.fullName,
        phone: widget.phone,
        otp: otpCode,
      );

      final userIdDB = result['user']['user_id'].toString();

      await storage.saveUserProfile(widget.fullName, widget.phone);
      await storage.saveUserIdFromDB(userIdDB);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Verifikasi Gagal: ${e.toString().replaceAll("Exception:", "")}",
          ),
          backgroundColor: Colors.red,
        ),
      );
      _otpController.clear();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Color.fromRGBO(30, 60, 87, 1),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade100,
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(
        color: AppColors.primary,
      ),
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: const Color.fromRGBO(234, 239, 243, 1),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              "Verifikasi OTP",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Masukkan kode 6 digit yang dikirim ke\n${widget.phone}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            Pinput(
              length: 6,
              controller: _otpController,
              focusNode: _focusNode,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              submittedPinTheme: submittedPinTheme,
              showCursor: true,
              onCompleted: (pin) {
                _verifyOtp(pin);
              },
            ),

            // ---------------------------
            const SizedBox(height: 40),

            if (_isLoading)
              const CircularProgressIndicator(color: AppColors.primary)
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _verifyOtp(_otpController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Verifikasi",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),

            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Fitur Kirim Ulang belum diaktifkan (tunggu 5 menit)",
                    ),
                  ),
                );
              },
              child: const Text(
                "Kirim Ulang Kode?",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
