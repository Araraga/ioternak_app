import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // --- [PERUBAHAN] Ganti Icon dengan Path Gambar ---
  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Ekosistem Alat Pintar\nKandang Ternak",
      "desc":
          "Hubungkan berbagai perangkat canggih mulai dari sensor lingkungan hingga pakan otomatis dalam satu aplikasi yang terintegrasi.",
      "image": "assets/images/slide1.png", // Ganti Icon jadi Image
    },
    {
      "title": "Monitor dan Kontrol\nKandang Secara Realtime",
      "desc":
          "Pantau suhu, kelembapan, dan gas amonia detik ini juga. Atur jadwal pakan dari mana saja tanpa perlu datang ke kandang.",
      "image": "assets/images/slide2.png",
    },
    {
      "title": "Tingkatkan Kualitas dan\nPenghasilan Kandang",
      "desc":
          "Ciptakan lingkungan ideal untuk pertumbuhan ternak yang sehat, kurangi risiko kematian, dan maksimalkan keuntungan panen Anda.",
      "image": "assets/images/slide3.png",
    },
  ];

  void _finishOnboarding() async {
    await context.read<StorageService>().setOnboardingComplete();

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  final data = _onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // --- [PERUBAHAN] Tampilkan Gambar ---
                        // Tidak perlu Container bulat lagi jika gambarnya ilustrasi penuh
                        SizedBox(
                          height: 250, // Atur tinggi gambar agar proporsional
                          child: Image.asset(
                            data['image'],
                            fit: BoxFit.contain,
                            // Placeholder jika gambar belum ada
                            errorBuilder: (ctx, err, stack) => Container(
                              height: 150,
                              width: 150,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 60,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        Text(
                          data['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data['desc'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bagian Bawah (Dots & Tombol)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indikator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.textSecondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Tombol Mulai (Hanya di slide terakhir)
                  if (_currentPage == _onboardingData.length - 1)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _finishOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          "Mulai Sekarang",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48), // Placeholder jarak
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
