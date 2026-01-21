import 'package:flutter/material.dart';

// Import Services
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';

// Import App View
import 'app_view.dart';

// Import Pages
import 'features/0_splash/view/onboarding_page.dart';
import 'features/0_splash/view/login_page.dart';
import 'features/main_navigation/view/main_navigation_page.dart';

// Inisialisasi Service secara global
final storageService = StorageService();
final apiService = ApiService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Storage Service sebelum aplikasi jalan
  await storageService.init();

  Widget startPage;

  // 2. Cek Status Login & Onboarding
  final bool isOnboardingDone = storageService.isOnboardingComplete();

  // Menggunakan User ID dari DB sebagai penanda login yang valid
  // (Pastikan key-nya sesuai dengan yang ada di storage_service.dart)
  final String? userId = storageService.getUserIdFromDB();

  // 3. Logika Penentuan Halaman Awal
  if (!isOnboardingDone) {
    // Jika baru pertama kali install -> Onboarding
    startPage = const OnboardingPage();
  } else if (userId == null || userId.isEmpty) {
    // Jika belum login atau token hilang -> Login Page
    startPage = const LoginPage();
  } else {
    // Jika sudah login -> Masuk ke Halaman Utama dengan Navbar
    startPage = const MainNavigationPage();
  }

  // 4. Jalankan Aplikasi
  // Kita mengirimkan service ke AppView agar bisa diakses oleh Bloc/Cubit
  runApp(
    AppView(
      initialPage: startPage,
      apiService: apiService,
      storageService: storageService,
    ),
  );
}
