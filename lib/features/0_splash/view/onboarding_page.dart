import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _bgController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Ekosistem Alat Pintar\nKandang Ternak',
      'desc':
          'Hubungkan berbagai perangkat canggih mulai dari sensor lingkungan hingga pakan otomatis dalam satu aplikasi terintegrasi.',
      'icon': Icons.hub_outlined,
      'gradient': [Color(0xFF2ECC71), Color(0xFF1ABC9C)],
      'accentIcon': Icons.sensors,
    },
    {
      'title': 'Monitor & Kontrol\nKandang Realtime',
      'desc':
          'Pantau suhu, kelembapan, dan gas amonia detik ini juga. Atur jadwal pakan dari mana saja tanpa perlu ke kandang.',
      'icon': Icons.monitor_heart_outlined,
      'gradient': [Color(0xFF3498DB), Color(0xFF2980B9)],
      'accentIcon': Icons.thermostat,
    },
    {
      'title': 'AI Jago Siap\nMembantu Anda',
      'desc':
          'Tanya Prof. Jago tentang kondisi kandang, jadwal pakan ideal, atau tips beternak. AI kami tahu semuanya.',
      'icon': Icons.psychology_outlined,
      'gradient': [Color(0xFF667EEA), Color(0xFF764BA2)],
      'accentIcon': Icons.chat_bubble_outline,
    },
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _slideController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _slideController.reset();
    _slideController.forward();
  }

  Future<void> _finishOnboarding() async {
    await context.read<StorageService>().setOnboardingComplete();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final data = _onboardingData[_currentPage];
    final gradColors = data['gradient'] as List<Color>;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          final t = _bgController.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFFE8F8F0),
                    const Color(0xFFE0F0FF),
                    t,
                  )!,
                  Color.lerp(
                    const Color(0xFFE0F0FF),
                    const Color(0xFFECF9F1),
                    t,
                  )!,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Skip button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_currentPage < _onboardingData.length - 1)
                          GestureDetector(
                            onTap: _finishOnboarding,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                'Lewati',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Main page content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _onboardingData.length,
                      itemBuilder: (context, index) {
                        return _buildPage(
                          _onboardingData[index],
                          index == _currentPage,
                        );
                      },
                    ),
                  ),

                  // Bottom controls
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 36),
                    child: Column(
                      children: [
                        // Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _onboardingData.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.elasticOut,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: _currentPage == i ? 32 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == i
                                    ? gradColors[0]
                                    : AppColors.textSecondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Button
                        GestureDetector(
                          onTap: _currentPage == _onboardingData.length - 1
                              ? _finishOnboarding
                              : () => _pageController.nextPage(
                                  duration: const Duration(milliseconds: 450),
                                  curve: Curves.easeInOut,
                                ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradColors,
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: gradColors[0].withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Text(
                              _currentPage == _onboardingData.length - 1
                                  ? 'Mulai Sekarang 🚀'
                                  : 'Lanjutkan',
                              textAlign: TextAlign.center,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> data, bool isActive) {
    final gradColors = data['gradient'] as List<Color>;
    final icon = data['icon'] as IconData;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: FadeTransition(
        opacity: isActive ? _fadeAnim : const AlwaysStoppedAnimation(1.0),
        child: SlideTransition(
          position: isActive ? _slideAnim : const AlwaysStoppedAnimation(Offset.zero),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.12),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradColors[0].withOpacity(0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Illustration area
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            colors: [
                              gradColors[0].withOpacity(0.2),
                              gradColors[1].withOpacity(0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: gradColors[0].withOpacity(0.2),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background circle
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    gradColors[0].withOpacity(0.15),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // Main icon
                            Icon(icon, size: 80, color: gradColors[0]),
                            // Small floating icons
                            Positioned(
                              top: 30,
                              right: 40,
                              child: _floatingIcon(
                                data['accentIcon'] as IconData,
                                gradColors[0],
                                small: true,
                              ),
                            ),
                            Positioned(
                              bottom: 30,
                              left: 35,
                              child: _floatingIcon(
                                Icons.check_circle,
                                gradColors[1],
                                small: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      Text(
                        data['title'],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        data['desc'],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _floatingIcon(IconData icon, Color color, {bool small = false}) {
    final size = small ? 36.0 : 48.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(icon, color: color, size: small ? 18 : 24),
    );
  }
}
