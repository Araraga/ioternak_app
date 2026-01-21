import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Akses ke ApiService
import 'package:flutter/services.dart'; // Untuk format input nomor HP
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'verification_page.dart'; // Pastikan file ini ada (halaman input OTP)

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller Input Data
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- LOGIKA UTAMA: TOMBOL DAFTAR ---
  void _handleDaftarButton() async {
    // 1. Cek validitas form UI
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final api = context.read<ApiService>();

      // 2. Request OTP ke Backend
      // Jika nomor sudah terdaftar, ApiService akan melempar Exception error
      final isSent = await api.requestOtp(_phoneController.text.trim());

      if (isSent) {
        if (!mounted) return;

        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kode OTP berhasil dikirim ke WhatsApp!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // 3. Pindah ke Halaman Verifikasi (Hanya jika sukses kirim OTP)
        // Kita bawa data Nama & HP untuk disimpan nanti setelah verifikasi OTP selesai
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationPage(
              fullName: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Bersihkan pesan error dari teks "Exception:" agar lebih rapi
      String errorMessage = e.toString().replaceAll("Exception:", "").trim();

      // Tampilkan Error (Misal: "Nomor ini sudah terdaftar")
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4), // Tampil agak lama biar terbaca
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background, // Pastikan warna ini ada di constants Anda
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- LOGO APLIKASI ---
                SizedBox(
                  height: 100,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => const Icon(
                      Icons.image_not_supported,
                      size: 80,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- HEADER TEKS ---
                const Text(
                  "Buat Akun Baru",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Lengkapi data diri Anda untuk mendaftar.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 40),

                // --- INPUT NAMA ---
                TextFormField(
                  controller: _nameController,
                  textCapitalization:
                      TextCapitalization.words, // Kapital tiap kata
                  decoration: InputDecoration(
                    labelText: "Nama Lengkap",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? "Nama wajib diisi" : null,
                ),
                const SizedBox(height: 20),

                // --- INPUT NOMOR HP ---
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ], // Hanya angka
                  decoration: InputDecoration(
                    labelText: "Nomor WhatsApp",
                    hintText: "Contoh: 08123456789",
                    prefixIcon: const Icon(Icons.phone_android),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: "Pastikan nomor aktif di WhatsApp",
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Nomor wajib diisi";
                    if (v.length < 10)
                      return "Nomor tidak valid (min 10 digit)";
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                // --- TOMBOL LANJUT ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleDaftarButton,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text(
                          "Lanjut Verifikasi",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),

                const SizedBox(height: 20),

                // --- LINK MASUK (LOGIN) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Sudah punya akun? ",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pop(context), // Kembali ke Login Page
                      child: const Text(
                        "Masuk",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
